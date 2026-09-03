import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bunaiksen_setup/bunaiksen_team_setup_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bunaiksen_setup/bunaiksen_team_member_list.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/time/time_source.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';
import 'package:kendo_os/shared/widgets/glass_button.dart';
import 'package:kendo_os/shared/widgets/multi_player_select_input.dart';

/// 部内戦 団体戦タブ
class BunaiksenTeamTab extends StatefulWidget {
  final List<PlayerModel> masterPlayers;
  final bool isDark;
  final AppThemeColors themeColors;

  const BunaiksenTeamTab({
    super.key,
    required this.masterPlayers,
    required this.isDark,
    required this.themeColors,
  });

  @override
  State<BunaiksenTeamTab> createState() => _BunaiksenTeamTabState();
}

class _BunaiksenTeamTabState extends State<BunaiksenTeamTab> {
  int _teamSize = 5;
  final List<String> _poolPlayers = [];
  bool _isPoolFolded = false;
  final List<String?> _redTeam = List.filled(5, null, growable: true);
  final List<String?> _whiteTeam = List.filled(5, null, growable: true);

  void _autoAssignByGrade(List<PlayerModel> masterPlayers) {
    final result = BunaiksenTeamSetupHelper.autoAssignByGrade(
      poolPlayers: _poolPlayers,
      masterPlayers: masterPlayers,
      teamSize: _teamSize,
    );
    setState(() {
      for (int i = 0; i < _teamSize; i++) {
        _redTeam[i] = result.redTeam[i];
        _whiteTeam[i] = result.whiteTeam[i];
      }
    });
  }

  int _getUsageCount(String name) {
    return _redTeam.where((n) => n == name).length +
        _whiteTeam.where((n) => n == name).length;
  }

  Widget _buildPlayerChip(
    String name, {
    bool isFeedback = false,
    bool isAssigned = false,
    required bool isDark,
  }) {
    final count = _getUsageCount(name);
    return AppActionChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: TextStyle(
              color: isAssigned
                  ? (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))
                  : (context.appColors.textColor),
              fontWeight: AppFontWeight.bold,
            ),
          ),
          if (count > 0 && !isFeedback) ...[
            const SizedBox(width: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: const BoxDecoration(
                color: AppKendoColors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: AppKendoColors.pureWhite,
                  fontSize: AppFontSize.badge,
                  fontWeight: AppFontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      backgroundColor: isFeedback
          ? widget.themeColors.primaryAccent.withValues(alpha: 0.2)
          : (isAssigned
                ? (context.appColors.separatorColor)
                : (isDark
                      ? const Color(0xFFFFFFFF)
                      : context.appColors.textColor)),
      side: BorderSide(
        color: isAssigned
            ? AppKendoColors.transparent
            : widget.themeColors.primaryAccent.withValues(alpha: 0.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final masterPlayers = widget.masterPlayers;
    final positions = ['先鋒', '次鋒', '五将', '中堅', '三将', '副将', '大将'];
    List<String> getPositions(int size) {
      if (size == 3) return ['先鋒', '中堅', '大将'];
      if (size == 5) return ['先鋒', '次鋒', '中堅', '副将', '大将'];
      if (size == 7) return positions;
      return List.generate(size, (i) => '${i + 1}番手');
    }

    final currentPositions = getPositions(_teamSize);

    return Consumer(
      builder: (context, ref, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0.0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '参加者プール (${_poolPlayers.length}名)',
                      style: const TextStyle(
                        fontWeight: AppFontWeight.bold,
                        fontSize: AppFontSize.bodySmall,
                        color: AppKendoColors.grey,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isPoolFolded ? Icons.expand_more : Icons.expand_less,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _isPoolFolded = !_isPoolFolded),
                    ),
                  ],
                ),
              ),
              if (!_isPoolFolded) ...[
                MultiPlayerSelectInput(
                  initialSelected: _poolPlayers,
                  label: '団体戦メンバーを選択（複数可）',
                  onConfirm: (selectedList) {
                    setState(() {
                      _poolPlayers.clear();
                      _poolPlayers.addAll(selectedList);
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _poolPlayers.length,
                  itemBuilder: (context, index) {
                    final name = _poolPlayers[index];
                    final isAssigned =
                        _redTeam.contains(name) || _whiteTeam.contains(name);

                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: Draggable<String>(
                        data: name,
                        affinity: Axis.vertical,
                        feedback: Material(
                          color: AppKendoColors.transparent,
                          child: _buildPlayerChip(
                            name,
                            isFeedback: true,
                            isDark: isDark,
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.3,
                          child: _buildPlayerChip(name, isDark: isDark),
                        ),
                        child: _buildPlayerChip(
                          name,
                          isAssigned: isAssigned,
                          isDark: isDark,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () {
                          if (_teamSize > 1) {
                            setState(() {
                              _teamSize--;
                              _redTeam.removeLast();
                              _whiteTeam.removeLast();
                            });
                          }
                        },
                      ),
                      Text(
                        '$_teamSize 対 $_teamSize',
                        style: const TextStyle(
                          fontWeight: AppFontWeight.bold,
                          fontSize: AppFontSize.subhead,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () {
                          setState(() {
                            _teamSize++;
                            _redTeam.add(null);
                            _whiteTeam.add(null);
                          });
                        },
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('学年順 自動振り分け'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppKendoColors.ipponGold,
                      foregroundColor: AppKendoColors.pureBlack,
                    ),
                    onPressed: () => _autoAssignByGrade(masterPlayers),
                  ),
                ],
              ),
              const Divider(height: 16),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: BunaiksenTeamMemberList(
                        teamSize: _teamSize,
                        teamMembers: _redTeam,
                        positions: currentPositions,
                        teamColor: AppKendoColors.hansokuRed,
                        isDark: isDark,
                        onMemberAssigned: (index, player) =>
                            setState(() => _redTeam[index] = player),
                        onMemberCleared: (index) =>
                            setState(() => _redTeam[index] = null),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: BunaiksenTeamMemberList(
                        teamSize: _teamSize,
                        teamMembers: _whiteTeam,
                        positions: currentPositions,
                        teamColor: const Color(0xFF607D8B),
                        isDark: isDark,
                        onMemberAssigned: (index, player) =>
                            setState(() => _whiteTeam[index] = player),
                        onMemberCleared: (index) =>
                            setState(() => _whiteTeam[index] = null),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: GlassButton(
                  icon: Icons.check_circle,
                  label: '確定して対戦表を作成',
                  color: widget.themeColors.primaryAccent,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  expandContent: false,
                  onPressed: () async {
                    final rule = ref.read(bunaiksenRuleProvider);
                    final now = ref.read(timeSourceProvider).now();
                    final matchesToSave =
                        BunaiksenTeamSetupHelper.generateTeamMatches(
                          teamSize: _teamSize,
                          currentPositions: currentPositions,
                          redTeam: _redTeam,
                          whiteTeam: _whiteTeam,
                          rule: rule,
                          now: now,
                        );

                    await ref
                        .read(matchApplicationServiceProvider)
                        .saveMatchesBulk(matchesToSave);
                    if (context.mounted) context.pop();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
