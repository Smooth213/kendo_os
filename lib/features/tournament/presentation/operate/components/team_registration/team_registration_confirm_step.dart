import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/registered_team_card.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';

/// チーム登録画面 ページ3: 登録プレビュー＆登録済み一覧（カテゴリ分類＆タップ編集対応）
class TeamRegistrationConfirmStep extends StatefulWidget {
  final AsyncValue<List<TeamModel>> registeredTeamsAsync;
  final int playerCount;
  final String selectedCategory;
  final String teamName;
  final String matchType;
  final Map<int, String> tempSelectedPlayers;
  final AppThemeColors themeColors;
  final void Function(TeamModel team) onEditTeam;
  final void Function(String teamId) onDeleteTeam;
  final void Function(TeamModel team, String newCategory)? onUpdateCategory;
  final VoidCallback? onAddNewTeam;

  const TeamRegistrationConfirmStep({
    super.key,
    required this.registeredTeamsAsync,
    required this.playerCount,
    required this.selectedCategory,
    required this.teamName,
    required this.matchType,
    required this.tempSelectedPlayers,
    required this.themeColors,
    required this.onEditTeam,
    required this.onDeleteTeam,
    this.onUpdateCategory,
    this.onAddNewTeam,
  });

  @override
  State<TeamRegistrationConfirmStep> createState() =>
      _TeamRegistrationConfirmStepState();
}

class _TeamRegistrationConfirmStepState
    extends State<TeamRegistrationConfirmStep> {
  String _selectedCategoryFilter = 'すべて';

  Widget _buildSectionTitle(String title, {IconData? icon, Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: widget.themeColors.primaryAccent),
            const SizedBox(width: AppSpacing.subValue),
          ],
          Text(
            title,
            style: TextStyle(
              fontSize: AppFontSize.subhead,
              fontWeight: AppFontWeight.bold,
              color: widget.themeColors.primaryAccent,
            ),
          ),
          if (trailing != null) ...[const Spacer(), trailing],
        ],
      ),
    );
  }

  /// カテゴリをワンタップで変更できるダイアログ
  void _showChangeCategoryDialog(BuildContext context, TeamModel team) {
    final candidateCategories = [
      '小学生低学年の部',
      '小学生高学年の部',
      '小学生の部',
      '中学生の部',
      '中学生男子の部',
      '中学生女子の部',
      '高校生の部',
      '一般の部',
    ];

    showAppBottomSheet(
      context: context,
      builder: (ctx) {
        return AppBottomSheetContent(
          title: '「${team.teamName}」のカテゴリ変更',
          titleIcon: Icons.category,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '所属する部門（カテゴリ）を選択してください：',
                style: TextStyle(
                  fontSize: AppFontSize.small,
                  color: context.appColors.subTextColor,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: candidateCategories.map((cat) {
                  final isCurrent = team.category == cat;
                  return AppChoiceChip(
                    label: Text(cat),
                    selected: isCurrent,
                    selectedColor: widget.themeColors.primaryAccent.withValues(
                      alpha: 0.2,
                    ),
                    onSelected: (selected) {
                      Navigator.pop(ctx);
                      if (widget.onUpdateCategory != null) {
                        widget.onUpdateCategory!(team, cat);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = context.appColors.textColor;
    final subTextColor = context.appColors.subTextColor;
    final inputBgColor = widget.themeColors.cardBackground;
    final borderColor = isDark
        ? const Color(0xFF38383A)
        : context.appColors.separatorColor;
    final accentColor = widget.themeColors.primaryAccent;

    final isInputting =
        widget.teamName.trim().isNotEmpty ||
        widget.tempSelectedPlayers.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        // 登録済みチーム一覧（最上部に配置してすぐに見えるようにする！）
        widget.registeredTeamsAsync.when(
          data: (teams) {
            // カテゴリごとのグルーピング集計
            final Map<String, List<TeamModel>> groupedTeams = {};
            for (final t in teams) {
              final cat = t.category.trim().isNotEmpty
                  ? t.category.trim()
                  : '一般の部';
              groupedTeams.putIfAbsent(cat, () => []).add(t);
            }

            final allCategories = groupedTeams.keys.toList()..sort();
            final displayedCategories = _selectedCategoryFilter == 'すべて'
                ? allCategories
                : allCategories
                      .where((c) => c == _selectedCategoryFilter)
                      .toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // タイトル＆新規追加ボタン（折り返し崩れを防ぐクリーンな配置）
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '登録済みチーム (${teams.length})',
                            style: TextStyle(
                              fontSize: AppFontSize.headline,
                              fontWeight: AppFontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'カードタップで直接オーダーを編集できます',
                            style: TextStyle(
                              fontSize: AppFontSize.caption,
                              color: subTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.onAddNewTeam != null)
                      ElevatedButton.icon(
                        onPressed: widget.onAddNewTeam,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('新規追加'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor.withValues(alpha: 0.15),
                          foregroundColor: accentColor,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppRadius.smallValue,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // カテゴリ分類フィルタチップ（カテゴリが2つ以上存在する場合に表示）
                if (allCategories.length > 1) ...[
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            right: AppSpacing.subValue,
                          ),
                          child: AppChoiceChip(
                            label: Text('すべて (${teams.length})'),
                            selected: _selectedCategoryFilter == 'すべて',
                            selectedColor: accentColor.withValues(alpha: 0.2),
                            onSelected: (_) =>
                                setState(() => _selectedCategoryFilter = 'すべて'),
                          ),
                        ),
                        ...allCategories.map((cat) {
                          final count = groupedTeams[cat]?.length ?? 0;
                          final isSel = _selectedCategoryFilter == cat;
                          return Padding(
                            padding: const EdgeInsets.only(
                              right: AppSpacing.subValue,
                            ),
                            child: AppChoiceChip(
                              label: Text('$cat ($count)'),
                              selected: isSel,
                              selectedColor: accentColor.withValues(alpha: 0.2),
                              onSelected: (_) =>
                                  setState(() => _selectedCategoryFilter = cat),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],

                if (teams.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: inputBgColor,
                      borderRadius: BorderRadius.circular(
                        AppRadius.mediumValue,
                      ),
                      border: Border.all(color: borderColor),
                    ),
                    child: Center(
                      child: Text(
                        'まだ登録されたチームはありません。\n新規追加ボタンからチームを登録してください。',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: subTextColor),
                      ),
                    ),
                  )
                else
                  // カテゴリごとの分類セクション
                  ...displayedCategories.map((cat) {
                    final categoryTeams = groupedTeams[cat] ?? [];
                    if (categoryTeams.isEmpty) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // カテゴリ見出しヘッダー
                        Container(
                          margin: const EdgeInsets.only(
                            top: AppSpacing.md,
                            bottom: AppSpacing.sm,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.subValue,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(
                              AppRadius.smallValue,
                            ),
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.18),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.category,
                                size: 16,
                                color: accentColor,
                              ),
                              const SizedBox(width: AppSpacing.subValue),
                              Expanded(
                                child: Text(
                                  cat,
                                  style: TextStyle(
                                    fontSize: AppFontSize.subhead,
                                    fontWeight: AppFontWeight.bold,
                                    color: accentColor,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: accentColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.smallValue,
                                  ),
                                ),
                                child: Text(
                                  '${categoryTeams.length}チーム',
                                  style: TextStyle(
                                    fontSize: AppFontSize.caption,
                                    fontWeight: AppFontWeight.bold,
                                    color: accentColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // カテゴリに属するチームカード群
                        ...categoryTeams.map(
                          (t) => RegisteredTeamCard(
                            team: t,
                            themeColors: widget.themeColors,
                            onEditTeam: widget.onEditTeam,
                            onDeleteTeam: widget.onDeleteTeam,
                            onChangeCategory: (team) =>
                                _showChangeCategoryDialog(context, team),
                          ),
                        ),
                      ],
                    );
                  }),
              ],
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, s) => Center(child: Text('エラー: $e')),
        ),

        const SizedBox(height: AppSpacing.xxl),

        // 入力中・編集中チームプレビュー（入力されている場合のみ表示）
        if (isInputting) ...[
          _buildSectionTitle(
            widget.teamName.isNotEmpty
                ? '「${widget.teamName}」の入力内容'
                : '新規登録中のチームプレビュー',
            icon: Icons.pending_actions,
          ),
          Card(
            elevation: 0,
            color: inputBgColor,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.large,
              side: BorderSide(
                color: widget.themeColors.primaryAccent,
                width: 2,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(AppSpacing.lg),
              title: Text(
                '${widget.selectedCategory} : ${widget.teamName.isEmpty ? "(チーム名未入力)" : widget.teamName}',
                style: TextStyle(
                  fontWeight: AppFontWeight.bold,
                  fontSize: AppFontSize.subhead,
                  color: textColor,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  '${widget.matchType}\n選手: ${List.generate(widget.playerCount, (i) => widget.tempSelectedPlayers[i] ?? '').where((n) => n.isNotEmpty).join(", ")}',
                  style: TextStyle(height: 1.5, color: textColor),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
