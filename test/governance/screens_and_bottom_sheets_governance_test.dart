import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

// ============================================================================
// 🛡️ kendo OS 全画面・全ドック・全ボトムシート 横断網羅ガバナンス監査テスト
// 新規画面、新規ドック機能、新規ボトムシート追加時の設計思想・安全規約・
// メモリ解放・トークン規約・ロール隔離の抜け漏れを恒久的にゼロ保証します。
// ============================================================================
void main() {
  group('🛡️ 全画面・全ドック・全ボトムシート 横断網羅ガバナンス監査', () {
    late Directory libDir;
    late List<File> dartFiles;
    late List<File> screenFiles;
    late List<File> sheetFiles;
    late List<File> dockFiles;

    setUpAll(() {
      libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue, reason: 'lib ディレクトリが存在すること');

      dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where(
            (f) =>
                !f.path.endsWith('.freezed.dart') &&
                !f.path.endsWith('.g.dart'),
          )
          .toList();

      screenFiles = dartFiles
          .where(
            (f) =>
                f.path.contains('/screens/') || f.path.endsWith('_screen.dart'),
          )
          .toList();

      sheetFiles = dartFiles
          .where(
            (f) =>
                f.path.contains('_sheet') ||
                f.path.contains('_bottom_sheet') ||
                f.path.contains('/sheets/'),
          )
          .toList();

      dockFiles = dartFiles
          .where(
            (f) =>
                f.path.contains('dock') ||
                f.path.contains('FloatingProgramDock') ||
                f.path.contains('BunaiksenDock'),
          )
          .toList();
    });

    // -------------------------------------------------------------------------
    // 1. 全画面（Screens）横断ガバナンス規約
    // -------------------------------------------------------------------------
    test('1. 全画面: 生の AppBar 直書きが 0 件であり AppHeader または専用ヘッダーに統一されていること', () {
      final violations = <String>[];
      for (final file in screenFiles) {
        if (file.path.endsWith('app_header.dart')) continue;
        final content = file.readAsStringSync();
        if (RegExp(r'\bAppBar\s*\(').hasMatch(content)) {
          violations.add(file.path);
        }
      }
      expect(
        violations,
        isEmpty,
        reason:
            '画面内で生の AppBar が検出されました。AppHeader を使用してください:\n${violations.join('\n')}',
      );
    });

    test(
      '2. 全画面: レガシー戻るアイコン（arrow_back）が 0 件であり arrow_back_ios_new に統一されていること',
      () {
        final violations = <String>[];
        for (final file in screenFiles) {
          final content = file.readAsStringSync();
          if (RegExp(
            r'Icons\.arrow_back(?!\w|_ios_new)\b|Icons\.arrow_back_ios\b(?!_new)',
          ).hasMatch(content)) {
            violations.add(file.path);
          }
        }
        expect(
          violations,
          isEmpty,
          reason:
              '画面内でレガシー戻るアイコンが検出されました。Icons.arrow_back_ios_new に統一してください:\n${violations.join('\n')}',
        );
      },
    );

    test('3. 全画面: Scaffold 背景色に硬直色 (Colors.*) が直接指定されていないこと', () {
      final violations = <String>[];
      for (final file in screenFiles) {
        final content = file.readAsStringSync();
        final match = RegExp(
          r'Scaffold\s*\([^)]*backgroundColor\s*:\s*Colors\.[a-zA-Z]+',
          dotAll: true,
        ).firstMatch(content);
        if (match != null) {
          violations.add('${file.path}: ${match.group(0)}');
        }
      }
      expect(
        violations,
        isEmpty,
        reason:
            'Scaffold の背景色に Colors.* が直書きされています。context.appColors.scaffoldBackground を使用してください:\n${violations.join('\n')}',
      );
    });

    // -------------------------------------------------------------------------
    // 2. 全ボトムシート（BottomSheets）横断ガバナンス規約
    // -------------------------------------------------------------------------
    test(
      '4. 全ボトムシート: TextEditingController を生成する StatefulWidget は必ず dispose() で破棄していること',
      () {
        final violations = <String>[];
        for (final file in sheetFiles) {
          final content = file.readAsStringSync();
          if (content.contains('TextEditingController') &&
              content.contains('StatefulWidget')) {
            if (!content.contains('.dispose()') &&
                !content.contains('dispose()')) {
              violations.add(file.path);
            }
          }
        }
        expect(
          violations,
          isEmpty,
          reason:
              'ボトムシート内で TextEditingController の dispose() 漏れが検出されました:\n${violations.join('\n')}',
        );
      },
    );

    test(
      '5. 全ボトムシート: 生の showModalBottomSheet の直書きが 0 件であり showAppBottomSheet に統一されていること',
      () {
        final violations = <String>[];
        for (final file in sheetFiles) {
          if (file.path.contains('app_bottom_sheet.dart')) continue;
          final content = file.readAsStringSync();
          if (content.contains('showModalBottomSheet(')) {
            violations.add(file.path);
          }
        }
        expect(
          violations,
          isEmpty,
          reason:
              'ボトムシート内で生の showModalBottomSheet 呼び出しが検出されました:\n${violations.join('\n')}',
        );
      },
    );

    test(
      '6. 全ボトムシート: 生の showDialog / AlertDialog 直書きが 0 件であり AppDialog に統一されていること',
      () {
        final violations = <String>[];
        for (final file in sheetFiles) {
          if (file.path.contains('app_dialog.dart')) continue;
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
              'ボトムシート内で生の showDialog / AlertDialog が検出されました:\n${violations.join('\n')}',
        );
      },
    );

    test('7. 全ボトムシート: 硬直色 Colors.* 直書きが 0 件であること', () {
      final violations = <String>[];
      for (final file in sheetFiles) {
        final content = file.readAsStringSync();
        final cleanCode = content
            .split('\n')
            .where((line) => !line.trim().startsWith('//'))
            .join('\n');
        final matches = RegExp(
          r'(?<!\.)\bColors\.(white|black|grey|red|blue|amber|orange|purple|deepPurple|indigo|teal|green|yellow|brown|pink|cyan|lime)\b',
        ).allMatches(cleanCode);
        if (matches.isNotEmpty) {
          violations.add('${file.path} (${matches.length}件)');
        }
      }
      expect(
        violations,
        isEmpty,
        reason:
            'ボトムシート内で硬直色 Colors.* が検出されました。context.appColors または AppKendoColors を使用してください:\n${violations.join('\n')}',
      );
    });

    // -------------------------------------------------------------------------
    // 3. ドック（Floating Docks）機能横断ガバナンス規約
    // -------------------------------------------------------------------------
    test('8. 全ドック機能: 観戦（Viewer）配下でドック関連コンポーネントが一切参照・配置されていないこと', () {
      final viewerFiles = dartFiles
          .where((f) => f.path.contains('/features/viewer/'))
          .toList();
      final violations = <String>[];
      for (final file in viewerFiles) {
        final content = file.readAsStringSync();
        if (content.contains('FloatingProgramDockButton') ||
            content.contains('BunaiksenDockButton') ||
            content.contains('FloatingDockSheetManager')) {
          violations.add(file.path);
        }
      }
      expect(
        violations,
        isEmpty,
        reason:
            'Viewer 画面配下でドック機能の呼び出しが検出されました。観客画面でのドック表示は禁止されています:\n${violations.join('\n')}',
      );
    });

    test('9. 全ドック機能: 部内戦ドック（BunaiksenDockButton）が通常大会画面から隔離されていること', () {
      final normalOperateFiles = dartFiles
          .where(
            (f) =>
                f.path.contains('/features/tournament/presentation/operate/'),
          )
          .where(
            (f) =>
                !f.path.contains('bunaiksen') &&
                !f.path.endsWith('match_floating_dock_entry.dart'),
          )
          .toList();
      final violations = <String>[];
      for (final file in normalOperateFiles) {
        final content = file.readAsStringSync();
        if (content.contains('BunaiksenDockButton')) {
          violations.add(file.path);
        }
      }
      expect(
        violations,
        isEmpty,
        reason:
            '通常大会運営画面で部内戦ドックが参照されています。完全隔離規約違反です:\n${violations.join('\n')}',
      );
    });

    test('10. 全ファイル行数: 画面・ドック・ボトムシートのすべてのファイルが500行制限を厳格に順守していること', () {
      final allUiFiles = {...screenFiles, ...sheetFiles, ...dockFiles}.toList();
      final violations = <String>[];
      for (final file in allUiFiles) {
        final lines = file.readAsLinesSync().length;
        if (lines > 500) {
          violations.add('${file.path}: $lines 行 (上限 500行)');
        }
      }
      expect(
        violations,
        isEmpty,
        reason:
            'UIファイルで行数制限 (500行) を超過しているファイルが検出されました:\n${violations.join('\n')}',
      );
    });
  });
}
