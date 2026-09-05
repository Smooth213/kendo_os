import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('🛡️ マニュアル完全性＆整合性テスト (Manual Integrity Tests)', () {
    const manualsBasePath = 'packages/documentation_runtime/manuals';
    final indexFile = File('$manualsBasePath/manual_search_index.json');

    test('1. manual_search_index.json が存在し、正しいJSON形式でパースできること', () {
      expect(
        indexFile.existsSync(),
        isTrue,
        reason: 'manual_search_index.json が存在しません',
      );

      final content = indexFile.readAsStringSync();
      final dynamic decoded = jsonDecode(content);

      expect(decoded, isA<List<dynamic>>(), reason: 'インデックスはリスト形式である必要があります');
      final list = decoded as List<dynamic>;
      expect(
        list.length,
        greaterThanOrEqualTo(30),
        reason: 'インデックス項目が少なすぎます（新機能マニュアルが含まれていない可能性）',
      );
    });

    test('2. インデックス内の全エントリに対応するMarkdownファイルが実在すること（デッドパス防止）', () {
      final list = jsonDecode(indexFile.readAsStringSync()) as List<dynamic>;

      for (final entry in list) {
        final path = entry['path'] as String?;
        expect(path, isNotNull);
        final file = File(path!);
        expect(
          file.existsSync(),
          isTrue,
          reason: 'インデックスに記載されたファイルが存在しません: $path',
        );

        // 必須フィールドの検証
        final title = entry['title'] as String?;
        expect(title, isNotNull);
        expect(title, isNot('無題'));
        expect(title!.trim(), isNotEmpty);

        final headings = entry['headings'] as List<dynamic>?;
        expect(headings, isNotNull);

        final tags = entry['tags'] as List<dynamic>?;
        expect(tags, isNotNull);

        final sortOrder = entry['sort_order'] as int?;
        expect(sortOrder, isNotNull);
        expect(sortOrder! > 0, isTrue);

        final lastUpdated = entry['last_updated'] as String?;
        expect(lastUpdated, isNotNull);
        expect(
          DateTime.tryParse(lastUpdated!),
          isNotNull,
          reason: 'last_updated が正しいISOフォーマットではありません: $lastUpdated',
        );
      }
    });

    test('3. 全主要カテゴリのMarkdownファイルが漏れなくインデックスに登録されていること', () {
      final list = jsonDecode(indexFile.readAsStringSync()) as List<dynamic>;
      final indexedPaths = list.map((e) => e['path'] as String).toSet();

      final categories = [
        'quickstart',
        'recovery',
        'operator',
        'viewer',
        'faq',
      ];

      for (final cat in categories) {
        final dir = Directory('$manualsBasePath/$cat');
        if (!dir.existsSync()) continue;

        final mdFiles = dir.listSync().whereType<File>().where(
          (f) => f.path.endsWith('.md'),
        );

        for (final mdFile in mdFiles) {
          final normalizedPath = mdFile.path.replaceAll('\\', '/');
          expect(
            indexedPaths.contains(normalizedPath),
            isTrue,
            reason:
                'マニュアルファイルが manual_search_index.json に登録されていません: $normalizedPath',
          );
        }
      }
    });

    test('4. 全マニュアルファイルが500行制限を守り、空でないこと（憲法遵守）', () {
      final dir = Directory(manualsBasePath);
      final allMdFiles = dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.md'));

      for (final file in allMdFiles) {
        final lines = file.readAsLinesSync();
        expect(
          lines.isNotEmpty,
          isTrue,
          reason: '空のマニュアルファイルが存在します: ${file.path}',
        );
        expect(
          lines.length,
          lessThanOrEqualTo(500),
          reason: '1ファイル500行上限を超過しています (${lines.length}行): ${file.path}',
        );
      }
    });

    test('5. 本番マニュアル内の相対Markdownリンクがすべて実在すること（リンク切れ防止）', () {
      final categories = [
        'quickstart',
        'recovery',
        'operator',
        'viewer',
        'faq',
      ];
      final linkRegex = RegExp(r'\[([^\]]+)\]\(([^)]+)\)');

      for (final cat in categories) {
        final dir = Directory('$manualsBasePath/$cat');
        if (!dir.existsSync()) continue;

        final mdFiles = dir.listSync().whereType<File>().where(
          (f) => f.path.endsWith('.md'),
        );

        for (final file in mdFiles) {
          final content = file.readAsStringSync();
          final matches = linkRegex.allMatches(content);

          for (final m in matches) {
            final link = m.group(2) ?? '';
            // 外部リンクやアンカーのみのリンクはスキップ
            if (link.startsWith('http://') ||
                link.startsWith('https://') ||
                link.startsWith('#') ||
                link.startsWith('mailto:')) {
              continue;
            }

            // アンカー (#...) の除去
            final cleanLink = link.split('#').first;
            if (cleanLink.isEmpty) continue;

            // 相対パスの解決
            final parentDir = file.parent.path;
            final targetFile = File(Directory('$parentDir/$cleanLink').path);

            expect(
              targetFile.existsSync(),
              isTrue,
              reason:
                  'リンク切れ（デッドリンク）を検出しました: ${file.path} 内の [$link] -> 解決先: ${targetFile.path}',
            );
          }
        }
      }
    });

    test('6. 本番マニュアル内で非推奨語句（スコアラー等）が使用されていないこと（憲法遵守）', () {
      final categories = [
        'quickstart',
        'recovery',
        'operator',
        'viewer',
        'faq',
      ];
      // ドキュメント憲法で禁止されている非推奨語句
      const forbiddenTerms = ['スコアラー'];

      for (final cat in categories) {
        final dir = Directory('$manualsBasePath/$cat');
        if (!dir.existsSync()) continue;

        final mdFiles = dir.listSync().whereType<File>().where(
          (f) => f.path.endsWith('.md'),
        );

        for (final file in mdFiles) {
          final content = file.readAsStringSync();
          for (final term in forbiddenTerms) {
            expect(
              content.contains(term),
              isFalse,
              reason: '非推奨用語「$term」が使用されています（「記録係」等に統一してください）: ${file.path}',
            );
          }
        }
      }
    });
  });
}
