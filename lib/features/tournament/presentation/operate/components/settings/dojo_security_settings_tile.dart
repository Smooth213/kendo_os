import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/settings/settings_ui_tiles.dart';
import 'package:kendo_os/security/dojo_security_repository.dart';
import 'package:kendo_os/security/pin_hasher.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/presentation/providers/auth_session_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_user_role_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_loading_indicator.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

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

/// 道場入室PINおよび各ロールPIN（Admin / Operator / Recorder）を変更するボトムシート
class DojoSecuritySettingsSheet extends ConsumerStatefulWidget {
  final String? initialCurrentAdminPin;

  const DojoSecuritySettingsSheet({super.key, this.initialCurrentAdminPin});

  static Future<bool?> show(
    BuildContext context, {
    String? initialCurrentAdminPin,
  }) {
    return showAppBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DojoSecuritySettingsSheet(
        initialCurrentAdminPin: initialCurrentAdminPin,
      ),
    );
  }

  @override
  ConsumerState<DojoSecuritySettingsSheet> createState() =>
      _DojoSecuritySettingsSheetState();
}

class _DojoSecuritySettingsSheetState
    extends ConsumerState<DojoSecuritySettingsSheet> {
  late final TextEditingController _currentAdminPinCtrl;
  final TextEditingController _newJoinPinCtrl = TextEditingController();
  final TextEditingController _newAdminPinCtrl = TextEditingController();
  final TextEditingController _newOperatorPinCtrl = TextEditingController();
  final TextEditingController _newRecorderPinCtrl = TextEditingController();

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentAdminPinCtrl = TextEditingController(
      text: widget.initialCurrentAdminPin ?? '',
    );
  }

  @override
  void dispose() {
    _currentAdminPinCtrl.dispose();
    _newJoinPinCtrl.dispose();
    _newAdminPinCtrl.dispose();
    _newOperatorPinCtrl.dispose();
    _newRecorderPinCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;
    final currentAdmin = _currentAdminPinCtrl.text.trim();
    if (!PinHasher.isValidRolePinFormat(currentAdmin)) {
      setState(() => _errorMessage = '現在の管理者(Admin) PIN（4桁数字）を入力してください');
      return;
    }

    final newJoin = _newJoinPinCtrl.text.trim();
    if (newJoin.isNotEmpty) {
      final joinCheck = PinHasher.validateJoinPinFormat(newJoin);
      if (!joinCheck.isValid) {
        setState(() => _errorMessage = '道場入室PIN: ${joinCheck.errorMessage}');
        return;
      }
    }

    final newRolePins = <UserRole, String>{};
    final roleInputs = {
      UserRole.admin: _newAdminPinCtrl.text.trim(),
      UserRole.operator: _newOperatorPinCtrl.text.trim(),
      UserRole.recorder: _newRecorderPinCtrl.text.trim(),
    };

    for (final entry in roleInputs.entries) {
      if (entry.value.isNotEmpty) {
        if (!PinHasher.isValidRolePinFormat(entry.value)) {
          setState(
            () =>
                _errorMessage = '${entry.key.displayName} のPINは4桁の数字で入力してください',
          );
          return;
        }
        newRolePins[entry.key] = entry.value;
      }
    }

    if (newJoin.isEmpty && newRolePins.isEmpty) {
      setState(() => _errorMessage = '変更したいPINを1つ以上入力してください');
      return;
    }

    final dojoId = ref.read(currentDojoIdProvider);
    final repo = ref.read(dojoSecurityRepositoryProvider);
    if (repo == null || dojoId.isEmpty || dojoId == 'default_dojo_room') {
      setState(() => _errorMessage = 'クラウド接続された道場ルームでのみ変更できます');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      String? uid;
      if (Firebase.apps.isNotEmpty) {
        uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null) {
          final cred = await FirebaseAuth.instance.signInAnonymously();
          uid = cred.user?.uid;
        }
      }

      final result = await repo.updateDojoSecurityPins(
        dojoId: dojoId,
        currentAdminPin: currentAdmin,
        newJoinPin: newJoin.isNotEmpty ? newJoin : null,
        newRolePins: newRolePins.isNotEmpty ? newRolePins : null,
        uid: uid ?? 'admin_terminal',
      );

      if (!mounted) return;

      if (!result.success) {
        setState(() {
          _isSaving = false;
          _errorMessage = result.errorMessage ?? 'PINの更新に失敗しました';
        });
        return;
      }

      if (result.newJoinPinHash != null) {
        ref
            .read(authSessionProvider.notifier)
            .updateJoinPinHash(dojoId, result.newJoinPinHash!);
      }

      Navigator.of(context).pop(true);
      AppSnackBar.showSuccess(context, '🔒 道場セキュリティPINを更新しました');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = '更新に失敗しました: $e';
      });
    }
  }

  Widget _buildPinField({
    required AppThemeColors themeColors,
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isNumeric4 = true,
    bool obscure = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: themeColors.textColor,
            fontSize: AppFontSize.bodySmall,
            fontWeight: AppFontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        AppTextField(
          controller: controller,
          obscureText: obscure,
          inputFormatters: [
            LengthLimitingTextInputFormatter(
              isNumeric4 ? 4 : PinHasher.maxJoinPinLength,
            ),
          ],
          keyboardType: isNumeric4 ? TextInputType.number : TextInputType.text,
          style: TextStyle(
            color: themeColors.textColor,
            fontWeight: AppFontWeight.bold,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: hint,
            hintStyle: TextStyle(color: themeColors.subTextColor),
            filled: true,
            fillColor: themeColors.inputBackground,
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.medium,
              borderSide: BorderSide(color: themeColors.separatorColor),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: AppRadius.medium,
              borderSide: BorderSide(color: AppKendoColors.purple),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
    final dojoId = ref.watch(currentDojoIdProvider);

    return AppBottomSheetContent(
      title: '道場セキュリティ・PIN設定',
      titleIcon: Icons.shield_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '対象道場: $dojoId\n変更したい項目だけ入力し、保存してください（空欄の項目は維持されます）。',
            style: TextStyle(
              color: themeColors.subTextColor,
              fontSize: AppFontSize.bodySmall,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildPinField(
            themeColors: themeColors,
            controller: _currentAdminPinCtrl,
            label: '現在の代表・管理者 (Admin) PIN（必須・確認用）',
            hint: '現在の4桁数字（初期値: 9999）',
            obscure: true,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildPinField(
            themeColors: themeColors,
            controller: _newJoinPinCtrl,
            label: '新しい道場入室PIN（合言葉）',
            hint: '変更する場合のみ入力（6文字以上の英数字推奨）',
            isNumeric4: false,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildPinField(
            themeColors: themeColors,
            controller: _newAdminPinCtrl,
            label: '新しい 代表・管理者 (Admin) PIN',
            hint: '変更する場合のみ4桁数字を入力',
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildPinField(
            themeColors: themeColors,
            controller: _newOperatorPinCtrl,
            label: '新しい 監督・引率責任者 (Operator) PIN',
            hint: '変更する場合のみ4桁数字を入力',
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildPinField(
            themeColors: themeColors,
            controller: _newRecorderPinCtrl,
            label: '新しい スコア・記録係 (Recorder) PIN',
            hint: '変更する場合のみ4桁数字を入力',
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: AppKendoColors.orangeAccent,
                fontSize: AppFontSize.bodySmall,
                fontWeight: AppFontWeight.bold,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          _isSaving
              ? const Center(
                  child: AppLoadingIndicator(color: AppKendoColors.purple),
                )
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppKendoColors.purple,
                    foregroundColor: AppKendoColors.pureWhite,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.medium,
                    ),
                  ),
                  onPressed: _handleSave,
                  child: const Text(
                    'PIN変更を保存する',
                    style: TextStyle(fontWeight: AppFontWeight.bold),
                  ),
                ),
        ],
      ),
    );
  }
}
