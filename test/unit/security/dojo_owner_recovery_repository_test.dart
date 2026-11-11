import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/security/dojo_owner_recovery_repository.dart';
import 'package:kendo_os/security/dojo_security_repository.dart';
import 'package:kendo_os/security/viewer_share_models.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';

void main() {
  group('[Unit] DojoOwnerRecoveryRepository 代表者管理・PIN初期化テスト', () {
    late FakeFirebaseFirestore fakeFirestore;
    late DojoSecurityRepository securityRepo;
    late DojoOwnerRecoveryRepository recoveryRepo;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      securityRepo = DojoSecurityRepository(fakeFirestore);
      recoveryRepo = DojoOwnerRecoveryRepository(fakeFirestore);
    });

    test('代表者Googleアカウントを最大5名まで登録・引き継ぎ更新でき、6名目は拒否されること', () async {
      await securityRepo.createDojoWithPin(
        dojoId: 'univ_kendo',
        joinPin: 'univ2026',
        uid: 'admin_1',
      );

      final tooMany = List.generate(
        6,
        (i) => DojoOwnerAccount(email: 'user$i@example.com'),
      );
      final rejected = await recoveryRepo.updateDojoOwners(
        dojoId: 'univ_kendo',
        owners: tooMany,
        currentAdminPin: '9999',
        uid: 'admin_1',
      );
      expect(rejected.success, isFalse);
      expect(rejected.errorMessage, contains('最大5名'));

      final validOwners = [
        const DojoOwnerAccount(
          email: 'Captain2026@Example.com',
          displayName: '主将',
        ),
        const DojoOwnerAccount(email: 'coach@example.com', displayName: '監督'),
      ];
      final ok = await recoveryRepo.updateDojoOwners(
        dojoId: 'univ_kendo',
        owners: validOwners,
        currentAdminPin: '9999',
        uid: 'admin_1',
      );
      expect(ok.success, isTrue);

      final fetched = await recoveryRepo.fetchDojoOwners('univ_kendo');
      expect(fetched.map((e) => e.email).toList(), [
        'captain2026@example.com',
        'coach@example.com',
      ]);

      // 引き継ぎ（旧主将を外して新主将へ差し替え）
      await recoveryRepo.updateDojoOwners(
        dojoId: 'univ_kendo',
        owners: const [
          DojoOwnerAccount(email: 'coach@example.com', displayName: '監督'),
          DojoOwnerAccount(
            email: 'captain2027@example.com',
            displayName: '新主将',
          ),
        ],
        currentAdminPin: '9999',
        uid: 'admin_2',
      );

      final oldVerify = await recoveryRepo.verifyOwnerGoogleAccess(
        dojoId: 'univ_kendo',
        email: 'captain2026@example.com',
      );
      expect(oldVerify.isOwner, isFalse);

      final newVerify = await recoveryRepo.verifyOwnerGoogleAccess(
        dojoId: 'univ_kendo',
        email: 'Captain2027@example.com',
      );
      expect(newVerify.isOwner, isTrue);
    });

    test('代表者Google確認後に道場入室PINとロールPINを初期化でき、Admin確認で新PINが復号できること', () async {
      final initialJoinHash = await securityRepo.createDojoWithPin(
        dojoId: 'dojo_reset',
        joinPin: 'oldpass1',
        uid: 'u1',
      );

      await securityRepo.updateDojoSecurityPins(
        dojoId: 'dojo_reset',
        currentAdminPin: '9999',
        newRolePins: {
          UserRole.admin: '7777',
          UserRole.operator: '6666',
          UserRole.recorder: '5555',
        },
        uid: 'u1',
      );

      final resetRes = await recoveryRepo.resetPinsByVerifiedOwner(
        dojoId: 'dojo_reset',
        uid: 'owner_uid',
        existingJoinPinHash: initialJoinHash,
        newJoinPin: 'newpass2027',
        resetRolePinsToDefault: true,
        elevateToAdmin: true,
      );

      expect(resetRes.success, isTrue);
      expect(resetRes.effectiveAdminPin, '9999');
      expect(resetRes.newJoinPinHash, isNotNull);

      // 新しい入室PINでのみ入室可能
      expect(
        await securityRepo.joinExistingDojoWithPin(
          dojoId: 'dojo_reset',
          joinPin: 'oldpass1',
          uid: 'guest',
        ),
        isNull,
      );
      expect(
        await securityRepo.joinExistingDojoWithPin(
          dojoId: 'dojo_reset',
          joinPin: 'newpass2027',
          uid: 'guest',
        ),
        resetRes.newJoinPinHash,
      );

      // Admin本人確認で初期化後の全PINが復号・初期表示できること
      final unlockRes = await securityRepo.verifyAdminAndUnlockVault(
        dojoId: 'dojo_reset',
        currentAdminPin: '9999',
        joinPinHash: resetRes.newJoinPinHash,
        uid: 'owner_uid',
      );
      expect(unlockRes.status, AdminVaultUnlockStatus.unlocked);
      expect(unlockRes.payload?.joinPin, 'newpass2027');
      expect(unlockRes.payload?.adminPin, '9999');
      expect(unlockRes.payload?.operatorPin, '2468');
      expect(unlockRes.payload?.recorderPin, '1357');
    });

    test(
      '不正メールは拒否され、ロールPIN未初期化での入室PINリセット時は古いロールPINを維持しつつ古いボールトをクリアすること',
      () async {
        await securityRepo.createDojoWithPin(
          dojoId: 'dojo_partial',
          joinPin: 'join_old',
          uid: 'u1',
        );
        await securityRepo.updateDojoSecurityPins(
          dojoId: 'dojo_partial',
          currentAdminPin: '9999',
          newRolePins: {UserRole.admin: '7777'},
          uid: 'u1',
        );

        final invalidEmailRes = await recoveryRepo.updateDojoOwners(
          dojoId: 'dojo_partial',
          owners: const [DojoOwnerAccount(email: 'invalid-email')],
          currentAdminPin: '7777',
          uid: 'u1',
        );
        expect(invalidEmailRes.success, isFalse);

        // 入室PINのみリセット（ロールPINは変更しない）
        final resetJoinOnly = await recoveryRepo.resetPinsByVerifiedOwner(
          dojoId: 'dojo_partial',
          uid: 'owner_1',
          newJoinPin: 'join_new2027',
          resetRolePinsToDefault: false,
        );
        expect(resetJoinOnly.success, isTrue);

        // カスタムAdmin PIN 7777 は引き続き有効
        expect(
          await securityRepo.authenticateRoleWithPin(
            dojoId: 'dojo_partial',
            role: UserRole.admin,
            rolePin: '7777',
            joinPinHash: resetJoinOnly.newJoinPinHash,
            uid: 'owner_1',
          ),
          isTrue,
        );

        // 古い暗号化ボールトはクリアされ、誤って古い入室PINが表示されないこと
        final unlock = await securityRepo.verifyAdminAndUnlockVault(
          dojoId: 'dojo_partial',
          currentAdminPin: '7777',
          joinPinHash: resetJoinOnly.newJoinPinHash,
          uid: 'owner_1',
        );
        expect(unlock.status, AdminVaultUnlockStatus.legacyUnmigrated);
        expect(unlock.payload?.joinPin, isEmpty);
        expect(unlock.payload?.adminPin, '7777');
      },
    );

    test(
      '不正メールは拒否され、ロールPIN未初期化での入室PINリセット時は古いロールPINを維持しつつ古いボールトをクリアすること',
      () async {
        await securityRepo.createDojoWithPin(
          dojoId: 'dojo_partial',
          joinPin: 'join_old',
          uid: 'u1',
        );
        await securityRepo.updateDojoSecurityPins(
          dojoId: 'dojo_partial',
          currentAdminPin: '9999',
          newRolePins: {UserRole.admin: '7777'},
          uid: 'u1',
        );

        final invalidEmailRes = await recoveryRepo.updateDojoOwners(
          dojoId: 'dojo_partial',
          owners: const [DojoOwnerAccount(email: 'invalid-email')],
          currentAdminPin: '7777',
          uid: 'u1',
        );
        expect(invalidEmailRes.success, isFalse);

        // 入室PINのみリセット（ロールPINは変更しない）
        final resetJoinOnly = await recoveryRepo.resetPinsByVerifiedOwner(
          dojoId: 'dojo_partial',
          uid: 'owner_1',
          newJoinPin: 'join_new2027',
          resetRolePinsToDefault: false,
        );
        expect(resetJoinOnly.success, isTrue);

        // カスタムAdmin PIN 7777 は引き続き有効
        expect(
          await securityRepo.authenticateRoleWithPin(
            dojoId: 'dojo_partial',
            role: UserRole.admin,
            rolePin: '7777',
            joinPinHash: resetJoinOnly.newJoinPinHash,
            uid: 'owner_1',
          ),
          isTrue,
        );

        // 古い暗号化ボールトはクリアされ、誤って古い入室PINが表示されないこと
        final unlock = await securityRepo.verifyAdminAndUnlockVault(
          dojoId: 'dojo_partial',
          currentAdminPin: '7777',
          joinPinHash: resetJoinOnly.newJoinPinHash,
          uid: 'owner_1',
        );
        expect(unlock.status, AdminVaultUnlockStatus.legacyUnmigrated);
        expect(unlock.payload?.joinPin, isEmpty);
        expect(unlock.payload?.adminPin, '7777');
      },
    );
  });
}
