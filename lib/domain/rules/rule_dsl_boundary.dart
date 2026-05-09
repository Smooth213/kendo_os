import 'package:kendo_os/domain/rules/tournament_rule_config.dart';

// ==========================================
// ★ Phase 12: DSL準備 (Domain-Specific Language)
// 将来的にテキストや独自スクリプトからルールを構築するための境界線
// ==========================================

/// 12-2: Rule Metadata (displayName, description)
/// DSLのリファレンスや、将来の動的UI生成に使用するメタデータ
class RuleMetadata {
  final String property;
  final String displayName;
  final String description;

  const RuleMetadata(this.property, this.displayName, this.description);
}

/// 12-1: Internal Schema 整理
/// ルールの設定項目スキーマを構造化して保持（将来のパーサー辞書）
class RuleSchemaRegistry {
  static const List<RuleMetadata> schemas = [
    RuleMetadata('time.matchTimeMinutes', '試合時間', '試合の基本時間（分）'),
    RuleMetadata('time.isRunningTime', 'ランニングタイム', '時計を止めずに流し続けるか'),
    RuleMetadata('scoring.isIpponShobu', '一本勝負', '1本先取で勝利とするか'),
    RuleMetadata('scoring.ipponLimit', '規定本数', '勝利に必要な本数（通常2）'),
    RuleMetadata('encho.isEnchoUnlimited', '延長無制限', '勝敗が決まるまで時間を無制限にするか'),
    RuleMetadata('encho.enchoCount', '延長回数', '無制限でない場合の延長の上限回数'),
    RuleMetadata('draw.hasHantei', '判定の有無', '時間切れ・延長終了時に判定を行うか'),
    RuleMetadata('hansoku.hansokuLimit', '反則限界回数', '相手に1本を与える反則の累積回数'),
    RuleMetadata('team.isKachinuki', '勝ち抜き戦', '勝者が次の試合も続けて戦う形式か'),
  ];
}

/// 12-3: DSL変換境界整理
/// 将来のパーサー(String -> Config)実装に備え、まずは Config -> DSL文字列 のエクスポート口を確保
abstract class RuleDslMapper {
  
  /// 現在のルール設定を人間が読めるDSLライクな文字列に変換
  static String exportToDsl(TournamentRuleConfig config) {
    final buffer = StringBuffer();
    buffer.writeln('TournamentRule (v${config.schemaVersion}) {');
    buffer.writeln('  Time {');
    buffer.writeln('    matchTimeMinutes: ${config.time.matchTimeMinutes}');
    buffer.writeln('    isRunningTime: ${config.time.isRunningTime}');
    buffer.writeln('  }');
    buffer.writeln('  Scoring {');
    buffer.writeln('    isIpponShobu: ${config.scoring.isIpponShobu}');
    buffer.writeln('    ipponLimit: ${config.scoring.ipponLimit}');
    buffer.writeln('  }');
    buffer.writeln('  Encho {');
    buffer.writeln('    isEnchoUnlimited: ${config.encho.isEnchoUnlimited}');
    buffer.writeln('    enchoTimeMinutes: ${config.encho.enchoTimeMinutes}');
    buffer.writeln('    enchoCount: ${config.encho.enchoCount}');
    buffer.writeln('  }');
    buffer.writeln('  Draw {');
    buffer.writeln('    hasHantei: ${config.draw.hasHantei}');
    buffer.writeln('  }');
    buffer.writeln('  Hansoku {');
    buffer.writeln('    hansokuLimit: ${config.hansoku.hansokuLimit}');
    buffer.writeln('  }');
    buffer.writeln('  Team {');
    buffer.writeln('    isKachinuki: ${config.team.isKachinuki}');
    buffer.writeln('  }');
    buffer.writeln('}');
    return buffer.toString();
  }
}