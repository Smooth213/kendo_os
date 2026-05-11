import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../manual/manual_routes.dart';

// ============================================================================
// Phase 5 & 6: Embedded Documentation Viewer
// アプリ内に同梱されたMarkdownマニュアルをオフラインで閲覧・検索する画面
// AIメタデータの除外処理およびレスポンシブ対応（スマホ/iPad）を含む
// ============================================================================

// ★ Step 6-1: 新しい全文検索インデックス (manual_search_index.json) を読み込む
final manualIndexProvider = FutureProvider<List<dynamic>>((ref) async {
  final jsonString = await rootBundle.loadString('docs/manuals/manual_search_index.json');
  final decoded = jsonDecode(jsonString);

  // 新しいList形式の場合
  if (decoded is List) {
    return decoded;
  } 
  // 古いMap形式（以前のロードマップの遺物）が残っていた場合のフェイルセーフ（自動変換）
  else if (decoded is Map) {
    return decoded.entries.map((e) => {
      'path': e.key,
      'title': e.value['title'] ?? '無題',
      'headings': [],
      'tags': e.value['keywords'] ?? [],
    }).toList();
  }
  
  return [];
});

class EmbeddedManualScreen extends ConsumerStatefulWidget {
  final String? initialFilePath;
  final String? initialSearchQuery;
  const EmbeddedManualScreen({super.key, this.initialFilePath, this.initialSearchQuery});

  @override
  ConsumerState<EmbeddedManualScreen> createState() => _EmbeddedManualScreenState();
}

class _EmbeddedManualScreenState extends ConsumerState<EmbeddedManualScreen> {
  String _currentFilePath = 'docs/manuals/quickstart/index.md';
  String _markdownContent = '';
  String _searchQuery = '';
  bool _isLoading = true;
  // ★ 修正1: 検索ボックスの文字をプログラムから操作(クリア)するためのコントローラーを追加
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialFilePath != null) {
      _currentFilePath = widget.initialFilePath!;
    }
    _loadMarkdown(_currentFilePath);
  }

  // ★ 修正2: メモリリークを防ぐための破棄処理
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMarkdown(String path) async {
    setState(() => _isLoading = true);
    
    // ★ 修正1: リンクや古いインデックスからの不正なパスを強制的に正しいfaqディレクトリへ補正
    if (path.endsWith('viewer_faq.md')) path = 'docs/manuals/faq/viewer_faq.md';
    if (path.endsWith('operator_faq.md')) path = 'docs/manuals/faq/operator_faq.md';

    try {
      final rawContent = await rootBundle.loadString(path);
      // AI用メタデータを取り除く
      String content = rawContent.replaceFirst(RegExp(r'^---\s*\n.*?\n---\s*\n', dotAll: true), '');

      // 検索語がある場合、Markdown内で目立たせる
      if (_searchQuery.isNotEmpty) {
        final escapedQuery = RegExp.escape(_searchQuery);
        content = content.replaceAllMapped(
          RegExp('($escapedQuery)', caseSensitive: false),
          (match) => '***${match.group(0)}***',
        );
      }
      
      if (widget.initialSearchQuery != null && widget.initialSearchQuery!.isNotEmpty) {
        final query = widget.initialSearchQuery!;
        content = content.replaceAllMapped(
          RegExp(RegExp.escape(query), caseSensitive: false),
          (match) => '***${match.group(0)}***',
        );
      }

      setState(() {
        _markdownContent = content;
        _currentFilePath = path;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        // ★ 修正2: pubspec.yaml への追加忘れをフォローする親切なエラー画面
        _markdownContent = '# 📄 読み込みエラー\n\nファイルが見つかりません: `$path`\n\n'
            '**【開発者の方へ：pubspec.yamlの確認】**\n'
            'このファイルが新しく追加されたフォルダ（例: `faq/`）にある場合、'
            'アプリの `pubspec.yaml` の `assets:` セクションにそのフォルダパスが登録されていない可能性があります。\n\n'
            '```yaml\n'
            'flutter:\n'
            '  assets:\n'
            '    - docs/manuals/faq/  <-- これを追加してください\n'
            '```\n\n'
            '詳細なエラー:\n$e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final indexAsync = ref.watch(manualIndexProvider);
    // ★ 修正点2: 画面幅を判定し、スマホ(600px未満)とiPadでレイアウトを切り替える
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    Widget buildIndexPane() {
      return SafeArea(
        child: Container(
          width: isWideScreen ? 320 : null,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            border: Border(right: BorderSide(color: isDark ? Colors.white12 : Colors.black12)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  // ★ 修正3: コントローラーを紐付け
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'タイトル、見出し、キーワード検索...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    // ★ 修正4: 文字が入力されている時だけ右端に「✕」ボタンを表示
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            tooltip: '検索をクリアして一覧に戻る',
                            onPressed: () {
                              _searchController.clear(); // 検索枠の文字を消去
                              setState(() => _searchQuery = ''); // 検索状態をリセットして一覧を再描画
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                ),
              ),
              Expanded(
                child: indexAsync.when(
                  data: (indexList) {
                    final results = indexList.where((item) {
                      if (_searchQuery.isEmpty) return true;
                      final title = item['title'].toString().toLowerCase();
                      final headings = (item['headings'] as List).join(' ').toLowerCase();
                      final tags = (item['tags'] as List).join(' ').toLowerCase();
                      return title.contains(_searchQuery) ||
                             headings.contains(_searchQuery) ||
                             tags.contains(_searchQuery);
                    }).toList();

                    return ListView.separated(
                      itemCount: results.length,
                      separatorBuilder: (_, _) => Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
                      itemBuilder: (ctx, i) {
                        final path = results[i]['path'];
                        final title = results[i]['title'];
                        final isSelected = path == _currentFilePath;
                        return ListTile(
                          dense: true,
                          title: Text(title, style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.blueAccent : null,
                          )),
                          subtitle: _searchQuery.isNotEmpty ? Text(
                            (results[i]['headings'] as List).take(2).join(' / '),
                            style: const TextStyle(fontSize: 10),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ) : null,
                          onTap: () {
                            _loadMarkdown(path);
                            // スマホ画面ならタップ後にドロワーを閉じる
                            if (!isWideScreen) Navigator.pop(context);
                          },
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Index Error: $err')),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final markdownPane = Expanded(
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Markdown(
              data: _markdownContent,
              // ★ 修正1: テキスト選択機能を切り、タップ判定をリンク機能に全集中させる
              selectable: false,
              onTapLink: (text, href, title) {
                if (href == null || href.startsWith('http')) return;
                
                // ★ 修正1: ページ内リンク（#単体）がタップされても、エラー画面に行かないよう完全に無視する
                if (href.startsWith('#')) return;

                // 内部リンク処理 (manual:// 形式の解決)
                if (href.startsWith('manual://')) {
                  final id = href.replaceFirst('manual://', '');
                  final route = ManualRoute.fromId(id);
                  if (route != null) {
                    _loadMarkdown(route.path);
                    return;
                  }
                }

                // 現在のファイルのディレクトリを取得
                final dirSegments = _currentFilePath.split('/');
                dirSegments.removeLast();
                
                // 相対パスを絶対パスに変換
                final hrefSegments = href.split('/');
                for (final segment in hrefSegments) {
                  if (segment == '.') continue;
                  if (segment == '..') {
                    if (dirSegments.isNotEmpty) dirSegments.removeLast();
                  } else {
                    // ★ 修正2: リンク先にアンカー(#)が含まれる場合、ファイル名だけを抽出してエラーを回避する
                    final fileOnly = segment.split('#').first;
                    if (fileOnly.isNotEmpty) {
                      dirSegments.add(fileOnly);
                    }
                  }
                }
                
                final targetPath = dirSegments.join('/');
                _loadMarkdown(targetPath);
              },
              styleSheet: MarkdownStyleSheet(
                h1: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                h2: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal, decoration: TextDecoration.underline),
                p: const TextStyle(fontSize: 16, height: 1.7),
                code: TextStyle(backgroundColor: isDark ? Colors.white10 : Colors.black12),
                // ★ 修正4: リンクの色と下線を「明示的」に指定し、確実に水色にする
                a: const TextStyle(color: Colors.blueAccent, decoration: TextDecoration.underline),
                em: TextStyle(
                  backgroundColor: Colors.yellow.withValues(alpha: 0.5),
                  color: isDark ? Colors.white : Colors.black,
                  fontStyle: FontStyle.normal,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
    );

    // ★ 修正5: 以前のAppBar（✕ボタン、🏠ボタン、≡メニューの共存）を再適用
    return Scaffold(
      drawer: isWideScreen ? null : Drawer(child: buildIndexPane()),
      appBar: AppBar(
        title: const Text('ヘルプ・マニュアル', style: TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => _loadMarkdown('docs/manuals/manual_index.md'),
            tooltip: '総合ホームへ戻る',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const Icon(Icons.close, size: 28),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'マニュアルを閉じる',
            ),
          ),
        ],
      ),
      body: Builder(builder: (context) {
        return Stack(
          children: [
            isWideScreen
                ? Row(children: [buildIndexPane(), markdownPane])
                : Column(children: [markdownPane]),
            if (!isWideScreen)
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton(
                  mini: true,
                  backgroundColor: Theme.of(context).primaryColor,
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  tooltip: 'メニューを開く',
                  child: const Icon(Icons.search, color: Colors.white),
                ),
              ),
          ],
        );
      }),
    );
  }
}