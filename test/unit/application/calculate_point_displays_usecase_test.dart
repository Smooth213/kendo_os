import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/application/usecases/match_rebuild_usecase.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';

void main() {
  late KendoRuleEngine engine;
  late CalculatePointDisplaysUseCase useCase;

  setUp(() {
    engine = KendoRuleEngine();
    useCase = CalculatePointDisplaysUseCase(engine);
  });

  group('[Unit] CalculatePointDisplaysUseCase 単体テスト', () {
    test('イベントが存在しない初期試合データにおいて赤白ともに空のリストが返却されること', () {
      const match = MatchModel(
        id: 'match-empty',
        matchType: 'individual',
        redName: '選手A',
        whiteName: '選手B',
      );

      final result = useCase.execute(match);
      expect(result[Side.red], isEmpty);
      expect(result[Side.white], isEmpty);
    });

    test('赤選手に面打突イベントが存在する場合に赤側にPointDisplayが1件算出されること', () {
      final match = MatchModel(
        id: 'match-red-men',
        matchType: 'individual',
        redName: '選手A',
        whiteName: '選手B',
        events: [
          ScoreEvent(
            id: 'evt-1',
            side: Side.red,
            strikeType: StrikeType.men,
            isIppon: true,
            timestamp: DateTime.now(),
          ),
        ],
      );

      final result = useCase.execute(match);
      expect(result[Side.red]?.length, 1);
      expect(result[Side.white], isEmpty);
    });

    test('赤白双方に打突イベントが存在する場合に両者のPointDisplayが過不足なく算出されること', () {
      final match = MatchModel(
        id: 'match-both',
        matchType: 'individual',
        redName: '選手A',
        whiteName: '選手B',
        events: [
          ScoreEvent(
            id: 'evt-red',
            side: Side.red,
            strikeType: StrikeType.kote,
            isIppon: true,
            timestamp: DateTime.now(),
          ),
          ScoreEvent(
            id: 'evt-white',
            side: Side.white,
            strikeType: StrikeType.dou,
            isIppon: true,
            timestamp: DateTime.now(),
          ),
        ],
      );

      final result = useCase.execute(match);
      expect(result[Side.red]?.length, 1);
      expect(result[Side.white]?.length, 1);
    });
  });
}
