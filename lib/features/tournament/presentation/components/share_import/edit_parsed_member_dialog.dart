import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/domain/share_import/player_roster_matcher.dart';
import 'package:kendo_os/features/tournament/domain/share_import/tournament_share_data.dart';
import 'package:kendo_os/features/tournament/presentation/components/share_import/edit_parsed_member_roster_list.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';
import 'package:kendo_os/shared/widgets/glass_button.dart';

/// 🥋 取り込み選手・オーダー個別編集ボトムシート
class EditParsedMemberDialog extends StatefulWidget {
  final ParsedTeamMember member;
  final List<PlayerModel> roster;
  final Map<String, String>? assignedPlayerMap;
  final String? category;

  const EditParsedMemberDialog({
    super.key,
    required this.member,
    required this.roster,
    this.assignedPlayerMap,
    this.category,
  });

  /// ボトムシートとして選手編集画面を表示（親がボトムシートでも安全に起動するため useRootNavigator: true）
  static Future<ParsedTeamMember?> show(
    BuildContext context, {
    required ParsedTeamMember member,
    required List<PlayerModel> roster,
    List<ParsedTeamOrder>? allTeams,
    String? currentTeamName,
    String? category,
    Map<String, String>? assignedPlayerMap,
    bool useRootNavigator = true,
  }) {
    final effectiveCategory =
        category ??
        (allTeams != null && currentTeamName != null
            ? allTeams
                  .where((t) => t.teamName == currentTeamName)
                  .map((t) => t.category)
                  .firstOrNull
            : null);

    final effectiveAssignedMap =
        assignedPlayerMap ??
        (allTeams != null
            ? PlayerRosterMatcher.buildAssignedPlayerMap(
                allTeams: allTeams,
                roster: roster,
                currentEditingMember: member,
                currentTeamName: currentTeamName,
              )
            : null);

    return showAppBottomSheet<ParsedTeamMember>(
      context: context,
      useRootNavigator: useRootNavigator,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      builder: (ctx) => EditParsedMemberDialog(
        member: member,
        roster: roster,
        assignedPlayerMap: effectiveAssignedMap,
        category: effectiveCategory,
      ),
    );
  }

  @override
  State<EditParsedMemberDialog> createState() => _EditParsedMemberDialogState();
}

class _EditParsedMemberDialogState extends State<EditParsedMemberDialog> {
  late TextEditingController _positionController;
  late TextEditingController _nameController;
  late String _selectedPosition;
  String _rosterSearchQuery = '';

  static const List<String> _commonPositions = [
    '先鋒',
    '次鋒',
    '五将',
    '中堅',
    '三将',
    '副将',
    '大将',
    '補欠',
  ];

  @override
  void initState() {
    super.initState();
    _selectedPosition = widget.member.position;
    _positionController = TextEditingController(text: widget.member.position);
    _nameController = TextEditingController(text: widget.member.name);
  }

  @override
  void dispose() {
    _positionController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
    final accentColor = themeColors.primaryAccent;
    final textColor = context.appColors.textColor;
    final subTextColor = context.appColors.subTextColor;
    final borderColor = isDark
        ? const Color(0xFF38383A)
        : context.appColors.separatorColor;

    // 名簿のフィルタリング（名前・学年で検索可能）
    final searchedRoster = widget.roster.where((p) {
      if (_rosterSearchQuery.isEmpty) return true;
      final query = _rosterSearchQuery
          .replaceAll(RegExp(r'\s+'), '')
          .toLowerCase();
      final pName = p.name.replaceAll(RegExp(r'\s+'), '').toLowerCase();
      final pKana = p.nameKana.replaceAll(RegExp(r'\s+'), '').toLowerCase();
      final pGrade = p.gradeName.toLowerCase();
      return pName.contains(query) ||
          pKana.contains(query) ||
          pGrade.contains(query);
    }).toList();

    // カテゴリ優先ソート（該当カテゴリの選手、かつ未登録選手を優先して上位に表示）
    final filteredRoster = PlayerRosterMatcher.sortRosterForCategory(
      roster: searchedRoster,
      category: widget.category,
      assignedPlayerMap: widget.assignedPlayerMap,
    );

    return AppBottomSheetContent(
      title: '選手の編集',
      titleIcon: Icons.edit_note,
      padding: EdgeInsets.zero,
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        children: [
          // 1. ポジション選択
          Text(
            '役職・ポジション',
            style: TextStyle(
              fontSize: AppFontSize.caption,
              fontWeight: AppFontWeight.bold,
              color: subTextColor,
            ),
          ),
          const SizedBox(height: AppSpacing.subValue),
          Wrap(
            spacing: AppSpacing.subValue,
            runSpacing: AppSpacing.subValue,
            children: _commonPositions.map((pos) {
              final isSelected = _selectedPosition == pos;
              return AppChoiceChip(
                label: Text(pos),
                selected: isSelected,
                selectedColor: accentColor.withValues(alpha: 0.2),
                backgroundColor: isDark
                    ? const Color(0xFF2C2C35)
                    : const Color(0xFFF2F2F7),
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedPosition = pos;
                      _positionController.text = pos;
                    });
                  }
                },
              );
            }).toList(),
          ),

          const SizedBox(height: AppSpacing.lg),

          // 2. 選手氏名入力
          Text(
            '選手氏名',
            style: TextStyle(
              fontSize: AppFontSize.caption,
              fontWeight: AppFontWeight.bold,
              color: subTextColor,
            ),
          ),
          const SizedBox(height: AppSpacing.subValue),
          AppTextField(
            controller: _nameController,
            style: TextStyle(
              fontSize: AppFontSize.body,
              fontWeight: AppFontWeight.bold,
              color: textColor,
            ),
            decoration: InputDecoration(
              hintText: '例: 皿田 脩人',
              prefixIcon: Icon(Icons.person, color: accentColor),
              isDense: true,
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF2C2C35)
                  : const Color(0xFFF2F2F7),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.mediumValue),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.mediumValue),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.mediumValue),
                borderSide: BorderSide(color: accentColor, width: 1.5),
              ),
            ),
            onChanged: (val) {
              setState(() => _rosterSearchQuery = val);
            },
          ),

          // 3. 道場名簿サジェスト
          if (widget.roster.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '道場名簿から選択',
                      style: TextStyle(
                        fontSize: AppFontSize.caption,
                        fontWeight: AppFontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                    if (widget.category != null &&
                        widget.category!.isNotEmpty) ...[
                      const SizedBox(width: AppSpacing.subValue),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.subValue,
                          vertical: AppSpacing.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(
                            AppRadius.tinyValue,
                          ),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          '${widget.category}優先',
                          style: TextStyle(
                            fontSize: AppFontSize.badge,
                            fontWeight: AppFontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (widget.assignedPlayerMap != null &&
                    widget.assignedPlayerMap!.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 12,
                        color: AppKendoColors.green,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '他枠に登録済',
                        style: TextStyle(
                          fontSize: AppFontSize.badge,
                          color: AppKendoColors.green,
                          fontWeight: AppFontWeight.bold,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.subValue),
            Material(
              color: isDark ? const Color(0xFF282830) : const Color(0xFFF7F7FA),
              borderRadius: BorderRadius.circular(AppRadius.mediumValue),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 220),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.mediumValue),
                  border: Border.all(color: borderColor),
                ),
                child: EditParsedMemberRosterList(
                  roster: filteredRoster,
                  currentName: _nameController.text,
                  category: widget.category,
                  assignedPlayerMap: widget.assignedPlayerMap,
                  accentColor: accentColor,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  borderColor: borderColor,
                  isDark: isDark,
                  onSelectName: (name) {
                    setState(() {
                      _nameController.text = name;
                    });
                  },
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),

          // 下部のアクションボタン
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      side: BorderSide(color: borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppRadius.mediumValue,
                        ),
                      ),
                    ),
                    child: Text('キャンセル', style: TextStyle(color: subTextColor)),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 2,
                  child: GlassButton(
                    onPressed: () {
                      final cleanName = _nameController.text.trim();
                      final cleanPos = _positionController.text.trim();
                      if (cleanName.isEmpty) return;

                      final updated = ParsedTeamMember(
                        position: cleanPos.isNotEmpty
                            ? cleanPos
                            : _selectedPosition,
                        name: cleanName,
                      );
                      Navigator.of(context).pop(updated);
                    },
                    color: accentColor,
                    icon: Icons.check,
                    label: '変更を適用',
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    expandContent: false,
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
