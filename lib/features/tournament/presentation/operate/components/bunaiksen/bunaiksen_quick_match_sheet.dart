import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bunaiksen/bunaiksen_quick_match_player_select_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bunaiksen/bunaiksen_quick_match_rule_section.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:uuid/uuid.dart';

/// 🥋 部内戦・フリー対戦のクイックマッチ作成ボトムシート
class BunaiksenQuickMatchSheet extends ConsumerStatefulWidget {
  final String dateId;

  const BunaiksenQuickMatchSheet({super.key, required this.dateId});

  static Future<void> show(BuildContext context, WidgetRef ref, String dateId) {
    return showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => BunaiksenQuickMatchSheet(dateId: dateId),
    );
  }

  @override
  ConsumerState<BunaiksenQuickMatchSheet> createState() =>
      _BunaiksenQuickMatchSheetState();
}

class _BunaiksenQuickMatchSheetState
    extends ConsumerState<BunaiksenQuickMatchSheet> {
  String redPlayer = '選手A';
  String whitePlayer = '選手B';
  String selectedCourt = '部内戦コート';
  String selectedGroupName = '部内対戦';
  double selectedMatchTime = 2.0;
  late bool selectedIsIpponShobu;

  @override
  void initState() {
    super.initState();
    final initialRule = ref.read(bunaiksenRuleProvider);
    selectedIsIpponShobu = initialRule.isIpponShobu;
  }

  Future<void> _startMatch(AppThemeColors themeColors) async {
    Navigator.pop(context);
    final dojoId = ref.read(currentDojoIdProvider);
    final baseRule = ref.read(bunaiksenRuleProvider);
    final matchId = const Uuid().v4();

    final matchRule = baseRule.copyWith(
      matchTimeMinutes: selectedMatchTime,
      isIpponShobu: selectedIsIpponShobu,
      ipponLimit: selectedIsIpponShobu ? 1 : 2,
    );

    final newMatch = MatchModel(
      id: matchId,
      tournamentId: widget.dateId,
      groupName: selectedGroupName,
      matchType: '個人戦',
      redName: redPlayer,
      whiteName: whitePlayer,
      matchTimeMinutes: selectedMatchTime,
      hasExtension: baseRule.enchoTimeMinutes > 0 || baseRule.isEnchoUnlimited,
      extensionTimeMinutes: baseRule.enchoTimeMinutes,
      status: 'in_progress',
      order: DateTime.now().millisecondsSinceEpoch.toDouble(),
      rule: matchRule,
      note: '$selectedCourt\n$selectedGroupName',
    );

    await ref.read(matchApplicationServiceProvider).saveMatch(newMatch);

    if (mounted) {
      context.push(
        '/match/${newMatch.id}?tournamentId=${widget.dateId}&dojoId=$dojoId',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'bunaiksen');

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: AppSpacing.lg,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0x8A000000),
              borderRadius: AppRadius.micro,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'クイック対戦',
            style: TextStyle(
              fontSize: AppFontSize.headline,
              fontWeight: AppFontWeight.bold,
              color: themeColors.textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '赤・白の選手を選択して「試合スタート」を押すとすぐに計測が始まります',
            style: TextStyle(
              fontSize: AppFontSize.small,
              color: isDark ? const Color(0xFFFFFFFF) : const Color(0x8A000000),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          BunaiksenQuickMatchPlayerSelectSection(
            redPlayer: redPlayer,
            whitePlayer: whitePlayer,
            onRedPlayerSelected: (p) => setState(() => redPlayer = p),
            onWhitePlayerSelected: (p) => setState(() => whitePlayer = p),
            ref: ref,
          ),
          const SizedBox(height: 20),
          BunaiksenQuickMatchRuleSection(
            selectedMatchTime: selectedMatchTime,
            selectedIsIpponShobu: selectedIsIpponShobu,
            onMatchTimeChanged: (t) => setState(() => selectedMatchTime = t),
            onIsIpponShobuChanged: (s) =>
                setState(() => selectedIsIpponShobu = s),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _startMatch(themeColors),
              icon: const Icon(Icons.play_arrow, size: 20),
              label: const Text(
                '試合スタート',
                style: TextStyle(
                  fontSize: AppFontSize.subhead,
                  fontWeight: AppFontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColors.primaryAccent,
                foregroundColor: AppKendoColors.pureWhite,
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.modernValue,
                ),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.large),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
