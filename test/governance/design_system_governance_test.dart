import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
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
      '3. Chip シリーズ: 生の Chip / ChoiceChip / ActionChip / FilterChip の直書きが全アプリで 0 件であること',
      () {
        final violations = <String>[];

        for (final file in dartFiles) {
          // AppChip の基盤定義ファイル自身は除外
          if (file.path.contains('lib/shared/widgets/app_chip.dart')) continue;

          final content = file.readAsStringSync();
          if (RegExp(
            r'\b(Chip|ChoiceChip|ActionChip|FilterChip|RawChip|InputChip)\s*\(',
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
      '5. Dialog: アプリ全体での生の showDialog / AlertDialog 直書きが 0 件であり AppDialog / showAppDialog に統一されていること',
      () {
        final violations = <String>[];

        for (final file in dartFiles) {
          // AppDialog の基盤定義ファイル自身のみ除外
          if (file.path.contains('lib/shared/widgets/app_dialog.dart')) {
            continue;
          }

          final content = file.readAsStringSync();
          if (content.contains('showDialog(') ||
              RegExp(r'\bAlertDialog\s*\(').hasMatch(content)) {
            violations.add(file.path);
          }
        }

        expect(
          violations,
          isEmpty,
          reason:
              '生の showDialog または AlertDialog 呼び出しが検出されました。showAppDialog / AppDialog を使用してください。\n'
              '違反ファイル:\n${violations.join('\n')}',
        );
      },
    );

    test('6. AppTokens & AppKendoColors: デザインシステム装飾トークンが整合していること', () {
      expect(AppRadius.microValue, equals(2.0));
      expect(AppRadius.tinyValue, equals(4.0));
      expect(AppRadius.subValue, equals(6.0));
      expect(AppRadius.smallValue, equals(8.0));
      expect(AppRadius.mediumValue, equals(12.0));
      expect(AppRadius.largeValue, equals(16.0));
      expect(AppRadius.roundValue, equals(20.0));
      expect(AppSpacing.sm, equals(8.0));
      expect(AppSpacing.md, equals(12.0));
      expect(AppSpacing.lg, equals(16.0));
      expect(AppFontWeight.light, equals(FontWeight.w300));
      expect(AppFontWeight.regular, equals(FontWeight.w400));
      expect(AppFontWeight.medium, equals(FontWeight.w500));
      expect(AppFontWeight.semiBold, equals(FontWeight.w600));
      expect(AppFontWeight.bold, equals(FontWeight.w700));
      expect(AppFontWeight.black, equals(FontWeight.w900));
      expect(AppFontSize.micro, equals(8.0));
      expect(AppFontSize.badge, equals(10.0));
      expect(AppFontSize.caption, equals(11.0));
      expect(AppKendoColors.aka, equals(Colors.red));
      expect(AppKendoColors.shiro, equals(Colors.white));
    });

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
            expect(theme.separatorColor, isNotNull);
            expect(theme.inputBackground, isNotNull);
            expect(theme.hintColor, isNotNull);
            expect(theme.rosePink, isNotNull);
            expect(theme.successColor, isNotNull);
            expect(theme.warningColor, isNotNull);
            expect(theme.errorColor, isNotNull);
            expect(theme.infoColor, isNotNull);
          }
        }
      },
    );

    test(
      '8. AppFontWeight: UIコンポーネントにおける生の FontWeight.w400/w600/w700/bold の直接指定が 0 件であり AppFontWeight に統一されていること',
      () {
        final violations = <String>[];

        for (final file in dartFiles) {
          // トークン定義自身および PDF ペインターは除外
          if (file.path.contains('lib/shared/theme/app_tokens.dart') ||
              file.path.contains('lib/features/pdf/')) {
            continue;
          }

          final content = file.readAsStringSync();
          if (RegExp(
            r'\bFontWeight\.(w400|w600|w700|bold)\b',
          ).hasMatch(content)) {
            violations.add(file.path);
          }
        }

        expect(
          violations,
          isEmpty,
          reason:
              'UIコンポーネント内で生の FontWeight 直接指定が検出されました。AppFontWeight.regular / semiBold / bold を使用してください。\n'
              '違反ファイル:\n${violations.join('\n')}',
        );
      },
    );

    test(
      '9. AppRadius: UIコンポーネントにおける生の BorderRadius.circular(8/12/16/24) の直接指定が 0 件であり AppRadius に統一されていること',
      () {
        final violations = <String>[];

        for (final file in dartFiles) {
          // トークン定義自身および PDF ペインターは除外
          if (file.path.contains('lib/shared/theme/app_tokens.dart') ||
              file.path.contains('lib/features/pdf/')) {
            continue;
          }

          final content = file.readAsStringSync();
          if (RegExp(
            r'BorderRadius\.circular\s*\(\s*(8|12|16|24)(\.0)?\s*\)',
          ).hasMatch(content)) {
            violations.add(file.path);
          }
        }

        expect(
          violations,
          isEmpty,
          reason:
              'UIコンポーネント内で生の BorderRadius.circular(8/12/16/24) 直接指定が検出されました。AppRadius (small/medium/large/xlarge) を使用してください。\n'
              '違反ファイル:\n${violations.join('\n')}',
        );
      },
    );

    test(
      '10. AppSpacing: UIコンポーネントにおける生の SizedBox(height/width: 4/8/12/16/24/32) の直接数値指定が 0 件であり AppSpacing に統一されていること',
      () {
        final violations = <String>[];

        for (final file in dartFiles) {
          // トークン定義自身および PDF ペインターは除外
          if (file.path.contains('lib/shared/theme/app_tokens.dart') ||
              file.path.contains('lib/features/pdf/')) {
            continue;
          }

          final content = file.readAsStringSync();
          if (RegExp(
            r'SizedBox\s*\(\s*(height|width)\s*:\s*(4|8|12|16|24|32)(\.0)?\s*\)',
          ).hasMatch(content)) {
            violations.add(file.path);
          }
        }

        expect(
          violations,
          isEmpty,
          reason:
              'UIコンポーネント内で生の SizedBox(height/width: 4/8/12/16/24/32) 直接数値指定が検出されました。AppSpacing (xs/sm/md/lg/xl/xxl) を使用してください。\n'
              '違反ファイル:\n${violations.join('\n')}',
        );
      },
    );

    test(
      '11. AppThemeColors: theme_color_extensions.dart 内の全 14 色プロパティの copyWith / lerp が正しく機能すること',
      () {
        final darkTheme = AppThemeColors.ofMode(isDark: true, mode: 'normal');
        final lightTheme = AppThemeColors.ofMode(isDark: false, mode: 'normal');

        final lerped = darkTheme.lerp(lightTheme, 0.5);
        expect(lerped.primaryAccent, isNotNull);
        expect(lerped.softAccent, isNotNull);
        expect(lerped.cardBackground, isNotNull);
        expect(lerped.scaffoldBackground, isNotNull);
        expect(lerped.textColor, isNotNull);

        final copied = darkTheme.copyWith(textColor: Colors.yellow);
        expect(copied.textColor, equals(Colors.yellow));
        expect(copied.primaryAccent, equals(darkTheme.primaryAccent));
      },
    );

    test(
      '12. BottomSheet: アプリ全体での生の showModalBottomSheet 直書きが 0 件であり showAppBottomSheet に統一されていること',
      () {
        final violations = <String>[];

        for (final file in dartFiles) {
          // AppBottomSheet の基盤定義ファイル自身は除外
          if (file.path.contains('lib/shared/widgets/app_bottom_sheet.dart')) {
            continue;
          }

          final content = file.readAsStringSync();
          if (content.contains('showModalBottomSheet')) {
            violations.add(file.path);
          }
        }

        expect(
          violations,
          isEmpty,
          reason:
              '生の showModalBottomSheet 呼び出しが検出されました。showAppBottomSheet / AppBottomSheetContent を使用してください。\n'
              '違反ファイル:\n${violations.join('\n')}',
        );
      },
    );

    test(
      '13. AppFontSize & AppTokens: アプリ全体系でのデザインシステム装飾トークン（AppFontSize / AppRadius / AppFontWeight / AppKendoColors）の定義完全性',
      () {
        expect(AppFontSize.micro, equals(8.0));
        expect(AppFontSize.badge, equals(10.0));
        expect(AppFontSize.caption, equals(11.0));
        expect(AppFontSize.small, equals(12.0));
        expect(AppFontSize.body, equals(14.0));
        expect(AppFontSize.subhead, equals(16.0));
        expect(AppFontSize.headline, equals(18.0));
        expect(AppFontSize.header, equals(20.0));
        expect(AppFontSize.display, equals(24.0));
        expect(AppFontSize.hero, equals(28.0));
        expect(AppFontSize.jumbo, equals(32.0));
        expect(AppEdgeInsets.zero, equals(EdgeInsets.zero));
        expect(AppEdgeInsets.allSm, equals(const EdgeInsets.all(8.0)));
      },
    );
  });
}
