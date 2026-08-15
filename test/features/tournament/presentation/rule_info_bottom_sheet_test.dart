import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/rule_info_bottom_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestableApp({
    required MatchModel match,
    bool isDark = false,
    String mode = 'normal',
  }) {
    final themeData = ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      splashFactory: NoSplash.splashFactory,
      extensions: [AppThemeColors.ofMode(isDark: isDark, mode: mode)],
    );

    return ProviderScope(
      child: MaterialApp(
        theme: themeData,
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                key: const ValueKey('open_rule_sheet_button'),
                onPressed: () => showRuleInfoBottomSheet(context, match),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('RuleInfoBottomSheet Strict Rule Isolation Tests (全試合方式の排他ルール検証)', () {
    testWidgets(
      '1. トーナメント団体戦: 団体戦ルールのみが表示され、個人戦・リーグ戦・勝ち抜き・錬成会ルールが1つも表示されないこと',
      (WidgetTester tester) async {
        final teamRule = const MatchRule(
          matchTimeMinutes: 2.0,
          isRunningTime: false,
          isIpponShobu: false,
          hasHantei: false,
          enchoCount: 0,
          enchoTimeMinutes: 3.0,
          isEnchoUnlimited: false,
          hasRepresentativeMatch: true,
          isDaihyoIpponShobu: true,
          daihyoMatchTimeMinutes: 0.0,
          daihyoHasExtension: true,
          daihyoEnchoCount: -2,
          positions: ['先鋒', '中堅', '大将'],
        );

        final match = MatchModel(
          id: 'team_m1',
          category: '一般の部',
          groupName: '道上剣友会A vs 相手チーム',
          matchType: '先鋒',
          redName: '道上剣友会A:山田',
          whiteName: '相手チーム:鈴木',
          rule: teamRule,
          note: '第1試合場, 2回戦 13時開始',
        );

        await tester.pumpWidget(buildTestableApp(match: match, isDark: true));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('open_rule_sheet_button')));
        await tester.pumpAndSettle();

        // [表示されるべき正しい項目]
        expect(find.text('試合レギュレーション'), findsOneWidget);
        expect(find.text('試合形式'), findsOneWidget);
        expect(find.text('団体戦'), findsOneWidget);
        expect(find.text('勝負形式'), findsOneWidget);
        expect(find.text('３本勝負 (２本先取)'), findsOneWidget);
        expect(find.text('試合時間'), findsOneWidget);
        expect(find.text('2分 (都度ストップ)'), findsOneWidget);
        expect(find.text('団体戦・チーム設定'), findsOneWidget);
        expect(find.text('代表戦'), findsOneWidget);
        expect(find.text('あり'), findsOneWidget);
        expect(find.text('代表戦勝負形式'), findsOneWidget);
        expect(find.text('１本勝負'), findsOneWidget);
        expect(find.text('代表戦時間'), findsOneWidget);
        expect(find.text('時間制限なし'), findsOneWidget);
        expect(find.text('代表戦延長'), findsOneWidget);
        expect(find.text('あり (無制限)'), findsOneWidget);
        expect(find.text('ポジション'), findsOneWidget);
        expect(find.text('先鋒、中堅、大将'), findsOneWidget);
        expect(find.text('備考・メモ'), findsOneWidget);
        expect(find.text('第1試合場, 2回戦 13時開始'), findsOneWidget);

        // [絶対に表示されてはならない無関係な項目]
        expect(find.text('延長戦'), findsNothing);
        expect(find.text('判定'), findsNothing);
        expect(find.text('ポジション延長'), findsNothing);
        expect(find.text('リーグ団体戦設定'), findsNothing);
        expect(find.text('リーグ勝点設定'), findsNothing);
        expect(find.text('同点時代表戦'), findsNothing);
        expect(find.text('勝点配分'), findsNothing);
        expect(find.text('勝ち抜き戦設定'), findsNothing);
        expect(find.text('無制限条件'), findsNothing);
        expect(find.text('錬成会設定'), findsNothing);
        expect(find.text('進行方式'), findsNothing);
        expect(find.text('制限時間'), findsNothing);
      },
    );

    testWidgets(
      '2. トーナメント個人戦: 個人戦ルールのみが表示され、団体戦・リーグ戦・勝ち抜き・錬成会ルールが1つも表示されないこと',
      (WidgetTester tester) async {
        final individualRule = const MatchRule(
          matchTimeMinutes: 3.0,
          isRunningTime: false,
          isIpponShobu: false,
          hasHantei: true,
          enchoCount: 1,
          enchoTimeMinutes: 3.0,
          isEnchoUnlimited: false,
          positions: ['選手'],
        );

        final match = MatchModel(
          id: 'indiv_m1',
          category: '一般の部',
          groupName: '',
          matchType: '個人戦',
          redName: '高橋',
          whiteName: '佐藤',
          rule: individualRule,
          note: '第2試合場 14時開始',
        );

        await tester.pumpWidget(buildTestableApp(match: match, isDark: false));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('open_rule_sheet_button')));
        await tester.pumpAndSettle();

        // [表示されるべき正しい項目]
        expect(find.text('試合形式'), findsOneWidget);
        expect(find.text('個人戦'), findsOneWidget);
        expect(find.text('勝負形式'), findsOneWidget);
        expect(find.text('３本勝負 (２本先取)'), findsOneWidget);
        expect(find.text('試合時間'), findsOneWidget);
        expect(find.text('3分 (都度ストップ)'), findsOneWidget);
        expect(find.text('延長戦'), findsOneWidget);
        expect(find.text('あり (3分・1回)'), findsOneWidget);
        expect(find.text('判定'), findsOneWidget);
        expect(find.text('あり'), findsOneWidget);

        // [絶対に表示されてはならない無関係な項目]
        expect(find.text('団体戦・チーム設定'), findsNothing);
        expect(find.text('代表戦'), findsNothing);
        expect(find.text('代表戦勝負形式'), findsNothing);
        expect(find.text('代表戦時間'), findsNothing);
        expect(find.text('代表戦延長'), findsNothing);
        expect(find.text('同点時代表戦'), findsNothing);
        expect(find.text('リーグ団体戦設定'), findsNothing);
        expect(find.text('リーグ勝点設定'), findsNothing);
        expect(find.text('勝点配分'), findsNothing);
        expect(find.text('勝ち抜き戦設定'), findsNothing);
        expect(find.text('無制限条件'), findsNothing);
        expect(find.text('錬成会設定'), findsNothing);
        expect(find.text('進行方式'), findsNothing);
        expect(find.text('制限時間'), findsNothing);
        expect(find.text('ポジション'), findsNothing);
      },
    );

    testWidgets(
      '3. リーグ団体戦: リーグ団体戦ルールのみが表示され、トーナメント団体・個人・勝ち抜き・錬成会ルールが表示されないこと',
      (WidgetTester tester) async {
        final leagueTeamRule = const MatchRule(
          isLeague: true,
          matchTimeMinutes: 3.0,
          isRunningTime: false,
          isIpponShobu: false,
          hasLeagueDaihyo: true,
          isDaihyoIpponShobu: true,
          daihyoMatchTimeMinutes: 0.0,
          winPoint: 3.0,
          drawPoint: 1.0,
          lossPoint: 0.0,
          positions: ['先鋒', '次鋒', '中堅', '副将', '大将'],
        );

        final match = MatchModel(
          id: 'league_m1',
          category: '一般の部',
          groupName: 'Aリーグ 第1試合',
          matchType: '先鋒',
          redName: 'チームA:山田',
          whiteName: 'チームB:田中',
          rule: leagueTeamRule,
        );

        await tester.pumpWidget(buildTestableApp(match: match));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('open_rule_sheet_button')));
        await tester.pumpAndSettle();

        // [表示されるべき正しい項目]
        expect(find.text('試合形式'), findsOneWidget);
        expect(find.text('リーグ団体戦'), findsOneWidget);
        expect(find.text('勝負形式'), findsOneWidget);
        expect(find.text('３本勝負 (２本先取)'), findsOneWidget);
        expect(find.text('試合時間'), findsOneWidget);
        expect(find.text('3分 (都度ストップ)'), findsOneWidget);
        expect(find.text('リーグ団体戦設定'), findsOneWidget);
        expect(find.text('同点時代表戦'), findsOneWidget);
        expect(find.text('あり'), findsOneWidget);
        expect(find.text('代表戦勝負形式'), findsOneWidget);
        expect(find.text('１本勝負'), findsOneWidget);
        expect(find.text('代表戦時間'), findsOneWidget);
        expect(find.text('時間制限なし'), findsOneWidget);
        expect(find.text('勝点配分'), findsOneWidget);
        expect(find.text('勝: 3.0点 / 分: 1.0点 / 負: 0.0点'), findsOneWidget);
        expect(find.text('ポジション'), findsOneWidget);
        expect(find.text('先鋒、次鋒、中堅、副将、大将'), findsOneWidget);

        // [絶対に表示されてはならない無関係な項目]
        expect(find.text('延長戦'), findsNothing);
        expect(find.text('判定'), findsNothing);
        expect(find.text('団体戦・チーム設定'), findsNothing);
        expect(find.text('勝ち抜き戦設定'), findsNothing);
        expect(find.text('無制限条件'), findsNothing);
        expect(find.text('錬成会設定'), findsNothing);
        expect(find.text('進行方式'), findsNothing);
        expect(find.text('制限時間'), findsNothing);
      },
    );

    testWidgets('4. リーグ個人戦: リーグ個人戦ルールのみが表示され、団体戦・勝ち抜き・錬成会ルールが表示されないこと', (
      WidgetTester tester,
    ) async {
      final leagueIndivRule = const MatchRule(
        isLeague: true,
        matchTimeMinutes: 2.0,
        isRunningTime: false,
        isIpponShobu: false,
        winPoint: 2.0,
        drawPoint: 1.0,
        lossPoint: 0.0,
        positions: ['選手'],
      );

      final match = MatchModel(
        id: 'league_indiv_m1',
        category: '一般の部',
        groupName: '個人Aリーグ 第1試合',
        matchType: '個人戦',
        redName: '山田',
        whiteName: '佐藤',
        rule: leagueIndivRule,
      );

      await tester.pumpWidget(buildTestableApp(match: match));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('open_rule_sheet_button')));
      await tester.pumpAndSettle();

      // [表示されるべき正しい項目]
      expect(find.text('試合形式'), findsOneWidget);
      expect(find.text('リーグ個人戦'), findsOneWidget);
      expect(find.text('勝負形式'), findsOneWidget);
      expect(find.text('３本勝負 (２本先取)'), findsOneWidget);
      expect(find.text('試合時間'), findsOneWidget);
      expect(find.text('2分 (都度ストップ)'), findsOneWidget);
      expect(find.text('リーグ勝点設定'), findsOneWidget);
      expect(find.text('勝点配分'), findsOneWidget);
      expect(find.text('勝: 2.0点 / 分: 1.0点 / 負: 0.0点'), findsOneWidget);

      // [絶対に表示されてはならない無関係な項目]
      expect(find.text('団体戦・チーム設定'), findsNothing);
      expect(find.text('代表戦'), findsNothing);
      expect(find.text('同点時代表戦'), findsNothing);
      expect(find.text('リーグ団体戦設定'), findsNothing);
      expect(find.text('勝ち抜き戦設定'), findsNothing);
      expect(find.text('無制限条件'), findsNothing);
      expect(find.text('錬成会設定'), findsNothing);
      expect(find.text('進行方式'), findsNothing);
      expect(find.text('制限時間'), findsNothing);
      expect(find.text('ポジション'), findsNothing);
    });

    testWidgets('5. 勝ち抜き戦: 勝ち抜き戦設定のみが表示され、リーグ・個人戦延長・錬成会ルールが表示されないこと', (
      WidgetTester tester,
    ) async {
      final kachinukiRule = const MatchRule(
        isKachinuki: true,
        kachinukiUnlimitedType: '大将対大将',
        matchTimeMinutes: 3.0,
        positions: ['先鋒', '次鋒', '中堅', '副将', '大将'],
      );

      final match = MatchModel(
        id: 'kachi_m1',
        category: '一般の部',
        groupName: '勝ち抜き 1回戦',
        matchType: '先鋒',
        isKachinuki: true,
        redName: '道場A:選手1',
        whiteName: '道場B:選手1',
        rule: kachinukiRule,
      );

      await tester.pumpWidget(buildTestableApp(match: match));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('open_rule_sheet_button')));
      await tester.pumpAndSettle();

      // [表示されるべき正しい項目]
      expect(find.text('試合形式'), findsOneWidget);
      expect(find.text('勝ち抜き戦'), findsOneWidget);
      expect(find.text('勝負形式'), findsOneWidget);
      expect(find.text('３本勝負 (２本先取)'), findsOneWidget);
      expect(find.text('試合時間'), findsOneWidget);
      expect(find.text('3分 (都度ストップ)'), findsOneWidget);
      expect(find.text('勝ち抜き戦設定'), findsOneWidget);
      expect(find.text('無制限条件'), findsOneWidget);
      expect(find.text('大将対大将'), findsOneWidget);
      expect(find.text('ポジション'), findsOneWidget);
      expect(find.text('先鋒、次鋒、中堅、副将、大将'), findsOneWidget);

      // [絶対に表示されてはならない無関係な項目]
      expect(find.text('延長戦'), findsNothing);
      expect(find.text('判定'), findsNothing);
      expect(find.text('団体戦・チーム設定'), findsNothing);
      expect(find.text('代表戦'), findsNothing);
      expect(find.text('リーグ団体戦設定'), findsNothing);
      expect(find.text('リーグ勝点設定'), findsNothing);
      expect(find.text('勝点配分'), findsNothing);
      expect(find.text('同点時代表戦'), findsNothing);
      expect(find.text('錬成会設定'), findsNothing);
      expect(find.text('進行方式'), findsNothing);
      expect(find.text('制限時間'), findsNothing);
    });

    testWidgets('6. 錬成会（時間制）: 錬成会ルールのみが表示され、延長・判定・代表戦・リーグ設定が表示されないこと', (
      WidgetTester tester,
    ) async {
      final renseikaiRule = const MatchRule(
        isRenseikai: true,
        renseikaiType: '時間制',
        overallTimeMinutes: 30,
        matchTimeMinutes: 2.0,
        isRunningTime: true,
        positions: ['先鋒', '中堅', '大将'],
      );

      final match = MatchModel(
        id: 'rensei_m1',
        category: '錬成会',
        groupName: '1コート 第1試合',
        matchType: '先鋒',
        redName: '錬成会A:選手',
        whiteName: '錬成会B:選手',
        rule: renseikaiRule,
      );

      await tester.pumpWidget(buildTestableApp(match: match));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('open_rule_sheet_button')));
      await tester.pumpAndSettle();

      // [表示されるべき正しい項目]
      expect(find.text('試合形式'), findsOneWidget);
      expect(find.text('錬成会'), findsOneWidget);
      expect(find.text('勝負形式'), findsOneWidget);
      expect(find.text('３本勝負 (２本先取)'), findsOneWidget);
      expect(find.text('試合時間'), findsOneWidget);
      expect(find.text('2分 (通し/空回し)'), findsOneWidget);
      expect(find.text('錬成会設定'), findsOneWidget);
      expect(find.text('進行方式'), findsOneWidget);
      expect(find.text('時間制'), findsOneWidget);
      expect(find.text('制限時間'), findsOneWidget);
      expect(find.text('30分'), findsOneWidget);
      expect(find.text('ポジション'), findsOneWidget);
      expect(find.text('先鋒、中堅、大将'), findsOneWidget);

      // [絶対に表示されてはならない無関係な項目]
      expect(find.text('延長戦'), findsNothing);
      expect(find.text('判定'), findsNothing);
      expect(find.text('団体戦・チーム設定'), findsNothing);
      expect(find.text('代表戦'), findsNothing);
      expect(find.text('リーグ団体戦設定'), findsNothing);
      expect(find.text('リーグ勝点設定'), findsNothing);
      expect(find.text('勝点配分'), findsNothing);
      expect(find.text('勝ち抜き戦設定'), findsNothing);
      expect(find.text('無制限条件'), findsNothing);
    });

    testWidgets('7. 錬成会（一試合制）: 制限時間が非表示になり、一試合制のみが表示されること', (
      WidgetTester tester,
    ) async {
      final renseikaiRule = const MatchRule(
        isRenseikai: true,
        renseikaiType: '一試合制',
        overallTimeMinutes: 30, // 一試合制の場合は無視されて非表示になること
        matchTimeMinutes: 3.0,
        isRunningTime: false,
      );

      final match = MatchModel(
        id: 'rensei_m2',
        category: '錬成会',
        groupName: '2コート 第1試合',
        matchType: '選手',
        redName: '選手A',
        whiteName: '選手B',
        rule: renseikaiRule,
      );

      await tester.pumpWidget(buildTestableApp(match: match));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('open_rule_sheet_button')));
      await tester.pumpAndSettle();

      // [表示されるべき正しい項目]
      expect(find.text('試合形式'), findsOneWidget);
      expect(find.text('錬成会'), findsOneWidget);
      expect(find.text('進行方式'), findsOneWidget);
      expect(find.text('一試合制'), findsOneWidget);

      // [一試合制では制限時間は非表示]
      expect(find.text('制限時間'), findsNothing);
      expect(find.text('延長戦'), findsNothing);
      expect(find.text('判定'), findsNothing);
      expect(find.text('代表戦'), findsNothing);
    });

    testWidgets('8. 団体戦で代表戦なしに設定された場合: 代表戦の個別項目（時間/延長/判定）が非表示になること', (
      WidgetTester tester,
    ) async {
      final teamRuleNoDaihyo = const MatchRule(
        matchTimeMinutes: 3.0,
        isRunningTime: false,
        isIpponShobu: false,
        hasRepresentativeMatch: false, // 代表戦なし
        positions: ['先鋒', '中堅', '大将'],
      );

      final match = MatchModel(
        id: 'team_m_no_daihyo',
        category: '一般の部',
        groupName: 'Aチーム vs Bチーム',
        matchType: '先鋒',
        redName: 'A:選手',
        whiteName: 'B:選手',
        rule: teamRuleNoDaihyo,
      );

      await tester.pumpWidget(buildTestableApp(match: match));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('open_rule_sheet_button')));
      await tester.pumpAndSettle();

      expect(find.text('団体戦・チーム設定'), findsOneWidget);
      expect(find.text('代表戦'), findsOneWidget);
      expect(find.text('なし'), findsOneWidget);

      // 代表戦が「なし」の場合は、代表戦の勝負形式・時間・延長・判定は表示されないこと
      expect(find.text('代表戦勝負形式'), findsNothing);
      expect(find.text('代表戦時間'), findsNothing);
      expect(find.text('代表戦延長'), findsNothing);
      expect(find.text('代表戦判定'), findsNothing);
    });

    testWidgets('9. 特設部内戦: bunaiksenモードでもテーマ破綻なく正確なルールが表示されること', (
      WidgetTester tester,
    ) async {
      final bunaiksenRule = const MatchRule(
        matchTimeMinutes: 3.0,
        isRunningTime: false,
        isIpponShobu: false,
        hasRepresentativeMatch: true,
        isDaihyoIpponShobu: true,
        daihyoMatchTimeMinutes: 0.0,
        daihyoHasExtension: true,
        daihyoEnchoCount: -2,
        positions: ['先鋒', '次鋒', '中堅', '副将', '大将'],
      );

      final match = MatchModel(
        id: 'bunaiksen_m1',
        tournamentId: 'bunaiksen_20260814',
        category: '部内戦',
        groupName: '紅組 vs 白組',
        matchType: '先鋒',
        redName: '紅組:選手',
        whiteName: '白組:選手',
        rule: bunaiksenRule,
      );

      await tester.pumpWidget(
        buildTestableApp(match: match, isDark: true, mode: 'bunaiksen'),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('open_rule_sheet_button')));
      await tester.pumpAndSettle();

      expect(find.text('試合レギュレーション'), findsOneWidget);
      expect(find.text('試合形式'), findsOneWidget);
      expect(find.text('団体戦'), findsOneWidget);
      expect(find.text('勝負形式'), findsOneWidget);
      expect(find.text('３本勝負 (２本先取)'), findsOneWidget);
      expect(find.text('代表戦'), findsOneWidget);
      expect(find.text('あり'), findsOneWidget);
      expect(find.text('代表戦勝負形式'), findsOneWidget);
      expect(find.text('１本勝負'), findsOneWidget);

      // 無関係な項目が出ないこと
      expect(find.text('延長戦'), findsNothing);
      expect(find.text('判定'), findsNothing);
      expect(find.text('ポジション延長'), findsNothing);
      expect(find.text('リーグ団体戦設定'), findsNothing);
      expect(find.text('勝ち抜き戦設定'), findsNothing);
    });

    testWidgets(
      '10. 【ポジション延長 誤表示回帰防止テスト】旧データや不正なデフォルト値（enchoTimeMinutes=3.0, enchoCount=0）を持つ団体戦データでも「ポジション延長」「延長戦」「判定」が100%非表示であること',
      (WidgetTester tester) async {
        final legacyTeamRule = const MatchRule(
          matchTimeMinutes: 2.0,
          isRunningTime: false,
          isIpponShobu: false,
          hasHantei: false,
          enchoCount: 0,
          enchoTimeMinutes: 3.0, // 旧データでデフォルト値が残っているパターン
          isEnchoUnlimited: false,
          hasRepresentativeMatch: true,
          isDaihyoIpponShobu: true,
          daihyoMatchTimeMinutes: 0.0,
          daihyoHasExtension: true,
          daihyoEnchoCount: -2,
          positions: ['先鋒', '次鋒', '中堅', '副将', '大将'],
        );

        final legacyMatch = MatchModel(
          id: 'legacy_team_m',
          category: '一般の部',
          groupName: '道上剣友会A vs 相手チーム',
          matchType: '先鋒',
          redName: '道上剣友会A:山田',
          whiteName: '相手チーム:鈴木',
          rule: legacyTeamRule,
          hasExtension: true, // MatchModel 直下の古いフラグ
          extensionTimeMinutes: 3,
          extensionCount: 1,
          note: '第1試合場, 2回戦 13時開始',
        );

        await tester.pumpWidget(
          buildTestableApp(match: legacyMatch, isDark: true),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('open_rule_sheet_button')));
        await tester.pumpAndSettle();

        // 団体戦の正しい設定が表示されること
        expect(find.text('団体戦'), findsOneWidget);
        expect(find.text('団体戦・チーム設定'), findsOneWidget);
        expect(find.text('代表戦'), findsOneWidget);
        expect(find.text('あり'), findsOneWidget);

        // ★ ユーザー指摘の「ポジション延長」および「延長戦」「判定」が確実に非表示であること
        expect(find.text('ポジション延長'), findsNothing);
        expect(find.text('延長戦'), findsNothing);
        expect(find.text('判定'), findsNothing);
      },
    );
  });
}
