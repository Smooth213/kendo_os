import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/presentation/providers/match_rule_provider.dart';
import 'package:kendo_os/features/match/domain/rules/rule_preset.dart'; // ★ プリセットをインポート
import 'package:kendo_os/shared/config/beta_feature_flags.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';

// ==========================================
// ★ Phase 7: UI Rule Builder (Basic/Advanced分離)
// プリセットによる安全な設定と、エキスパート向けの詳細設定を分離
// ==========================================
class RuleConfigPanel extends ConsumerWidget {
  const RuleConfigPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ★ Phase 5-1: Rule Config UI削除（Stage2 β環境における編集パネルの完全隠蔽）
    if (!BetaFeatureFlags.showRuleDslEditor) {
      return const SizedBox.shrink(); // UI上からパネルの存在を完全に消滅させます
    }

    final rule = ref.watch(matchRuleProvider);
    final summary = ref.watch(ruleSummaryProvider);
    final notifier = ref.read(matchRuleProvider.notifier);
    final primaryColor = Colors.purple.shade700;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.large,
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- Basic Section: プリセット選択 ---
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: primaryColor),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '1. 大会プリセットを選択 (Basic)',
                      style: TextStyle(
                        fontWeight: AppFontWeight.bold,
                        fontSize: AppFontSize.subhead,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: RulePreset.officials.map((preset) {
                    return AppActionChip(
                      label: Text(preset.name),
                      backgroundColor: Colors.purple.shade50,
                      onPressed: () => notifier.applyPreset(preset),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // --- Real-time Summary Section ---
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            color: Colors.blueGrey.shade50,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Colors.blueGrey,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    summary,
                    style: TextStyle(
                      fontSize: AppFontSize.body,
                      color: Colors.blueGrey.shade800,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- Advanced Section: 詳細設定 ---
          ExpansionTile(
            title: const Text(
              '2. 詳細設定をカスタマイズ (Advanced)',
              style: TextStyle(
                fontWeight: AppFontWeight.bold,
                fontSize: AppFontSize.body,
              ),
            ),
            collapsedBackgroundColor: Colors.grey.shade50,
            childrenPadding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              // 1. 規定本数の切り替え
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '規定本数（勝敗ライン）',
                  style: TextStyle(
                    fontSize: AppFontSize.small,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 2, label: Text('3本勝負 (2本先取)')),
                  ButtonSegment(value: 1, label: Text('1本勝負')),
                ],
                selected: {rule.ipponLimit},
                onSelectionChanged: (set) {
                  notifier.updateField(
                    ipponLimit: set.first,
                    isIpponShobu: set.first == 1,
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xl),

              // 2. 延長設定
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '延長戦の有無',
                    style: TextStyle(
                      fontSize: AppFontSize.body,
                      fontWeight: AppFontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  Switch(
                    value: rule.isEnchoUnlimited || rule.enchoCount > 0,
                    activeThumbColor: primaryColor,
                    onChanged: (val) {
                      if (val) {
                        notifier.updateField(
                          isEnchoUnlimited: true,
                          enchoCount: 1,
                        );
                      } else {
                        notifier.updateField(
                          isEnchoUnlimited: false,
                          enchoCount: 0,
                        );
                      }
                    },
                  ),
                ],
              ),

              // 3. 判定設定
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '判定 (引き分け時に旗で決着)',
                    style: TextStyle(
                      fontSize: AppFontSize.body,
                      fontWeight: AppFontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
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
