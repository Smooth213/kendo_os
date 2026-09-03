import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/tournament_repository.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

/// 大会情報の編集ダイアログ
class TournamentEditDialog extends StatefulWidget {
  final TournamentModel tournament;
  final WidgetRef ref;
  final Color cardColor;
  final Color textColor;
  final Color subTextColor;
  final Color borderColor;

  const TournamentEditDialog({
    super.key,
    required this.tournament,
    required this.ref,
    required this.cardColor,
    required this.textColor,
    required this.subTextColor,
    required this.borderColor,
  });

  static Future<void> show({
    required BuildContext context,
    required WidgetRef ref,
    required TournamentModel tournament,
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
    required Color borderColor,
  }) {
    return showAppDialog(
      context: context,
      builder: (ctx) => TournamentEditDialog(
        tournament: tournament,
        ref: ref,
        cardColor: cardColor,
        textColor: textColor,
        subTextColor: subTextColor,
        borderColor: borderColor,
      ),
    );
  }

  @override
  State<TournamentEditDialog> createState() => _TournamentEditDialogState();
}

class _TournamentEditDialogState extends State<TournamentEditDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _venueController;
  late final TextEditingController _notesController;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.tournament.name);
    _venueController = TextEditingController(text: widget.tournament.venue);
    _notesController = TextEditingController(text: widget.tournament.notes);
    _selectedDate = widget.tournament.date;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _venueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppDialog(
      title: '大会情報の編集',
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: _nameController,
              style: TextStyle(color: widget.textColor),
              decoration: InputDecoration(
                labelText: '大会名',
                labelStyle: TextStyle(color: widget.subTextColor),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: widget.borderColor),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            InkWell(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                  builder: (context, child) => Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: AppKendoColors.indigo,
                        onPrimary: AppKendoColors.pureWhite,
                        onSurface: context.appColors.textColor,
                      ),
                      dialogTheme: DialogThemeData(
                        backgroundColor: widget.cardColor,
                      ),
                    ),
                    child: child!,
                  ),
                );
                if (picked != null && picked != _selectedDate) {
                  setState(() => _selectedDate = picked);
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: '開催年月日',
                  labelStyle: TextStyle(color: widget.subTextColor),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: widget.borderColor),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('yyyy年MM月dd日').format(_selectedDate),
                      style: TextStyle(color: widget.textColor),
                    ),
                    Icon(
                      Icons.calendar_today,
                      size: 20,
                      color: isDark
                          ? const Color(0xFF3F51B5)
                          : const Color(0xFF3F51B5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _venueController,
              style: TextStyle(color: widget.textColor),
              decoration: InputDecoration(
                labelText: '会場・住所',
                labelStyle: TextStyle(color: widget.subTextColor),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: widget.borderColor),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _notesController,
              style: TextStyle(color: widget.textColor),
              decoration: InputDecoration(
                labelText: '大会メモ（任意）',
                labelStyle: TextStyle(color: widget.subTextColor),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: widget.borderColor),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'キャンセル',
            style: TextStyle(color: AppKendoColors.grey),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3F51B5),
            foregroundColor: AppKendoColors.pureWhite,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.small),
          ),
          onPressed: () async {
            await widget.ref
                .read(tournamentRepositoryProvider)
                .updateTournamentDetails(
                  widget.tournament.id,
                  name: _nameController.text,
                  venue: _venueController.text,
                  notes: _notesController.text,
                  date: _selectedDate,
                );
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text(
            '保存',
            style: TextStyle(fontWeight: AppFontWeight.bold),
          ),
        ),
      ],
    );
  }
}
