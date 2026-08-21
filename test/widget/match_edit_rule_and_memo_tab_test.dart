import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_edit_rule_and_memo_tab.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';

void main() {
  testWidgets(
    'MatchEditRuleAndMemoTab renders rule summary and switches correctly',
    (WidgetTester tester) async {
      bool ipponToggled = false;
      bool hanteiToggled = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MatchEditRuleAndMemoTab(
                primaryAccent: AppKendoColors.blueAccent,
                isDark: false,
                textColor: AppKendoColors.pureBlack,
                tournamentId: 't1',
                match: const MatchModel(
                  id: 'm1',
                  tournamentId: 't1',
                  matchType: 'individual',
                  category: '一般の部',
                  redName: '選手A',
                  whiteName: '選手B',
                ),
                selectedPresetKey: 'honsen',
                selectedPresetRule: const MatchRule(
                  matchTimeMinutes: 3.0,
                  isIpponShobu: false,
                  hasHantei: true,
                ),
                matchTime: 3.0,
                isIpponShobu: false,
                hasHantei: true,
                onPresetSelected: (rule, key) {},
                onMatchTimeChanged: (val) {},
                onIpponShobuChanged: (val) {
                  ipponToggled = val;
                },
                onHanteiChanged: (val) {
                  hanteiToggled = val;
                },
              ),
            ),
          ),
        ),
      );

      // Verify summary text
      expect(find.text('🛡️ 適用されるルールの全内訳 (リアルタイム同期)'), findsOneWidget);
      expect(find.text('試合時間: 3分'), findsOneWidget);
      expect(find.text('勝負: 三本勝負 ⚔️'), findsOneWidget);
      expect(find.text('判定: ON ⭕'), findsOneWidget);

      // Toggle switch
      final ipponSwitch = find.widgetWithText(SwitchListTile, '一本勝負にする');
      expect(ipponSwitch, findsOneWidget);
      await tester.tap(ipponSwitch);
      await tester.pump();
      expect(ipponToggled, isTrue);

      final hanteiSwitch = find.widgetWithText(
        SwitchListTile,
        '個人戦の判定（ハンテイ）を適用',
      );
      expect(hanteiSwitch, findsOneWidget);
      await tester.tap(hanteiSwitch);
      await tester.pump();
      expect(hanteiToggled, isFalse);
    },
  );
}
