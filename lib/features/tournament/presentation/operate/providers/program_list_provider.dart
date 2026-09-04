import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/domain/entities/program_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/program_repository.dart';

/// 大会IDに紐づくプログラム一覧のリアルタイム監視プロバイダ
final programListProvider = StreamProvider.family<List<ProgramModel>, String>((
  ref,
  tournamentId,
) {
  final repository = ref.watch(programRepositoryProvider);
  return repository.watchPrograms(tournamentId);
});
