import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/services/team_match_calculator.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/official_record_export_bar.dart';
import 'package:kendo_os/features/viewer/components/official_record_action_button.dart';
import 'package:kendo_os/features/viewer/components/viewer_official_record_export_bar.dart';
import 'package:kendo_os/shared/application/projections/tournament_projection.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/shared/widgets/app_switch.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Widget] 公式記録エクスポートバーおよびアクションコンポーネント統合テスト', () {
    group('OfficialRecordActionButton ウィジェットテスト', () {
      testWidgets('アイコンとラベルが表示されタップ時にコールバックが正常に実行されること', (
        WidgetTester tester,
      ) async {
        bool tapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: OfficialRecordActionButton(
                icon: Icons.picture_as_pdf,
                label: 'PDF出力',
                color: Colors.red,
                onTap: () {
                  tapped = true;
                },
              ),
            ),
          ),
        );

        expect(find.text('PDF出力'), findsOneWidget);
        expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);

        await tester.tap(find.byType(OfficialRecordActionButton));
        await tester.pumpAndSettle();

        expect(tapped, isTrue);
      });
    });

    group('OfficialRecordExportBar ウィジェットテスト', () {
      testWidgets('3つのエクスポートボタン一覧が描画されコールバックが正しく動作すること', (
        WidgetTester tester,
      ) async {
        bool pdfTapped = false;
        bool imageTapped = false;
        bool csvTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: OfficialRecordExportBar(
                isExporting: false,
                onPdfPressed: () => pdfTapped = true,
                onImagePressed: () => imageTapped = true,
                onCsvPressed: () => csvTapped = true,
                isDark: false,
              ),
            ),
          ),
        );

        expect(find.text('PDF'), findsOneWidget);
        expect(find.text('画像'), findsOneWidget);
        expect(find.text('CSV'), findsOneWidget);

        await tester.tap(find.text('PDF'));
        expect(pdfTapped, isTrue);

        await tester.tap(find.text('画像'));
        expect(imageTapped, isTrue);

        await tester.tap(find.text('CSV'));
        expect(csvTapped, isTrue);
      });

      testWidgets('エクスポート実行中は各ボタンが無効化されること', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: OfficialRecordExportBar(isExporting: true, isDark: true),
            ),
          ),
        );

        final pdfButton = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'PDF'),
        );
        expect(pdfButton.enabled, isFalse);
      });

      testWidgets('複数部門が存在しない場合はトグルが非表示になること', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: OfficialRecordExportBar(
                isExporting: false,
                hasMultipleCategories: false,
                isDark: false,
              ),
            ),
          ),
        );

        expect(find.text('全カテゴリを一括出力'), findsNothing);
        expect(find.byType(AppSwitch), findsNothing);
      });

      testWidgets('複数部門が存在する場合はトグルが表示され切り替えが動作すること', (
        WidgetTester tester,
      ) async {
        OfficialRecordExportScope currentScope =
            OfficialRecordExportScope.current;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return OfficialRecordExportBar(
                    isExporting: false,
                    hasMultipleCategories: true,
                    exportScope: currentScope,
                    onScopeChanged: (scope) {
                      setState(() {
                        currentScope = scope;
                      });
                    },
                    isDark: false,
                  );
                },
              ),
            ),
          ),
        );

        expect(find.text('全カテゴリを一括出力'), findsOneWidget);
        expect(find.byType(AppSwitch), findsOneWidget);
        expect(currentScope, OfficialRecordExportScope.current);

        await tester.tap(find.byType(AppSwitch));
        await tester.pump();

        expect(currentScope, OfficialRecordExportScope.all);
      });
    });

    group('ViewerOfficialRecordExportBar ウィジェットテスト', () {
      testWidgets('PDFおよび画像エクスポートボタンが正しく描画されること', (tester) async {
        final proj = TournamentProjection(
          tournament: TournamentModel(
            id: 't1',
            name: 'テスト大会',
            date: DateTime(2026, 8, 20),
            organizationId: 'org1',
            venue: '第一武道場',
          ),
          allMatches: const [],
          categoryToGroupKeys: const {
            '一般の部': ['リーグA'],
          },
          teamMatches: {
            'リーグA': TeamMatchProjection(
              groupName: 'リーグA',
              redTeamName: 'チームA',
              whiteTeamName: 'チームB',
              matchType: 'team',
              note: '',
              isKachinuki: false,
              isLeague: true,
              matches: [],
              result: TeamMatchResult(
                redWins: 0,
                whiteWins: 0,
                redPoints: 0,
                whitePoints: 0,
                allFinished: true,
                hasDaihyo: false,
                isTie: false,
                teamWinner: 'draw',
              ),
            ),
          },
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ViewerOfficialRecordExportBar(
                  category: '一般の部',
                  sortedGroupKeys: const ['リーグA'],
                  proj: proj,
                ),
              ),
            ),
          ),
        );

        expect(
          find.byKey(const Key('viewer_export_pdf_button')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('viewer_export_image_button')),
          findsOneWidget,
        );
        expect(find.text('PDF印刷'), findsOneWidget);
        expect(find.text('画像シェア'), findsOneWidget);
      });
    });
  });
}
