import 'package:flutter/material.dart';
import 'package:kendo_os/shared/domain/entities/organization_graduation_type.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 選手編集シート用の在籍区分（現役 / 卒業・OB/OG）および卒業年度セレクタ
class MasterPlayerStatusSelector extends StatelessWidget {
  final String selectedStatus;
  final int? graduatedFiscalYear;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<int?> onGraduatedYearChanged;

  const MasterPlayerStatusSelector({
    super.key,
    required this.selectedStatus,
    required this.graduatedFiscalYear,
    required this.onStatusChanged,
    required this.onGraduatedYearChanged,
  });

  List<int> _yearOptions() {
    final defaultYear = FiscalYearHelper.defaultGraduationFiscalYear(
      DateTime.now(),
    );
    final maxYear = defaultYear + 1;
    final minYear = defaultYear - 15;
    final years = <int>[for (int y = maxYear; y >= minYear; y--) y];
    if (graduatedFiscalYear != null && !years.contains(graduatedFiscalYear)) {
      years.add(graduatedFiscalYear!);
      years.sort((a, b) => b.compareTo(a));
    }
    return years;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = context.appColors.primaryAccent;
    final isGraduated = selectedStatus == PlayerModel.statusGraduated;
    final years = _yearOptions();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '在籍区分',
          style: TextStyle(
            fontSize: AppFontSize.bodySmall,
            fontWeight: AppFontWeight.bold,
            color: context.appColors.subTextColor,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: PlayerModel.statusActive,
                icon: Icon(Icons.person_outline, size: 16),
                label: Text('現役'),
              ),
              ButtonSegment(
                value: PlayerModel.statusGraduated,
                icon: Icon(Icons.school_outlined, size: 16),
                label: Text('卒業・OB/OG'),
              ),
            ],
            selected: {
              isGraduated
                  ? PlayerModel.statusGraduated
                  : PlayerModel.statusActive,
            },
            onSelectionChanged: (set) {
              final next = set.first;
              onStatusChanged(next);
              if (next == PlayerModel.statusGraduated &&
                  graduatedFiscalYear == null) {
                onGraduatedYearChanged(
                  FiscalYearHelper.defaultGraduationFiscalYear(DateTime.now()),
                );
              }
            },
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: primaryColor,
              selectedForegroundColor: AppKendoColors.pureWhite,
              backgroundColor: context.appColors.inputBackground,
              foregroundColor: context.appColors.textColor,
              side: BorderSide(color: context.appColors.separatorColor),
              textStyle: const TextStyle(
                fontSize: AppFontSize.bodySmall,
                fontWeight: AppFontWeight.bold,
              ),
            ),
          ),
        ),
        if (isGraduated) ...[
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<int?>(
            initialValue: graduatedFiscalYear,
            dropdownColor: context.appColors.cardBackground,
            style: TextStyle(
              color: context.appColors.textColor,
              fontSize: AppFontSize.subhead,
            ),
            decoration: InputDecoration(
              labelText: '卒業年度',
              prefixIcon: Icon(
                Icons.history_edu,
                color: context.appColors.subTextColor,
              ),
              border: OutlineInputBorder(borderRadius: AppRadius.medium),
              filled: true,
              fillColor: context.appColors.inputBackground,
            ),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('年度未設定')),
              ...years.map(
                (y) => DropdownMenuItem<int?>(value: y, child: Text('$y年度卒')),
              ),
            ],
            onChanged: onGraduatedYearChanged,
          ),
        ],
      ],
    );
  }
}
