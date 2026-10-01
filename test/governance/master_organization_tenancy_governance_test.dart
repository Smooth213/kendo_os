import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/infrastructure/repository/firestore_path.dart';

void main() {
  group('[Governance] マスター組織登録およびマルチテナント空間分離保証規約', () {
    test('FirestorePathファクトリが道場IDに基づき厳格な階層パスを決定論的に返却すること', () {
      const dojoId = 'sample_dojo_123';
      expect(
        FirestorePath.organization(dojoId),
        'organizations/sample_dojo_123',
      );
      expect(
        FirestorePath.players(dojoId),
        'organizations/sample_dojo_123/players',
      );
      expect(
        FirestorePath.matches(dojoId),
        'organizations/sample_dojo_123/matches',
      );
      expect(
        FirestorePath.tournaments(dojoId),
        'organizations/sample_dojo_123/tournaments',
      );
      expect(
        FirestorePath.settings(dojoId),
        'organizations/sample_dojo_123/settings/config',
      );
      expect(
        FirestorePath.auditLogs(dojoId),
        'organizations/sample_dojo_123/auditLogs',
      );
    });

    test('道場登録ボトムシートの実装においてTextSanitizerによるサニタイズと組織パスへの安全な永続化が行われていること', () {
      final file = File(
        'lib/admin/presentation/components/master_register_organization_bottom_sheet.dart',
      );
      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();

      expect(content.contains('TextSanitizer.clean'), isTrue);
      expect(content.contains("collection('organizations')"), isTrue);
      expect(content.contains('currentDojoIdProvider'), isTrue);
    });

    test('選手マスタ管理メニューにおいてデータ管理ダイアログおよび学年一括進級リポジトリ処理への安全な委譲が行われていること', () {
      final file = File(
        'lib/admin/presentation/components/master_menu_bottom_sheet.dart',
      );
      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();

      expect(content.contains('MasterDataCleanupDialog'), isTrue);
      expect(content.contains('playerRepositoryProvider'), isTrue);
      expect(content.contains('promoteAllPlayers'), isTrue);
    });
  });
}
