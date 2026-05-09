import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/match_rule_provider.dart';
import 'package:kendo_os/domain/rules/rule_preset.dart'; // ★ プリセットをインポート

// ==========================================
// ★ Phase 7: UI Rule Builder (Basic/Advanced分離)
// プリセットによる安全な設定と、エキスパート向けの詳細設定を分離
// ==========================================
class RuleConfigPanel extends ConsumerWidget {
  const RuleConfigPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rule = ref.watch(matchRuleProvider);
    final summary = ref.watch(ruleSummaryProvider);
    final notifier = ref.read(matchRuleProvider.notifier);
    final primaryColor = Colors.purple.shade700;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- Basic Section: プリセット選択 ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: primaryColor),
                    const SizedBox(width: 8),
                    Text('1. 大会プリセットを選択 (Basic)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor)),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: RulePreset.officials.map((preset) {
                    return ActionChip(
                      label: Text(preset.name),
                      backgroundColor: Colors.purple.shade50,
                      side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
                      onPressed: () => notifier.applyPreset(preset),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          
          // --- Real-time Summary Section ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            color: Colors.blueGrey.shade50,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: Colors.blueGrey, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    summary,
                    style: TextStyle(fontSize: 14, color: Colors.blueGrey.shade800, height: 1.4),
                  ),
                ),
              ],
            ),
          ),

          // --- Advanced Section: 詳細設定 ---
          ExpansionTile(
            title: const Text('2. 詳細設定をカスタマイズ (Advanced)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            collapsedBackgroundColor: Colors.grey.shade50,
            childrenPadding: const EdgeInsets.all(16.0),
            children: [
              // 1. 規定本数の切り替え
              Align(
                alignment: Alignment.centerLeft,
                child: Text('規定本数（勝敗ライン）', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ),
              const SizedBox(height: 8),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 2, label: Text('3本勝負 (2本先取)')),
                  ButtonSegment(value: 1, label: Text('1本勝負')),
                ],
                selected: {rule.ipponLimit},
                onSelectionChanged: (set) {
                  notifier.updateField(ipponLimit: set.first, isIpponShobu: set.first == 1);
                },
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
        ],
      ),
    );
  }
}