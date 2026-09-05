import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('🔍 マニュアル検索・クエリ機能テスト (Manual Search & Query Tests)', () {
    const indexPath =
        'packages/documentation_runtime/manuals/manual_search_index.json';
    late List<dynamic> searchIndex;

    setUpAll(() {
      final file = File(indexPath);
      searchIndex = jsonDecode(file.readAsStringSync()) as List<dynamic>;
    });

    List<dynamic> performSearch(String query) {
      final q = query.toLowerCase();
      return searchIndex.where((item) {
        final title = (item['title'] as String? ?? '').toLowerCase();
        final headings = ((item['headings'] as List<dynamic>?) ?? [])
            .map((e) => e.toString().toLowerCase())
            .join(' ');
        final tags = ((item['tags'] as List<dynamic>?) ?? [])
            .map((e) => e.toString().toLowerCase())
            .join(' ');
        return title.contains(q) || headings.contains(q) || tags.contains(q);
      }).toList();
    }

    test('1. 「ドック」検索でドック操作ガイドが最上位または上位にヒットすること', () {
      final results = performSearch('ドック');
      expect(results, isNotEmpty);

      final paths = results.map((r) => r['path'] as String).toList();
      expect(
        paths.any((p) => p.contains('dock_guide.md')),
        isTrue,
        reason: 'ドック操作ガイドがヒットしませんでした',
      );
    });

    test('2. 「ルール」検索で独立ルール設定および一括ルール編集がヒットすること', () {
      final results = performSearch('ルール');
      expect(results, isNotEmpty);

      final paths = results.map((r) => r['path'] as String).toList();
      expect(
        paths.any((p) => p.contains('category_rules.md')),
        isTrue,
        reason: '部門ルール設定マニュアルがヒットしませんでした',
      );
      expect(
        paths.any((p) => p.contains('bulk_rule_edit.md')),
        isTrue,
        reason: '一括ルール編集マニュアルがヒットしませんでした',
      );
    });

    test('3. 「チーム」検索でチーム試合状況マニュアル（Operate/Viewer）がヒットすること', () {
      final results = performSearch('チーム');
      expect(results, isNotEmpty);

      final paths = results.map((r) => r['path'] as String).toList();
      expect(paths.any((p) => p.contains('team_match_status.md')), isTrue);
      expect(
        paths.any((p) => p.contains('viewer_team_match_status.md')),
        isTrue,
      );
    });

    test('4. 「Undo」または「取り消し」検索で試合記録マニュアルやクイックシートがヒットすること', () {
      final resultsUndo = performSearch('undo');
      final resultsCancel = performSearch('取り消し');

      final combinedPaths = {
        ...resultsUndo,
        ...resultsCancel,
      }.map((r) => r['path'] as String).toSet();

      expect(combinedPaths.any((p) => p.contains('match.md')), isTrue);
      expect(
        combinedPaths.any((p) => p.contains('operator_1pager.md')),
        isTrue,
      );
    });

    test('5. 「部内戦」検索で運営マニュアルと閲覧マニュアルが両方ヒットすること', () {
      final results = performSearch('部内戦');
      expect(results, isNotEmpty);

      final paths = results.map((r) => r['path'] as String).toList();
      expect(paths.any((p) => p.contains('operator/bunaiksen.md')), isTrue);
      expect(
        paths.any((p) => p.contains('viewer/viewer_bunaiksen.md')),
        isTrue,
      );
    });

    test('6. 「進級」検索で選手マスタ管理（新年度一括進級）マニュアルがヒットすること', () {
      final results = performSearch('進級');
      expect(results, isNotEmpty);

      final paths = results.map((r) => r['path'] as String).toList();
      expect(
        paths.any((p) => p.contains('master_management.md')),
        isTrue,
        reason: '選手マスタ管理・進級マニュアルがヒットしませんでした',
      );
    });

    test('7. 「サンシャイン」または「サーマル」検索で設定マニュアルがヒットすること', () {
      final resultsSunshine = performSearch('サンシャイン');
      final resultsThermal = performSearch('サーマル');

      final combined = {
        ...resultsSunshine,
        ...resultsThermal,
      }.map((r) => r['path'] as String).toSet();

      expect(
        combined.any((p) => p.contains('settings.md')),
        isTrue,
        reason: 'サンシャイン/サーマル冷却対応の設定マニュアルがヒットしませんでした',
      );
    });

    test('8. 「プログラム」検索で大会プログラムマニュアルがヒットすること', () {
      final results = performSearch('プログラム');
      expect(results, isNotEmpty);

      final paths = results.map((r) => r['path'] as String).toList();
      expect(paths.any((p) => p.contains('program_management.md')), isTrue);
      expect(paths.any((p) => p.contains('viewer_program.md')), isTrue);
    });

    test('9. 「PDF」または「公式記録」検索で記録出力マニュアルがヒットすること', () {
      final results = performSearch('pdf');
      expect(results, isNotEmpty);

      final paths = results.map((r) => r['path'] as String).toList();
      expect(paths.any((p) => p.contains('official_record.md')), isTrue);
    });
  });
}
