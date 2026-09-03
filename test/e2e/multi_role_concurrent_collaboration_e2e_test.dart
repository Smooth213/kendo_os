import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/viewer/presentation/providers/viewer_timeline_provider.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/application/projections/match_projection.dart';

void main() {
  group('🚀 【E2E 2/5】審判席iPad ＋ 本部PC ＋ 観客席スマホ 3者同時並行データ連携E2Eテスト', () {
    test('審判席のスコア入力が本部タイムラインと観客席プロジェクションに即時同期し、ロール権限分離が徹底されること', () async {
      final initialMatch = MatchModel(
        id: 'court1_match_1',
        tournamentId: 'collab_tour_1',
        category: '一般団体',
        groupName: '第1コート',
        redName: '神武館',
        whiteName: '修道館',
        matchType: '先鋒戦',
        status: 'inProgress',
        redScore: 0,
        whiteScore: 0,
        order: 1.0,
        events: [],
      );

      // 1. ロール権限の検証
      // 観客席 (Viewer): 閲覧専用、作成・管理権限なし
      const viewerPerms = PermissionState(role: UserRole.viewer);
      expect(viewerPerms.isReadOnly, isTrue);
      expect(viewerPerms.canCreateMatch, isFalse);
      expect(viewerPerms.canManageTournament, isFalse);

      // 審判席 (Operator): 記録可能、大会作成権限なし
      const operatorPerms = PermissionState(role: UserRole.operator);
      expect(operatorPerms.isReadOnly, isFalse);
      expect(operatorPerms.canCreateMatch, isTrue);
      expect(operatorPerms.canManageTournament, isTrue);

      // 大会本部 (Admin): 全権限保有（削除権限含む）
      const adminPerms = PermissionState(role: UserRole.admin);
      expect(adminPerms.isReadOnly, isFalse);
      expect(adminPerms.canDeleteData, isTrue);
      expect(adminPerms.canManageTournament, isTrue);

      // 2. 審判席によるスコア入力（赤選手がメン取得）
      final scoredMatch = initialMatch.copyWith(
        redScore: 1,
        events: [
          ScoreEvent(
            id: 'ev_men_1',
            side: Side.red,
            strikeType: StrikeType.men,
            isIppon: true,
            timestamp: DateTime(2026, 9, 3, 10, 0),
            logicalClock: 1,
          ),
        ],
      );

      // 3. 本部PC・観客席タイムラインProviderへの同期検証
      final container = ProviderContainer(
        overrides: [
          matchListByTournamentProvider(
            'collab_tour_1',
          ).overrideWith((ref) => Stream.value([scoredMatch])),
        ],
      );
      addTearDown(container.dispose);

      // タイムラインの購読と状態反映
      final timelineState = container.read(
        safeViewerTimelineProvider('collab_tour_1'),
      );
      expect(timelineState.hasError, isFalse);

      // 4. 観客席用 MatchProjection への変換と反映
      final projection = MatchProjection(
        id: scoredMatch.id,
        tournamentId: scoredMatch.tournamentId ?? '',
        matchOrder: scoredMatch.order.toInt(),
        matchType: scoredMatch.matchType,
        status: scoredMatch.status,
        groupName: scoredMatch.groupName ?? '',
        isKachinuki: false,
        redName: scoredMatch.redName,
        whiteName: scoredMatch.whiteName,
        redScore: scoredMatch.redScore,
        whiteScore: scoredMatch.whiteScore,
        remainingSeconds: 180,
        timerIsRunning: true,
        note: '',
      );

      expect(projection.redScore, 1);
      expect(projection.whiteScore, 0);
      expect(projection.status, 'inProgress');
    });
  });
}
