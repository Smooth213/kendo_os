import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/tournament_repository.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';

class TournamentHeaderCard extends ConsumerWidget {
  final TournamentModel tournament;

  const TournamentHeaderCard({super.key, required this.tournament});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
    final cardColor = themeColors.cardBackground;
    final borderColor = isDark
        ? const Color(0xFF38383A)
        : AppKendoColors.grey.shade200;
    final textColor = context.appColors.textColor;
    final subTextColor = isDark
        ? const Color(0xFF8E8E93)
        : AppKendoColors.grey.shade700;
    final iconBgColor = isDark
        ? AppKendoColors.ipponGold.withValues(alpha: 0.3)
        : AppKendoColors.ipponGold;
    final popupIconColor = isDark
        ? AppKendoColors.grey.shade400
        : AppKendoColors.grey.shade500;
    final noteBgColor = isDark
        ? const Color(0xFF2C2C2E)
        : AppKendoColors.grey.shade50;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.medium,
        side: BorderSide(color: borderColor, width: isDark ? 0.5 : 1.0),
      ),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.roundValue),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    color: AppKendoColors.ipponGold,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    tournament.name,
                    style: TextStyle(
                      fontSize: AppFontSize.headline,
                      fontWeight: AppFontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                if (ref.watch(permissionProvider).canManageTournament)
                  IconButton(
                    icon: Icon(
                      Icons.more_horiz,
                      color: popupIconColor,
                      size: 28,
                    ),
                    onPressed: () => _showTournamentMenuBottomSheet(
                      context,
                      ref,
                      tournament,
                      cardColor,
                      textColor,
                      subTextColor,
                      borderColor,
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Divider(height: 1, color: borderColor),
            ),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: AppKendoColors.grey.shade500,
                  size: 16,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  DateFormat('yyyy年MM月dd日').format(tournament.date),
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: AppFontSize.bodySmall,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Icon(
                  Icons.location_on,
                  color: AppKendoColors.grey.shade500,
                  size: 16,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    tournament.venue,
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: AppFontSize.bodySmall,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (tournament.notes.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: noteBgColor,
                  borderRadius: AppRadius.small,
                ),
                child: Text(
                  tournament.notes,
                  style: TextStyle(
                    color: textColor,
                    fontSize: AppFontSize.bodySmall,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showTournamentMenuBottomSheet(
    BuildContext context,
    WidgetRef ref,
    TournamentModel tournament,
    Color cardColor,
    Color textColor,
    Color subTextColor,
    Color borderColor,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showAppBottomSheet(
      context: context,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : AppKendoColors.pureWhite,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xlargeValue),
          ),
        ),
        padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: 56),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: AppKendoColors.grey.shade400,
                  borderRadius: AppRadius.medium,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: AppKendoColors.indigo.withValues(alpha: 0.1),
                child: const Icon(Icons.edit, color: AppKendoColors.indigo),
              ),
              title: Text(
                '大会情報の編集',
                style: TextStyle(
                  fontWeight: AppFontWeight.bold,
                  color: textColor,
                ),
              ),
              subtitle: const Text(
                '大会名や会場、日付を変更します',
                style: TextStyle(
                  fontSize: AppFontSize.small,
                  color: AppKendoColors.grey,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _openEditTournamentDialog(
                  context,
                  ref,
                  tournament,
                  cardColor,
                  textColor,
                  subTextColor,
                  borderColor,
                );
              },
            ),
            if (ref.read(permissionProvider).canDeleteData) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Divider(height: 1, color: borderColor),
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppKendoColors.red.withValues(alpha: 0.1),
                  child: const Icon(Icons.delete, color: AppKendoColors.red),
                ),
                title: const Text(
                  'この大会を削除',
                  style: TextStyle(
                    color: AppKendoColors.red,
                    fontWeight: AppFontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  '関連するすべての試合も完全に削除されます',
                  style: TextStyle(
                    fontSize: AppFontSize.small,
                    color: AppKendoColors.grey,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeleteTournament(
                    context,
                    ref,
                    tournament,
                    cardColor,
                    textColor,
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openEditTournamentDialog(
    BuildContext context,
    WidgetRef ref,
    TournamentModel tournament,
    Color cardColor,
    Color textColor,
    Color subTextColor,
    Color borderColor,
  ) {
    final nameController = TextEditingController(text: tournament.name);
    final venueController = TextEditingController(text: tournament.venue);
    final notesController = TextEditingController(text: tournament.notes);
    DateTime selectedDate = tournament.date;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showAppDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AppDialog(
            title: '大会情報の編集',
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: '大会名',
                      labelStyle: TextStyle(color: subTextColor),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: borderColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
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
                              backgroundColor: cardColor,
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null && picked != selectedDate) {
                        setState(() => selectedDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: '開催年月日',
                        labelStyle: TextStyle(color: subTextColor),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: borderColor),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('yyyy年MM月dd日').format(selectedDate),
                            style: TextStyle(color: textColor),
                          ),
                          Icon(
                            Icons.calendar_today,
                            size: 20,
                            color: isDark
                                ? AppKendoColors.indigo.shade400
                                : AppKendoColors.indigo.shade600,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: venueController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: '会場・住所',
                      labelStyle: TextStyle(color: subTextColor),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: borderColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: notesController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: '大会メモ（任意）',
                      labelStyle: TextStyle(color: subTextColor),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: borderColor),
                      ),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'キャンセル',
                  style: TextStyle(color: AppKendoColors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppKendoColors.indigo.shade600,
                  foregroundColor: AppKendoColors.pureWhite,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.small),
                ),
                onPressed: () async {
                  await ref
                      .read(tournamentRepositoryProvider)
                      .updateTournamentDetails(
                        tournament.id,
                        name: nameController.text,
                        venue: venueController.text,
                        notes: notesController.text,
                        date: selectedDate,
                      );
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text(
                  '保存',
                  style: TextStyle(fontWeight: AppFontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteTournament(
    BuildContext context,
    WidgetRef ref,
    TournamentModel tournament,
    Color cardColor,
    Color textColor,
  ) async {
    final confirm = await showAppDialog<bool>(
      context: context,
      builder: (ctx) => AppDialog(
        titleIcon: Icons.warning_amber_rounded,
        iconColor: AppKendoColors.red,
        title: '大会削除の確認',
        content: Text(
          'この大会を削除しますか？\n（取り消しはできません）',
          style: TextStyle(color: textColor, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'キャンセル',
              style: TextStyle(color: AppKendoColors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppKendoColors.red,
              foregroundColor: AppKendoColors.pureWhite,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.small),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              '削除する',
              style: TextStyle(fontWeight: AppFontWeight.bold),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref
          .read(tournamentRepositoryProvider)
          .deleteTournament(tournament.id);
      if (context.mounted) context.go('/');
    }
  }
}
