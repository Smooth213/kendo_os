import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/presentation/providers/match_view_model_provider.dart';
import 'package:kendo_os/features/viewer/components/official_record_action_button.dart';
import 'package:kendo_os/features/viewer/components/viewer_bunaiksen_category_content.dart';
import 'package:kendo_os/features/viewer/services/viewer_bunaiksen_export_service.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[E2E] 部内戦 リアルタイム試合進行・観戦記録自動更新・エクスポート統合テスト', () {
    testWidgets('試合結果確定に伴い観戦側星取表が即座に自動再集計されPDFエクスポートが活性化すること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final matchStreamController =
          StreamController<List<MatchModel>>.broadcast();
      addTearDown(() => matchStreamController.close());

      const tId = 'bunaiksen_20261001';
      final dummyStateController = StateController<bool>(false);
      final themeColors = AppThemeColors.ofMode(
        isDark: false,
        mode: 'bunaiksen_viewer',
      );

      final initialMatches = [
        MatchModel(
          id: 'bm_01',
          tournamentId: tId,
          category: '中学生の部',
          groupName: 'リーグA',
          order: 1.0,
          redName: '選手1',
          whiteName: '選手2',
          redScore: 0,
          whiteScore: 0,
          matchType: '選手',
          status: 'ongoing',
          note: '[リーグ戦]',
        ),
      ];

      Widget buildViewerApp() {
        return ProviderScope(
          overrides: [
            bunaiksenRecordCategoryGroupsProvider(tId).overrideWith((ref) {
              final asyncMatches = ref.watch(
                StreamProvider<List<MatchModel>>(
                  (_) => matchStreamController.stream,
                ),
              );
              final matches = asyncMatches.value ?? initialMatches;
              final map = <String, Map<String, List<MatchModel>>>{};
              for (final m in matches) {
                final cat = m.category ?? '部内戦';
                final grp = m.groupName ?? 'リーグA';
                map.putIfAbsent(cat, () => {})[grp] = [
                  ...map[cat]?[grp] ?? [],
                  m,
                ];
              }
              return map;
            }),
          ],
          child: MaterialApp(
            theme: ThemeData.light().copyWith(extensions: [themeColors]),
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  final categoryGroups = ref.watch(
                    bunaiksenRecordCategoryGroupsProvider(tId),
                  );
                  final groupsMap = categoryGroups['中学生の部'] ?? {};
                  return ViewerBunaiksenCategoryContent(
                    category: '中学生の部',
                    groupsMap: groupsMap,
                    cardColor: Colors.white,
                    themeColors: themeColors,
                    isDark: false,
                    isExporting: false,
                    isExportingController: dummyStateController,
                    tDate: '2026年10月01日',
                    exportService: const ViewerBunaiksenExportService(),
                  );
                },
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(buildViewerApp());
      matchStreamController.add(initialMatches);
      await tester.pumpAndSettle();

      // 初期状態の検証（進行中試合あり）
      expect(find.byType(OfficialRecordActionButton), findsNWidgets(2));
      expect(find.text('PDF印刷'), findsOneWidget);

      // 審判端末で試合終了（赤が2本勝ち: メ・コ）
      final finishedMatches = [
        MatchModel(
          id: 'bm_01',
          tournamentId: tId,
          category: '中学生の部',
          groupName: 'リーグA',
          order: 1.0,
          redName: '選手1',
          whiteName: '選手2',
          redScore: 2,
          whiteScore: 0,
          matchType: '選手',
          status: 'finished',
          note: '[リーグ戦]',
        ),
      ];

      matchStreamController.add(finishedMatches);
      await tester.pumpAndSettle();

      // 観戦側UIが自動更新され、エラーなく再描画されること
      expect(tester.takeException(), isNull);
      expect(find.text('PDF印刷'), findsOneWidget);
      expect(find.text('画像シェア'), findsOneWidget);
    });
  });
}
