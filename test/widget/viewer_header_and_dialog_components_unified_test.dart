import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/viewer_qr_bottom_sheet.dart';
import 'package:kendo_os/features/viewer/components/viewer_bunaiksen_category_content.dart';
import 'package:kendo_os/features/viewer/components/viewer_bunaiksen_header_actions.dart';
import 'package:kendo_os/features/viewer/components/viewer_bunaiksen_match_card.dart';
import 'package:kendo_os/features/viewer/components/viewer_bunaiksen_share_dialog.dart';
import 'package:kendo_os/features/viewer/components/viewer_home_header_actions.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_category_section_list.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_match_list_search_bar.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_share_dialog.dart';
import 'package:kendo_os/features/viewer/screens/viewer_bunaiksen_official_record_screen.dart';
import 'package:kendo_os/features/viewer/services/viewer_bunaiksen_export_service.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Widget] 観戦者画面 ヘッダー・検索バー・共有ダイアログ・部内戦コンポーネント統合検証テスト', () {
    testWidgets('ViewerMatchCardにおいて 部内戦カードのスコアと選手名が正しく描画されること', (
      tester,
    ) async {
      final match = MatchModel(
        id: 'm1',
        matchOrder: 1,
        redName: '佐藤',
        whiteName: '鈴木',
        redScore: 2,
        whiteScore: 0,
        status: 'finished',
        matchType: '個人戦',
        note: '予選',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ViewerBunaiksenMatchCard(
              match: match,
              index: 0,
              tournamentId: 'bunaiksen_20260821',
              dojoId: 'dojo1',
            ),
          ),
        ),
      );

      expect(find.text('佐藤'), findsOneWidget);
      expect(find.text('鈴木'), findsOneWidget);
      expect(find.text('第1試合'), findsOneWidget);

      final zeroMatch = MatchModel(
        id: 'm2',
        matchOrder: 2,
        redName: '佐藤',
        whiteName: '鈴木',
        redScore: 0,
        whiteScore: 0,
        status: 'waiting',
        matchType: '個人戦',
      );
      final widget = ViewerBunaiksenMatchCard.buildScoreMarks(zeroMatch, false);
      expect(widget, isNotNull);
    });

    testWidgets('ViewerBunaiksenCategoryContentにおいて 試合カード一覧と操作ボタンが描画されること', (
      tester,
    ) async {
      final matches = [
        MatchModel(
          id: 'test_m1',
          matchType: '先鋒',
          redName: '東京道場:山田 太郎',
          whiteName: '大阪道場:佐藤 次郎',
          status: 'finished',
          redScore: 2,
          whiteScore: 0,
          order: 1,
        ),
      ];

      final themeColors = AppThemeColors.ofMode(
        isDark: false,
        mode: 'bunaiksen_viewer',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  return ViewerBunaiksenCategoryContent(
                    category: '一般の部',
                    groupsMap: {'group1': matches},
                    cardColor: Colors.white,
                    themeColors: themeColors,
                    isDark: false,
                    isExporting: false,
                    isExportingController: ref.watch(
                      isExportingProvider.notifier,
                    ),
                    tDate: '2026年08月20日',
                    exportService: const ViewerBunaiksenExportService(),
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('PDF印刷'), findsOneWidget);
      expect(find.text('画像シェア'), findsOneWidget);
      expect(find.text('東京道場 vs 大阪道場'), findsOneWidget);
    });

    testWidgets('ViewerBunaiksenShareDialogにおいて 共有リンクが正しく表示されること', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentDojoIdProvider.overrideWith((ref) => 'org_dojo_test'),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  return ElevatedButton(
                    onPressed: () {
                      ViewerBunaiksenShareDialog.show(
                        context,
                        ref,
                        tournamentId: 't-12345',
                        dateDisplay: '2026年10月2日',
                      );
                    },
                    child: const Text('共有ダイアログを開く'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('共有ダイアログを開く'));
      await tester.pumpAndSettle();

      expect(find.text('2026年10月2日 観戦リンク'), findsOneWidget);
      expect(find.text('部内戦ID: t-12345'), findsOneWidget);
      expect(find.text('LINEやSNSでURLを送る'), findsOneWidget);
    });

    testWidgets('ViewerCategorySectionListにおいて 部門一覧が正しく描画されること', (
      tester,
    ) async {
      const match = MatchModel(
        id: 'm1',
        tournamentId: 't1',
        category: '小学生低学年',
        matchType: '先鋒',
        redName: '練馬道場 : 山田',
        whiteName: '杉並道場 : 田中',
        redScore: 2,
        whiteScore: 0,
        status: 'finished',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ViewerCategorySectionList(
                entries: [
                  MapEntry('小学生低学年', [match]),
                ],
                ownTeams: ['練馬道場'],
                sanitizedQuery: '',
                matchedMatchIds: {},
                matchedGroupNames: {},
                isDark: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('小学生低学年'), findsOneWidget);
    });

    testWidgets('ViewerHomeHeaderActionsにおいて QR共有ボタンが描画されダイアログが正しく開くこと', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData(
              extensions: [
                AppThemeColors.ofMode(isDark: false, mode: 'normal'),
              ],
            ),
            home: Scaffold(
              appBar: AppBar(
                actions: const [
                  ViewerHomeHeaderActions(
                    tournamentId: 't1',
                    isDark: false,
                    iconColor: Colors.black,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final qrBtn = find.byIcon(Icons.qr_code_2);
      expect(qrBtn, findsOneWidget);

      await tester.tap(qrBtn);
      await tester.pumpAndSettle();
      expect(find.byType(ViewerShareDialog), findsOneWidget);
    });

    testWidgets('ViewerBunaiksenHeaderActionsにおいて カレンダーボタンが描画され詳細メニューが開くこと', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData(
              extensions: [
                AppThemeColors.ofMode(isDark: false, mode: 'bunaiksen_viewer'),
              ],
            ),
            home: Scaffold(
              appBar: AppBar(
                actions: const [
                  ViewerBunaiksenHeaderActions(
                    tournamentId: 'bunaiksen_20260829',
                    dateDisplay: '2026年8月29日',
                    dojoId: 'd1',
                    isDark: false,
                    isQrAccess: false,
                    availableDates: {'20260829'},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.calendar_month), findsOneWidget);
      final moreBtn = find.byIcon(Icons.more_horiz_rounded);
      expect(moreBtn, findsOneWidget);

      await tester.tap(moreBtn);
      await tester.pumpAndSettle();

      expect(find.text('部内戦 成績一覧'), findsOneWidget);
      expect(find.text('観戦リンクを共有する'), findsOneWidget);
      expect(find.text('表示設定'), findsOneWidget);
    });

    testWidgets('ViewerMatchListSearchBarにおいて 検索ボタンおよびソートボタンが正しく動作すること', (
      tester,
    ) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');
      bool toggledSort = false;
      bool openedSearch = false;
      bool toggledExpandAll = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(extensions: [themeColors]),
          home: Scaffold(
            body: ViewerMatchListSearchBar(
              isSearchVisible: false,
              searchQuery: '',
              isSortAscending: true,
              isAllExpanded: false,
              onSearchQueryChanged: (_) {},
              onOpenSearch: () => openedSearch = true,
              onCloseSearch: () {},
              onToggleSort: () => toggledSort = true,
              onToggleExpandAll: () => toggledExpandAll = true,
            ),
          ),
        ),
      );

      expect(find.text('試合リスト'), findsOneWidget);
      expect(find.text('カテゴリ昇順'), findsOneWidget);
      expect(find.text('全て開く'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);

      await tester.tap(find.text('カテゴリ昇順'));
      await tester.pump();
      expect(toggledSort, isTrue);

      await tester.tap(find.text('全て開く'));
      await tester.pump();
      expect(toggledExpandAll, isTrue);

      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();
      expect(openedSearch, isTrue);
    });

    testWidgets('ViewerQrBottomSheetにおいて QRコードと共有ボタンが正常に描画されること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ViewerQrBottomSheet(tournamentId: 'test_tournament_123'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('観戦用QRコード ＆ 速報共有'), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text('大会ID: test_tournament_123'), findsOneWidget);
      expect(find.text('LINEやSNSで観戦URLを送る'), findsOneWidget);
      expect(find.text('観戦URLをコピー'), findsOneWidget);
    });
  });
}
