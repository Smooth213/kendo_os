import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/domain/entities/organization_graduation_type.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';

void main() {
  PlayerModel buildPlayer({
    required String id,
    required int grade,
    String status = PlayerModel.statusActive,
    int? graduatedFiscalYear,
  }) {
    return PlayerModel(
      id: id,
      lastName: 'テスト',
      firstName: id,
      lastNameKana: 'テスト',
      firstNameKana: id,
      grade: grade,
      status: status,
      graduatedFiscalYear: graduatedFiscalYear,
    );
  }

  group(
    '[Unit] OrganizationGraduationType・FiscalYearHelper・PlayerModel 卒業年度と進級境界の検証',
    () {
      test('2027年3月および2027年4月の進級年度が2027・卒業年度が2026年度卒として一致すること', () {
        final march = DateTime(2027, 3, 25);
        final april = DateTime(2027, 4, 1);
        final jan = DateTime(2027, 1, 15);

        expect(FiscalYearHelper.targetPromotionFiscalYear(march), equals(2027));
        expect(
          FiscalYearHelper.defaultGraduationFiscalYear(march),
          equals(2026),
        );

        expect(FiscalYearHelper.targetPromotionFiscalYear(april), equals(2027));
        expect(
          FiscalYearHelper.defaultGraduationFiscalYear(april),
          equals(2026),
        );

        expect(FiscalYearHelper.targetPromotionFiscalYear(jan), equals(2026));
        expect(FiscalYearHelper.defaultGraduationFiscalYear(jan), equals(2025));
      });

      test('PlayerModel.fromMapにおいて旧データ(status欠損)が現役扱いとなり互換性が維持されること', () {
        final legacy = PlayerModel.fromMap({
          'lastName': '山田',
          'firstName': '太郎',
          'lastNameKana': 'ヤマダ',
          'firstNameKana': 'タロウ',
          'grade': 9,
        }, 'p_legacy');

        expect(legacy.status, equals(PlayerModel.statusActive));
        expect(legacy.isActive, isTrue);
        expect(legacy.isGraduated, isFalse);
        expect(legacy.graduatedFiscalYear, isNull);
        expect(legacy.gradeOrGraduationDisplay, equals('中学3年'));
      });

      test('卒業済みPlayerModelにおいて卒業年度表記と卒業時学年表示が正しく返却されること', () {
        final grad = buildPlayer(
          id: 'p_grad',
          grade: 9,
          status: PlayerModel.statusGraduated,
          graduatedFiscalYear: 2026,
        );

        expect(grad.isGraduated, isTrue);
        expect(grad.isActive, isFalse);
        expect(grad.graduationLabel, equals('2026年度卒'));
        expect(grad.gradeOrGraduationDisplay, equals('中学3年卒'));
      });

      test('少年道場・中学部活設定において中3は卒業アーカイブ、例外残留は高1進級、一般は維持されること', () {
        final now = DateTime(2027, 4, 1);
        const type = OrganizationGraduationType.juniorDojo;

        final jh3Grad = buildPlayer(id: 'jh3_grad', grade: 9);
        final jh3Retain = buildPlayer(id: 'jh3_retain', grade: 9);
        final adult = buildPlayer(id: 'adult', grade: 99);

        final outGrad = type.evaluatePromotion(
          jh3Grad,
          retainInActive: false,
          graduationFiscalYear: 2026,
          now: now,
        );
        expect(outGrad.kind, equals(PlayerPromotionKind.graduated));
        expect(outGrad.updatedPlayer.isGraduated, isTrue);
        expect(outGrad.updatedPlayer.grade, equals(9));
        expect(outGrad.updatedPlayer.graduatedFiscalYear, equals(2026));

        final outRetain = type.evaluatePromotion(
          jh3Retain,
          retainInActive: true,
          graduationFiscalYear: 2026,
          now: now,
        );
        expect(outRetain.kind, equals(PlayerPromotionKind.promoted));
        expect(outRetain.updatedPlayer.isActive, isTrue);
        expect(outRetain.updatedPlayer.grade, equals(10));

        final outAdult = type.evaluatePromotion(
          adult,
          retainInActive: false,
          graduationFiscalYear: 2026,
          now: now,
        );
        expect(outAdult.kind, equals(PlayerPromotionKind.unchanged));
        expect(outAdult.updatedPlayer.grade, equals(99));
      });

      test('高校部活および大学部活設定において該当卒業学年が正しく卒業アーカイブされること', () {
        final now = DateTime(2027, 4, 1);

        final hs3 = buildPlayer(id: 'hs3', grade: 12);
        final hsOut = OrganizationGraduationType.highSchoolClub
            .evaluatePromotion(
              hs3,
              retainInActive: false,
              graduationFiscalYear: 2026,
              now: now,
            );
        expect(hsOut.kind, equals(PlayerPromotionKind.graduated));
        expect(hsOut.updatedPlayer.grade, equals(12));
        expect(hsOut.updatedPlayer.graduatedFiscalYear, equals(2026));

        final uni4 = buildPlayer(id: 'uni4', grade: 16);
        final uniOut = OrganizationGraduationType.universityClub
            .evaluatePromotion(
              uni4,
              retainInActive: false,
              graduationFiscalYear: 2026,
              now: now,
            );
        expect(uniOut.kind, equals(PlayerPromotionKind.graduated));
        expect(uniOut.updatedPlayer.grade, equals(16));
        expect(uniOut.updatedPlayer.graduatedFiscalYear, equals(2026));
      });

      test('小学生のみ・一貫道場・既卒業者の境界値が仕様通りに処理されること', () {
        final now = DateTime(2027, 4, 1);

        final elem6 = buildPlayer(id: 'e6', grade: 6);
        final elemOut = OrganizationGraduationType.elementary.evaluatePromotion(
          elem6,
          retainInActive: false,
          graduationFiscalYear: 2026,
          now: now,
        );
        expect(elemOut.kind, equals(PlayerPromotionKind.graduated));
        expect(elemOut.updatedPlayer.grade, equals(6));

        final uni4All = buildPlayer(id: 'u4_all', grade: 16);
        final allOut = OrganizationGraduationType.allAges.evaluatePromotion(
          uni4All,
          retainInActive: false,
          graduationFiscalYear: 2026,
          now: now,
        );
        expect(allOut.kind, equals(PlayerPromotionKind.promoted));
        expect(allOut.updatedPlayer.isActive, isTrue);
        expect(allOut.updatedPlayer.grade, equals(99));

        final alreadyGrad = buildPlayer(
          id: 'done',
          grade: 9,
          status: PlayerModel.statusGraduated,
          graduatedFiscalYear: 2024,
        );
        final doneOut = OrganizationGraduationType.juniorDojo.evaluatePromotion(
          alreadyGrad,
          retainInActive: false,
          graduationFiscalYear: 2026,
          now: now,
        );
        expect(doneOut.kind, equals(PlayerPromotionKind.unchanged));
        expect(doneOut.updatedPlayer.graduatedFiscalYear, equals(2024));
      });
    },
  );
}
