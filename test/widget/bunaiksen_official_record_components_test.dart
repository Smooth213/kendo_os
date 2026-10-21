import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen_official_record/bunaiksen_kachinuki_record_card.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen_official_record/bunaiksen_record_action_bar.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen_official_record/bunaiksen_team_score_table.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen_official_record/bunaiksen_team_score_table_row_builder.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/official_record_export_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Widget] 部内戦公式記録コンポーネント統合テスト', () {
    group('BunaiksenRecordActionBar ウィジェットテスト', () {
      testWidgets('部内戦記録アクションバーのアクションボタンが正しく描画されること', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BunaiksenRecordActionBar(
                cardColor: Colors.white,
                isDark: false,
                isExporting: false,
                onPrintPdf: () {},
                onShareImage: () {},
              ),
            ),
          ),
        );

        expect(find.text('PDF印刷'), findsOneWidget);
        expect(find.text('画像シェア'), findsOneWidget);
        expect(find.text('全試合形式一括出力'), findsNothing);
      });

      testWidgets('複数形式存在時に全試合形式一括出力トグルが表示されタップで切り替わること', (tester) async {
        OfficialRecordExportScope currentScope =
            OfficialRecordExportScope.current;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return BunaiksenRecordActionBar(
                    cardColor: Colors.white,
                    isDark: false,
                    isExporting: false,
                    hasMultipleCategories: true,
                    exportScope: currentScope,
                    onScopeChanged: (scope) {
                      setState(() {
                        currentScope = scope;
                      });
                    },
                    onPrintPdf: () {},
                    onShareImage: () {},
                  );
                },
              ),
            ),
          ),
        );

        expect(find.text('全試合形式一括出力'), findsOneWidget);
        expect(currentScope, OfficialRecordExportScope.current);

        await tester.tap(find.text('全試合形式一括出力'));
        await tester.pump();

        expect(currentScope, OfficialRecordExportScope.all);
      });
    });

    group('BunaiksenTeamScoreTable ウィジェットテスト', () {
      testWidgets('部内戦チームスコアテーブルの対戦表が正しく描画されること', (tester) async {
        const match1 = MatchModel(
          id: 'm1',
          tournamentId: 't1',
          matchType: '先鋒',
          redName: '先鋒チーム : 山田',
          whiteName: '相手チーム : 田中',
          redScore: 2,
          whiteScore: 0,
          status: 'finished',
          note: 'リーグ1',
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: BunaiksenTeamScoreTable(
                  groupName: 'グループA',
                  matches: [match1],
                  cardColor: Colors.white,
                  isDark: false,
                ),
              ),
            ),
          ),
        );

        expect(find.text('先鋒'), findsOneWidget);
        expect(find.textContaining('先鋒チーム vs 相手チーム'), findsOneWidget);
        expect(find.text('赤'), findsOneWidget);
        expect(find.text('白'), findsOneWidget);
      });

      testWidgets('チーム結果セルが勝敗状態に応じて正しく描画されること', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BunaiksenTeamScoreTableRowBuilder.teamResultCell(
                'red',
                false,
                true,
              ),
            ),
          ),
        );

        expect(find.text('勝'), findsOneWidget);
        expect(find.text('負'), findsOneWidget);
      });

      testWidgets('サマリーセルが取得本数と勝利数に応じて正しく描画されること', (tester) async {
        const match = MatchModel(
          id: 'm1',
          tournamentId: 't1',
          redName: 'A',
          whiteName: 'B',
          matchType: '先鋒',
          redScore: 2,
          whiteScore: 0,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BunaiksenTeamScoreTableRowBuilder.summaryCell(
                const [match],
                true,
                false,
              ),
            ),
          ),
        );

        expect(find.text('2\n--\n1'), findsOneWidget);
      });
    });

    group('BunaiksenKachinukiRecordCard ウィジェットテスト', () {
      testWidgets('勝ち抜き戦カードのタイトルおよび描画領域が正しく描画されること', (tester) async {
        const match = MatchModel(
          id: 'match1',
          redName: '赤チーム: 先鋒',
          whiteName: '白チーム: 先鋒',
          matchType: '勝ち抜き戦',
          isKachinuki: true,
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) {
                    return BunaiksenKachinukiRecordCard(
                      matches: const [match],
                      isDark: false,
                      ref: ref,
                    );
                  },
                ),
              ),
            ),
          ),
        );

        expect(find.text('勝ち抜き戦：赤チーム vs 白チーム'), findsOneWidget);
        expect(find.byType(CustomPaint), findsWidgets);
      });

      testWidgets('試合一覧が空の場合は勝ち抜きタイトルが描画されないこと', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) {
                    return BunaiksenKachinukiRecordCard(
                      matches: const [],
                      isDark: false,
                      ref: ref,
                    );
                  },
                ),
              ),
            ),
          ),
        );

        expect(find.text('勝ち抜き戦：赤チーム vs 白チーム'), findsNothing);
      });
    });
  });
}
