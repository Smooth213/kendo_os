import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_switch.dart';

/// 設定画面のセクションヘッダー
class SettingsSectionHeader extends StatelessWidget {
  final String title;

  const SettingsSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.lg,
        bottom: AppSpacing.sm,
        top: AppSpacing.md,
      ),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: isDark
              ? context.appColors.subTextColor
              : context.appColors.subTextColor,
          fontSize: AppFontSize.bodySmall,
          fontWeight: AppFontWeight.semiBold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// 設定画面のセクションフッター
class SettingsSectionFooter extends StatelessWidget {
  final String text;

  const SettingsSectionFooter({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.sm,
        bottom: AppSpacing.sm,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isDark
              ? context.appColors.subTextColor
              : context.appColors.subTextColor,
          fontSize: AppFontSize.small,
          height: 1.4,
        ),
      ),
    );
  }
}

/// 設定画面のカードブロック（すりガラス対応）
class SettingsBlock extends StatelessWidget {
  final List<Widget> children;
  final bool enableLiquidGlass;
  final AppThemeColors themeColors;

  const SettingsBlock({
    super.key,
    required this.children,
    required this.enableLiquidGlass,
    required this.themeColors,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final List<Widget> spacedChildren = [];
    for (int i = 0; i < children.length; i++) {
      spacedChildren.add(children[i]);
      if (i < children.length - 1) {
        spacedChildren.add(
          Divider(
            height: 1,
            thickness: 1,
            color: isDark ? const Color(0xFF38383A) : const Color(0xFFC6C6C8),
            indent: 56,
            endIndent: 0,
          ),
        );
      }
    }

    final Widget blockContent = Material(
      color: AppKendoColors.transparent,
      child: Column(children: spacedChildren),
    );

    if (enableLiquidGlass) {
      return ClipRRect(
        borderRadius: AppRadius.large,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: themeColors.cardBackground,
              borderRadius: AppRadius.large,
              border: Border.all(color: themeColors.separatorColor),
            ),
            child: blockContent,
          ),
        ),
      );
    } else {
      return Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: themeColors.cardBackground,
          borderRadius: AppRadius.large,
          border: Border.all(color: themeColors.separatorColor),
        ),
        child: blockContent,
      );
    }
  }
}

/// 設定画面のリストタイル
class SettingsListTile extends StatelessWidget {
  final String title;
  final Widget trailing;
  final IconData icon;
  final Color iconBgColor;
  final VoidCallback? onTap;
  final String? subtitle;

  const SettingsListTile({
    super.key,
    required this.title,
    required this.trailing,
    required this.icon,
    required this.iconBgColor,
    this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final Color dynamicTextColor = context.appColors.textColor;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      leading: Container(
        padding: const EdgeInsets.all(AppSpacing.subValue),
        decoration: BoxDecoration(
          color: iconBgColor,
          borderRadius: AppRadius.small,
        ),
        child: Icon(icon, color: AppKendoColors.pureWhite, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: dynamicTextColor,
          fontSize: AppFontSize.bodyMedium,
          fontWeight: AppFontWeight.medium,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle!, style: const TextStyle(fontSize: AppFontSize.small))
          : null,
      trailing: trailing,
      onTap: onTap,
    );
  }
}

/// 設定画面のスイッチタイル
class SettingsSwitchTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData icon;
  final Color iconBgColor;

  const SettingsSwitchTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    required this.icon,
    required this.iconBgColor,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsListTile(
      title: title,
      icon: icon,
      iconBgColor: iconBgColor,
      onTap: () => onChanged(!value),
      trailing: AppSwitch(
        value: value,
        activeColor: AppKendoColors.green,
        onChanged: onChanged,
      ),
    );
  }
}
