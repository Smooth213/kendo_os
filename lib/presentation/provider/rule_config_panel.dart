import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/provider/match_rule_provider.dart';

// ==========================================
// ★ Phase 6: ⑤ UI設定化 - ルール差し替えパネル
// 現場で「今日は3本勝負」「延長なし」などを即変更できるUI
// ==========================================
class RuleConfigPanel extends ConsumerWidget {
  const RuleConfigPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rule = ref.watch(matchRuleProvider);
    final notifier = ref.read(matchRuleProvider.notifier);
    final primaryColor = Colors.purple.shade700;

    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings_suggest, color: primaryColor),
                const SizedBox(width: 8),
                Text('大会・試合ルール設定', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor)),
              ],
            ),
            const Divider(height: 24),

            // 1. 規定本数の切り替え
            Text('規定本数（勝敗ライン）', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 2, label: Text('3本勝負 (2本先取)')),
                ButtonSegment(value: 1, label: Text('1本勝負')),
              ],
              selected: {rule.ipponLimit},
              onSelectionChanged: (set) => notifier.updateField(ipponLimit: set.first),
            ),
            const SizedBox(height: 24),

            // 2. 延長設定
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('延長戦の有無', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                Switch(
                  value: rule.isEnchoUnlimited || rule.enchoCount > 0,
                  activeThumbColor: primaryColor,
                  onChanged: (val) {
                    if (val) {
                      notifier.updateField(isEnchoUnlimited: true, enchoCount: 1);
                    } else {
                      notifier.updateField(isEnchoUnlimited: false, enchoCount: 0);
                    }
                  },
                ),
              ],
            ),

            // 3. 判定設定
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('判定 (引き分け時に旗で決着)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                Switch(
                  value: rule.hasHantei,
                  activeThumbColor: primaryColor,
                  onChanged: (val) => notifier.updateField(hasHantei: val),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}