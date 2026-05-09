import 'dart:convert';
import 'package:kendo_os/domain/rules/match_rule.dart';
import 'package:kendo_os/domain/rules/tournament_rule_config.dart';

// ==========================================
// ★ Phase 9: Rule Persistence
// 旧バージョンのデータ互換性（マイグレーション）を保ちつつ、
// 大会ルールの保存・共有（Import/Export）を可能にするシリアライザー
// ==========================================
class RuleSerializer {
  
  // --- 9-1 & 9-3: JSON Serialization (Export) ---
  /// 新しい階層型ConfigをJSON文字列に変換（DB保存や他端末への共有用）
  static String serialize(TournamentRuleConfig config) {
    return jsonEncode(config.toJson());
  }

  // --- 9-2 & 9-3: Migration & Import ---
  /// JSON文字列からConfigを安全に復元。旧バージョンのデータも自動で新構造へマイグレーションする。
  static TournamentRuleConfig deserialize(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) {
      return const TournamentRuleConfig();
    }

    try {
      final Map<String, dynamic> decoded = jsonDecode(jsonString);

      // 9-2: Migration Strategy (互換性維持)
      // 'schemaVersion' キーが存在すれば、新しい TournamentRuleConfig としてパースする
      if (decoded.containsKey('schemaVersion')) {
        return TournamentRuleConfig.fromJson(decoded);
      } else {
        // 旧バージョンの MatchRule JSON とみなして安全にマイグレーション（変換）
        // これにより、既存のIsarデータベース内の古い試合データがクラッシュせずに読み込める
        final oldRule = MatchRule.fromJson(decoded);
        return oldRule.toRuleConfig; 
      }
    } catch (e) {
      // 不正な文字列やパースエラー時は、システムを落とさずデフォルトルールを返す
      return const TournamentRuleConfig();
    }
  }
}