import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_header_widgets.dart';
import 'package:kendo_os/features/viewer/components/viewer_bunaiksen_header_actions.dart';
import 'package:kendo_os/features/viewer/components/viewer_home_header_actions.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';

void main() {
  group('🛡️ AppBar タイトル文字切れ防止・Moreメニュー検証テスト', () {
    testWidgets('1. 幅狭端末(375pt)において試合画面ヘッダーが文字切れせずMoreメニューが動作すること', (
      tester,
    ) async {
      // iPhone SE 等の 375px 幅をシミュレート
      tester.view.physicalSize = const Size(375 * 2.0, 667 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final testMatch = MatchModel(
        id: 'test_match_1',
        tournamentId: 'test_tournament',
        category: '小学生の部',
        matchType: '中堅',
        redName: '道上剣友会',
        whiteName: '相手道場チーム',
        status: 'in_progress',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData(
              extensions: [
                AppThemeColors.ofMode(isDark: false, mode: 'normal'),
              ],
            ),
            home: Scaffold(
              appBar: AppHeader(
                centerTitle: true,
                titleWidget: MatchHeaderTitle(match: testMatch),
                actions: [MatchHeaderActions(match: testMatch)],
              ),
              body: const SizedBox.expand(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // タイトルと選手名が表示されていること
      expect(find.text('小学生の部 - 中堅'), findsOneWidget);
      expect(find.text('道上剣友会 vs 相手道場チーム'), findsOneWidget);

      // 右側アクションが三点リーダー (Icons.more_horiz_rounded) 1つであること
      expect(find.byIcon(Icons.more_horiz_rounded), findsOneWidget);

      // 三点リーダーをタップしてメニューが展開すること
      await tester.tap(find.byIcon(Icons.more_horiz_rounded));
      await tester.pumpAndSettle();

      expect(find.text('スコア左右入れ替え'), findsOneWidget);
      expect(find.text('途中棄権の記録'), findsOneWidget);
      expect(find.text('マニュアル・ヘルプ'), findsOneWidget);
      expect(find.text('試合一覧へ戻る'), findsOneWidget);
      expect(find.text('アプリ設定'), findsOneWidget);
    });

    testWidgets('2. 大会ホーム画面のAppHeaderが375pt幅で「大会ホーム」タイトルを広々と描画できること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(375 * 2.0, 667 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData(
              extensions: [
                AppThemeColors.ofMode(isDark: false, mode: 'normal'),
              ],
            ),
            home: Scaffold(
              appBar: AppHeader(
                title: '大会ホーム',
                actions: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.qr_code_2),
                    onPressed: () {},
                  ),
                ],
              ),
              body: const SizedBox.expand(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final titleFinder = find.text('大会ホーム');
      expect(titleFinder, findsOneWidget);

      // タイトルウィジェットの幅が十分確保されていること
      final titleSize = tester.getSize(titleFinder);
      expect(titleSize.width, greaterThan(0));
    });

    testWidgets('3. 公式記録画面のAppHeaderが375pt幅でタイトルを広々と描画できること', (tester) async {
      tester.view.physicalSize = const Size(375 * 2.0, 667 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData(
              extensions: [
                AppThemeColors.ofMode(isDark: false, mode: 'normal'),
              ],
            ),
            home: const Scaffold(
              appBar: AppHeader(
                title: '第1回 練成大会 公式記録',
                actions: [Icon(Icons.help_outline), SizedBox(width: 8)],
              ),
              body: SizedBox.expand(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final titleFinder = find.text('第1回 練成大会 公式記録');
      expect(titleFinder, findsOneWidget);
    });

    testWidgets(
      '4. iOSネイティブのステータスバー・ノッチ領域(padding.top: 47pt)が存在する場合、AppBarが重ならず正しくオフセットされること',
      (tester) async {
        // iPhone 14 Pro 相当のステータスバーパディング (47pt) をシミュレート
        tester.view.physicalSize = const Size(393 * 3.0, 852 * 3.0);
        tester.view.devicePixelRatio = 3.0;
        tester.view.padding = const FakeViewPadding(top: 47 * 3.0);
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetPadding();
        });

        final testMatch = MatchModel(
          id: 'test_match_safe_area',
          tournamentId: 'test_tournament',
          category: '小学生低学年の部',
          matchType: '先鋒',
          redName: '道上剣友会A',
          whiteName: '相手道場A',
          status: 'in_progress',
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: ThemeData(
                extensions: [
                  AppThemeColors.ofMode(isDark: false, mode: 'normal'),
                ],
              ),
              home: Scaffold(
                appBar: AppHeader(
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new),
                    onPressed: () {},
                  ),
                  centerTitle: true,
                  titleWidget: MatchHeaderTitle(match: testMatch),
                  actions: [MatchHeaderActions(match: testMatch)],
                ),
                body: const SizedBox.expand(),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // タイトルおよび戻るボタン、Moreボタンの中心がステータスバー(47pt)より下に配置され被らないこと
        final titleTop = tester.getTopLeft(find.text('小学生低学年の部 - 先鋒')).dy;
        expect(titleTop, greaterThanOrEqualTo(47.0));

        final backButtonTop = tester
            .getTopLeft(find.byIcon(Icons.arrow_back_ios_new))
            .dy;
        expect(backButtonTop, greaterThanOrEqualTo(47.0));

        final moreButtonTop = tester
            .getTopLeft(find.byIcon(Icons.more_horiz_rounded))
            .dy;
        expect(moreButtonTop, greaterThanOrEqualTo(47.0));
      },
    );

    testWidgets(
      '5. 観戦席ホーム画面(ViewerHomeScreen)が375pt幅端末で「大会ホーム (観客席)」タイトルを広々と描画し、Moreメニューに共有・設定・FAQが集約されていること',
      (tester) async {
        tester.view.physicalSize = const Size(375 * 2.0, 667 * 2.0);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: ThemeData(
                extensions: [
                  AppThemeColors.ofMode(isDark: false, mode: 'normal'),
                ],
              ),
              home: Scaffold(
                appBar: AppHeader(
                  title: '大会ホーム (観客席)',
                  actions: [
                    ViewerHomeHeaderActions(
                      tournamentId: 'test_t1',
                      isDark: false,
                      iconColor: const Color(0xFF000000),
                    ),
                  ],
                ),
                body: const SizedBox.expand(),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // タイトルが文字切れせず描画されていること
        expect(find.text('大会ホーム (観客席)'), findsOneWidget);

        // Moreメニューボタンが存在すること
        expect(find.byIcon(Icons.more_horiz_rounded), findsOneWidget);

        // Moreメニューをタップして展開
        await tester.tap(find.byIcon(Icons.more_horiz_rounded));
        await tester.pumpAndSettle();

        expect(find.text('大会を共有する'), findsOneWidget);
        expect(find.text('表示設定'), findsOneWidget);
        expect(find.text('観戦ヘルプ・FAQ'), findsOneWidget);
      },
    );

    testWidgets(
      '6. 部内戦観客席ホーム(ViewerBunaiksenHomeScreen)が375pt幅端末でタイトルを広々と描画し、Moreメニューに成績一覧・共有・設定が集約されていること',
      (tester) async {
        tester.view.physicalSize = const Size(375 * 2.0, 667 * 2.0);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: ThemeData(
                extensions: [
                  AppThemeColors.ofMode(isDark: false, mode: 'normal'),
                ],
              ),
              home: Scaffold(
                appBar: AppHeader(
                  title: '2026/08/29 の記録 (観戦)',
                  actions: const [
                    ViewerBunaiksenHeaderActions(
                      tournamentId: 'bunaiksen_20260829',
                      dateDisplay: '2026/08/29',
                      dojoId: 'd1',
                      isDark: false,
                      isQrAccess: false,
                      availableDates: {},
                    ),
                  ],
                ),
                body: const SizedBox.expand(),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('2026/08/29 の記録 (観戦)'), findsOneWidget);
        expect(find.byIcon(Icons.more_horiz_rounded), findsOneWidget);

        await tester.tap(find.byIcon(Icons.more_horiz_rounded));
        await tester.pumpAndSettle();

        expect(find.text('部内戦 成績一覧'), findsOneWidget);
        expect(find.text('観戦リンクを共有する'), findsOneWidget);
        expect(find.text('表示設定'), findsOneWidget);
      },
    );
  });
}
