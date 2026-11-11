import 'package:flutter/material.dart';
import 'package:kendo_os/security/pin_hasher.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';
import 'package:kendo_os/shared/widgets/app_loading_indicator.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

/// 道場入室PINダイアログの動作モード
enum RoomJoinPinMode { createNew, joinExisting, initializeLegacy }

/// 道場IDに対する「道場入室PIN（合言葉）」の設定・認証ダイアログ。
class RoomJoinPinDialog extends StatefulWidget {
  final String dojoId;
  final RoomJoinPinMode mode;
  final Future<String?> Function(String pin) onSubmitPin;

  const RoomJoinPinDialog({
    super.key,
    required this.dojoId,
    required this.mode,
    required this.onSubmitPin,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String dojoId,
    required RoomJoinPinMode mode,
    required Future<String?> Function(String pin) onSubmitPin,
  }) {
    return showAppDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => RoomJoinPinDialog(
        dojoId: dojoId,
        mode: mode,
        onSubmitPin: onSubmitPin,
      ),
    );
  }

  @override
  State<RoomJoinPinDialog> createState() => _RoomJoinPinDialogState();
}

class _RoomJoinPinDialogState extends State<RoomJoinPinDialog> {
  final TextEditingController _pinController = TextEditingController();
  bool _obscureText = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _isSetupMode =>
      widget.mode == RoomJoinPinMode.createNew ||
      widget.mode == RoomJoinPinMode.initializeLegacy;

  @override
  void initState() {
    super.initState();
    _pinController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
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

  String get _description {
    switch (widget.mode) {
      case RoomJoinPinMode.createNew:
        return '道場ID [ ${widget.dojoId} ] を新しく作成します。\n'
            '他道場からの誤接続を防ぐため、入室PIN（合言葉）を設定してください。';
      case RoomJoinPinMode.initializeLegacy:
        return '既存ルーム [ ${widget.dojoId} ] には入室PINが未設定です。\n'
            '今後の保護のため、この道場専用の入室PIN（合言葉）を設定してください。';
      case RoomJoinPinMode.joinExisting:
        return '既存の道場 [ ${widget.dojoId} ] に参加するには、\n'
            'この道場の入室PIN（合言葉）を入力してください。';
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

    return AppDialog(
      title: _title,
      titleIcon: _isSetupMode ? Icons.shield_outlined : Icons.lock_outline,
      iconColor: AppKendoColors.teal,
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _description,
              style: TextStyle(
                color: themeColors.subTextColor,
                fontSize: AppFontSize.bodySmall,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _pinController,
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
              const SizedBox(height: AppSpacing.sm),
              Text(
                '※ 4〜20文字の半角英数字・ハイフン(- )・アンダーバー(_)が使用できます。セキュリティのため6文字以上の英数字を推奨します（例: dojo2026）。',
                style: TextStyle(
                  color: themeColors.subTextColor,
                  fontSize: AppFontSize.caption,
                  height: 1.4,
                ),
              ),
              if (_pinController.text.trim().isNotEmpty &&
                  pinValidation.isValid) ...[
                const SizedBox(height: AppSpacing.xs),
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
                ),
              ],
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting
              ? null
              : () => Navigator.of(context).pop(false),
          child: Text(
            'キャンセル',
            style: TextStyle(
              color: themeColors.subTextColor,
              fontWeight: AppFontWeight.bold,
            ),
          ),
        ),
        _isSubmitting
            ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: AppLoadingIndicator(color: AppKendoColors.teal),
              )
            : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppKendoColors.teal,
                  foregroundColor: AppKendoColors.pureWhite,
                  elevation: 0,
                  shape: const StadiumBorder(),
                ),
                onPressed: _handleSubmit,
                child: Text(
                  _submitLabel,
                  style: const TextStyle(fontWeight: AppFontWeight.bold),
                ),
              ),
      ],
    );
  }
}
