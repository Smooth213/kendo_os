import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/team_repository.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';

/// チーム詳細およびオーダー入替ダイアログ
class MatchFormatTeamDetailDialog extends ConsumerStatefulWidget {
  final TeamModel team;
  final List<String> posNames;
  final AppThemeColors themeColors;
  final List<PlayerModel> players;
  final ValueChanged<TeamModel> onTeamUpdated;

  const MatchFormatTeamDetailDialog({
    super.key,
    required this.team,
    required this.posNames,
    required this.themeColors,
    required this.players,
    required this.onTeamUpdated,
  });

  static Future<void> show({
    required BuildContext context,
    required TeamModel team,
    required List<String> posNames,
    required AppThemeColors themeColors,
    required List<PlayerModel> players,
    required ValueChanged<TeamModel> onTeamUpdated,
  }) {
    return showAppDialog(
      context: context,
      builder: (ctx) => MatchFormatTeamDetailDialog(
        team: team,
        posNames: posNames,
        themeColors: themeColors,
        players: players,
        onTeamUpdated: onTeamUpdated,
      ),
    );
  }

  @override
  ConsumerState<MatchFormatTeamDetailDialog> createState() =>
      _MatchFormatTeamDetailDialogState();
}

class _MatchFormatTeamDetailDialogState
    extends ConsumerState<MatchFormatTeamDetailDialog> {
  late TeamModel _currentTeam;

  @override
  void initState() {
    super.initState();
    _currentTeam = widget.team;
  }

  Future<void> _selectAndSwapPlayer(int index) async {
    final players = widget.players;

    final helperEntries = _currentTeam.playerNames
        .asMap()
        .entries
        .where((e) => e.value.isNotEmpty && e.value != '欠員')
        .where((e) => !players.any((p) => p.name == e.value))
        .toList();

    final selected = await showAppBottomSheet<String>(
      context: context,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      builder: (ctx) => AppBottomSheetContent(
        title: '${widget.posNames[index]} の選択',
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: ListView(
            children: [
              if (helperEntries.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Text(
                    '手入力選手から選ぶ',
                    style: TextStyle(
                      fontWeight: AppFontWeight.bold,
                      color: AppKendoColors.orange,
                    ),
                  ),
                ),
                ...helperEntries.map(
                  (entry) => Card(
                    color: const Color(0xFFFF9800),
                    child: ListTile(
                      title: Text(
                        entry.value,
                        style: const TextStyle(fontWeight: AppFontWeight.bold),
                      ),
                      trailing: Text(
                        '${entry.key < widget.posNames.length ? widget.posNames[entry.key] : "補欠"}と入替',
                        style: const TextStyle(
                          fontSize: AppFontSize.caption,
                          color: AppKendoColors.orange,
                        ),
                      ),
                      onTap: () => Navigator.pop(ctx, entry.value),
                    ),
                  ),
                ),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text(
                  '登録名簿から選ぶ',
                  style: TextStyle(
                    fontWeight: AppFontWeight.bold,
                    color: widget.themeColors.primaryAccent,
                  ),
                ),
              ),
              ...players.map((p) {
                final usedIdx = _currentTeam.playerNames.indexOf(p.name);
                final isUsed = usedIdx != -1 && usedIdx != index;
                return ListTile(
                  title: Text(p.name),
                  trailing: isUsed
                      ? Text(
                          '${usedIdx < widget.posNames.length ? widget.posNames[usedIdx] : "補欠"}と入替',
                          style: const TextStyle(
                            fontSize: AppFontSize.caption,
                            color: AppKendoColors.orange,
                          ),
                        )
                      : null,
                  onTap: () => Navigator.pop(ctx, p.name),
                );
              }),
            ],
          ),
        ),
      ),
    );

    if (selected != null) {
      List<String> newOrder = List.from(_currentTeam.playerNames);
      int existingIdx = newOrder.indexOf(selected);

      if (existingIdx != -1) {
        String currentOccupant = newOrder[index];
        newOrder[existingIdx] = currentOccupant;
      }
      newOrder[index] = selected;

      final updatedTeam = _currentTeam.copyWith(playerNames: newOrder);
      await ref.read(teamRepositoryProvider).saveTeam(updatedTeam);
      setState(() {
        _currentTeam = updatedTeam;
      });
      widget.onTeamUpdated(updatedTeam);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.xlarge),
      backgroundColor: AppKendoColors.pureWhite,
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.xl,
                horizontal: AppSpacing.xl,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.themeColors.primaryAccent,
                    widget.themeColors.primaryAccent.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppKendoColors.pureWhite.withValues(
                      alpha: 0.24,
                    ),
                    child: const Icon(
                      Icons.shield,
                      color: AppKendoColors.pureWhite,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentTeam.teamName,
                          style: const TextStyle(
                            color: AppKendoColors.pureWhite,
                            fontSize: AppFontSize.header,
                            fontWeight: AppFontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${_currentTeam.category} / ${_currentTeam.matchType}',
                          style: TextStyle(
                            color: AppKendoColors.pureWhite.withValues(
                              alpha: 0.7,
                            ),
                            fontSize: AppFontSize.small,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: AppSpacing.lg, left: AppSpacing.xl),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'オーダー（タップして入れ替え）',
                  style: TextStyle(
                    fontSize: AppFontSize.small,
                    fontWeight: AppFontWeight.bold,
                    color: AppKendoColors.grey,
                  ),
                ),
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.all(AppSpacing.roundValue),
                itemCount: _currentTeam.playerNames.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final String posName = i < widget.posNames.length
                      ? widget.posNames[i]
                      : '補欠';
                  final String name = _currentTeam.playerNames[i].isEmpty
                      ? '未設定'
                      : _currentTeam.playerNames[i];
                  final bool isSub = posName == '補欠';

                  final bool isDark =
                      Theme.of(context).brightness == Brightness.dark;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () => _selectAndSwapPlayer(i),
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: isSub
                          ? (isDark
                                ? const Color(0xFFFF9800).withValues(alpha: 0.2)
                                : const Color(0xFFFFF3E0))
                          : widget.themeColors.softAccent,
                      child: Text(
                        isSub ? '補' : posName.substring(0, 1),
                        style: TextStyle(
                          color: isSub
                              ? (isDark
                                    ? const Color(0xFFFFB74D)
                                    : const Color(0xFFE65100))
                              : widget.themeColors.primaryAccent,
                          fontWeight: AppFontWeight.bold,
                          fontSize: AppFontSize.bodySmall,
                        ),
                      ),
                    ),
                    title: Text(
                      name,
                      style: TextStyle(
                        fontWeight: AppFontWeight.bold,
                        color: name == '未設定'
                            ? AppKendoColors.grey
                            : AppKendoColors.pureBlack,
                      ),
                    ),
                    subtitle: Text(
                      posName,
                      style: TextStyle(
                        color: isSub
                            ? const Color(0xFFFF9800)
                            : widget.themeColors.primaryAccent,
                        fontSize: AppFontSize.caption,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.swap_vert,
                      color: AppKendoColors.grey,
                      size: 20,
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  '完了',
                  style: TextStyle(
                    fontWeight: AppFontWeight.bold,
                    color: widget.themeColors.primaryAccent,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
