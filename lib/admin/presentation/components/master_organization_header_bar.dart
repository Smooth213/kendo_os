import 'package:flutter/material.dart';
import 'package:kendo_os/admin/presentation/components/master_edit_organization_bottom_sheet.dart';
import 'package:kendo_os/admin/presentation/components/master_team_name_management_sheet.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';

/// 選手マスタ画面の所属道場名ヘッダーおよび学年別/カテゴリ別切替バー
class MasterOrganizationHeaderBar extends StatelessWidget {
  final String orgName;
  final List<PlayerModel> players;
  final int groupingMode;
  final bool isSelectionMode;
  final bool isReadOnly;
  final bool canManageMaster;
  final bool isDark;
  final Color primaryColor;
  final ValueChanged<int> onGroupingModeChanged;

  const MasterOrganizationHeaderBar({
    super.key,
    required this.orgName,
    required this.players,
    required this.groupingMode,
    required this.isSelectionMode,
    required this.isReadOnly,
    required this.canManageMaster,
    required this.isDark,
    required this.primaryColor,
    required this.onGroupingModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = context.appColors.textColor;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.lg,
            left: 32,
            right: 32,
            bottom: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(Icons.account_balance, color: primaryColor, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  orgName,
                  style: TextStyle(
                    fontSize: AppFontSize.headline,
                    fontWeight: AppFontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              if (!isSelectionMode && !isReadOnly && canManageMaster) ...[
                IconButton(
                  icon: Icon(
                    Icons.format_list_bulleted_add,
                    color: primaryColor.withValues(alpha: 0.7),
                  ),
                  tooltip: 'よく使うチーム名の管理',
                  onPressed: () => showAppBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    enableDrag: false,
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.85,
                    ),
                    builder: (ctx) =>
                        MasterTeamNameManagementSheet(orgName: orgName),
                  ),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(AppSpacing.sm),
                ),
                IconButton(
                  icon: Icon(
                    Icons.edit_note,
                    color: context.appColors.subTextColor,
                  ),
                  tooltip: '道場名・学校名を一括変更',
                  onPressed: () => MasterEditOrganizationBottomSheet.show(
                    context,
                    currentName: orgName,
                    players: players,
                  ),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(AppSpacing.sm),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.sm,
          ),
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('学年別')),
              ButtonSegment(value: 1, label: Text('カテゴリ別')),
            ],
            selected: {groupingMode},
            onSelectionChanged: (Set<int> newSelection) {
              onGroupingModeChanged(newSelection.first);
            },
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: isDark
                  ? const Color(0xFF9C27B0).withValues(alpha: 0.4)
                  : const Color(0xFF9C27B0),
              selectedForegroundColor: primaryColor,
              side: BorderSide(color: context.appColors.separatorColor),
            ),
          ),
        ),
      ],
    );
  }
}
