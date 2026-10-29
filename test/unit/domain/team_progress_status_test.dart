import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/domain/team_progress_model.dart';

void main() {
  group('[Unit] チーム進行ステータスモデルおよびゼロ除算保護テスト', () {
    test('試合総数がゼロの場合にゼロ除算が発生せず進行度がゼロとして保護されること', () {
      const status = TeamProgressStatus(
        teamName: '道場A',
        matches: [],
        completedCount: 0,
        totalCount: 0,
        hasLiveMatch: false,
      );

      expect(status.progressRatio, equals(0.0));
      expect(status.progressPercent, equals(0));
      expect(status.isAllFinished, isFalse);
      expect(status.isFinished, isFalse);
    });

    test('試合進行度およびパーセンテージが正確に算出され最大値が1に制限されること', () {
      const normalStatus = TeamProgressStatus(
        teamName: '道場B',
        matches: [],
        completedCount: 3,
        totalCount: 5,
        hasLiveMatch: true,
      );

      expect(normalStatus.progressRatio, closeTo(0.6, 0.0001));
      expect(normalStatus.progressPercent, equals(60));
      expect(normalStatus.isAllFinished, isFalse);

      // 上限超過時のclamp保護
      const overflowStatus = TeamProgressStatus(
        teamName: '道場B',
        matches: [],
        completedCount: 6,
        totalCount: 5,
        hasLiveMatch: false,
      );
      expect(overflowStatus.progressRatio, equals(1.0));
      expect(overflowStatus.progressPercent, equals(100));
      expect(overflowStatus.isAllFinished, isTrue);
    });

    test('全試合終了判定および対戦カード完了フラグが正しく判定されること', () {
      final finishedMatch1 = const MatchModel(
        id: 'm1',
        tournamentId: 't1',
        matchType: 'individual',
        redName: '先鋒A',
        whiteName: '先鋒B',
        status: 'finished',
      );
      final approvedMatch2 = const MatchModel(
        id: 'm2',
        tournamentId: 't1',
        matchType: 'individual',
        redName: '中堅A',
        whiteName: '中堅B',
        status: 'approved',
      );

      final statusAllDone = TeamProgressStatus(
        teamName: '道場C',
        matches: [finishedMatch1, approvedMatch2],
        completedCount: 2,
        totalCount: 2,
        hasLiveMatch: false,
      );

      expect(statusAllDone.isAllFinished, isTrue);
      expect(statusAllDone.isFinished, isTrue);

      // 1試合でも進行中がある場合はisFinishedがfalseとなること
      final inProgressMatch = const MatchModel(
        id: 'm3',
        tournamentId: 't1',
        matchType: 'individual',
        redName: '大将A',
        whiteName: '大将B',
        status: 'in_progress',
      );

      final statusWithLive = TeamProgressStatus(
        teamName: '道場C',
        matches: [finishedMatch1, approvedMatch2, inProgressMatch],
        completedCount: 2,
        totalCount: 3,
        hasLiveMatch: true,
      );

      expect(statusWithLive.isAllFinished, isFalse);
      expect(statusWithLive.isFinished, isFalse);
    });
  });
}
