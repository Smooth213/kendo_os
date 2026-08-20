import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 📖 マニュアル全文検索インデックス (manual_search_index.json) プロバイダ
final manualIndexProvider = FutureProvider<List<dynamic>>((ref) async {
  final jsonString = await rootBundle.loadString(
    'packages/documentation_runtime/manuals/manual_search_index.json',
  );
  final decoded = jsonDecode(jsonString);

  if (decoded is List) {
    return decoded;
  } else if (decoded is Map) {
    return decoded.entries
        .map(
          (e) => {
            'path': e.key,
            'title': e.value['title'] ?? '無題',
            'headings': [],
            'tags': e.value['keywords'] ?? [],
          },
        )
        .toList();
  }

  return [];
});
