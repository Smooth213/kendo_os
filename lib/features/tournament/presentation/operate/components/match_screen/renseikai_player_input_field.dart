import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

/// 錬成会画面のチーム別選手選択チップ＆入力フィールド
class RenseikaiPlayerInputField extends StatelessWidget {
  final String teamName;
  final List<String> players;
  final Set<String> masterSet;
  final TextEditingController controller;
  final bool isDark;
  final Color textColor;
  final Color inputBgColor;
  final Color borderColor;
  final ValueChanged<String> onPlayerSelected;

  const RenseikaiPlayerInputField({
    super.key,
    required this.teamName,
    required this.players,
    required this.masterSet,
    required this.controller,
    required this.isDark,
    required this.textColor,
    required this.inputBgColor,
    required this.borderColor,
    required this.onPlayerSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (players.isNotEmpty) ...[
          Text(
            '$teamName の選手を選択:',
            style: const TextStyle(
              fontSize: AppFontSize.bodySmall,
              color: Color(0xFF009688),
              fontWeight: AppFontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: players.map((p) {
              final isMaster = masterSet.contains(p);
              final isSelected = controller.text == p;

              return AppChoiceChip(
                label: Text(p),
                selected: isSelected,
                selectedColor: const Color(0xFF009688),
                backgroundColor: isSelected
                    ? const Color(0xFF009688)
                    : (isMaster
                          ? (isDark
                                ? const Color(0xFF2C2C2E)
                                : context.appColors.inputBackground)
                          : (isDark
                                ? const Color(0xFF1E1E20)
                                : context.appColors.cardBackground)),
                side: BorderSide(
                  color: isSelected
                      ? AppKendoColors.transparent
                      : (isMaster
                            ? AppKendoColors.transparent
                            : (context.appColors.separatorColor)),
                  width: 1.0,
                ),
                labelStyle: TextStyle(
                  color: isSelected
                      ? AppKendoColors.pureWhite
                      : (isMaster ? textColor : context.appColors.subTextColor),
                  fontWeight: AppFontWeight.bold,
                ),
                onSelected: (selected) {
                  if (selected) {
                    onPlayerSelected(p);
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        AppTextField(
          controller: controller,
          style: TextStyle(color: textColor, fontWeight: AppFontWeight.bold),
          onChanged: (_) {},
          decoration: InputDecoration(
            labelText: '$teamName の選手名を入力',
            labelStyle: const TextStyle(color: AppKendoColors.grey),
            filled: true,
            fillColor: inputBgColor,
            contentPadding: const EdgeInsets.symmetric(
              vertical: AppSpacing.lg,
              horizontal: AppSpacing.lg,
            ),
            prefixIcon: const Icon(Icons.person_outline, size: 20),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.medium,
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.medium,
              borderSide: const BorderSide(color: Color(0xFF009688), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
