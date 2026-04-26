import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/match_model.dart';
import '../../domain/match/score_event.dart';
import 'match_command_provider.dart';
import '../../application/service/match_application_service.dart'; 
import '../../repositories/match_repository.dart'; // ★ 復元
import '../../domain/kendo_rule_engine.dart';      // ★ 復元
import '../../application/usecase/match_usecase.dart';         // ★ 復元

// 1. 現在選択されている試合ID
class CurrentMatchIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void setId(String id) { state = id; }
}

final currentMatchIdProvider = NotifierProvider<CurrentMatchIdNotifier, String?>(() {
  return CurrentMatchIdNotifier();
});

// ★ 削ぎ落としすぎてしまった重要プロバイダ群の復元
final currentMatchStreamProvider = StreamProvider<MatchModel?>((ref) {
  final matchId = ref.watch(currentMatchIdProvider);
  if (matchId == null) return Stream.value(null);
  return ref.read(matchRepositoryProvider).watchSingleMatch(matchId);
});

final kendoRuleEngineProvider = Provider<KendoRuleEngine>((ref) {
  return KendoRuleEngine();
});

final matchUseCaseProvider = Provider<MatchUseCase>((ref) {
  return MatchUseCase(ref.watch(kendoRuleEngineProvider));
});

final matchActionProvider = Provider<MatchActionController>((ref) {
  return MatchActionController(ref);
});

class MatchActionController {
  final Ref ref;

  MatchActionController(this.ref);

  // ★ ③ Providerの役割変更: ロジックを捨て、Serviceへの「橋渡し」のみを行う
  Future<void> processScoreEvent(MatchModel currentMatch, ScoreEvent event) async {
    await ref.read(matchApplicationServiceProvider).addIppon(currentMatch.id, event.side, event.type);
  }

  Future<void> undoEvent(MatchModel currentMatch) async {
    await ref.read(matchApplicationServiceProvider).undo(currentMatch.id);
  }

  Future<void> handleTimeUp(MatchModel currentMatch, bool isEnchoEnabled) async {
    await ref.read(matchApplicationServiceProvider).handleTimeUp(currentMatch.id);
  }

  // UIからの手動操作用
  Future<void> approveMatch(MatchModel currentMatch) async {
    await ref.read(matchApplicationServiceProvider).approveMatch(currentMatch.id);
  }

  Future<void> finishMatch(MatchModel currentMatch) async {
    await ref.read(matchApplicationServiceProvider).finishMatch(currentMatch.id);
  }

  void updateScore(MatchModel currentMatch, int redScore, int whiteScore) async {
    final updatedMatch = currentMatch.copyWith(redScore: redScore, whiteScore: whiteScore, status: 'in_progress');
    await ref.read(matchCommandProvider).saveMatch(updatedMatch);
  }
}