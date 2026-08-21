import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_rule_summary_card.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  testWidgets('MatchFormatRuleSummaryCard renders match rule details', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MatchFormatRuleSummaryCard(
              displayRuleName: '🏆 本戦ルール',
              isAdvanced: false,
              themeColors: AppThemeColors.ofMode(isDark: false, mode: 'normal'),
              isRenseikai: false,
              renseikaiType: '試合数制',
              matchTime: 3.0,
              overallTimeMinutes: '30',
              matchType: '団体戦',
              isRunningTime: false,
              isIpponShobu: false,
              ipponLimit: 2,
              hansokuLimit: 2,
              extensionText: 'あり (2分 / 1回)',
              hasHantei: true,
              kachinukiUnlimitedType: 'なし',
              hasLeagueDaihyo: true,
              isDaihyoIpponShobu: true,
              daihyoMatchTime: 2.0,
              daihyoHasExtension: true,
              daihyoEnchoTime: 2.0,
              daihyoEnchoCount: 1,
              daihyoHasHantei: false,
              winPoint: 3,
              lossPoint: 0,
              drawPoint: 1,
              formatMinutesText: (m) => '${m.toInt()}分',
              buildSectionHeader: (title, color) => Text(title),
            ),
          ),
        ),
      ),
    );

    expect(find.text('現在適用中のルール: 🏆 本戦ルール'), findsOneWidget);
    expect(find.text('試合方式'), findsOneWidget);
    expect(find.text('団体戦'), findsOneWidget);
    expect(find.text('勝負方式'), findsOneWidget);
    expect(find.text('三本勝負 (2本先取)'), findsOneWidget);
    expect(find.text('代表戦'), findsOneWidget);
    expect(find.text('あり (一本勝負)'), findsOneWidget);
  });
}
