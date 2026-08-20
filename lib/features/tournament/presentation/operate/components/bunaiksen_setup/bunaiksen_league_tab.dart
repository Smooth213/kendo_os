import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart';
import 'package:kendo_os/shared/time/time_source.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/glass_button.dart';
import 'package:kendo_os/shared/widgets/multi_player_select_input.dart';
import 'package:uuid/uuid.dart';

/// 🥋 特設部内戦 試合作成「総当たりリーグ戦」タブ
class BunaiksenLeagueTab extends StatefulWidget {
  final AppThemeColors themeColors;

  const BunaiksenLeagueTab({super.key, required this.themeColors});

  @override
  State<BunaiksenLeagueTab> createState() => _BunaiksenLeagueTabState();
}

class _BunaiksenLeagueTabState extends State<BunaiksenLeagueTab> {
  final List<String> _leagueParticipants = [];

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            children: [
              MultiPlayerSelectInput(
                initialSelected: _leagueParticipants,
                label: 'リーグ戦メンバーを選択（複数可）',
                onConfirm: (selectedList) {
                  setState(() {
                    _leagueParticipants.clear();
                    _leagueParticipants.addAll(selectedList);
                  });
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: context.appColors.inputBackground,
                    borderRadius: AppRadius.medium,
                    border: Border.all(color: context.appColors.separatorColor),
                  ),
                  child: Material(
                    color: AppKendoColors.transparent,
                    child: _leagueParticipants.isEmpty
                        ? Center(
                            child: Text(
                              '選手を追加してください',
                              style: TextStyle(
                                color: context.appColors.subTextColor,
                              ),
                            ),
                          )
                        : ReorderableListView.builder(
                            itemCount: _leagueParticipants.length,
                            onReorderItem: (oldIndex, newIndex) {
                              setState(() {
                                final item = _leagueParticipants.removeAt(
                                  oldIndex,
                                );
                                _leagueParticipants.insert(newIndex, item);
                              });
                            },
                            itemBuilder: (context, index) {
                              final p = _leagueParticipants[index];
                              return ListTile(
                                key: ValueKey(p),
                                leading: CircleAvatar(
                                  backgroundColor: widget
                                      .themeColors
                                      .primaryAccent
                                      .withValues(alpha: 0.2),
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: widget.themeColors.primaryAccent,
                                      fontSize: AppFontSize.small,
                                      fontWeight: AppFontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(p),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: AppKendoColors.grey,
                                  ),
                                  onPressed: () => setState(
                                    () => _leagueParticipants.remove(p),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: GlassButton(
                  icon: Icons.grid_on,
                  label: '総当たり対戦表を作成（${_leagueParticipants.length}人）',
                  color: widget.themeColors.primaryAccent,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  expandContent: false,
                  onPressed: _leagueParticipants.length < 2
                      ? null
                      : () async {
                          final rule = ref.read(bunaiksenRuleProvider);
                          final now = ref.read(timeSourceProvider).now();
                          final dateStr = DateFormat(
                            'yyyyMMdd',
                          ).format(DateTime.now());
                          final todayId = 'bunaiksen_$dateStr';
                          final groupId = const Uuid().v4();
                          final baseOrder = now.millisecondsSinceEpoch
                              .toDouble();

                          List<MatchModel> matchesToSave = [];
                          int matchCount = 0;
                          for (int i = 0; i < _leagueParticipants.length; i++) {
                            for (
                              int j = i + 1;
                              j < _leagueParticipants.length;
                              j++
                            ) {
                              final matchId = const Uuid().v4();
                              matchesToSave.add(
                                MatchModel(
                                  id: matchId,
                                  tournamentId: todayId,
                                  groupName: groupId,
                                  matchType: 'リーグ戦',
                                  redName: _leagueParticipants[i],
                                  whiteName: _leagueParticipants[j],
                                  matchTimeMinutes: rule.matchTimeMinutes,
                                  hasExtension:
                                      rule.enchoTimeMinutes > 0 ||
                                      rule.isEnchoUnlimited,
                                  extensionTimeMinutes: rule.enchoTimeMinutes,
                                  status: 'waiting',
                                  order: baseOrder + matchCount,
                                  rule: rule.copyWith(
                                    isLeague: true,
                                    winPoint: 3,
                                    drawPoint: 1,
                                    lossPoint: 0,
                                  ),
                                  note: '[リーグ戦] 部内戦',
                                ),
                              );
                              matchCount++;
                            }
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
