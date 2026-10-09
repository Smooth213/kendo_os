import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_command_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_player_match_classifier.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/match_repository.dart';

class MockLocalMatchRepository implements LocalMatchRepository {
  final List<String> deletedMatchIds = [];

  @override
  Future<void> deleteMatch(String matchId) async {
    deletedMatchIds.add(matchId);
  }

  @override
  Future<void> deleteMatchesBulk(List<String> matchIds) async {
    deletedMatchIds.addAll(matchIds);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockMatchRepository implements MatchRepository {
  final List<String> deletedMatchIds = [];

  @override
  Future<void> deleteMatch(String matchId) async {
    deletedMatchIds.add(matchId);
  }

  @override
  Future<void> deleteMatchesBulk(List<String> matchIds) async {
    deletedMatchIds.addAll(matchIds);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('[Unit] 団体戦一括削除と対戦残留防止テスト', () {
    test('団体戦の全試合IDを一括指定した際に全ての対戦が漏れなく削除されること', () async {
      final mockLocalRepo = MockLocalMatchRepository();
      final mockRemoteRepo = MockMatchRepository();

      final container = ProviderContainer(
        overrides: [
          localMatchRepositoryProvider.overrideWithValue(mockLocalRepo),
          matchRepositoryProvider.overrideWithValue(mockRemoteRepo),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(matchCommandProvider);
      final targetIds = [
        'm_senpo',
        'm_jiho',
        'm_chuken',
        'm_fukuso',
        'm_taisho',
      ];

      await service.deleteMatchesBulk(targetIds);

      expect(mockLocalRepo.deletedMatchIds, equals(targetIds));
      expect(mockRemoteRepo.deletedMatchIds, equals(targetIds));
    });

    test(
      'Web環境においてwebCurrentTournamentMatchesProviderから対象全試合が即座に除外されること',
      () async {
        final mockLocalRepo = MockLocalMatchRepository();
        final mockRemoteRepo = MockMatchRepository();

        final initialMatches = [
          const MatchModel(
            id: 'm1',
            tournamentId: 't1',
            matchType: '先鋒',
            redName: 'Aチーム:選手1',
            whiteName: 'Bチーム:選手1',
          ),
          const MatchModel(
            id: 'm2',
            tournamentId: 't1',
            matchType: '中堅',
            redName: 'Aチーム:選手2',
            whiteName: 'Bチーム:選手2',
          ),
          const MatchModel(
            id: 'm3',
            tournamentId: 't1',
            matchType: '大将',
            redName: 'Aチーム:選手3',
            whiteName: 'Bチーム:選手3',
          ),
          const MatchModel(
            id: 'other_m',
            tournamentId: 't1',
            matchType: '個人戦',
            redName: '個人A',
            whiteName: '個人B',
          ),
        ];

        final container = ProviderContainer(
          overrides: [
            localMatchRepositoryProvider.overrideWithValue(mockLocalRepo),
            matchRepositoryProvider.overrideWithValue(mockRemoteRepo),
          ],
        );
        addTearDown(container.dispose);

        debugIsWebOverride = true;
        try {
          container.read(webCurrentTournamentMatchesProvider.notifier).state =
              initialMatches;

          final service = container.read(matchCommandProvider);
          await service.deleteMatchesBulk(['m1', 'm2', 'm3']);

          final remaining = container.read(webCurrentTournamentMatchesProvider);
          expect(remaining.length, equals(1));
          expect(remaining.first.id, equals('other_m'));
          expect(mockRemoteRepo.deletedMatchIds, equals(['m1', 'm2', 'm3']));
        } finally {
          debugIsWebOverride = false;
        }
      },
    );

    test('団体戦ポジションの試合が残り1件であっても個人戦に誤分類されず団体戦グループとして維持されること', () {
      final singleTeamMatch = [
        const MatchModel(
          id: 'm_taisho',
          groupName: 'group_team_1',
          matchType: '大将',
          redName: 'Aチーム:大将選手',
          whiteName: 'Bチーム:大将選手',
        ),
      ];

      final classified = TimelinePlayerMatchClassifier.classifyTeamMatches(
        teamMatchesList: singleTeamMatch,
        teamName: 'Aチーム',
        sanitizedQuery: '',
        matchedMatchIds: {},
        matchedGroupNames: {},
        ownTeams: ['Aチーム'],
      );

      expect(classified.sortedGroups.length, equals(1));
      expect(classified.sortedGroups.first.key, equals('group_team_1'));
      expect(classified.sortedGroups.first.value.first.id, equals('m_taisho'));
      expect(classified.sortedPlayers.isEmpty, isTrue);
    });
  });
}
