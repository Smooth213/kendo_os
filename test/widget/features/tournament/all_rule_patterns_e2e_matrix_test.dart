import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../helpers/safe_pump_helper.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/rule_info_bottom_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Widget] ルール表示BottomSheet 主要バリエーションUI整合性テスト', () {
    late TournamentModel representativeTournament;

    setUp(() {
      representativeTournament = TournamentModel(
        id: 'matrix_tourney_id',
        organizationId: 'matrix_dojo_id',
        name: '全日本剣道ルール大会',
        date: DateTime(2026, 8, 15),
        venue: '日本武道館',
        categories: [
          '①トーナメント団体戦_標準5人制',
          '②トーナメント個人戦_標準',
          '③リーグ団体戦_代表戦あり',
          '④遠征マルチシーン',
          '⑤部内戦_特設紅白戦',
        ],
        categoryRules: {
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
          '②トーナメント個人戦_標準': const CategoryRuleSet(
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
          '③リーグ団体戦_代表戦あり': const CategoryRuleSet(
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
          '④遠征マルチシーン': const CategoryRuleSet(
            matchType: '団体戦',
            isMultiScene: true,
            useRenseikaiRule: true,
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
          '⑤部内戦_特設紅白戦': const CategoryRuleSet(
            matchType: '部内戦',
            normalRule: MatchRule(
              matchTimeMinutes: 2.0,
              isRunningTime: false,
              isIpponShobu: false,
              hasRepresentativeMatch: true,
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
      await tester.safePumpAndSettle();

      await tester.tap(find.text('OpenSheet'));
      await tester.safePumpAndSettle();

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

    testWidgets('トーナメント団体戦 標準5人制のUI表示が正しく検証されること', (WidgetTester tester) async {
      final rule = representativeTournament
          .categoryRules['①トーナメント団体戦_標準5人制']!
          .normalRule;
      final match = MatchModel(
        id: 'p1_match',
        category: '①トーナメント団体戦_標準5人制',
        groupName: '紅組 vs 白組',
        matchType: '先鋒',
        redName: '紅組:選手1',
        whiteName: '白組:選手1',
        rule: rule,
      );

      await pumpAndVerifyBottomSheet(
        tester,
        match,
        ['団体戦', '2分', '🥋 代表戦'],
        ['反則', '判定'],
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('トーナメント個人戦 標準のUIで代表戦が非表示になることが正しく検証されること', (
      WidgetTester tester,
    ) async {
      final rule =
          representativeTournament.categoryRules['②トーナメント個人戦_標準']!.normalRule;
      final match = MatchModel(
        id: 'p2_match',
        category: '②トーナメント個人戦_標準',
        groupName: '個人戦トーナメント',
        matchType: '個人戦',
        redName: '選手A',
        whiteName: '選手B',
        rule: rule,
      );

      await pumpAndVerifyBottomSheet(
        tester,
        match,
        ['個人戦', '3分', '判定'],
        ['🥋 代表戦'],
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('リーグ団体戦 勝点制のUI表示が正しく検証されること', (WidgetTester tester) async {
      final rule =
          representativeTournament.categoryRules['③リーグ団体戦_代表戦あり']!.normalRule;
      final match = MatchModel(
        id: 'p3_match',
        category: '③リーグ団体戦_代表戦あり',
        groupName: 'リーグA',
        matchType: '中堅',
        redName: '紅組:選手2',
        whiteName: '白組:選手2',
        rule: rule.copyWith(isLeague: true),
      );

      await pumpAndVerifyBottomSheet(
        tester,
        match,
        ['リーグ団体戦', '2分', '🥋 代表戦'],
        ['判定'],
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('遠征マルチシーンのUI表示が正しく検証されること', (WidgetTester tester) async {
      final rule =
          representativeTournament.categoryRules['④遠征マルチシーン']!.normalRule;
      final match = MatchModel(
        id: 'p4_match',
        category: '④遠征マルチシーン',
        groupName: '遠征交流',
        matchType: '大将',
        redName: '紅組:大将',
        whiteName: '白組:大将',
        rule: rule,
      );

      await pumpAndVerifyBottomSheet(tester, match, ['団体戦', '2分'], []);
      expect(tester.takeException(), isNull);
    });

    testWidgets('部内戦 紅白戦のUI表示が正しく検証されること', (WidgetTester tester) async {
      final rule =
          representativeTournament.categoryRules['⑤部内戦_特設紅白戦']!.normalRule;
      final match = MatchModel(
        id: 'p5_match',
        category: '⑤部内戦_特設紅白戦',
        groupName: '特設紅白戦',
        matchType: '大将',
        redName: '紅組:大将',
        whiteName: '白組:大将',
        rule: rule,
      );

      await pumpAndVerifyBottomSheet(tester, match, ['部内戦', '2分'], []);
      expect(tester.takeException(), isNull);
    });

    testWidgets('操作検証: 閉じるボタン押下でBottomSheetが正常に閉じること', (
      WidgetTester tester,
    ) async {
      final rule = representativeTournament
          .categoryRules['①トーナメント団体戦_標準5人制']!
          .normalRule;
      final match = MatchModel(
        id: 'p_close_match',
        category: '①トーナメント団体戦_標準5人制',
        groupName: '紅組 vs 白組',
        matchType: '先鋒',
        redName: '紅組:選手1',
        whiteName: '白組:選手1',
        rule: rule,
      );

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
      await tester.safePumpAndSettle();

      await tester.tap(find.text('OpenSheet'));
      await tester.safePumpAndSettle();

      expect(find.textContaining('試合レギュレーション確認'), findsOneWidget);

      final closeButton = find.byIcon(Icons.close);
      if (closeButton.evaluate().isNotEmpty) {
        await tester.tap(closeButton);
        await tester.safePumpAndSettle();
        expect(find.textContaining('試合レギュレーション確認'), findsNothing);
      }
      expect(tester.takeException(), isNull);
    });
  });
}
