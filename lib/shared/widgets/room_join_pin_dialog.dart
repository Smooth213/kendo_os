import 'package:flutter/material.dart';
import 'package:kendo_os/features/auth/presentation/widgets/dojo_pin_recovery_sheet.dart';
import 'package:kendo_os/security/pin_hasher.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_loading_indicator.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

/// 道場入室PINダイアログの動作モード
enum RoomJoinPinMode { createNew, joinExisting, initializeLegacy }

/// 道場IDに対する「道場入室PIN（合言葉）」の設定・認証ボトムシート。
///
/// iOS Safari / 小型画面でキーボードが出現した際も上下が見切れないよう、
/// 画面下部アンカーのボトムシート＋全体スクロール構成で安全に描画する。
class RoomJoinPinDialog extends StatefulWidget {
  final String dojoId;
  final RoomJoinPinMode mode;
  final Future<String?> Function(String pin) onSubmitPin;
  final Future<void> Function(String newJoinPinHash)? onRecoveredJoinPin;

  const RoomJoinPinDialog({
    super.key,
    required this.dojoId,
    required this.mode,
    required this.onSubmitPin,
    this.onRecoveredJoinPin,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String dojoId,
    required RoomJoinPinMode mode,
    required Future<String?> Function(String pin) onSubmitPin,
    Future<void> Function(String newJoinPinHash)? onRecoveredJoinPin,
  }) {
    return showAppBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      isDismissible: false,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.90,
      ),
      builder: (ctx) => RoomJoinPinDialog(
        dojoId: dojoId,
        mode: mode,
        onSubmitPin: onSubmitPin,
        onRecoveredJoinPin: onRecoveredJoinPin,
      ),
    );
  }

  @override
  State<RoomJoinPinDialog> createState() => _RoomJoinPinDialogState();
}

class _RoomJoinPinDialogState extends State<RoomJoinPinDialog> {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _obscureText = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _isSetupMode =>
      widget.mode == RoomJoinPinMode.createNew ||
      widget.mode == RoomJoinPinMode.initializeLegacy;

  @override
  void initState() {
    super.initState();
    _pinController.addListener(_onStateUpdated);
    _focusNode.addListener(_onStateUpdated);
  }

  void _onStateUpdated() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _pinController.removeListener(_onStateUpdated);
    _focusNode.removeListener(_onStateUpdated);
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String get _title {
    switch (widget.mode) {
      case RoomJoinPinMode.createNew:
        return '新規道場ルームのPIN設定';
      case RoomJoinPinMode.initializeLegacy:
        return '初回入室PINの設定（既存ルーム保護）';
      case RoomJoinPinMode.joinExisting:
        return '道場入室PINの入力';
    }
  }

  String _description(bool isCompact) {
    switch (widget.mode) {
      case RoomJoinPinMode.createNew:
        return isCompact
            ? '道場ID [ ${widget.dojoId} ] の入室PINを設定してください。'
            : '道場ID [ ${widget.dojoId} ] を新しく作成します。\n他道場からの誤接続を防ぐため、入室PIN（合言葉）を設定してください。';
      case RoomJoinPinMode.initializeLegacy:
        return isCompact
            ? '既存ルーム [ ${widget.dojoId} ] の初回入室PINを設定してください。'
            : '既存ルーム [ ${widget.dojoId} ] には入室PINが未設定です。\n今後の保護のため、この道場専用の入室PIN（合言葉）を設定してください。';
      case RoomJoinPinMode.joinExisting:
        return isCompact
            ? '道場 [ ${widget.dojoId} ] の入室PINを入力してください。'
            : '既存の道場 [ ${widget.dojoId} ] に参加するには、\nこの道場の入室PIN（合言葉）を入力してください。';
    }
  }

  String get _submitLabel {
    switch (widget.mode) {
      case RoomJoinPinMode.createNew:
        return 'PINを設定して作成';
      case RoomJoinPinMode.initializeLegacy:
        return 'PINを設定して接続';
      case RoomJoinPinMode.joinExisting:
        return '認証して接続';
    }
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;
    final rawPin = _pinController.text.trim();

    if (_isSetupMode) {
      final validation = PinHasher.validateJoinPinFormat(rawPin);
      if (!validation.isValid) {
        setState(() => _errorMessage = validation.errorMessage);
        return;
      }
    } else if (rawPin.isEmpty) {
      setState(() => _errorMessage = '道場入室PINを入力してください');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final error = await widget.onSubmitPin(rawPin);
    if (!mounted) return;

    if (error == null) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _isSubmitting = false;
      _errorMessage = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
    final pinValidation = PinHasher.validateJoinPinFormat(_pinController.text);

    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    final isKeyboardVisible = _focusNode.hasFocus || keyboardHeight > 50;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final availableHeight = (screenHeight - keyboardHeight).clamp(
      0.0,
      screenHeight,
    );
    final maxSheetHeight = availableHeight * 0.92;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxSheetHeight),
        decoration: BoxDecoration(
          color: themeColors.cardBackground,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xlargeValue),
          ),
        ),
        padding: const EdgeInsets.only(
          top: AppSpacing.md,
          left: AppSpacing.xl,
          right: AppSpacing.xl,
          bottom: AppSpacing.lg,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: themeColors.separatorColor.withValues(alpha: 0.5),
                    borderRadius: AppRadius.capsule,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Icon(
                    _isSetupMode ? Icons.shield_outlined : Icons.lock_outline,
                    size: 22,
                    color: AppKendoColors.teal,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      _title,
                      style: TextStyle(
                        color: themeColors.textColor,
                        fontSize: AppFontSize.subhead,
                        fontWeight: AppFontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _description(isKeyboardVisible),
                style: TextStyle(
                  color: themeColors.subTextColor,
                  fontSize: AppFontSize.bodySmall,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _pinController,
                focusNode: _focusNode,
                obscureText: _obscureText,
                autofocus: true,
                style: TextStyle(
                  color: themeColors.textColor,
                  fontWeight: AppFontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: _isSetupMode ? '例: dojo2026' : '道場入室PINを入力',
                  hintStyle: TextStyle(color: themeColors.subTextColor),
                  filled: true,
                  fillColor: themeColors.inputBackground,
                  errorText: _errorMessage,
                  errorStyle: const TextStyle(
                    color: AppKendoColors.orangeAccent,
                    fontWeight: AppFontWeight.bold,
                  ),
                  prefixIcon: Icon(
                    Icons.vpn_key_outlined,
                    color: themeColors.subTextColor,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                      color: themeColors.subTextColor,
                    ),
                    onPressed: () {
                      setState(() => _obscureText = !_obscureText);
                    },
                  ),
                  border: const OutlineInputBorder(
                    borderRadius: AppRadius.capsule,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadius.capsule,
                    borderSide: BorderSide(color: themeColors.separatorColor),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: AppRadius.capsule,
                    borderSide: BorderSide(color: AppKendoColors.teal),
                  ),
                ),
                onSubmitted: (_) => _handleSubmit(),
              ),
              if (_isSetupMode) ...[
                const SizedBox(height: AppSpacing.xs),
                if (_pinController.text.trim().isNotEmpty &&
                    pinValidation.isValid)
                  Text(
                    pinValidation.isRecommendedLength
                        ? '✓ 推奨文字数（6文字以上）を満たしています'
                        : '△ 登録可能ですが、6文字以上の英数字を推奨します',
                    style: TextStyle(
                      color: pinValidation.isRecommendedLength
                          ? AppKendoColors.teal
                          : AppKendoColors.orangeAccent,
                      fontSize: AppFontSize.caption,
                      fontWeight: AppFontWeight.bold,
                    ),
                  )
                else
                  Text(
                    '※ 4〜20文字の半角英数字・-・_（6文字以上を推奨: 例 dojo2026）',
                    style: TextStyle(
                      color: themeColors.subTextColor,
                      fontSize: AppFontSize.caption,
                      height: 1.3,
                    ),
                  ),
              ],
              const SizedBox(height: AppSpacing.md),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  OutlinedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: themeColors.subTextColor,
                      side: BorderSide(color: themeColors.separatorColor),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text(
                      'キャンセル',
                      style: TextStyle(fontWeight: AppFontWeight.bold),
                    ),
                  ),
                  _isSubmitting
                      ? const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          child: AppLoadingIndicator(
                            color: AppKendoColors.teal,
                          ),
                        )
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppKendoColors.teal,
                            foregroundColor: AppKendoColors.pureWhite,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.sm,
                            ),
                            shape: const StadiumBorder(),
                          ),
                          onPressed: _handleSubmit,
                          child: Text(
                            _submitLabel,
                            style: const TextStyle(
                              fontWeight: AppFontWeight.bold,
                            ),
                          ),
                        ),
                ],
              ),
              if (widget.mode == RoomJoinPinMode.joinExisting &&
                  widget.onRecoveredJoinPin != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () async {
                            final res = await DojoPinRecoverySheet.show(
                              context: context,
                              dojoId: widget.dojoId,
                              mode: DojoRecoveryMode.joinPin,
                            );
                            if (!mounted ||
                                res == null ||
                                !res.recovered ||
                                res.newJoinPinHash == null) {
                              return;
                            }
                            await widget.onRecoveredJoinPin!(
                              res.newJoinPinHash!,
                            );
                            if (context.mounted) {
                              Navigator.of(context).pop(true);
                            }
                          },
                    child: const Text(
                      '入室PINを忘れた場合（代表者Googleで再設定）',
                      style: TextStyle(
                        color: AppKendoColors.teal,
                        fontSize: AppFontSize.caption,
                        fontWeight: AppFontWeight.semiBold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
