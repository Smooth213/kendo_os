import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

/// 🥋 試合場（コート）と試合順（何試合目）を ＋/－ および テンキーで素早く設定する数値スロットUI
class MatchCourtSlotPicker extends StatelessWidget {
  final int? courtNumber;
  final int? matchOrder;
  final ValueChanged<int?> onCourtNumberChanged;
  final ValueChanged<int?> onMatchOrderChanged;
  final bool isDark;

  const MatchCourtSlotPicker({
    super.key,
    required this.courtNumber,
    required this.matchOrder,
    required this.onCourtNumberChanged,
    required this.onMatchOrderChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = context.appColors;

    return Row(
      children: [
        // 🏟️ 試合場スロット
        Expanded(
          child: _buildSlotCard(
            context: context,
            themeColors: themeColors,
            icon: Icons.stadium,
            label: '試合場',
            prefixText: '第',
            suffixText: '試合場',
            value: courtNumber,
            onDecrement: () {
              final current = courtNumber ?? 1;
              if (current > 1) {
                onCourtNumberChanged(current - 1);
              } else {
                onCourtNumberChanged(null);
              }
            },
            onIncrement: () {
              final current = courtNumber ?? 0;
              onCourtNumberChanged(current + 1);
            },
            onTapValue: () => _showNumberInputDialog(
              context: context,
              title: '試合場番号を入力',
              currentValue: courtNumber,
              suffix: '試合場',
              onConfirmed: onCourtNumberChanged,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        // 🔢 試合順スロット
        Expanded(
          child: _buildSlotCard(
            context: context,
            themeColors: themeColors,
            icon: Icons.tag,
            label: '試合順',
            prefixText: '第',
            suffixText: '試合目',
            value: matchOrder,
            onDecrement: () {
              final current = matchOrder ?? 1;
              if (current > 1) {
                onMatchOrderChanged(current - 1);
              } else {
                onMatchOrderChanged(null);
              }
            },
            onIncrement: () {
              final current = matchOrder ?? 0;
              onMatchOrderChanged(current + 1);
            },
            onTapValue: () => _showNumberInputDialog(
              context: context,
              title: '試合順を入力',
              currentValue: matchOrder,
              suffix: '試合目',
              onConfirmed: onMatchOrderChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlotCard({
    required BuildContext context,
    required AppThemeColors themeColors,
    required IconData icon,
    required String label,
    required String prefixText,
    required String suffixText,
    required int? value,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
    required VoidCallback onTapValue,
  }) {
    final bgColor = isDark
        ? const Color(0xFF2C2C2E)
        : themeColors.cardBackground;
    final borderColor = isDark
        ? const Color(0xFF38383A)
        : themeColors.primaryAccent.withValues(alpha: 0.2);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.medium,
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: themeColors.primaryAccent),
              const SizedBox(width: AppSpacing.xxs),
              Text(
                label,
                style: TextStyle(
                  fontSize: AppFontSize.caption,
                  fontWeight: AppFontWeight.bold,
                  color: themeColors.subTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ［－］ボタン
              _buildStepButton(
                icon: Icons.remove,
                onPressed: onDecrement,
                themeColors: themeColors,
              ),
              const SizedBox(width: AppSpacing.xs),
              // 中央の数字枠（タップでテンキー入力）
              Expanded(
                child: InkWell(
                  onTap: onTapValue,
                  borderRadius: AppRadius.small,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E1E20)
                          : AppKendoColors.pureWhite,
                      borderRadius: AppRadius.small,
                      border: Border.all(
                        color: value != null
                            ? themeColors.primaryAccent
                            : (isDark
                                  ? const Color(0xFF38383A)
                                  : const Color(0x33000000)),
                        width: value != null ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          value != null ? '$value' : '-',
                          style: TextStyle(
                            fontSize: AppFontSize.title,
                            fontWeight: AppFontWeight.bold,
                            color: value != null
                                ? themeColors.primaryAccent
                                : themeColors.subTextColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          value != null
                              ? '$prefixText$value$suffixText'
                              : '未設定',
                          style: TextStyle(
                            fontSize: AppFontSize.micro,
                            fontWeight: AppFontWeight.semiBold,
                            color: themeColors.subTextColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              // ［＋］ボタン
              _buildStepButton(
                icon: Icons.add,
                onPressed: onIncrement,
                themeColors: themeColors,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepButton({
    required IconData icon,
    required VoidCallback onPressed,
    required AppThemeColors themeColors,
  }) {
    return Material(
      color: isDark ? const Color(0xFF1E1E20) : AppKendoColors.pureWhite,
      borderRadius: AppRadius.small,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadius.small,
        child: Container(
          width: 32,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: AppRadius.small,
            border: Border.all(
              color: isDark ? const Color(0xFF38383A) : const Color(0x22000000),
            ),
          ),
          child: Icon(icon, size: 18, color: themeColors.primaryAccent),
        ),
      ),
    );
  }

  void _showNumberInputDialog({
    required BuildContext context,
    required String title,
    required int? currentValue,
    required String suffix,
    required ValueChanged<int?> onConfirmed,
  }) {
    final controller = TextEditingController(
      text: currentValue != null ? '$currentValue' : '',
    );

    showAppDialog<void>(
      context: context,
      builder: (ctx) {
        final themeColors = ctx.appColors;
        return AppDialog(
          title: title,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppFontSize.title,
                  fontWeight: AppFontWeight.bold,
                  color: themeColors.primaryAccent,
                ),
                decoration: InputDecoration(
                  hintText: '例: 3',
                  suffixText: suffix,
                  filled: true,
                  fillColor: isDark
                      ? themeColors.inputBackground
                      : themeColors.cardBackground,
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.medium,
                    borderSide: BorderSide(color: themeColors.primaryAccent),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                onConfirmed(null);
                Navigator.pop(ctx);
              },
              child: Text(
                'クリア',
                style: TextStyle(color: themeColors.subTextColor),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColors.primaryAccent,
                foregroundColor: AppKendoColors.pureWhite,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
              ),
              onPressed: () {
                final text = controller.text.trim();
                final val = int.tryParse(text);
                onConfirmed(val);
                Navigator.pop(ctx);
              },
              child: const Text('決定'),
            ),
          ],
        );
      },
    );
  }
}
