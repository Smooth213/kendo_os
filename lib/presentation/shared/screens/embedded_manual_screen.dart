import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ============================================================================
// Phase 5: Embedded Documentation Viewer
// アプリ内に同梱されたMarkdownマニュアルをオフラインで閲覧・検索する画面
// ============================================================================

final manualIndexProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final jsonString = await rootBundle.loadString('docs/manuals/manual_index.json');
  return jsonDecode(jsonString) as Map<String, dynamic>;
});

class EmbeddedManualScreen extends ConsumerStatefulWidget {
  final String? initialFilePath;
  const EmbeddedManualScreen({super.key, this.initialFilePath});

  @override
  ConsumerState<EmbeddedManualScreen> createState() => _EmbeddedManualScreenState();
}

class _EmbeddedManualScreenState extends ConsumerState<EmbeddedManualScreen> {
  String _currentFilePath = 'docs/manuals/quickstart/index.md';
  String _markdownContent = '';
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialFilePath != null) {
      _currentFilePath = widget.initialFilePath!;
    }
    _loadMarkdown(_currentFilePath);
  }

  Future<void> _loadMarkdown(String path) async {
    setState(() => _isLoading = true);
    try {
      final content = await rootBundle.loadString(path);
      setState(() {
        _markdownContent = content;
        _currentFilePath = path;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _markdownContent = '# Error\\nFailed to load documentation: $path';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final indexAsync = ref.watch(manualIndexProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kendo Sync 取扱説明書'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => _loadMarkdown('docs/manuals/quickstart/index.md'),
            tooltip: 'クイックガイドへ戻る',
          )
        ],
      ),
      body: Row(
        children: [
          // 左側: 検索＆目次ペイン
          Container(
            width: 300,
            color: isDark ? Colors.grey[900] : Colors.grey[100],
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'マニュアル内を検索',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                  ),
                ),
                Expanded(
                  child: indexAsync.when(
                    data: (indexData) {
                      final results = indexData.entries.where((entry) {
                        if (_searchQuery.isEmpty) return true;
                        final title = entry.value['title'].toString().toLowerCase();
                        final keywords = (entry.value['keywords'] as List).join(' ').toLowerCase();
                        return title.contains(_searchQuery) || keywords.contains(_searchQuery);
                      }).toList();

                      return ListView.builder(
                        itemCount: results.length,
                        itemBuilder: (ctx, i) {
                          final path = results[i].key;
                          final title = results[i].value['title'];
                          final isSelected = path == _currentFilePath;
                          return ListTile(
                            title: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                            selected: isSelected,
                            selectedTileColor: isDark ? Colors.blue[900] : Colors.blue[100],
                            onTap: () => _loadMarkdown(path),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => const Padding(padding: EdgeInsets.all(8.0), child: Text('インデックス読み込みエラー')),
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          
          // 右側: Markdown表示ペイン
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Markdown(
                    data: _markdownContent,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                      h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
                      p: const TextStyle(fontSize: 16, height: 1.6),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}