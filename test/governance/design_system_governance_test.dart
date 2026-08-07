import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

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
          if (file.path.contains('lib/shared/utils/app_snack_bar.dart')) {
            continue;
          }

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
        if (file.path.contains('lib/shared/widgets/app_bottom_sheet.dart')) {
          continue;
        }

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

    test('4. AppBar: アプリ全体での生の AppBar 直書きが 0 件であり AppHeader に統一されていること', () {
      final violations = <String>[];

      for (final file in dartFiles) {
        // AppHeader の基盤定義ファイル自身は除外
        if (file.path.contains('lib/shared/widgets/app_header.dart')) {
          continue;
        }

        final content = file.readAsStringSync();
        if (RegExp(r'\bAppBar\s*\(').hasMatch(content)) {
          violations.add(file.path);
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

    test(
      '5. AlertDialog: アプリ全体での生の AlertDialog 直書きが 0 件であり AppDialog に統一されていること',
      () {
        final violations = <String>[];

        for (final file in dartFiles) {
          // AppDialog の基盤定義ファイルおよび共通ガードは除外
          if (file.path.contains('lib/shared/widgets/app_dialog.dart') ||
              file.path.contains(
                'lib/shared/widgets/critical_action_guard.dart',
              )) {
            continue;
          }

          final content = file.readAsStringSync();
          if (RegExp(r'\bAlertDialog\s*\(').hasMatch(content)) {
            violations.add(file.path);
          }
        }

        expect(
          violations,
          isEmpty,
          reason:
              '主要画面で生の AlertDialog インスタンス化が検出されました。AppDialog(...) を使用してください。\n'
              '違反ファイル:\n${violations.join('\n')}',
        );
      },
    );

    test(
      '6. AppTokens: デザインシステム装飾トークン (AppRadius, AppSpacing, AppFontWeight) が整合していること',
      () {
        expect(AppRadius.smallValue, equals(8.0));
        expect(AppRadius.mediumValue, equals(12.0));
        expect(AppRadius.largeValue, equals(16.0));
        expect(AppSpacing.sm, equals(8.0));
        expect(AppSpacing.md, equals(12.0));
        expect(AppSpacing.lg, equals(16.0));
        expect(AppFontWeight.regular, equals(FontWeight.w400));
        expect(AppFontWeight.semiBold, equals(FontWeight.w600));
        expect(AppFontWeight.bold, equals(FontWeight.w700));
      },
    );

    test(
      '7. AppThemeColors: 全4モード (normal, bunaiksen, normal_viewer, bunaiksen_viewer) x Dark/Light で解像され色の破綻がないこと',
      () {
        for (final isDark in [true, false]) {
          for (final mode in [
            'normal',
            'bunaiksen',
            'normal_viewer',
            'bunaiksen_viewer',
          ]) {
            final theme = AppThemeColors.ofMode(isDark: isDark, mode: mode);
            expect(theme.primaryAccent, isNotNull);
            expect(theme.softAccent, isNotNull);
            expect(theme.cardBackground, isNotNull);
            expect(theme.scaffoldBackground, isNotNull);
            expect(theme.textColor, isNotNull);
            expect(theme.subTextColor, isNotNull);
          }
        }
      },
    );
  });
}
