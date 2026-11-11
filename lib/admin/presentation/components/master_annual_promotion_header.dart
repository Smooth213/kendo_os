import 'package:flutter/material.dart';
import 'package:kendo_os/shared/domain/entities/organization_graduation_type.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 一括進級シートの上部設定・警告・内訳サマリーセクション
class MasterAnnualPromotionHeader extends StatelessWidget {
  final OrganizationGraduationType activeType;
  final OrganizationPromotionConfig config;
  final int promotionFiscalYear;
  final int graduationFiscalYear;
  final int defaultGraduationFiscalYear;
  final bool alreadyPromoted;
  final int promotedCount;
  final int graduatedCount;
  final int adultKeptCount;
  final int candidateCount;
  final ValueChanged<OrganizationGraduationType> onTypeChanged;
  final ValueChanged<int> onGraduationYearChanged;

  const MasterAnnualPromotionHeader({
    super.key,
    required this.activeType,
    required this.config,
    required this.promotionFiscalYear,
    required this.graduationFiscalYear,
    required this.defaultGraduationFiscalYear,
    required this.alreadyPromoted,
    required this.promotedCount,
    required this.graduatedCount,
    required this.adultKeptCount,
    required this.candidateCount,
    required this.onTypeChanged,
    required this.onGraduationYearChanged,
  });

  String _formatDate(DateTime dt) {
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '${dt.year}/$m/$d';
  }

  @override
  Widget build(BuildContext context) {
    final gradYears = [
      for (
        int y = defaultGraduationFiscalYear + 1;
        y >= defaultGraduationFiscalYear - 3;
        y--
      )
        y,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.md),
        if (alreadyPromoted) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: context.appColors.warningColor.withValues(alpha: 0.14),
              borderRadius: AppRadius.medium,
              border: Border.all(color: context.appColors.warningColor),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: context.appColors.warningColor,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '$promotionFiscalYear年度の一括進級は'
                    '${config.lastPromotedAt != null ? ' ${_formatDate(config.lastPromotedAt!)} に' : ''}'
                    '実行済みです。二重進級にご注意ください。',
                    style: TextStyle(
                      fontSize: AppFontSize.small,
                      fontWeight: AppFontWeight.semiBold,
                      color: context.appColors.textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        DropdownButtonFormField<OrganizationGraduationType>(
          initialValue: activeType,
          dropdownColor: context.appColors.cardBackground,
          style: TextStyle(
            color: context.appColors.textColor,
            fontSize: AppFontSize.body,
          ),
          decoration: InputDecoration(
            labelText: '組織種別（卒業ライン）',
            prefixIcon: const Icon(Icons.account_balance),
            border: OutlineInputBorder(borderRadius: AppRadius.capsule),
            filled: true,
            fillColor: context.appColors.inputBackground,
          ),
          items: OrganizationGraduationType.values
              .map(
                (type) =>
                    DropdownMenuItem(value: type, child: Text(type.label)),
              )
              .toList(),
          onChanged: (val) {
            if (val != null) onTypeChanged(val);
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        if (activeType.graduationGrade != null)
          DropdownButtonFormField<int>(
            initialValue: graduationFiscalYear,
            dropdownColor: context.appColors.cardBackground,
            style: TextStyle(
              color: context.appColors.textColor,
              fontSize: AppFontSize.body,
            ),
            decoration: InputDecoration(
              labelText: '記録する卒業年度',
              prefixIcon: const Icon(Icons.history_edu),
              border: OutlineInputBorder(borderRadius: AppRadius.capsule),
              filled: true,
              fillColor: context.appColors.inputBackground,
            ),
            items: gradYears
                .map((y) => DropdownMenuItem(value: y, child: Text('$y年度卒')))
                .toList(),
            onChanged: (val) {
              if (val != null) onGraduationYearChanged(val);
            },
          ),
        const SizedBox(height: AppSpacing.md),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: context.appColors.inputBackground,
            borderRadius: AppRadius.medium,
          ),
          child: Text(
            '進級予定：$promotedCount名  /  卒業(OB/OG)：$graduatedCount名  /  一般(維持)：$adultKeptCount名',
            style: TextStyle(
              fontSize: AppFontSize.bodySmall,
              fontWeight: AppFontWeight.bold,
              color: context.appColors.textColor,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          '卒業対象の選手（$candidateCount名）',
          style: TextStyle(
            fontSize: AppFontSize.bodySmall,
            fontWeight: AppFontWeight.bold,
            color: context.appColors.textColor,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '道場や部活に残留し、次の学年へ進級させたい選手のみスイッチをONにしてください。',
          style: TextStyle(
            fontSize: AppFontSize.small,
            color: context.appColors.subTextColor,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}
