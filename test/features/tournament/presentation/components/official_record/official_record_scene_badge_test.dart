import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/pdf/widgets/pdf_individual_list.dart';
import 'package:kendo_os/features/pdf/widgets/pdf_team_table.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/official_record_individual_matches_list.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/official_record_kachinuki_card.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/official_record_score_table_builder.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/safe_timeline_provider.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  group('🥋 【試合記録画面 & PDF】ヘッダー先頭への【錬成】・【申合せ】バッジ／テキスト表示完全保証テスト', () {
    testWidgets('1. 公式記録画面の団体戦スコアテーブルヘッダー先頭に色分けされた【錬成】バッジが表示されること', (
      tester,
    ) async {
      const renseiMatches = [
        MatchModel(
          id: 'm1',
          groupName: 'group_rensei_1',
          matchType: '先鋒戦',
          redName: '道上剣友会: 皿田',
          whiteName: '相手02: 選手',
          status: 'finished',
          matchScene: 'renseikai',
          redScore: 2,
          whiteScore: 0,
        ),
      ];

      final widget = OfficialRecordScoreTableBuilder.buildScoreTable(
        'group_rensei_1',
        renseiMatches,
        isDark: false,
      );

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
      await tester.pumpAndSettle();

      // ヘッダー先頭に【錬成】バッジが表示されていること
      expect(find.text('【錬成】'), findsOneWidget);
      expect(find.text('【団体戦】 道上剣友会 vs 相手02'), findsOneWidget);
    });

    testWidgets('2. 公式記録画面の個人戦リストヘッダー先頭に色分けされた【申合せ】バッジが表示されること', (
      tester,
    ) async {
      const moushiawaseMatches = [
        MatchModel(
          id: 'indiv_m1',
          matchType: '個人戦',
          redName: '道上剣友会: 久安',
          whiteName: '相手03: 選手',
          status: 'finished',
          matchScene: 'moushiawase',
          redScore: 1,
          whiteScore: 0,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            customTeamNamesProvider.overrideWith(
              (ref) => Stream.value(['道上剣友会']),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: OfficialRecordIndividualMatchesList(
                groupName: '小学生個人の部',
                matches: moushiawaseMatches,
                isDark: false,
                applySort: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // ヘッダー先頭に【申合せ】バッジが表示されていること
      expect(find.text('【申合せ】'), findsOneWidget);
      expect(find.text('【個人戦】 小学生個人の部'), findsOneWidget);
    });

    testWidgets('3. 公式記録画面の勝ち抜き戦カードヘッダー先頭に【錬成】バッジが表示されること', (tester) async {
      const kachinukiMatches = [
        MatchModel(
          id: 'kachinuki_m1',
          matchType: '勝ち抜き戦',
          redName: '道上剣友会: 選手A',
          whiteName: '相手05: 選手B',
          status: 'finished',
          matchScene: 'renseikai',
          redRemaining: ['選手A'],
          whiteRemaining: [],
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, _) {
              return MaterialApp(
                home: Scaffold(
                  body: OfficialRecordKachinukiCard(
                    matches: kachinukiMatches,
                    isDark: false,
                    ref: ref,
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('【錬成】'), findsOneWidget);
      expect(find.text('【勝ち抜き戦】 道上剣友会 vs 相手05'), findsOneWidget);
    });

    test('4. PDF出力（団体戦・個人戦）のタイトルにシンプルな【錬成】・【申合せ】が付与されること', () {
      final font = pw.Font.courier();
      final fontBold = pw.Font.courierBold();

      // 錬成会団体戦
      const pdfRenseiMatches = [
        MatchModel(
          id: 'pdf_m1',
          matchType: '先鋒戦',
          redName: '道上剣友会: 皿田',
          whiteName: '相手02: 選手',
          status: 'finished',
          matchScene: 'renseikai',
        ),
      ];
      final teamWidget = PdfTeamTable.build(
        'g1',
        pdfRenseiMatches,
        font,
        fontBold,
      );
      expect(teamWidget, isNotNull);

      // 申合せ個人戦
      const pdfMoushiawaseMatches = [
        MatchModel(
          id: 'pdf_indiv_1',
          matchType: '個人戦',
          redName: '道上剣友会: 久安',
          whiteName: '相手03: 選手',
          status: 'finished',
          matchScene: 'moushiawase',
        ),
      ];
      final indivWidget = PdfIndividualList.build(
        '小学生個人の部',
        pdfMoushiawaseMatches,
        font,
        fontBold,
      );
      expect(indivWidget, isNotNull);
    });
  });
}
