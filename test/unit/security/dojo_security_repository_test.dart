import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/security/dojo_security_repository.dart';
import 'package:kendo_os/security/pin_hasher.dart';
import 'package:kendo_os/security/viewer_share_models.dart';
import 'package:kendo_os/security/viewer_share_repository.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';

void main() {
  group('[Unit] DojoSecurityRepository 道場PIN・ロールPIN・観戦リンク検証', () {
    late FakeFirebaseFirestore fakeFirestore;
    late DojoSecurityRepository repo;
    late ViewerShareRepository shareRepo;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      repo = DojoSecurityRepository(fakeFirestore);
      shareRepo = ViewerShareRepository(fakeFirestore);
    });

    test('新規道場作成時に道場入室PINと初期ロールPINハッシュが保存され、正しいPINのみ入室できること', () async {
      expect(
        await repo.inspectRoomStatus('sakura_dojo'),
        DojoJoinStatus.notFound,
      );

      final joinHash = await repo.createDojoWithPin(
        dojoId: 'sakura_dojo',
        joinPin: 'sakura2026',
        uid: 'owner_uid',
      );
      expect(joinHash, PinHasher.hashJoinPin('sakura_dojo', 'sakura2026'));
      expect(
        await repo.inspectRoomStatus('sakura_dojo'),
        DojoJoinStatus.requiresPin,
      );

      // 不正な入室PINは拒否
      final wrongJoin = await repo.joinExistingDojoWithPin(
        dojoId: 'sakura_dojo',
        joinPin: 'wrongpass',
        uid: 'guest_uid',
      );
      expect(wrongJoin, isNull);

      // 正しい入室PINは成功
      final rightJoin = await repo.joinExistingDojoWithPin(
        dojoId: 'sakura_dojo',
        joinPin: 'sakura2026',
        uid: 'guest_uid',
      );
      expect(rightJoin, equals(joinHash));
    });

    test('PIN未設定の既存道場を legacyUnsetPin と検知し、初回設定後にPIN必須化されること', () async {
      await fakeFirestore.collection('organizations').doc('legacy_dojo').set({
        'createdBy': 'owner_terminal',
      });

      expect(
        await repo.inspectRoomStatus('legacy_dojo'),
        DojoJoinStatus.legacyUnsetPin,
      );

      await repo.initializeLegacyDojoPin(
        dojoId: 'legacy_dojo',
        joinPin: 'legacy2026',
        uid: 'admin_uid',
      );

      expect(
        await repo.inspectRoomStatus('legacy_dojo'),
        DojoJoinStatus.requiresPin,
      );
      expect(
        await repo.joinExistingDojoWithPin(
          dojoId: 'legacy_dojo',
          joinPin: 'legacy2026',
          uid: 'member_uid',
        ),
        isNotNull,
      );
    });

    test('初期ロールPIN(9999/2468/1357)で認証でき、Admin設定変更後は新しいPINのみ通ること', () async {
      final joinHash = await repo.createDojoWithPin(
        dojoId: 'kendo_a',
        joinPin: 'kendo2026',
        uid: 'u1',
      );

      expect(await repo.needsInitialAdminRolePinPrompt('kendo_a'), isTrue);

      expect(
        await repo.authenticateRoleWithPin(
          dojoId: 'kendo_a',
          role: UserRole.admin,
          rolePin: '9999',
          joinPinHash: joinHash,
          uid: 'u1',
        ),
        isTrue,
      );
      expect(
        await repo.authenticateRoleWithPin(
          dojoId: 'kendo_a',
          role: UserRole.admin,
          rolePin: '1111',
          joinPinHash: joinHash,
          uid: 'u1',
        ),
        isFalse,
      );

      // 現在のAdmin PINが違えば更新失敗
      final failedUpdate = await repo.updateDojoSecurityPins(
        dojoId: 'kendo_a',
        currentAdminPin: '0000',
        newJoinPin: 'newjoin99',
        newRolePins: {UserRole.admin: '8888'},
        uid: 'u1',
      );
      expect(failedUpdate.success, isFalse);

      // 正しいAdmin PINで道場入室PINとAdmin/Recorder PINを更新
      final okUpdate = await repo.updateDojoSecurityPins(
        dojoId: 'kendo_a',
        currentAdminPin: '9999',
        newJoinPin: 'newjoin99',
        newRolePins: {UserRole.admin: '8888', UserRole.recorder: '4321'},
        uid: 'u1',
      );
      expect(okUpdate.success, isTrue);
      expect(okUpdate.newJoinPinHash, isNotNull);
      expect(await repo.needsInitialAdminRolePinPrompt('kendo_a'), isFalse);

      // 旧Admin PINは無効になり新PINが有効
      expect(
        await repo.authenticateRoleWithPin(
          dojoId: 'kendo_a',
          role: UserRole.admin,
          rolePin: '9999',
          joinPinHash: okUpdate.newJoinPinHash,
          uid: 'u1',
        ),
        isFalse,
      );
      expect(
        await repo.authenticateRoleWithPin(
          dojoId: 'kendo_a',
          role: UserRole.admin,
          rolePin: '8888',
          joinPinHash: okUpdate.newJoinPinHash,
          uid: 'u1',
        ),
        isTrue,
      );
    });

    test('観戦共有リンクが 24時間 / 7日間 / 無期限 / 停止 の状態に応じて有効・失効を判定すること', () async {
      await repo.createDojoWithPin(
        dojoId: 'dojo_share',
        joinPin: 'share2026',
        uid: 'admin_1',
      );

      final t0 = DateTime.utc(2026, 11, 11, 10, 0, 0);
      final link7d = await shareRepo.saveTournamentShareLink(
        dojoId: 'dojo_share',
        tournamentId: 'tourney_1',
        preset: ViewerShareExpiryPreset.days7,
        uid: 'admin_1',
        now: t0,
      );

      // 期限内（3日後）は通過、他大会IDは拒否
      final okRes = await shareRepo.verifyAndActivateShareLink(
        dojoId: 'dojo_share',
        tournamentId: 'tourney_1',
        token: link7d.token,
        uid: 'viewer_1',
        now: t0.add(const Duration(days: 3)),
      );
      expect(okRes.status, ViewerShareAccessStatus.valid);

      final wrongTournament = await shareRepo.verifyAndActivateShareLink(
        dojoId: 'dojo_share',
        tournamentId: 'tourney_2',
        token: link7d.token,
        uid: 'viewer_1',
        now: t0.add(const Duration(days: 3)),
      );
      expect(wrongTournament.status, ViewerShareAccessStatus.invalid);

      // 8日後は期限切れ
      final expiredRes = await shareRepo.verifyAndActivateShareLink(
        dojoId: 'dojo_share',
        tournamentId: 'tourney_1',
        token: link7d.token,
        uid: 'viewer_1',
        now: t0.add(const Duration(days: 8)),
      );
      expect(expiredRes.status, ViewerShareAccessStatus.expired);

      // 無期限に切り替えれば30日後も通過
      await shareRepo.saveTournamentShareLink(
        dojoId: 'dojo_share',
        tournamentId: 'tourney_1',
        preset: ViewerShareExpiryPreset.unlimited,
        existingToken: link7d.token,
        uid: 'admin_1',
        now: t0,
      );
      final unlimitedRes = await shareRepo.verifyAndActivateShareLink(
        dojoId: 'dojo_share',
        tournamentId: 'tourney_1',
        token: link7d.token,
        uid: 'viewer_1',
        now: t0.add(const Duration(days: 30)),
      );
      expect(unlimitedRes.status, ViewerShareAccessStatus.valid);

      // 停止に切り替えれば即時遮断
      await shareRepo.saveTournamentShareLink(
        dojoId: 'dojo_share',
        tournamentId: 'tourney_1',
        preset: ViewerShareExpiryPreset.revoked,
        existingToken: link7d.token,
        uid: 'admin_1',
        now: t0,
      );
      final revokedRes = await shareRepo.verifyAndActivateShareLink(
        dojoId: 'dojo_share',
        tournamentId: 'tourney_1',
        token: link7d.token,
        uid: 'viewer_1',
        now: t0,
      );
      expect(revokedRes.status, ViewerShareAccessStatus.revoked);
    });
  });
}
