import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 大会新規作成: ステップ1（大会名・日付入力）
class CreateTournamentPage1 extends StatelessWidget {
  final TextEditingController nameController;
  final DateTime selectedDate;
  final VoidCallback onPickDate;

  const CreateTournamentPage1({
    super.key,
    required this.nameController,
    required this.selectedDate,
    required this.onPickDate,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color inputBgColor = isDark
        ? const Color(0xFF1C1C1E)
        : context.appColors.textColor;
    final Color textColor = context.appColors.textColor;
    final Color hintColor = isDark
        ? const Color(0xFF8E8E93)
        : const Color(0x8A000000);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        Text(
          '大会の名前と日付を\n教えてください',
          style: TextStyle(
            fontSize: AppFontSize.display,
            fontWeight: AppFontWeight.bold,
            height: 1.4,
            color: textColor,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        TextFormField(
          controller: nameController,
          style: TextStyle(color: textColor, fontWeight: AppFontWeight.bold),
          decoration: InputDecoration(
            labelText: '大会名',
            labelStyle: const TextStyle(color: AppKendoColors.grey),
            hintText: '例：第1回 〇〇剣道大会',
            hintStyle: TextStyle(
              color: hintColor,
              fontSize: AppFontSize.bodySmall,
            ),
            prefixIcon: const Icon(
              Icons.emoji_events,
              color: Color(0xFFD97706),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.medium,
              borderSide: BorderSide(
                color: isDark
                    ? const Color(0xFF38383A)
                    : const Color(0x33000000),
                width: 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.medium,
              borderSide: const BorderSide(
                color: Color(0xFF3F51B5),
                width: 2.0,
              ),
            ),
            filled: true,
            fillColor: inputBgColor,
          ),
          validator: (v) => v == null || v.isEmpty ? '大会名を入力してください' : null,
        ),
        const SizedBox(height: AppSpacing.xl),
        ListTile(
          title: const Text(
            '開催年月日',
            style: TextStyle(
              color: AppKendoColors.grey,
              fontSize: AppFontSize.small,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              DateFormat('yyyy年MM月dd日').format(selectedDate),
              style: TextStyle(
                fontSize: AppFontSize.header,
                fontWeight: AppFontWeight.bold,
                color: textColor,
              ),
            ),
          ),
          trailing: const Icon(
            Icons.calendar_today,
            color: AppKendoColors.indigo,
          ),
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: isDark ? const Color(0xFF38383A) : const Color(0x33000000),
              width: 1.0,
            ),
            borderRadius: AppRadius.medium,
          ),
          tileColor: inputBgColor,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          onTap: onPickDate,
        ),
      ],
    );
  }
}
