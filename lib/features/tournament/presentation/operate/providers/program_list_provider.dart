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

  final syncContext = ref.watch(currentSyncContextProvider);
  if (syncContext.organizationId.isNotEmpty &&
      syncContext.organizationId != 'default_dojo_room') {
    final syncRepo = ProgramRepository(dojoId: syncContext.organizationId);
    yield* syncRepo.watchPrograms(tournamentId);
    return;
  }

  // 2. 道場IDが未確定（default_dojo_room または空）の場合はフォールバックリポジトリを返す
  yield* repository.watchPrograms(tournamentId);
});
