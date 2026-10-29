import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/application/mappers/match_projection_mapper.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/tournament/presentation/components/kachinuki/kachinuki_center_battle_card.dart';
import 'package:kendo_os/features/tournament/presentation/components/kachinuki/kachinuki_team_life_card.dart';

void main() {
  group('[Widget] 勝ち抜き戦 チーム残機・センターバトルカード統合検証テスト', () {
    testWidgets('チーム名・タイトル・シールド残機が正しく描画されること', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: KachinukiTeamLifeCard(
              redTeamName: '赤道場',
              whiteTeamName: '白道場',
              redTotal: 5,
              redDead: 2,
              whiteTotal: 5,
              whiteDead: 3,
              isDark: false,
            ),
          ),
        ),
      );

      expect(find.text('チーム生存状況（残機）'), findsOneWidget);
      expect(find.text('赤道場'), findsOneWidget);
      expect(find.text('白道場'), findsOneWidget);
      expect(find.text('VS'), findsOneWidget);
      expect(find.byIcon(Icons.shield), findsNWidgets(10));
    });

    testWidgets('ダークモードにおいてシールド残機がエラーなく正しく描画されること', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: KachinukiTeamLifeCard(
              redTeamName: '紅組',
              whiteTeamName: '白組',
              redTotal: 3,
              redDead: 1,
              whiteTotal: 3,
              whiteDead: 0,
              isDark: true,
            ),
          ),
        ),
      );

      expect(find.text('紅組'), findsOneWidget);
      expect(find.text('白組'), findsOneWidget);
      expect(find.byIcon(Icons.shield), findsNWidgets(6));
    });

    testWidgets('進行中の勝ち抜き試合においてVS表示と選手名が正しく描画されること', (tester) async {
      final match = MatchModel(
        id: 'm1',
        tournamentId: 't1',
        matchType: '勝ち抜き戦',
        redName: '山田 太郎',
        whiteName: '佐藤 次郎',
        status: 'in_progress',
        isKachinuki: true,
      );

      final engine = KendoRuleEngine();
      final analysis = engine.analyzeHistory(match.events, match, match.rule);

      final uiState = {
        'match': MatchProjectionMapper.toProjection(match, analysis),
        'isDone': false,
        'rStreak': 0,
        'wStreak': 0,
        'rName': '山田 太郎',
        'wName': '佐藤 次郎',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KachinukiCenterBattleCard(
              uiState: uiState,
              matchNumber: 1,
              isDark: false,
              rLasts: ['山田'],
              wLasts: ['佐藤'],
            ),
          ),
        ),
      );

      expect(find.text('1試合目'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('山田'),
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('佐藤'),
        ),
        findsOneWidget,
      );
      expect(find.text('VS'), findsOneWidget);
    });

    testWidgets('終了済みの勝ち抜き試合においてスコアと連勝バッジが正しく描画されること', (tester) async {
      final match = MatchModel(
        id: 'm2',
        tournamentId: 't1',
        matchType: '勝ち抜き戦',
        redName: '山田 太郎',
        whiteName: '佐藤 次郎',
        status: 'finished',
        isKachinuki: true,
        events: [
          ScoreEvent(
            id: 'e1',
            side: Side.red,
            strikeType: StrikeType.men,
            isIppon: true,
            timestamp: DateTime.now(),
          ),
          ScoreEvent(
            id: 'e2',
            side: Side.red,
            strikeType: StrikeType.kote,
            isIppon: true,
            timestamp: DateTime.now(),
          ),
        ],
      );

      final engine = KendoRuleEngine();
      final analysis = engine.analyzeHistory(match.events, match, match.rule);

      final uiState = {
        'match': MatchProjectionMapper.toProjection(match, analysis),
        'isDone': true,
        'rStreak': 3,
        'wStreak': 0,
        'rName': '山田 太郎',
        'wName': '佐藤 次郎',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KachinukiCenterBattleCard(
              uiState: uiState,
              matchNumber: 3,
              isDark: false,
              rLasts: ['山田'],
              wLasts: ['佐藤'],
            ),
          ),
        ),
      );

      expect(find.text('3試合目'), findsOneWidget);
      expect(find.text('🔥 3人抜き'), findsOneWidget);
      expect(find.text('-'), findsOneWidget);
    });
  });
}
