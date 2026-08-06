import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';

void main() {
  group('🛡️ Design System Governance & Direct Usage Prevention Fortress Tests', () {
    test('1. AppTokens Constant Values Integrity Test', () {
      // AppRadius の確実な検証
      expect(AppRadius.smallValue, 8.0);
      expect(AppRadius.mediumValue, 12.0);
      expect(AppRadius.largeValue, 16.0);
      expect(AppRadius.xlargeValue, 24.0);
      expect(AppRadius.fullValue, 999.0);

      expect(AppRadius.small, const BorderRadius.all(Radius.circular(8.0)));
      expect(AppRadius.medium, const BorderRadius.all(Radius.circular(12.0)));
      expect(AppRadius.large, const BorderRadius.all(Radius.circular(16.0)));
      expect(AppRadius.xlarge, const BorderRadius.all(Radius.circular(24.0)));
      expect(AppRadius.full, const BorderRadius.all(Radius.circular(999.0)));

      // AppSpacing の確実な検証
      expect(AppSpacing.xs, 4.0);
      expect(AppSpacing.sm, 8.0);
      expect(AppSpacing.md, 12.0);
      expect(AppSpacing.lg, 16.0);
      expect(AppSpacing.xl, 24.0);
      expect(AppSpacing.xxl, 32.0);

      // AppFontWeight の確実な検証
      expect(AppFontWeight.regular, FontWeight.w400);
      expect(AppFontWeight.semiBold, FontWeight.w600);
      expect(AppFontWeight.bold, FontWeight.w700);
    });

    test(
      '2. Codebase Static Inspection: No direct showModalBottomSheet calls in lib/ (0 occurrences)',
      () {
        final libDir = Directory('lib');
        expect(libDir.existsSync(), isTrue, reason: 'lib directory must exist');

        final violations = <String>[];
        final dartFiles = libDir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'));

        for (final file in dartFiles) {
          // Shared bottom sheet definition widget itself is allowed
          if (file.path.endsWith('app_bottom_sheet.dart')) continue;

          final lines = file.readAsLinesSync();
          for (var i = 0; i < lines.length; i++) {
            final line = lines[i];
            if (line.contains('showModalBottomSheet(') &&
                !line.trim().startsWith('//')) {
              violations.add('${file.path}:${i + 1}: $line');
            }
          }
        }

        expect(
          violations,
          isEmpty,
          reason:
              'Direct showModalBottomSheet calls are strictly forbidden in lib/! Use showAppBottomSheet from app_bottom_sheet.dart instead.\nViolations found:\n${violations.join('\n')}',
        );
      },
    );

    test(
      '3. Codebase Static Inspection: Direct ChoiceChip, FilterChip, ActionChip usage banned outside app_chip.dart',
      () {
        final libDir = Directory('lib');
        final violations = <String>[];
        final dartFiles = libDir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'));

        // Matches ChoiceChip(, FilterChip(, ActionChip( ONLY if not prefixed with 'App'
        final directChipPattern = RegExp(
          r'(?<!App)(ChoiceChip|FilterChip|ActionChip)\(',
        );

        for (final file in dartFiles) {
          if (file.path.endsWith('app_chip.dart')) continue;

          final lines = file.readAsLinesSync();
          for (var i = 0; i < lines.length; i++) {
            final line = lines[i];
            final trimmed = line.trim();
            if (trimmed.startsWith('//')) continue;

            if (directChipPattern.hasMatch(line)) {
              violations.add('${file.path}:${i + 1}: $line');
            }
          }
        }

        expect(
          violations,
          isEmpty,
          reason:
              'Direct Material Chip instantiation is strictly forbidden! Use AppChoiceChip, AppFilterChip, or AppActionChip from app_chip.dart.\nViolations found:\n${violations.join('\n')}',
        );
      },
    );

    testWidgets('4. AppHeader Widget Rendering & Theme Token Compliance', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
          ),
          home: const Scaffold(appBar: AppHeader(title: 'デザインガバナンスヘッダー')),
        ),
      );

      expect(find.text('デザインガバナンスヘッダー'), findsOneWidget);
      final appBarFinder = find.byType(AppBar);
      expect(appBarFinder, findsOneWidget);

      final AppBar appBar = tester.widget<AppBar>(appBarFinder);
      expect(appBar.elevation, 0.0);
    });

    testWidgets('5. Unified AppChip Widgets Rendering & Radius Test', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: Column(
              children: [
                AppChoiceChip(
                  label: const Text('Choice Test'),
                  selected: true,
                  onSelected: (_) {},
                ),
                AppFilterChip(
                  label: const Text('Filter Test'),
                  selected: false,
                  onSelected: (_) {},
                ),
                AppActionChip(
                  label: const Text('Action Test'),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Choice Test'), findsOneWidget);
      expect(find.text('Filter Test'), findsOneWidget);
      expect(find.text('Action Test'), findsOneWidget);

      // Raw Material Chips embedded inside wrapper widgets must exist
      expect(find.byType(ChoiceChip), findsOneWidget);
      expect(find.byType(FilterChip), findsOneWidget);
      expect(find.byType(ActionChip), findsOneWidget);
    });

    testWidgets('6. Unified AppDialog Widget Rendering & Corner Radius Test', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const Scaffold(
            body: AppDialog(title: 'ダイアログテスト', content: Text('コンテンツダイアログ')),
          ),
        ),
      );

      expect(find.text('ダイアログテスト'), findsOneWidget);
      expect(find.text('コンテンツダイアログ'), findsOneWidget);

      final alertDialogFinder = find.byType(AlertDialog);
      expect(alertDialogFinder, findsOneWidget);

      final AlertDialog dialog = tester.widget<AlertDialog>(alertDialogFinder);
      expect(dialog.shape, isA<RoundedRectangleBorder>());
      final shape = dialog.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(16));
    });
  });
}
