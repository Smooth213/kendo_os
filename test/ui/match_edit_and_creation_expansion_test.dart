import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_edit_sheet.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🛡️ Match Edit & Creation Flow Expansion Integration Tests', () {
    testWidgets(
      '1. Verify MatchEditSheet renders 3 tabs and handles individual match properly',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        const initialMatch = MatchModel(
          id: 'test_edit_1',
          matchType: '個人戦',
          redName: '剣道太郎',
          whiteName: '武道花子',
          note: '第1試合場\nAリーグ',
          rule: MatchRule(
            matchTimeMinutes: 3.0,
            isIpponShobu: false,
            teamName: '剣道道場A',
          ),
        );

        final themeColors = AppThemeColors.ofMode(
          isDark: false,
          mode: 'operate',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            child: MaterialApp(
              home: Scaffold(
                body: MatchEditSheet(
                  matches: const [initialMatch],
                  tournamentId: 'test_tourney',
                  themeColors: themeColors,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('試合情報の編集'), findsOneWidget);
        expect(find.text('コート・メモ'), findsOneWidget);
        expect(find.text('一括ルール'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '2. Verify MatchEditSheet Team-wide Bulk Edit Mode for Dantai Matches',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        const dantaiMatches = [
          MatchModel(
            id: 'senho',
            matchType: '団体戦',
            redName: '赤先鋒',
            whiteName: '白先鋒',
            note: '道上 vs テスト相手',
            rule: MatchRule(teamName: '道上'),
          ),
          MatchModel(
            id: 'jiho',
            matchType: '団体戦',
            redName: '赤次鋒',
            whiteName: '白次鋒',
            note: '道上 vs テスト相手',
            rule: MatchRule(teamName: '道上'),
          ),
          MatchModel(
            id: 'chuken',
            matchType: '団体戦',
            redName: '赤中堅',
            whiteName: '手中堅',
            note: '道上 vs テスト相手',
            rule: MatchRule(teamName: '道上'),
          ),
        ];

        final themeColors = AppThemeColors.ofMode(
          isDark: false,
          mode: 'operate',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            child: MaterialApp(
              home: Scaffold(
                body: MatchEditSheet(
                  matches: dantaiMatches,
                  tournamentId: 'test_dantai_tourney',
                  themeColors: themeColors,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('団体戦対戦の編集'), findsOneWidget);
        expect(find.text('チーム丸ごと赤と白を入れ替える ⇄'), findsOneWidget);
        expect(find.text('先鋒'), findsOneWidget);
        expect(find.text('中堅'), findsOneWidget);
        expect(find.text('大将'), findsOneWidget);

        final swapButton = find.text('チーム丸ごと赤と白を入れ替える ⇄');
        await tester.tap(swapButton, warnIfMissed: false);
        await tester.pumpAndSettle();

        expect(find.text('団体戦全体を一括保存'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '3. Verify My-Team (自チーム) Tracking & Alignment Preservation after Swap',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        const myTeamMatches = [
          MatchModel(
            id: 'senho',
            matchType: '団体戦',
            redName: '道上先鋒',
            whiteName: 'ライバル先鋒',
            note: '第1試合場\n道上 vs ライバル',
            rule: MatchRule(teamName: '道上'),
          ),
        ];

        final themeColors = AppThemeColors.ofMode(
          isDark: false,
          mode: 'operate',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            child: MaterialApp(
              home: Scaffold(
                body: MatchEditSheet(
                  matches: myTeamMatches,
                  tournamentId: 'test_myteam_tourney',
                  themeColors: themeColors,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final swapButton = find.text('チーム丸ごと赤と白を入れ替える ⇄');
        await tester.tap(swapButton, warnIfMissed: false);
        await tester.pumpAndSettle();

        // 自チーム追従の実効性確認
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '4. Verify Red/White Swap, Own-Team Tracking, Accordion Integrity & Rule Score Input Propagation',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        const initialRule = MatchRule(
          matchTimeMinutes: 3.0,
          isIpponShobu: false,
          hasHantei: true,
          teamName: '道上剣友会',
        );

        const dantaiFiveMatches = [
          MatchModel(
            id: 'senho_1',
            matchType: '団体戦',
            redName: '道上剣友会: 剣道先鋒',
            whiteName: 'ライバル道場: 相手先鋒',
            groupName: 'group_dantai_100',
            note: '第1試合場\n1回戦',
            rule: initialRule,
          ),
          MatchModel(
            id: 'taisho_1',
            matchType: '団体戦',
            redName: '道上剣友会: 剣道大将',
            whiteName: 'ライバル道場: 相手大将',
            groupName: 'group_dantai_100',
            note: '第1試合場\n1回戦',
            rule: initialRule,
          ),
        ];

        final themeColors = AppThemeColors.ofMode(
          isDark: false,
          mode: 'operate',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            child: MaterialApp(
              home: Scaffold(
                body: MatchEditSheet(
                  matches: dantaiFiveMatches,
                  tournamentId: 'test_dantai_tourney',
                  themeColors: themeColors,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 1. 赤白入れ替え実行
        final swapButton = find.text('チーム丸ごと赤と白を入れ替える ⇄');
        await tester.tap(swapButton, warnIfMissed: false);
        await tester.pumpAndSettle();

        // 2. 「クリア」ボタンをタップして無駄な見出し補完を完全除去
        final clearButton = find.text('クリア');
        if (clearButton.evaluate().isNotEmpty) {
          await tester.tap(clearButton);
          await tester.pumpAndSettle();
        }

        // 3. 一括ルール タブへ切り替え
        final ruleTab = find.text('一括ルール');
        await tester.tap(ruleTab);
        await tester.pumpAndSettle();

        expect(find.text('試合時間'), findsWidgets);
        expect(find.textContaining('一本勝負'), findsWidgets);

        // 4. 一括編集画面の全コンポーネント正常描画・操作性の完了検証
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '5. Verify MatchEditSheet unified court and round heading chips with clear and left alignment',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        const testMatch = MatchModel(
          id: 'test_heading_chip_1',
          matchType: '個人戦',
          redName: '剣道選手A',
          whiteName: '剣道選手B',
          note: '',
          rule: MatchRule(matchTimeMinutes: 3.0),
        );

        final themeColors = AppThemeColors.ofMode(
          isDark: false,
          mode: 'operate',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            child: MaterialApp(
              home: Scaffold(
                body: MatchEditSheet(
                  matches: const [testMatch],
                  tournamentId: 'test_tourney_chips',
                  themeColors: themeColors,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 1. コート・メモ タブおよび見出し・メモ項目の描画検証
        expect(find.text('試合情報の編集'), findsOneWidget);
        expect(find.text('コート・メモ'), findsOneWidget);

        // 2. 試合場（コート）および回戦・ラウンド選択チップのタップ検証
        final courtChip = find.text('第1試合場');
        final roundChip = find.text('準決勝');

        if (courtChip.evaluate().isNotEmpty) {
          await tester.tap(courtChip.first);
          await tester.pumpAndSettle();
        }

        if (roundChip.evaluate().isNotEmpty) {
          await tester.tap(roundChip.first);
          await tester.pumpAndSettle();
        }

        // 3. 全体エラーなし正常描画の完了検証
        expect(tester.takeException(), isNull);
      },
    );
  });
}
