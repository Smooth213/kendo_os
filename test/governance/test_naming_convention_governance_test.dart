import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Governance] 第23条 テスト設計・タイトル命名規約 ＆ テストスイート整合性ガバナンステスト', () {
    // ① 装飾絵文字の検出正規表現（ドメイン記号 ◯△▲㋙℃、外字 𠮷髙﨑德 等は除外）
    final emojiRegex = RegExp(
      r'[\u{1F300}-\u{1F9FF}\u{1FA00}-\u{1FAFF}\u{2600}-\u{27BF}\u{2300}-\u{23FF}\u{FE0F}\u{203C}\u{2049}\u{2139}]',
      unicode: true,
    );
    const allowedSpecialChars = '◯△▲㋙℃𠮷髙﨑德';

    // ② 先頭連番・ナンバリング正規表現
    final numberingRegex = RegExp(
      r'(?:^\s*\d+[\.\-:\s]+\s*|^\s*[①-⑳]\s*|^\s*\[\d+\]\s*|^\s*#\d+\s*|\bPhase\s*[\d\.\-\/]+|\bStep\s*[\d\.\-\/]+|&\s*\d+[\-\.]\d+|\bRule\s*\d+[:\s\-]|\bPart\s*\d+[:\s\-]|\bNo\.\s*\d+)',
      caseSensitive: false,
    );

    // ③ 括弧検出
    final tagRegex = RegExp(
      r'^\[(Unit|Widget|Governance|Golden|E2E|Security)\]',
    );

    // ④ 文末表現正規表現
    final doubleKotoRegex = RegExp(r'(?:ことこと|であることこと|ことであること)$');
    final bracketKotoRegex = RegExp(r'[\)）]こと$');

    // ⑤ 英語構文タイトル正規表現
    final englishClauseRegex = RegExp(
      r'\b(renders|displays|updates|preserves|handles|resolves|orders|extracts|sorts|calculates|formats|triggers|returns|swaps|applies|expands|contains|creates|deletes|fetches|loads|parses|validates|verifies|verify|should|when\s+tapped|initial\s+state|default\s+state|can\s+be|fails\s+to|throws|emits)\b',
      caseSensitive: false,
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

    test('装飾絵文字排除規約において test配下のすべてのテストおよびグループ名に装飾絵文字が含まれていないこと', () {
      final files = getTestFiles();
      final violations = <String>[];

      for (final f in files) {
        final items = extractTestItems(f.readAsStringSync(), f.path);
        for (final item in items) {
          final badEmojis = item.title.runes
              .map(String.fromCharCode)
              .where(
                (c) =>
                    emojiRegex.hasMatch(c) && !allowedSpecialChars.contains(c),
              )
              .toList();
          if (badEmojis.isNotEmpty) {
            violations.add(
              '${item.filePath}: ${item.fnName}("${item.title}") -> $badEmojis',
            );
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: '装飾絵文字を含むテスト/グループが存在します:\n${violations.take(10).join('\n')}',
      );
    });

    test('テスト連番排除規約において test配下のすべてのテストタイトルの先頭に連番やナンバリングが存在しないこと', () {
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

    test('括弧排除規約において 最上位種別タグ以外の隅付き括弧および角括弧が完全に排除されていること', () {
      final files = getTestFiles();
      final violations = <String>[];

      for (final f in files) {
        final items = extractTestItems(f.readAsStringSync(), f.path);
        var hasTopGroup = false;
        for (final item in items) {
          final cleanTitle = item.title.trim();
          var isTopGroup = false;
          if (item.fnName == 'group' && !hasTopGroup) {
            hasTopGroup = true;
            isTopGroup = true;
          }

          // 【】はグループ・テスト問わず完全禁止
          if (cleanTitle.contains('【') || cleanTitle.contains('】')) {
            violations.add(
              '${item.filePath}: ${item.fnName}("$cleanTitle") -> contains 【】',
            );
            continue;
          }

          // [] のチェック
          if (item.fnName != 'group') {
            if (cleanTitle.contains('[') || cleanTitle.contains(']')) {
              violations.add(
                '${item.filePath}: ${item.fnName}("$cleanTitle") -> contains []',
              );
            }
          } else {
            if (isTopGroup) {
              final withoutTag = cleanTitle.replaceFirst(tagRegex, '').trim();
              if (withoutTag.contains('[') || withoutTag.contains(']')) {
                violations.add(
                  '${item.filePath}: group("$cleanTitle") -> contains internal []',
                );
              }
            } else {
              if (cleanTitle.contains('[') || cleanTitle.contains(']')) {
                violations.add(
                  '${item.filePath}: sub-group("$cleanTitle") -> contains []',
                );
              }
            }
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            '最上位種別タグ以外の【】または[]を含むテストが存在します:\n${violations.take(10).join('\n')}',
      );
    });

    test('文末統一＆文法規約において 末尾が「こと」で終わり、「〜べき」や二重語尾が存在しないこと', () {
      final files = getTestFiles();
      final violations = <String>[];

      for (final f in files) {
        final items = extractTestItems(f.readAsStringSync(), f.path);
        for (final item in items) {
          if (item.fnName != 'group') {
            final cleanTitle = item.title.trim();
            final cleanedForBeki = cleanTitle
                .replaceAll('べき等', '')
                .replaceAll('「〜べき」', '');
            if (!cleanTitle.endsWith('こと') ||
                cleanedForBeki.contains('べき') ||
                doubleKotoRegex.hasMatch(cleanTitle) ||
                bracketKotoRegex.hasMatch(cleanTitle)) {
              violations.add('${item.filePath}: ${item.fnName}("$cleanTitle")');
            }
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            '文末が「こと」でないか、「〜べき」、二重語尾、または括弧直後の「こと」を含むテストが存在します:\n${violations.take(10).join('\n')}',
      );
    });

    test('英文タイトル排除規約において 英文主体のテストタイトルが存在せず日本語に統一されていること', () {
      final files = getTestFiles();
      final violations = <String>[];

      for (final f in files) {
        final items = extractTestItems(f.readAsStringSync(), f.path);
        for (final item in items) {
          if (item.fnName != 'group') {
            final cleanTitle = item.title.trim();
            final hiraganaMatches = RegExp(
              r'[\u3040-\u309F]',
            ).allMatches(cleanTitle);
            if ((hiraganaMatches.length < 6 &&
                    englishClauseRegex.hasMatch(cleanTitle)) ||
                cleanTitle.startsWith('should') ||
                cleanTitle.startsWith('can ') ||
                cleanTitle.startsWith('renders') ||
                cleanTitle.startsWith('verify')) {
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
      'テスト種別タグ規約において 最上位groupが規約タグ（Unit・Widget・Governance・Golden・E2E・Security）で始まっていること',
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
              '最上位groupが規約タグで始まっていないファイルが存在します:\n${violations.take(10).join('\n')}',
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
