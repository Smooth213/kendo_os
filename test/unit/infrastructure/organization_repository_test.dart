import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/domain/entities/organization.dart';
import 'package:kendo_os/shared/infrastructure/repository/organization_repository.dart';

void main() {
  group('[Unit] 道場組織リポジトリFirestore連携単体テスト', () {
    late FakeFirebaseFirestore fakeFirestore;
    late OrganizationRepository repository;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      repository = OrganizationRepository(fakeFirestore);
    });

    test('新規組織の保存時に自動でドキュメントIDが採番されストリーム監視で取得できること', () async {
      final newOrg = const Organization(
        id: '',
        name: '東剣友会',
        memberNames: ['山田', '佐々木'],
      );

      await repository.saveOrganization(newOrg);

      final orgs = await repository.watchOrganizations().first;
      expect(orgs.length, 1);
      expect(orgs.first.name, '東剣友会');
      expect(orgs.first.id, isNotEmpty);
      expect(orgs.first.memberNames, containsAll(['山田', '佐々木']));
    });

    test('既存IDを持つ組織の更新時に同一IDで上書き保存されること', () async {
      final org = const Organization(
        id: 'org_custom_101',
        name: '西武館',
        memberNames: ['伊藤'],
      );

      await repository.saveOrganization(org);

      final snapshot = await fakeFirestore
          .collection('organizations')
          .doc('org_custom_101')
          .get();
      expect(snapshot.exists, isTrue);
      expect(snapshot.data()?['name'], '西武館');

      // 更新
      final updated = org.copyWith(name: '西武館道場');
      await repository.saveOrganization(updated);

      final orgs = await repository.watchOrganizations().first;
      expect(orgs.length, 1);
      expect(orgs.first.id, 'org_custom_101');
      expect(orgs.first.name, '西武館道場');
    });

    test('選手追加時に配列ユニオンによって重複なくメンバーが追加されること', () async {
      final docRef = await fakeFirestore.collection('organizations').add({
        'name': '南陽道場',
        'memberNames': ['高木'],
      });

      await repository.addPlayer(docRef.id, '三浦');

      final updatedDoc = await docRef.get();
      final members = List<String>.from(
        updatedDoc.data()?['memberNames'] ?? [],
      );
      expect(members, containsAll(['高木', '三浦']));
    });

    test('チームテンプレートの保存時に自動採番されたIDが付与されサブコレクションから取得できること', () async {
      const orgId = 'org_north_01';
      final team = const TeamTemplate(
        id: '',
        name: 'Aチーム',
        orderedMemberNames: ['先鋒選手', '中堅選手', '大将選手'],
      );

      await repository.saveTeamTemplate(orgId, team);

      final teams = await repository.watchTeamTemplates(orgId).first;
      expect(teams.length, 1);
      expect(teams.first.name, 'Aチーム');
      expect(teams.first.id, isNotEmpty);
      expect(teams.first.orderedMemberNames.length, 3);
    });
  });
}
