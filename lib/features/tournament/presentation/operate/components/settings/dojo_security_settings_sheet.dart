import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/auth/application/google_auth_service.dart';
import 'package:kendo_os/features/auth/presentation/widgets/dojo_pin_recovery_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/settings/dojo_owner_accounts_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/settings/dojo_security_pin_form_card.dart';
import 'package:kendo_os/security/dojo_join_access_storage.dart';
import 'package:kendo_os/security/dojo_owner_recovery_repository.dart';
import 'package:kendo_os/security/dojo_security_repository.dart';
import 'package:kendo_os/security/pin_hasher.dart';
import 'package:kendo_os/security/pin_vault_cipher.dart';
import 'package:kendo_os/security/viewer_share_models.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/presentation/providers/auth_session_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/dojo_security_form_widgets.dart';

/// 道場入室PIN・各ロールPIN確認/変更および代表者Googleアカウント管理ボトムシート
class DojoSecuritySettingsSheet extends ConsumerStatefulWidget {
  final String? initialCurrentAdminPin;

  const DojoSecuritySettingsSheet({super.key, this.initialCurrentAdminPin});

  static Future<bool?> show(
    BuildContext context, {
    String? initialCurrentAdminPin,
  }) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    return showAppBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(maxHeight: screenHeight * 0.88),
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
  final _newJoinPinCtrl = TextEditingController();
  final _newAdminPinCtrl = TextEditingController();
  final _newOperatorPinCtrl = TextEditingController();
  final _newRecorderPinCtrl = TextEditingController();

  bool _obscureCurrentAdmin = true;
  bool _hideUnlockedPins = false;
  bool _isUnlocked = false;
  bool _isLegacyUnmigrated = false;
  bool _isBusy = false;
  bool _isUpdatingOwners = false;
  String? _errorMessage;
  String? _verifiedAdminPin;
  DojoPinVaultPayload? _unlockedVault;
  List<DojoOwnerAccount> _owners = const [];

  @override
  void initState() {
    super.initState();
    _currentAdminPinCtrl = TextEditingController(
      text: widget.initialCurrentAdminPin ?? '',
    );
    if (widget.initialCurrentAdminPin != null &&
        PinHasher.isValidRolePinFormat(widget.initialCurrentAdminPin!)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _handleUnlockVault();
      });
    }
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

  Future<String> _ensureUid() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        var uid = FirebaseAuth.instance.currentUser?.uid;
        uid ??= (await FirebaseAuth.instance.signInAnonymously()).user?.uid;
        if (uid != null && uid.isNotEmpty) return uid;
      }
    } catch (_) {}
    return 'admin_terminal';
  }

  String? _currentSignedInGoogleEmail() {
    try {
      if (Firebase.apps.isEmpty) return null;
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.isAnonymous) return null;
      return user.email;
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleUnlockVault() async {
    if (_isBusy) return;
    final adminPin = _currentAdminPinCtrl.text.trim();
    if (!PinHasher.isValidRolePinFormat(adminPin)) {
      setState(() => _errorMessage = '現在の管理者(Admin) PIN（4桁数字）を入力してください');
      return;
    }

    final dojoId = ref.read(currentDojoIdProvider);
    final securityRepo = ref.read(dojoSecurityRepositoryProvider);
    final recoveryRepo = ref.read(dojoOwnerRecoveryRepositoryProvider);
    if (securityRepo == null ||
        dojoId.isEmpty ||
        dojoId == 'default_dojo_room') {
      setState(() => _errorMessage = 'クラウド接続された道場ルームでのみ確認・変更できます');
      return;
    }

    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      final uid = await _ensureUid();
      final joinPinHash = DojoJoinAccessStorage.getJoinPinHash(dojoId);
      final unlock = await securityRepo.verifyAdminAndUnlockVault(
        dojoId: dojoId,
        currentAdminPin: adminPin,
        joinPinHash: joinPinHash,
        uid: uid,
      );
      if (!mounted) return;

      if (!unlock.isVerified) {
        setState(() {
          _isBusy = false;
          _errorMessage = unlock.errorMessage ?? '現在の管理者(Admin) PINが一致しません';
        });
        return;
      }

      final owners = recoveryRepo != null
          ? await recoveryRepo.fetchDojoOwners(dojoId)
          : const <DojoOwnerAccount>[];
      if (!mounted) return;

      final payload = unlock.payload;
      _newJoinPinCtrl.text = payload?.joinPin ?? '';
      _newAdminPinCtrl.text = payload?.adminPin ?? adminPin;
      _newOperatorPinCtrl.text = payload?.operatorPin ?? '';
      _newRecorderPinCtrl.text = payload?.recorderPin ?? '';

      setState(() {
        _isBusy = false;
        _isUnlocked = true;
        _isLegacyUnmigrated =
            unlock.status == AdminVaultUnlockStatus.legacyUnmigrated;
        _verifiedAdminPin = adminPin;
        _unlockedVault = payload;
        _owners = owners;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _errorMessage = '本人確認に失敗しました: $e';
      });
    }
  }

  Future<void> _handleOpenRecovery() async {
    final dojoId = ref.read(currentDojoIdProvider);
    if (dojoId.isEmpty || dojoId == 'default_dojo_room') {
      setState(() => _errorMessage = 'クラウド接続された道場ルームでのみ利用できます');
      return;
    }
    final res = await DojoPinRecoverySheet.show(
      context: context,
      dojoId: dojoId,
      mode: DojoRecoveryMode.rolePin,
      elevateToAdmin: true,
    );
    if (!mounted || res == null || !res.recovered) return;
    if (res.effectiveAdminPin != null && res.effectiveAdminPin!.isNotEmpty) {
      _currentAdminPinCtrl.text = res.effectiveAdminPin!;
      await _handleUnlockVault();
    }
  }

  Future<void> _handleSavePins() async {
    if (_isBusy) return;
    final currentAdmin = _verifiedAdminPin ?? _currentAdminPinCtrl.text.trim();
    if (!PinHasher.isValidRolePinFormat(currentAdmin)) {
      setState(() => _errorMessage = '本人確認（Admin PIN）をやり直してください');
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
      if (entry.value.isEmpty) continue;
      if (!PinHasher.isValidRolePinFormat(entry.value)) {
        setState(
          () => _errorMessage = '${entry.key.displayName} のPINは4桁の数字で入力してください',
        );
        return;
      }
      newRolePins[entry.key] = entry.value;
    }

    if (newJoin.isEmpty && newRolePins.isEmpty) {
      setState(() => _errorMessage = '保存するPINを1つ以上入力してください');
      return;
    }

    final dojoId = ref.read(currentDojoIdProvider);
    final repo = ref.read(dojoSecurityRepositoryProvider);
    if (repo == null || dojoId.isEmpty || dojoId == 'default_dojo_room') {
      setState(() => _errorMessage = 'クラウド接続された道場ルームでのみ変更できます');
      return;
    }

    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      final uid = await _ensureUid();
      final result = await repo.updateDojoSecurityPins(
        dojoId: dojoId,
        currentAdminPin: currentAdmin,
        newJoinPin: newJoin.isNotEmpty ? newJoin : null,
        newRolePins: newRolePins.isNotEmpty ? newRolePins : null,
        currentVault: _unlockedVault,
        uid: uid,
      );
      if (!mounted) return;
      if (!result.success) {
        setState(() {
          _isBusy = false;
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
        _isBusy = false;
        _errorMessage = '更新に失敗しました: $e';
      });
    }
  }

  Future<void> _saveOwners(List<DojoOwnerAccount> nextOwners) async {
    final dojoId = ref.read(currentDojoIdProvider);
    final recoveryRepo = ref.read(dojoOwnerRecoveryRepositoryProvider);
    final adminPin = _verifiedAdminPin ?? _currentAdminPinCtrl.text.trim();
    if (recoveryRepo == null || adminPin.isEmpty) return;

    setState(() {
      _isUpdatingOwners = true;
      _errorMessage = null;
    });
    try {
      final uid = await _ensureUid();
      final res = await recoveryRepo.updateDojoOwners(
        dojoId: dojoId,
        owners: nextOwners,
        currentAdminPin: adminPin,
        uid: uid,
      );
      if (!mounted) return;
      if (!res.success) {
        setState(() {
          _isUpdatingOwners = false;
          _errorMessage = res.errorMessage;
        });
        return;
      }
      final latest = await recoveryRepo.fetchDojoOwners(dojoId);
      if (!mounted) return;
      setState(() {
        _isUpdatingOwners = false;
        _owners = latest;
      });
      AppSnackBar.showSuccess(context, '✓ 代表者Googleアカウントを更新しました');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUpdatingOwners = false;
        _errorMessage = '代表者の更新に失敗しました: $e';
      });
    }
  }

  Future<void> _handleLinkCurrentGoogle() async {
    String? email = _currentSignedInGoogleEmail();
    String? displayName = FirebaseAuth.instance.currentUser?.displayName;
    if (email == null || email.isEmpty) {
      try {
        final cred = await ref
            .read(googleAuthServiceProvider)
            .linkOrSignInWithGoogle();
        email = cred?.user?.email;
        displayName = cred?.user?.displayName;
      } catch (e) {
        if (!mounted) return;
        setState(() => _errorMessage = 'Googleアカウント連携に失敗しました: $e');
        return;
      }
    }
    if (email == null || email.trim().isEmpty) return;
    await _saveOwners([
      ..._owners,
      DojoOwnerAccount(email: email, displayName: displayName),
    ]);
  }

  Future<void> _handleAddManualEmail(String email) =>
      _saveOwners([..._owners, DojoOwnerAccount(email: email)]);

  Future<void> _handleRemoveOwnerEmail(String email) {
    final normalized = DojoOwnerRecoveryRepository.normalizeEmail(email);
    return _saveOwners(
      _owners.where((o) => o.normalizedEmail != normalized).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
    final dojoId = ref.watch(currentDojoIdProvider);
    final mediaQuery = MediaQuery.of(context);
    final maxScrollHeight =
        (mediaQuery.size.height * 0.88 -
                mediaQuery.viewInsets.bottom -
                mediaQuery.padding.top -
                96)
            .clamp(180.0, 560.0);

    return AppBottomSheetContent(
      title: '道場セキュリティ・PIN設定',
      titleIcon: Icons.shield_outlined,
      titleTrailing: IconButton(
        icon: Icon(Icons.close, color: themeColors.subTextColor),
        onPressed: _isBusy ? null : () => Navigator.of(context).pop(false),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxScrollHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DojoSecurityTargetBanner(
                themeColors: themeColors,
                dojoId: dojoId,
                message: !_isUnlocked
                    ? '現在のPINを確認・変更するには、まずAdmin PINで本人確認を行ってください。'
                    : (_isLegacyUnmigrated
                          ? '✓ 本人確認済み（未移行の既存PINは空欄で表示されます。入力・保存すると次回から表示されます）'
                          : '✓ 本人確認済み（設定中のPINを表示しています）'),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (!_isUnlocked)
                DojoAdminUnlockCard(
                  themeColors: themeColors,
                  controller: _currentAdminPinCtrl,
                  obscurePin: _obscureCurrentAdmin,
                  isBusy: _isBusy,
                  onToggleObscure: () => setState(
                    () => _obscureCurrentAdmin = !_obscureCurrentAdmin,
                  ),
                  onUnlock: _handleUnlockVault,
                  onOpenRecovery: _handleOpenRecovery,
                )
              else ...[
                DojoSecurityPinFormCard(
                  themeColors: themeColors,
                  joinPinController: _newJoinPinCtrl,
                  adminPinController: _newAdminPinCtrl,
                  operatorPinController: _newOperatorPinCtrl,
                  recorderPinController: _newRecorderPinCtrl,
                  hidePins: _hideUnlockedPins,
                  isBusy: _isBusy,
                  onToggleHidePins: () =>
                      setState(() => _hideUnlockedPins = !_hideUnlockedPins),
                  onSave: _handleSavePins,
                ),
                const SizedBox(height: AppSpacing.lg),
                DojoOwnerAccountsCard(
                  themeColors: themeColors,
                  owners: _owners,
                  currentGoogleEmail: _currentSignedInGoogleEmail(),
                  isUpdating: _isUpdatingOwners,
                  onLinkCurrentGoogle: _handleLinkCurrentGoogle,
                  onAddManualEmail: _handleAddManualEmail,
                  onRemoveEmail: _handleRemoveOwnerEmail,
                ),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                DojoSecurityErrorBanner(message: _errorMessage!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
