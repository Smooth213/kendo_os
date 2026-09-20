import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_edit_rule_and_memo_tab.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
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

  testWidgets(
    '設定していないルール（マルチシーンOFF時の錬成・申合せ、他部門ルール）が表示されず、設定済みルールのみが選択肢となり、延長戦が勝手にONにならないこと',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      MatchRule? selectedRule;
      String? selectedKey;

      final testTournament = TournamentModel(
        id: 't1',
        organizationId: 'org1',
        name: 'テスト大会',
        date: DateTime.now(),
        venue: '第1武道館',
        categoryRules: {
          // 部門1: 小学生の部（マルチシーン無効、本戦2分30秒のみ設定）
          '小学生の部': const CategoryRuleSet(
            matchType: '団体戦',
            isMultiScene: false,
            useHonsenRule: true,
            useRenseikaiRule: false,
            useMoushiawaseRule: false,
            normalRule: MatchRule(
              category: '小学生の部',
              matchTimeMinutes: 2.5,
              enchoCount: 0,
              isEnchoUnlimited: false,
              hasRepresentativeMatch: true,
            ),
          ),
          // 部門2: 中学生の部（別部門のルール）
          '中学生の部': const CategoryRuleSet(
            matchType: '団体戦',
            isMultiScene: false,
            useHonsenRule: true,
            normalRule: MatchRule(
              category: '中学生の部',
              matchTimeMinutes: 3.0,
              enchoCount: 0,
              isEnchoUnlimited: false,
              hasRepresentativeMatch: true,
            ),
          ),
        },
      );

      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tournamentProvider(
              't1',
            ).overrideWith((ref) => Stream.value(testTournament)),
          ],
          child: MaterialApp(
            theme: ThemeData.light().copyWith(extensions: [themeColors]),
            home: Scaffold(
              body: MatchEditRuleAndMemoTab(
                primaryAccent: AppKendoColors.blueAccent,
                isDark: false,
                textColor: AppKendoColors.pureBlack,
                tournamentId: 't1',
                isDantai: true,
                match: const MatchModel(
                  id: 'm_elem',
                  tournamentId: 't1',
                  matchType: '団体戦',
                  category: '小学生の部', // 小学生の試合
                  redName: '東京A',
                  whiteName: '大阪A',
                ),
                selectedPresetKey: null,
                selectedPresetRule: null,
                matchTime: 2.5,
                isRunningTime: false,
                isIpponShobu: false,
                hasExtension: false, // 延長戦はOFF
                enchoTime: 2.0,
                enchoCount: 0,
                isEnchoUnlimited: false,
                hasHantei: true,
                hasRepresentativeMatch: true,
                isDaihyoIpponShobu: true,
                daihyoHasExtension: true,
                daihyoEnchoTime: 3.0,
                daihyoEnchoCount: -2,
                isDaihyoEnchoUnlimited: true,
                daihyoHasHantei: false,
                renseikaiType: '一試合制',
                onPresetSelected: (rule, key) {
                  selectedRule = rule;
                  selectedKey = key;
                },
                onMatchTimeChanged: (_) {},
                onRunningTimeChanged: (_) {},
                onIpponShobuChanged: (_) {},
                onExtensionChanged: (_) {},
                onEnchoTimeChanged: (_) {},
                onEnchoCountChanged: (_) {},
                onEnchoUnlimitedChanged: (_) {},
                onHanteiChanged: (_) {},
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

      await tester.pumpAndSettle();

      // 1. 設定されている「本戦ルール (2分30秒)」のみが表示されていること
      expect(find.text('本戦ルール (2分30秒)'), findsOneWidget);

      // 2. 設定していないルール（錬成ルール・申合せルール）は表示されないこと
      expect(find.textContaining('錬成ルール'), findsNothing);
      expect(find.textContaining('申合せルール'), findsNothing);

      // 3. 他部門（中学生の部: 本戦3分）のルールは小学生の試合に混ざって表示されないこと
      expect(find.text('本戦ルール (3分)'), findsNothing);
      expect(find.textContaining('中学生の部'), findsNothing);

      // 4. 「本戦ルール (2分30秒)」チップをタップすると正しくルールが選択されること
      await tester.tap(find.text('本戦ルール (2分30秒)'));
      await tester.pumpAndSettle();

      expect(selectedRule, isNotNull);
      expect(selectedRule!.matchTimeMinutes, 2.5);
      expect(selectedRule!.enchoCount, 0, reason: '団体戦本戦ルールには延長戦が含まれていないこと');
      expect(selectedKey, '小学生の部_honsen');

      // 5. 延長戦ルールがOFF（Switchがfalse）であることの確認
      final extensionSwitchFinder = find.widgetWithText(
        SwitchListTile,
        '延長戦を行う',
      );
      if (extensionSwitchFinder.evaluate().isNotEmpty) {
        final switchTile = tester.widget<SwitchListTile>(extensionSwitchFinder);
        expect(switchTile.value, isFalse, reason: '設定にない延長戦はOFFでなければならない');
      }
    },
  );
}
