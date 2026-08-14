import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_state.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/match/application/usecases/match_usecases.dart';
import 'package:kendo_os/features/match/domain/services/match_strategy.dart';
import 'package:kendo_os/shared/domain/entities/role_permission.dart';
import 'package:kendo_os/shared/time/time_source.dart';
import 'package:kendo_os/shared/presentation/utils/match_calculator_helper.dart';

class _FixedTimeSource implements TimeSource {
  final DateTime _fixed;
  _FixedTimeSource(this._fixed);
  @override
  DateTime now() => _fixed;
}

void main() {
  group('⚔️ 代表戦・個人戦・勝ち抜き戦 延長戦完全挙動検証テスト', () {
    test('1. scheduled / waiting 状態からスコア入力＆勝敗決定まで例外なく完了すること', () {
      // scheduled からのライフサイクル状態の解像
      final state = MatchLifecycleStateLegacyExt.fromLegacyString('scheduled');
      expect(state, equals(MatchLifecycleState.ready));

      // startMatch イベント
      final inProgress = MatchStateMachine.transition(
        state,
        StateTransitionEvent.startMatch,
      );
      expect(inProgress, equals(MatchLifecycleState.inProgress));

      // decideWinner イベント
      final completed = MatchStateMachine.transition(
        inProgress,
        StateTransitionEvent.decideWinner,
      );
      expect(completed, equals(MatchLifecycleState.completed));

      // 二重決定（冪等性）の検証
      final completedAgain = MatchStateMachine.transition(
        completed,
        StateTransitionEvent.decideWinner,
      );
      expect(completedAgain, equals(MatchLifecycleState.completed));
    });

    test('2. AddScoreUseCase で scheduled 状態の代表戦にスコアが入った際に正しく処理されること', () {
      final engine = KendoRuleEngine();
      final permission = PermissionService();
      final timeSource = _FixedTimeSource(DateTime(2026, 8, 14, 10, 0));
      final useCase = AddScoreUseCase(engine, permission, timeSource);

      final now = DateTime(2026, 8, 14, 10, 0);
      final match = MatchModel(
        id: 'daihyo_1',
        tournamentId: 't1',
        matchType: '代表戦',
        status: 'scheduled',
        redName: '道上剣友会 : 塚本',
        whiteName: '相手チーム : 選手',
        redScore: 0,
        whiteScore: 0,
        events: [],
        lastUpdatedAt: now,
      );

      final event = ScoreEvent(
        id: 'e1',
        side: Side.red,
        strikeType: StrikeType.men,
        isIppon: true,
        timestamp: now,
      );

      const user = User(id: 'u1', role: Role.admin, organizationId: 'org_1');
      const rule = MatchRule(isIpponShobu: true);

      final updated = useCase.execute(user, match, event, rule);
      expect(updated.status, equals('finished'));
      expect(updated.redScore, equals(1));
    });

    test('3. 代表戦・通常戦ともに本戦時間内決着は「延長」がつかず、延長突入後に「延長」がつくこと', () {
      final now = DateTime(2026, 8, 14, 10, 0);
      // 代表戦（本戦3分内で一本決着）
      final daihyoHonsenMatch = MatchModel(
        id: 'daihyo_honsen',
        tournamentId: 't1',
        matchType: '代表戦',
        status: 'finished',
        redName: '道上剣友会 : 久安',
        whiteName: '相手04 : 選手',
        redScore: 0,
        whiteScore: 1,
        note: '', // 延長なし
        events: [],
        lastUpdatedAt: now,
      );

      // 本戦決着なので false であること
      expect(
        MatchCalculatorHelper.isEnchoFromModel(daihyoHonsenMatch),
        isFalse,
      );

      // 代表戦（3分終了後または引き分け後に延長戦に入って決着）
      final daihyoEnchoMatch = daihyoHonsenMatch.copyWith(note: '延長1回目');
      // 延長突入後なので true であること
      expect(MatchCalculatorHelper.isEnchoFromModel(daihyoEnchoMatch), isTrue);

      // 通常戦（本戦決着）
      final senpoMatch = daihyoHonsenMatch.copyWith(matchType: '先鋒');
      expect(MatchCalculatorHelper.isEnchoFromModel(senpoMatch), isFalse);

      // 通常戦（延長決着）
      final senpoEnchoMatch = senpoMatch.copyWith(note: '延長戦');
      expect(MatchCalculatorHelper.isEnchoFromModel(senpoEnchoMatch), isTrue);
    });

    test('4. 団体戦で通常戦延長なしでも、代表戦（2分・延長2分・無制限）で引き分け時に startExtension が返ること', () {
      const daihyoRule = MatchRule(
        daihyoMatchTimeMinutes: 2.0,
        daihyoHasExtension: true,
        daihyoEnchoTimeMinutes: 2.0,
        daihyoEnchoCount: -2, // 無制限
      );

      final daihyoMatch = MatchModel(
        id: 'daihyo_match',
        matchType: '代表戦',
        redName: '道上剣友会 : 久安',
        whiteName: '相手04 : 選手',
        redScore: 0,
        whiteScore: 0,
        hasExtension: true,
        extensionCount: -2,
        extensionTimeMinutes: 2.0,
        rule: daihyoRule,
      );

      final strategy = TeamMatchStrategy();
      // 直前の通常試合設定は延長なし（hasExtension: false）
      final lastSettings = <String, dynamic>{
        'hasExtension': false,
        'extensionCount': 0,
      };

      final action = strategy.getNextActionOnTie(
        match: daihyoMatch,
        lastSettings: lastSettings,
      );

      // 通常試合の設定に引きずられず、代表戦専用設定（無制限延長）に従って startExtension が返ること
      expect(action, equals(NextMatchAction.startExtension));
    });

    test('5. 代表戦（回数無制限）で複数回の延長戦（1回目、2回目、3回目）が常に startExtension と判定されること', () {
      const daihyoRule = MatchRule(
        daihyoHasExtension: true,
        daihyoEnchoCount: -2, // 無制限
      );

      final strategy = TeamMatchStrategy();

      for (int extNum = 1; extNum <= 5; extNum++) {
        final extNote = extNum == 1
            ? ''
            : List.generate(extNum - 1, (i) => '延長${i + 1}回目').join(' ');
        final match = MatchModel(
          id: 'daihyo_ext_$extNum',
          matchType: '代表戦',
          redName: '道上 : 塚本',
          whiteName: '相手 : 選手',
          hasExtension: true,
          extensionCount: -2,
          rule: daihyoRule,
          note: extNote,
        );

        final action = strategy.getNextActionOnTie(
          match: match,
          lastSettings: {'hasExtension': false},
        );
        expect(
          action,
          equals(NextMatchAction.startExtension),
          reason: '延長第$extNum 回目の判定',
        );
      }
    });

    test('6. 代表戦で延長回数上限（2回）に設定されている場合、2回終了後に判定（showHantei）へ正しく移行すること', () {
      const daihyoRule = MatchRule(
        daihyoHasExtension: true,
        daihyoEnchoCount: 2, // 2回上限
        daihyoHasHantei: true, // 終了後判定
      );

      final strategy = TeamMatchStrategy();

      // 本戦終了時 ➔ 延長1回目へ
      final m0 = MatchModel(
        id: 'd1',
        matchType: '代表戦',
        redName: '赤',
        whiteName: '白',
        hasExtension: true,
        extensionCount: 2,
        hasHantei: true,
        rule: daihyoRule,
        note: '',
      );
      expect(
        strategy.getNextActionOnTie(match: m0, lastSettings: null),
        equals(NextMatchAction.startExtension),
      );

      // 延長1回目終了時 ➔ 延長2回目へ
      final m1 = m0.copyWith(note: '延長1回目');
      expect(
        strategy.getNextActionOnTie(match: m1, lastSettings: null),
        equals(NextMatchAction.startExtension),
      );

      // 延長2回目終了時（上限到達） ➔ 判定へ
      final m2 = m0.copyWith(note: '延長1回目 延長2回目');
      expect(
        strategy.getNextActionOnTie(match: m2, lastSettings: null),
        equals(NextMatchAction.showHantei),
      );
    });

    test('7. 代表戦延長突入後のデータ更新（note記録・タイマー初期化秒数）が正しく行われること', () {
      final now = DateTime(2026, 8, 14, 10, 0);
      const extMins = 2.0;

      final initialMatch = MatchModel(
        id: 'daihyo_timer_test',
        matchType: '代表戦',
        redName: '道上 : 久安',
        whiteName: '相手 : 選手',
        extensionTimeMinutes: extMins,
        lastUpdatedAt: now,
      );

      // 延長1回目の更新シミュレーション
      final currentExtCount = '延長'.allMatches(initialMatch.note).length;
      final extStr = '延長${currentExtCount + 1}回目';

      final updatedMatch = initialMatch
          .updateRemainingSeconds((extMins * 60).toInt(), now)
          .copyWith(
            timerStartedAt: null,
            note: initialMatch.note.isEmpty
                ? extStr
                : '${initialMatch.note} ($extStr)',
            extensionTimeMinutes: extMins,
          );

      expect(updatedMatch.note, equals('延長1回目'));
      expect(updatedMatch.extensionTimeMinutes, equals(2.0));
      expect(updatedMatch.timerStartedAt, isNull);

      // 延長戦判定が true になること
      expect(
        MatchCalculatorHelper.isEnchoFromModel(
          updatedMatch.copyWith(status: 'finished'),
        ),
        isTrue,
      );
    });

    test('8. 個人戦で設定した延長回数・判定有無が getNextActionOnTie に正確に反映されること', () {
      const indivRule = MatchRule(
        enchoCount: 1, // 延長1回のみ
        hasHantei: true, // 延長終了後は判定
      );

      final indivMatch = MatchModel(
        id: 'indiv_match',
        matchType: '個人戦',
        redName: '選手A',
        whiteName: '選手B',
        redScore: 0,
        whiteScore: 0,
        hasExtension: true,
        extensionCount: 1,
        hasHantei: true,
        rule: indivRule,
        note: '', // 本戦終了時
      );

      final strategy = IndividualMatchStrategy();

      // 1回目：延長戦へ
      final action1 = strategy.getNextActionOnTie(
        match: indivMatch,
        lastSettings: null,
      );
      expect(action1, equals(NextMatchAction.startExtension));

      // 延長1回終了後（上限到達）：判定へ
      final indivMatchAfterExt = indivMatch.copyWith(note: '延長1回目');
      final action2 = strategy.getNextActionOnTie(
        match: indivMatchAfterExt,
        lastSettings: null,
      );
      expect(action2, equals(NextMatchAction.showHantei));
    });

    test('9. 勝ち抜き戦の大将戦引き分け延長（大将引き分け延長）が正しく動作すること', () {
      const kachinukiRule = MatchRule(
        isKachinuki: true,
        kachinukiUnlimitedType: '大将引き分け延長',
        isEnchoUnlimited: true,
      );

      final strategy = KachinukiStrategy();

      // 大将同士（redRemaining / whiteRemaining が空）
      final taishoMatch = MatchModel(
        id: 'kachinuki_taisho',
        matchType: '大将戦',
        redName: '赤大将',
        whiteName: '白大将',
        redRemaining: [],
        whiteRemaining: [],
        hasExtension: true,
        rule: kachinukiRule,
      );

      final action = strategy.getNextActionOnTie(
        match: taishoMatch,
        lastSettings: null,
      );
      expect(action, equals(NextMatchAction.startExtension));

      // 先鋒戦（まだ後ろの選手が残っている）の場合は延長せず即引き分け（両者退場）
      final senpoMatch = taishoMatch.copyWith(
        matchType: '先鋒戦',
        redRemaining: ['次鋒', '中堅'],
        whiteRemaining: ['次鋒', '中堅'],
      );
      final senpoAction = strategy.getNextActionOnTie(
        match: senpoMatch,
        lastSettings: null,
      );
      expect(senpoAction, equals(NextMatchAction.finishMatch));
    });
  });
}
