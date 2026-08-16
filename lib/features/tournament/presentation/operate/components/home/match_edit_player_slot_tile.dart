import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

/// 試合編集シートにおける各ポジションの赤・白選手入力スロットタイル（純粋UIコンポーネント）
class MatchEditPlayerSlotTile extends StatelessWidget {
  final String posLabel;
  final TextEditingController redController;
  final TextEditingController whiteController;
  final Color primaryAccent;
  final bool isDark;
  final Color textColor;

  const MatchEditPlayerSlotTile({
    super.key,
    required this.posLabel,
    required this.redController,
    required this.whiteController,
    required this.primaryAccent,
    required this.isDark,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF252527)
            : context.appColors.inputBackground,
        borderRadius: AppRadius.medium,
        border: Border.all(color: context.appColors.separatorColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            posLabel,
            style: TextStyle(
              fontSize: AppFontSize.small,
              fontWeight: AppFontWeight.bold,
              color: primaryAccent,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: redController,
                  style: const TextStyle(
                    color: AppKendoColors.red,
                    fontSize: AppFontSize.bodySmall,
                  ),
                  decoration: InputDecoration(
                    hintText: '赤 選手名',
                    filled: true,
                    fillColor: AppKendoColors.red.withAlpha(isDark ? 25 : 12),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: AppSpacing.sm,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.small,
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Text('vs', style: TextStyle(color: AppKendoColors.grey)),
              ),
              Expanded(
                child: AppTextField(
                  controller: whiteController,
                  style: TextStyle(
                    color: textColor,
                    fontSize: AppFontSize.bodySmall,
                  ),
                  decoration: InputDecoration(
                    hintText: '白 選手名',
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFFFFFFFF).withAlpha(15)
                        : const Color(0xFFF2F2F7),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: AppSpacing.sm,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.small,
                      borderSide: BorderSide.none,
                    ),
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
