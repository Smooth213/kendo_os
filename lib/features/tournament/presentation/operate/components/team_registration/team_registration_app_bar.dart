import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';
import 'package:kendo_os/shared/widgets/manual_help_button.dart';

/// 🥋 チーム登録画面 トップAppBar（戻るボタン ＆ マニュアルヘルプボタン付き）
class TeamRegistrationAppBar extends StatelessWidget {
  final VoidCallback onBack;
  final int registeredTeamCount;
  final VoidCallback? onViewRegisteredTeams;
  final String? editingTeamName;

  const TeamRegistrationAppBar({
    super.key,
    required this.onBack,
    this.registeredTeamCount = 0,
    this.onViewRegisteredTeams,
    this.editingTeamName,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = context.appColors.primaryAccent;

    return Container(
      padding: const EdgeInsets.only(
        top: AppSpacing.sm,
        bottom: AppSpacing.sm,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: context.appColors.iconColor,
              size: 24,
            ),
            onPressed: onBack,
          ),
          if (editingTeamName != null && editingTeamName!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.largeValue),
                border: Border.all(color: accentColor.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit, size: 14, color: accentColor),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '編集中: $editingTeamName',
                    style: TextStyle(
                      fontSize: AppFontSize.caption,
                      fontWeight: AppFontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Spacer(),
          if (registeredTeamCount > 0 && onViewRegisteredTeams != null) ...[
            AppActionChip(
              icon: Icons.groups,
              label: Text('登録済 ($registeredTeamCount)'),
              onPressed: onViewRegisteredTeams,
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          const ManualHelpButton(
            manualPath: 'docs/manuals/operator/team_registration.md',
          ),
        ],
      ),
    );
  }
}
