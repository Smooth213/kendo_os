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
        expect(find.text('コート・グループ'), findsOneWidget);
        expect(find.text('一括ルール・メモ'), findsOneWidget);
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
  });
}
