import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/calculator/bunaiksen_calculator_create_match_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/calculator/match_calculator_allocation_view.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/calculator/match_calculator_input_section.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/calculator/match_calculator_summary_card.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_bottom_sheet_header.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_draggable_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/floating_dock_sheet_manager.dart';
import 'package:kendo_os/features/tournament/presentation/providers/match_calculator_provider.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';

/// 🥋 部内戦ドック：総試合数・コート配分計算ボトムシート
class BunaiksenDockCalculatorSheet extends ConsumerWidget {
  const BunaiksenDockCalculatorSheet({super.key});

  static void show(BuildContext context) {
    FloatingDockSheetManager.show(
      context: context,
      builder: (_) => const BunaiksenDockCalculatorSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calcState = ref.watch(matchCalculatorProvider);
    final calcNotifier = ref.read(matchCalculatorProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'bunaiksen');

    return DockDraggableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.50,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusScope.of(context).unfocus(),
          child: ListView(
            controller: scrollController,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            children: [
              DockBottomSheetHeader(
                title: '試合数・コート配分計算',
                icon: Icons.calculate_rounded,
                iconColor: themeColors.primaryAccent,
                extraActions: [
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 20),
                    tooltip: '進行表テキストをコピー',
                    onPressed: () async {
                      AppHaptics.medium();
                      final text = calcNotifier.getClipboardSummary();
                      await Clipboard.setData(ClipboardData(text: text));
                      if (context.mounted) {
                        AppSnackBar.show(context, 'コート配分・進行表をコピーしました');
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.restart_alt_rounded, size: 20),
                    tooltip: '初期設定にリセット',
                    onPressed: () {
                      AppHaptics.light();
                      calcNotifier.resetToDefaults();
                    },
                  ),
                ],
                onClose: () => FloatingDockSheetManager.close(),
              ),
              const SizedBox(height: AppSpacing.xs),

              // 1. サマリー表示カード
              MatchCalculatorSummaryCard(
                result: calcState.result,
                settings: calcState.settings,
              ),

              const SizedBox(height: AppSpacing.md),

              // 2. 入力設定セクション
              MatchCalculatorInputSection(
                settings: calcState.settings,
                notifier: calcNotifier,
              ),

              const SizedBox(height: AppSpacing.md),

              // 3. コート別タイムライン割り振りビュー
              MatchCalculatorAllocationView(
                result: calcState.result,
                courtCount: calcState.settings.courtCount,
              ),

              const SizedBox(height: AppSpacing.xl),

              // 1. メインアクション: 部内戦試合作成ボタン
              ElevatedButton.icon(
                icon: const Icon(Icons.sports_kabaddi_rounded, size: 20),
                label: Text(
                  'この配分で部内戦の試合を作成 (全${calcState.result.totalMatches}試合)',
                  style: const TextStyle(fontWeight: AppFontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColors.primaryAccent,
                  foregroundColor: themeColors.onPrimaryAccent,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
                  elevation: 2,
                ),
                onPressed: () {
                  AppHaptics.medium();
                  BunaiksenCalculatorCreateMatchSheet.show(context);
                },
              ),
              const SizedBox(height: AppSpacing.sm),

              // 2. サブアクション: コピーボタン（枠線スタイル）
              OutlinedButton.icon(
                icon: const Icon(Icons.content_copy_rounded, size: 18),
                label: const Text('進行予定・コート配分表をテキストコピー'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: themeColors.primaryAccent,
                  side: BorderSide(
                    color: themeColors.primaryAccent.withValues(alpha: 0.5),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
                ),
                onPressed: () async {
                  AppHaptics.medium();
                  final text = calcNotifier.getClipboardSummary();
                  await Clipboard.setData(ClipboardData(text: text));
                  if (context.mounted) {
                    AppSnackBar.show(context, 'コート配分・進行表をコピーしました');
                  }
                },
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        );
      },
    );
  }
}
