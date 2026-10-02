import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('[Governance] ガバナンス第5条拡充において Web境界全走査・ネイティブ直接import遮断 監査テスト', () {
    const nativeOnlyAllowlist = {
      'lib/shared/platform/platform_file_io.dart',
      'lib/shared/infrastructure/persistence/twin_match_persistence_helper.dart',
      'lib/shared/infrastructure/repository/local_match_repository.dart',
      'lib/shared/infrastructure/repository/local_match_emergency_backup.dart',
      'lib/shared/infrastructure/repository/program_repository.dart',
      'lib/shared/infrastructure/repository/sync_engine.dart',
      'lib/shared/infrastructure/services/manual_download_service.dart',
      'lib/shared/infrastructure/services/manual_print_share_service.dart',
      'lib/shared/errors/emergency_crash_preserver.dart',
      'lib/shared/utils/payload_compression_helper.dart',
      'lib/admin/presentation/components/master_data_cleanup_dialog.dart',
      'lib/features/p2p/infrastructure/local_p2p_broadcaster.dart',
      'lib/features/pdf/pdf_service.dart',
      'lib/features/tournament/presentation/components/manual/manual_full_manual_tab_view.dart',
      'lib/shared/presentation/screens/embedded_manual_tab_views.dart',
      'lib/features/tournament/presentation/components/program_management/program_title_preview_dialog.dart',
      'lib/features/tournament/presentation/operate/helpers/clipboard_program_helper.dart',
      'lib/features/tournament/presentation/operate/screens/program_management_screen.dart',
      'lib/features/tournament/presentation/operate/providers/sync_backup_helper.dart',
      'lib/shared/presentation/screens/embedded_manual_screen.dart',
    };

    test(
      'lib/ 配下の全Web対応コード（embedded_manual_screen含む）に dart:io / dart:ffi の直接importがないこと',
      () {
        final forbiddenPattern = RegExp(
          r'import\s+[\x27\x22](dart:io|dart:ffi)[\x27\x22]',
        );
        final violations = <String>[];

        final libDir = Directory('lib');
        expect(libDir.existsSync(), isTrue);

        final dartFiles = libDir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'));

        for (final file in dartFiles) {
          final normalizedPath = file.path.replaceAll('\\', '/');
          if (nativeOnlyAllowlist.contains(normalizedPath)) {
            continue;
          }

          final content = file.readAsStringSync();
          if (forbiddenPattern.hasMatch(content)) {
            violations.add(normalizedPath);
          }
        }

        expect(violations, isEmpty, reason: 'Web境界違反ファイル: $violations');
      },
    );
  });
}
