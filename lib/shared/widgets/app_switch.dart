import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';

/// kendo OS 全体で統一された iOS スタイルの適応型スイッチ
class AppSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;

  const AppSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = context.appColors;
    final effectiveActiveColor = activeColor ?? themeColors.successColor;

    return Switch.adaptive(
      value: value,
      activeTrackColor: effectiveActiveColor,
      onChanged: onChanged == null
          ? null
          : (newValue) {
              AppHaptics.selection();
              onChanged!(newValue);
            },
    );
  }
}
