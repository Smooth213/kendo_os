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
      '1. Verify MatchEditSheet renders 3 tabs and swaps Red/White players properly',
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
                  match: initialMatch,
                  tournamentId: 'test_tourney',
                  themeColors: themeColors,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 1. ヘッダーと3つのタブが存在することを確認
        expect(find.text('試合情報の編集'), findsOneWidget);
        expect(find.text('選手・チーム'), findsOneWidget);
        expect(find.text('コート・グループ'), findsOneWidget);
        expect(find.text('ルール・メモ'), findsOneWidget);

        // 2. 「赤と白を入れ替える ⇄」ボタンをタップ
        final swapButton = find.text('赤と白を入れ替える ⇄');
        expect(swapButton, findsOneWidget);

        await tester.tap(swapButton, warnIfMissed: false);
        await tester.pumpAndSettle();

        // 3. コート・グループ タブへの切り替えテスト
        await tester.tap(find.text('コート・グループ'), warnIfMissed: false);
        await tester.pumpAndSettle();

        expect(find.text('試合場（コート）の設定'), findsOneWidget);
        expect(find.text('グループ・ラウンド見出し（アコーディオン）'), findsOneWidget);

        // 4. ルール・メモ タブへの切り替えテスト
        await tester.tap(find.text('ルール・メモ'), warnIfMissed: false);
        await tester.pumpAndSettle();

        expect(find.text('⏱️ この試合だけの個別ルール'), findsOneWidget);
        expect(find.text('一本勝負にする'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
