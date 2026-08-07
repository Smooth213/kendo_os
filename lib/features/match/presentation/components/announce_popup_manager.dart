import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/announce_model.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/match/presentation/components/announce_history_bottom_sheet.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kendo_os/shared/infrastructure/services/notification_service.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';

// 🛡️ アクティブなストリームサブスクリプションを追跡（画面再構築時の重複購読を完全に防止）
final Map<String, StreamSubscription> _activeSubscriptions = {};

// 表示済みのポップアップID（同一IDの再表示を完全に防止）
final Set<String> _shownAnnounceIds = {};

// ポップアップダイアログ表示中フラグ（累積スタック・多重モーダルの発生を防止）
bool _isAnnounceDialogShowing = false;

// 🌟 キューイング用：ポップアップ表示中に受信した最新のアナウンスを保留するバッファ
AnnounceModel? _pendingAnnounce;
String? _pendingTarget;

// 🌟 自身が送信したアナウンスIDのキャッシュ（自分の送信によるポップアップ表示を防ぐため）
final Set<String> _mySentAnnounceIds = {};

// 🌟 自身が送信したアナウンスIDをキャッシュへ安全に登録する関数
void registerMySentAnnounceId(String id) {
  _mySentAnnounceIds.add(id);
}

/// 🛡️ テスト環境用の状態リセット関数
@visibleForTesting
void resetAnnouncePopupManager() {
  for (final sub in _activeSubscriptions.values) {
    sub.cancel();
  }
  _activeSubscriptions.clear();
  _shownAnnounceIds.clear();
  _isAnnounceDialogShowing = false;
  _pendingAnnounce = null;
  _pendingTarget = null;
  _mySentAnnounceIds.clear();
}

/// 🌟 ダイアログを安全に表示し、閉じられた後に保留中のアナウンスがあれば連鎖起動するヘルパー
void _showAnnounceDialog(
  BuildContext context,
  WidgetRef ref,
  AnnounceModel announce,
  String target,
) {
  _shownAnnounceIds.add(announce.id);
  _isAnnounceDialogShowing = true;

  showAppDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      final bool isStaffOnlyNotice = target == 'staff';

      return AppDialog(
        titleIcon: Icons.campaign,
        iconColor: const Color(0xFFFF69B4),
        title: isStaffOnlyNotice
            ? '【スタッフ限定業務連絡】'
            : (announce.title.isNotEmpty ? announce.title : '大会本部からのお知らせ'),
        content: Text(
          announce.body,
          style: TextStyle(
            fontSize: AppFontSize.body,
            height: 1.5,
            color: isDark
                ? AppKendoColors.grey.shade300
                : const Color(0xFF2C3E50),
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00796B), // 引き締めTealグリーン
                foregroundColor: AppKendoColors.pureWhite,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.small),
                elevation: 0,
              ),
              onPressed: () {
                // 🌟 既読にしたことを端末ローカルに保存（再度画面に入った際に表示させないため）
                ref
                    .read(readAnnouncementsProvider.notifier)
                    .markAsRead(announce.id);
                Navigator.pop(ctx);
              },
              child: const Text(
                '内容を確認しました',
                style: TextStyle(
                  fontWeight: AppFontWeight.bold,
                  fontSize: AppFontSize.bodySmall,
                ),
              ),
            ),
          ),
        ],
      );
    },
  ).then((_) {
    debugPrint(
      '📢 [PopupManager] ダイアログが閉じられました。_isAnnounceDialogShowing を false にリセットします。',
    );
    _isAnnounceDialogShowing = false;

    // 🌟 閉じた直後、もし表示待機中（保留中）の別のアナウンスがあれば連鎖表示を開始
    if (_pendingAnnounce != null && _pendingTarget != null) {
      final pending = _pendingAnnounce!;
      final pendingTarget = _pendingTarget!;
      _pendingAnnounce = null;
      _pendingTarget = null;

      final int nowMs = DateTime.now().millisecondsSinceEpoch;
      final int announceMs = pending.timestamp.millisecondsSinceEpoch;
      final int diffMs = (nowMs - announceMs).abs();
      final bool isRecent = diffMs < 30 * 60 * 1000;

      if (isRecent &&
          !_shownAnnounceIds.contains(pending.id) &&
          context.mounted) {
        debugPrint('📢 [PopupManager] 保留されていた次のアナウンスを連鎖表示します: ${pending.id}');
        _showAnnounceDialog(context, ref, pending, pendingTarget);
      }
    }
  });
}

/// 🌟 各画面の最外殻でアナウンスのFirestoreを監視し、全員向け/スタッフ向けの送り分けを安全に制御する
void listenGlobalAnnouncements(
  BuildContext context,
  WidgetRef ref,
  String tournamentId, {
  required bool isStaffRoom,
}) {
  try {
    final settings = ref.read(settingsProvider);
    debugPrint(
      '📢 [listenGlobalAnnouncements] 開始 - tournamentId: "$tournamentId", isStaffRoom: $isStaffRoom, notifyOnEmergency: ${settings.notifyOnEmergency}',
    );
    if (!settings.notifyOnEmergency) return;

    final key = '${tournamentId}_$isStaffRoom';
    if (_activeSubscriptions.containsKey(key)) {
      debugPrint('📢 [listenGlobalAnnouncements] 既に監視中のためスキップ - key: "$key"');
      return; // 🛡️ 防衛線：既にこの画面種別でストリーム購読済みの場合は即時リターン（重複を回避）
    }

    // 🔔 プッシュ通知受信用にトピック購読（Native）またはFCMトークン保存（Web）を実行
    ref
        .read(notificationServiceProvider)
        .registerPushNotification(
          tournamentId: tournamentId,
          isStaff: isStaffRoom,
        );

    final firestore = ref.read(firestoreProvider);
    final DateTime listenerStartTime = DateTime.now();

    final subscription = firestore
        .collection('announcements')
        .where('tournamentId', isEqualTo: tournamentId)
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots()
        .listen((snapshot) {
          debugPrint(
            '📢 [listenGlobalAnnouncements] Firestore受信 - docs数: ${snapshot.docs.length}',
          );
          if (snapshot.docs.isEmpty) return;

          // 🛡️ インデックス安全パッチ：クエリでの複合インデックス要件を回避するため、
          // クライアント側で最新 of type == 'emergency' アナウンスを探す
          DocumentSnapshot<Map<String, dynamic>>? targetDoc;
          for (final doc in snapshot.docs) {
            final data = doc.data();
            if (data['type'] == 'emergency') {
              targetDoc = doc;
              break;
            }
          }

          if (targetDoc == null) {
            debugPrint(
              '📢 [listenGlobalAnnouncements] 警告: emergency タイプのドキュメントが見つかりませんでした。',
            );
            return;
          }
          final doc = targetDoc;
          final data = doc.data();
          if (data == null) return;

          // 🌟 送り分けターゲットの抽出（デフォルトは全員向け 'all'）
          final String target = data['target'] as String? ?? 'all';
          debugPrint(
            '📢 [listenGlobalAnnouncements] ドキュメント判定 - ID: ${doc.id}, target: $target',
          );

          // 🛡️ 防衛線：スタッフ限定通知（staff）であり、かつ現在の画面が観客席（isStaffRoom == false）なら完全スルー
          if (target == 'staff' && !isStaffRoom) {
            debugPrint(
              '🛡️ [PopupManager] スタッフ限定アナウンスを検知したため、観客席でのポップアップをスキップしました。',
            );
            return;
          }

          final announce = AnnounceModel.fromJson({...data, 'id': doc.id});

          // 🛡️ 防衛線：自分自身が発信したお知らせである場合はポップアップを表示しない
          if (_mySentAnnounceIds.contains(announce.id)) {
            debugPrint(
              '📢 [listenGlobalAnnouncements] 自身が送信したアナウンスのためスキップします - ID: ${announce.id}',
            );
            return;
          }

          // 🛡️ 防衛線：既にローカルで既読済みのアナウンスである場合はポップアップを表示しない
          final readIds = ref.read(readAnnouncementsProvider);
          final bool isAlreadyRead =
              announce.isRead || readIds.contains(announce.id);
          debugPrint(
            '📢 [listenGlobalAnnouncements] 既読チェック - isRead: ${announce.isRead}, contains: ${readIds.contains(announce.id)}',
          );
          if (isAlreadyRead) return;

          final int announceMs = announce.timestamp.millisecondsSinceEpoch;

          // 🛡️ 防衛線：起動直後に過去の古い通知が再度ポップアップするのを完全に防止（サーバーと端末の微小な時計誤差を吸収するため2秒の猶予を持たせる）
          final int listenerStartMs =
              listenerStartTime.millisecondsSinceEpoch - 2000;
          if (announceMs < listenerStartMs) {
            debugPrint(
              '📢 [listenGlobalAnnouncements] 監視開始前の過去のお知らせのためスキップします - ID: ${announce.id}, announceMs: $announceMs, listenerStartMs: $listenerStartMs',
            );
            return;
          }

          // 🌟 タイムゾーン/時計のズレに100%強い、ミリ秒エポック基準の絶対時間差チェック（30分 = 1800000ms）
          final int nowMs = DateTime.now().millisecondsSinceEpoch;
          final int diffMs = (nowMs - announceMs).abs();
          final bool isRecent = diffMs < 30 * 60 * 1000;
          debugPrint(
            '📢 [listenGlobalAnnouncements] 時間差チェック - nowMs: $nowMs, announceMs: $announceMs, diffMinutes: ${diffMs / 60000.0}, isRecent: $isRecent',
          );

          if (_shownAnnounceIds.contains(announce.id) || !isRecent) {
            debugPrint(
              '📢 [listenGlobalAnnouncements] 既に表示済みまたは30分以上前のためスキップ - shown: ${_shownAnnounceIds.contains(announce.id)}, isRecent: $isRecent',
            );
            return;
          }

          // 🛡️ 防衛線：既に別のポップアップが表示中である場合、このお知らせを保留バッファに格納してスルーする（連鎖表示へ）
          debugPrint(
            '📢 [listenGlobalAnnouncements] 表示前最終チェック - _isAnnounceDialogShowing: $_isAnnounceDialogShowing, context.mounted: ${context.mounted}',
          );
          if (_isAnnounceDialogShowing) {
            debugPrint(
              '📢 [listenGlobalAnnouncements] 警告: 既にダイアログが表示中のため、この通知を保留します。ID: ${announce.id}',
            );
            _pendingAnnounce = announce;
            _pendingTarget = target;
            return;
          }

          if (!context.mounted) return;

          _showAnnounceDialog(context, ref, announce, target);
        });

    _activeSubscriptions[key] = subscription;
  } catch (e) {
    debugPrint(
      '⚠️ [listenGlobalAnnouncements] Firestore connection skipped: $e',
    );
  }
}
