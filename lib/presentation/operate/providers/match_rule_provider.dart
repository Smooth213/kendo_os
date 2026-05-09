import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/domain/rules/match_rule.dart';
import 'package:kendo_os/domain/rules/rule_preset.dart'; // ★ Phase 7: プリセットのインポート
import 'package:kendo_os/domain/rules/rule_config_validator.dart'; // ★ Phase 8: インポートを追加

// 1. 金庫の管理人（Notifier）
class MatchRuleNotifier extends Notifier<MatchRule> {
  @override
  MatchRule build() {
    return const MatchRule(); // 最初は空っぽの箱を用意
  }

  void updateRule(MatchRule newState) {
    state = newState;
  }

  void updateBaseOrder(List<String> newOrder) {
    state = state.copyWith(baseOrder: newOrder);
  }

  // ★ Phase 7: プリセットを適用し、内部のフラットな設定値を一括で書き換える
  void applyPreset(RulePreset preset) {
    final c = preset.config;
    state = state.copyWith(
      matchTimeMinutes: c.time.matchTimeMinutes,
      isRunningTime: c.time.isRunningTime,
      ipponLimit: c.scoring.ipponLimit,
      isIpponShobu: c.scoring.isIpponShobu,
      isEnchoUnlimited: c.encho.isEnchoUnlimited,
      enchoTimeMinutes: c.encho.enchoTimeMinutes,
      enchoCount: c.encho.enchoCount,
      hasHantei: c.draw.hasHantei,
      hansokuLimit: c.hansoku.hansokuLimit,
      isKachinuki: c.team.isKachinuki,
      kachinukiUnlimitedType: c.team.kachinukiUnlimitedType,
      hasRepresentativeMatch: c.team.hasRepresentativeMatch,
      isDaihyoIpponShobu: c.team.isDaihyoIpponShobu,
    );
  }

  void updateField({
    int? ipponLimit,
    int? hansokuLimit,
    bool? isEnchoUnlimited,
    int? enchoCount,
    bool? hasHantei,
    double? matchTimeMinutes,
    double? enchoTimeMinutes,
    bool? isIpponShobu,
  }) {
    state = state.copyWith(
      ipponLimit: ipponLimit ?? state.ipponLimit,
      hansokuLimit: hansokuLimit ?? state.hansokuLimit,
      isEnchoUnlimited: isEnchoUnlimited ?? state.isEnchoUnlimited,
      enchoCount: enchoCount ?? state.enchoCount,
      hasHantei: hasHantei ?? state.hasHantei,
      matchTimeMinutes: matchTimeMinutes ?? state.matchTimeMinutes,
      enchoTimeMinutes: enchoTimeMinutes ?? state.enchoTimeMinutes,
      isIpponShobu: isIpponShobu ?? state.isIpponShobu,
    );
  }
}

// 2. アプリのどこからでもこの金庫にアクセスできる合鍵（Provider）
final matchRuleProvider = NotifierProvider<MatchRuleNotifier, MatchRule>(() {
  return MatchRuleNotifier();
});

// ==========================================
// ★ Phase 7 & 8: Real-time Summary & Runtime Validation
// ==========================================
final ruleSummaryProvider = Provider<String>((ref) {
  final rule = ref.watch(matchRuleProvider);
  final c = rule.toRuleConfig;

  final timeStr = '${c.time.matchTimeMinutes.toStringAsFixed(c.time.matchTimeMinutes % 1 == 0 ? 0 : 1)}分';
  final scoreStr = c.scoring.isIpponShobu ? '1本勝負' : '3本勝負(${c.scoring.ipponLimit}本先取)';
  final enchoStr = c.encho.isEnchoUnlimited ? '延長無制限' : (c.encho.enchoCount > 0 ? '延長${c.encho.enchoCount}回(${c.encho.enchoTimeMinutes.toInt()}分)' : '延長なし');
  final hanteiStr = c.draw.hasHantei ? '判定あり' : '判定なし';

  // ★ Phase 8: ドメイン層の Validator でルールの矛盾をチェック
  final errors = RuleConfigValidator.validate(c);

  String summary = 'この設定では：\n・$timeStr $scoreStr\n・$enchoStr\n・$hanteiStr';

  if (errors.isNotEmpty) {
    summary += '\n\n❌ 以下の設定エラーを修正してください：\n${errors.map((e) => '・$e').join('\n')}';
  } else if (!c.encho.isEnchoUnlimited && c.encho.enchoCount == 0 && !c.draw.hasHantei && !c.scoring.isIpponShobu) {
    summary += '\n\n⚠️ 注意: 延長も判定もないため、引き分けで終わる可能性があります。';
  }

  return summary;
});