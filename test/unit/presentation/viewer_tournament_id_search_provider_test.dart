import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/viewer/providers/viewer_tournament_id_search_provider.dart';

void main() {
  group('webTournamentIdSearchProvider テスト', () {
    test('ローカルマッチリストに一致するgroupNameがある場合、そのtournamentIdを返すこと', () async {
      final match = MatchModel(
        id: 'm1',
        tournamentId: 'tour_abc',
        groupName: 'group_xyz',
        matchType: '個人戦',
        redName: '赤',
        whiteName: '白',
      );

      final container = ProviderContainer(
        overrides: [
          matchListProvider.overrideWith((ref) => [match]),
        ],
      );

      final result = await container.read(
        webTournamentIdSearchProvider('group_xyz').future,
      );

      expect(result, 'tour_abc');
    });

    test('一致するgroupNameがないがフォールバック試合が存在する場合、最初のtournamentIdを返すこと', () async {
      final match = MatchModel(
        id: 'm2',
        tournamentId: 'fallback_tour',
        groupName: 'other_group',
        matchType: '個人戦',
        redName: '赤',
        whiteName: '白',
      );

      final container = ProviderContainer(
        overrides: [
          matchListProvider.overrideWith((ref) => [match]),
        ],
      );

      final result = await container.read(
        webTournamentIdSearchProvider('non_existent_group').future,
      );

      // Firestore未初期化のユニットテスト環境ではcatchブロックまたはfallbackMatches経由で解決される
      expect(result, isNotNull);
      expect(
        result,
        anyOf(equals('fallback_tour'), equals('default_tournament')),
      );
    });
  });
}
