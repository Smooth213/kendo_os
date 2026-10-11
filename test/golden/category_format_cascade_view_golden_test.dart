import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/common/category_cascade_selector_view.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/common/match_format_selector_view.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildFrame({
    required Widget child,
    required bool isDark,
    required double width,
    required double height,
  }) {
    final themeColors = AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
    final theme = (isDark ? ThemeData.dark() : ThemeData.light()).copyWith(
      extensions: [themeColors],
    );

    return MaterialApp(
      theme: theme,
      home: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF121212)
            : const Color(0xFFF8F9FA),
        body: Center(
          child: SizedBox(
            width: width,
            height: height,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  group('[Golden] カテゴリ・試合形式 カスケード階層 視覚的整合性テスト', () {
    testWidgets(
      'モバイル幅(375px)ライトテーマにおいて、小学生カテゴリおよび勝ち抜き戦サブコンテナがオーバーフローなく描画されること',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final themeColors = AppThemeColors.ofMode(
          isDark: false,
          mode: 'normal',
        );

        await tester.pumpWidget(
          buildFrame(
            isDark: false,
            width: 375,
            height: 812,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CategoryCascadeSelectorView(
                  selectedMajorCategory: '小学生',
                  selectedMinorCategory: '高学年',
                  themeColors: themeColors,
                  onCategoryChanged:
                      ({
                        required majorCategory,
                        required minorCategory,
                        customCategoryName,
                      }) {},
                ),
                const SizedBox(height: 24),
                MatchFormatSelectorView(
                  currentMatchType: '勝ち抜き戦（5人制）',
                  themeColors: themeColors,
                  onMatchTypeChanged: (_) {},
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 各要素がレンダリングされていること
        expect(find.byType(CategoryCascadeSelectorView), findsOneWidget);
        expect(find.byType(MatchFormatSelectorView), findsOneWidget);
        expect(find.text('小学生'), findsOneWidget);
        expect(find.text('高学年 (5-6年)'), findsOneWidget);
        expect(find.text('勝ち抜き戦'), findsOneWidget);
        expect(find.text('5人制'), findsOneWidget);

        // レイアウト例外・オーバーフローが発生していないこと
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('デスクトップ幅(1024px)ダークテーマにおいて、その他カテゴリ入力とリーグ戦サブコンテナが破綻なく描画されること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final themeColors = AppThemeColors.ofMode(isDark: true, mode: 'normal');

      await tester.pumpWidget(
        buildFrame(
          isDark: true,
          width: 1024,
          height: 768,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CategoryCascadeSelectorView(
                selectedMajorCategory: 'その他',
                selectedMinorCategory: '自由',
                customCategoryName: '親善東西対抗',
                themeColors: themeColors,
                onCategoryChanged:
                    ({
                      required majorCategory,
                      required minorCategory,
                      customCategoryName,
                    }) {},
              ),
              const SizedBox(height: 24),
              MatchFormatSelectorView(
                currentMatchType: 'リーグ団体戦',
                themeColors: themeColors,
                onMatchTypeChanged: (_) {},
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CategoryCascadeSelectorView), findsOneWidget);
      expect(find.byType(MatchFormatSelectorView), findsOneWidget);
      expect(find.text('その他'), findsOneWidget);
      expect(find.text('親善東西対抗'), findsOneWidget);
      expect(find.text('リーグ戦'), findsOneWidget);
      expect(find.text('団体戦 (5人制)'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });
  });
}
