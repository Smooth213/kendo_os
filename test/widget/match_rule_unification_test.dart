import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_edit_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/rule_info_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/rules/match_rule_setting_form.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('🥋 ルール設定・一括変更・スワイプ編集・確認画面 統一テスト要塞', () {
    testWidgets(
      '1. MatchRuleSettingForm: 代表戦ON時に代表戦時間・延長時間・延長回数が展開され、時間制も選択できること',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final themeColors = AppThemeColors.ofMode(
          isDark: false,
          mode: 'normal',
        );
        bool repMatch = false;
        bool repIppon = true;
        double repTime = 0.0;
        bool repEncho = true;
        double repEnchoTime = 3.0;
        int repEnchoCount = -2;
        bool repEnchoUnlimited = true;
        bool repHantei = false;
        String renseikaiType = '一試合制';

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light().copyWith(extensions: [themeColors]),
            home: StatefulBuilder(
              builder: (context, setState) {
                return Scaffold(
                  body: SingleChildScrollView(
                    child: MatchRuleSettingForm(
                      isDantai: true,
                      selectedSceneKey: 'honsen',
                      matchTime: 3.0,
                      isRunningTime: false,
                      isIpponShobu: false,
                      hasExtension: true,
                      enchoTime: 2.0,
                      enchoCount: 1,
                      isEnchoUnlimited: false,
                      hasHantei: true,
                      hasRepresentativeMatch: repMatch,
                      isDaihyoIpponShobu: repIppon,
                      daihyoMatchTime: repTime,
                      daihyoHasExtension: repEncho,
                      daihyoEnchoTime: repEnchoTime,
                      daihyoEnchoCount: repEnchoCount,
                      isDaihyoEnchoUnlimited: repEnchoUnlimited,
                      daihyoHasHantei: repHantei,
                      renseikaiType: renseikaiType,
                      primaryAccent: Colors.blue,
                      isDark: false,
                      onMatchTimeChanged: (_) {},
                      onRunningTimeChanged: (_) {},
                      onIpponShobuChanged: (_) {},
                      onExtensionChanged: (_) {},
                      onEnchoTimeChanged: (_) {},
                      onEnchoCountChanged: (_) {},
                      onEnchoUnlimitedChanged: (_) {},
                      onHanteiChanged: (_) {},
                      onRepresentativeMatchChanged: (v) {
                        setState(() => repMatch = v);
                      },
                      onDaihyoIpponShobuChanged: (v) {
                        setState(() => repIppon = v);
                      },
                      onDaihyoMatchTimeChanged: (v) {
                        setState(() => repTime = v);
                      },
                      onDaihyoExtensionChanged: (v) {
                        setState(() => repEncho = v);
                      },
                      onDaihyoEnchoTimeChanged: (v) {
                        setState(() => repEnchoTime = v);
                      },
                      onDaihyoEnchoCountChanged: (v) {
                        setState(() => repEnchoCount = v);
                      },
                      onDaihyoEnchoUnlimitedChanged: (v) {
                        setState(() => repEnchoUnlimited = v);
                      },
                      onDaihyoHanteiChanged: (v) {
                        setState(() => repHantei = v);
                      },
                      onRenseikaiTypeChanged: (v) {
                        setState(() => renseikaiType = v);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. 時間制の選択テスト
        expect(find.text('一試合制 (デフォルト)'), findsOneWidget);
        expect(find.text('時間制'), findsOneWidget);
        await tester.tap(find.text('時間制'));
        await tester.pumpAndSettle();
        expect(find.text('全体の制限時間: 30分'), findsOneWidget);
        expect(find.text('15分'), findsOneWidget);
        expect(find.text('20分'), findsOneWidget);

        // 2. 代表戦スイッチをONにする
        expect(find.text('代表戦 詳細設定'), findsNothing);
        await tester.tap(find.text('代表戦の適用'));
        await tester.pumpAndSettle();

        // 代表戦詳細設定がすべて展開されること
        expect(find.text('代表戦 詳細設定'), findsOneWidget);
        expect(find.text('代表戦の時間: 時間制限なし'), findsOneWidget);
        expect(find.text('制限なし'), findsOneWidget);
        // 3. 反則上限・勝ち抜き戦・リーグ戦の表示・操作検証
        expect(find.text('反則累積上限'), findsOneWidget);
        expect(find.text('2回'), findsAtLeastNWidgets(1));
        expect(find.text('1回'), findsAtLeastNWidgets(1));

        expect(find.text('勝ち抜き戦形式'), findsOneWidget);
        expect(find.text('リーグ戦（勝点集計ルール）'), findsOneWidget);

        expect(find.text('代表戦は一本勝負'), findsOneWidget);
        expect(find.text('代表戦の延長戦を行う'), findsOneWidget);
        expect(find.text('代表戦延長の時間: 3分'), findsOneWidget);
        expect(find.text('代表戦延長は無制限（決着まで）'), findsOneWidget);
        expect(find.text('代表戦の判定を行う'), findsOneWidget);

        // 代表戦延長の無制限をOFFにして回数指定を表示
        await tester.tap(find.text('代表戦延長は無制限（決着まで）'));
        await tester.pumpAndSettle();
        expect(find.text('代表戦最大延長回数: '), findsOneWidget);
        expect(find.text('1回'), findsWidgets);
      },
    );

    testWidgets('2. MatchEditSheet: スワイプ編集で統一ルール設定フォームが表示され操作できること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');
      const testMatch1 = MatchModel(
        id: 'edit_match_1',
        tournamentId: 'tourney_1',
        matchType: '先鋒戦',
        redName: '青龍道場: 佐藤',
        whiteName: '白虎道場: 鈴木',
        status: 'waiting',
        order: 1.0,
        note: '[団体戦]',
        matchTimeMinutes: 3.0,
        rule: MatchRule(
          matchTimeMinutes: 3.0,
          isIpponShobu: false,
          hasRepresentativeMatch: true,
        ),
      );
      const testMatch2 = MatchModel(
        id: 'edit_match_2',
        tournamentId: 'tourney_1',
        matchType: '次鋒戦',
        redName: '青龍道場: 田中',
        whiteName: '白虎道場: 高橋',
        status: 'waiting',
        order: 2.0,
        note: '[団体戦]',
        matchTimeMinutes: 3.0,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.light().copyWith(extensions: [themeColors]),
            home: Scaffold(
              body: MatchEditSheet(
                matches: const [testMatch1, testMatch2],
                tournamentId: 'tourney_1',
                themeColors: themeColors,
                initialTabIndex: 2, // ルールタブを直接開く
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 統一ルール設定フォームの要素が表示されていること
      expect(find.text('🏷️ 試合ルール設定からワンタップ選択'), findsOneWidget);
      expect(find.text('⏱️ 試合時間 ＆ 基本形式'), findsOneWidget);
      expect(find.text('通し時間（空回し）にする'), findsOneWidget);
      expect(find.text('一本勝負形式にする'), findsOneWidget);
      expect(find.text('🔄 延長戦ルール'), findsOneWidget);
      expect(find.text('⚖️ 判定（ハンテイ）ルール'), findsOneWidget);
      expect(find.text('🥋 団体戦・代表戦ルール'), findsOneWidget);
    });

    testWidgets('3. RuleInfoBottomSheet: 統一された順序・アイコンでルール確認が表示されること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');
      const testMatch = MatchModel(
        id: 'info_match_1',
        tournamentId: 'tourney_1',
        matchType: '先鋒戦',
        redName: '青龍道場: 佐藤',
        whiteName: '白虎道場: 鈴木',
        status: 'waiting',
        order: 1.0,
        note: '第1試合場',
        matchTimeMinutes: 4.0,
        isRunningTime: true,
        hasExtension: true,
        extensionTimeMinutes: 2.0,
        extensionCount: 1,
        rule: MatchRule(
          positions: ['先鋒', '中堅', '大将'],
          matchTimeMinutes: 4.0,
          isRunningTime: true,
          isIpponShobu: false,
          enchoTimeMinutes: 2.0,
          enchoCount: 1,
          hasRepresentativeMatch: true,
          isDaihyoIpponShobu: true,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(extensions: [themeColors]),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: ElevatedButton(
                    onPressed: () =>
                        showRuleInfoBottomSheet(context, testMatch),
                    child: const Text('Open Rule Info'),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // ボタンを押してボトムシートを開く
      await tester.tap(find.text('Open Rule Info'));
      await tester.pumpAndSettle();

      // 統一ルール確認の要素を検証
      expect(find.text('試合レギュレーション確認'), findsOneWidget);
      expect(find.text('🏆 本戦'), findsOneWidget);
      expect(find.text('🎯 試合形式'), findsOneWidget);
      expect(find.text('⏱️ 試合時間'), findsOneWidget);
      expect(find.text('4分 (通し/空回し)'), findsOneWidget);
      expect(find.text('⚔️ 勝負形式'), findsOneWidget);
      expect(find.text('３本勝負 (２本先取)'), findsOneWidget);
      expect(find.text('🔄 延長戦'), findsOneWidget);
      expect(find.text('あり (2分・1回)'), findsOneWidget);
      expect(find.text('⚖️ 判定'), findsOneWidget);
      expect(find.text('🥋 代表戦'), findsOneWidget);
    });

    testWidgets('4. ワンタップ選択で設定されたルールが反映され未設定ルールがOFFになること', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');
      const testMatch1 = MatchModel(
        id: 'preset_test_match',
        tournamentId: 'tourney_preset_1',
        matchType: '先鋒戦',
        redName: '青龍道場: 佐藤',
        whiteName: '白虎道場: 鈴木',
        status: 'waiting',
        order: 1.0,
        note: '[団体戦]',
        matchTimeMinutes: 3.0,
        rule: MatchRule(
          matchTimeMinutes: 3.0,
          isIpponShobu: false,
          enchoTimeMinutes: 2.0,
          enchoCount: 1,
          hasHantei: true,
          hasRepresentativeMatch: true,
        ),
      );

      const testMatch2 = MatchModel(
        id: 'preset_test_match_2',
        tournamentId: 'tourney_preset_1',
        matchType: '次鋒戦',
        redName: '青龍道場: 田中',
        whiteName: '白虎道場: 高橋',
        status: 'waiting',
        order: 2.0,
        note: '[団体戦]',
        matchTimeMinutes: 3.0,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.light().copyWith(extensions: [themeColors]),
            home: Scaffold(
              body: MatchEditSheet(
                matches: const [testMatch1, testMatch2],
                tournamentId: 'tourney_preset_1',
                themeColors: themeColors,
                initialTabIndex: 2,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 初期状態: 延長あり・判定あり
      final initialSwitchFinder = find.byType(Switch);
      expect(initialSwitchFinder, findsWidgets);

      // 錬成会ルールチップをタップ（判定なし・延長なし・代表戦なし）
      await tester.tap(find.text('錬成会ルール (3分)'));
      await tester.pumpAndSettle();

      // 代表戦詳細設定が非表示（代表戦OFF）になっていること
      expect(find.text('代表戦 詳細設定'), findsNothing);

      // 再度本戦ルールチップをタップ（判定あり・延長あり・代表戦あり）
      await tester.tap(find.text('本戦ルール (3分)'));
      await tester.pumpAndSettle();

      // 代表戦詳細設定が展開されること
      expect(find.text('代表戦 詳細設定'), findsOneWidget);
    });
  });
}
