import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';

/// 試合画面における「勝敗の判定」選択ダイアログ（純粋UIコンポーネント）
class MatchHanteiDialog extends StatelessWidget {
  final String redName;
  final String whiteName;
  final bool isDark;
  final void Function(String? result) onSelected;

  const MatchHanteiDialog({
    super.key,
    required this.redName,
    required this.whiteName,
    required this.isDark,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final rName = redName.contains(':')
        ? redName.split(':').last.trim()
        : redName;
    final wName = whiteName.contains(':')
        ? whiteName.split(':').last.trim()
        : whiteName;

    return AppDialog(
      title: '勝敗の判定',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '同点のため、判定（または引き分け）を選択してください',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.appColors.textColor),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => onSelected('red'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppKendoColors.hansokuRed,
                    foregroundColor: AppKendoColors.pureWhite,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.lg,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.medium,
                    ),
                    elevation: 0,
                  ),
                  child: FittedBox(
                    child: Text(
                      '赤の判定勝ち\n($rName)',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: AppFontSize.scoreboardMedium,
                        fontWeight: AppFontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => onSelected('white'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? const Color(0xFF38383A)
                        : const Color(0x33000000),
                    foregroundColor: isDark
                        ? const Color(0xFFFFFFFF)
                        : const Color(0xFF000000),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.lg,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.medium,
                    ),
                    elevation: 0,
                  ),
                  child: FittedBox(
                    child: Text(
                      '白の判定勝ち\n($wName)',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: AppFontSize.scoreboardMedium,
                        fontWeight: AppFontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => onSelected('draw'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                side: BorderSide(
                  color: isDark
                      ? const Color(0xFFFFFFFF)
                      : const Color(0x8A000000),
                ),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
              ),
              child: Text(
                '引き分け',
                style: TextStyle(
                  fontWeight: AppFontWeight.bold,
                  color: isDark
                      ? const Color(0xFFFFFFFF)
                      : const Color(0xFF000000),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextButton(
            onPressed: () => onSelected(null),
            child: const Text(
              'キャンセル（戻る）',
              style: TextStyle(color: AppKendoColors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
