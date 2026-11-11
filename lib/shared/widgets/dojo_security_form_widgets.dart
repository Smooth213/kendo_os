import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kendo_os/security/pin_hasher.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

/// 道場PIN・代表者管理フォームで共通利用するカプセル型PIN入力フィールド
class DojoSecurityField extends StatelessWidget {
  final AppThemeColors themeColors;
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final Color focusBorderColor;
  final bool isNumeric4;
  final bool obscure;
  final bool autofocus;
  final VoidCallback? onToggleObscure;
  final ValueChanged<String>? onSubmitted;

  const DojoSecurityField({
    super.key,
    required this.themeColors,
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.focusBorderColor = AppKendoColors.purple,
    this.isNumeric4 = true,
    this.obscure = false,
    this.autofocus = false,
    this.onToggleObscure,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: themeColors.textColor,
            fontSize: AppFontSize.small,
            fontWeight: AppFontWeight.semiBold,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        AppTextField(
          controller: controller,
          obscureText: obscure,
          autofocus: autofocus,
          inputFormatters: [
            LengthLimitingTextInputFormatter(
              isNumeric4 ? 4 : PinHasher.maxJoinPinLength,
            ),
          ],
          keyboardType: isNumeric4 ? TextInputType.number : TextInputType.text,
          style: TextStyle(
            color: themeColors.textColor,
            fontWeight: AppFontWeight.bold,
            fontSize: AppFontSize.body,
          ),
          onSubmitted: onSubmitted,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            counterText: '',
            hintText: hint,
            hintStyle: TextStyle(
              color: themeColors.subTextColor,
              fontSize: AppFontSize.bodySmall,
              fontWeight: AppFontWeight.regular,
            ),
            filled: true,
            fillColor: themeColors.cardBackground,
            prefixIcon: Icon(
              prefixIcon,
              size: 18,
              color: themeColors.subTextColor,
            ),
            suffixIcon: onToggleObscure == null
                ? null
                : IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_off : Icons.visibility,
                      size: 18,
                      color: themeColors.subTextColor,
                    ),
                    onPressed: onToggleObscure,
                  ),
            border: const OutlineInputBorder(borderRadius: AppRadius.capsule),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.capsule,
              borderSide: BorderSide(color: themeColors.separatorColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.capsule,
              borderSide: BorderSide(color: focusBorderColor),
            ),
          ),
        ),
      ],
    );
  }
}

/// セキュリティ設定シート用のセクションカード枠
class DojoSecuritySectionCard extends StatelessWidget {
  final AppThemeColors themeColors;
  final String title;
  final Widget? trailing;
  final Widget child;

  const DojoSecuritySectionCard({
    super.key,
    required this.themeColors,
    required this.title,
    this.trailing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: themeColors.inputBackground.withValues(alpha: 0.55),
        borderRadius: AppRadius.large,
        border: Border.all(
          color: themeColors.separatorColor.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: themeColors.subTextColor,
                    fontSize: AppFontSize.caption,
                    fontWeight: AppFontWeight.bold,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

/// 道場IDとステータス案内を表示する共通バナー
class DojoSecurityTargetBanner extends StatelessWidget {
  final AppThemeColors themeColors;
  final String dojoId;
  final String message;
  final Color accentColor;
  final IconData icon;

  const DojoSecurityTargetBanner({
    super.key,
    required this.themeColors,
    required this.dojoId,
    required this.message,
    this.accentColor = AppKendoColors.purple,
    this.icon = Icons.domain_verification_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: AppRadius.large,
        border: Border.all(color: accentColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: accentColor),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '対象道場: $dojoId',
                  style: TextStyle(
                    color: themeColors.textColor,
                    fontSize: AppFontSize.body,
                    fontWeight: AppFontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  message,
                  style: TextStyle(
                    color: themeColors.subTextColor,
                    fontSize: AppFontSize.small,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// セキュリティフォーム共通のエラー表示バナー
class DojoSecurityErrorBanner extends StatelessWidget {
  final String message;

  const DojoSecurityErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppKendoColors.orangeAccent.withValues(alpha: 0.12),
        borderRadius: AppRadius.medium,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            size: 18,
            color: AppKendoColors.orangeAccent,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppKendoColors.orangeAccent,
                fontSize: AppFontSize.bodySmall,
                fontWeight: AppFontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
