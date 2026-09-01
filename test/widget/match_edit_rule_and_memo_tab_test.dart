import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_edit_rule_and_memo_tab.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  testWidgets(
    'MatchEditRuleAndMemoTab renders rule summary and switches correctly',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool ipponToggled = false;
      bool hanteiToggled = false;
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.light().copyWith(extensions: [themeColors]),
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
                isRunningTime: false,
                isIpponShobu: false,
                hasExtension: true,
                enchoTime: 2.0,
                enchoCount: 1,
                isEnchoUnlimited: false,
                hasHantei: true,
                hasRepresentativeMatch: false,
                isDaihyoIpponShobu: true,
                daihyoHasExtension: true,
                daihyoEnchoTime: 3.0,
                daihyoEnchoCount: -2,
                isDaihyoEnchoUnlimited: true,
                daihyoHasHantei: false,
                renseikaiType: '一試合制',
                onPresetSelected: (rule, key) {},
                onMatchTimeChanged: (val) {},
                onRunningTimeChanged: (_) {},
                onIpponShobuChanged: (val) {
                  ipponToggled = val;
                },
                onExtensionChanged: (_) {},
                onEnchoTimeChanged: (_) {},
                onEnchoCountChanged: (_) {},
                onEnchoUnlimitedChanged: (_) {},
                onHanteiChanged: (val) {
                  hanteiToggled = val;
                },
                onRepresentativeMatchChanged: (_) {},
                onDaihyoIpponShobuChanged: (_) {},
                onDaihyoMatchTimeChanged: (_) {},
                onDaihyoExtensionChanged: (_) {},
                onDaihyoEnchoTimeChanged: (_) {},
                onDaihyoEnchoCountChanged: (_) {},
                onDaihyoEnchoUnlimitedChanged: (_) {},
                onDaihyoHanteiChanged: (_) {},
                onRenseikaiTypeChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      // Verify Unified Form headers and switch options
      expect(find.text('🏷️ 試合ルール設定からワンタップ選択'), findsOneWidget);
      expect(find.text('⏱️ 試合時間 ＆ 基本形式'), findsOneWidget);
      expect(find.text('一本勝負形式にする'), findsOneWidget);
      expect(find.text('判定の適用'), findsOneWidget);

      // Toggle switches
      await tester.tap(find.text('一本勝負形式にする'));
      await tester.pumpAndSettle();
      expect(ipponToggled, isTrue);

      await tester.tap(find.text('判定の適用'));
      await tester.pumpAndSettle();
      expect(hanteiToggled, isFalse);
    },
  );
}
