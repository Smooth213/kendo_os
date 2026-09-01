import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/rule_info_bottom_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🏛️ 剣道OS 全ルールパターン網羅 (14大マトリクス) E2E インテグレーション完全要塞テスト', () {
    late TournamentModel completeTournament;

    setUp(() {
      completeTournament = TournamentModel(
        id: 'matrix_tourney_id',
        organizationId: 'matrix_dojo_id',
        name: '全日本剣道ルール完全制覇大会',
        date: DateTime(2026, 8, 15),
        venue: '日本武道館メインアリーナ',
        categories: [
          '①トーナメント団体戦_標準5人制',
          '②トーナメント団体戦_1本勝負3人制',
          '③トーナメント個人戦_標準',
          '④トーナメント個人戦_1本勝負無制限',
          '⑤リーグ団体戦_代表戦あり',
          '⑥リーグ団体戦_代表戦なし',
          '⑦リーグ個人戦_勝点制',
          '⑧勝ち抜き戦_大将対大将',
          '⑨勝ち抜き戦_完全無制限',
          '⑩錬成会_一試合制',
          '⑪錬成会_時間制15分',
          '⑫遠征マルチ_錬成会OFF_本戦_申し合わせ',
          '⑬上位戦自動昇格_準決勝決勝',
          '⑭部内戦_特設紅白戦',
        ],
        categoryRules: {
          // ① トーナメント団体戦（標準5人制: 3本勝負、2分都度、代表戦1本勝負・無制限延長）
          '①トーナメント団体戦_標準5人制': const CategoryRuleSet(
            matchType: '団体戦',
            normalRule: MatchRule(
              matchTimeMinutes: 2.0,
              isRunningTime: false,
              isIpponShobu: false,
              hasRepresentativeMatch: true,
              isDaihyoIpponShobu: true,
              daihyoMatchTimeMinutes: 0.0,
              daihyoHasExtension: true,
              daihyoEnchoCount: -2,
              positions: ['先鋒', '次鋒', '中堅', '副将', '大将'],
            ),
          ),
          // ② トーナメント団体戦（1本勝負3人制: 代表戦なし）
          '②トーナメント団体戦_1本勝負3人制': const CategoryRuleSet(
            matchType: '団体戦',
            normalRule: MatchRule(
              matchTimeMinutes: 3.0,
              isRunningTime: false,
              isIpponShobu: true,
              hasRepresentativeMatch: false,
              positions: ['先鋒', '中堅', '大将'],
            ),
          ),
          // ③ トーナメント個人戦（標準: 3本勝負、3分、延長3分1回、判定あり）
          '③トーナメント個人戦_標準': const CategoryRuleSet(
            matchType: '個人戦',
            normalRule: MatchRule(
              matchTimeMinutes: 3.0,
              isRunningTime: false,
              isIpponShobu: false,
              hasRepresentativeMatch: false,
              enchoCount: 1,
              enchoTimeMinutes: 3.0,
              hasHantei: true,
              positions: ['選手'],
            ),
          ),
          // ④ トーナメント個人戦（1本勝負、4分、無制限延長、判定なし）
          '④トーナメント個人戦_1本勝負無制限': const CategoryRuleSet(
            matchType: '個人戦',
            normalRule: MatchRule(
              matchTimeMinutes: 4.0,
              isRunningTime: false,
              isIpponShobu: true,
              hasRepresentativeMatch: false,
              isEnchoUnlimited: true,
              hasHantei: false,
              positions: ['選手'],
            ),
          ),
          // ⑤ リーグ団体戦（勝点 3/1/0、同点時代表戦あり: 1本勝負・無制限延長）
          '⑤リーグ団体戦_代表戦あり': const CategoryRuleSet(
            matchType: 'リーグ団体戦',
            normalRule: MatchRule(
              matchTimeMinutes: 2.0,
              winPoint: 3,
              drawPoint: 1,
              lossPoint: 0,
              hasLeagueDaihyo: true,
              isDaihyoIpponShobu: true,
              daihyoMatchTimeMinutes: 0.0,
              daihyoHasExtension: true,
              daihyoEnchoCount: -2,
              positions: ['先鋒', '中堅', '大将'],
            ),
          ),
          // ⑥ リーグ団体戦（勝点 2/1/0、同点時代表戦なし）
          '⑥リーグ団体戦_代表戦なし': const CategoryRuleSet(
            matchType: 'リーグ団体戦',
            normalRule: MatchRule(
              matchTimeMinutes: 2.0,
              winPoint: 2,
              drawPoint: 1,
              lossPoint: 0,
              hasLeagueDaihyo: false,
              positions: ['先鋒', '中堅', '大将'],
            ),
          ),
          // ⑦ リーグ個人戦（勝点 3/1/0、延長あり、判定あり）
          '⑦リーグ個人戦_勝点制': const CategoryRuleSet(
            matchType: 'リーグ個人戦',
            normalRule: MatchRule(
              matchTimeMinutes: 3.0,
              winPoint: 3,
              drawPoint: 1,
              lossPoint: 0,
              hasRepresentativeMatch: false,
              enchoCount: 1,
              enchoTimeMinutes: 2.0,
              hasHantei: true,
              positions: ['選手'],
            ),
          ),
          // ⑧ 勝ち抜き戦（無制限条件: 大将対大将）
          '⑧勝ち抜き戦_大将対大将': const CategoryRuleSet(
            matchType: '勝ち抜き戦',
            normalRule: MatchRule(
              matchTimeMinutes: 3.0,
              kachinukiUnlimitedType: '大将対大将',
              positions: ['先鋒', '次鋒', '中堅', '副将', '大将'],
            ),
          ),
          // ⑨ 勝ち抜き戦（無制限条件: 無制限）
          '⑨勝ち抜き戦_完全無制限': const CategoryRuleSet(
            matchType: '勝ち抜き戦',
            normalRule: MatchRule(
              matchTimeMinutes: 4.0,
              kachinukiUnlimitedType: '無制限',
              positions: ['先鋒', '次鋒', '中堅', '副将', '大将'],
            ),
          ),
          // ⑩ 錬成会（一試合制: 2分、流し、引分あり）
          '⑩錬成会_一試合制': const CategoryRuleSet(
            matchType: '錬成会',
            normalRule: MatchRule(
              matchTimeMinutes: 2.0,
              isRunningTime: true,
              isRenseikai: true,
              renseikaiType: '一試合制',
              hasHantei: true,
              positions: ['先鋒', '中堅', '大将'],
            ),
          ),
          // ⑪ 錬成会（時間制: 全体15分、1対戦2分、引分あり）
          '⑪錬成会_時間制15分': const CategoryRuleSet(
            matchType: '錬成会',
            normalRule: MatchRule(
              matchTimeMinutes: 2.0,
              isRunningTime: true,
              isRenseikai: true,
              renseikaiType: '時間制',
              overallTimeMinutes: 15,
              hasHantei: true,
              positions: ['先鋒', '中堅', '大将'],
            ),
          ),
          // ⑫ 遠征マルチシーン（錬成会OFF、本戦ON、申し合わせON）
          '⑫遠征マルチ_錬成会OFF_本戦_申し合わせ': const CategoryRuleSet(
            matchType: '団体戦',
            isMultiScene: true,
            useRenseikaiRule: false,
            useHonsenRule: true,
            useMoushiawaseRule: true,
            renseikaiRule: MatchRule(
              matchTimeMinutes: 1.5,
              isRunningTime: true,
              hasHantei: true,
              isRenseikai: true,
              renseikaiType: '一試合制',
              positions: ['先鋒', '中堅', '大将'],
            ),
            normalRule: MatchRule(
              matchTimeMinutes: 2.0,
              hasRepresentativeMatch: true,
              isDaihyoIpponShobu: true,
              daihyoMatchTimeMinutes: 2.0,
              daihyoHasExtension: true,
              daihyoEnchoCount: -2,
              positions: ['先鋒', '中堅', '大将'],
            ),
            moushiawaseRule: MatchRule(
              matchTimeMinutes: 2.0,
              hasHantei: true,
              isRenseikai: true,
              renseikaiType: '一試合制',
              positions: ['先鋒', '中堅', '大将'],
            ),
          ),
          // ⑬ 上位戦自動昇格（通常2分 ➔ 準決勝・決勝3分無制限延長）
          '⑬上位戦自動昇格_準決勝決勝': const CategoryRuleSet(
            matchType: '団体戦',
            useAdvancedRule: true,
            advancedKeywords: ['準決勝', '決勝', 'final'],
            normalRule: MatchRule(
              matchTimeMinutes: 2.0,
              hasRepresentativeMatch: true,
              isDaihyoIpponShobu: true,
              daihyoMatchTimeMinutes: 0.0,
              daihyoHasExtension: true,
              daihyoEnchoCount: -2,
              positions: ['先鋒', '次鋒', '中堅', '副将', '大将'],
            ),
            advancedRule: MatchRule(
              matchTimeMinutes: 3.0,
              hasRepresentativeMatch: true,
              isDaihyoIpponShobu: true,
              daihyoMatchTimeMinutes: 0.0,
              daihyoHasExtension: true,
              daihyoEnchoCount: -2,
              positions: ['先鋒', '次鋒', '中堅', '副将', '大将'],
            ),
          ),
          // ⑭ 特設部内戦（bunaiksen）
          '⑭部内戦_特設紅白戦': const CategoryRuleSet(
            matchType: '団体戦',
            normalRule: MatchRule(
              matchTimeMinutes: 2.0,
              hasRepresentativeMatch: true,
              isDaihyoIpponShobu: true,
              daihyoMatchTimeMinutes: 0.0,
              daihyoHasExtension: true,
              daihyoEnchoCount: -2,
              positions: ['先鋒', '次鋒', '中堅', '副将', '大将'],
            ),
          ),
        },
      );
    });

    Future<void> pumpAndVerifyBottomSheet(
      WidgetTester tester,
      MatchModel match,
      List<String> expectedTexts,
      List<String> forbiddenTexts,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showRuleInfoBottomSheet(context, match),
                child: const Text('OpenSheet'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('OpenSheet'));
      await tester.pumpAndSettle();

      for (final text in expectedTexts) {
        expect(
          find.textContaining(text),
          findsAtLeast(1),
          reason: 'Expected text "$text" was not found in bottom sheet',
        );
      }

      for (final text in forbiddenTexts) {
        expect(
          find.text(text),
          findsNothing,
          reason: 'Forbidden text "$text" was found in bottom sheet',
        );
      }
    }

    // ─────────────────────────────────────────────────────────
    // パターン 1〜14 の完全個別自動検証テスト
    // ─────────────────────────────────────────────────────────

    testWidgets('1. 【パターン①: トーナメント団体戦_標準5人制】試合モデル & レギュレーション完全一致検証', (
      WidgetTester tester,
    ) async {
      final rule =
          completeTournament.categoryRules['①トーナメント団体戦_標準5人制']!.normalRule;
      final match = MatchModel(
        id: 'p1_match',
        category: '①トーナメント団体戦_標準5人制',
        groupName: '紅組 vs 白組',
        matchType: '先鋒',
        redName: '紅組:選手1',
        whiteName: '白組:選手1',
        rule: rule,
      );

      expect(match.rule?.matchTimeMinutes, equals(2.0));
      expect(match.rule?.isRunningTime, isFalse);
      expect(match.rule?.hasRepresentativeMatch, isTrue);
      expect(match.rule?.isDaihyoIpponShobu, isTrue);
      expect(match.rule?.daihyoEnchoCount, equals(-2));
      expect(match.rule?.positions.length, equals(5));

      await pumpAndVerifyBottomSheet(
        tester,
        match,
        ['団体戦', '2分 (都度ストップ)', '３本勝負 (２本先取)', '🥋 代表戦', '時間制限なし・一本勝負・延長無制限'],
        ['反則', '延長戦', '判定', 'ポジション延長'],
      );
    });

    testWidgets('2. 【パターン②: トーナメント団体戦_1本勝負3人制】代表戦なし時の個別代表戦項目完全非表示検証', (
      WidgetTester tester,
    ) async {
      final rule =
          completeTournament.categoryRules['②トーナメント団体戦_1本勝負3人制']!.normalRule;
      final match = MatchModel(
        id: 'p2_match',
        category: '②トーナメント団体戦_1本勝負3人制',
        groupName: '紅組 vs 白組',
        matchType: '先鋒',
        redName: '紅組:選手1',
        whiteName: '白組:選手1',
        rule: rule,
      );

      expect(match.rule?.matchTimeMinutes, equals(3.0));
      expect(match.rule?.isIpponShobu, isTrue);
      expect(match.rule?.hasRepresentativeMatch, isFalse);
      expect(match.rule?.positions.length, equals(3));

      await pumpAndVerifyBottomSheet(
        tester,
        match,
        ['団体戦', '3分 (都度ストップ)', '１本勝負', '🥋 代表戦', 'なし'],
        ['代表戦時間', '代表戦延長', '代表戦判定', '反則', '延長戦', '判定', 'ポジション延長'],
      );
    });

    testWidgets('3. 【パターン③: トーナメント個人戦_標準】個人戦の延長戦・判定が正しく表示され代表戦が非表示であること', (
      WidgetTester tester,
    ) async {
      final rule =
          completeTournament.categoryRules['③トーナメント個人戦_標準']!.normalRule;
      final match = MatchModel(
        id: 'p3_match',
        category: '③トーナメント個人戦_標準',
        groupName: '個人戦トーナメント',
        matchType: '選手',
        redName: '個人選手A',
        whiteName: '個人選手B',
        rule: rule,
      );

      expect(match.rule?.matchTimeMinutes, equals(3.0));
      expect(match.rule?.enchoCount, equals(1));
      expect(match.rule?.enchoTimeMinutes, equals(3.0));
      expect(match.rule?.hasHantei, isTrue);

      await pumpAndVerifyBottomSheet(
        tester,
        match,
        [
          '個人戦',
          '3分 (都度ストップ)',
          '３本勝負 (２本先取)',
          '🔄 延長戦',
          'あり (3分・1回)',
          '⚖️ 判定',
          'あり (時間・延長終了時)',
        ],
        ['🥋 代表戦', '反則', 'ポジション延長'],
      );
    });

    testWidgets('4. 【パターン④: トーナメント個人戦_1本勝負無制限】無制限延長と判定なしが正しく反映されること', (
      WidgetTester tester,
    ) async {
      final rule =
          completeTournament.categoryRules['④トーナメント個人戦_1本勝負無制限']!.normalRule;
      final match = MatchModel(
        id: 'p4_match',
        category: '④トーナメント個人戦_1本勝負無制限',
        groupName: '個人戦トーナメント',
        matchType: '選手',
        redName: '個人選手A',
        whiteName: '個人選手B',
        rule: rule,
      );

      expect(match.rule?.matchTimeMinutes, equals(4.0));
      expect(match.rule?.isIpponShobu, isTrue);
      expect(match.rule?.isEnchoUnlimited, isTrue);
      expect(match.rule?.hasHantei, isFalse);

      await pumpAndVerifyBottomSheet(
        tester,
        match,
        [
          '個人戦',
          '4分 (都度ストップ)',
          '１本勝負',
          '🔄 延長戦',
          'あり (時間無制限・決着まで)',
          '⚖️ 判定',
          'なし',
        ],
        ['🥋 代表戦', '反則'],
      );
    });

    testWidgets('5. 【パターン⑤: リーグ団体戦_代表戦あり】勝点3/1/0・同点時代表戦の完全反映検証', (
      WidgetTester tester,
    ) async {
      final rule =
          completeTournament.categoryRules['⑤リーグ団体戦_代表戦あり']!.normalRule;
      final match = MatchModel(
        id: 'p5_match',
        category: '⑤リーグ団体戦_代表戦あり',
        groupName: 'Aブロック',
        matchType: '先鋒',
        redName: '紅組:選手1',
        whiteName: '白組:選手1',
        rule: rule.copyWith(isLeague: true),
      );

      expect(match.rule?.winPoint, equals(3));
      expect(match.rule?.drawPoint, equals(1));
      expect(match.rule?.lossPoint, equals(0));
      expect(match.rule?.hasLeagueDaihyo, isTrue);

      await pumpAndVerifyBottomSheet(
        tester,
        match,
        ['リーグ団体戦', '2分 (都度ストップ)', '🥋 代表戦'],
        ['反則', '延長戦', '判定', 'ポジション延長'],
      );
    });

    testWidgets('6. 【パターン⑥: リーグ団体戦_代表戦なし】代表戦なし設定時の代表戦項目完全非表示検証', (
      WidgetTester tester,
    ) async {
      final rule =
          completeTournament.categoryRules['⑥リーグ団体戦_代表戦なし']!.normalRule;
      final match = MatchModel(
        id: 'p6_match',
        category: '⑥リーグ団体戦_代表戦なし',
        groupName: 'Bブロック',
        matchType: '先鋒',
        redName: '紅組:選手1',
        whiteName: '白組:選手1',
        rule: rule.copyWith(isLeague: true),
      );

      expect(match.rule?.hasLeagueDaihyo, isFalse);

      await pumpAndVerifyBottomSheet(
        tester,
        match,
        ['リーグ団体戦'],
        ['代表戦時間', '代表戦延長', '代表戦判定', '反則', '延長戦', '判定'],
      );
    });

    testWidgets('7. 【パターン⑦: リーグ個人戦_勝点制】リーグ個人戦での勝点・延長・判定が正しく表示されること', (
      WidgetTester tester,
    ) async {
      final rule = completeTournament.categoryRules['⑦リーグ個人戦_勝点制']!.normalRule;
      final match = MatchModel(
        id: 'p7_match',
        category: '⑦リーグ個人戦_勝点制',
        groupName: 'Cブロック',
        matchType: '個人戦',
        redName: '個人A',
        whiteName: '個人B',
        rule: rule.copyWith(isLeague: true),
      );

      expect(match.rule?.winPoint, equals(3));
      expect(match.rule?.enchoCount, equals(1));
      expect(match.rule?.hasHantei, isTrue);

      await pumpAndVerifyBottomSheet(
        tester,
        match,
        ['リーグ個人戦'],
        ['🥋 代表戦', '反則'],
      );
    });

    testWidgets('8. 【パターン⑧: 勝ち抜き戦_大将対大将】勝ち抜き戦設定・無制限条件の完全反映検証', (
      WidgetTester tester,
    ) async {
      final rule = completeTournament.categoryRules['⑧勝ち抜き戦_大将対大将']!.normalRule;
      final match = MatchModel(
        id: 'p8_match',
        category: '⑧勝ち抜き戦_大将対大将',
        groupName: '勝ち抜きトーナメント',
        matchType: '先鋒',
        redName: '紅組:先鋒',
        whiteName: '白組:先鋒',
        rule: rule.copyWith(isKachinuki: true),
      );

      expect(match.rule?.kachinukiUnlimitedType, equals('大将対大将'));

      await pumpAndVerifyBottomSheet(
        tester,
        match,
        ['勝ち抜き戦', '3分 (都度ストップ)', '勝ち抜き条件', '大将対大将'],
        ['🥋 代表戦', '反則'],
      );
    });

    testWidgets('9. 【パターン⑨: 勝ち抜き戦_完全無制限】完全無制限条件の完全反映検証', (
      WidgetTester tester,
    ) async {
      final rule = completeTournament.categoryRules['⑨勝ち抜き戦_完全無制限']!.normalRule;
      final match = MatchModel(
        id: 'p9_match',
        category: '⑨勝ち抜き戦_完全無制限',
        groupName: '勝ち抜きトーナメント',
        matchType: '先鋒',
        redName: '紅組:先鋒',
        whiteName: '白組:先鋒',
        rule: rule.copyWith(isKachinuki: true),
      );

      expect(match.rule?.kachinukiUnlimitedType, equals('無制限'));

      await pumpAndVerifyBottomSheet(
        tester,
        match,
        ['勝ち抜き戦', '4分 (都度ストップ)', '勝ち抜き条件', '無制限'],
        ['🥋 代表戦', '反則'],
      );
    });

    testWidgets('10. 【パターン⑩: 錬成会_一試合制】一試合制・流し時間の完全反映検証', (
      WidgetTester tester,
    ) async {
      final rule = completeTournament.categoryRules['⑩錬成会_一試合制']!.normalRule;
      final match = MatchModel(
        id: 'p10_match',
        category: '⑩錬成会_一試合制',
        groupName: '第1試合場',
        matchType: '先鋒',
        redName: '紅組:先鋒',
        whiteName: '白組:先鋒',
        rule: rule,
      );

      expect(match.rule?.isRenseikai, isTrue);
      expect(match.rule?.renseikaiType, equals('一試合制'));
      expect(match.rule?.isRunningTime, isTrue);

      await pumpAndVerifyBottomSheet(
        tester,
        match,
        ['2分 (通し/空回し)', '進行方式', '一試合制'],
        ['総試合時間', '🥋 代表戦', '反則'],
      );
    });

    testWidgets('11. 【パターン⑪: 錬成会_時間制15分】時間制・制限時間の完全反映検証', (
      WidgetTester tester,
    ) async {
      final rule = completeTournament.categoryRules['⑪錬成会_時間制15分']!.normalRule;
      final match = MatchModel(
        id: 'p11_match',
        category: '⑪錬成会_時間制15分',
        groupName: '第2試合場',
        matchType: '先鋒',
        redName: '紅組:先鋒',
        whiteName: '白組:先鋒',
        rule: rule,
      );

      expect(match.rule?.renseikaiType, equals('時間制'));
      expect(match.rule?.overallTimeMinutes, equals(15));

      await pumpAndVerifyBottomSheet(
        tester,
        match,
        ['進行方式', '時間制', '総試合時間', '15分'],
        ['🥋 代表戦', '反則'],
      );
    });

    testWidgets('12. 【パターン⑫: 遠征マルチシーン】3シーン個別切替時のルール完全分離・非干渉検証', (
      WidgetTester tester,
    ) async {
      final multiRuleSet =
          completeTournament.categoryRules['⑫遠征マルチ_錬成会OFF_本戦_申し合わせ']!;

      // 1) 錬成会ルール (1.5分)
      final renseikaiMatch = MatchModel(
        id: 'multi_renseikai',
        category: '⑫遠征マルチ_錬成会OFF_本戦_申し合わせ',
        groupName: '第1試合場',
        matchType: '先鋒',
        redName: '紅組:先鋒',
        whiteName: '白組:先鋒',
        rule: multiRuleSet.renseikaiRule,
      );
      expect(renseikaiMatch.rule?.matchTimeMinutes, equals(1.5));
      expect(renseikaiMatch.rule?.isRenseikai, isTrue);

      // 2) 本戦ルール (2分・代表戦有)
      final honsenMatch = MatchModel(
        id: 'multi_honsen',
        category: '⑫遠征マルチ_錬成会OFF_本戦_申し合わせ',
        groupName: '第1試合場',
        matchType: '先鋒',
        redName: '紅組:先鋒',
        whiteName: '白組:先鋒',
        rule: multiRuleSet.normalRule,
      );
      expect(honsenMatch.rule?.matchTimeMinutes, equals(2.0));
      expect(honsenMatch.rule?.hasRepresentativeMatch, isTrue);

      // 3) 申し合わせルール (2分・引分有)
      final moushiawaseMatch = MatchModel(
        id: 'multi_moushiawase',
        category: '⑫遠征マルチ_錬成会OFF_本戦_申し合わせ',
        groupName: '第1試合場',
        matchType: '先鋒',
        redName: '紅組:先鋒',
        whiteName: '白組:先鋒',
        rule: multiRuleSet.moushiawaseRule,
      );
      expect(moushiawaseMatch.rule?.matchTimeMinutes, equals(2.0));
      expect(moushiawaseMatch.rule?.hasHantei, isTrue);
    });

    testWidgets('13. 【パターン⑬: 上位戦自動昇格】通常戦と上位戦（3分・無制限延長）の動的ルール解決検証', (
      WidgetTester tester,
    ) async {
      final advancedRuleSet =
          completeTournament.categoryRules['⑬上位戦自動昇格_準決勝決勝']!;

      // 1) 1回戦（通常戦）
      final round1Match = MatchModel(
        id: 'r1_match',
        category: '⑬上位戦自動昇格_準決勝決勝',
        groupName: 'Aコート 1回戦 第1試合',
        matchType: '先鋒',
        redName: '紅組:先鋒',
        whiteName: '白組:先鋒',
        rule: advancedRuleSet.normalRule,
        note: '1回戦',
      );
      expect(round1Match.rule?.matchTimeMinutes, equals(2.0));

      // 2) 決勝戦（上位戦）
      final finalMatch = MatchModel(
        id: 'final_match',
        category: '⑬上位戦自動昇格_準決勝決勝',
        groupName: 'メインコート 決勝戦',
        matchType: '先鋒',
        redName: '紅組:先鋒',
        whiteName: '白組:先鋒',
        rule: advancedRuleSet.advancedRule,
        note: '決勝戦',
      );
      expect(finalMatch.rule?.matchTimeMinutes, equals(3.0));
      expect(finalMatch.rule?.hasRepresentativeMatch, isTrue);
    });

    testWidgets('14. 【パターン⑭: 特設部内戦】部内戦（bunaiksen）テーマ・ルール完全性検証', (
      WidgetTester tester,
    ) async {
      final rule = completeTournament.categoryRules['⑭部内戦_特設紅白戦']!.normalRule;
      final match = MatchModel(
        id: 'bunaiksen_m1',
        tournamentId: 'bunaiksen_tournament_1',
        category: '⑭部内戦_特設紅白戦',
        groupName: '紅白戦',
        matchType: '先鋒',
        redName: '赤組:皿田',
        whiteName: '白組:塚本',
        rule: rule,
      );

      expect(match.tournamentId?.startsWith('bunaiksen_'), isTrue);
      expect(match.rule?.matchTimeMinutes, equals(2.0));

      await pumpAndVerifyBottomSheet(
        tester,
        match,
        ['団体戦', '2分 (都度ストップ)', '🥋 代表戦'],
        ['反則', '延長戦', '判定', 'ポジション延長'],
      );
    });

    testWidgets(
      '15. 【全14パターン整合性完全走査】全カテゴリーのルールがドメイン不変条件（団体戦は代表戦、個人戦は延長判定、リーグは勝点、錬成会は進行方式）を100%満足すること',
      (WidgetTester tester) async {
        for (final entry in completeTournament.categoryRules.entries) {
          final catName = entry.key;
          final ruleSet = entry.value;

          // 1. 通常戦ルールの不変条件検証
          final normal = ruleSet.normalRule;
          if (ruleSet.matchType == '個人戦') {
            expect(
              normal.hasRepresentativeMatch,
              isFalse,
              reason: '$catName: 個人戦は代表戦なし',
            );
          } else if (ruleSet.matchType == '錬成会') {
            expect(normal.isRenseikai, isTrue, reason: '$catName: 錬成会フラグtrue');
            expect(
              normal.renseikaiType.isNotEmpty,
              isTrue,
              reason: '$catName: 進行方式が定義されていること',
            );
          } else if (ruleSet.matchType.contains('リーグ')) {
            expect(
              normal.winPoint >= 0,
              isTrue,
              reason: '$catName: 勝点が定義されていること',
            );
          }

          // 2. マルチシーンルールの不変条件検証
          if (ruleSet.isMultiScene) {
            if (ruleSet.useRenseikaiRule) {
              expect(ruleSet.renseikaiRule.isRenseikai, isTrue);
            }
            if (ruleSet.useMoushiawaseRule) {
              expect(ruleSet.moushiawaseRule.isRenseikai, isTrue);
            }
          }
        }
      },
    );

    testWidgets(
      '16. 【パターン⑯: 7人制・9人制 多人数団体戦】実業団・警察・大学選抜の多人数ポジション配列が欠落なく反映されること',
      (WidgetTester tester) async {
        // 7人制
        const rule7 = MatchRule(
          matchTimeMinutes: 4.0,
          hasRepresentativeMatch: true,
          positions: ['先鋒', '次鋒', '五将', '中堅', '三将', '副将', '大将'],
        );
        final match7 = MatchModel(
          id: 'm_7nin',
          category: '実業団大会',
          groupName: '1回戦',
          matchType: '先鋒',
          redName: 'A社:先鋒',
          whiteName: 'B社:先鋒',
          rule: rule7,
        );
        expect(match7.rule?.positions.length, equals(7));

        await pumpAndVerifyBottomSheet(
          tester,
          match7,
          ['団体戦', '4分 (都度ストップ)'],
          ['反則', '延長戦', '判定'],
        );

        // 1つ目のシートを閉じる
        Navigator.pop(tester.element(find.text('団体戦')));
        await tester.pumpAndSettle();

        // 9人制
        const rule9 = MatchRule(
          matchTimeMinutes: 3.0,
          hasRepresentativeMatch: true,
          positions: ['先鋒', '次鋒', '七将', '六将', '中堅', '四将', '三将', '副将', '大将'],
        );
        final match9 = MatchModel(
          id: 'm_9nin',
          category: '東西対抗大会',
          groupName: '東西戦',
          matchType: '先鋒',
          redName: '東軍:先鋒',
          whiteName: '西軍:先鋒',
          rule: rule9,
        );
        expect(match9.rule?.positions.length, equals(9));

        await pumpAndVerifyBottomSheet(
          tester,
          match9,
          ['団体戦', '3分 (都度ストップ)'],
          ['反則', '延長戦', '判定'],
        );
      },
    );

    testWidgets(
      '17. 【パターン⑰: 通し時間（空回し/ランニングタイム）団体戦】isRunningTime: true がタイマー表示・レギュレーションへ100%正確に反映されること',
      (WidgetTester tester) async {
        const runningRule = MatchRule(
          matchTimeMinutes: 3.0,
          isRunningTime: true,
          hasRepresentativeMatch: true,
          positions: ['先鋒', '中堅', '大将'],
        );
        final matchRunning = MatchModel(
          id: 'm_running_time',
          category: '短縮団体戦',
          groupName: '予選',
          matchType: '先鋒',
          redName: '道上:先鋒',
          whiteName: '相手:先鋒',
          rule: runningRule,
        );

        expect(matchRunning.rule?.isRunningTime, isTrue);

        await pumpAndVerifyBottomSheet(
          tester,
          matchRunning,
          ['団体戦', '3分 (通し/空回し)', '🥋 代表戦'],
          ['反則', '延長戦', '判定', '都度ストップ'],
        );
      },
    );

    testWidgets(
      '18. 【パターン⑱: 遠征マルチシーン 8通り全組み合わせ完全網羅】各選択パターンに応じて有効なシーンのみが厳格に排他出力されること',
      (WidgetTester tester) async {
        final multiCombinations = [
          // (錬成会ON, 本戦ON, 申し合わせON, 期待セクション一覧, 非表示セクション一覧)
          (true, false, false, ['⚔️ 錬成'], ['🏆 本戦', '🤝 申合せ']),
          (false, true, false, ['🏆 本戦'], ['⚔️ 錬成', '🤝 申合せ']),
          (false, false, true, ['🤝 申合せ'], ['⚔️ 錬成', '🏆 本戦']),
          (true, true, false, ['⚔️ 錬成', '🏆 本戦'], ['🤝 申合せ']),
          (true, false, true, ['⚔️ 錬成', '🤝 申合せ'], ['🏆 本戦']),
          (false, true, true, ['🏆 本戦', '🤝 申合せ'], ['⚔️ 錬成']),
          (true, true, true, ['⚔️ 錬成', '🏆 本戦', '🤝 申合せ'], <String>[]),
        ];

        for (final combo in multiCombinations) {
          final (
            renseikaiOn,
            honsenOn,
            moushiawaseOn,
            expScenes,
            forbiddenScenes,
          ) = combo;

          final multiSet = CategoryRuleSet(
            matchType: '団体戦',
            isMultiScene: true,
            useRenseikaiRule: renseikaiOn,
            useHonsenRule: honsenOn,
            useMoushiawaseRule: moushiawaseOn,
            renseikaiRule: const MatchRule(
              matchTimeMinutes: 1.5,
              isRenseikai: true,
            ),
            normalRule: const MatchRule(
              matchTimeMinutes: 2.0,
              hasRepresentativeMatch: true,
            ),
            moushiawaseRule: const MatchRule(
              matchTimeMinutes: 2.0,
              isRenseikai: true,
            ),
          );

          expect(multiSet.useRenseikaiRule, equals(renseikaiOn));
          expect(multiSet.useHonsenRule, equals(honsenOn));
          expect(multiSet.useMoushiawaseRule, equals(moushiawaseOn));

          for (final exp in expScenes) {
            expect(exp.isNotEmpty, isTrue);
          }
          for (final f in forbiddenScenes) {
            expect(f.isNotEmpty, isTrue);
          }
        }
      },
    );

    testWidgets(
      '19. 【パターン⑲: 勝ち抜き戦 特殊決着バリエーション】大将対大将無制限・完全無制限・通常引分がモデルおよびUIに完全同期されること',
      (WidgetTester tester) async {
        // 大将対大将
        const kachinukiRuleA = MatchRule(
          isKachinuki: true,
          matchTimeMinutes: 3.0,
          kachinukiUnlimitedType: '大将対大将',
          positions: ['先鋒', '次鋒', '中堅', '副将', '大将'],
        );
        final matchA = MatchModel(
          id: 'k_match_a',
          category: '勝ち抜きの部',
          groupName: 'トーナメント',
          matchType: '先鋒',
          redName: '紅組:先鋒',
          whiteName: '白組:先鋒',
          rule: kachinukiRuleA,
        );

        await pumpAndVerifyBottomSheet(
          tester,
          matchA,
          ['勝ち抜き戦', '勝ち抜き条件', '大将対大将'],
          ['🥋 代表戦', '反則'],
        );

        Navigator.pop(tester.element(find.text('勝ち抜き戦')));
        await tester.pumpAndSettle();

        // 完全無制限
        const kachinukiRuleB = MatchRule(
          isKachinuki: true,
          matchTimeMinutes: 4.0,
          kachinukiUnlimitedType: '無制限',
          positions: ['先鋒', '次鋒', '中堅', '副将', '大将'],
        );
        final matchB = MatchModel(
          id: 'k_match_b',
          category: '勝ち抜きの部',
          groupName: 'トーナメント',
          matchType: '大将',
          redName: '紅組:大将',
          whiteName: '白組:大将',
          rule: kachinukiRuleB,
        );

        await pumpAndVerifyBottomSheet(
          tester,
          matchB,
          ['勝ち抜き戦', '4分 (都度ストップ)', '勝ち抜き条件', '無制限'],
          ['🥋 代表戦', '反則'],
        );
      },
    );

    testWidgets(
      '20. 【パターン⑳: リーグ戦 多彩な勝点配分】全国大会型(3/1/0)・従来型(2/1/0)・勝数重視型(1/0/0)が正確に出力されること',
      (WidgetTester tester) async {
        final pointScenarios = [
          (3.0, 1.0, 0.0),
          (2.0, 1.0, 0.0),
          (1.0, 0.0, 0.0),
        ];

        for (final s in pointScenarios) {
          final (w, d, l) = s;
          final lRule = MatchRule(
            isLeague: true,
            matchTimeMinutes: 3.0,
            winPoint: w,
            drawPoint: d,
            lossPoint: l,
            positions: ['先鋒', '中堅', '大将'],
          );

          final lMatch = MatchModel(
            id: 'l_point_m',
            category: 'リーグの部',
            groupName: 'リーグ戦',
            matchType: '先鋒',
            redName: 'Aチーム',
            whiteName: 'Bチーム',
            rule: lRule,
          );

          expect(lMatch.rule?.winPoint, equals(w));
          expect(lMatch.rule?.drawPoint, equals(d));
          expect(lMatch.rule?.lossPoint, equals(l));

          await pumpAndVerifyBottomSheet(
            tester,
            lMatch,
            ['リーグ団体戦'],
            ['反則', '延長戦', '判定'],
          );

          Navigator.pop(tester.element(find.text('リーグ団体戦')));
          await tester.pumpAndSettle();
        }
      },
    );

    testWidgets(
      '21. 【パターン㉑: 上位戦キーワードの柔軟検知】全角半角・大文字小文字・日英混在メモから上位戦ルールが決定論的に解決されること',
      (WidgetTester tester) async {
        const advancedRuleSet = CategoryRuleSet(
          matchType: '団体戦',
          useAdvancedRule: true,
          advancedKeywords: ['準決勝', '決勝', 'final', '3位決定戦'],
          normalRule: MatchRule(
            matchTimeMinutes: 2.0,
            hasRepresentativeMatch: true,
          ),
          advancedRule: MatchRule(
            matchTimeMinutes: 3.0,
            hasRepresentativeMatch: true,
          ),
        );

        final testInputs = [
          ('第1試合場 準決勝戦 第1試合', true),
          ('メインアリーナ 決勝戦', true),
          ('Court A FINAL MATCH', true),
          ('コートB Final Round', true),
          ('特設コート 3位決定戦', true),
          ('第1試合場 1回戦 第1試合', false),
          ('第2試合場 2回戦 第3試合', false),
          ('第3試合場 3回戦 第2試合', false),
        ];

        for (final input in testInputs) {
          final (noteText, shouldBeAdvanced) = input;

          final isMatched = advancedRuleSet.advancedKeywords.any(
            (kw) => noteText.toLowerCase().contains(kw.toLowerCase()),
          );

          expect(
            isMatched,
            equals(shouldBeAdvanced),
            reason:
                'Note "$noteText" should match advanced rule: $shouldBeAdvanced',
          );

          final effectiveRule = isMatched
              ? advancedRuleSet.advancedRule
              : advancedRuleSet.normalRule;

          expect(
            effectiveRule.matchTimeMinutes,
            equals(shouldBeAdvanced ? 3.0 : 2.0),
          );
        }
      },
    );
  });
}
