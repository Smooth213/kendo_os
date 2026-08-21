import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/match_screen.dart'
    show playerListProvider;
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
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

  String _getPlayerCategory(int grade) {
    if (grade == -1) return '初心者の部';
    if (grade == 0) return '幼年の部';
    if (grade >= 1 && grade <= 4) return '小学生低学年の部';
    if (grade >= 5 && grade <= 6) return '小学生高学年の部';
    if (grade >= 7 && grade <= 9) return '中学生の部';
    if (grade >= 10 && grade <= 12) return '高校生の部';
    return '一般の部';
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

    final activePlayerNames = <String>{};
    final playerPositions = <String, String>{};
    for (final m in currentGroupMatches) {
      if (m.redName.contains(':')) {
        final parts = m.redName.split(':');
        if (parts.first.trim() == _teamName) {
          final name = parts.last.trim();
          activePlayerNames.add(name);
          playerPositions[name] = m.matchType;
        }
      }
      if (m.whiteName.contains(':')) {
        final parts = m.whiteName.split(':');
        if (parts.first.trim() == _teamName) {
          final name = parts.last.trim();
          activePlayerNames.add(name);
          playerPositions[name] = m.matchType;
        }
      }
    }

    final ownTeamPlayers = players.where((p) {
      final org = p.organization.trim();
      if (org.isEmpty) return false;
      return _teamName.contains(org) || org.contains(_teamName);
    }).toList();

    final matchedTeam = registeredTeams.firstWhere(
      (t) => t.teamName == _teamName || _teamName == t.teamName,
      orElse: () {
        return registeredTeams.firstWhere(
          (t) =>
              _teamName.contains(t.teamName) || t.teamName.contains(_teamName),
          orElse: () => TeamModel(
            id: '',
            tournamentId: '',
            category: '',
            teamName: '',
            matchType: '',
            playerNames: [],
          ),
        );
      },
    );
    final teamRegisteredPlayerNames = matchedTeam.playerNames
        .where((name) => name.isNotEmpty)
        .toSet();

    final Set<String> ownPlayerNames = ownTeamPlayers
        .map((p) => p.name)
        .toSet();
    final List<PlayerModel> finalOwnTeamPlayers = List<PlayerModel>.from(
      ownTeamPlayers,
    );

    for (final name in teamRegisteredPlayerNames) {
      if (!ownPlayerNames.contains(name)) {
        final found = players.firstWhere(
          (p) => p.name == name,
          orElse: () => PlayerModel(
            id: 'virtual_$name',
            lastName: name,
            firstName: '',
            lastNameKana: '',
            firstNameKana: '',
            grade: 0,
            organization: _teamName,
          ),
        );
        finalOwnTeamPlayers.add(found);
        ownPlayerNames.add(name);
      }
    }

    final matchCategory = widget.match.category ?? '';

    final teamSubstitutes = matchedTeam.playerNames
        .where((name) => name.isNotEmpty && !activePlayerNames.contains(name))
        .toList();

    final teamSubstitutesPlayers = finalOwnTeamPlayers
        .where((p) => teamSubstitutes.contains(p.name))
        .toList();
    final substitutes = teamSubstitutesPlayers;

    final sameCatActive = finalOwnTeamPlayers
        .where((p) => activePlayerNames.contains(p.name))
        .toList();

    final sameCategorySubstitutes = finalOwnTeamPlayers
        .where((p) => !activePlayerNames.contains(p.name))
        .where((p) {
          if (matchCategory.isEmpty) return true;
          return _getPlayerCategory(p.grade) == matchCategory;
        })
        .toList();

    final List<PlayerModel> quickAccessPlayers;
    if (teamSubstitutesPlayers.isNotEmpty) {
      quickAccessPlayers = teamSubstitutesPlayers;
    } else {
      quickAccessPlayers = sameCategorySubstitutes;
    }

    final dojoListSubstitutes = sameCategorySubstitutes
        .where((p) => !quickAccessPlayers.any((q) => q.name == p.name))
        .toList();

    final otherCategoryPlayers = players.where((p) {
      if (sameCatActive.any((a) => a.name == p.name)) return false;
      if (quickAccessPlayers.any((q) => q.name == p.name)) return false;
      if (dojoListSubstitutes.any((d) => d.name == p.name)) return false;
      return true;
    }).toList();

    Widget buildPlayerCard(PlayerModel p, {required bool isSub}) {
      final isCurrentPosition = p.name == _playerName;
      final currentPosition = playerPositions[p.name];

      Color cardColor;
      BorderSide borderSide;
      if (isSub) {
        cardColor = isDark
            ? const Color(0xFF009688).withValues(alpha: 0.2)
            : const Color(0xFF009688).withValues(alpha: 0.6);
        borderSide = BorderSide(color: const Color(0xFF009688));
      } else {
        cardColor = isDark
            ? const Color(0xFFFF9800).withValues(alpha: 0.15)
            : const Color(0xFFFF9800).withValues(alpha: 0.6);
        borderSide = BorderSide(color: const Color(0xFFFF9800));
      }

      return Card(
        margin: const EdgeInsets.only(bottom: AppSpacing.subValue),
        elevation: 0,
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.compact,
          side: borderSide,
        ),
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 0,
          ),
          leading: CircleAvatar(
            radius: 14,
            backgroundColor: isSub
                ? const Color(0xFF009688)
                : const Color(0xFFFF9800),
            child: Text(
              p.name.substring(0, 1),
              style: TextStyle(
                color: isSub
                    ? (isDark
                          ? const Color(0xFFFFFFFF)
                          : const Color(0xFF009688))
                    : (isDark
                          ? const Color(0xFFFFFFFF)
                          : const Color(0xFFFF9800)),
                fontWeight: AppFontWeight.bold,
                fontSize: AppFontSize.small,
              ),
            ),
          ),
          title: Text(
            p.name,
            style: TextStyle(
              fontWeight: AppFontWeight.bold,
              color: textColor,
              fontSize: AppFontSize.body,
            ),
          ),
          subtitle: Text(
            currentPosition != null
                ? (isCurrentPosition ? 'このポジション' : '$currentPositionで出場中')
                : '${p.gradeName} / ${p.gender}',
            style: TextStyle(
              color: isSub ? const Color(0xFF009688) : const Color(0xFFFF9800),
              fontSize: AppFontSize.caption,
              fontWeight: currentPosition != null
                  ? AppFontWeight.bold
                  : AppFontWeight.regular,
            ),
          ),
          trailing: Icon(
            isSub ? Icons.check_circle_outline : Icons.swap_horiz,
            size: 18,
            color: isSub ? const Color(0xFF009688) : const Color(0xFFFF9800),
          ),
          onTap: isCurrentPosition
              ? null
              : () async {
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
        ),
      );
    }

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
                  child: players.isEmpty
                      ? const Center(
                          child: Text(
                            '名簿に登録されている選手がいません',
                            style: TextStyle(color: AppKendoColors.grey),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                          children: [
                            if (sameCatActive.isNotEmpty) ...[
                              const Padding(
                                padding: EdgeInsets.only(bottom: AppSpacing.sm),
                                child: Text(
                                  '出場中の選手 (交代・スワップ)',
                                  style: TextStyle(
                                    fontSize: AppFontSize.small,
                                    fontWeight: AppFontWeight.bold,
                                    color: Color(0xFFFF9800),
                                  ),
                                ),
                              ),
                              ...sameCatActive.map(
                                (p) => buildPlayerCard(p, isSub: false),
                              ),
                              const SizedBox(height: AppSpacing.md),
                            ],
                            if (dojoListSubstitutes.isNotEmpty) ...[
                              const Padding(
                                padding: EdgeInsets.only(bottom: AppSpacing.sm),
                                child: Text(
                                  '同カテゴリの控え選手',
                                  style: TextStyle(
                                    fontSize: AppFontSize.small,
                                    fontWeight: AppFontWeight.bold,
                                    color: Color(0xFF009688),
                                  ),
                                ),
                              ),
                              ...dojoListSubstitutes.map(
                                (p) => buildPlayerCard(p, isSub: true),
                              ),
                              const SizedBox(height: AppSpacing.md),
                            ],
                            const Divider(),
                            const SizedBox(height: AppSpacing.sm),
                            Theme(
                              data: Theme.of(context).copyWith(
                                dividerColor: AppKendoColors.transparent,
                              ),
                              child: ExpansionTile(
                                title: Text(
                                  '他のカテゴリの選手を表示',
                                  style: TextStyle(
                                    fontSize: AppFontSize.bodySmall,
                                    fontWeight: AppFontWeight.bold,
                                    color: context.appColors.primaryAccent,
                                  ),
                                ),
                                tilePadding: EdgeInsets.zero,
                                childrenPadding: EdgeInsets.zero,
                                children: [
                                  if (otherCategoryPlayers.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: AppSpacing.lg,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '他のカテゴリに選手はいません',
                                          style: TextStyle(
                                            color: AppKendoColors.grey,
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    ...otherCategoryPlayers.map((p) {
                                      final isSub = !activePlayerNames.contains(
                                        p.name,
                                      );
                                      return buildPlayerCard(p, isSub: isSub);
                                    }),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ] else ...[
                const Spacer(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
