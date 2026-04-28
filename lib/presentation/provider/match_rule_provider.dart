import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/match/match_rule.dart';

// 1. 金庫の管理人（Notifier）
class MatchRuleNotifier extends Notifier<MatchRule> {
  @override
  MatchRule build() {
    return MatchRule(); // 最初は空っぽの箱を用意
  }

  // 荷物をドサッと預かるための処理
  void updateRule(MatchRule newState) {
    state = newState;
  }

  // ★ 追加：基本オーダーだけをサッと書き換える専用の処理
  void updateBaseOrder(List<String> newOrder) {
    state = state.copyWith(baseOrder: newOrder);
  }

  // ★ Phase 6: UIから個別のルールを即座に変更するための処理
  void updateField({
    int? ipponLimit,
    int? hansokuLimit,
    bool? isEnchoUnlimited,
    int? enchoCount,
    bool? hasHantei,
    double? matchTimeMinutes,
    double? enchoTimeMinutes,
  }) {
    state = state.copyWith(
      ipponLimit: ipponLimit ?? state.ipponLimit,
      hansokuLimit: hansokuLimit ?? state.hansokuLimit,
      isEnchoUnlimited: isEnchoUnlimited ?? state.isEnchoUnlimited,
      enchoCount: enchoCount ?? state.enchoCount,
      hasHantei: hasHantei ?? state.hasHantei,
      matchTimeMinutes: matchTimeMinutes ?? state.matchTimeMinutes,
      enchoTimeMinutes: enchoTimeMinutes ?? state.enchoTimeMinutes,
    );
  }
}

// 2. アプリのどこからでもこの金庫にアクセスできる合鍵（Provider）
final matchRuleProvider = NotifierProvider<MatchRuleNotifier, MatchRule>(() {
  return MatchRuleNotifier();
});