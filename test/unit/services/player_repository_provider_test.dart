import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';

void main() {
  group('[Unit] PlayerRepository & Provider選手データ取得テスト', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    test('道場指定時(千代田道場)にProvider経由で選手リストが正常に取得できること', () async {
      await fakeFirestore
          .collection('organizations')
          .doc('chiyoda_dojo_id')
          .collection('players')
          .doc('player_1')
          .set({
            'id': 'player_1',
            'lastName': '山田',
            'firstName': '太郎',
            'lastNameKana': 'ヤマダ',
            'firstNameKana': 'タロウ',
            'grade': 3,
            'organization': '千代田道場',
            'isBeginner': false,
          });

      final container = ProviderContainer(
        overrides: [
          currentDojoIdProvider.overrideWith((ref) => 'chiyoda_dojo_id'),
          playerRepositoryProvider.overrideWith((ref) {
            final dojoId = ref.watch(currentDojoIdProvider);
            return PlayerRepository(dojoId: dojoId, firestore: fakeFirestore);
          }),
        ],
      );
      addTearDown(container.dispose);

      final playerRepository = container.read(playerRepositoryProvider);
      final stream = playerRepository.getPlayers();
      final playerList = await stream.first;

      expect(playerList, hasLength(1));
      expect(playerList.first.name, '山田 太郎');
      expect(playerList.first.organization, '千代田道場');
    });

    test('別の道場(港武道館)を指定した場合もProvider経由で独立して選手リストが取得できること', () async {
      await fakeFirestore
          .collection('organizations')
          .doc('minato_budokan_id')
          .collection('players')
          .doc('player_2')
          .set({
            'id': 'player_2',
            'lastName': '佐藤',
            'firstName': '次郎',
            'lastNameKana': 'サトウ',
            'firstNameKana': 'ジロウ',
            'grade': 4,
            'organization': '港武道館',
            'isBeginner': false,
          });

      final container = ProviderContainer(
        overrides: [
          currentDojoIdProvider.overrideWith((ref) => 'minato_budokan_id'),
          playerRepositoryProvider.overrideWith((ref) {
            final dojoId = ref.watch(currentDojoIdProvider);
            return PlayerRepository(dojoId: dojoId, firestore: fakeFirestore);
          }),
        ],
      );
      addTearDown(container.dispose);

      final playerRepository = container.read(playerRepositoryProvider);
      final stream = playerRepository.getPlayers();
      final playerList = await stream.first;

      expect(playerList, hasLength(1));
      expect(playerList.first.name, '佐藤 次郎');
      expect(playerList.first.organization, '港武道館');
    });
  });
}
