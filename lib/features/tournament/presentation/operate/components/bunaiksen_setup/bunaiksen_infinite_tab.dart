import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_command_provider.dart';
import 'package:kendo_os/shared/time/time_source.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/glass_button.dart';
import 'package:kendo_os/shared/widgets/multi_player_select_input.dart';
import 'package:uuid/uuid.dart';

/// 🥋 特設部内戦 試合作成「無限勝ち抜き戦」タブ
class BunaiksenInfiniteTab extends ConsumerWidget {
  final AppThemeColors themeColors;

  const BunaiksenInfiniteTab({super.key, required this.themeColors});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(bunaiksenInfiniteQueueProvider);

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
            initialSelected: queue,
            label: '待機列のメンバーを選択（複数可）',
            onConfirm: (selectedList) {
              ref
                  .read(bunaiksenInfiniteQueueProvider.notifier)
                  .setPlayers(selectedList);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '待機列 (${queue.length}人)',
                style: const TextStyle(fontWeight: AppFontWeight.bold),
              ),
              TextButton.icon(
                icon: const Icon(Icons.shuffle),
                label: const Text('シャッフル'),
                onPressed: () =>
                    ref.read(bunaiksenInfiniteQueueProvider.notifier).shuffle(),
              ),
            ],
          ),
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
                child: queue.isEmpty
                    ? Center(
                        child: Text(
                          '選手を追加してください',
                          style: TextStyle(
                            color: context.appColors.subTextColor,
                          ),
                        ),
                      )
                    : ReorderableListView.builder(
                        itemCount: queue.length,
                        onReorderItem: (oldIndex, newIndex) {
                          ref
                              .read(bunaiksenInfiniteQueueProvider.notifier)
                              .reorder(oldIndex, newIndex);
                        },
                        itemBuilder: (context, index) {
                          final p = queue[index];
                          return ListTile(
                            key: ValueKey(p),
                            leading: CircleAvatar(
                              backgroundColor: index < 2
                                  ? AppKendoColors.hansokuRed
                                  : context.appColors.separatorColor,
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: index < 2
                                      ? AppKendoColors.hansokuRed
                                      : context.appColors.textColor,
                                  fontSize: AppFontSize.small,
                                  fontWeight: AppFontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              p,
                              style: TextStyle(
                                fontWeight: index < 2
                                    ? AppFontWeight.bold
                                    : AppFontWeight.regular,
                              ),
                            ),
                            subtitle: index == 0
                                ? const Text(
                                    '最初の赤選手',
                                    style: TextStyle(
                                      fontSize: AppFontSize.badge,
                                      color: AppKendoColors.red,
                                    ),
                                  )
                                : index == 1
                                ? const Text(
                                    '最初の白選手',
                                    style: TextStyle(
                                      fontSize: AppFontSize.badge,
                                      color: AppKendoColors.blueGrey,
                                    ),
                                  )
                                : null,
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: AppKendoColors.grey,
                              ),
                              onPressed: () => ref
                                  .read(bunaiksenInfiniteQueueProvider.notifier)
                                  .removePlayer(p),
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
              icon: Icons.local_fire_department,
              label: '無限稽古スタート',
              color: themeColors.primaryAccent,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              expandContent: false,
              onPressed: queue.length < 2
                  ? null
                  : () async {
                      final notifier = ref.read(
                        bunaiksenInfiniteQueueProvider.notifier,
                      );
                      final p1 = notifier.popFirst();
                      final p2 = notifier.popFirst();
                      if (p1 == null || p2 == null) return;

                      final rule = ref.read(bunaiksenRuleProvider);
                      final now = ref.read(timeSourceProvider).now();
                      final dateStr = DateFormat(
                        'yyyyMMdd',
                      ).format(DateTime.now());
                      final todayId = 'bunaiksen_$dateStr';
                      final groupId = 'infinite_$dateStr';
                      final matchId = const Uuid().v4();

                      final newMatch = MatchModel(
                        id: matchId,
                        tournamentId: todayId,
                        groupName: groupId,
                        matchType: '無限勝ち抜き',
                        redName: p1,
                        whiteName: p2,
                        matchTimeMinutes: rule.matchTimeMinutes,
                        hasExtension: false,
                        extensionTimeMinutes: 0.0,
                        status: 'in_progress',
                        order: now.millisecondsSinceEpoch.toDouble(),
                        rule: rule,
                        note: '無限勝ち抜き',
                        isKachinuki: true,
                      );

                      ref
                          .read(bunaiksenInfiniteStreakProvider.notifier)
                          .clearAll();

                      await ref.read(matchCommandProvider).addMatch(newMatch);
                      if (context.mounted) context.push('/match/$matchId');
                    },
            ),
          ),
        ],
      ),
    );
  }
}
