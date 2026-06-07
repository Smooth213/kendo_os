// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

// ============================================================================
// Deep Doc Phase 7: AI Knowledge Optimization
// AI（RAG等）が文脈を理解できるよう、チャンク構造の最適化、
// セマンティックタグの付与、クロスリファレンスの抽出を行います。
// ============================================================================

void main() {
  const msg =
      '🧠 [AI Knowledge Indexer] Optimizing Knowledge for AI Runtime (Phase 7)...';
  print(msg);

  final manualsDir = Directory('docs/manuals');
  final listSync = manualsDir.listSync(recursive: true);
  final fileList = listSync.whereType<File>();
  final mdFiles = fileList.where((f) => f.path.endsWith('.md'));

  final List<Map<String, dynamic>> chunks = [];

  for (final file in mdFiles) {
    if (file.path.contains('templates')) {
      continue;
    }

    final content = file.readAsStringSync();

    // Step 7-2: Semantic Tagging (YAMLメタデータの詳細抽出)
    final metadataRegex = RegExp(r'^---\s*\n(.*?)\n---\s*\n', dotAll: true);
    final metadataMatch = metadataRegex.firstMatch(content);
    Map<String, dynamic> metadata = {};
    if (metadataMatch != null) {
      final yamlContent = metadataMatch.group(1) ?? '';
      for (var line in yamlContent.split('\n')) {
        final parts = line.split(':');
        if (parts.length >= 2) {
          final key = parts[0].trim();
          final val = parts.sublist(1).join(':').trim();
          // boolean値のパース（offline_supported等）
          if (val == 'true') {
            metadata[key] = true;
          } else if (val == 'false') {
            metadata[key] = false;
          } else {
            metadata[key] = val;
          }
        }
      }
    }

    // Step 7-3: Cross Reference Network の抽出 (See also: ...)
    List<String> crossReferences = [];
    final seeAlsoRegex = RegExp(r'See also:\n((\s*-\s*\[.*?\]\(.*?\)\n?)+)');
    final seeAlsoMatch = seeAlsoRegex.firstMatch(content);
    if (seeAlsoMatch != null) {
      final linkRegex = RegExp(r'\[(.*?)\]\((.*?)\)');
      final links = linkRegex.allMatches(seeAlsoMatch.group(1) ?? '');
      for (final link in links) {
        crossReferences.add(link.group(2) ?? ''); // リンク先の相対パスを抽出
      }
    }

    // Step 7-1: Chunk Structure 最適化
    final bodyRegex = RegExp(r'^---\s*\n.*?\n---\s*\n', dotAll: true);
    final body = content.replaceFirst(bodyRegex, '');
    final lines = body.split('\n');
    String currentH1 = '';
    String currentH2 = '';
    List<String> currentBuffer = [];

    void saveChunk() {
      final joined = currentBuffer.join('');
      if (currentBuffer.isNotEmpty && joined.trim().isNotEmpty) {
        // 見出しからチャンクの種類を高精度に推論
        String chunkType = 'info';
        final h2Lower = currentH2.toLowerCase();
        final hasObstacle = h2Lower.contains('障害') || h2Lower.contains('エラー');
        final hasNetwork = h2Lower.contains('通信断') || h2Lower.contains('停電');
        final isFailure = hasObstacle || hasNetwork;

        if (h2Lower.contains('faq') || h2Lower.contains('質問')) {
          chunkType = 'faq';
        } else if (h2Lower.contains('手順') || h2Lower.contains('操作')) {
          chunkType = 'procedure';
        } else if (isFailure) {
          chunkType = 'failure_recovery';
        } else if (h2Lower.contains('governance')) {
          chunkType = 'governance';
        }

        chunks.add({
          'source': file.path,
          'metadata': metadata,
          'chunk_type': chunkType,
          'h1': currentH1,
          'h2': currentH2,
          'content': currentBuffer.join('\n').trim(),
          // ナレッジグラフ構築用
          'cross_references': crossReferences,
        });
        currentBuffer.clear();
      }
    }

    for (final line in lines) {
      if (line.startsWith('# ')) {
        saveChunk();
        currentH1 = line.replaceFirst('# ', '').trim();
        currentH2 = '';
      } else if (line.startsWith('## ')) {
        saveChunk();
        currentH2 = line.replaceFirst('## ', '').trim();
      } else {
        currentBuffer.add(line);
      }
    }
    saveChunk();
  }

  final outputDir = Directory('assets/manual_embeddings');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  final outputFile = File('${outputDir.path}/vector_index.json');
  outputFile.writeAsStringSync(jsonEncode(chunks));

  final count = chunks.length;
  final msg2 =
      '✅ [PASS] AI Knowledge Optimized: $count chunks generated with Semantic Tags & Cross-Refs.';
  print(msg2);
}
