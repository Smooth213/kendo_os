import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/admin/presentation/components/master_delete_dialog_helper.dart';
import 'package:kendo_os/admin/presentation/components/master_player_edit_bottom_sheet.dart';
import 'package:kendo_os/admin/presentation/components/master_player_grouping_helper.dart';
import 'package:kendo_os/admin/presentation/components/master_player_tile.dart';
import 'package:kendo_os/admin/presentation/screens/master_management_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';
import 'package:kendo_os/shared/widgets/app_loading_indicator.dart';

/// 卒業・OB/OGとしてアーカイブされた選手の一覧閲覧・現役復帰・編集・削除シート
class MasterGraduatedPlayersSheet extends ConsumerWidget {
  const MasterGraduatedPlayersSheet({super.key});

  static void show(BuildContext context) {
    showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      builder: (_) => const MasterGraduatedPlayersSheet(),
    );
  }

  Future<void> _confirmReactivatePlayer(
    BuildContext context,
    WidgetRef ref,
    PlayerModel player,
  ) async {
    final int? promotedGrade = (player.grade >= 0 && player.grade < 16)
        ? player.grade + 1
        : (player.grade == 16 ? 99 : null);
    final String promotedLabel = promotedGrade != null
        ? PlayerModel(
            id: '',
            lastName: '',
            firstName: '',
            lastNameKana: '',
            firstNameKana: '',
            grade: promotedGrade,
          ).gradeName
        : '一般';

    final int? chosenGrade = await showAppDialog<int?>(
      context: context,
      builder: (ctx) => AppDialog(
        titleIcon: Icons.restore,
        iconColor: AppKendoColors.successGreen,
        title: '現役への復帰',
        content: Text(
          '${player.name} さんを現役名簿へ復帰させます。\n復帰時の学年・区分を選択してください。',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, -1),
            child: const Text('キャンセル'),
          ),
          if (promotedGrade != null)
            TextButton(
              onPressed: () => Navigator.pop(ctx, 99),
              child: const Text('一般として復帰'),
            ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, promotedGrade ?? player.grade),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppKendoColors.successGreen,
              foregroundColor: AppKendoColors.pureWhite,
              shape: const StadiumBorder(),
              elevation: 0,
            ),
            child: Text(
              promotedGrade != null ? '$promotedLabel で復帰' : '現役へ復帰',
              style: const TextStyle(fontWeight: AppFontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (chosenGrade == null || chosenGrade == -1) return;

    final dojoId = ref.read(currentDojoIdProvider);
    final safeDojoId = dojoId.isNotEmpty ? dojoId : 'test201';
    FirebaseFirestore? firestore;
    try {
      firestore = ref.read(firestoreProvider);
    } catch (_) {}

    final repo = PlayerRepository(dojoId: safeDojoId, firestore: firestore);
    await repo.reactivatePlayer(player.id, nextGrade: chosenGrade);
    if (!context.mounted) return;
    AppSnackBar.showSuccess(context, '${player.name} さんを現役へ復帰しました');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerListAsync = ref.watch(playerListProvider);

    return AppBottomSheetContent(
      showDragHandle: true,
      title: '卒業・OB/OG名簿',
      child: playerListAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.xxl),
          child: Center(child: AppLoadingIndicator()),
        ),
        error: (err, _) => Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text('読み込みエラー: $err'),
        ),
        data: (allPlayers) {
          final graduatedPlayers = allPlayers
              .where((p) => p.isGraduated)
              .toList();

          if (graduatedPlayers.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.xxl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 48,
                    color: context.appColors.subTextColor,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    '卒業・OB/OGとしてアーカイブされた選手はまだいません',
                    style: TextStyle(
                      fontSize: AppFontSize.body,
                      color: context.appColors.subTextColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '新年度の一括進級や選手編集から卒業（OB/OG）へ移動できます。',
                    style: TextStyle(
                      fontSize: AppFontSize.small,
                      color: context.appColors.subTextColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final grouped = MasterPlayerGroupingHelper.groupGraduatedPlayers(
            players: graduatedPlayers,
          );
          final groupKeys = grouped.keys.toList();

          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.68,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.xs,
                  ),
                  child: Text(
                    '計 ${graduatedPlayers.length}名 ・ 左スワイプで現役復帰・編集・削除ができます',
                    style: TextStyle(
                      fontSize: AppFontSize.small,
                      color: context.appColors.subTextColor,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                    itemCount: groupKeys.length,
                    itemBuilder: (context, index) {
                      final groupName = groupKeys[index];
                      final items = grouped[groupName]!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              top: AppSpacing.lg,
                              bottom: AppSpacing.sm,
                              left: AppSpacing.xl,
                            ),
                            child: Text(
                              groupName,
                              style: TextStyle(
                                fontSize: AppFontSize.bodySmall,
                                fontWeight: AppFontWeight.semiBold,
                                color: context.appColors.subTextColor,
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                            ),
                            decoration: BoxDecoration(
                              color: context.appColors.cardBackground,
                              borderRadius: AppRadius.medium,
                              border: Border.all(
                                color: context.appColors.separatorColor
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              children: items.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final player = entry.value;
                                final isLast = idx == items.length - 1;
                                return Column(
                                  children: [
                                    MasterPlayerTile(
                                      player: player,
                                      isReadOnly: false,
                                      canManageMaster: true,
                                      isSelectionMode: false,
                                      isSelected: false,
                                      onEdit: () =>
                                          MasterPlayerEditBottomSheet.show(
                                            context,
                                            player: player,
                                            cloudDojoName: player.organization,
                                          ),
                                      onDelete: () =>
                                          MasterDeleteDialogHelper.confirmSingleDelete(
                                            context,
                                            ref,
                                            player,
                                          ),
                                      onReactivate: () =>
                                          _confirmReactivatePlayer(
                                            context,
                                            ref,
                                            player,
                                          ),
                                    ),
                                    if (!isLast)
                                      Divider(
                                        height: 1,
                                        thickness: 1,
                                        color: context.appColors.separatorColor,
                                        indent: 68,
                                      ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
