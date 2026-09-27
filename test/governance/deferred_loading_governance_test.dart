import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('📦 【ガバナンス第19条】重厚ライブラリ遅延読み込み＆初期バンドル最小化規約テスト', () {
    late List<File> dartFiles;

    setUpAll(() {
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue);

      dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();
    });

    test(
      '1. 【クリティカルUI隔離規約】試合進行・操作画面（lib/features/match/）からPDF・印刷ライブラリが直接インポートされていないこと',
      () {
        final prohibitedPackages = [
          'package:pdf/pdf.dart',
          'package:pdf/widgets.dart',
          'package:printing/printing.dart',
          'package:syncfusion_flutter_pdfviewer/pdfviewer.dart',
        ];

        final matchFiles = dartFiles.where(
          (f) => f.path.replaceAll('\\', '/').contains('/features/match/'),
        );

        final violations = <String>[];

        for (final file in matchFiles) {
          final content = file.readAsStringSync();
          for (final pkg in prohibitedPackages) {
            if (content.contains(pkg)) {
              violations.add('${file.path}: 直接同期インポートを検出 ($pkg)');
            }
          }
        }

        expect(
          violations,
          isEmpty,
          reason:
              '試合操作・進行画面は軽量・即時応答が必須のため、重厚PDFライブラリを直接インポートしてはなりません:\n${violations.join('\n')}',
        );
      },
    );

    test(
      '2. 【観戦ビュアーUI隔離規約】観客用リアルタイム画面（lib/features/viewer/）からPDF・印刷ライブラリが直接インポートされていないこと',
      () {
        final prohibitedPackages = [
          'package:pdf/pdf.dart',
          'package:pdf/widgets.dart',
          'package:printing/printing.dart',
          'package:syncfusion_flutter_pdfviewer/pdfviewer.dart',
        ];

        final viewerFiles = dartFiles.where(
          (f) => f.path.replaceAll('\\', '/').contains('/features/viewer/'),
        );

        final violations = <String>[];

        for (final file in viewerFiles) {
          final content = file.readAsStringSync();
          for (final pkg in prohibitedPackages) {
            if (content.contains(pkg)) {
              violations.add('${file.path}: 直接同期インポートを検出 ($pkg)');
            }
          }
        }

        expect(
          violations,
          isEmpty,
          reason:
              '観客・保護者用ビュアーは初期ロード時間最小化のため、重厚PDFライブラリを直接インポートしてはなりません:\n${violations.join('\n')}',
        );
      },
    );

    test(
      '3. 【PDF機能局所化規約】package:pdf/ は lib/features/pdf/ 配下に厳格にカプセル化されていること',
      () {
        final violations = <String>[];

        for (final file in dartFiles) {
          final path = file.path.replaceAll('\\', '/');
          // lib/features/pdf/ 以外での package:pdf の直接インポートを検出
          if (!path.contains('/features/pdf/')) {
            final content = file.readAsStringSync();
            if (content.contains("import 'package:pdf/")) {
              violations.add(
                '${file.path}: lib/features/pdf/ 外での package:pdf 直接インポート',
              );
            }
          }
        }

        expect(
          violations,
          isEmpty,
          reason:
              'package:pdf は lib/features/pdf/ 配下の専用サービスおよびWidget群にカプセル化されていなければなりません:\n${violations.join('\n')}',
        );
      },
    );
  });
}
