import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/domain/entities/program_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/program_repository.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';

/// 大会IDに紐づくプログラム一覧のリアルタイム監視プロバイダ
/// ドック等から初回オープンされた際も、道場ID未確定によるローディング停止を防ぐため
/// 必要に応じて大会の所属組織IDを自動解決・補正して即座にデータをストリーミングします。
final programListProvider = StreamProvider.family<List<ProgramModel>, String>((
  ref,
  tournamentId,
) async* {
  final currentDojoId = ref.watch(currentDojoIdProvider);
  final repository = ref.watch(programRepositoryProvider);

  // 1. 道場IDが既に有効値（default_dojo_room以外かつ空でない）であれば即座に監視開始
  if (currentDojoId.isNotEmpty && currentDojoId != 'default_dojo_room') {
    yield* repository.watchPrograms(tournamentId);
    return;
  }

  // 2. 道場IDが未確定（default_dojo_room または空）の場合、大会の所属道場IDを探索
  String? resolvedDojoId;
  try {
    final firestore = FirebaseFirestore.instance;
    final snap = await firestore
        .collectionGroup('tournaments')
        .where(FieldPath.documentId, isEqualTo: tournamentId)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      final pathSegments = snap.docs.first.reference.path.split('/');
      final orgIndex = pathSegments.indexOf('organizations');
      if (orgIndex != -1 && pathSegments.length > orgIndex + 1) {
        resolvedDojoId = pathSegments[orgIndex + 1];
        debugPrint('🎯 [programListProvider] 大会所属道場IDを自動特定: $resolvedDojoId');

        // グローバルの currentDojoIdProvider も自動同期補正
        Future.microtask(() {
          try {
            ref.read(currentDojoIdProvider.notifier).state = resolvedDojoId!;
          } catch (_) {}
        });
      }
    }
  } catch (e) {
    debugPrint('⚠️ [programListProvider] 道場ID自動探索エラー: $e');
  }

  if (resolvedDojoId != null && resolvedDojoId.isNotEmpty) {
    final resolvedRepo = ProgramRepository(dojoId: resolvedDojoId);
    yield* resolvedRepo.watchPrograms(tournamentId);
    return;
  }

  // フォールバック: 現在のリポジトリ（モック等含む）から取得
  yield* repository.watchPrograms(tournamentId);
});
