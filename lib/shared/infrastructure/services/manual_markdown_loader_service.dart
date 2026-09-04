import 'package:flutter/services.dart';

/// 📖 マニュアルMarkdownローダー＆ハイライト処理サービス
class ManualMarkdownLoaderService {
  const ManualMarkdownLoaderService();

  String resolvePath(String path) {
    if (path.startsWith('docs/manuals/')) {
      return path.replaceFirst(
        'docs/manuals/',
        'packages/documentation_runtime/manuals/',
      );
    }
    if (path.startsWith('manual/') || path.startsWith('manuals/')) {
      return path.replaceFirst(
        RegExp(r'^manuals?/'),
        'packages/documentation_runtime/manuals/',
      );
    }
    if (path.endsWith('manual_index.md') || path.endsWith('index.md')) {
      return 'packages/documentation_runtime/manuals/manual_index.md';
    }
    if (path.endsWith('viewer_faq.md')) {
      return 'packages/documentation_runtime/manuals/faq/viewer_faq.md';
    }
    if (path.endsWith('operator_faq.md')) {
      return 'packages/documentation_runtime/manuals/faq/operator_faq.md';
    }
    if (!path.startsWith('packages/')) {
      return 'packages/documentation_runtime/manuals/$path';
    }
    return path;
  }

  Future<String> loadMarkdownContent({
    required String path,
    required String searchQuery,
    String? initialSearchQuery,
  }) async {
    final resolvedPath = resolvePath(path);
    final rawContent = await rootBundle.loadString(resolvedPath);

    // Web等で存在しないアセットキーに対し index.html が返却された場合の安全防壁
    if (rawContent.contains('<!DOCTYPE html>') ||
        rawContent.contains('<script') ||
        rawContent.contains('IndexedDB 永続化保護')) {
      // デフォルトのマニュアル目次をロードするフォールバック
      return loadMarkdownContent(
        path: 'packages/documentation_runtime/manuals/manual_index.md',
        searchQuery: searchQuery,
        initialSearchQuery: initialSearchQuery,
      );
    }

    // AI用メタデータを取り除く
    String content = rawContent.replaceFirst(
      RegExp(r'^---\s*\n.*?\n---\s*\n', dotAll: true),
      '',
    );

    // 検索語がある場合、Markdown内で目立たせる
    if (searchQuery.isNotEmpty) {
      final escapedQuery = RegExp.escape(searchQuery);
      content = content.replaceAllMapped(
        RegExp('($escapedQuery)', caseSensitive: false),
        (match) => '***${match.group(0)}***',
      );
    }

    if (initialSearchQuery != null && initialSearchQuery.isNotEmpty) {
      content = content.replaceAllMapped(
        RegExp(RegExp.escape(initialSearchQuery), caseSensitive: false),
        (match) => '***${match.group(0)}***',
      );
    }

    return content;
  }
}
