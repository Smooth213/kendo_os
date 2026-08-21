import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bunaiksen/bunaiksen_single_player_select_sheet.dart';
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
          Row(
            children: [
              // 赤選手
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppKendoColors.red.withValues(
                      alpha: isDark ? 0.15 : 0.08,
                    ),
                    borderRadius: AppRadius.large,
                    border: Border.all(
                      color: const Color(0xFFE53935).withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '赤',
                        style: TextStyle(
                          fontSize: AppFontSize.body,
                          fontWeight: AppFontWeight.bold,
                          color: AppKendoColors.hansokuRed,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      InkWell(
                        onTap: () async {
                          final picked =
                              await BunaiksenSinglePlayerSelectSheet.show(
                                context,
                                ref,
                                sideName: '赤',
                                accentColor: AppKendoColors.hansokuRed,
                              );
                          if (picked != null) {
                            setState(() => redPlayer = picked);
                          }
                        },
                        borderRadius: AppRadius.small,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2C2C2E)
                                : const Color(0xFFFFFFFF),
                            borderRadius: AppRadius.small,
                            border: Border.all(
                              color: AppKendoColors.hansokuRed.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  redPlayer,
                                  style: TextStyle(
                                    fontSize: AppFontSize.subhead,
                                    fontWeight: AppFontWeight.bold,
                                    color: themeColors.textColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(
                                Icons.arrow_drop_down,
                                color: AppKendoColors.hansokuRed,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Text(
                  'VS',
                  style: TextStyle(
                    fontWeight: AppFontWeight.black,
                    fontSize: AppFontSize.subhead,
                    color: AppKendoColors.grey,
                  ),
                ),
              ),
              // 白選手
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppKendoColors.blueGrey.withValues(
                      alpha: isDark ? 0.15 : 0.08,
                    ),
                    borderRadius: AppRadius.large,
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF607D8B)
                          : const Color(0xFF607D8B),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '白',
                        style: TextStyle(
                          fontSize: AppFontSize.body,
                          fontWeight: AppFontWeight.bold,
                          color: isDark
                              ? const Color(0xFFFFFFFF).withValues(alpha: 0.7)
                              : const Color(0xFF607D8B),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      InkWell(
                        onTap: () async {
                          final picked =
                              await BunaiksenSinglePlayerSelectSheet.show(
                                context,
                                ref,
                                sideName: '白',
                                accentColor: isDark
                                    ? context.appColors.subTextColor
                                    : context.appColors.subTextColor,
                              );
                          if (picked != null) {
                            setState(() => whitePlayer = picked);
                          }
                        },
                        borderRadius: AppRadius.small,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2C2C2E)
                                : const Color(0xFFFFFFFF),
                            borderRadius: AppRadius.small,
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF607D8B)
                                  : const Color(
                                      0xFF607D8B,
                                    ).withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  whitePlayer,
                                  style: TextStyle(
                                    fontSize: AppFontSize.subhead,
                                    fontWeight: AppFontWeight.bold,
                                    color: themeColors.textColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(
                                Icons.arrow_drop_down,
                                color: isDark
                                    ? const Color(
                                        0xFFFFFFFF,
                                      ).withValues(alpha: 0.7)
                                    : const Color(0xFF607D8B),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 試合時間＆勝負設定
          Container(
            padding: const EdgeInsets.all(AppSpacing.modernValue),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
              borderRadius: AppRadius.large,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 試合時間 (＋／－ カプセルステッパー)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 16,
                          color: isDark
                              ? const Color(0xFFFFFFFF)
                              : const Color(0xDE000000),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '試合時間',
                          style: TextStyle(
                            fontSize: AppFontSize.bodySmall,
                            fontWeight: AppFontWeight.bold,
                            color: themeColors.textColor,
                          ),
                        ),
                      ],
                    ),
                    // ＋／－ カプセルコントローラー
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF3A3A3C)
                            : const Color(0xFFFFFFFF),
                        borderRadius: AppRadius.round,
                        border: Border.all(
                          color: themeColors.primaryAccent.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 18),
                            padding: const EdgeInsets.all(AppSpacing.xs),
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 32,
                            ),
                            color: selectedMatchTime > 0.5
                                ? themeColors.primaryAccent
                                : AppKendoColors.grey,
                            onPressed: selectedMatchTime > 0.5
                                ? () => setState(
                                    () => selectedMatchTime =
                                        (selectedMatchTime - 0.5).clamp(
                                          0.5,
                                          10.0,
                                        ),
                                  )
                                : null,
                          ),
                          Container(
                            constraints: const BoxConstraints(minWidth: 54),
                            alignment: Alignment.center,
                            child: Text(
                              selectedMatchTime % 1 == 0
                                  ? '${selectedMatchTime.toInt()}分'
                                  : '$selectedMatchTime分',
                              style: TextStyle(
                                fontWeight: AppFontWeight.bold,
                                fontSize: AppFontSize.body,
                                color: themeColors.textColor,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 18),
                            padding: const EdgeInsets.all(AppSpacing.xs),
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 32,
                            ),
                            color: selectedMatchTime < 10.0
                                ? themeColors.primaryAccent
                                : AppKendoColors.grey,
                            onPressed: selectedMatchTime < 10.0
                                ? () => setState(
                                    () => selectedMatchTime =
                                        (selectedMatchTime + 0.5).clamp(
                                          0.5,
                                          10.0,
                                        ),
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // 勝負形式 (3本勝負 / 1本勝負)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.emoji_events_outlined,
                          size: 16,
                          color: isDark
                              ? const Color(0xFFFFFFFF)
                              : const Color(0xDE000000),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '勝負形式',
                          style: TextStyle(
                            fontSize: AppFontSize.bodySmall,
                            fontWeight: AppFontWeight.bold,
                            color: themeColors.textColor,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // 3本勝負
                        InkWell(
                          onTap: () =>
                              setState(() => selectedIsIpponShobu = false),
                          borderRadius: AppRadius.large,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.modernValue,
                              vertical: AppSpacing.subValue,
                            ),
                            decoration: BoxDecoration(
                              color: !selectedIsIpponShobu
                                  ? themeColors.primaryAccent
                                  : (isDark
                                        ? const Color(0xFF3A3A3C)
                                        : const Color(0xFFFFFFFF)),
                              borderRadius: AppRadius.large,
                              border: Border.all(
                                color: !selectedIsIpponShobu
                                    ? themeColors.primaryAccent
                                    : const Color(0x33000000),
                              ),
                            ),
                            child: Text(
                              '3本勝負',
                              style: TextStyle(
                                fontSize: AppFontSize.small,
                                fontWeight: !selectedIsIpponShobu
                                    ? AppFontWeight.bold
                                    : AppFontWeight.regular,
                                color: !selectedIsIpponShobu
                                    ? AppKendoColors.pureWhite
                                    : themeColors.textColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        // 1本勝負
                        InkWell(
                          onTap: () =>
                              setState(() => selectedIsIpponShobu = true),
                          borderRadius: AppRadius.large,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.modernValue,
                              vertical: AppSpacing.subValue,
                            ),
                            decoration: BoxDecoration(
                              color: selectedIsIpponShobu
                                  ? themeColors.primaryAccent
                                  : (isDark
                                        ? const Color(0xFF3A3A3C)
                                        : const Color(0xFFFFFFFF)),
                              borderRadius: AppRadius.large,
                              border: Border.all(
                                color: selectedIsIpponShobu
                                    ? themeColors.primaryAccent
                                    : const Color(0x33000000),
                              ),
                            ),
                            child: Text(
                              '1本勝負',
                              style: TextStyle(
                                fontSize: AppFontSize.small,
                                fontWeight: selectedIsIpponShobu
                                    ? AppFontWeight.bold
                                    : AppFontWeight.regular,
                                color: selectedIsIpponShobu
                                    ? AppKendoColors.pureWhite
                                    : themeColors.textColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
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
                  hasExtension:
                      baseRule.enchoTimeMinutes > 0 ||
                      baseRule.isEnchoUnlimited,
                  extensionTimeMinutes: baseRule.enchoTimeMinutes,
                  status: 'in_progress',
                  order: DateTime.now().millisecondsSinceEpoch.toDouble(),
                  rule: matchRule,
                  note: '$selectedCourt\n$selectedGroupName',
                );

                await ref
                    .read(matchApplicationServiceProvider)
                    .saveMatch(newMatch);

                if (context.mounted) {
                  context.push(
                    '/match/${newMatch.id}?tournamentId=${widget.dateId}&dojoId=$dojoId',
                  );
                }
              },
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
