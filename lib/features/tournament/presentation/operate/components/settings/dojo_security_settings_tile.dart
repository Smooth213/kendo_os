import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/settings/dojo_security_settings_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/settings/settings_ui_tiles.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_user_role_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

export 'package:kendo_os/features/tournament/presentation/operate/components/settings/dojo_security_settings_sheet.dart';

/// 設定画面に配置する管理者限定の「道場PIN・ロールPIN設定」セクション
class DojoSecuritySettingsSection extends ConsumerWidget {
  final bool enableLiquidGlass;
  final AppThemeColors themeColors;

  const DojoSecuritySettingsSection({
    super.key,
    required this.enableLiquidGlass,
    required this.themeColors,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRole = ref.watch(currentUserRoleProvider);
    if (currentRole != UserRole.admin) {
      return const SizedBox.shrink();
    }

    final dojoId = ref.watch(currentDojoIdProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SettingsSectionHeader(title: '道場セキュリティ・PIN管理（管理者限定）'),
        SettingsBlock(
          enableLiquidGlass: enableLiquidGlass,
          themeColors: themeColors,
          children: [
            SettingsListTile(
              title: '道場入室PIN・ロールPINの変更',
              subtitle: dojoId.isNotEmpty
                  ? '対象道場: $dojoId の入室PINと権限PINを変更'
                  : '道場ID別の入室PINと権限PINを変更',
              icon: Icons.admin_panel_settings_rounded,
              iconBgColor: AppKendoColors.purple,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => DojoSecuritySettingsSheet.show(context),
            ),
          ],
        ),
        const SettingsSectionFooter(
          text:
              '※ 道場入室PIN（合言葉）を変更すると、次回以降に別の端末から入室する際から新しいPINが必要になります。\n'
              '※ 権限PIN（Admin / Operator / Recorder）は4桁の数字で個別に変更できます。',
        ),
      ],
    );
  }
}
