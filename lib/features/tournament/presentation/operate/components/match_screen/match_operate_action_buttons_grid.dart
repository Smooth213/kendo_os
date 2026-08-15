import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

/// 試合画面上部の4大アクションボタングリッド（純粋UIコンポーネント）
/// 1段目: 観戦URLを共有 | 履歴から復元
/// 2段目: スコアを確認 | ルールを確認
class MatchOperateActionButtonsGrid extends StatelessWidget {
  final bool isViewOnly;
  final bool isKachinuki;
  final VoidCallback onShareUrl;
  final VoidCallback? onRestoreHistory;
  final VoidCallback onCheckScore;
  final VoidCallback onCheckRule;

  const MatchOperateActionButtonsGrid({
    super.key,
    required this.isViewOnly,
    required this.isKachinuki,
    required this.onShareUrl,
    this.onRestoreHistory,
    required this.onCheckScore,
    required this.onCheckRule,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 0,
        left: AppSpacing.sm,
        right: AppSpacing.sm,
      ),
      child: Column(
        children: [
          // 1段目: 観戦URLを共有 | 履歴から復元
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onShareUrl,
                  icon: const Icon(Icons.ios_share, size: 16),
                  label: const Text(
                    '観戦URLを共有',
                    style: TextStyle(
                      fontSize: AppFontSize.small,
                      fontWeight: AppFontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 30),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isViewOnly ? null : onRestoreHistory,
                  icon: const Icon(Icons.history, size: 16),
                  label: const Text(
                    '履歴から復元',
                    style: TextStyle(
                      fontSize: AppFontSize.small,
                      fontWeight: AppFontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 30),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
          // 2段目: スコアを確認 | ルールを確認
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCheckScore,
                  icon: Icon(
                    isKachinuki ? Icons.timeline : Icons.table_chart_outlined,
                    size: 16,
                  ),
                  label: const Text(
                    'スコアを確認',
                    style: TextStyle(
                      fontSize: AppFontSize.small,
                      fontWeight: AppFontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 30),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCheckRule,
                  icon: const Icon(Icons.info_outline, size: 16),
                  label: const Text(
                    'ルールを確認',
                    style: TextStyle(
                      fontSize: AppFontSize.small,
                      fontWeight: AppFontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 30),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
