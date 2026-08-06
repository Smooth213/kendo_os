import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

// ============================================================================
// 🛡️ DESIGN SYSTEM GOVERNANCE FORTRESS TEST
// kendo OS デザインシステム完全統一が今後永久に崩れないよう、
// 生の Material UI 直書きコンポーネント（SnackBar, ModalBottomSheet, AppBar,
// AlertDialog, ChoiceChip, ActionChip, FilterChip）の混入を全自動検知・遮断します。
// ============================================================================
void main() {
  group('🛡️ kendo OS Design System Governance Protection Test', () {
    late List<File> dartFiles;

    setUpAll(() {
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue, reason: 'lib directory must exist.');

      dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .toList();
    });

    test(
      '1. SnackBar: 生の ScaffoldMessenger.of(context).showSnackBar の直書きが全アプリで 0 件であること',
      () {
        final violations = <String>[];

        for (final file in dartFiles) {
          // AppSnackBar の基盤定義ファイル自身は除外
          if (file.path.contains('lib/shared/utils/app_snack_bar.dart'))
            continue;

          final content = file.readAsStringSync();
          if (content.contains('showSnackBar(')) {
            violations.add(file.path);
          }
        }

        expect(
          violations,
          isEmpty,
          reason:
              '生の showSnackBar 呼び出しが検出されました。AppSnackBar.show(...) を使用してください。\n'
              '違反ファイル:\n${violations.join('\n')}',
        );
      },
    );

    test('2. ModalBottomSheet: 生の showModalBottomSheet の直書きが全アプリで 0 件であること', () {
      final violations = <String>[];

      for (final file in dartFiles) {
        // AppBottomSheet の基盤定義ファイル自身は除外
        if (file.path.contains('lib/shared/widgets/app_bottom_sheet.dart'))
          continue;

        final content = file.readAsStringSync();
        if (content.contains('showModalBottomSheet(')) {
          violations.add(file.path);
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            '生の showModalBottomSheet 呼び出しが検出されました。showAppBottomSheet(...) を使用してください。\n'
            '違反ファイル:\n${violations.join('\n')}',
      );
    });

    test(
      '3. Chip シリーズ: 生の ChoiceChip / ActionChip / FilterChip の直書きが全アプリで 0 件であること',
      () {
        final violations = <String>[];

        for (final file in dartFiles) {
          // AppChip の基盤定義ファイル自身は除外
          if (file.path.contains('lib/shared/widgets/app_chip.dart')) continue;

          final content = file.readAsStringSync();
          if (RegExp(
            r'\b(ChoiceChip|ActionChip|FilterChip)\s*\(',
          ).hasMatch(content)) {
            violations.add(file.path);
          }
        }

        expect(
          violations,
          isEmpty,
          reason:
              '生の Chip コンポーネント呼び出しが検出されました。AppChoiceChip / AppActionChip / AppFilterChip を使用してください。\n'
              '違反ファイル:\n${violations.join('\n')}',
        );
      },
    );

    test('4. AppBar: 主要画面での生の AppBar 直書きが 0 件であり AppHeader に統一されていること', () {
      final targetFiles = [
        'lib/features/tournament/presentation/operate/screens/tournament_list_screen.dart',
        'lib/features/tournament/presentation/operate/screens/create_tournament_screen.dart',
        'lib/features/tournament/presentation/operate/screens/new_match_screen.dart',
        'lib/features/tournament/presentation/operate/screens/category_rules_screen.dart',
        'lib/features/tournament/presentation/operate/screens/program_viewer_screen.dart',
        'lib/features/tournament/presentation/operate/screens/setup_match_format_screen.dart',
        'lib/features/tournament/presentation/operate/screens/bunaiksen_setup_screen.dart',
        'lib/features/tournament/presentation/operate/screens/order_setup_screen.dart',
      ];

      final violations = <String>[];
      for (final path in targetFiles) {
        final file = File(path);
        if (!file.existsSync()) continue;
        final content = file.readAsStringSync();
        if (RegExp(r'\bAppBar\s*\(').hasMatch(content)) {
          violations.add(path);
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            '主要画面で生の AppBar インスタンス化が検出されました。AppHeader(...) を使用してください。\n'
            '違反ファイル:\n${violations.join('\n')}',
      );
    });

    test('5. AlertDialog: 主要画面での生の AlertDialog 直書きが 0 件であり AppDialog に統一されていること', () {
      final targetFiles = [
        'lib/features/tournament/presentation/operate/screens/home_screen.dart',
        'lib/features/tournament/presentation/operate/screens/program_management_screen.dart',
        'lib/features/tournament/presentation/operate/screens/bunaiksen_home_screen.dart',
        'lib/features/tournament/presentation/operate/screens/order_setup_screen.dart',
        'lib/features/tournament/presentation/operate/screens/category_rules_screen.dart',
      ];

      final violations = <String>[];
      for (final path in targetFiles) {
        final file = File(path);
        if (!file.existsSync()) continue;
        final content = file.readAsStringSync();
        if (RegExp(r'\bAlertDialog\s*\(').hasMatch(content)) {
          violations.add(path);
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            '主要画面で生の AlertDialog インスタンス化が検出されました。AppDialog(...) を使用してください。\n'
            '違反ファイル:\n${violations.join('\n')}',
      );
    });
  });
}
