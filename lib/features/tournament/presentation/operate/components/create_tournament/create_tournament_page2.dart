import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 大会新規作成: ステップ2（会場・メモ入力）
class CreateTournamentPage2 extends StatelessWidget {
  final TextEditingController venueController;
  final TextEditingController notesController;
  final VoidCallback onOpenMap;

  const CreateTournamentPage2({
    super.key,
    required this.venueController,
    required this.notesController,
    required this.onOpenMap,
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
          '開催場所とメモを\n入力してください',
          style: TextStyle(
            fontSize: AppFontSize.display,
            fontWeight: AppFontWeight.bold,
            height: 1.4,
            color: textColor,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        TextFormField(
          controller: venueController,
          style: TextStyle(color: textColor, fontWeight: AppFontWeight.bold),
          decoration: InputDecoration(
            labelText: '会場・住所',
            labelStyle: const TextStyle(color: AppKendoColors.grey),
            hintText: '例：〇〇県立武道館',
            hintStyle: TextStyle(
              color: hintColor,
              fontSize: AppFontSize.bodySmall,
            ),
            prefixIcon: const Icon(
              Icons.location_on,
              color: AppKendoColors.blue,
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.map, color: AppKendoColors.blue),
              onPressed: onOpenMap,
              tooltip: '地図で場所を確認',
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
          validator: (v) => v == null || v.isEmpty ? '会場を入力してください' : null,
        ),
        const SizedBox(height: AppSpacing.xl),
        TextFormField(
          controller: notesController,
          maxLines: 4,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            labelText: '大会メモ（任意）',
            labelStyle: const TextStyle(color: AppKendoColors.grey),
            hintText: '例：駐車場は第2駐車場を利用。\n開場は8:30〜。',
            hintStyle: TextStyle(
              color: hintColor,
              fontSize: AppFontSize.bodySmall,
            ),
            prefixIcon: const Icon(Icons.note_alt, color: AppKendoColors.grey),
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
        ),
      ],
    );
  }
}
