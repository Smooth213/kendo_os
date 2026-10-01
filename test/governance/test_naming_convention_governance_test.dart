import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Governance] 第23条 テスト設計・タイトル命名規約 ＆ テストスイート整合性ガバナンステスト', () {
    // ① 装飾絵文字の検出正規表現
    final emojiRegex = RegExp(
      r'[\u{1F300}-\u{1F9FF}\u{1FA00}-\u{1FAFF}\u{2600}-\u{27BF}\u{2300}-\u{23FF}\u{FE0F}\u{203C}\u{2049}\u{2139}]',
      unicode: true,
    );

    // ② 先頭連番正規表現
    final numberingRegex = RegExp(
      r'^(?:\d+[\.\-:\s]+\s*|\d+-\d+[\.\-:\s]*\s*|[①-⑳]\s*|\[\d+\]\s*|#\d+\s*|Step\s*\d+(?:-\d+)?[:\.\s]*|Phase\s*\d+[:\s\-]*)',
      caseSensitive: false,
    );

    // ③ 「〜べき」および二重語尾
    final bekiRegex = RegExp(r'べき[、。\s]*$');
    final doubleKotoRegex = RegExp(r'(?:ことこと|であることこと|であることであること)');

    // ④ 英語構文タイトル正規表現
    final englishClauseRegex = RegExp(
      r'\b(renders|displays|updates|preserves|handles|resolves|orders|extracts|sorts|calculates|formats|triggers|returns|swaps|applies|expands|contains|creates|deletes|fetches|loads|parses|validates|verifies|verify|should\s+not|should\s+show|when\s+tapped)\b',
      caseSensitive: false,
    );

    // ⑤ 最上位種別タグ正規表現
    final tagRegex = RegExp(
      r'^\[(Unit|Widget|Governance|Golden|E2E|Security)\]',
    );

    final callRegex = RegExp(
      r'''\b(group|test|testWidgets)\s*\(\s*(r?("""|'{3}|"|'))''',
      multiLine: true,
    );

    List<_TestItem> extractTestItems(String content, String filePath) {
      final items = <_TestItem>[];
      var pos = 0;
      while (pos < content.length) {
        final match = callRegex.firstMatch(content.substring(pos));
        if (match == null) break;
        final fnName = match.group(1)!;
        final delim = match.group(3)!;
        final startInSub = match.end;
        final absStart = pos + startInSub;

        var curr = absStart;
        var escaped = false;
        while (curr < content.length) {
          if (delim == '"""' || delim == "'''") {
            if (content.startsWith(delim, curr)) break;
            curr++;
          } else {
            if (escaped) {
              escaped = false;
            } else if (content[curr] == '\\') {
              escaped = true;
            } else if (content[curr] == delim) {
              break;
            }
            curr++;
          }
        }
        if (curr <= content.length) {
          final title = content.substring(absStart, curr);
          items.add(_TestItem(filePath, fnName, title));
          pos = curr + delim.length;
        } else {
          pos = pos + match.end;
        }
      }
      return items;
    }

    List<File> getTestFiles() {
      final dir = Directory('test');
      return dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('_test.dart'))
          .toList();
    }

    test('【①装飾絵文字排除】test配下のすべてのテストおよびグループ名に装飾絵文字が含まれていないこと', () {
      final files = getTestFiles();
      final violations = <String>[];

      for (final f in files) {
        final items = extractTestItems(f.readAsStringSync(), f.path);
        for (final item in items) {
          if (emojiRegex.hasMatch(item.title)) {
            violations.add('${item.filePath}: ${item.fnName}("${item.title}")');
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: '装飾絵文字を含むテスト/グループが存在します:\n${violations.take(10).join('\n')}',
      );
    });

    test('【②連番排除】test配下のすべてのテストタイトルの先頭に連番やナンバリングが存在しないこと', () {
      final files = getTestFiles();
      final violations = <String>[];

      for (final f in files) {
        final items = extractTestItems(f.readAsStringSync(), f.path);
        for (final item in items) {
          if (item.fnName != 'group') {
            final cleanTitle = item.title.trim();
            if (numberingRegex.hasMatch(cleanTitle)) {
              violations.add('${item.filePath}: ${item.fnName}("$cleanTitle")');
            }
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: '先頭にナンバリングを含むテストが存在します:\n${violations.take(10).join('\n')}',
      );
    });

    test('【③文末統一＆文法規約】末尾が「こと」で終わり、「〜べき」や二重語尾が存在しないこと', () {
      final files = getTestFiles();
      final violations = <String>[];

      for (final f in files) {
        final items = extractTestItems(f.readAsStringSync(), f.path);
        for (final item in items) {
          if (item.fnName != 'group') {
            final cleanTitle = item.title.trim();
            if (!cleanTitle.endsWith('こと') ||
                bekiRegex.hasMatch(cleanTitle) ||
                doubleKotoRegex.hasMatch(cleanTitle)) {
              violations.add('${item.filePath}: ${item.fnName}("$cleanTitle")');
            }
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            '文末が「こと」でないか、「〜べき」または二重語尾を含むテストが存在します:\n${violations.take(10).join('\n')}',
      );
    });

    test('【④英文タイトル排除】英文主体のテストタイトルが存在せず日本語に統一されていること', () {
      final files = getTestFiles();
      final violations = <String>[];

      for (final f in files) {
        final items = extractTestItems(f.readAsStringSync(), f.path);
        for (final item in items) {
          if (item.fnName != 'group') {
            final cleanTitle = item.title.trim();
            // ひらがな文字数が5文字未満かつ英語の動詞・述語を含む場合は英文タイトルと判定
            final hiraganaMatches = RegExp(
              r'[\u3040-\u309F]',
            ).allMatches(cleanTitle);
            if (hiraganaMatches.length < 5 &&
                englishClauseRegex.hasMatch(cleanTitle)) {
              violations.add('${item.filePath}: ${item.fnName}("$cleanTitle")');
            }
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: '英文主体のテストタイトルが存在します:\n${violations.take(10).join('\n')}',
      );
    });

    test(
      '【⑤種別タグ】最上位groupが規約タグ([Unit], [Widget], [Governance], [Golden], [E2E], [Security])で始まっていること',
      () {
        final files = getTestFiles();
        final violations = <String>[];

        for (final f in files) {
          final items = extractTestItems(f.readAsStringSync(), f.path);
          final topGroup = items.where((i) => i.fnName == 'group').firstOrNull;
          if (topGroup != null) {
            final cleanTitle = topGroup.title.trim();
            if (!tagRegex.hasMatch(cleanTitle)) {
              violations.add('${topGroup.filePath}: group("$cleanTitle")');
            }
          }
        }

        expect(
          violations,
          isEmpty,
          reason:
              '最上位groupに許可された種別タグが付与されていません:\n${violations.take(10).join('\n')}',
        );
      },
    );
  });
}

class _TestItem {
  final String filePath;
  final String fnName;
  final String title;

  _TestItem(this.filePath, this.fnName, this.title);
}
