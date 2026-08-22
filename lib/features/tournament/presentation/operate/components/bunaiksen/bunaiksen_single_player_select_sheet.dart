import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

/// 🥋 部内戦 選手選択モーダルシート（カテゴリ別フィルタリング＆テキスト検索＆手入力）
class BunaiksenSinglePlayerSelectSheet extends StatefulWidget {
  final String sideName;
  final Color accentColor;
  final List<PlayerModel> masterPlayers;

  const BunaiksenSinglePlayerSelectSheet({
    super.key,
    required this.sideName,
    required this.accentColor,
    required this.masterPlayers,
  });

  static Future<String?> show(
    BuildContext context,
    WidgetRef ref, {
    required String sideName,
    required Color accentColor,
  }) async {
    final repo = ref.read(playerRepositoryProvider);
    final masterPlayers = await repo.getPlayers().first;

    if (!context.mounted) return null;

    return showAppBottomSheet<String>(
      context: context,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      builder: (ctx) {
        return BunaiksenSinglePlayerSelectSheet(
          sideName: sideName,
          accentColor: accentColor,
          masterPlayers: masterPlayers,
        );
      },
    );
  }

  @override
  State<BunaiksenSinglePlayerSelectSheet> createState() =>
      _BunaiksenSinglePlayerSelectSheetState();
}

class _BunaiksenSinglePlayerSelectSheetState
    extends State<BunaiksenSinglePlayerSelectSheet> {
  String _searchText = '';
  String _selectedFilter = 'すべて';
  bool _isAscending = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = widget.masterPlayers.where((p) {
      final matchSearch =
          _searchText.isEmpty ||
          p.name.contains(_searchText) ||
          p.nameKana.contains(_searchText);

      bool matchFilter = true;
      if (_selectedFilter == '初心者') {
        matchFilter = p.isBeginner;
      } else if (_selectedFilter == '幼年') {
        matchFilter = p.grade == 0 && !p.isBeginner;
      } else if (_selectedFilter == '低学年') {
        matchFilter = p.grade >= 1 && p.grade <= 4 && !p.isBeginner;
      } else if (_selectedFilter == '高学年') {
        matchFilter = p.grade >= 5 && p.grade <= 6 && !p.isBeginner;
      } else if (_selectedFilter == '中学生') {
        matchFilter = p.grade >= 7 && p.grade <= 9 && !p.isBeginner;
      } else if (_selectedFilter == '高校生') {
        matchFilter = p.grade >= 10 && p.grade <= 12 && !p.isBeginner;
      } else if (_selectedFilter == '一般') {
        matchFilter = p.grade >= 13 && !p.isBeginner;
      }

      return matchSearch && matchFilter;
    }).toList();

    // 学年順（同一年齢内はよみがな順）でソート（昇順 / 降順）
    filtered.sort((a, b) {
      final gradeCompare = _isAscending
          ? a.grade.compareTo(b.grade)
          : b.grade.compareTo(a.grade);
      if (gradeCompare != 0) return gradeCompare;
      return _isAscending
          ? a.nameKana.compareTo(b.nameKana)
          : b.nameKana.compareTo(a.nameKana);
    });

    return AppBottomSheetContent(
      title: '${widget.sideName} の選手を選択',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Icon(Icons.person_search, color: widget.accentColor, size: 24),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '${widget.sideName}の選手を選択',
                    style: TextStyle(
                      fontSize: AppFontSize.headline,
                      fontWeight: AppFontWeight.bold,
                      color: context.appColors.textColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                InkWell(
                  onTap: () {
                    setState(() => _isAscending = !_isAscending);
                  },
                  borderRadius: AppRadius.full,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2C2C2E)
                          : context.appColors.inputBackground,
                      borderRadius: AppRadius.full,
                      border: Border.all(
                        color: context.appColors.separatorColor,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isAscending
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          size: 14,
                          color: widget.accentColor,
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Text(
                          _isAscending ? '学年 昇順' : '学年 降順',
                          style: TextStyle(
                            fontSize: AppFontSize.badge,
                            fontWeight: AppFontWeight.bold,
                            color: context.appColors.textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // 検索窓・自由テキスト入力
            AppTextField(
              autofocus: false,
              decoration: InputDecoration(
                hintText: '名前を入力または名簿から1タップ選択',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchText.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.check_circle,
                          color: AppKendoColors.green,
                        ),
                        onPressed: () => Navigator.pop(context, _searchText),
                      )
                    : null,
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF2C2C2E)
                    : const Color(0xFFF2F2F7),
                border: const OutlineInputBorder(
                  borderRadius: AppRadius.medium,
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
              ),
              onChanged: (val) => setState(() => _searchText = val),
              onSubmitted: (val) {
                if (val.trim().isNotEmpty) {
                  Navigator.pop(context, val.trim());
                }
              },
            ),
            const SizedBox(height: 10),
            // カテゴリフィルター
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['すべて', '初心者', '幼年', '低学年', '高学年', '中学生', '高校生', '一般']
                    .map((filterName) {
                      final isSel = _selectedFilter == filterName;
                      return Padding(
                        padding: const EdgeInsets.only(
                          right: AppSpacing.subValue,
                        ),
                        child: AppChoiceChip(
                          label: Text(filterName),
                          selected: isSel,
                          customSelectedColor: widget.accentColor,
                          customTextColor: isSel
                              ? AppKendoColors.pureWhite
                              : null,
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
            // 名簿リスト (ワンタップ決定)
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        _searchText.isNotEmpty
                            ? '「$_searchText」をタップして決定できます'
                            : '該当する選手がいません',
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFFFFFFFF).withValues(alpha: 0.54)
                              : const Color(0x8A000000),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (itemCtx, index) {
                        final p = filtered[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          color: isDark
                              ? const Color(0xFF2C2C2E)
                              : const Color(0xFFF2F2F7),
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.medium,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: widget.accentColor.withValues(
                                alpha: 0.2,
                              ),
                              child: Text(
                                p.name.isNotEmpty
                                    ? p.name.substring(0, 1)
                                    : '?',
                                style: TextStyle(
                                  color: widget.accentColor,
                                  fontWeight: AppFontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              p.name,
                              style: TextStyle(
                                fontWeight: AppFontWeight.bold,
                                color: context.appColors.textColor,
                              ),
                            ),
                            subtitle: Text(
                              p.gradeName,
                              style: TextStyle(
                                color: widget.accentColor,
                                fontSize: AppFontSize.small,
                              ),
                            ),
                            trailing: Icon(
                              Icons.touch_app,
                              color: widget.accentColor,
                            ),
                            onTap: () => Navigator.pop(context, p.name),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
