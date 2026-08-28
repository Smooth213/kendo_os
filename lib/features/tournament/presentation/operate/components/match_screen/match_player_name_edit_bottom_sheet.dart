import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_player_roster_list_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_player_roster_resolver.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/quick_roster_swap_dialog.dart';
import 'package:kendo_os/features/tournament/presentation/operate/match_screen.dart'
    show playerListProvider;
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/shared/infrastructure/repository/team_repository.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';

/// 試合画面用 選手名編集・スマートスワップボトムシート
class MatchPlayerNameEditBottomSheet extends ConsumerStatefulWidget {
  final MatchModel match;
  final String side; // 'red' or 'white'

  const MatchPlayerNameEditBottomSheet({
    super.key,
    required this.match,
    required this.side,
  });

  static Future<void> show(
    BuildContext context, {
    required MatchModel match,
    required String side,
  }) {
    return showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppKendoColors.transparent,
      builder: (ctx) =>
          MatchPlayerNameEditBottomSheet(match: match, side: side),
    );
  }

  @override
  ConsumerState<MatchPlayerNameEditBottomSheet> createState() =>
      _MatchPlayerNameEditBottomSheetState();
}

class _MatchPlayerNameEditBottomSheetState
    extends ConsumerState<MatchPlayerNameEditBottomSheet> {
  late final TextEditingController _ctrl;
  late final String _teamName;
  late final String _playerName;

  @override
  void initState() {
    super.initState();
    final String fullName = widget.side == 'red'
        ? widget.match.redName
        : widget.match.whiteName;
    _teamName = fullName.contains(':') ? fullName.split(':').first.trim() : '';
    _playerName = fullName.contains(':')
        ? fullName.split(':').last.replaceAll(')', '').trim()
        : fullName;

    _ctrl = TextEditingController(text: _playerName == '欠員' ? '' : _playerName);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _updatePlayerName(
    String newName, {
    bool isSwap = false,
    MatchModel? targetMatch,
    String? targetSide,
  }) async {
    final newFullName = _teamName.isNotEmpty
        ? '$_teamName : $newName'
        : newName;

    if (isSwap && targetMatch != null && targetSide != null) {
      final currentFullName = _teamName.isNotEmpty
          ? '$_teamName : $_playerName'
          : _playerName;

      final updatedCurrentMatch = widget.side == 'red'
          ? widget.match.copyWith(redName: newFullName)
          : widget.match.copyWith(whiteName: newFullName);

      final updatedTargetMatch = targetSide == 'red'
          ? targetMatch.copyWith(redName: currentFullName)
          : targetMatch.copyWith(whiteName: currentFullName);

      await ref.read(matchApplicationServiceProvider).saveMatchesBulk([
        updatedCurrentMatch,
        updatedTargetMatch,
      ]);
    } else {
      final updatedMatch = widget.side == 'red'
          ? widget.match.copyWith(redName: newFullName)
          : widget.match.copyWith(whiteName: newFullName);
      await ref.read(matchApplicationServiceProvider).saveMatch(updatedMatch);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = context.appColors.cardBackground;
    final textColor = context.appColors.textColor;

    final playersAsync = ref.watch(playerListProvider);
    final teamsAsync = ref.watch(
      registeredTeamsProvider(widget.match.tournamentId ?? ''),
    );

    final registeredTeams = teamsAsync.value ?? [];
    final players = playersAsync.value ?? [];
    final isOwnTeam = registeredTeams.any((t) => t.teamName == _teamName);

    final allMatches = ref.watch(matchListProvider);
    final currentGroupMatches = allMatches
        .where((m) => m.groupName == widget.match.groupName)
        .toList();

    final roster = MatchPlayerRosterResolver.resolve(
      teamName: _teamName,
      match: widget.match,
      currentGroupMatches: currentGroupMatches,
      players: players,
      registeredTeams: registeredTeams,
    );

    final activePlayerNames = roster.activePlayerNames;
    final playerPositions = roster.playerPositions;
    final substitutes = roster.substitutes;
    final sameCatActive = roster.sameCatActive;
    final dojoListSubstitutes = roster.dojoListSubstitutes;
    final otherCategoryPlayers = roster.otherCategoryPlayers;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Material(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xlargeValue),
        ),
        clipBehavior: Clip.antiAlias,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          padding: const EdgeInsets.only(
            top: AppSpacing.lg,
            left: AppSpacing.xl,
            right: AppSpacing.xl,
          ),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: context.appColors.subTextColor.withValues(alpha: 0.3),
                  borderRadius: AppRadius.compact,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                '選手名の変更',
                style: TextStyle(
                  fontSize: AppFontSize.header,
                  fontWeight: AppFontWeight.bold,
                  color: textColor,
                ),
              ),
              if (_teamName.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _teamName,
                  style: TextStyle(
                    color: context.appColors.subTextColor,
                    fontSize: AppFontSize.body,
                    fontWeight: AppFontWeight.bold,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _ctrl,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: '名前を直接入力 (助っ人など)',
                        labelStyle: const TextStyle(color: AppKendoColors.grey),
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.medium,
                          borderSide: const BorderSide(
                            color: Color(0xFF3F51B5),
                          ),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF2C2C2E)
                            : const Color(0xFFF2F2F7),
                        prefixIcon: const Icon(
                          Icons.edit,
                          color: Color(0xFF3F51B5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  ElevatedButton(
                    onPressed: () async {
                      final newName = _ctrl.text.trim().isEmpty
                          ? '欠員'
                          : _ctrl.text.trim();
                      await _updatePlayerName(newName);
                      if (context.mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3F51B5),
                      foregroundColor: AppKendoColors.pureWhite,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: AppSpacing.lg,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.medium,
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      '確定',
                      style: TextStyle(fontWeight: AppFontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await _updatePlayerName('欠員');
                    if (context.mounted) Navigator.pop(context);
                  },
                  icon: const Icon(Icons.block, size: 18),
                  label: const Text(
                    'このポジションを「欠員」にする',
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
              if (isOwnTeam && substitutes.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '補欠登録の選手（タップで交代）',
                    style: TextStyle(
                      fontSize: AppFontSize.small,
                      fontWeight: AppFontWeight.bold,
                      color: Color(0xFF009688),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: substitutes.map((p) {
                      return AppActionChip(
                        label: Text(p.name),
                        backgroundColor: isDark
                            ? const Color(0xFF009688).withValues(alpha: 0.3)
                            : const Color(0xFF009688).withValues(alpha: 0.6),
                        side: const BorderSide(color: Color(0xFF009688)),
                        labelStyle: const TextStyle(
                          color: Color(0xFF009688),
                          fontWeight: AppFontWeight.bold,
                        ),
                        onPressed: () async {
                          await _updatePlayerName(p.name);
                          if (context.mounted) Navigator.pop(context);
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
              if (isOwnTeam) ...[
                const SizedBox(height: AppSpacing.md),
                const Divider(),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '道場の名簿から選ぶ (${widget.match.category ?? "カテゴリ指定なし"})',
                    style: const TextStyle(
                      fontSize: AppFontSize.body,
                      fontWeight: AppFontWeight.bold,
                      color: Color(0xFF3F51B5),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: MatchPlayerRosterListSection(
                    sameCatActive: sameCatActive,
                    dojoListSubstitutes: dojoListSubstitutes,
                    otherCategoryPlayers: otherCategoryPlayers,
                    activePlayerNames: activePlayerNames,
                    playerPositions: playerPositions,
                    currentPlayerName: _playerName,
                    onPlayerSelected: (p, isSub) async {
                      if (isSub) {
                        await _updatePlayerName(p.name);
                      } else {
                        MatchModel? targetM;
                        String? targetS;
                        for (final m in currentGroupMatches) {
                          if (m.redName.contains(':')) {
                            final parts = m.redName.split(':');
                            if (parts.first.trim() == _teamName &&
                                parts.last.trim() == p.name) {
                              targetM = m;
                              targetS = 'red';
                              break;
                            }
                          }
                          if (m.whiteName.contains(':')) {
                            final parts = m.whiteName.split(':');
                            if (parts.first.trim() == _teamName &&
                                parts.last.trim() == p.name) {
                              targetM = m;
                              targetS = 'white';
                              break;
                            }
                          }
                        }
                        await _updatePlayerName(
                          p.name,
                          isSwap: true,
                          targetMatch: targetM,
                          targetSide: targetS,
                        );
                      }
                      if (context.mounted) Navigator.pop(context);
                    },
                    onOpenFullReorder: currentGroupMatches.length > 1
                        ? () {
                            Navigator.pop(context);
                            QuickRosterSwapDialog.show(
                              context,
                              currentMatch: widget.match,
                              teamMatches: currentGroupMatches,
                              isRedSide: widget.side == 'red',
                            );
                          }
                        : null,
                  ),
                ),
              ] else ...[
                if (currentGroupMatches.length > 1) ...[
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      QuickRosterSwapDialog.show(
                        context,
                        currentMatch: widget.match,
                        teamMatches: currentGroupMatches,
                        isRedSide: widget.side == 'red',
                      );
                    },
                    icon: const Icon(Icons.drag_handle_rounded),
                    label: const Text('全体オーダーを並び替える (ドラッグ＆ドロップ)'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.medium,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
