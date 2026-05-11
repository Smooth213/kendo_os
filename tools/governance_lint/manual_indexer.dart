// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:convert';

// ============================================================================
// Documentation Indexer (Appliance Quality Edition)
// インデックスから重複絵文字、英語表記、ファイル名露出を完全に排除し、
// 古いディレクトリに残ったFAQの残骸を無視する。
// ============================================================================
void main() {
  print('🔍 [Indexer] Building End-User Search Index...');

  final docsDir = Directory('docs/manuals');
  final validDirs = ['viewer', 'operator', 'quickstart', 'faq', 'recovery'];
  final excludeFiles = ['personas.md', 'image_mapping.md', 'style_guide.md', 'forbidden_words.md', 'manual_index.md'];

  final List<Map<String, dynamic>> index = [];

  final mdFiles = docsDir.listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.md'))
      .where((f) {
        final isAllowedDir = validDirs.any((dir) => f.path.contains('/$dir/'));
        final isExcluded = excludeFiles.any((ex) => f.path.endsWith(ex));
        return isAllowedDir && !isExcluded;
      }).toList();

  for (final file in mdFiles) {
    // ★ 修正1: 古い場所に残っているFAQファイルの残骸を完全に無視する
    if ((file.path.endsWith('viewer_faq.md') || file.path.endsWith('operator_faq.md')) && 
        !file.path.contains('/faq/')) {
      continue; 
    }

    final content = file.readAsStringSync();
    
    String title = '';
    final titleMatch = RegExp(r'^#\s+(.+)$', multiLine: true).firstMatch(content);
    if (titleMatch != null) {
      title = titleMatch.group(1)?.trim() ?? '';
    }

    if (title.isEmpty || title.contains('.md') || title.contains('_')) {
      if (file.path.contains('viewer_faq')) {
        title = '観客向け よくある質問';
      } else if (file.path.contains('operator_faq')) {
        title = '運営向け よくある質問';
      } else {
        title = file.uri.pathSegments.last.replaceAll('.md', '').replaceAll('_', ' ');
      }
    }

    String cleanTitle = title.replaceFirst(RegExp(r'^(?:\s|⏱|🚨|📋|📱|💡|❓|\uFE0F)+', unicode: true), '');
    cleanTitle = cleanTitle.replaceAll(RegExp(r'\s*\([A-Za-z0-9\s&\-]+\)$'), '').trim();

    String finalTitle = cleanTitle;
    int sortOrder = 99;

    // ★ 修正2: FAQの場合は確実に 💡 アイコンにする
    if (file.path.contains('/faq/') || file.path.endsWith('_faq.md')) {
      finalTitle = '💡 $cleanTitle';
      sortOrder = 50;
    } else if (file.path.contains('/quickstart/')) {
      finalTitle = '⏱️ $cleanTitle';
      sortOrder = 10;
    } else if (file.path.contains('/recovery/')) {
      finalTitle = '🚨 $cleanTitle';
      sortOrder = 20;
    } else if (file.path.contains('/operator/')) {
      finalTitle = '📋 $cleanTitle';
      sortOrder = 30;
    } else if (file.path.contains('/viewer/')) {
      finalTitle = '📱 $cleanTitle';
      sortOrder = 40;
    }

    index.add({
      'path': file.path,
      'title': finalTitle,
      'headings': RegExp(r'^##\s+(.+)$', multiLine: true).allMatches(content).map((m) => m.group(1)?.trim() ?? '').toList(),
      'sort_order': sortOrder,
      'tags': [], 
      'last_updated': DateTime.now().toIso8601String(),
    });
  }

  final faqFile = File('docs/manuals/faq/faq_index.json');
  if (faqFile.existsSync()) {
    final List<dynamic> faqs = jsonDecode(faqFile.readAsStringSync());
    for (final faq in faqs) {
      index.add({
        'path': 'docs/manuals/faq/${faq['category']}_faq.md',
        'title': '❓ Q. ${faq['question']}',
        'headings': ['FAQ'],
        'sort_order': 60,
        'tags': faq['tags'] ?? [],
        'last_updated': DateTime.now().toIso8601String(),
      });
    }
  }

  index.sort((a, b) {
    final cmp = (a['sort_order'] as int).compareTo(b['sort_order'] as int);
    return cmp != 0 ? cmp : (a['title'] as String).compareTo(b['title'] as String);
  });

  File('docs/manuals/manual_search_index.json').writeAsStringSync(jsonEncode(index));
  print('✅ [PASS] Cleaned Search Index generated.');
}