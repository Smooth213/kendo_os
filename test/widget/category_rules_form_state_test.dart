import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_chips.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_match_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rules_form_state.dart';

void main() {
  group('CategoryRulesFormState Tests', () {
    test(
      'populateFromRuleSet fills state and buildCategoryRuleSet reproduces it',
      () {
        final formState = CategoryRulesFormState();
        final initialRule = CategoryRuleSet(
          matchType: '団体戦',
          normalRule: MatchRule(
            matchTimeMinutes: 4.0,
            isRunningTime: true,
            enchoCount: 2,
          ),
          advancedRule: MatchRule(
            matchTimeMinutes: 5.0,
            isEnchoUnlimited: true,
          ),
          useAdvancedRule: true,
          advancedKeywords: ['決勝', '準決勝'],
          subtitle: '決勝トーナメント',
          comment: '3人制・代表戦あり',
        );

        formState.populateFromRuleSet('小学生の部', initialRule);

        expect(formState.editingCategory, '小学生の部');
        expect(formState.editingSubtitle, '決勝トーナメント');
        expect(formState.editingComment, '3人制・代表戦あり');
        expect(formState.normalTime, 4.0);
        expect(formState.normalIsRunningTime, isTrue);
        expect(formState.advancedTime, 5.0);
        expect(formState.useAdvancedRule, isTrue);

        final generated = formState.buildCategoryRuleSet('小学生の部');
        expect(generated.subtitle, '決勝トーナメント');
        expect(generated.comment, '3人制・代表戦あり');
        expect(generated.normalRule.matchTimeMinutes, 4.0);
        expect(generated.normalRule.isRunningTime, isTrue);
        expect(generated.advancedRule.matchTimeMinutes, 5.0);
        expect(generated.useAdvancedRule, isTrue);
        expect(generated.advancedKeywords, contains('決勝'));
      },
    );

    test('formatRuleTitle works as expected', () {
      expect(
        CategoryRuleMatchHelper.formatRuleTitle('小学生の部', '決勝トーナメント'),
        '小学生の部 決勝トーナメント',
      );
      expect(CategoryRuleMatchHelper.formatRuleTitle('小学生の部', ''), '小学生の部');
      expect(CategoryRuleMatchHelper.formatRuleTitle('小学生の部', '   '), '小学生の部');
    });

    test(
      'representative match (代表戦) OFF is correctly saved and restored without automatically turning ON',
      () {
        // 1. トーナメント団体戦で代表戦をOFFにした場合
        final formState = CategoryRulesFormState();
        formState.editingMatchType = '団体戦';
        formState.normalHasLeagueDaihyo = false;
        formState.advancedHasLeagueDaihyo = false;

        final savedRuleSet = formState.buildCategoryRuleSet('中学生男子の部');

        // MatchRule 内で両方のフラグが false になっていること
        expect(savedRuleSet.normalRule.hasRepresentativeMatch, isFalse);
        expect(savedRuleSet.normalRule.hasLeagueDaihyo, isFalse);
        expect(savedRuleSet.advancedRule.hasRepresentativeMatch, isFalse);
        expect(savedRuleSet.advancedRule.hasLeagueDaihyo, isFalse);

        // 再度フォームに読み込んだ時、勝手に true (ON) に戻らないこと
        final restoredState = CategoryRulesFormState();
        restoredState.populateFromRuleSet('中学生男子の部', savedRuleSet);

        expect(restoredState.normalHasLeagueDaihyo, isFalse);
        expect(restoredState.advancedHasLeagueDaihyo, isFalse);
        expect(restoredState.editingMatchType, '団体戦');

        // 2. リーグ団体戦で代表戦をOFFにした場合
        final leagueFormState = CategoryRulesFormState();
        leagueFormState.editingMatchType = 'リーグ団体戦';
        leagueFormState.normalHasLeagueDaihyo = false;
        leagueFormState.advancedHasLeagueDaihyo = false;

        final leagueSavedRuleSet = leagueFormState.buildCategoryRuleSet(
          '一般男子の部',
        );
        expect(leagueSavedRuleSet.normalRule.hasLeagueDaihyo, isFalse);
        expect(leagueSavedRuleSet.normalRule.hasRepresentativeMatch, isFalse);
        expect(leagueSavedRuleSet.advancedRule.hasLeagueDaihyo, isFalse);
        expect(leagueSavedRuleSet.advancedRule.hasRepresentativeMatch, isFalse);

        final leagueRestoredState = CategoryRulesFormState();
        leagueRestoredState.populateFromRuleSet('一般男子の部', leagueSavedRuleSet);

        expect(leagueRestoredState.normalHasLeagueDaihyo, isFalse);
        expect(leagueRestoredState.advancedHasLeagueDaihyo, isFalse);
        expect(leagueRestoredState.editingMatchType, 'リーグ団体戦');
      },
    );

    test('representative match (代表戦) ON is correctly saved and restored', () {
      final formState = CategoryRulesFormState();
      formState.editingMatchType = '団体戦';
      formState.normalHasLeagueDaihyo = true;
      formState.advancedHasLeagueDaihyo = true;

      final saved = formState.buildCategoryRuleSet('高校生女子の部');
      expect(saved.normalRule.hasRepresentativeMatch, isTrue);
      expect(saved.normalRule.hasLeagueDaihyo, isTrue);
      expect(saved.advancedRule.hasRepresentativeMatch, isTrue);
      expect(saved.advancedRule.hasLeagueDaihyo, isTrue);

      final restored = CategoryRulesFormState();
      restored.populateFromRuleSet('高校生女子の部', saved);
      expect(restored.normalHasLeagueDaihyo, isTrue);
      expect(restored.advancedHasLeagueDaihyo, isTrue);
    });

    test(
      'comprehensive test: all rule parameters are fully saved and faithfully restored',
      () {
        final form = CategoryRulesFormState();
        // 基本メタ
        form.editingSubtitle = '予選リーグAコート';
        form.editingComment = '本戦と申合せ併用・延長1回判定あり';
        form.editingMatchType = 'リーグ個人戦';
        form.useAdvancedRule = true;
        form.editingAdvancedKeywords = ['決勝', '準決勝', '3決'];

        // マルチシーン
        form.isMultiScene = true;
        form.useHonsenRule = true;
        form.useRenseikaiRule = true;
        form.useMoushiawaseRule = true;

        // 錬成会・申合せ
        form.renseikaiTime = 2.5;
        form.renseikaiIsRunningTime = true;
        form.renseikaiHasHantei = false;
        form.renseikaiType = '勝ち残り制';
        form.renseikaiOverallTime = 40;

        form.moushiawaseTime = 1.5;
        form.moushiawaseIsRunningTime = false;
        form.moushiawaseHasHantei = true;
        form.moushiawaseType = '一試合制';
        form.moushiawaseOverallTime = 25;

        // 通常戦パラメータ（全項目カスタム設定）
        form.normalTime = 4.5;
        form.normalIsRunningTime = true;
        form.normalIsIpponShobu = true;
        form.normalIpponLimit = 1;
        form.normalHansokuLimit = 3;
        form.normalHasHantei = true;
        form.normalHasExtension = true;
        form.normalIsEnchoUnlimited = false;
        form.normalEnchoTime = 2.5;
        form.normalEnchoCount = 3;
        form.normalKachinukiUnlimitedType = '勝者対勝者';
        form.normalHasLeagueDaihyo = false; // 代表戦 OFF
        form.normalIsDaihyoIpponShobu = false;
        form.normalWinPoint = 3.0;
        form.normalLossPoint = 0.5;
        form.normalDrawPoint = 1.5;
        form.normalRenseikaiType = '勝ち残り制';
        form.normalOverallTime = 45;

        form.normalDaihyoMatchTime = 3.5;
        form.normalDaihyoHasExtension = false;
        form.normalDaihyoEnchoTime = 2.0;
        form.normalDaihyoEnchoCount = 1;
        form.normalDaihyoHasHantei = true;

        // 上位戦パラメータ（全項目カスタム設定）
        form.advancedTime = 5.0;
        form.advancedIsRunningTime = false;
        form.advancedIsIpponShobu = false;
        form.advancedIpponLimit = 2;
        form.advancedHansokuLimit = 2;
        form.advancedHasHantei = false;
        form.advancedHasExtension = true;
        form.advancedIsEnchoUnlimited = true;
        form.advancedEnchoTime = 3.0;
        form.advancedEnchoCount = 0;
        form.advancedKachinukiUnlimitedType = '大将対大将';
        form.advancedHasLeagueDaihyo = false; // 代表戦 OFF
        form.advancedIsDaihyoIpponShobu = true;
        form.advancedWinPoint = 2.0;
        form.advancedLossPoint = 0.0;
        form.advancedDrawPoint = 1.0;
        form.advancedRenseikaiType = '一試合制';
        form.advancedOverallTime = 60;

        form.advancedDaihyoMatchTime = 5.0;
        form.advancedDaihyoHasExtension = true;
        form.advancedDaihyoEnchoTime = 3.0;
        form.advancedDaihyoEnchoCount = -2;
        form.advancedDaihyoHasHantei = false;

        // 保存実行
        const categoryName = '中学生の部';
        final savedRuleSet = form.buildCategoryRuleSet(categoryName);

        // 復元実行
        final restored = CategoryRulesFormState();
        restored.populateFromRuleSet(categoryName, savedRuleSet);

        // 検証: メタ
        expect(restored.editingCategory, categoryName);
        expect(restored.editingSubtitle, '予選リーグAコート');
        expect(restored.editingComment, '本戦と申合せ併用・延長1回判定あり');
        expect(restored.editingMatchType, 'リーグ個人戦');
        expect(restored.useAdvancedRule, isTrue);
        expect(restored.editingAdvancedKeywords, equals(['決勝', '準決勝', '3決']));

        // 検証: マルチシーン
        expect(restored.isMultiScene, isTrue);
        expect(restored.useHonsenRule, isTrue);
        expect(restored.useRenseikaiRule, isTrue);
        expect(restored.useMoushiawaseRule, isTrue);

        // 検証: 錬成会・申合せ
        expect(restored.renseikaiTime, 2.5);
        expect(restored.renseikaiIsRunningTime, isTrue);
        expect(restored.renseikaiHasHantei, isFalse);
        expect(restored.renseikaiType, '勝ち残り制');
        expect(restored.renseikaiOverallTime, 40);

        expect(restored.moushiawaseTime, 1.5);
        expect(restored.moushiawaseIsRunningTime, isFalse);
        expect(restored.moushiawaseHasHantei, isTrue);
        expect(restored.moushiawaseType, '一試合制');
        expect(restored.moushiawaseOverallTime, 25);

        // 検証: 通常戦パラメータ
        expect(restored.normalTime, 4.5);
        expect(restored.normalIsRunningTime, isTrue);
        expect(restored.normalIsIpponShobu, isTrue);
        expect(restored.normalIpponLimit, 1);
        expect(restored.normalHansokuLimit, 3);
        expect(restored.normalHasHantei, isTrue);
        expect(restored.normalHasExtension, isTrue);
        expect(restored.normalIsEnchoUnlimited, isFalse);
        expect(restored.normalEnchoTime, 2.5);
        expect(restored.normalEnchoCount, 3);
        expect(restored.normalKachinukiUnlimitedType, '勝者対勝者');
        expect(restored.normalHasLeagueDaihyo, isFalse); // 代表戦OFFが正しく維持
        expect(restored.normalIsDaihyoIpponShobu, isFalse);
        expect(restored.normalWinPoint, 3.0);
        expect(restored.normalLossPoint, 0.5);
        expect(restored.normalDrawPoint, 1.5);
        expect(restored.normalRenseikaiType, '勝ち残り制');
        expect(restored.normalOverallTime, 45);

        expect(restored.normalDaihyoMatchTime, 3.5);
        expect(restored.normalDaihyoHasExtension, isFalse);
        expect(restored.normalDaihyoEnchoTime, 2.0);
        expect(restored.normalDaihyoEnchoCount, 1);
        expect(restored.normalDaihyoHasHantei, isTrue);

        // 検証: 上位戦パラメータ
        expect(restored.advancedTime, 5.0);
        expect(restored.advancedIsRunningTime, isFalse);
        expect(restored.advancedIsIpponShobu, isFalse);
        expect(restored.advancedIpponLimit, 2);
        expect(restored.advancedHansokuLimit, 2);
        expect(restored.advancedHasHantei, isFalse);
        expect(restored.advancedHasExtension, isTrue);
        expect(restored.advancedIsEnchoUnlimited, isTrue);
        expect(restored.advancedEnchoTime, 3.0);
        expect(restored.advancedEnchoCount, 0);
        expect(restored.advancedKachinukiUnlimitedType, '大将対大将');
        expect(restored.advancedHasLeagueDaihyo, isFalse); // 代表戦OFFが正しく維持
        expect(restored.advancedIsDaihyoIpponShobu, isTrue);
        expect(restored.advancedWinPoint, 2.0);
        expect(restored.advancedLossPoint, 0.0);
        expect(restored.advancedDrawPoint, 1.0);
        expect(restored.advancedRenseikaiType, '一試合制');
        expect(restored.advancedOverallTime, 60);

        expect(restored.advancedDaihyoMatchTime, 5.0);
        expect(restored.advancedDaihyoHasExtension, isTrue);
        expect(restored.advancedDaihyoEnchoTime, 3.0);
        expect(restored.advancedDaihyoEnchoCount, -2);
        expect(restored.advancedDaihyoHasHantei, isFalse);
      },
    );

    test(
      'team match (団体戦) does not have normal match extension, only daihyo extension, and CategoryRuleChips does not show "延長1回"',
      () {
        final form = CategoryRulesFormState();
        form.editingMatchType = '団体戦';
        form.normalHasLeagueDaihyo = true;
        // 代表戦の延長設定
        form.normalDaihyoHasExtension = true;
        form.normalDaihyoEnchoCount = -2; // 無制限

        final saved = form.buildCategoryRuleSet('中学生男子の部');

        // 団体戦では通常戦（先鋒〜大将）の延長は無効（0回・延長なし）となること
        expect(saved.normalRule.enchoCount, 0);
        expect(saved.normalRule.isEnchoUnlimited, isFalse);
        expect(saved.advancedRule.enchoCount, 0);
        expect(saved.advancedRule.isEnchoUnlimited, isFalse);

        // 代表戦の延長は正しく保持されていること
        expect(saved.normalRule.hasRepresentativeMatch, isTrue);
        expect(saved.normalRule.daihyoHasExtension, isTrue);
        expect(saved.normalRule.daihyoEnchoCount, -2);
      },
    );

    testWidgets(
      'CategoryRuleChips does not show extension badge for team match (even if rule has enchoCount)',
      (tester) async {
        final ruleSet = CategoryRuleSet(
          matchType: '団体戦',
          normalRule: const MatchRule(
            matchTimeMinutes: 3.0,
            enchoCount: 1, // 既存データ等で1が残っている場合
            hasRepresentativeMatch: true,
          ),
          advancedRule: const MatchRule(matchTimeMinutes: 3.0, enchoCount: 1),
          useAdvancedRule: false,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CategoryRuleChips(ruleSet: ruleSet, isDark: false),
            ),
          ),
        );

        // 団体戦では通常戦の延長バッジが表示されないこと
        expect(find.textContaining('延長1回'), findsNothing);
        expect(find.textContaining('延長無制限'), findsNothing);
        // 代表戦有は表示されること
        expect(find.textContaining('代表戦有'), findsOneWidget);
      },
    );

    testWidgets(
      'CategoryRuleChips shows extension badge for individual match when enchoCount > 0',
      (tester) async {
        final ruleSet = CategoryRuleSet(
          matchType: '個人戦',
          normalRule: const MatchRule(matchTimeMinutes: 3.0, enchoCount: 1),
          advancedRule: const MatchRule(matchTimeMinutes: 3.0),
          useAdvancedRule: false,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CategoryRuleChips(ruleSet: ruleSet, isDark: false),
            ),
          ),
        );

        // 個人戦では延長バッジが表示されること
        expect(find.textContaining('延長1回'), findsOneWidget);
      },
    );

    test('ipponLimit = 1 correctly synchronizes isIpponShobu to true', () {
      final formState = CategoryRulesFormState();
      formState.normalIpponLimit = 1;
      formState.advancedIpponLimit = 1;

      final ruleSet = formState.buildCategoryRuleSet('小学生の部');
      expect(ruleSet.normalRule.isIpponShobu, isTrue);
      expect(ruleSet.normalRule.ipponLimit, 1);
      expect(ruleSet.advancedRule.isIpponShobu, isTrue);
      expect(ruleSet.advancedRule.ipponLimit, 1);

      // 再度復元した場合も isIpponShobu が true のまま維持されること
      final restored = CategoryRulesFormState();
      restored.populateFromRuleSet('小学生の部', ruleSet);
      expect(restored.normalIsIpponShobu, isTrue);
      expect(restored.normalIpponLimit, 1);
      expect(restored.advancedIsIpponShobu, isTrue);
      expect(restored.advancedIpponLimit, 1);
    });
  });
}
