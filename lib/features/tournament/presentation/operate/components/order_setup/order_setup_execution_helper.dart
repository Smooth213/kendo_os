import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/presentation/providers/match_rule_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/order_setup/order_setup_match_generator.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/time/time_source.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';

/// オーダー編成確定・試合生成実行ヘルパー
class OrderSetupExecutionHelper {
  /// オーダー編成確定ダイアログを表示し、試合生成と保存を実行
  static Future<void> executeOrderSetup({
    required BuildContext context,
    required WidgetRef ref,
    required String tournamentId,
    required MatchRule rule,
    required List<String> positions,
    required Map<int, String> selectedPlayers,
    required Map<int, String> opponentPlayers,
    required String opponentTeamInput,
    required bool isOwnTeamRed,
    required List<String> leagueParticipants,
    required Map<String, List<String>> leagueTeamOrders,
    required String matchType,
    required AppThemeColors themeColors,
  }) async {
    final bool? isStartNow = await showAppDialog<bool>(
      context: context,
      builder: (dialogCtx) => AppDialog(
        title: '試合の登録',
        content: const Text('このオーダーで試合を登録します。今すぐ試合画面に進みますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text(
              '後で（リストに保存）',
              style: TextStyle(color: AppKendoColors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColors.primaryAccent,
              foregroundColor: AppKendoColors.pureWhite,
              elevation: 0,
            ),
            child: const Text(
              '今すぐ試合開始',
              style: TextStyle(fontWeight: AppFontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (isStartNow == null || !context.mounted) {
      return;
    }

    showAppDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      if (rule.isLeague) {
        if (leagueParticipants.length < 2) {
          AppSnackBar.showError(context, 'リーグ戦には少なくとも2つのチーム・選手が必要です');
          if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
          return;
        }
        ref
            .read(matchRuleProvider.notifier)
            .updateRule(rule.copyWith(leagueOrder: leagueParticipants));
      }

      final double baseOrder = ref
          .read(timeSourceProvider)
          .now()
          .millisecondsSinceEpoch
          .toDouble();

      final matchesToSave = OrderSetupMatchGenerator.generateMatches(
        tournamentId: tournamentId,
        rule: rule,
        positions: positions,
        selectedPlayers: selectedPlayers,
        opponentPlayers: opponentPlayers,
        opponentTeamInput: opponentTeamInput,
        isOwnTeamRed: isOwnTeamRed,
        leagueParticipants: leagueParticipants,
        leagueTeamOrders: leagueTeamOrders,
        matchType: matchType,
        isStartNow: isStartNow,
        baseOrder: baseOrder,
      );

      if (matchesToSave.isNotEmpty) {
        await ref
            .read(matchApplicationServiceProvider)
            .saveMatchesBulk(matchesToSave);
      }

      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      final String senpoMatchId = matchesToSave.isNotEmpty
          ? matchesToSave.first.id
          : '';

      if (isStartNow) {
        if (senpoMatchId.isNotEmpty) {
          context.push('/match/$senpoMatchId');
        } else {
          context.go('/home/$tournamentId');
        }
      } else {
        AppSnackBar.showSuccess(context, '試合をプールしました（待機リストに追加）');
        context.go('/home/$tournamentId');
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      AppSnackBar.showError(context, '保存に失敗しました: $e');
    }
  }
}
