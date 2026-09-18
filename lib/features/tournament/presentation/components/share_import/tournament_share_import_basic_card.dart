import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kendo_os/features/tournament/presentation/components/share_import/tournament_share_import_cards.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

/// 🥋 大会・オーダー取り込みの大綱情報（大会名、開催日、会場）カード
class TournamentShareImportBasicCard extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController venueController;
  final DateTime? selectedDate;
  final VoidCallback onPickDate;
  final Color accentColor;
  final Color cardColor;
  final Color textColor;
  final Color subTextColor;

  const TournamentShareImportBasicCard({
    super.key,
    required this.nameController,
    required this.venueController,
    required this.selectedDate,
    required this.onPickDate,
    required this.accentColor,
    required this.cardColor,
    required this.textColor,
    required this.subTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return ShareImportInfoCard(
      title: '大会基本情報',
      icon: Icons.emoji_events_outlined,
      accentColor: accentColor,
      cardColor: cardColor,
      textColor: textColor,
      subTextColor: subTextColor,
      children: [
        AppTextField(
          controller: nameController,
          style: TextStyle(
            fontSize: AppFontSize.body,
            fontWeight: AppFontWeight.bold,
            color: textColor,
          ),
          decoration: const InputDecoration(
            labelText: '大会名',
            prefixIcon: Icon(Icons.title),
            isDense: true,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onPickDate,
                borderRadius: BorderRadius.circular(AppRadius.smallValue),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: '開催日',
                    prefixIcon: Icon(Icons.calendar_today),
                    isDense: true,
                  ),
                  child: Text(
                    selectedDate != null
                        ? DateFormat(
                            'yyyy年M月d日 (E)',
                            'ja',
                          ).format(selectedDate!)
                        : '未設定 (タップして選択)',
                    style: TextStyle(
                      color: selectedDate != null ? textColor : subTextColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: venueController,
          style: TextStyle(fontSize: AppFontSize.body, color: textColor),
          decoration: const InputDecoration(
            labelText: '会場',
            prefixIcon: Icon(Icons.place_outlined),
            isDense: true,
          ),
        ),
      ],
    );
  }
}
