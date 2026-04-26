import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/strategy/match_strategy.dart';
import 'match_list_provider.dart';
import 'match_rule_provider.dart';
import 'last_used_settings_provider.dart';
import 'match_provider.dart';

// ★ Step 3-5: 団体戦や勝ち抜き戦の複雑な集計ロジックをキャッシュするProvider
// これにより、MatchScreenのbuild内で毎秒計算が走るのを防ぎます
final groupMatchStatusProvider = Provider.family<GroupMatchStatus, String>((ref, matchId) {
  // 1. 必要なデータを取得（これらのデータが変更された時だけ再計算される）
  final matches = ref.watch(matchListProvider);
  final match = matches.where((m) => m.id == matchId).firstOrNull;
  if (match == null) return GroupMatchStatus(isAllDone: false);

  final teamMatches = matches.where((m) => m.groupName == match.groupName).toList();
  final rule = ref.watch(matchRuleProvider);
  final lastSettings = ref.watch(lastUsedSettingsProvider);

  // ★ Step 5-4: 仲介役の Strategy を通さず、直接 Engine で解析
  final engine = ref.watch(kendoRuleEngineProvider);
  return engine.analyzeGroupStatus(
    currentMatch: match,
    groupMatches: teamMatches,
    rule: rule,
    lastSettings: lastSettings,
  );
});