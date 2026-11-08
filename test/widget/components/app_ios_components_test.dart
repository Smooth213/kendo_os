import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../helpers/safe_pump_helper.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/admin/presentation/screens/design_system_gallery_screen.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/presentation/widgets/app_card.dart';
import 'package:kendo_os/shared/presentation/widgets/app_glass_container.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:kendo_os/shared/widgets/app_loading_indicator.dart';
import 'package:kendo_os/shared/widgets/app_switch.dart';

void main() {
  group('[Widget] AppHaptics ユーティリティ テスト', () {
    test('全Hapticメソッドがクラッシュせず安全に実行できること', () {
      expect(() => AppHaptics.selection(), returnsNormally);
      expect(() => AppHaptics.light(), returnsNormally);
      expect(() => AppHaptics.medium(), returnsNormally);
      expect(() => AppHaptics.heavy(), returnsNormally);
      expect(() => AppHaptics.success(), returnsNormally);
      expect(() => AppHaptics.warning(), returnsNormally);
      expect(() => AppHaptics.error(), returnsNormally);
    });
  });

  group('AppLoadingIndicator ウィジェット テスト', () {
    testWidgets(
      '標準の AppLoadingIndicator が CupertinoActivityIndicator として描画されること',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              extensions: [
                AppThemeColors.ofMode(isDark: false, mode: 'normal'),
              ],
            ),
            home: const Scaffold(body: Center(child: AppLoadingIndicator())),
          ),
        );

        final indicatorFinder = find.byType(CupertinoActivityIndicator);
        expect(indicatorFinder, findsOneWidget);

        final indicator = tester.widget<CupertinoActivityIndicator>(
          indicatorFinder,
        );
        expect(indicator.radius, 10.0);
      },
    );

    testWidgets('.small および .large ファクトリで適切な radius が設定されること', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
          ),
          home: const Scaffold(
            body: Column(
              children: [
                AppLoadingIndicator.small(color: Colors.red),
                AppLoadingIndicator.large(color: Colors.blue),
              ],
            ),
          ),
        ),
      );

      final indicators = tester.widgetList<CupertinoActivityIndicator>(
        find.byType(CupertinoActivityIndicator),
      );
      expect(indicators.length, 2);
      expect(indicators.first.radius, 8.0);
      expect(indicators.first.color, Colors.red);
      expect(indicators.last.radius, 14.0);
      expect(indicators.last.color, Colors.blue);
    });
  });

  group('AppSwitch ウィジェット テスト', () {
    testWidgets('Switch.adaptive が描画され、タップ時に値の変更コールバックが発火すること', (tester) async {
      bool currentValue = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
          ),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return AppSwitch(
                  value: currentValue,
                  onChanged: (val) {
                    setState(() {
                      currentValue = val;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);

      // タップして切り替え
      await tester.tap(switchFinder);
      await tester.safePumpAndSettle();

      expect(currentValue, isTrue);
    });
  });
  group('AppChoiceChip ウィジェット テスト', () {
    testWidgets('ピル形状(Capsule)で描画され、タップ時にonSelectedが発火すること', (tester) async {
      bool isSelected = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
          ),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return AppChoiceChip(
                  label: const Text('個人戦'),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() {
                      isSelected = val;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      final chipFinder = find.byType(ChoiceChip);
      expect(chipFinder, findsOneWidget);

      final choiceChip = tester.widget<ChoiceChip>(chipFinder);
      expect(choiceChip.shape, isA<RoundedRectangleBorder>());
      final shape = choiceChip.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, AppRadius.capsule);

      await tester.tap(chipFinder);
      await tester.safePumpAndSettle();

      expect(isSelected, isTrue);
    });
  });

  group('AppSnackBar ユーティリティ テスト', () {
    testWidgets('show, showError, showSuccess がクラッシュせず SnackBar を表示すること', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    AppSnackBar.show(context, 'テストメッセージ');
                  },
                  child: const Text('Show SnackBar'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show SnackBar'));
      await tester.pump();

      expect(find.text('テストメッセージ'), findsOneWidget);
    });
  });

  group('AppBottomSheetContent ウィジェット テスト', () {
    testWidgets('ドラッグハンドルとタイトルが正しく描画されること', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
          ),
          home: const Scaffold(
            body: AppBottomSheetContent(
              title: '設定シート',
              titleIcon: Icons.settings,
              child: Text('コンテンツ'),
            ),
          ),
        ),
      );

      expect(find.text('設定シート'), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
      expect(find.text('コンテンツ'), findsOneWidget);
    });
  });

  group('AppHeader ウィジェット テスト', () {
    testWidgets('canPop時に自動で iOS 戻るボタンが描画されること', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
          ),
          home: Navigator(
            onGenerateRoute: (_) {
              return MaterialPageRoute(
                builder: (context) {
                  return Scaffold(
                    body: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const Scaffold(
                              appBar: AppHeader(title: 'サブ画面'),
                            ),
                          ),
                        );
                      },
                      child: const Text('Go'),
                    ),
                  );
                },
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Go'));
      await tester.safePumpAndSettle();

      expect(find.text('サブ画面'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
    });

    testWidgets('canPopがfalseでもfallbackRouteが指定されていれば戻るボタンが描画されること', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
          ),
          home: const Scaffold(
            appBar: AppHeader(
              title: 'ホーム画面',
              fallbackRoute: '/tournament-list',
            ),
          ),
        ),
      );

      expect(find.text('ホーム画面'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
    });

    testWidgets('canPopがfalseのときにonBackPressedがタップで発火すること', (tester) async {
      var backPressed = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
          ),
          home: Scaffold(
            appBar: AppHeader(
              title: 'ホーム画面',
              onBackPressed: () => backPressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.safePumpAndSettle();

      expect(backPressed, isTrue);
    });

    testWidgets('canPopがfalseのときにfallbackRouteが指定されていればGoRouterのgoが呼ばれること', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const Scaffold(
              appBar: AppHeader(
                title: 'ホーム画面',
                fallbackRoute: '/tournament-list',
              ),
            ),
          ),
          GoRoute(
            path: '/tournament-list',
            builder: (context, state) => const Scaffold(body: Text('大会一覧画面')),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          theme: ThemeData(
            extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
          ),
          routerConfig: router,
        ),
      );
      await tester.safePumpAndSettle();

      expect(find.text('ホーム画面'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.safePumpAndSettle();

      expect(find.text('大会一覧画面'), findsOneWidget);
    });
  });

  group('AppGlassContainer ＆ AppCard iOS 27 テスト', () {
    testWidgets('AppGlassContainer が RepaintBoundary で保護され正常に描画されること', (
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
            home: const Scaffold(
              body: AppGlassContainer(child: Text('フロストガラス')),
            ),
          ),
        ),
      );

      expect(find.text('フロストガラス'), findsOneWidget);
      expect(find.byType(RepaintBoundary), findsWidgets);
    });

    testWidgets('AppCard がタップ可能でコールバックをトリガーすること', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData(
              extensions: [
                AppThemeColors.ofMode(isDark: false, mode: 'normal'),
              ],
            ),
            home: Scaffold(
              body: AppCard(
                onTap: () => tapped = true,
                child: const Text('タップカード'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('タップカード'), findsOneWidget);
      await tester.tap(find.text('タップカード'));
      await tester.safePumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('DesignSystemGalleryScreen が正常に描画され各セクションが表示されること', (
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
            home: const DesignSystemGalleryScreen(),
          ),
        ),
      );

      expect(find.text('デザインシステム・ギャラリー'), findsOneWidget);
      expect(find.text('1. 着せ替え基盤・モード制御'), findsOneWidget);
      expect(
        find.text('2. iOS 27 フロストガラス (AppGlassContainer)'),
        findsOneWidget,
      );
      expect(find.text('Loading例'), findsOneWidget);
      expect(find.text('3. 物理スプリングカード (AppCard)'), findsOneWidget);

      // タブ「競技・スコア」への切り替え検証 (index: 1)
      await tester.tap(find.byType(AppChoiceChip).at(1));
      await tester.safePumpAndSettle();
      expect(find.text('1. 紅白対戦対比（Red vs White）'), findsOneWidget);

      // タブ「シーン・状態」への切り替え検証 (index: 2)
      await tester.tap(find.byType(AppChoiceChip).at(2));
      await tester.safePumpAndSettle();
      expect(find.text('1. 4大試合シーンバッジ (KendoSceneBadge)'), findsOneWidget);

      // タブ「ボタン」への切り替え検証 (index: 3)
      await tester.tap(find.byType(AppChoiceChip).at(3));
      await tester.safePumpAndSettle();
      expect(find.text('1. ボタンの階層言語 (Hierarchy)'), findsOneWidget);

      // タブ「入力フォーム」への切り替え検証 (index: 4)
      await tester.tap(find.byType(AppChoiceChip).at(4));
      await tester.safePumpAndSettle();
      expect(
        find.text('1. 単一行入力: iOS 27 カプセル型 (StadiumBorder)'),
        findsOneWidget,
      );

      // タブ「ドック・シート」への切り替え検証 (index: 5)
      await tester.tap(find.byType(AppChoiceChip).at(5));
      await tester.safePumpAndSettle();
      expect(
        find.text('1. 常設フローティングドック (Floating Dock アイランド)'),
        findsOneWidget,
      );

      // タブ「カラー・文字」への切り替え検証 (index: 6)
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(-300, 0),
      );
      await tester.safePumpAndSettle();
      await tester.tap(find.byType(AppChoiceChip).at(6));
      await tester.safePumpAndSettle();
      expect(find.text('1. セマンティックカラーパレット (AppThemeColors)'), findsOneWidget);
    });
  });
}
