import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_rule_summary_card.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import '../helpers/contrast_test_helper.dart';

Widget _buildThemedApp({
  required Widget child,
  required bool isDark,
  String mode = 'normal',
}) {
  final themeColors = AppThemeColors.ofMode(isDark: isDark, mode: mode);
  final themeData = isDark ? ThemeData.dark() : ThemeData.light();

  return MaterialApp(
    theme: themeData.copyWith(
      scaffoldBackgroundColor: themeColors.scaffoldBackground,
      extensions: [themeColors],
    ),
    home: Scaffold(
      backgroundColor: themeColors.scaffoldBackground,
      body: Center(child: child),
    ),
  );
}

void main() {
  group('[Widget] 視認性コントラスト3層防衛 共通コンポーネント完全検証テスト', () {
    testWidgets('白背景に白文字の不可視テキストが正しく検知・遮断されること', (WidgetTester tester) async {
      // 意図的に白背景に白文字（不可視）を配置
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.white,
            body: Container(
              color: Colors.white,
              child: const Text(
                '見えない白文字',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      );

      // expectValidThemeContrast がこれを確実に検知して例外を投げることを検証
      expect(
        () async => await expectValidThemeContrast(tester),
        throwsA(isA<TestFailure>()),
      );
    });

    testWidgets('MatchRuleSummaryCard がライトモードで WCAG コントラスト基準を満たしていること', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _buildThemedApp(
          isDark: false,
          child: MatchRuleSummaryCard(
            matchType: '個人戦',
            currentRule: const MatchRule(
              matchTimeMinutes: 3.0,
              isIpponShobu: false,
            ),
            matchTime: 3.0,
            isIpponShobu: false,
            hasHantei: true,
            primaryAccent: const Color(0xFF303F9F),
            isDark: false,
            textColor: Colors.black,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1行で画面内の全文字の視認性コントラストを自動検証
      await expectValidThemeContrast(tester);
    });

    testWidgets('MatchRuleSummaryCard がダークモードで WCAG コントラスト基準を満たしていること', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _buildThemedApp(
          isDark: true,
          child: MatchRuleSummaryCard(
            matchType: '個人戦',
            currentRule: const MatchRule(
              matchTimeMinutes: 3.0,
              isIpponShobu: false,
            ),
            matchTime: 3.0,
            isIpponShobu: false,
            hasHantei: true,
            primaryAccent: const Color(0xFF5C6BC0),
            isDark: true,
            textColor: Colors.white,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1行で画面内の全文字の視認性コントラストを自動検証
      await expectValidThemeContrast(tester);
    });

    testWidgets('ElevatedButton と PrimaryAccent の組み合わせがライト＆ダークで高コントラストであること', (
      WidgetTester tester,
    ) async {
      for (final isDark in [false, true]) {
        final themeColors = AppThemeColors.ofMode(
          isDark: isDark,
          mode: 'normal',
        );

        await tester.pumpWidget(
          _buildThemedApp(
            isDark: isDark,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColors.primaryAccent,
                foregroundColor: themeColors.onPrimaryAccent,
              ),
              onPressed: () {},
              child: const Text('大会を保存する'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await expectValidThemeContrast(tester);
      }
    });
  });
}
