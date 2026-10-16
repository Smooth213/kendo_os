import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';
import 'package:kendo_os/features/tournament/domain/match_calculator/bunaiksen_calculator_match_generator.dart';
import 'package:kendo_os/features/tournament/domain/match_calculator/match_calculation_models.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/calculator/bunaiksen_calculator_advancement_card.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/calculator/bunaiksen_calculator_create_match_roster_card.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_bottom_sheet_header.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_draggable_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/floating_dock_sheet_manager.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_command_provider.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_matches_provider.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart';
import 'package:kendo_os/features/tournament/presentation/providers/match_calculator_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';

/// 🥋 試合作成モード
enum _CreationMode {
  placeholder, // 仮名で即座に作成（枠だけ）
  roster, // 部員名簿から選択・割り当て
}

/// 🥋 試合数・コート配分計算からの部内戦試合作成ボトムシート
class BunaiksenCalculatorCreateMatchSheet extends ConsumerStatefulWidget {
  const BunaiksenCalculatorCreateMatchSheet({super.key});

  static void show(BuildContext context) {
    FloatingDockSheetManager.show(
      context: context,
      builder: (_) => const BunaiksenCalculatorCreateMatchSheet(),
    );
  }

  @override
  ConsumerState<BunaiksenCalculatorCreateMatchSheet> createState() =>
      _BunaiksenCalculatorCreateMatchSheetState();
}

class _BunaiksenCalculatorCreateMatchSheetState
    extends ConsumerState<BunaiksenCalculatorCreateMatchSheet> {
  _CreationMode _mode = _CreationMode.placeholder;
  TournamentAdvancementMethod _advancementMethod =
      TournamentAdvancementMethod.directRank;
  final List<String> _selectedPlayers = [];
  bool _resetExistingMatches = false;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final calcState = ref.watch(matchCalculatorProvider);
    final settings = calcState.settings;
    final totalMatches = calcState.result.totalMatches;
    final requiredCount = settings.effectiveParticipantCount;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'bunaiksen');

    final viewDate = ref.watch(bunaiksenViewDateProvider);
    final dateStr = DateFormat('yyyyMMdd').format(viewDate);
    final todayId = 'bunaiksen_$dateStr';
    final existingMatches = ref.watch(bunaiksenMatchesProvider(todayId));

    final isPrelimWithTournament =
        settings.format == MatchFormatType.prelimLeagueAndTournament;

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
                title: '部内戦の試合作成',
                icon: Icons.sports_kabaddi_rounded,
                iconColor: themeColors.primaryAccent,
                onClose: () => FloatingDockSheetManager.close(),
              ),
              const SizedBox(height: AppSpacing.xs),

              // 1. 設定要約カード
              _buildSummaryCard(settings, totalMatches, themeColors, isDark),

              const SizedBox(height: AppSpacing.md),

              // 2. 作成モード切替（仮名即作成 vs 名簿割り当て）
              _buildModeSelector(themeColors, isDark),

              const SizedBox(height: AppSpacing.md),

              // 3. 名簿選択セクション（名簿モード時のみ）
              if (_mode == _CreationMode.roster) ...[
                BunaiksenCalculatorCreateMatchRosterCard(
                  requiredCount: requiredCount,
                  selectedPlayers: _selectedPlayers,
                  onChanged: (list) {
                    setState(() {
                      _selectedPlayers.clear();
                      _selectedPlayers.addAll(list);
                    });
                  },
                  themeColors: themeColors,
                  isDark: isDark,
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // 4. 予選L＋決勝Tの進出方式（トーナメント進出枠がある場合）
              if (isPrelimWithTournament) ...[
                BunaiksenCalculatorAdvancementCard(
                  advancementMethod: _advancementMethod,
                  onChanged: (val) {
                    setState(() => _advancementMethod = val);
                  },
                  themeColors: themeColors,
                  isDark: isDark,
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // 5. 既存試合の扱い（既存試合がある場合）
              if (existingMatches.isNotEmpty) ...[
                _buildExistingMatchesOption(
                  existingCount: existingMatches.length,
                  themeColors: themeColors,
                  isDark: isDark,
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              const SizedBox(height: AppSpacing.sm),

              // 6. 作成実行ボタン
              _buildSubmitButton(
                totalMatches: totalMatches,
                todayId: todayId,
                existingMatches: existingMatches,
                calcState: calcState,
                themeColors: themeColors,
              ),

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        );
      },
    );
  }

  /// 要約カード
  Widget _buildSummaryCard(
    CalculatorSettings settings,
    int totalMatches,
    AppThemeColors themeColors,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: AppRadius.medium,
        border: Border.all(
          color: themeColors.primaryAccent.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: themeColors.primaryAccent.withValues(alpha: 0.15),
            child: Icon(
              settings.format.icon,
              color: themeColors.primaryAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  settings.format.label,
                  style: const TextStyle(
                    fontWeight: AppFontWeight.bold,
                    fontSize: AppFontSize.body,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '参加: ${settings.effectiveParticipantCount}名 • ${settings.courtCount}コート • 1試合${settings.matchDurationFormatted}',
                  style: TextStyle(
                    fontSize: AppFontSize.caption,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: themeColors.primaryAccent,
              borderRadius: AppRadius.tiny,
            ),
            child: Text(
              '全$totalMatches試合',
              style: TextStyle(
                color: themeColors.onPrimaryAccent,
                fontSize: AppFontSize.caption,
                fontWeight: AppFontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// モード切替タブ
  Widget _buildModeSelector(AppThemeColors themeColors, bool isDark) {
    return SegmentedButton<_CreationMode>(
      segments: const [
        ButtonSegment(
          value: _CreationMode.placeholder,
          icon: Icon(Icons.flash_on_rounded, size: 16),
          label: Text('仮名で即枠作成'),
        ),
        ButtonSegment(
          value: _CreationMode.roster,
          icon: Icon(Icons.people_alt_rounded, size: 16),
          label: Text('部員名簿から選択'),
        ),
      ],
      selected: {_mode},
      onSelectionChanged: (set) {
        AppHaptics.light();
        setState(() => _mode = set.first);
      },
      style: ButtonStyle(
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: AppRadius.small),
        ),
      ),
    );
  }

  /// 既存試合の扱いオプション
  Widget _buildExistingMatchesOption({
    required int existingCount,
    required AppThemeColors themeColors,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppKendoColors.amber.withValues(alpha: 0.1),
        borderRadius: AppRadius.medium,
        border: Border.all(color: AppKendoColors.amber.withValues(alpha: 0.4)),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        title: Text(
          '既存の試合 ($existingCount試合) をリセットして新設',
          style: const TextStyle(
            fontSize: AppFontSize.bodySmall,
            fontWeight: AppFontWeight.bold,
          ),
        ),
        subtitle: const Text('OFFの場合は既存の試合の後ろに追加されます'),
        value: _resetExistingMatches,
        activeThumbColor: AppKendoColors.amber[800],
        onChanged: (val) {
          AppHaptics.light();
          setState(() => _resetExistingMatches = val);
        },
      ),
    );
  }

  /// 作成ボタン
  Widget _buildSubmitButton({
    required int totalMatches,
    required String todayId,
    required List<dynamic> existingMatches,
    required MatchCalculatorState calcState,
    required AppThemeColors themeColors,
  }) {
    return ElevatedButton.icon(
      icon: _isSaving
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppKendoColors.pureWhite,
              ),
            )
          : const Icon(Icons.add_task_rounded, size: 20),
      label: Text(
        _isSaving ? '試合作成中...' : 'この配分で部内戦に全$totalMatches試合を作成',
        style: const TextStyle(fontWeight: AppFontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: themeColors.primaryAccent,
        foregroundColor: themeColors.onPrimaryAccent,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
        elevation: 2,
      ),
      onPressed: _isSaving
          ? null
          : () => _executeCreateMatches(
              todayId: todayId,
              existingMatches: existingMatches,
              calcState: calcState,
              totalMatches: totalMatches,
            ),
    );
  }

  /// 作成処理実行
  Future<void> _executeCreateMatches({
    required String todayId,
    required List<dynamic> existingMatches,
    required MatchCalculatorState calcState,
    required int totalMatches,
  }) async {
    setState(() => _isSaving = true);
    try {
      AppHaptics.medium();

      // 1. 既存試合のリセット処理（ONの場合）
      if (_resetExistingMatches && existingMatches.isNotEmpty) {
        final existingIds = existingMatches.map((m) => m.id as String).toList();
        await ref.read(matchCommandProvider).deleteMatchesBulk(existingIds);
      }

      // 2. 基準オーダーの決定
      final double baseOrder = _resetExistingMatches
          ? 0.0
          : (existingMatches.isEmpty
                ? 0.0
                : existingMatches
                          .map((m) => (m.order as num).toDouble())
                          .fold<double>(
                            0.0,
                            (prev, ord) => ord > prev ? ord : prev,
                          ) +
                      10.0);

      // 3. ルールの取得
      final currentRule = ref.read(bunaiksenRuleProvider);

      // 4. 試合モデルの一括生成
      final matchesToSave = BunaiksenCalculatorMatchGenerator.generateMatches(
        result: calcState.result,
        settings: calcState.settings,
        rule: currentRule,
        tournamentId: todayId,
        playerNames:
            _mode == _CreationMode.roster && _selectedPlayers.isNotEmpty
            ? _selectedPlayers
            : null,
        advancementMethod: _advancementMethod,
        baseOrder: baseOrder,
      );

      // 5. 一括保存
      await ref
          .read(matchApplicationServiceProvider)
          .saveMatchesBulk(matchesToSave);

      AppHaptics.heavy();

      // 6. 完了ダイアログまたは閉じる
      FloatingDockSheetManager.close();

      if (mounted) {
        final courtCount = calcState.settings.courtCount;
        AppSnackBar.show(context, '全$totalMatches試合（$courtCountコート）を作成しました！');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, '試合作成に失敗しました: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
