import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/infrastructure/repository/firestore_path.dart';
import 'package:kendo_os/shared/sync/current_sync_context.dart';

void main() {
  group('[Unit] マルチテナント空間パス決定論および同期コンテキスト単体テスト', () {
    test('FirestorePathにおいて道場別の階層パスが厳格かつ決定論的に生成されること', () {
      const dojoId = 'dojo_tokyo_01';
      expect(FirestorePath.organization(dojoId), 'organizations/dojo_tokyo_01');
      expect(
        FirestorePath.players(dojoId),
        'organizations/dojo_tokyo_01/players',
      );
      expect(
        FirestorePath.player(dojoId, 'p-100'),
        'organizations/dojo_tokyo_01/players/p-100',
      );
      expect(
        FirestorePath.matches(dojoId),
        'organizations/dojo_tokyo_01/matches',
      );
      expect(
        FirestorePath.match(dojoId, 'm-200'),
        'organizations/dojo_tokyo_01/matches/m-200',
      );
      expect(
        FirestorePath.tournaments(dojoId),
        'organizations/dojo_tokyo_01/tournaments',
      );
      expect(
        FirestorePath.tournament(dojoId, 't-300'),
        'organizations/dojo_tokyo_01/tournaments/t-300',
      );
      expect(
        FirestorePath.settings(dojoId),
        'organizations/dojo_tokyo_01/settings/config',
      );
      expect(
        FirestorePath.auditLogs(dojoId),
        'organizations/dojo_tokyo_01/auditLogs',
      );
    });

    test('CurrentSyncContextにおいて不変性とcopyWithによる安全な複製が保証されること', () {
      const context = CurrentSyncContext(
        organizationId: 'org-abc',
        role: UserRole.operator,
        deviceId: 'device-ipad-01',
      );

      expect(context.organizationId, 'org-abc');
      expect(context.role, UserRole.operator);
      expect(context.deviceId, 'device-ipad-01');

      final updatedContext = context.copyWith(role: UserRole.admin);
      expect(updatedContext.organizationId, 'org-abc');
      expect(updatedContext.role, UserRole.admin);
      expect(updatedContext.deviceId, 'device-ipad-01');

      // 元のインスタンスは不変
      expect(context.role, UserRole.operator);
    });
  });
}
