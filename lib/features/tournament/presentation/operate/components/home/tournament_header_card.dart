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
import 'package:kendo_os/features/tournament/presentation/operate/components/home/tournament_edit_dialog.dart';

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
        : context.appColors.separatorColor;
    final textColor = context.appColors.textColor;
    final subTextColor = isDark
        ? const Color(0xFF8E8E93)
        : context.appColors.textColor;
    final iconBgColor = isDark
        ? context.appColors.primaryAccent.withValues(alpha: 0.3)
        : context.appColors.primaryAccent;
    final popupIconColor = isDark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF475569);
    final noteBgColor = isDark
        ? const Color(0xFF2C2C2E)
        : context.appColors.cardBackground;

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
                    color: Color(0xFFD97706),
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
                Icon(Icons.calendar_today, color: subTextColor, size: 16),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  DateFormat('yyyy年MM月dd日').format(tournament.date),
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: AppFontSize.bodySmall,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Icon(Icons.location_on, color: subTextColor, size: 16),
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
          color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF),
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
                  color: const Color(0x8A000000),
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
                TournamentEditDialog.show(
                  context: context,
                  ref: ref,
                  tournament: tournament,
                  cardColor: cardColor,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  borderColor: borderColor,
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
