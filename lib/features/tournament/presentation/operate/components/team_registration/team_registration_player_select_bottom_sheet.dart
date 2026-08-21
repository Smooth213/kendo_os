import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_selection_card.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

/// 🏆 チーム登録: カテゴリ連動フィルタリング ＋ よみがな順ソートを搭載した選手選択ボトムシート
class TeamRegistrationPlayerSelectBottomSheet extends StatefulWidget {
  final int index;
  final List<PlayerModel> players;
  final List<String> posNames;
  final Map<int, String> tempSelectedPlayers;
  final String selectedMajorCategory;
  final String selectedMinorCategory;
  final AppThemeColors themeColors;

  const TeamRegistrationPlayerSelectBottomSheet({
    super.key,
    required this.index,
    required this.players,
    required this.posNames,
    required this.tempSelectedPlayers,
    required this.selectedMajorCategory,
    required this.selectedMinorCategory,
    required this.themeColors,
  });

  static Future<String?> show({
    required BuildContext context,
    required int index,
    required List<PlayerModel> players,
    required List<String> posNames,
    required Map<int, String> tempSelectedPlayers,
    required String selectedMajorCategory,
    required String selectedMinorCategory,
    required AppThemeColors themeColors,
  }) {
    return showAppBottomSheet<String>(
      context: context,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      builder: (ctx) => TeamRegistrationPlayerSelectBottomSheet(
        index: index,
        players: players,
        posNames: posNames,
        tempSelectedPlayers: tempSelectedPlayers,
        selectedMajorCategory: selectedMajorCategory,
        selectedMinorCategory: selectedMinorCategory,
        themeColors: themeColors,
      ),
    );
  }

  @override
  State<TeamRegistrationPlayerSelectBottomSheet> createState() =>
      _TeamRegistrationPlayerSelectBottomSheetState();
}

class _TeamRegistrationPlayerSelectBottomSheetState
    extends State<TeamRegistrationPlayerSelectBottomSheet> {
  final TextEditingController _customNameController = TextEditingController();
  bool _showAllPlayers = false;

  @override
  void dispose() {
    _customNameController.dispose();
    super.dispose();
  }

  InputDecoration _buildTextFieldDecoration({
    required String labelText,
    String? hintText,
    Widget? prefixIcon,
    String? suffixText,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(color: widget.themeColors.subTextColor),
      hintText: hintText,
      hintStyle: TextStyle(color: widget.themeColors.hintColor),
      suffixText: suffixText,
      suffixStyle: TextStyle(color: widget.themeColors.subTextColor),
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: widget.themeColors.inputBackground,
      border: OutlineInputBorder(borderRadius: AppRadius.medium),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.medium,
        borderSide: BorderSide(
          color: widget.themeColors.separatorColor,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.medium,
        borderSide: BorderSide(
          color: widget.themeColors.primaryAccent,
          width: 2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = context.appColors.textColor;

    // 手入力選手の抽出
    final helperEntries = widget.tempSelectedPlayers.entries
        .where((e) => e.value.isNotEmpty && e.value != '欠員')
        .where((e) => !widget.players.any((p) => p.name == e.value))
        .toList();

    // --- フィルタリングロジックの実行 ---
    List<PlayerModel> displayList = widget.players;
    if (!_showAllPlayers) {
      if (widget.selectedMajorCategory == '初心者') {
        displayList = widget.players.where((p) => p.isBeginner).toList();
      } else if (widget.selectedMajorCategory == '幼年') {
        displayList = widget.players.where((p) => p.grade == 0).toList();
      } else if (widget.selectedMajorCategory == '小学生') {
        if (widget.selectedMinorCategory == '低学年') {
          displayList = widget.players
              .where((p) => p.grade >= 1 && p.grade <= 4)
              .toList();
        } else if (widget.selectedMinorCategory == '高学年') {
          displayList = widget.players
              .where((p) => p.grade >= 5 && p.grade <= 6)
              .toList();
        } else if (widget.selectedMinorCategory.contains('年')) {
          int targetGrade =
              int.tryParse(widget.selectedMinorCategory.replaceAll('年', '')) ??
              0;
          displayList = widget.players
              .where((p) => p.grade == targetGrade)
              .toList();
        } else {
          displayList = widget.players
              .where((p) => p.grade >= 1 && p.grade <= 6)
              .toList();
        }
      } else if (widget.selectedMajorCategory == '中学生') {
        displayList = widget.players
            .where((p) => p.grade >= 7 && p.grade <= 9)
            .toList();
      } else if (widget.selectedMajorCategory == '高校生') {
        displayList = widget.players
            .where((p) => p.grade >= 10 && p.grade <= 12)
            .toList();
      } else if (widget.selectedMajorCategory == '大学・一般') {
        displayList = widget.players.where((p) => p.grade >= 13).toList();
      }
    }

    // よみがな順でソート（常に美しく並ぶ）
    displayList.sort((a, b) => a.nameKana.compareTo(b.nameKana));

    final currentPosName = widget.index < widget.posNames.length
        ? widget.posNames[widget.index]
        : '選手';

    return AppBottomSheetContent(
      title: '選手の選択 ($currentPosName)',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '選手の選択 ($currentPosName)',
                    style: TextStyle(
                      fontSize: AppFontSize.headline,
                      fontWeight: AppFontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                // ★ フィルタ切り替えボタン
                TextButton.icon(
                  onPressed: () =>
                      setState(() => _showAllPlayers = !_showAllPlayers),
                  icon: Icon(
                    _showAllPlayers ? Icons.filter_alt : Icons.filter_alt_off,
                    size: 14,
                  ),
                  label: Text(
                    _showAllPlayers ? 'フィルタ適用' : '全員表示',
                    style: const TextStyle(
                      fontSize: AppFontSize.caption,
                      fontWeight: AppFontWeight.bold,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: widget.themeColors.primaryAccent,
                    backgroundColor: widget.themeColors.softAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // 助っ人直接入力
            AppTextField(
              controller: _customNameController,
              style: TextStyle(color: textColor),
              decoration:
                  _buildTextFieldDecoration(
                    labelText: '助っ人の名前を直接入力',
                    prefixIcon: Icon(
                      Icons.person_add_alt_1,
                      color: widget.themeColors.primaryAccent,
                    ),
                  ).copyWith(
                    suffixIcon: Padding(
                      padding: const EdgeInsets.only(
                        right: AppSpacing.sm,
                        top: AppSpacing.xs,
                        bottom: AppSpacing.xs,
                      ),
                      child: ElevatedButton(
                        onPressed: () =>
                            Navigator.pop(context, _customNameController.text),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.themeColors.primaryAccent,
                          foregroundColor: AppKendoColors.pureWhite,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.medium,
                          ),
                          elevation: 0,
                        ),
                        child: const Text('確定'),
                      ),
                    ),
                  ),
            ),
            const SizedBox(height: AppSpacing.xl),

            Expanded(
              child: ListView(
                children: [
                  if (helperEntries.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      child: Text(
                        '現在チームにいる手入力選手',
                        style: TextStyle(
                          fontSize: AppFontSize.small,
                          fontWeight: AppFontWeight.bold,
                          color: const Color(0xFFFF9800),
                        ),
                      ),
                    ),
                    ...helperEntries.map((entry) {
                      if (entry.key == widget.index) {
                        return const SizedBox.shrink();
                      }
                      return TeamRegistrationSelectionCard(
                        name: entry.value,
                        subtitle: '手入力選手',
                        isUsed: true,
                        usedPos: entry.key < widget.posNames.length
                            ? widget.posNames[entry.key]
                            : '補欠',
                        isDark: isDark,
                        isHelper: true,
                        onTap: () => Navigator.pop(context, entry.value),
                      );
                    }),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    child: Text(
                      _showAllPlayers ? '名簿の全選手' : 'おすすめの選手',
                      style: TextStyle(
                        fontSize: AppFontSize.small,
                        fontWeight: AppFontWeight.bold,
                        color: widget.themeColors.primaryAccent,
                      ),
                    ),
                  ),

                  // 欠員・未定ボタン
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, 'CLEAR_FLAG'),
                          child: const Text('未定'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, '欠員'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppKendoColors.red,
                          ),
                          child: const Text('欠員'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  if (displayList.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      child: Column(
                        children: [
                          Icon(
                            Icons.person_search,
                            size: 48,
                            color: AppKendoColors.grey.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            '該当する選手がいません',
                            style: TextStyle(
                              color: const Color(0x8A000000),
                              fontSize: AppFontSize.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),

                  ...displayList.map((p) {
                    int? usedIdx;
                    widget.tempSelectedPlayers.forEach((k, v) {
                      if (v == p.name) usedIdx = k;
                    });
                    final isUsed = usedIdx != null && usedIdx != widget.index;

                    return TeamRegistrationSelectionCard(
                      name: p.name,
                      subtitle:
                          '${p.gradeName}${p.isBeginner ? " (🔰初心者)" : ""}',
                      isUsed: isUsed,
                      usedPos: usedIdx != null
                          ? (usedIdx! < widget.posNames.length
                                ? widget.posNames[usedIdx!]
                                : '補欠')
                          : '',
                      isDark: isDark,
                      isBeginner: p.isBeginner,
                      onTap: () => Navigator.pop(context, p.name),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
