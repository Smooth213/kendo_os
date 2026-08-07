// ignore_for_file: avoid_print

import 'dart:io';

/// kendo OS デザインシステム一括自動補正スクリプト
/// 実行方法: `dart scripts/design_system_autofix.dart <mode>`
void main(List<String> args) {
  if (args.isEmpty) {
    print('使用方法: dart scripts/design_system_autofix.dart <mode>');
    print('利用可能なモード: font_weight, radius, spacing, dialog');
    exit(1);
  }

  final mode = args.first;
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    print('エラー: lib ディレクトリが見つかりません。');
    exit(1);
  }

  final files = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  int totalReplacements = 0;

  for (final file in files) {
    // テーマ・トークン基盤ファイル自体および PDF 生成モジュールはスキップ
    if (file.path.contains('lib/shared/theme/app_tokens.dart') ||
        file.path.contains('lib/shared/theme/theme_color_extensions.dart') ||
        file.path.contains('lib/features/pdf/')) {
      continue;
    }

    var content = file.readAsStringSync();
    final original = content;

    if (mode == 'font_weight') {
      content = content.replaceAll('FontWeight.w400', 'AppFontWeight.regular');
      content = content.replaceAll('FontWeight.w600', 'AppFontWeight.semiBold');
      content = content.replaceAll('FontWeight.w700', 'AppFontWeight.bold');
      content = content.replaceAll(
        RegExp(r'(?<!App)FontWeight\.bold'),
        'AppFontWeight.bold',
      );
      content = content.replaceAll('AppAppFontWeight', 'AppFontWeight');
    } else if (mode == 'radius') {
      content = content.replaceAll(
        'BorderRadius.circular(8)',
        'AppRadius.small',
      );
      content = content.replaceAll(
        'BorderRadius.circular(8.0)',
        'AppRadius.small',
      );
      content = content.replaceAll(
        'BorderRadius.circular(12)',
        'AppRadius.medium',
      );
      content = content.replaceAll(
        'BorderRadius.circular(12.0)',
        'AppRadius.medium',
      );
      content = content.replaceAll(
        'BorderRadius.circular(16)',
        'AppRadius.large',
      );
      content = content.replaceAll(
        'BorderRadius.circular(16.0)',
        'AppRadius.large',
      );
      content = content.replaceAll(
        'BorderRadius.circular(24)',
        'AppRadius.xlarge',
      );
      content = content.replaceAll(
        'BorderRadius.circular(24.0)',
        'AppRadius.xlarge',
      );
    } else if (mode == 'spacing') {
      content = content.replaceAll(
        'SizedBox(height: 4)',
        'SizedBox(height: AppSpacing.xs)',
      );
      content = content.replaceAll(
        'SizedBox(height: 4.0)',
        'SizedBox(height: AppSpacing.xs)',
      );
      content = content.replaceAll(
        'SizedBox(width: 4)',
        'SizedBox(width: AppSpacing.xs)',
      );
      content = content.replaceAll(
        'SizedBox(width: 4.0)',
        'SizedBox(width: AppSpacing.xs)',
      );
      content = content.replaceAll(
        'SizedBox(height: 8)',
        'SizedBox(height: AppSpacing.sm)',
      );
      content = content.replaceAll(
        'SizedBox(height: 8.0)',
        'SizedBox(height: AppSpacing.sm)',
      );
      content = content.replaceAll(
        'SizedBox(width: 8)',
        'SizedBox(width: AppSpacing.sm)',
      );
      content = content.replaceAll(
        'SizedBox(width: 8.0)',
        'SizedBox(width: AppSpacing.sm)',
      );
      content = content.replaceAll(
        'SizedBox(height: 12)',
        'SizedBox(height: AppSpacing.md)',
      );
      content = content.replaceAll(
        'SizedBox(height: 12.0)',
        'SizedBox(height: AppSpacing.md)',
      );
      content = content.replaceAll(
        'SizedBox(width: 12)',
        'SizedBox(width: AppSpacing.md)',
      );
      content = content.replaceAll(
        'SizedBox(width: 12.0)',
        'SizedBox(width: AppSpacing.md)',
      );
      content = content.replaceAll(
        'SizedBox(height: 16)',
        'SizedBox(height: AppSpacing.lg)',
      );
      content = content.replaceAll(
        'SizedBox(height: 16.0)',
        'SizedBox(height: AppSpacing.lg)',
      );
      content = content.replaceAll(
        'SizedBox(width: 16)',
        'SizedBox(width: AppSpacing.lg)',
      );
      content = content.replaceAll(
        'SizedBox(width: 16.0)',
        'SizedBox(width: AppSpacing.lg)',
      );
      content = content.replaceAll(
        'SizedBox(height: 24)',
        'SizedBox(height: AppSpacing.xl)',
      );
      content = content.replaceAll(
        'SizedBox(height: 24.0)',
        'SizedBox(height: AppSpacing.xl)',
      );
      content = content.replaceAll(
        'SizedBox(width: 24)',
        'SizedBox(width: AppSpacing.xl)',
      );
      content = content.replaceAll(
        'SizedBox(width: 24.0)',
        'SizedBox(width: AppSpacing.xl)',
      );
      content = content.replaceAll(
        'SizedBox(height: 32)',
        'SizedBox(height: AppSpacing.xxl)',
      );
      content = content.replaceAll(
        'SizedBox(height: 32.0)',
        'SizedBox(height: AppSpacing.xxl)',
      );
      content = content.replaceAll(
        'SizedBox(width: 32)',
        'SizedBox(width: AppSpacing.xxl)',
      );
      content = content.replaceAll(
        'SizedBox(width: 32.0)',
        'SizedBox(width: AppSpacing.xxl)',
      );

      content = content.replaceAll(
        'EdgeInsets.all(4)',
        'EdgeInsets.all(AppSpacing.xs)',
      );
      content = content.replaceAll(
        'EdgeInsets.all(4.0)',
        'EdgeInsets.all(AppSpacing.xs)',
      );
      content = content.replaceAll(
        'EdgeInsets.all(8)',
        'EdgeInsets.all(AppSpacing.sm)',
      );
      content = content.replaceAll(
        'EdgeInsets.all(8.0)',
        'EdgeInsets.all(AppSpacing.sm)',
      );
      content = content.replaceAll(
        'EdgeInsets.all(12)',
        'EdgeInsets.all(AppSpacing.md)',
      );
      content = content.replaceAll(
        'EdgeInsets.all(12.0)',
        'EdgeInsets.all(AppSpacing.md)',
      );
      content = content.replaceAll(
        'EdgeInsets.all(16)',
        'EdgeInsets.all(AppSpacing.lg)',
      );
      content = content.replaceAll(
        'EdgeInsets.all(16.0)',
        'EdgeInsets.all(AppSpacing.lg)',
      );
      content = content.replaceAll(
        'EdgeInsets.all(24)',
        'EdgeInsets.all(AppSpacing.xl)',
      );
      content = content.replaceAll(
        'EdgeInsets.all(24.0)',
        'EdgeInsets.all(AppSpacing.xl)',
      );
      content = content.replaceAll(
        'EdgeInsets.all(32)',
        'EdgeInsets.all(AppSpacing.xxl)',
      );
      content = content.replaceAll(
        'EdgeInsets.all(32.0)',
        'EdgeInsets.all(AppSpacing.xxl)',
      );
    }

    if (content != original) {
      // app_tokens.dart のインポートを追加が必要な場合
      if (!content.contains(
            "import 'package:kendo_os/shared/theme/app_tokens.dart';",
          ) &&
          !content.contains('package:kendo_os/shared/theme/app_tokens.dart')) {
        content =
            "import 'package:kendo_os/shared/theme/app_tokens.dart';\n$content";
      }
      file.writeAsStringSync(content);
      totalReplacements++;
      print('置換完了: ${file.path}');
    }
  }

  print('\n✅ [$mode] の自動置換が完了しました。修正対象ファイル数: $totalReplacements');
}
