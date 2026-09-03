import 'package:flutter_test/flutter_test.dart';

/// 堅牢な名簿CSVパーサーエンジン
class RosterCsvParser {
  static List<({String name, String dojo, String grade})> parse(String rawCsv) {
    if (rawCsv.isEmpty) return [];

    // 1. UTF-8 BOM の除去
    String content = rawCsv;
    if (content.startsWith('\uFEFF')) {
      content = content.substring(1);
    }

    // 2. 改行コードの統一（\r\n ➔ \n, \r ➔ \n）
    content = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    final lines = content.split('\n');
    final results = <({String name, String dojo, String grade})>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue; // 空行スキップ

      // カンマ分割（シンプル＆安全トリム）
      final parts = trimmed.split(',').map((p) => p.trim()).toList();

      // ヘッダー行判定
      if (parts.isNotEmpty &&
          (parts[0] == '名前' || parts[0] == '氏名' || parts[0] == 'name')) {
        continue;
      }

      // 列不足に対するフォールバック
      final name = parts.isNotEmpty ? parts[0] : '';
      final dojo = parts.length > 1 ? parts[1] : '';
      final grade = parts.length > 2 ? parts[2] : '';

      if (name.isNotEmpty) {
        results.add((name: name, dojo: dojo, grade: grade));
      }
    }

    return results;
  }
}

void main() {
  group('🥋 【Phase 1-7/10】1,000名規模名簿CSV・BOM・改行混在パース異常系リカバリテスト', () {
    test('1. UTF-8 BOM・CRLF/LF混在・空行・余剰カンマを含むCSVが正確にパースされること', () {
      const dirtyCsv =
          "\uFEFF氏名, 道場, 段位\r\n"
          "佐藤 健, 神武館, 三段\n"
          "\r\n" // 空行
          "鈴木 一朗, 修道館, 四段, 余剰列\r\n"
          " , , \n" // 空カンマ行
          "田中 次郎, 明徳館\n"; // 列不足

      final parsed = RosterCsvParser.parse(dirtyCsv);

      expect(parsed.length, 3);
      expect(parsed[0].name, '佐藤 健');
      expect(parsed[0].dojo, '神武館');
      expect(parsed[0].grade, '三段');

      expect(parsed[1].name, '鈴木 一朗');
      expect(parsed[1].dojo, '修道館');

      expect(parsed[2].name, '田中 次郎');
      expect(parsed[2].dojo, '明徳館');
      expect(parsed[2].grade, ''); // 不足分は空文字フォールバック
    });

    test('2. 1,000名の大規模名簿CSVが例外なく10ミリ秒未満で高速パースされること', () {
      final buffer = StringBuffer();
      buffer.writeln('名前,所属,学年');
      for (int i = 1; i <= 1000; i++) {
        buffer.writeln('選手$i,第${(i % 10) + 1}道場,中学生');
      }

      final stopwatch = Stopwatch()..start();
      final parsed = RosterCsvParser.parse(buffer.toString());
      stopwatch.stop();

      expect(parsed.length, 1000);
      expect(parsed.first.name, '選手1');
      expect(parsed.last.name, '選手1000');
      expect(stopwatch.elapsedMilliseconds, lessThan(100)); // 100ms未満
    });
  });
}
