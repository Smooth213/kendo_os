import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/domain/entities/organization_graduation_type.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';

void main() {
  group('[Unit] PlayerRepository 学年一括進級と昇格境界値の検証', () {
    late FakeFirebaseFirestore fakeFirestore;
    late PlayerRepository repository;
    const testDojoId = 'test_dojo_001';
    const targetOrg = '剣道クラブA';
    const otherOrg = '剣道クラブB';

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      repository = PlayerRepository(
        dojoId: testDojoId,
        firestore: fakeFirestore,
      );
    });

    test('未就学児から大学3年生において1学年繰り上げ加算されること', () async {
      final playersCol = fakeFirestore
          .collection('organizations')
          .doc(testDojoId)
          .collection('players');

      // 未就学児(0), 小学生(1), 中学1年(7), 高校1年(10), 大学3年(15)
      final p0 = PlayerModel(
        id: 'p_0',
        lastName: '幼児',
        firstName: '太郎',
        lastNameKana: 'ヨウジ',
        firstNameKana: 'タロウ',
        grade: 0,
        organization: targetOrg,
      );
      final p1 = PlayerModel(
        id: 'p_1',
        lastName: '小一',
        firstName: '次郎',
        lastNameKana: 'ショウイチ',
        firstNameKana: 'ジロウ',
        grade: 1,
        organization: targetOrg,
      );
      final p15 = PlayerModel(
        id: 'p_15',
        lastName: '大三',
        firstName: '三郎',
        lastNameKana: 'ダイサン',
        firstNameKana: 'サブロウ',
        grade: 15,
        organization: targetOrg,
      );

      await playersCol.doc(p0.id).set(p0.toMap());
      await playersCol.doc(p1.id).set(p1.toMap());
      await playersCol.doc(p15.id).set(p15.toMap());

      await repository.promoteAllPlayers(organization: targetOrg);

      final doc0 = await playersCol.doc(p0.id).get();
      final doc1 = await playersCol.doc(p1.id).get();
      final doc15 = await playersCol.doc(p15.id).get();

      expect(doc0.data()?['grade'], equals(1));
      expect(doc1.data()?['grade'], equals(2));
      expect(doc15.data()?['grade'], equals(16));
    });

    test('大学4年生において一般へ昇格すること', () async {
      final playersCol = fakeFirestore
          .collection('organizations')
          .doc(testDojoId)
          .collection('players');

      final p16 = PlayerModel(
        id: 'p_16',
        lastName: '大四',
        firstName: '四郎',
        lastNameKana: 'ダイヨン',
        firstNameKana: 'シロウ',
        grade: 16,
        organization: targetOrg,
      );

      await playersCol.doc(p16.id).set(p16.toMap());

      await repository.promoteAllPlayers(organization: targetOrg);

      final doc16 = await playersCol.doc(p16.id).get();
      expect(doc16.data()?['grade'], equals(99));
    });

    test('既に一般の選手において学年が変更されず維持されること', () async {
      final playersCol = fakeFirestore
          .collection('organizations')
          .doc(testDojoId)
          .collection('players');

      final p99 = PlayerModel(
        id: 'p_99',
        lastName: '一般',
        firstName: '五郎',
        lastNameKana: 'イッパン',
        firstNameKana: 'ゴロウ',
        grade: 99,
        organization: targetOrg,
      );

      await playersCol.doc(p99.id).set(p99.toMap());

      await repository.promoteAllPlayers(organization: targetOrg);

      final doc99 = await playersCol.doc(p99.id).get();
      expect(doc99.data()?['grade'], equals(99));
    });

    test('指定された組織名に合致する選手のみがバッチ更新対象となること', () async {
      final playersCol = fakeFirestore
          .collection('organizations')
          .doc(testDojoId)
          .collection('players');

      final pTarget = PlayerModel(
        id: 'p_target',
        lastName: '対象',
        firstName: '生徒',
        lastNameKana: 'タイショウ',
        firstNameKana: 'セイト',
        grade: 3,
        organization: targetOrg,
      );
      final pOther = PlayerModel(
        id: 'p_other',
        lastName: '他所属',
        firstName: '生徒',
        lastNameKana: 'タショゾク',
        firstNameKana: 'セイト',
        grade: 3,
        organization: otherOrg,
      );

      await playersCol.doc(pTarget.id).set(pTarget.toMap());
      await playersCol.doc(pOther.id).set(pOther.toMap());

      await repository.promoteAllPlayers(organization: targetOrg);

      final docTarget = await playersCol.doc(pTarget.id).get();
      final docOther = await playersCol.doc(pOther.id).get();

      expect(docTarget.data()?['grade'], equals(4));
      expect(docOther.data()?['grade'], equals(3));
    });

    test('卒業区分・例外残留・卒業年度記録・組織履歴更新が一括進級で正しく反映されること', () async {
      final playersCol = fakeFirestore
          .collection('organizations')
          .doc(testDojoId)
          .collection('players');

      await playersCol
          .doc('p_jh2')
          .set(
            PlayerModel(
              id: 'p_jh2',
              lastName: '中二',
              firstName: '太郎',
              lastNameKana: 'チュウニ',
              firstNameKana: 'タロウ',
              grade: 8,
              organization: targetOrg,
            ).toMap(),
          );
      await playersCol
          .doc('p_jh3_grad')
          .set(
            PlayerModel(
              id: 'p_jh3_grad',
              lastName: '中三',
              firstName: '卒業',
              lastNameKana: 'チュウサン',
              firstNameKana: 'ソツギョウ',
              grade: 9,
              organization: targetOrg,
            ).toMap(),
          );
      await playersCol
          .doc('p_jh3_keep')
          .set(
            PlayerModel(
              id: 'p_jh3_keep',
              lastName: '中三',
              firstName: '残留',
              lastNameKana: 'チュウサン',
              firstNameKana: 'ザンリュウ',
              grade: 9,
              organization: targetOrg,
            ).toMap(),
          );
      await playersCol
          .doc('p_adult')
          .set(
            PlayerModel(
              id: 'p_adult',
              lastName: '顧問',
              firstName: '先生',
              lastNameKana: 'コモン',
              firstNameKana: 'センセイ',
              grade: 99,
              organization: targetOrg,
            ).toMap(),
          );
      await playersCol
          .doc('p_old_ob')
          .set(
            PlayerModel(
              id: 'p_old_ob',
              lastName: '先輩',
              firstName: 'オービー',
              lastNameKana: 'センパイ',
              firstNameKana: 'オービー',
              grade: 9,
              organization: targetOrg,
              status: PlayerModel.statusGraduated,
              graduatedFiscalYear: 2024,
            ).toMap(),
          );

      final summary = await repository.promoteAllPlayers(
        organization: null,
        graduationType: OrganizationGraduationType.juniorDojo,
        retainPlayerIds: {'p_jh3_keep'},
        graduationFiscalYear: 2026,
        promotionFiscalYear: 2027,
        now: DateTime(2027, 4, 1),
        recordOrganizationHistory: true,
      );

      expect(summary.promotedCount, equals(2));
      expect(summary.graduatedCount, equals(1));
      expect(summary.unchangedCount, equals(2));

      final docJh2 = (await playersCol.doc('p_jh2').get()).data()!;
      expect(docJh2['grade'], equals(9));
      expect(docJh2['status'], equals(PlayerModel.statusActive));

      final docGrad = (await playersCol.doc('p_jh3_grad').get()).data()!;
      expect(docGrad['grade'], equals(9));
      expect(docGrad['status'], equals(PlayerModel.statusGraduated));
      expect(docGrad['graduatedFiscalYear'], equals(2026));

      final docKeep = (await playersCol.doc('p_jh3_keep').get()).data()!;
      expect(docKeep['grade'], equals(10));
      expect(docKeep['status'], equals(PlayerModel.statusActive));

      final docAdult = (await playersCol.doc('p_adult').get()).data()!;
      expect(docAdult['grade'], equals(99));
      expect(docAdult['status'], equals(PlayerModel.statusActive));

      final docOldOb = (await playersCol.doc('p_old_ob').get()).data()!;
      expect(docOldOb['graduatedFiscalYear'], equals(2024));

      final orgDoc =
          (await fakeFirestore
                  .collection('organizations')
                  .doc(testDojoId)
                  .get())
              .data()!;
      expect(orgDoc['graduationType'], equals('junior_dojo'));
      expect(orgDoc['lastPromotedFiscalYear'], equals(2027));
    });

    test('reactivatePlayerにおいて卒業生が現役復帰し卒業年度がクリアされること', () async {
      final playersCol = fakeFirestore
          .collection('organizations')
          .doc(testDojoId)
          .collection('players');

      await playersCol
          .doc('p_ob')
          .set(
            PlayerModel(
              id: 'p_ob',
              lastName: '卒業',
              firstName: '復帰',
              lastNameKana: 'ソツギョウ',
              firstNameKana: 'フッキ',
              grade: 9,
              status: PlayerModel.statusGraduated,
              graduatedFiscalYear: 2026,
            ).toMap(),
          );

      await repository.reactivatePlayer('p_ob', nextGrade: 10);

      final doc = (await playersCol.doc('p_ob').get()).data()!;
      expect(doc['status'], equals(PlayerModel.statusActive));
      expect(doc['grade'], equals(10));
      expect(doc.containsKey('graduatedFiscalYear'), isFalse);
      expect(doc.containsKey('graduatedAt'), isFalse);
    });
  });
}
