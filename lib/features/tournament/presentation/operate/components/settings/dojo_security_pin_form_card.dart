import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_loading_indicator.dart';
import 'package:kendo_os/shared/widgets/dojo_security_form_widgets.dart';

/// Step 1: 現在の Admin PIN による本人確認および Google リカバリ導線カード
class DojoAdminUnlockCard extends StatelessWidget {
  final AppThemeColors themeColors;
  final TextEditingController controller;
  final bool obscurePin;
  final bool isBusy;
  final VoidCallback onToggleObscure;
  final VoidCallback onUnlock;
  final VoidCallback onOpenRecovery;

  const DojoAdminUnlockCard({
    super.key,
    required this.themeColors,
    required this.controller,
    required this.obscurePin,
    required this.isBusy,
    required this.onToggleObscure,
    required this.onUnlock,
    required this.onOpenRecovery,
  });

  @override
  Widget build(BuildContext context) {
    return DojoSecuritySectionCard(
      themeColors: themeColors,
      title: '1. 本人確認（必須）',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DojoSecurityField(
            themeColors: themeColors,
            controller: controller,
            label: '現在の代表・管理者 (Admin) PIN',
            hint: '現在の4桁数字（初期値: 9999）',
            prefixIcon: Icons.verified_user_outlined,
            obscure: obscurePin,
            onToggleObscure: onToggleObscure,
            onSubmitted: (_) => onUnlock(),
          ),
          const SizedBox(height: AppSpacing.md),
          isBusy
              ? const Center(
                  child: AppLoadingIndicator(color: AppKendoColors.purple),
                )
              : ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppKendoColors.purple,
                    foregroundColor: AppKendoColors.pureWhite,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    shape: const StadiumBorder(),
                  ),
                  onPressed: onUnlock,
                  icon: const Icon(Icons.lock_open_rounded, size: 18),
                  label: const Text(
                    '本人確認して現在のPINを表示',
                    style: TextStyle(
                      fontSize: AppFontSize.body,
                      fontWeight: AppFontWeight.bold,
                    ),
                  ),
                ),
          const SizedBox(height: AppSpacing.xs),
          TextButton(
            onPressed: isBusy ? null : onOpenRecovery,
            child: const Text(
              'PINを忘れた場合（代表者Googleで初期化）',
              style: TextStyle(
                color: AppKendoColors.teal,
                fontSize: AppFontSize.small,
                fontWeight: AppFontWeight.semiBold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Admin 本人確認通過後に、設定済み全PINを確認・編集して保存するカード
class DojoSecurityPinFormCard extends StatelessWidget {
  final AppThemeColors themeColors;
  final TextEditingController joinPinController;
  final TextEditingController adminPinController;
  final TextEditingController operatorPinController;
  final TextEditingController recorderPinController;
  final bool hidePins;
  final bool isBusy;
  final VoidCallback onToggleHidePins;
  final VoidCallback onSave;

  const DojoSecurityPinFormCard({
    super.key,
    required this.themeColors,
    required this.joinPinController,
    required this.adminPinController,
    required this.operatorPinController,
    required this.recorderPinController,
    required this.hidePins,
    required this.isBusy,
    required this.onToggleHidePins,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final roleFields = [
      (
        ctrl: adminPinController,
        label: '代表・管理者 (Admin) PIN',
        hint: '4桁数字',
        icon: Icons.admin_panel_settings_outlined,
      ),
      (
        ctrl: operatorPinController,
        label: '監督・引率責任者 (Operator) PIN',
        hint: '4桁数字（空欄は維持）',
        icon: Icons.supervisor_account_outlined,
      ),
      (
        ctrl: recorderPinController,
        label: 'スコア・記録係 (Recorder) PIN',
        hint: '4桁数字（空欄は維持）',
        icon: Icons.edit_note_outlined,
      ),
    ];

    return DojoSecuritySectionCard(
      themeColors: themeColors,
      title: '2. 現在のPIN確認・変更',
      trailing: IconButton(
        tooltip: hidePins ? 'PINを表示' : 'PINを隠す',
        icon: Icon(
          hidePins ? Icons.visibility_off : Icons.visibility,
          size: 18,
          color: themeColors.subTextColor,
        ),
        onPressed: onToggleHidePins,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DojoSecurityField(
            themeColors: themeColors,
            controller: joinPinController,
            label: '道場入室PIN（合言葉）',
            hint: '6文字以上の英数字推奨（空欄は維持）',
            prefixIcon: Icons.vpn_key_outlined,
            isNumeric4: false,
            obscure: hidePins,
          ),
          Divider(
            height: AppSpacing.xl,
            color: themeColors.separatorColor.withValues(alpha: 0.45),
          ),
          for (int i = 0; i < roleFields.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            DojoSecurityField(
              themeColors: themeColors,
              controller: roleFields[i].ctrl,
              label: roleFields[i].label,
              hint: roleFields[i].hint,
              prefixIcon: roleFields[i].icon,
              obscure: hidePins,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          isBusy
              ? const Center(
                  child: AppLoadingIndicator(color: AppKendoColors.purple),
                )
              : ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppKendoColors.purple,
                    foregroundColor: AppKendoColors.pureWhite,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    shape: const StadiumBorder(),
                  ),
                  onPressed: onSave,
                  icon: const Icon(Icons.lock_reset_rounded, size: 18),
                  label: const Text(
                    'PIN変更を保存する',
                    style: TextStyle(
                      fontSize: AppFontSize.body,
                      fontWeight: AppFontWeight.bold,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
