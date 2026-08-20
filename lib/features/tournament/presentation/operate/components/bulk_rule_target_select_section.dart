import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 🥋 一括ルール変更対象の試合グループ単位
class MatchGroupUnit {
  final String id;
  final String displayName;
  final List<String> matchIds;
  final String category;
  final String resolvedType;

  const MatchGroupUnit({
    required this.id,
    required this.displayName,
    required this.matchIds,
    required this.category,
    required this.resolvedType,
  });
}

/// 🥋 一括ルール変更: STEP 1 変更対象選択セクション
class BulkRuleTargetSelectSection extends StatelessWidget {
  final List<String> categories;
  final List<String> matchTypes;
  final String selectedCategoryFilter;
  final String selectedTypeFilter;
  final List<MatchGroupUnit> filteredUnits;
  final List<String> selectedMatchIds;
  final Color primaryAccent;
  final bool isDark;
  final Color textColor;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onTypeChanged;
  final void Function(MatchGroupUnit unit, bool? isChecked) onToggleUnit;
  final VoidCallback onToggleAll;

  const BulkRuleTargetSelectSection({
    super.key,
    required this.categories,
    required this.matchTypes,
    required this.selectedCategoryFilter,
    required this.selectedTypeFilter,
    required this.filteredUnits,
    required this.selectedMatchIds,
    required this.primaryAccent,
    required this.isDark,
    required this.textColor,
    required this.onCategoryChanged,
    required this.onTypeChanged,
    required this.onToggleUnit,
    required this.onToggleAll,
  });

  int get selectedUnitsCount {
    return filteredUnits.where((unit) {
      return unit.matchIds.every((id) => selectedMatchIds.contains(id));
    }).length;
  }

  bool get allSelected {
    if (filteredUnits.isEmpty) return false;
    return filteredUnits.every(
      (unit) => unit.matchIds.every((id) => selectedMatchIds.contains(id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STEP 1: 変更対象の試合を選択',
          style: TextStyle(
            fontSize: AppFontSize.body,
            fontWeight: AppFontWeight.bold,
            color: primaryAccent,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // カテゴリフィルター
        _buildFilterRow(
          context: context,
          label: 'カテゴリ',
          value: selectedCategoryFilter,
          options: categories,
          onChanged: onCategoryChanged,
        ),
        const SizedBox(height: AppSpacing.md),

        // 形式フィルター
        _buildFilterRow(
          context: context,
          label: '形式・種別',
          value: selectedTypeFilter,
          options: matchTypes,
          onChanged: onTypeChanged,
        ),
        const SizedBox(height: AppSpacing.lg),

        // 対象試合チェックリスト
        Container(
          constraints: const BoxConstraints(maxHeight: 180),
          decoration: BoxDecoration(
            borderRadius: AppRadius.medium,
            border: Border.all(color: context.appColors.separatorColor),
          ),
          child: Material(
            color: isDark
                ? const Color(0xFFFFFFFF)
                : context.appColors.cardBackground,
            borderRadius: AppRadius.medium,
            child: filteredUnits.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Text('条件に一致する試合がありません'),
                    ),
                  )
                : Scrollbar(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredUnits.length,
                      itemBuilder: (context, index) {
                        final unit = filteredUnits[index];
                        final isChecked = unit.matchIds.every(
                          (id) => selectedMatchIds.contains(id),
                        );

                        return CheckboxListTile(
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                          title: Text(
                            unit.displayName,
                            style: TextStyle(
                              fontSize: AppFontSize.bodySmall,
                              color: textColor,
                            ),
                          ),
                          value: isChecked,
                          activeColor: primaryAccent,
                          onChanged: (val) => onToggleUnit(unit, val),
                        );
                      },
                    ),
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '現在 $selectedUnitsCount 件を選択中 / 全 ${filteredUnits.length} 件中',
              style: TextStyle(
                fontSize: AppFontSize.small,
                fontWeight: AppFontWeight.bold,
                color: primaryAccent,
              ),
            ),
            if (filteredUnits.isNotEmpty)
              TextButton(
                onPressed: onToggleAll,
                child: Text(allSelected ? '全解除' : '全選択'),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterRow({
    required BuildContext context,
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    final resolvedOptions = options.contains(value)
        ? options
        : [value, ...options];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: AppFontSize.body,
            fontWeight: AppFontWeight.bold,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
            borderRadius: AppRadius.medium,
          ),
          child: DropdownButton<String>(
            value: value,
            underline: const SizedBox(),
            style: TextStyle(color: textColor, fontSize: AppFontSize.body),
            onChanged: onChanged,
            items: resolvedOptions.map((opt) {
              return DropdownMenuItem(
                value: opt,
                child: Text(opt.isEmpty ? '未設定' : opt),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
