import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/auth/application/google_auth_service.dart';
import 'package:kendo_os/security/dojo_join_access_storage.dart';
import 'package:kendo_os/security/dojo_owner_recovery_repository.dart';
import 'package:kendo_os/security/pin_hasher.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_loading_indicator.dart';
import 'package:kendo_os/shared/widgets/dojo_security_form_widgets.dart';

/// PIN復旧シートの動作モード
enum DojoRecoveryMode { joinPin, rolePin }

/// PIN復旧・初期化シートの完了結果
class DojoPinRecoveryResult {
  final bool recovered;
  final String? newJoinPinHash;
  final String? effectiveAdminPin;

  const DojoPinRecoveryResult({
    required this.recovered,
    this.newJoinPinHash,
    this.effectiveAdminPin,
  });
}

/// 登録済み代表者Googleアカウントによる本人確認と、PINの初期化／再設定を行うボトムシート
class DojoPinRecoverySheet extends ConsumerStatefulWidget {
  final String dojoId;
  final DojoRecoveryMode mode;
  final bool elevateToAdmin;
  final Future<String?> Function()? signInWithGoogleOverride;

  const DojoPinRecoverySheet({
    super.key,
    required this.dojoId,
    required this.mode,
    this.elevateToAdmin = false,
    this.signInWithGoogleOverride,
  });

  static Future<DojoPinRecoveryResult?> show({
    required BuildContext context,
    required String dojoId,
    required DojoRecoveryMode mode,
    bool elevateToAdmin = false,
    Future<String?> Function()? signInWithGoogleOverride,
  }) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    return showAppBottomSheet<DojoPinRecoveryResult>(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(maxHeight: screenHeight * 0.88),
      builder: (_) => DojoPinRecoverySheet(
        dojoId: dojoId,
        mode: mode,
        elevateToAdmin: elevateToAdmin,
        signInWithGoogleOverride: signInWithGoogleOverride,
      ),
    );
  }

  /// PIN認証画面からロールPIN初期化フローを起動するヘルパー
  static Future<void> openForRoleAuthScreen({
    required BuildContext context,
    required WidgetRef ref,
    required bool elevateToAdmin,
    required VoidCallback onRecovered,
  }) async {
    final dojoId = ref.read(currentDojoIdProvider);
    if (dojoId.isEmpty || dojoId == 'default_dojo_room') {
      AppSnackBar.showError(context, 'クラウド接続された道場でのみ初期化できます');
      return;
    }
    final res = await show(
      context: context,
      dojoId: dojoId,
      mode: DojoRecoveryMode.rolePin,
      elevateToAdmin: elevateToAdmin,
    );
    if (!context.mounted || res == null || !res.recovered) return;
    onRecovered();
    AppSnackBar.showSuccess(context, '✓ PINを初期化・再設定しました。新しいPINを入力してください');
  }

  @override
  ConsumerState<DojoPinRecoverySheet> createState() =>
      _DojoPinRecoverySheetState();
}

class _DojoPinRecoverySheetState extends ConsumerState<DojoPinRecoverySheet> {
  final TextEditingController _newJoinPinCtrl = TextEditingController();
  final TextEditingController _newAdminPinCtrl = TextEditingController();

  String? _verifiedOwnerEmail;
  bool _resetRolesToDefault = true;
  bool _isWorking = false;
  String? _errorMessage;

  @override
  void dispose() {
    _newJoinPinCtrl.dispose();
    _newAdminPinCtrl.dispose();
    super.dispose();
  }

  String? _currentGoogleEmail() {
    try {
      if (Firebase.apps.isEmpty) return null;
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.isAnonymous) return null;
      return user.email;
    } catch (_) {
      return null;
    }
  }

  String _resolveUid() {
    try {
      if (Firebase.apps.isNotEmpty) {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null && uid.isNotEmpty) return uid;
      }
    } catch (_) {}
    return 'owner_terminal';
  }

  Future<void> _handleVerifyGoogle({bool forceSignInPrompt = false}) async {
    if (_isWorking) return;
    final recoveryRepo = ref.read(dojoOwnerRecoveryRepositoryProvider);
    if (recoveryRepo == null) {
      setState(() => _errorMessage = 'クラウド接続が有効な環境でのみ代表者確認を実行できます');
      return;
    }

    setState(() {
      _isWorking = true;
      _errorMessage = null;
    });

    try {
      String? email = forceSignInPrompt ? null : _currentGoogleEmail();
      if (email == null || email.isEmpty) {
        if (widget.signInWithGoogleOverride != null) {
          email = await widget.signInWithGoogleOverride!();
        } else {
          final cred = await ref
              .read(googleAuthServiceProvider)
              .linkOrSignInWithGoogle();
          email = cred?.user?.email;
        }
      }

      if (!mounted) return;
      if (email == null || email.trim().isEmpty) {
        setState(() {
          _isWorking = false;
          _errorMessage = 'Googleアカウントの確認がキャンセルされました';
        });
        return;
      }

      final check = await recoveryRepo.verifyOwnerGoogleAccess(
        dojoId: widget.dojoId,
        email: email,
      );
      if (!mounted) return;

      if (!check.isOwner) {
        setState(() {
          _isWorking = false;
          _errorMessage =
              '「$email」はこの道場の代表者として登録されていません。登録済みの代表者アカウントでお試しください。';
        });
        return;
      }

      setState(() {
        _isWorking = false;
        _verifiedOwnerEmail = email!.trim().toLowerCase();
      });
    } catch (e) {
      if (!mounted) return;
      final raw = e.toString();
      setState(() {
        _isWorking = false;
        _errorMessage = raw.contains('popup-blocked')
            ? 'ブラウザのポップアップがブロックされました。許可してからもう一度お試しください。'
            : 'Google認証に失敗しました: $e';
      });
    }
  }

  Future<void> _handleApplyReset() async {
    if (_isWorking || _verifiedOwnerEmail == null) return;
    final recoveryRepo = ref.read(dojoOwnerRecoveryRepositoryProvider);
    if (recoveryRepo == null) {
      setState(() => _errorMessage = 'クラウド接続が有効な環境でのみ実行できます');
      return;
    }

    final newJoin = _newJoinPinCtrl.text.trim();
    final newAdmin = _newAdminPinCtrl.text.trim();

    if (widget.mode == DojoRecoveryMode.joinPin) {
      final check = PinHasher.validateJoinPinFormat(newJoin);
      if (!check.isValid) {
        setState(() => _errorMessage = check.errorMessage);
        return;
      }
    }

    if (newAdmin.isNotEmpty && !PinHasher.isValidRolePinFormat(newAdmin)) {
      setState(() => _errorMessage = '新しいAdmin PINは4桁の数字で入力してください');
      return;
    }

    if (widget.mode == DojoRecoveryMode.rolePin &&
        !_resetRolesToDefault &&
        newAdmin.isEmpty) {
      setState(() => _errorMessage = '初期値に戻すか、新しい4桁Admin PINを入力してください');
      return;
    }

    setState(() {
      _isWorking = true;
      _errorMessage = null;
    });

    try {
      final existingJoinHash = DojoJoinAccessStorage.getJoinPinHash(
        widget.dojoId,
      );
      final res = await recoveryRepo.resetPinsByVerifiedOwner(
        dojoId: widget.dojoId,
        uid: _resolveUid(),
        existingJoinPinHash: existingJoinHash,
        newJoinPin: newJoin.isNotEmpty ? newJoin : null,
        resetRolePinsToDefault: _resetRolesToDefault,
        newAdminPin: newAdmin.isNotEmpty ? newAdmin : null,
        elevateToAdmin: widget.elevateToAdmin,
      );

      if (!mounted) return;
      if (!res.success) {
        setState(() {
          _isWorking = false;
          _errorMessage = res.errorMessage ?? 'PINの初期化に失敗しました';
        });
        return;
      }

      Navigator.of(context).pop(
        DojoPinRecoveryResult(
          recovered: true,
          newJoinPinHash: res.newJoinPinHash,
          effectiveAdminPin: res.effectiveAdminPin,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isWorking = false;
        _errorMessage = 'PINの再設定に失敗しました: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
    final mediaQuery = MediaQuery.of(context);
    final maxScrollHeight =
        (mediaQuery.size.height * 0.88 -
                mediaQuery.viewInsets.bottom -
                mediaQuery.padding.top -
                96)
            .clamp(180.0, 520.0);
    final signedInEmail = _currentGoogleEmail();

    return AppBottomSheetContent(
      title: widget.mode == DojoRecoveryMode.joinPin
          ? '道場入室PINの再設定'
          : 'ロールPINの初期化・再設定',
      titleIcon: Icons.lock_reset_rounded,
      titleTrailing: IconButton(
        icon: Icon(Icons.close, color: themeColors.subTextColor),
        onPressed: _isWorking ? null : () => Navigator.of(context).pop(null),
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
                dojoId: widget.dojoId,
                accentColor: AppKendoColors.teal,
                icon: Icons.lock_reset_rounded,
                message: _verifiedOwnerEmail == null
                    ? '登録済みの代表者Googleアカウントで本人確認を行うと、PINを初期化・再設定できます。'
                    : '✓ 代表者確認済み（$_verifiedOwnerEmail）',
              ),
              const SizedBox(height: AppSpacing.lg),
              if (_verifiedOwnerEmail == null) ...[
                if (_isWorking)
                  const Center(
                    child: AppLoadingIndicator(color: AppKendoColors.teal),
                  )
                else ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppKendoColors.teal,
                      foregroundColor: AppKendoColors.pureWhite,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () => _handleVerifyGoogle(),
                    icon: const Icon(Icons.account_circle_outlined, size: 18),
                    label: Text(
                      signedInEmail != null && signedInEmail.isNotEmpty
                          ? '$signedInEmail で本人確認する'
                          : 'Googleアカウントで本人確認する',
                      style: const TextStyle(fontWeight: AppFontWeight.bold),
                    ),
                  ),
                  if (signedInEmail != null && signedInEmail.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed: () =>
                          _handleVerifyGoogle(forceSignInPrompt: true),
                      child: Text(
                        '別のGoogleアカウントでログインする',
                        style: TextStyle(
                          color: themeColors.subTextColor,
                          fontWeight: AppFontWeight.semiBold,
                        ),
                      ),
                    ),
                  ],
                ],
              ] else ...[
                if (widget.mode == DojoRecoveryMode.joinPin) ...[
                  DojoSecurityField(
                    themeColors: themeColors,
                    controller: _newJoinPinCtrl,
                    label: '新しい道場入室PIN（合言葉）',
                    hint: '6文字以上の英数字を推奨（例: dojo2026）',
                    prefixIcon: Icons.vpn_key_outlined,
                    focusBorderColor: AppKendoColors.teal,
                    isNumeric4: false,
                    autofocus: true,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                SwitchListTile.adaptive(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                  activeTrackColor: AppKendoColors.teal,
                  title: Text(
                    '全ロールPINを初期値（9999 / 2468 / 1357）に戻す',
                    style: TextStyle(
                      color: themeColors.textColor,
                      fontSize: AppFontSize.bodySmall,
                      fontWeight: AppFontWeight.semiBold,
                    ),
                  ),
                  subtitle: Text(
                    'オフにするとロールPINは変更しません',
                    style: TextStyle(
                      color: themeColors.subTextColor,
                      fontSize: AppFontSize.caption,
                    ),
                  ),
                  value: _resetRolesToDefault,
                  onChanged: (val) =>
                      setState(() => _resetRolesToDefault = val),
                ),
                if (widget.mode == DojoRecoveryMode.rolePin) ...[
                  const SizedBox(height: AppSpacing.sm),
                  DojoSecurityField(
                    themeColors: themeColors,
                    controller: _newAdminPinCtrl,
                    label: '新しい Admin PIN を直接指定（任意・4桁数字）',
                    hint: '空欄なら初期値 9999 を使用',
                    prefixIcon: Icons.admin_panel_settings_outlined,
                    focusBorderColor: AppKendoColors.teal,
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                _isWorking
                    ? const Center(
                        child: AppLoadingIndicator(color: AppKendoColors.teal),
                      )
                    : ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppKendoColors.teal,
                          foregroundColor: AppKendoColors.pureWhite,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          shape: const StadiumBorder(),
                        ),
                        onPressed: _handleApplyReset,
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text(
                          'PINを初期化・再設定する',
                          style: TextStyle(fontWeight: AppFontWeight.bold),
                        ),
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
