import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_detail_bottom_sheet.dart';

void main() {
  group('🛡️ CategoryRuleDetailBottomSheet Widget Tests', () {
    testWidgets('Renders standard rules detail sheet with correct labels', (
      WidgetTester tester,
    ) async {
      final ruleSet = const CategoryRuleSet(
        normalRule: MatchRule(
          matchTimeMinutes: 3.0,
          isEnchoUnlimited: true,
          hasHantei: false,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryRuleDetailBottomSheet(
              categoryName: '中学男子の部',
              ruleSet: ruleSet,
              isDark: false,
            ),
          ),
        ),
      );

      expect(find.text('中学男子の部 のルール設定'), findsOneWidget);
      expect(find.text('通常戦ルール'), findsOneWidget);
      expect(find.text('試合時間'), findsOneWidget);
      expect(find.text('閉じる'), findsOneWidget);
    });

    testWidgets(
      'Renders team match details with representative match settings',
      (WidgetTester tester) async {
        final ruleSet = const CategoryRuleSet(
          matchType: '団体戦',
          normalRule: MatchRule(
            matchTimeMinutes: 4.0,
            hasRepresentativeMatch: true,
            isDaihyoIpponShobu: true,
            daihyoMatchTimeMinutes: 3.0,
            daihyoEnchoCount: -2,
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CategoryRuleDetailBottomSheet(
                categoryName: '高校男子団体の部',
                ruleSet: ruleSet,
                isDark: true,
              ),
            ),
          ),
        );

        expect(find.text('高校男子団体の部 のルール設定'), findsOneWidget);
        expect(find.text('団体戦・チーム設定'), findsOneWidget);
        expect(find.text('代表戦'), findsOneWidget);
        expect(find.text('代表戦勝負形式'), findsOneWidget);
        expect(find.text('代表戦時間'), findsOneWidget);
      },
    );
  });
}
