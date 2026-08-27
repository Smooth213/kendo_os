import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/time/time_source.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';
import 'package:kendo_os/shared/widgets/glass_button.dart';
import 'package:kendo_os/shared/widgets/multi_player_select_input.dart';
import 'package:uuid/uuid.dart';

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
    List<String> sorted = List.from(_poolPlayers);
    sorted.sort((a, b) {
      final ga =
          masterPlayers.where((p) => p.name == a).firstOrNull?.grade ?? 99;
      final gb =
          masterPlayers.where((p) => p.name == b).firstOrNull?.grade ?? 99;
      return ga.compareTo(gb);
    });

    setState(() {
      for (int i = 0; i < _teamSize; i++) {
        _redTeam[i] = null;
        _whiteTeam[i] = null;
      }
      for (int i = 0; i < sorted.length; i++) {
        int pos = i ~/ 2;
        if (pos >= _teamSize) break;
        if (i % 4 == 0 || i % 4 == 3) {
          if (_redTeam[pos] == null) {
            _redTeam[pos] = sorted[i];
          } else if (_whiteTeam[pos] == null) {
            _whiteTeam[pos] = sorted[i];
          }
        } else {
          if (_whiteTeam[pos] == null) {
            _whiteTeam[pos] = sorted[i];
          } else if (_redTeam[pos] == null) {
            _redTeam[pos] = sorted[i];
          }
        }
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
                      child: ListView.builder(
                        itemCount: _teamSize,
                        itemBuilder: (context, index) {
                          return DragTarget<String>(
                            onAcceptWithDetails: (details) =>
                                setState(() => _redTeam[index] = details.data),
                            builder: (context, candidateData, rejectedData) {
                              return Card(
                                color: candidateData.isNotEmpty
                                    ? AppKendoColors.hansokuRed.withValues(
                                        alpha: 0.2,
                                      )
                                    : (isDark
                                          ? const Color(0xFF2C1C1E)
                                          : const Color(0xFFFFF5F5)),
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                    color: AppKendoColors.hansokuRed,
                                    width: candidateData.isNotEmpty ? 2 : 1,
                                  ),
                                  borderRadius: AppRadius.large,
                                ),
                                child: ListTile(
                                  dense: true,
                                  leading: CircleAvatar(
                                    backgroundColor: AppKendoColors.hansokuRed,
                                    radius: 14,
                                    child: Text(
                                      currentPositions[index].substring(0, 1),
                                      style: const TextStyle(
                                        color: AppKendoColors.pureWhite,
                                        fontSize: AppFontSize.badge,
                                        fontWeight: AppFontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    _redTeam[index] ?? '未定',
                                    style: TextStyle(
                                      fontWeight: AppFontWeight.bold,
                                      color: _redTeam[index] == null
                                          ? (isDark
                                                ? const Color(0xFF94A3B8)
                                                : const Color(0xFF64748B))
                                          : (context.appColors.textColor),
                                    ),
                                  ),
                                  onTap: () =>
                                      setState(() => _redTeam[index] = null),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _teamSize,
                        itemBuilder: (context, index) {
                          return DragTarget<String>(
                            onAcceptWithDetails: (details) => setState(
                              () => _whiteTeam[index] = details.data,
                            ),
                            builder: (context, candidateData, rejectedData) {
                              return Card(
                                color: candidateData.isNotEmpty
                                    ? const Color(
                                        0xFF607D8B,
                                      ).withValues(alpha: 0.2)
                                    : (isDark
                                          ? const Color(0xFF1E293B)
                                          : const Color(0xFFF8FAFC)),
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                    color: const Color(0xFF607D8B),
                                    width: candidateData.isNotEmpty ? 2 : 1,
                                  ),
                                  borderRadius: AppRadius.large,
                                ),
                                child: ListTile(
                                  dense: true,
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFF607D8B),
                                    radius: 14,
                                    child: Text(
                                      currentPositions[index].substring(0, 1),
                                      style: const TextStyle(
                                        color: AppKendoColors.pureWhite,
                                        fontSize: AppFontSize.badge,
                                        fontWeight: AppFontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    _whiteTeam[index] ?? '未定',
                                    style: TextStyle(
                                      fontWeight: AppFontWeight.bold,
                                      color: _whiteTeam[index] == null
                                          ? (isDark
                                                ? const Color(0xFF94A3B8)
                                                : const Color(0xFF64748B))
                                          : (context.appColors.textColor),
                                    ),
                                  ),
                                  onTap: () =>
                                      setState(() => _whiteTeam[index] = null),
                                ),
                              );
                            },
                          );
                        },
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
                    final dateStr = DateFormat(
                      'yyyyMMdd',
                    ).format(DateTime.now());
                    final todayId = 'bunaiksen_$dateStr';
                    final groupId = const Uuid().v4();
                    final baseOrder = now.millisecondsSinceEpoch.toDouble();

                    List<MatchModel> matchesToSave = [];
                    for (int i = 0; i < _teamSize; i++) {
                      final matchId = const Uuid().v4();
                      matchesToSave.add(
                        MatchModel(
                          id: matchId,
                          tournamentId: todayId,
                          groupName: groupId,
                          matchType: currentPositions[i],
                          redName: _redTeam[i] ?? '未定',
                          whiteName: _whiteTeam[i] ?? '未定',
                          matchTimeMinutes: rule.matchTimeMinutes,
                          hasExtension: false,
                          extensionTimeMinutes: 0.0,
                          status: 'waiting',
                          order: baseOrder + i,
                          rule: rule.copyWith(
                            isEnchoUnlimited: false,
                            enchoTimeMinutes: 0.0,
                            enchoCount: 0,
                            hasHantei: false,
                          ),
                          note: '部内・団体戦',
                        ),
                      );
                    }

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
