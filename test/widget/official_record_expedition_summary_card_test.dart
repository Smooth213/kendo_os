import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/official_record_expedition_summary_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🛡️ OfficialRecordExpeditionSummaryCard Tests', () {
    testWidgets(
      '1. OfficialRecordExpeditionSummaryCard renders properly with matches',
      (tester) async {
        final match = MatchModel(
          id: 'm1',
          matchOrder: 1,
          redName: 'A道場 : 佐藤',
          whiteName: 'B道場 : 鈴木',
          redScore: 2,
          whiteScore: 0,
          status: 'finished',
          matchType: '団体戦',
          matchScene: 'honsen',
          groupName: '第1試合場',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: OfficialRecordExpeditionSummaryCard(
                  matches: [match],
                  isDark: false,
                  registeredTeamNames: const {'A道場'},
                  registeredPlayerNames: const {'佐藤'},
                ),
              ),
            ),
          ),
        );

        expect(find.text('成績サマリー'), findsOneWidget);
        // 初期状態ではカード全体が折りたたまれており「開く」が表示される
        expect(find.text('開く'), findsOneWidget);
        expect(find.text('閉じる'), findsNothing);

        // カードを展開
        await tester.tap(
          find.byKey(const Key('btn_toggle_expedition_summary')),
        );
        await tester.pumpAndSettle();

        // 展開後は「閉じる」が表示され、中身の各要素が表示される
        expect(find.text('閉じる'), findsOneWidget);
        expect(find.text('本戦 (団体)'), findsOneWidget);
        expect(find.text('詳細分析 ›'), findsOneWidget);
        expect(find.text('選手別成績 (1名)'), findsOneWidget);
        expect(find.text('表示する'), findsOneWidget);

        // 選手別成績のアコーディオンをタップして展開
        await tester.tap(find.text('選手別成績 (1名)'));
        await tester.pumpAndSettle();

        // 選手別成績が展開される
        expect(find.text('佐藤: 1勝0敗'), findsOneWidget);

        // もう一度タップして選手別成績を折りたたみ
        await tester.tap(find.text('選手別成績 (1名)'));
        await tester.pumpAndSettle();

        expect(find.text('表示する'), findsOneWidget);

        // カード全体の「閉じる」をタップしてサマリーを折りたたむ
        await tester.tap(
          find.byKey(const Key('btn_toggle_expedition_summary')),
        );
        await tester.pumpAndSettle();

        // 再び「開く」が表示される
        expect(find.text('開く'), findsOneWidget);
      },
    );

    test('2. ExpeditionStatsCalculator computes wins accurately', () {
      final match = MatchModel(
        id: 'm1',
        matchOrder: 1,
        redName: 'A道場 : 佐藤',
        whiteName: 'B道場 : 鈴木',
        redScore: 2,
        whiteScore: 0,
        status: 'finished',
        matchType: '団体戦',
        matchScene: 'renseikai',
        groupName: '第1試合場',
      );

      final data = ExpeditionStatsCalculator.calculate(
        matches: [match],
        registeredTeamNames: const {'A道場'},
        registeredPlayerNames: const {'佐藤'},
        selectedSummaryTeam: '全体',
      );

      expect(data.renseikaiWin, equals(1));
      expect(data.renseikaiLoss, equals(0));
      expect(data.teamsList, contains('A道場'));
    });
  });
}
