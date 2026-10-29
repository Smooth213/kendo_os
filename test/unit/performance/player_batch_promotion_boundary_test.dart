import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';

void main() {
  group('[Unit] 選手一括進級におけるFirestoreバッチ制限分割境界テスト', () {
    late FakeFirebaseFirestore fakeFirestore;
    late PlayerRepository repository;
    const testDojoId = 'dojo_massive_001';
    const targetOrg = '道場連盟支部';

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      repository = PlayerRepository(
        dojoId: testDojoId,
        firestore: fakeFirestore,
      );
    });

    test('道場選手数が500名を超える大規模進級時にもバッチが自動分割され全選手が欠損なく進級すること', () async {
      final playersCol = fakeFirestore
          .collection('organizations')
          .doc(testDojoId)
          .collection('players');

      // 550名の選手データを投入（Firestoreの単一バッチ500件上限を超える規模）
      const totalCount = 550;
      for (int i = 0; i < totalCount; i++) {
        final player = PlayerModel(
          id: 'player_batch_$i',
          lastName: '選手',
          firstName: '$i',
          lastNameKana: 'センシュ',
          firstNameKana: '$i',
          grade: 5, // 小学5年生
          organization: targetOrg,
        );
        await playersCol.doc(player.id).set(player.toMap());
      }

      // 一括進級を実行（内部で450件ごとに分割コミットされる）
      await repository.promoteAllPlayers(organization: targetOrg);

      // 全550名が小学6年生（grade: 6）に進級していることを検証
      final snapshot = await playersCol
          .where('organization', isEqualTo: targetOrg)
          .get();
      expect(snapshot.docs.length, totalCount);

      final allPromoted = snapshot.docs.every(
        (doc) => doc.data()['grade'] == 6,
      );
      expect(allPromoted, isTrue);
    });
  });
}
