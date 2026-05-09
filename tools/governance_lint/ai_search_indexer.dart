// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:convert';

// ============================================================================
// Phase 6: AI Search Indexer (Markdown Chunking & Embedding Gen)
// Markdownファイルを読み込み、見出し(##)ごとに意味の塊(Chunk)として分割し、
// AI検索用のインデックスJSONを出力します。
// ============================================================================

void main() {
  print('🧠 [AI Indexer] Starting Markdown chunking and index generation...');

  final manualsDir = Directory('docs/manuals');
  if (!manualsDir.existsSync()) {
    print('❌ Docs directory not found.');
    return;
  }

  final mdFiles = manualsDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.md'));
  final List<Map<String, dynamic>> chunks = [];

  for (final file in mdFiles) {
    if (file.path.contains('templates')) continue;

    final lines = file.readAsLinesSync();
    String currentH1 = '';
    String currentH2 = '';
    List<String> currentBuffer = [];

    void saveChunk() {
      if (currentBuffer.isNotEmpty && currentBuffer.join('').trim().isNotEmpty) {
        chunks.add({
          'source': file.path,
          'h1': currentH1,
          'h2': currentH2,
          'content': currentBuffer.join('\\n'),
          // 実際の運用ではここで外部APIを叩いてVector Embedding(例: [0.01, 0.05, ...])を生成・付与します。
          // 本スクリプトはSandbox用のため、疑似インデックスとして保存します。
          'mock_vector_id': 'vec_${chunks.length}' 
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
    saveChunk(); // ファイル末尾のバッファを保存
  }

  final outputDir = Directory('assets/manual_embeddings');
  if (!outputDir.existsSync()) outputDir.createSync(recursive: true);

  final outputFile = File('${outputDir.path}/vector_index.json');
  outputFile.writeAsStringSync(jsonEncode(chunks));

  print('✅ [PASS] AI Search Index generated: ${chunks.length} chunks saved to ${outputFile.path}');
}