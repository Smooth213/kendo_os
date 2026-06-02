import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/core/config/beta_feature_flags.dart'; // ★ 追加: フラグによる完全統制

// ============================================================================
// Phase 6: AI Help Agent Service
// インデックス化されたチャンクを検索し、ユーザーの質問に該当するマニュアル箇所を特定します。
// ============================================================================

final aiHelpServiceProvider = Provider<AiHelpService>((ref) => AiHelpService());

class AiHelpService {
  List<Map<String, dynamic>>? _indexCache;

  Future<void> _loadIndex() async {
    // ★ Phase 4-1: AI Runtime の完全封鎖ガード
    if (!BetaFeatureFlags.showAiFeatures) return;
    if (_indexCache != null) return;
    try {
      final jsonString = await rootBundle.loadString(
        'assets/manual_embeddings/vector_index.json',
      );
      final List<dynamic> decoded = jsonDecode(jsonString);
      _indexCache = decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      _indexCache = [];
    }
  }

  /// ユーザーの質問(query)に最も関連するマニュアルのチャンクを検索します。
  Future<List<Map<String, dynamic>>> searchRelevantManuals(String query) async {
    // ★ Phase 4-1: AI Runtime の完全封鎖ガード
    if (!BetaFeatureFlags.showAiFeatures) return [];

    await _loadIndex();
    if (_indexCache == null || _indexCache!.isEmpty) return [];

    final searchTerms = query.toLowerCase().split(' ');

    final scoredChunks = _indexCache!.map((chunk) {
      int score = 0;
      final content = (chunk['content'] as String).toLowerCase();
      final h1 = (chunk['h1'] as String).toLowerCase();
      final h2 = (chunk['h2'] as String).toLowerCase();

      for (final term in searchTerms) {
        if (h1.contains(term)) score += 5;
        if (h2.contains(term)) score += 3;
        if (content.contains(term)) score += 1;
      }
      return {'chunk': chunk, 'score': score};
    }).toList();

    scoredChunks.sort(
      (a, b) => (b['score'] as int).compareTo(a['score'] as int),
    );
    return scoredChunks
        .where((e) => (e['score'] as int) > 0)
        .take(3)
        .map((e) => e['chunk'] as Map<String, dynamic>)
        .toList();
  }

  /// 検索結果を元に、LLM（またはルールベース）で最終的な回答を生成します。
  Future<String> askAgent(String query) async {
    // ★ Phase 4-1: AI Runtime の完全封鎖ガード
    if (!BetaFeatureFlags.showAiFeatures) {
      return '🔒 アクセス制限：この機能はStage2 βリリースでは完全に封鎖されています。';
    }

    final relevantChunks = await searchRelevantManuals(query);
    if (relevantChunks.isEmpty) {
      return "申し訳ありません。マニュアル内に「$query」に関する情報が見つかりませんでした。";
    }

    final sourceTitles = relevantChunks
        .map((c) => "「${c['h1']} > ${c['h2']}」")
        .toSet()
        .join(", ");
    return "マニュアルの $sourceTitles に関連する情報が見つかりました。\\n\\n"
        "【該当箇所の抜粋】\\n${relevantChunks.first['content']}";
  }
}
