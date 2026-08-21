import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// チーム登録画面 ページ3: 登録プレビュー＆登録済み一覧
class TeamRegistrationConfirmStep extends StatelessWidget {
  final AsyncValue<List<TeamModel>> registeredTeamsAsync;
  final int playerCount;
  final String selectedCategory;
  final String teamName;
  final String matchType;
  final Map<int, String> tempSelectedPlayers;
  final AppThemeColors themeColors;
  final void Function(TeamModel team) onEditTeam;
  final void Function(String teamId) onDeleteTeam;

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
  });

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(
        title,
        style: TextStyle(
          fontSize: AppFontSize.subhead,
          fontWeight: AppFontWeight.bold,
          color: themeColors.primaryAccent,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = context.appColors.textColor;
    final inputBgColor = themeColors.cardBackground;
    final borderColor = isDark
        ? const Color(0xFF38383A)
        : context.appColors.separatorColor;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        Text(
          '登録内容の確認と\n登録済みの一覧です',
          style: TextStyle(
            fontSize: AppFontSize.titleLarge,
            fontWeight: AppFontWeight.bold,
            height: 1.4,
            color: textColor,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        _buildSectionTitle('今回登録するチームのプレビュー'),
        Card(
          elevation: 0,
          color: inputBgColor,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.large,
            side: BorderSide(color: themeColors.primaryAccent, width: 2),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(AppSpacing.lg),
            title: Text(
              '$selectedCategory : ${teamName.isEmpty ? "(チーム名未入力)" : teamName}',
              style: TextStyle(
                fontWeight: AppFontWeight.bold,
                fontSize: AppFontSize.subhead,
                color: textColor,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                '$matchType\n選手: ${List.generate(playerCount, (i) => tempSelectedPlayers[i] ?? '').where((n) => n.isNotEmpty).join(", ")}',
                style: TextStyle(
                  height: 1.5,
                  color: isDark
                      ? const Color(0xFFFFFFFF)
                      : const Color(0xDE000000),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        _buildSectionTitle('現在の登録済み一覧'),
        registeredTeamsAsync.when(
          data: (teams) {
            if (teams.isEmpty) {
              return const Text(
                'まだ登録されたチームはありません',
                style: TextStyle(color: AppKendoColors.grey),
              );
            }
            return Column(
              children: teams
                  .map(
                    (t) => Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      elevation: 0,
                      color: inputBgColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.large,
                        side: BorderSide(color: borderColor),
                      ),
                      child: ListTile(
                        title: Text(
                          '${t.category} : ${t.teamName}',
                          style: TextStyle(
                            fontWeight: AppFontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        subtitle: Text(
                          '${t.matchType} / 選手: ${t.playerNames.where((n) => n.isNotEmpty).join(", ")}',
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFFFFFFFF)
                                : const Color(0x8A000000),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.edit,
                                color: themeColors.primaryAccent,
                              ),
                              onPressed: () => onEditTeam(t),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: AppKendoColors.red,
                              ),
                              onPressed: () => onDeleteTeam(t.id),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Text('エラー: $e'),
        ),
      ],
    );
  }
}
