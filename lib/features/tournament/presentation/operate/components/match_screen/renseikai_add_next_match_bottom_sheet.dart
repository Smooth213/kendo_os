import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/presentation/providers/match_rule_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/renseikai_player_candidate_resolver.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/renseikai_player_input_field.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/last_used_settings_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/team_repository.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';
import 'package:uuid/uuid.dart';
import '../../match_screen.dart' show playerListProvider;

/// 錬成会用 次の試合追加ボトムシート
class RenseikaiAddNextMatchBottomSheet extends ConsumerStatefulWidget {
  final MatchModel currentMatch;

  const RenseikaiAddNextMatchBottomSheet({
    super.key,
    required this.currentMatch,
  });

  static Future<void> show(
    BuildContext context, {
    required MatchModel currentMatch,
  }) {
    return showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppKendoColors.transparent,
      builder: (ctx) =>
          RenseikaiAddNextMatchBottomSheet(currentMatch: currentMatch),
    );
  }

  @override
  ConsumerState<RenseikaiAddNextMatchBottomSheet> createState() =>
      _RenseikaiAddNextMatchBottomSheetState();
}

class _RenseikaiAddNextMatchBottomSheetState
    extends ConsumerState<RenseikaiAddNextMatchBottomSheet> {
  late final TextEditingController _redCtrl;
  late final TextEditingController _whiteCtrl;

  @override
  void initState() {
    super.initState();
    _redCtrl = TextEditingController();
    _whiteCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _redCtrl.dispose();
    _whiteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = context.appColors.cardBackground;
    final textColor = context.appColors.textColor;
    final inputBgColor = isDark
        ? const Color(0xFF2C2C2E)
        : context.appColors.cardBackground;
    final borderColor = isDark
        ? const Color(0xFF38383A)
        : context.appColors.separatorColor;

    final String rTeam = widget.currentMatch.redName.contains(':')
        ? widget.currentMatch.redName.split(':').first.trim()
        : '赤';
    final String wTeam = widget.currentMatch.whiteName.contains(':')
        ? widget.currentMatch.whiteName.split(':').first.trim()
        : '白';

    final allMatches = ref.watch(matchListProvider);
    final teamMatches = allMatches
        .where((m) => m.groupName == widget.currentMatch.groupName)
        .toList();

    final baseRedPlayers = RenseikaiPlayerCandidateResolver.extractBasePlayers(
      teamMatches,
      rTeam,
    );
    final baseWhitePlayers =
        RenseikaiPlayerCandidateResolver.extractBasePlayers(teamMatches, wTeam);

    List<PlayerModel> localPlayers = [];
    try {
      localPlayers = ref.watch(playerListProvider).value ?? [];
    } catch (_) {}

    List<TeamModel> registeredTeams = [];
    try {
      registeredTeams =
          ref
              .watch(
                registeredTeamsProvider(widget.currentMatch.tournamentId ?? ''),
              )
              .value ??
          [];
    } catch (_) {}

    final matchCat = widget.currentMatch.category?.trim() ?? '';

    final redPlayers = RenseikaiPlayerCandidateResolver.resolveTeamPlayers(
      teamName: rTeam,
      matchCat: matchCat,
      registeredTeams: registeredTeams,
      localPlayers: localPlayers,
      basePlayers: baseRedPlayers,
    );

    final whitePlayers = RenseikaiPlayerCandidateResolver.resolveTeamPlayers(
      teamName: wTeam,
      matchCat: matchCat,
      registeredTeams: registeredTeams,
      localPlayers: localPlayers,
      basePlayers: baseWhitePlayers,
    );

    final Set<String> redMasterSet = redPlayers.toSet();
    final Set<String> whiteMasterSet = whitePlayers.toSet();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xlargeValue),
          ),
        ),
        padding: const EdgeInsets.only(
          top: AppSpacing.lg,
          left: AppSpacing.xl,
          right: AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              '次の試合を追加 (錬成会)',
              style: TextStyle(
                fontSize: AppFontSize.header,
                fontWeight: AppFontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '次の試合に出場する選手を入力または選択してください。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppFontSize.bodySmall,
                color: context.appColors.subTextColor,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                children: [
                  const SizedBox(height: AppSpacing.md),
                  RenseikaiPlayerInputField(
                    teamName: rTeam,
                    players: redPlayers,
                    masterSet: redMasterSet,
                    controller: _redCtrl,
                    isDark: isDark,
                    textColor: textColor,
                    inputBgColor: inputBgColor,
                    borderColor: borderColor,
                    onPlayerSelected: (p) => setState(() => _redCtrl.text = p),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  RenseikaiPlayerInputField(
                    teamName: wTeam,
                    players: whitePlayers,
                    masterSet: whiteMasterSet,
                    controller: _whiteCtrl,
                    isDark: isDark,
                    textColor: textColor,
                    inputBgColor: inputBgColor,
                    borderColor: borderColor,
                    onPlayerSelected: (p) =>
                        setState(() => _whiteCtrl.text = p),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.lg,
                  bottom: AppSpacing.xl,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppKendoColors.grey,
                          side: const BorderSide(color: AppKendoColors.grey),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.medium,
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'キャンセル',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: AppFontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF009688),
                          foregroundColor: const Color(0xFFFFFFFF),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.medium,
                          ),
                          elevation: 2,
                        ),
                        onPressed: () async {
                          showAppDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );

                          final nextMatchId = const Uuid().v4();
                          final newRed =
                              '$rTeam : ${_redCtrl.text.trim().isEmpty ? '選手' : _redCtrl.text.trim()}';
                          final newWhite =
                              '$wTeam : ${_whiteCtrl.text.trim().isEmpty ? '選手' : _whiteCtrl.text.trim()}';

                          final rule = ref.read(matchRuleProvider);
                          final lastSettings = ref.read(
                            lastUsedSettingsProvider,
                          );
                          final double exactMatchTime =
                              (lastSettings['matchTime'] as num?)?.toDouble() ??
                              rule.matchTimeMinutes.toDouble();

                          final nextMatch = MatchModel(
                            id: nextMatchId,
                            tournamentId: widget.currentMatch.tournamentId,
                            category: widget.currentMatch.category,
                            groupName: widget.currentMatch.groupName,
                            matchType: '錬成会',
                            rule: widget.currentMatch.rule ?? rule,
                            redName: newRed,
                            whiteName: newWhite,
                            status: 'waiting',
                            matchTimeMinutes: exactMatchTime,
                            isRunningTime: rule.isRunningTime,
                            order: widget.currentMatch.order + 0.1,
                            note: widget.currentMatch.note,
                          );

                          await ref
                              .read(matchApplicationServiceProvider)
                              .saveMatch(nextMatch);

                          if (!context.mounted) return;
                          Navigator.of(context, rootNavigator: true).pop();
                          if (!context.mounted) return;
                          Navigator.pop(context);

                          if (!context.mounted) return;
                          context.pushReplacement('/match/$nextMatchId');
                        },
                        child: const Text(
                          '決定して開始',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: AppFontSize.bodyMedium,
                            fontWeight: AppFontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
