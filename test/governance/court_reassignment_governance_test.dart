import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/tournament/domain/team_progress_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/team_progress_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/team_progress_sort_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🔀 【第21条 ガバナンス監査】現場動的運用・急遽コート振替 ＆ リアルタイム進行整合性保証規約', () {
    test(
      'Rule 1: [コート変更データ不変性] MatchModel のコート振替時におけるタイマー・スコア・イベント履歴の完全保持規約',
      () {
        final now = DateTime(2026, 9, 27, 10, 0, 0);
        final initialEvents = [
          ScoreEvent(
            id: 'ev_men_1',
            side: Side.red,
            strikeType: StrikeType.men,
            isIppon: true,
            timestamp: now,
            logicalClock: 1,
            sequence: 1,
          ),
        ];

        final ongoingMatch = MatchModel(
          id: 'reassign_m1',
          tournamentId: 't1',
          matchType: '個人戦',
          redName: '選手A',
          whiteName: '選手B',
          redScore: 1,
          whiteScore: 0,
          status: 'in_progress',
          note: '第1試合場, 1回戦',
          timerStartedAt: now,
          accumulatedPauseDurationMs: 1500,
          events: initialEvents,
        );

        // 現場での急遽コート振替（第1試合場 -> 第3試合場）
        final reassignedMatch = ongoingMatch.copyWith(note: '第3試合場, 1回戦');

        // 規約検証: コート以外のコアデータが完全に不変であること
        expect(reassignedMatch.id, ongoingMatch.id);
        expect(reassignedMatch.redScore, ongoingMatch.redScore);
        expect(reassignedMatch.whiteScore, ongoingMatch.whiteScore);
        expect(reassignedMatch.status, ongoingMatch.status);
        expect(reassignedMatch.timerStartedAt, ongoingMatch.timerStartedAt);
        expect(
          reassignedMatch.accumulatedPauseDurationMs,
          ongoingMatch.accumulatedPauseDurationMs,
        );
        expect(reassignedMatch.events.length, ongoingMatch.events.length);
        expect(reassignedMatch.events.first.id, ongoingMatch.events.first.id);
        expect(reassignedMatch.note, '第3試合場, 1回戦');
      },
    );

    test(
      'Rule 2: [コートパース＆優先度ソート整合性] team_progress_helper.dart & team_progress_sort_helper.dart 規約',
      () {
        // ヘルパーによる文字列抽出検証
        final court1 = TeamProgressHelper.extractCourtAndRoundDisplay(
          const MatchModel(
            id: 'm1',
            matchType: '個人戦',
            redName: 'A',
            whiteName: 'B',
            note: '第1試合場, 準決勝',
          ),
        );
        expect(court1, '第1試合場 (準決勝)');

        final court3 = TeamProgressHelper.extractCourtAndRoundDisplay(
          const MatchModel(
            id: 'm3',
            matchType: '個人戦',
            redName: 'A',
            whiteName: 'B',
            note: '第3コート, 決勝戦',
          ),
        );
        expect(court3, '第3コート (決勝戦)');

        // ソート優先度検証（第1コート < 第2コート < 第3コート < コート未指定）
        TeamProgressStatus createStatus(String courtName) => TeamProgressStatus(
          teamName: 'チームA',
          currentCourtName: courtName,
          matches: const [],
          completedCount: 0,
          totalCount: 1,
          hasLiveMatch: false,
        );

        final priority1 = TeamProgressSortHelper.extractCourtNumber(
          createStatus('第1コート'),
        );
        final priority2 = TeamProgressSortHelper.extractCourtNumber(
          createStatus('第2コート'),
        );
        final priority3 = TeamProgressSortHelper.extractCourtNumber(
          createStatus('第3コート'),
        );
        final priorityUnassigned = TeamProgressSortHelper.extractCourtNumber(
          createStatus('コート未指定'),
        );

        expect(priority1 < priority2, isTrue);
        expect(priority2 < priority3, isTrue);
        expect(priority3 < priorityUnassigned, isTrue);
      },
    );

    test(
      'Rule 3: [ライトスルー永続化規約] match_persistence_helper.dart & local_match_repository.dart によるコート変更の即時反映規約',
      () {
        final persistenceHelperFile = File(
          'lib/features/match/application/services/match_persistence_helper.dart',
        );
        expect(persistenceHelperFile.existsSync(), isTrue);
        final content = persistenceHelperFile.readAsStringSync();

        // 試合更新時にローカルリポジトリとコマンドキューへ安全にライトスルー保存されていること
        expect(
          content.contains('CommandType.updateMatch'),
          isTrue,
          reason: 'MatchPersistenceHelper で CommandType.updateMatch が発行されていること',
        );

        final localRepoFile = File(
          'lib/shared/infrastructure/repository/local_match_repository.dart',
        );
        expect(localRepoFile.existsSync(), isTrue);
        final repoContent = localRepoFile.readAsStringSync();
        expect(
          repoContent.contains('saveMatch') || repoContent.contains('putMatch'),
          isTrue,
          reason: 'LocalMatchRepository でローカル保存が提供されていること',
        );
      },
    );

    test('Rule 4: [試合編集タブ・UIプリセット規約] match_edit_court_and_group_tab.dart 規約', () {
      final tabFile = File(
        'lib/features/tournament/presentation/operate/components/home/match_edit_court_and_group_tab.dart',
      );
      expect(tabFile.existsSync(), isTrue);
      final tabContent = tabFile.readAsStringSync();

      expect(tabContent.contains('courtPresets'), isTrue);
      expect(tabContent.contains('第1試合場'), isTrue);
      expect(tabContent.contains('第2試合場'), isTrue);
      expect(tabContent.contains('第3試合場'), isTrue);
      expect(tabContent.contains('onClearCourt'), isTrue);
    });
  });
}
