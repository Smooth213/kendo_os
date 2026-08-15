import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';

/// 無限稽古モードにおける「次の試合へ進む / 終了 / 休憩」選択ダイアログ（純粋UIコンポーネント）
class MatchInfiniteNextDialog extends StatelessWidget {
  final String redName;
  final String whiteName;
  final int winnerStreak;
  final VoidCallback onFinishInfinite;
  final VoidCallback onRestAndReturn;
  final VoidCallback onStartNextMatchImmediately;

  const MatchInfiniteNextDialog({
    super.key,
    required this.redName,
    required this.whiteName,
    required this.winnerStreak,
    required this.onFinishInfinite,
    required this.onRestAndReturn,
    required this.onStartNextMatchImmediately,
  });

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: '無限稽古: 次の試合',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🔥 挑戦者が入りました！'),
          const SizedBox(height: AppSpacing.md),
          Text(
            '防衛(赤): $redName ($winnerStreak連勝中)',
            style: const TextStyle(
              fontWeight: AppFontWeight.bold,
              color: AppKendoColors.red,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '挑戦(白): $whiteName',
            style: const TextStyle(fontWeight: AppFontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text('どうしますか？'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onFinishInfinite,
          style: TextButton.styleFrom(
            foregroundColor: AppKendoColors.hansokuRed,
          ),
          child: const Text('無限稽古を終了'),
        ),
        TextButton(onPressed: onRestAndReturn, child: const Text('一覧に戻る（休憩）')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: context.appColors.warningColor,
            foregroundColor: AppKendoColors.pureWhite,
          ),
          onPressed: onStartNextMatchImmediately,
          child: const Text('すぐに次の試合を開始'),
        ),
      ],
    );
  }
}
