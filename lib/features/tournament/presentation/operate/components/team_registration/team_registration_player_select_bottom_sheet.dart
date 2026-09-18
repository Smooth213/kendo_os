import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_player_filter_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_select_header_actions.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_selection_card.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

/// 🏆 チーム登録: カテゴリ連動上位表示 ＋ リアルタイム絞り込み ＋ 助っ人即時登録対応の選手選択ボトムシート
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
        maxHeight: MediaQuery.of(context).size.height * 0.88,
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
  bool _showAllPlayers = true; // デフォルトで同カテゴリ優先の上位表示＋その他表示

  @override
  void initState() {
    super.initState();
    _customNameController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _customNameController.removeListener(_onSearchChanged);
    _customNameController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  InputDecoration _buildTextFieldDecoration({
    required String labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(color: widget.themeColors.subTextColor),
      hintText: hintText,
      hintStyle: TextStyle(color: widget.themeColors.hintColor),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
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

  Widget _buildPlayerCard(PlayerModel p, bool isDark) {
    int? usedIdx;
    widget.tempSelectedPlayers.forEach((k, v) {
      if (v == p.name) usedIdx = k;
    });
    final isUsed = usedIdx != null && usedIdx != widget.index;

    return TeamRegistrationSelectionCard(
      name: p.name,
      subtitle: '${p.gradeName}${p.isBeginner ? " (🔰初心者)" : ""}',
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
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = context.appColors.textColor;
    final query = _customNameController.text.trim();

    final helperEntries = TeamRegistrationPlayerFilterHelper.getHelperEntries(
      tempSelectedPlayers: widget.tempSelectedPlayers,
      players: widget.players,
      query: query,
    );

    final recommendedPlayers =
        TeamRegistrationPlayerFilterHelper.getRecommendedPlayers(
          players: widget.players,
          majorCategory: widget.selectedMajorCategory,
          minorCategory: widget.selectedMinorCategory,
          query: query,
        );

    final otherPlayers = TeamRegistrationPlayerFilterHelper.getOtherPlayers(
      players: widget.players,
      majorCategory: widget.selectedMajorCategory,
      minorCategory: widget.selectedMinorCategory,
      query: query,
    );

    final currentPosName = widget.index < widget.posNames.length
        ? widget.posNames[widget.index]
        : '選手';

    return AppBottomSheetContent(
      title: '選手の選択 ($currentPosName)',
      titleTrailing: TextButton.icon(
        onPressed: () => setState(() => _showAllPlayers = !_showAllPlayers),
        icon: Icon(
          _showAllPlayers ? Icons.filter_alt_outlined : Icons.filter_alt,
          size: 14,
        ),
        label: Text(
          _showAllPlayers ? 'おすすめのみ' : '全員表示',
          style: const TextStyle(
            fontSize: AppFontSize.caption,
            fontWeight: AppFontWeight.bold,
          ),
        ),
        style: TextButton.styleFrom(
          foregroundColor: widget.themeColors.primaryAccent,
          backgroundColor: widget.themeColors.softAccent,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _customNameController,
              style: TextStyle(color: textColor),
              onSubmitted: (val) {
                final trimmed = val.trim();
                if (trimmed.isNotEmpty) {
                  Navigator.pop(context, trimmed);
                }
              },
              decoration: _buildTextFieldDecoration(
                labelText: '選手名で検索 / 助っ人を直接入力',
                hintText: '名前やふりがなを入力',
                prefixIcon: Icon(
                  Icons.search,
                  color: widget.themeColors.primaryAccent,
                ),
                suffixIcon: query.isNotEmpty
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => _customNameController.clear(),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              right: AppSpacing.xs,
                            ),
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context, query),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    widget.themeColors.primaryAccent,
                                foregroundColor: AppKendoColors.pureWhite,
                                shape: RoundedRectangleBorder(
                                  borderRadius: AppRadius.medium,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.xs,
                                ),
                                elevation: 0,
                              ),
                              child: const Text('確定'),
                            ),
                          ),
                        ],
                      )
                    : null,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TeamRegistrationSelectHeaderActions(
                          query: query,
                          currentIndex: widget.index,
                          posNames: widget.posNames,
                          helperEntries: helperEntries,
                          themeColors: widget.themeColors,
                          isDark: isDark,
                          textColor: textColor,
                          onSelected: (val) => Navigator.pop(context, val),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm,
                          ),
                          child: Row(
                            children: [
                              Text(
                                'おすすめの選手（同カテゴリ）',
                                style: TextStyle(
                                  fontSize: AppFontSize.small,
                                  fontWeight: AppFontWeight.bold,
                                  color: widget.themeColors.primaryAccent,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.subValue,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: widget.themeColors.softAccent,
                                  borderRadius: AppRadius.tiny,
                                ),
                                child: Text(
                                  '${recommendedPlayers.length}',
                                  style: TextStyle(
                                    fontSize: AppFontSize.caption,
                                    fontWeight: AppFontWeight.bold,
                                    color: widget.themeColors.primaryAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (recommendedPlayers.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                            child: Text(
                              query.isEmpty
                                  ? '該当する同カテゴリ選手がいません'
                                  : '「$query」に一致する同カテゴリ選手はいません',
                              style: TextStyle(
                                color: context.appColors.subTextColor,
                                fontSize: AppFontSize.bodySmall,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SliverList.builder(
                    itemCount: recommendedPlayers.length,
                    itemBuilder: (context, idx) =>
                        _buildPlayerCard(recommendedPlayers[idx], isDark),
                  ),
                  if (_showAllPlayers) ...[
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppSpacing.lg),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.sm,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'その他の所属選手',
                                  style: TextStyle(
                                    fontSize: AppFontSize.small,
                                    fontWeight: AppFontWeight.bold,
                                    color: context.appColors.subTextColor,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.subValue,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF38383A)
                                        : const Color(0xFFE5E5EA),
                                    borderRadius: AppRadius.tiny,
                                  ),
                                  child: Text(
                                    '${otherPlayers.length}',
                                    style: TextStyle(
                                      fontSize: AppFontSize.caption,
                                      fontWeight: AppFontWeight.bold,
                                      color: context.appColors.subTextColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (otherPlayers.isEmpty && query.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md,
                              ),
                              child: Text(
                                '「$query」に一致するその他の選手はいません',
                                style: TextStyle(
                                  color: context.appColors.subTextColor,
                                  fontSize: AppFontSize.bodySmall,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    SliverList.builder(
                      itemCount: otherPlayers.length,
                      itemBuilder: (context, idx) =>
                          _buildPlayerCard(otherPlayers[idx], isDark),
                    ),
                  ],
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.xxl),
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
