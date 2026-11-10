import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';

/// OB戦・練習試合向けに卒業生（OB/OG）を選手候補に含めるための共通トグルチップ
class IncludeGraduatedFilterChip extends StatelessWidget {
  final bool includeGraduated;
  final ValueChanged<bool> onChanged;
  final Color? accentColor;

  const IncludeGraduatedFilterChip({
    super.key,
    required this.includeGraduated,
    required this.onChanged,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = accentColor ?? AppKendoColors.indigo;
    return AppChoiceChip(
      icon: Icons.school_outlined,
      label: const Text('卒業生(OB/OG)を含める'),
      selected: includeGraduated,
      customSelectedColor: effectiveColor,
      customTextColor: AppKendoColors.pureWhite,
      onSelected: onChanged,
    );
  }
}
