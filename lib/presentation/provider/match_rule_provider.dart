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
}

// 2. アプリのどこからでもこの金庫にアクセスできる合鍵（Provider）
final matchRuleProvider = NotifierProvider<MatchRuleNotifier, MatchRule>(() {
  return MatchRuleNotifier();
});