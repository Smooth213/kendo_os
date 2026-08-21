import 'package:flutter/material.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

/// オーダー設定用の選手選択ボトムシート
class OrderSetupPlayerSelectBottomSheet extends StatefulWidget {
  final List<PlayerModel> masterPlayers;
  final AppThemeColors themeColors;
  final bool isDark;

  const OrderSetupPlayerSelectBottomSheet({
    super.key,
    required this.masterPlayers,
    required this.themeColors,
    required this.isDark,
  });

  /// ボトムシートを表示して選択された選手名またはフラグを返す
  static Future<String?> show(
    BuildContext context, {
    required List<PlayerModel> masterPlayers,
    required AppThemeColors themeColors,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showAppBottomSheet<String>(
      context: context,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.80,
      ),
      builder: (context) => OrderSetupPlayerSelectBottomSheet(
        masterPlayers: masterPlayers,
        themeColors: themeColors,
        isDark: isDark,
      ),
    );
  }

  @override
  State<OrderSetupPlayerSelectBottomSheet> createState() =>
      _OrderSetupPlayerSelectBottomSheetState();
}

class _OrderSetupPlayerSelectBottomSheetState
    extends State<OrderSetupPlayerSelectBottomSheet> {
  String _searchText = '';
  String _selectedFilter = 'すべて';

  Future<String?> _showManualInputDialog(BuildContext context) async {
    String manualName = '';
    return showAppDialog<String>(
      context: context,
      builder: (context) => AppDialog(
        title: '選手名を直接入力',
        content: AppTextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '助っ人選手名などを入力',
            border: OutlineInputBorder(),
          ),
          onChanged: (val) => manualName = val,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, manualName),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.themeColors.primaryAccent,
              foregroundColor: AppKendoColors.pureWhite,
            ),
            child: const Text('決定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDark
        ? const Color(0xFFFFFFFF)
        : context.appColors.cardBackground;

    List<PlayerModel> filteredMaster = widget.masterPlayers
        .where((p) => p.name.contains(_searchText))
        .toList();

    if (_selectedFilter != 'すべて') {
      if (_selectedFilter == '初心者') {
        filteredMaster = filteredMaster.where((p) => p.isBeginner).toList();
      } else if (_selectedFilter == '幼年') {
        filteredMaster = filteredMaster
            .where((p) => p.grade == 0 && !p.isBeginner)
            .toList();
      } else if (_selectedFilter == '低学年') {
        filteredMaster = filteredMaster
            .where((p) => p.grade >= 1 && p.grade <= 4 && !p.isBeginner)
            .toList();
      } else if (_selectedFilter == '高学年') {
        filteredMaster = filteredMaster
            .where((p) => p.grade >= 5 && p.grade <= 6 && !p.isBeginner)
            .toList();
      } else if (_selectedFilter == '中学生') {
        filteredMaster = filteredMaster
            .where((p) => p.grade >= 7 && p.grade <= 9 && !p.isBeginner)
            .toList();
      } else if (_selectedFilter == '高校生') {
        filteredMaster = filteredMaster
            .where((p) => p.grade >= 10 && p.grade <= 12 && !p.isBeginner)
            .toList();
      } else if (_selectedFilter == '一般') {
        filteredMaster = filteredMaster
            .where((p) => p.grade >= 13 && !p.isBeginner)
            .toList();
      }
    }

    filteredMaster.sort((a, b) => a.nameKana.compareTo(b.nameKana));

    return AppBottomSheetContent(
      title: '選手の選択',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context, 'CLEAR_FLAG'),
                    icon: const Icon(Icons.person_outline, size: 16),
                    label: const Text(
                      '未定（空枠）',
                      style: TextStyle(fontWeight: AppFontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.appColors.textColor,
                      side: BorderSide(color: context.appColors.separatorColor),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.compact,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.compact,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context, '欠員'),
                    icon: const Icon(Icons.block, size: 16),
                    label: const Text(
                      '欠員（不戦敗）',
                      style: TextStyle(fontWeight: AppFontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppKendoColors.hansokuRed,
                      side: BorderSide(color: AppKendoColors.hansokuRed),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.compact,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.compact,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () async {
                final inputName = await _showManualInputDialog(context);
                if (context.mounted && inputName != null) {
                  Navigator.pop(context, inputName);
                }
              },
              icon: const Icon(Icons.edit, size: 16),
              label: const Text(
                '直接入力（助っ人など）',
                style: TextStyle(fontWeight: AppFontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: widget.themeColors.primaryAccent,
                side: BorderSide(color: widget.themeColors.softAccent),
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.compact),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // 検索窓
            AppTextField(
              decoration: InputDecoration(
                hintText: '名前で絞り込み...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: widget.isDark
                    ? const Color(0xFFFFFFFF)
                    : const Color(0xFFF2F2F7),
                border: OutlineInputBorder(
                  borderRadius: AppRadius.small,
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (val) => setState(() => _searchText = val),
            ),
            const SizedBox(height: AppSpacing.sm),
            // カテゴリフィルター
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['すべて', '初心者', '幼年', '低学年', '高学年', '中学生', '高校生', '一般']
                    .map((filterName) {
                      final isSelected = _selectedFilter == filterName;
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: AppChoiceChip(
                          label: Text(filterName),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedFilter = filterName);
                            }
                          },
                        ),
                      );
                    })
                    .toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: ListView(
                children: [
                  ...filteredMaster.map(
                    (p) => Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      elevation: 0,
                      color: widget.themeColors.softAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.medium,
                        side: BorderSide(
                          color: widget.isDark
                              ? Colors.transparent
                              : widget.themeColors.softAccent,
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: widget.isDark
                              ? const Color(0xFF2C2C2E)
                              : const Color(0xFFFFFFFF),
                          child: Text(
                            p.name.substring(0, 1),
                            style: TextStyle(
                              color: widget.themeColors.primaryAccent,
                              fontWeight: AppFontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          p.name,
                          style: TextStyle(
                            fontWeight: AppFontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        subtitle: Text(
                          p.gradeName,
                          style: TextStyle(
                            color: widget.themeColors.primaryAccent,
                            fontSize: AppFontSize.small,
                          ),
                        ),
                        trailing: Icon(
                          Icons.check_circle_outline,
                          color: widget.themeColors.primaryAccent,
                        ),
                        onTap: () => Navigator.pop(context, p.name),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
