import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/security/dojo_join_access_storage.dart';
import 'package:kendo_os/security/dojo_security_repository.dart';
import 'package:kendo_os/security/pwa_storage_bridge.dart';
import 'package:kendo_os/security/viewer_share_models.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/presentation/providers/auth_session_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/providers/dojo_room_history_provider.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/widgets/room_join_duplicate_warning_dialog.dart';
import 'package:kendo_os/shared/widgets/room_join_pin_dialog.dart';

/// 道場ルーム参加時の新規PIN設定・既存PIN認証・未設定ルーム初期化のオーケストレーション。
class RoomJoinFlowCoordinator {
  const RoomJoinFlowCoordinator._();

  static String resolveActorUid() {
    try {
      if (Firebase.apps.isNotEmpty) {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null && uid.isNotEmpty) return uid;
      }
    } catch (_) {}
    return 'owner_terminal';
  }

  /// 指定された道場コードに対する参加・PIN認証フローを実行する。
  /// 接続完了時は true を返す。
  static Future<bool> executeJoinFlow({
    required BuildContext context,
    required WidgetRef ref,
    required FirebaseFirestore firestore,
    required String cleanCode,
    bool showDuplicateWarning = true,
    VoidCallback? onInspectionComplete,
  }) async {
    final securityRepo = DojoSecurityRepository(firestore);
    final status = await securityRepo.inspectRoomStatus(cleanCode);
    onInspectionComplete?.call();
    if (!context.mounted) return false;

    final uid = resolveActorUid();

    if (status == DojoJoinStatus.notFound) {
      final created = await RoomJoinPinDialog.show(
        context: context,
        dojoId: cleanCode,
        mode: RoomJoinPinMode.createNew,
        onSubmitPin: (pin) async {
          try {
            final joinPinHash = await securityRepo.createDojoWithPin(
              dojoId: cleanCode,
              joinPin: pin,
              uid: uid,
            );
            if (!context.mounted) return null;
            await completeRoomConnection(
              context: context,
              ref: ref,
              code: cleanCode,
              joinPinHash: joinPinHash,
            );
            return null;
          } catch (e) {
            return '道場ルームの作成に失敗しました: $e';
          }
        },
      );
      return created == true;
    }

    if (!showDuplicateWarning) {
      return openExistingRoomPinDialog(
        context: context,
        ref: ref,
        code: cleanCode,
        status: status,
        securityRepo: securityRepo,
        uid: uid,
      );
    }

    var connected = false;
    await RoomJoinDuplicateWarningDialog.showAndAwait(
      context: context,
      code: codeOrClean(cleanCode),
      onConfirm: () async {
        connected = await openExistingRoomPinDialog(
          context: context,
          ref: ref,
          code: cleanCode,
          status: status,
          securityRepo: securityRepo,
          uid: uid,
        );
      },
    );
    return connected;
  }

  static String codeOrClean(String code) => code;

  /// 既存道場（またはPIN未設定レガシー道場）へのPIN認証/初期PIN設定ダイアログを開く
  static Future<bool> openExistingRoomPinDialog({
    required BuildContext context,
    required WidgetRef ref,
    required String code,
    required DojoJoinStatus status,
    required DojoSecurityRepository securityRepo,
    required String uid,
  }) async {
    if (!context.mounted) return false;
    final mode = status == DojoJoinStatus.legacyUnsetPin
        ? RoomJoinPinMode.initializeLegacy
        : RoomJoinPinMode.joinExisting;

    final verified = await RoomJoinPinDialog.show(
      context: context,
      dojoId: code,
      mode: mode,
      onRecoveredJoinPin: (newJoinPinHash) => completeRoomConnection(
        context: context,
        ref: ref,
        code: code,
        joinPinHash: newJoinPinHash,
      ),
      onSubmitPin: (pin) async {
        try {
          if (mode == RoomJoinPinMode.initializeLegacy) {
            final joinPinHash = await securityRepo.initializeLegacyDojoPin(
              dojoId: code,
              joinPin: pin,
              uid: uid,
            );
            if (!context.mounted) return null;
            await completeRoomConnection(
              context: context,
              ref: ref,
              code: code,
              joinPinHash: joinPinHash,
            );
            return null;
          }

          final joinPinHash = await securityRepo.joinExistingDojoWithPin(
            dojoId: code,
            joinPin: pin,
            uid: uid,
          );
          if (joinPinHash == null) {
            return '🔒 道場入室PINが一致しません';
          }
          if (!context.mounted) return null;
          await completeRoomConnection(
            context: context,
            ref: ref,
            code: code,
            joinPinHash: joinPinHash,
          );
          return null;
        } catch (e) {
          return '認証通信に失敗しました: $e';
        }
      },
    );
    return verified == true;
  }

  /// PIN検証通過後の最終接続確定処理
  static Future<void> completeRoomConnection({
    required BuildContext context,
    required WidgetRef ref,
    required String code,
    required String joinPinHash,
  }) async {
    DojoJoinAccessStorage.saveJoinPinHash(code, joinPinHash);
    ref.read(currentDojoIdProvider.notifier).state = code;
    try {
      PwaStorage.setItem('kendo_os_active_dojo_id', code);
    } catch (_) {}

    await ref
        .read(authSessionProvider.notifier)
        .establishSession(UserRole.viewer, code, joinPinHash: joinPinHash);

    ref.read(dojoRoomHistoryProvider.notifier).addHistory(code);

    if (!context.mounted) return;
    AppSnackBar.showSuccess(context, '⚡ 道場空間 [ $code ] にリアルタイム直結しました');
  }
}
