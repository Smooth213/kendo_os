import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

/// 大会情報の基本入力フィールド（大会名、日付、会場）
class TournamentEditBasicFields extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController venueController;
  final DateTime selectedDate;
  final Color effectiveTextColor;
  final Color effectiveSubTextColor;
  final Color effectiveBorderColor;
  final VoidCallback onPickDate;

  const TournamentEditBasicFields({
    super.key,
    required this.nameController,
    required this.venueController,
    required this.selectedDate,
    required this.effectiveTextColor,
    required this.effectiveSubTextColor,
    required this.effectiveBorderColor,
    required this.onPickDate,
  });

  InputDecoration _buildInputDecoration({
    required String labelText,
    required IconData icon,
  }) => InputDecoration(
    labelText: labelText,
    labelStyle: TextStyle(color: effectiveSubTextColor),
    prefixIcon: Icon(icon, size: 20),
    enabledBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: effectiveBorderColor),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 大会名入力
        AppTextField(
          controller: nameController,
          style: TextStyle(color: effectiveTextColor),
          decoration: _buildInputDecoration(
            labelText: '大会名',
            icon: Icons.emoji_events_outlined,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // 開催年月日選択
        InkWell(
          onTap: onPickDate,
          child: InputDecorator(
            decoration: _buildInputDecoration(
              labelText: '開催年月日',
              icon: Icons.calendar_today_outlined,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('yyyy年MM月dd日').format(selectedDate),
                  style: TextStyle(color: effectiveTextColor),
                ),
                const Icon(Icons.arrow_drop_down, color: AppKendoColors.indigo),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // 会場・住所入力
        AppTextField(
          controller: venueController,
          style: TextStyle(color: effectiveTextColor),
          decoration: _buildInputDecoration(
            labelText: '会場・住所',
            icon: Icons.location_on_outlined,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}
