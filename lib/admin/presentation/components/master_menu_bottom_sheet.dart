import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/admin/presentation/components/master_annual_promotion_sheet.dart';
import 'package:kendo_os/admin/presentation/components/master_data_cleanup_dialog.dart';
import 'package:kendo_os/admin/presentation/components/master_graduated_players_sheet.dart';
import 'package:kendo_os/admin/presentation/screens/master_management_screen.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';

/// 選手マスタ画面の管理メニューボトムシート（データクリーンアップ・一括進級）
class MasterMenuBottomSheet {
  static void show(BuildContext context, WidgetRef ref) {
    final themeColors = context.appColors;

    showAppBottomSheet(
      context: context,
      builder: (ctx) => AppBottomSheetContent(
        showDragHandle: true,
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppKendoColors.purple.withValues(alpha: 0.1),
                  child: const Icon(
                    Icons.cleaning_services,
                    color: AppKendoColors.purple,
                  ),
                ),
                title: Text(
                  'データとストレージ管理',
                  style: TextStyle(
                    fontWeight: AppFontWeight.bold,
                    color: themeColors.textColor,
                  ),
                ),
                subtitle: const Text(
                  'キャッシュクリアやデータのエクスポート・整理を行います',
                  style: TextStyle(
                    fontSize: AppFontSize.small,
                    color: AppKendoColors.grey,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  showAppDialog(
                    context: context,
                    builder: (dialogCtx) => const MasterDataCleanupDialog(),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Divider(height: 1, color: themeColors.separatorColor),
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppKendoColors.indigo.withValues(alpha: 0.1),
                  child: const Icon(Icons.school, color: AppKendoColors.indigo),
                ),
                title: Text(
                  '新年度の一括進級',
                  style: TextStyle(
                    fontWeight: AppFontWeight.bold,
                    color: themeColors.textColor,
                  ),
                ),
                subtitle: const Text(
                  '卒業ライン選択・卒業生アーカイブ・学年繰り上げを行います',
                  style: TextStyle(
                    fontSize: AppFontSize.small,
                    color: AppKendoColors.grey,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _openAnnualPromotionSheet(context, ref);
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Divider(height: 1, color: themeColors.separatorColor),
              ),
              Consumer(
                builder: (_, consumerRef, _) {
                  final graduatedCount =
                      consumerRef
                          .watch(playerListProvider)
                          .value
                          ?.where((p) => p.isGraduated)
                          .length ??
                      0;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppKendoColors.teal.withValues(
                        alpha: 0.1,
                      ),
                      child: const Icon(
                        Icons.history_edu,
                        color: AppKendoColors.teal,
                      ),
                    ),
                    title: Text(
                      '卒業・OB/OG名簿（$graduatedCount名）',
                      style: TextStyle(
                        fontWeight: AppFontWeight.bold,
                        color: themeColors.textColor,
                      ),
                    ),
                    subtitle: const Text(
                      'アーカイブされた卒業生の閲覧・現役復帰を行います',
                      style: TextStyle(
                        fontSize: AppFontSize.small,
                        color: AppKendoColors.grey,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      MasterGraduatedPlayersSheet.show(context);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _openAnnualPromotionSheet(BuildContext context, WidgetRef ref) {
    MasterAnnualPromotionSheet.show(
      context,
      onExecutePromotion:
          ({
            required graduationType,
            required retainPlayerIds,
            required graduationFiscalYear,
            required promotionFiscalYear,
          }) {
            return ref
                .read(playerRepositoryProvider)
                .promoteAllPlayers(
                  organization: null,
                  graduationType: graduationType,
                  retainPlayerIds: retainPlayerIds,
                  graduationFiscalYear: graduationFiscalYear,
                  promotionFiscalYear: promotionFiscalYear,
                  recordOrganizationHistory: true,
                );
          },
    );
  }
}
