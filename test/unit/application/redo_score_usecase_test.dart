import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/application/usecases/match_undo_redo_usecase.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/shared/domain/entities/role_permission.dart';
import 'package:kendo_os/shared/time/time_source.dart';

class FixedTimeSource implements TimeSource {
  final DateTime _fixed;
  FixedTimeSource(this._fixed);
  @override
  DateTime now() => _fixed;
}

void main() {
  group('[Unit] スコアRedoユースケース単体テスト', () {
    final fixedTime = DateTime(2026, 10, 1, 12, 0, 0);
    final timeSource = FixedTimeSource(fixedTime);
    final engine = KendoRuleEngine();
    final permissionService = PermissionService();
    final redoUseCase = RedoScoreUseCase(engine, permissionService, timeSource);

    final adminUser = const User(
      id: 'admin_1',
      role: Role.admin,
      organizationId: 'org_1',
    );
    final viewerUser = const User(
      id: 'viewer_1',
      role: Role.viewer,
      organizationId: 'org_1',
    );

    test('権限を持たない一般観戦者がRedoを実行した場合に拒否例外が発生すること', () {
      final match = MatchModel(
        id: 'm_redo_1',
        tournamentId: 't1',
        matchType: '個人戦',
        redName: '選手A',
        whiteName: '選手B',
        redScore: 1,
        whiteScore: 0,
        status: 'in_progress',
        events: [
          ScoreEvent(
            id: 'ev1',
            side: Side.red,
            strikeType: StrikeType.men,
            isIppon: true,
            timestamp: fixedTime,
            sequence: 1,
          ),
        ],
      );

      expect(
        () => redoUseCase.execute(viewerUser, match, const MatchRule()),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('イベント履歴が存在しない空の試合では変更されずそのまま返却されること', () {
      final emptyMatch = const MatchModel(
        id: 'm_redo_empty',
        tournamentId: 't1',
        matchType: '個人戦',
        redName: '選手A',
        whiteName: '選手B',
        redScore: 0,
        whiteScore: 0,
        status: 'ready',
        events: [],
      );

      final result = redoUseCase.execute(
        adminUser,
        emptyMatch,
        const MatchRule(),
      );
      expect(result.events, isEmpty);
      expect(result.status, 'ready');
    });

    test('Redo実行時にisRestoreがtrueのイベントが新規シーケンス番号で追加されること', () {
      final initialMatch = MatchModel(
        id: 'm_redo_seq',
        tournamentId: 't1',
        matchType: '個人戦',
        redName: '選手A',
        whiteName: '選手B',
        redScore: 1,
        whiteScore: 0,
        status: 'in_progress',
        events: [
          ScoreEvent(
            id: 'ev_men',
            side: Side.red,
            strikeType: StrikeType.men,
            isIppon: true,
            timestamp: fixedTime,
            sequence: 1,
          ),
          ScoreEvent(
            id: 'ev_undo',
            side: Side.none,
            isUndo: true,
            targetId: 'ev_men',
            timestamp: fixedTime.add(const Duration(seconds: 1)),
            sequence: 2,
          ),
        ],
      );

      final result = redoUseCase.execute(
        adminUser,
        initialMatch,
        const MatchRule(),
      );

      expect(result.events.length, 3);
      final redoEvent = result.events.last;
      expect(redoEvent.isRestore, isTrue);
      expect(redoEvent.sequence, 3);
      expect(redoEvent.logicalClock, 3);
      expect(redoEvent.userId, 'admin_1');
    });

    test('Redoによって勝敗が決着した場合にステータスが適切に完了状態へ遷移すること', () {
      // 1本勝負で、面を取得した後にUndoされ、再度Redoで復帰して勝利決着するシナリオ
      const ipponRule = MatchRule(isIpponShobu: true, ipponLimit: 1);

      final matchBeforeRedo = MatchModel(
        id: 'm_redo_win',
        tournamentId: 't1',
        matchType: '個人戦',
        redName: '選手A',
        whiteName: '選手B',
        redScore: 0,
        whiteScore: 0,
        status: 'in_progress',
        rule: ipponRule,
        events: [
          ScoreEvent(
            id: 'ev_win_men',
            side: Side.red,
            strikeType: StrikeType.men,
            isIppon: true,
            timestamp: fixedTime,
            sequence: 1,
          ),
          ScoreEvent(
            id: 'ev_undo_win',
            side: Side.none,
            isUndo: true,
            targetId: 'ev_win_men',
            timestamp: fixedTime.add(const Duration(seconds: 1)),
            sequence: 2,
          ),
        ],
      );

      final result = redoUseCase.execute(adminUser, matchBeforeRedo, ipponRule);

      expect(result.redScore, 1);
      expect(result.whiteScore, 0);
      expect(result.status, 'finished');
    });
  });
}
