import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/manual_help_button.dart';

/// 🥋 チーム登録画面 トップAppBar（戻るボタン ＆ マニュアルヘルプボタン付き）
class TeamRegistrationAppBar extends StatelessWidget {
  final VoidCallback onBack;

  const TeamRegistrationAppBar({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
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
          const Spacer(),
          const ManualHelpButton(
            manualPath: 'docs/manuals/operator/team_registration.md',
          ),
        ],
      ),
    );
  }
}
