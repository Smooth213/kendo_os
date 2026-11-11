import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/settings/dojo_security_settings_tile.dart';
import 'package:kendo_os/security/dojo_security_repository.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';

/// 初回 Admin 入室時のみ表示する「ロールPIN変更案内」ダイアログの選択結果
enum InitialRolePinPromptAction { changeNow, keepDefault }

/// 最初に Admin として入室したタイミングで1度だけ表示し、
/// 初期ロールPIN（9999 / 2468 / 1357）を変更するかそのまま使うかを選ばせるダイアログ。
class InitialRolePinPromptDialog extends StatelessWidget {
  final String dojoId;

  const InitialRolePinPromptDialog({super.key, required this.dojoId});

  static Future<InitialRolePinPromptAction?> show(
    BuildContext context, {
    required String dojoId,
  }) {
    return showAppDialog<InitialRolePinPromptAction>(
      context: context,
      barrierDismissible: false,
      builder: (_) => InitialRolePinPromptDialog(dojoId: dojoId),
    );
  }

  /// 初回Adminログイン時に必要に応じて変更案内ダイアログを表示し、完了フラグを記録する
  static Future<void> maybePromptAfterAdminLogin(
    BuildContext context, {
    required String dojoId,
    required String currentAdminPin,
    required DojoSecurityRepository? repository,
  }) async {
    if (repository == null || dojoId.isEmpty || dojoId == 'default_dojo_room') {
      return;
    }
    final needsPrompt = await repository.needsInitialAdminRolePinPrompt(dojoId);
    if (!needsPrompt || !context.mounted) return;

    final action = await show(context, dojoId: dojoId);
    if (!context.mounted) return;

    if (action == InitialRolePinPromptAction.changeNow) {
      await DojoSecuritySettingsSheet.show(
        context,
        initialCurrentAdminPin: currentAdminPin,
      );
    }
    await repository.markRolePinPromptCompleted(dojoId);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    return AppDialog(
      title: '権限PINの設定確認（初回のみ）',
      titleIcon: Icons.admin_panel_settings_rounded,
      iconColor: AppKendoColors.purple,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '道場 [ $dojoId ] の管理者として初めて入室しました。\n\n'
            '現在の操作権限PINは初期値（Admin: 9999 / Operator: 2468 / Recorder: 1357）に設定されています。\n'
            '道場内の保護者や生徒による誤操作を防ぐため、専用の4桁PINに変更しますか？\n\n'
            '※ この案内は初回のみ表示されます。後から「システム設定」画面でも変更できます。',
            style: TextStyle(
              color: themeColors.subTextColor,
              fontSize: AppFontSize.bodySmall,
              height: 1.5,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(InitialRolePinPromptAction.keepDefault),
          child: Text(
            '初期PINのまま使う',
            style: TextStyle(
              color: themeColors.subTextColor,
              fontWeight: AppFontWeight.bold,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppKendoColors.purple,
            foregroundColor: AppKendoColors.pureWhite,
            elevation: 0,
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.medium),
          ),
          onPressed: () =>
              Navigator.of(context).pop(InitialRolePinPromptAction.changeNow),
          child: const Text(
            '今すぐ変更する',
            style: TextStyle(fontWeight: AppFontWeight.bold),
          ),
        ),
      ],
    );
  }
}
