import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/domain/team_progress_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/team_progress_sort_helper.dart';

void main() {
  group('🥋 TeamProgressSortHelper Unit Tests', () {
    TeamProgressStatus makeStatus({
      required String teamName,
      required String courtName,
      bool hasLive = false,
      bool isFinished = false,
      List<MatchModel>? matches,
    }) {
      final mList =
          matches ??
          [
            MatchModel(
              id: 'm_$teamName',
              matchType: '先鋒',
              redName: teamName,
              whiteName: '相手',
              status: isFinished
                  ? 'finished'
                  : (hasLive ? 'in_progress' : 'waiting'),
              order: 1.0,
            ),
          ];

      return TeamProgressStatus(
        teamName: teamName,
        currentCourtName: courtName,
        matches: mList,
        completedCount: isFinished ? 1 : 0,
        totalCount: 1,
        hasLiveMatch: hasLive,
      );
    }

    test('extractCourtNumber correctly resolves court indices', () {
      expect(
        TeamProgressSortHelper.extractCourtNumber(
          makeStatus(teamName: 'A', courtName: '第1コート (1回戦・第1試合)'),
        ),
        1,
      );
      expect(
        TeamProgressSortHelper.extractCourtNumber(
          makeStatus(teamName: 'B', courtName: '第2試合場 (第5試合)'),
        ),
        2,
      );
      expect(
        TeamProgressSortHelper.extractCourtNumber(
          makeStatus(teamName: 'C', courtName: '第10コート'),
        ),
        10,
      );
      expect(
        TeamProgressSortHelper.extractCourtNumber(
          makeStatus(teamName: 'D', courtName: 'Aコート (第1試合)'),
        ),
        10000 + 'A'.codeUnitAt(0),
      );
      expect(
        TeamProgressSortHelper.extractCourtNumber(
          makeStatus(teamName: 'E', courtName: 'コート未指定 (第3試合)'),
        ),
        999999,
      );
    });

    test('extractMatchOrder correctly resolves match order indices', () {
      expect(
        TeamProgressSortHelper.extractMatchOrder(
          makeStatus(teamName: 'A', courtName: '第1コート (1回戦・第3試合)'),
        ),
        3.0,
      );
      expect(
        TeamProgressSortHelper.extractMatchOrder(
          makeStatus(teamName: 'B', courtName: '第2コート (5試合目)'),
        ),
        5.0,
      );
      // currentCourtName に第X試合が無い場合は matches の order fallback
      expect(
        TeamProgressSortHelper.extractMatchOrder(
          makeStatus(
            teamName: 'C',
            courtName: '第1コート',
            matches: [
              const MatchModel(
                id: 'm1',
                matchType: '先鋒',
                redName: 'A',
                whiteName: 'B',
                order: 4.0,
              ),
            ],
          ),
        ),
        4.0,
      );
    });

    test(
      'sortTeams by court orders teams by court number then match order',
      () {
        final teamA = makeStatus(teamName: '道場A', courtName: '第2コート (第1試合)');
        final teamB = makeStatus(teamName: '道場B', courtName: '第1コート (第2試合)');
        final teamC = makeStatus(teamName: '道場C', courtName: '第1コート (第1試合)');
        final teamD = makeStatus(teamName: '道場D', courtName: 'コート未指定');

        final sorted = TeamProgressSortHelper.sortTeams([
          teamA,
          teamB,
          teamC,
          teamD,
        ], TeamSortType.court);

        // 第1コート第1試合 -> 第1コート第2試合 -> 第2コート第1試合 -> コート未指定
        expect(sorted[0].teamName, '道場C');
        expect(sorted[1].teamName, '道場B');
        expect(sorted[2].teamName, '道場A');
        expect(sorted[3].teamName, '道場D');
      },
    );

    test('sortTeams by matchOrder orders teams by match sequence', () {
      final teamA = makeStatus(teamName: '道場A', courtName: '第1コート (第3試合)');
      final teamB = makeStatus(teamName: '道場B', courtName: '第2コート (第1試合)');
      final teamC = makeStatus(teamName: '道場C', courtName: '第1コート (第1試合)');
      final teamD = makeStatus(teamName: '道場D', courtName: '第3コート (第2試合)');

      final sorted = TeamProgressSortHelper.sortTeams([
        teamA,
        teamB,
        teamC,
        teamD,
      ], TeamSortType.matchOrder);

      // 第1試合 (第1コート -> 第2コート) -> 第2試合 (第3コート) -> 第3試合 (第1コート)
      expect(sorted[0].teamName, '道場C'); // 第1コート第1試合
      expect(sorted[1].teamName, '道場B'); // 第2コート第1試合
      expect(sorted[2].teamName, '道場D'); // 第3コート第2試合
      expect(sorted[3].teamName, '道場A'); // 第1コート第3試合
    });

    test(
      'sortTeams by status orders live matches first, then waiting, then finished',
      () {
        final teamLive = makeStatus(
          teamName: 'LIVE道場',
          courtName: '第2コート (第4試合)',
          hasLive: true,
        );
        final teamWaiting = makeStatus(
          teamName: '待機道場',
          courtName: '第1コート (第1試合)',
          hasLive: false,
        );
        final teamFinished = makeStatus(
          teamName: '終了道場',
          courtName: '第1コート (第2試合)',
          isFinished: true,
        );

        final sorted = TeamProgressSortHelper.sortTeams([
          teamFinished,
          teamWaiting,
          teamLive,
        ], TeamSortType.status);

        expect(sorted[0].teamName, 'LIVE道場');
        expect(sorted[1].teamName, '待機道場');
        expect(sorted[2].teamName, '終了道場');
      },
    );
  });
}
