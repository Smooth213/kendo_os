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
        const teamRule = MatchRule(
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

        const match = MatchModel(
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
        expect(find.text('試合レギュレーション確認'), findsOneWidget);
        expect(find.text('🎯 試合形式'), findsOneWidget);
        expect(find.text('団体戦'), findsOneWidget);
        expect(find.text('⚔️ 勝負形式'), findsOneWidget);
        expect(find.text('３本勝負 (２本先取)'), findsOneWidget);
        expect(find.text('⏱️ 試合時間'), findsOneWidget);
        expect(find.text('2分 (都度ストップ)'), findsOneWidget);
        expect(find.text('🥋 代表戦'), findsOneWidget);
        expect(find.textContaining('時間制限なし・一本勝負・延長無制限'), findsOneWidget);
        expect(find.text('📝 備考・メモ'), findsOneWidget);
        expect(find.text('第1試合場, 2回戦 13時開始'), findsOneWidget);

        // [絶対に表示されてはならない無関係な項目]
        expect(find.text('リーグ個人戦'), findsNothing);
        expect(find.text('勝ち抜き戦'), findsNothing);
      },
    );

    testWidgets(
      '2. トーナメント個人戦: 個人戦ルールのみが表示され、団体戦・リーグ戦・勝ち抜き・錬成会ルールが1つも表示されないこと',
      (WidgetTester tester) async {
        const indivRule = MatchRule(
          matchTimeMinutes: 3.0,
          isRunningTime: false,
          isIpponShobu: false,
          hasHantei: true,
          enchoCount: 1,
          enchoTimeMinutes: 2.0,
          isEnchoUnlimited: false,
          hasRepresentativeMatch: false,
          positions: ['選手'],
        );

        const match = MatchModel(
          id: 'indiv_m1',
          category: '男子個人の部',
          matchType: 'individual',
          redName: '山田 (道上剣友会)',
          whiteName: '佐藤 (東京剣道クラブ)',
          rule: indivRule,
          note: '3回戦',
        );

        await tester.pumpWidget(buildTestableApp(match: match));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('open_rule_sheet_button')));
        await tester.pumpAndSettle();

        expect(find.text('試合レギュレーション確認'), findsOneWidget);
        expect(find.text('🎯 試合形式'), findsOneWidget);
        expect(find.text('個人戦'), findsOneWidget);
        expect(find.text('⏱️ 試合時間'), findsOneWidget);
        expect(find.text('3分 (都度ストップ)'), findsOneWidget);
        expect(find.text('🔄 延長戦'), findsOneWidget);
        expect(find.text('あり (2分・1回)'), findsOneWidget);
        expect(find.text('⚖️ 判定'), findsOneWidget);
        expect(find.text('あり (時間・延長終了時)'), findsOneWidget);

        // 個人戦のため代表戦は非表示
        expect(find.text('🥋 代表戦'), findsNothing);
      },
    );

    testWidgets(
      '3. リーグ団体戦: リーグ団体戦ルールのみが表示され、トーナメント団体・個人・勝ち抜き・錬成会ルールが表示されないこと',
      (WidgetTester tester) async {
        const leagueTeamRule = MatchRule(
          matchTimeMinutes: 4.0,
          isRunningTime: true,
          isIpponShobu: false,
          hasHantei: false,
          enchoCount: 0,
          isEnchoUnlimited: false,
          hasRepresentativeMatch: true,
          isDaihyoIpponShobu: true,
          daihyoMatchTimeMinutes: 3.0,
          daihyoHasExtension: true,
          daihyoEnchoCount: -2,
          isLeague: true,
          winPoint: 3.0,
          drawPoint: 1.0,
          lossPoint: 0.0,
          positions: ['先鋒', '次鋒', '中堅', '副将', '大将'],
        );

        const match = MatchModel(
          id: 'league_team_m1',
          category: '一般の部',
          groupName: 'Aブロック 1位決定戦',
          matchType: '団体戦',
          redName: 'チームA',
          whiteName: 'チームB',
          rule: leagueTeamRule,
          note: '[リーグ戦] 第1試合',
        );

        await tester.pumpWidget(buildTestableApp(match: match));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('open_rule_sheet_button')));
        await tester.pumpAndSettle();

        expect(find.text('試合レギュレーション確認'), findsOneWidget);
        expect(find.text('🎯 試合形式'), findsOneWidget);
        expect(find.text('リーグ団体戦'), findsOneWidget);
        expect(find.text('⏱️ 試合時間'), findsOneWidget);
        expect(find.text('4分 (通し/空回し)'), findsOneWidget);
        expect(find.text('🥋 代表戦'), findsOneWidget);
      },
    );

    testWidgets('4. リーグ個人戦: リーグ個人戦ルールのみが表示され、団体戦・勝ち抜き・錬成会ルールが表示されないこと', (
      WidgetTester tester,
    ) async {
      const leagueIndivRule = MatchRule(
        matchTimeMinutes: 2.5,
        isRunningTime: false,
        isIpponShobu: true,
        hasHantei: false,
        enchoCount: 0,
        isEnchoUnlimited: false,
        hasRepresentativeMatch: false,
        isLeague: true,
        winPoint: 2.0,
        drawPoint: 1.0,
        lossPoint: 0.0,
        positions: ['選手'],
      );

      const match = MatchModel(
        id: 'league_indiv_m1',
        category: '女子個人の部',
        matchType: 'individual',
        redName: '高橋',
        whiteName: '伊藤',
        rule: leagueIndivRule,
        note: '[リーグ戦] 予選Aリーグ',
      );

      await tester.pumpWidget(buildTestableApp(match: match));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('open_rule_sheet_button')));
      await tester.pumpAndSettle();

      expect(find.text('試合レギュレーション確認'), findsOneWidget);
      expect(find.text('🎯 試合形式'), findsOneWidget);
      expect(find.text('リーグ個人戦'), findsOneWidget);
      expect(find.text('⏱️ 試合時間'), findsOneWidget);
      expect(find.text('2分30秒 (都度ストップ)'), findsOneWidget);
      expect(find.text('⚔️ 勝負形式'), findsOneWidget);
      expect(find.text('１本勝負'), findsOneWidget);

      expect(find.text('🥋 代表戦'), findsNothing);
    });

    testWidgets('5. 勝ち抜き戦: 勝ち抜き戦設定のみが表示され、リーグ・個人戦延長・錬成会ルールが表示されないこと', (
      WidgetTester tester,
    ) async {
      const kachinukiRule = MatchRule(
        matchTimeMinutes: 3.0,
        isRunningTime: false,
        isIpponShobu: false,
        hasHantei: false,
        enchoCount: 0,
        isEnchoUnlimited: false,
        isKachinuki: true,
        kachinukiUnlimitedType: '大将対大将',
        positions: ['先鋒', '中堅', '大将'],
      );

      const match = MatchModel(
        id: 'kachinuki_m1',
        category: '高校男子の部',
        groupName: '1回戦 第1試合',
        matchType: '先鋒',
        redName: 'A高校:木村',
        whiteName: 'B高校:斎藤',
        isKachinuki: true,
        rule: kachinukiRule,
        note: '勝ち抜き戦',
      );

      await tester.pumpWidget(buildTestableApp(match: match));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('open_rule_sheet_button')));
      await tester.pumpAndSettle();

      expect(find.text('試合レギュレーション確認'), findsOneWidget);
      expect(find.text('🎯 試合形式'), findsOneWidget);
      expect(find.text('勝ち抜き戦'), findsAtLeast(1));
      expect(find.text('勝ち抜き条件'), findsOneWidget);
      expect(find.text('大将対大将'), findsOneWidget);
    });

    testWidgets('6. 錬成会（時間制）: 錬成会ルールのみが表示され、延長・判定・代表戦・リーグ設定が表示されないこと', (
      WidgetTester tester,
    ) async {
      const renseikaiRule = MatchRule(
        matchTimeMinutes: 2.0,
        isRunningTime: true,
        isIpponShobu: false,
        hasHantei: false,
        enchoCount: 0,
        isEnchoUnlimited: false,
        hasRepresentativeMatch: false,
        isRenseikai: true,
        renseikaiType: '時間制',
        overallTimeMinutes: 30,
        positions: ['先鋒', '次鋒', '中堅', '副将', '大将'],
      );

      const match = MatchModel(
        id: 'renseikai_time_m1',
        category: '中学練成の部',
        groupName: '第1会場 錬成A',
        matchType: '団体戦',
        redName: '練成チーム1',
        whiteName: '練成チーム2',
        rule: renseikaiRule,
        note: '時間制練成会',
      );

      await tester.pumpWidget(buildTestableApp(match: match));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('open_rule_sheet_button')));
      await tester.pumpAndSettle();

      expect(find.text('試合レギュレーション確認'), findsOneWidget);
      expect(find.text('⏱️ 試合時間'), findsOneWidget);
      expect(find.text('2分 (通し/空回し)'), findsOneWidget);
      expect(find.text('進行方式'), findsOneWidget);
      expect(find.text('時間制'), findsOneWidget);
      expect(find.text('総試合時間'), findsOneWidget);
      expect(find.text('30分'), findsOneWidget);
    });

    testWidgets('7. 錬成会（一試合制）: 制限時間が非表示になり、一試合制のみが表示されること', (
      WidgetTester tester,
    ) async {
      const renseikaiRule = MatchRule(
        matchTimeMinutes: 3.0,
        isRunningTime: false,
        isIpponShobu: false,
        hasHantei: false,
        enchoCount: 0,
        isEnchoUnlimited: false,
        hasRepresentativeMatch: false,
        isRenseikai: true,
        renseikaiType: '一試合制',
        overallTimeMinutes: 0,
        positions: ['先鋒', '中堅', '大将'],
      );

      const match = MatchModel(
        id: 'renseikai_single_m1',
        category: '高校練成の部',
        groupName: '第2会場 錬成B',
        matchType: '団体戦',
        redName: '練成チーム3',
        whiteName: '練成チーム4',
        rule: renseikaiRule,
        note: '一試合制練成会',
      );

      await tester.pumpWidget(buildTestableApp(match: match));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('open_rule_sheet_button')));
      await tester.pumpAndSettle();

      expect(find.text('試合レギュレーション確認'), findsOneWidget);
      expect(find.text('⏱️ 試合時間'), findsOneWidget);
      expect(find.text('3分 (都度ストップ)'), findsOneWidget);
      expect(find.text('進行方式'), findsOneWidget);
      expect(find.text('一試合制'), findsOneWidget);
      expect(find.text('総試合時間'), findsNothing);
    });

    testWidgets('8. 団体戦で代表戦なしに設定された場合: 代表戦の個別項目（時間/延長/判定）が非表示になること', (
      WidgetTester tester,
    ) async {
      const noDaihyoRule = MatchRule(
        matchTimeMinutes: 2.0,
        isRunningTime: false,
        isIpponShobu: false,
        hasHantei: false,
        enchoCount: 0,
        isEnchoUnlimited: false,
        hasRepresentativeMatch: false,
        positions: ['先鋒', '中堅', '大将'],
      );

      const match = MatchModel(
        id: 'no_daihyo_m1',
        category: '一般の部',
        groupName: '道上剣友会A vs 相手チーム',
        matchType: '先鋒',
        redName: '道上剣友会A:山田',
        whiteName: '相手チーム:鈴木',
        rule: noDaihyoRule,
        note: '',
      );

      await tester.pumpWidget(buildTestableApp(match: match));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('open_rule_sheet_button')));
      await tester.pumpAndSettle();

      expect(find.text('試合レギュレーション確認'), findsOneWidget);
      expect(find.text('🥋 代表戦'), findsOneWidget);
      expect(find.text('なし'), findsAtLeast(1));
    });

    testWidgets('9. 特設部内戦: bunaiksenモードでもテーマ破綻なく正確なルールが表示されること', (
      WidgetTester tester,
    ) async {
      const bunaiksenRule = MatchRule(
        matchTimeMinutes: 2.0,
        isRunningTime: false,
        isIpponShobu: false,
        hasHantei: false,
        enchoCount: 0,
        isEnchoUnlimited: false,
        hasRepresentativeMatch: true,
        positions: ['先鋒', '次鋒', '中堅', '副将', '大将'],
      );

      const match = MatchModel(
        id: 'bunaiksen_m1',
        tournamentId: 'bunaiksen_123',
        category: '部内戦',
        groupName: '赤組 vs 白組',
        matchType: '先鋒',
        redName: '赤組:田中',
        whiteName: '白組:渡辺',
        rule: bunaiksenRule,
        note: '',
      );

      await tester.pumpWidget(
        buildTestableApp(match: match, isDark: true, mode: 'bunaiksen'),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('open_rule_sheet_button')));
      await tester.pumpAndSettle();

      expect(find.text('試合レギュレーション確認'), findsOneWidget);
      expect(find.text('🎯 試合形式'), findsOneWidget);
      expect(find.text('団体戦'), findsOneWidget);
    });

    testWidgets(
      '10. 【ポジション延長 誤表示回帰防止テスト】旧データや不正なデフォルト値（enchoTimeMinutes=3.0, enchoCount=0）を持つ団体戦データでも「ポジション延長」「延長戦」「判定」が100%非表示であること',
      (WidgetTester tester) async {
        const buggyLegacyRule = MatchRule(
          matchTimeMinutes: 3.0,
          isRunningTime: false,
          isIpponShobu: false,
          hasHantei: false,
          enchoTimeMinutes: 3.0,
          enchoCount: 0,
          isEnchoUnlimited: false,
          hasRepresentativeMatch: true,
          positions: ['先鋒', '中堅', '大将'],
        );

        const match = MatchModel(
          id: 'buggy_legacy_m1',
          category: '一般の部',
          groupName: 'チームA vs チームB',
          matchType: '先鋒',
          redName: 'チームA:選手1',
          whiteName: 'チームB:選手2',
          rule: buggyLegacyRule,
          note: '',
        );

        await tester.pumpWidget(buildTestableApp(match: match));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('open_rule_sheet_button')));
        await tester.pumpAndSettle();

        expect(find.text('試合レギュレーション確認'), findsOneWidget);
        expect(find.text('🎯 試合形式'), findsOneWidget);
        expect(find.text('団体戦'), findsOneWidget);
        expect(find.text('🔄 延長戦'), findsOneWidget);
        expect(find.text('なし'), findsOneWidget);
      },
    );
  });
}
