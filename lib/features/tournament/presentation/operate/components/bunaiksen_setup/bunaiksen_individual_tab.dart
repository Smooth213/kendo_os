import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_command_provider.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/time/time_source.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/widgets/glass_button.dart';
import 'package:kendo_os/shared/widgets/smart_player_input.dart';
import 'package:uuid/uuid.dart';

/// 部内戦 個人戦（即スタート）タブ
class BunaiksenIndividualTab extends ConsumerWidget {
  final TextEditingController redPlayerController;
  final TextEditingController whitePlayerController;
  final AppThemeColors themeColors;

  const BunaiksenIndividualTab({
    super.key,
    required this.redPlayerController,
    required this.whitePlayerController,
    required this.themeColors,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: SmartPlayerInput(
                  controller: redPlayerController,
                  label: '赤の選手',
                  accentColor: themeColors.primaryAccent,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  'VS',
                  style: TextStyle(
                    fontSize: AppFontSize.display,
                    fontWeight: AppFontWeight.bold,
                    color: Color(0x8A000000),
                  ),
                ),
              ),
              Expanded(
                child: SmartPlayerInput(
                  controller: whitePlayerController,
                  label: '白選手',
                  accentColor: isDark
                      ? context.appColors.separatorColor
                      : context.appColors.textColor,
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: GlassButton(
              icon: Icons.flash_on,
              label: '試合開始',
              color: themeColors.primaryAccent,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              expandContent: false,
              onPressed: () async {
                final redName = redPlayerController.text.trim();
                final whiteName = whitePlayerController.text.trim();

                if (redName.isEmpty || whiteName.isEmpty) {
                  AppSnackBar.showError(context, '両選手の名前を入力してください');
                  return;
                }

                final rule = ref.read(bunaiksenRuleProvider);
                final matchId = const Uuid().v4();
                final now = ref.read(timeSourceProvider).now();
                final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
                final todayId = 'bunaiksen_$dateStr';

                final newMatch = MatchModel(
                  id: matchId,
                  tournamentId: todayId,
                  groupName: const Uuid().v4(),
                  matchType: '個人戦',
                  redName: redName,
                  whiteName: whiteName,
                  matchTimeMinutes: rule.matchTimeMinutes,
                  hasExtension:
                      rule.enchoTimeMinutes > 0 || rule.isEnchoUnlimited,
                  extensionTimeMinutes: rule.enchoTimeMinutes,
                  status: 'in_progress',
                  order: now.millisecondsSinceEpoch.toDouble(),
                  rule: rule,
                  note: '部内戦',
                );

                await ref.read(matchCommandProvider).addMatch(newMatch);
                if (context.mounted) context.push('/match/$matchId');
              },
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
