import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';
import 'package:kendo_os/features/match/presentation/providers/match_rule_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/order_setup/order_setup_base_order_actions_bar.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/order_setup/order_setup_league_participants_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/order_setup/order_setup_match_generator.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/order_setup/order_setup_matchup_config_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/order_setup/order_setup_player_select_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/order_setup/order_setup_reorderable_slots_view.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/order_setup/order_setup_static_header.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/order_setup/order_setup_sticky_bottom_bar.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/time/time_source.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:kendo_os/shared/widgets/liquid_background.dart';
import 'package:kendo_os/shared/widgets/manual_help_button.dart';
import '../providers/last_used_settings_provider.dart';
import '../providers/match_list_provider.dart';

final playerListProvider = StreamProvider.autoDispose<List<PlayerModel>>((ref) {
  return ref.watch(playerRepositoryProvider).getPlayers();
});

// ★ 追加：登録した「よく使うチーム名」を取得するプロバイダー
final customTeamNamesProvider = StreamProvider.autoDispose<List<String>>((ref) {
  return ref.watch(playerRepositoryProvider).watchCustomTeamNames();
});

// ★ 修正：相手チーム用に過去の全試合から履歴を抽出するプロバイダー
final opponentTeamHistoryProvider = Provider.autoDispose<List<String>>((ref) {
  final allMatches = ref.watch(matchListProvider);
  final Set<String> history = {};
  for (final m in allMatches) {
    if (m.redName.contains(':')) {
      history.add(m.redName.split(':').first.trim());
    }
    if (m.whiteName.contains(':')) {
      history.add(m.whiteName.split(':').first.trim());
    }
  }
  return history.toList()..sort();
});

class OrderSetupScreen extends ConsumerStatefulWidget {
  final String tournamentId;

  const OrderSetupScreen({super.key, required this.tournamentId});

  @override
  ConsumerState<OrderSetupScreen> createState() => _OrderSetupScreenState();
}

class _OrderSetupScreenState extends ConsumerState<OrderSetupScreen> {
  late List<String> _positions;
  final Map<int, String> _selectedPlayers = {};

  final TextEditingController _opponentTeamController = TextEditingController();
  final FocusNode _opponentTeamFocusNode = FocusNode(); // ★ 追加：フォーカス状態を永続化
  final Map<int, String> _opponentPlayers = {};
  bool _isOwnTeamRed = true;
  late AppThemeColors _themeColors;

  // ★ リーグ戦拡張：参加者リスト
  final List<String> _leagueParticipants = [];
  final Map<String, List<String>> _leagueTeamOrders =
      {}; // ★ 追加：参加チームごとのオーダーを保持

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_onFocusChange);

    final rule = ref.read(matchRuleProvider);
    _positions = List.from(rule.positions);

    if (rule.baseOrder.isNotEmpty) {
      for (int i = 0; i < rule.baseOrder.length && i < _positions.length; i++) {
        if (rule.baseOrder[i].isNotEmpty) {
          _selectedPlayers[i] = rule.baseOrder[i];
        }
      }
    }
    // ★ リーグ戦の場合、自チームを最初の参加者として登録
    if (rule.isLeague) {
      _leagueParticipants.add('自チーム'); // ★ 修正：名前ではなくキーワードで固定し、ペアリング生成時に中身を呼ぶ
    }
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_onFocusChange);
    _opponentTeamController.dispose();
    _opponentTeamFocusNode.dispose(); // ★ 追加：メモリリーク防止
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _selectPlayer(int index, List<PlayerModel> masterPlayers) async {
    final result = await OrderSetupPlayerSelectBottomSheet.show(
      context,
      masterPlayers: masterPlayers,
      themeColors: _themeColors,
    );

    if (result == 'CLEAR_FLAG') {
      setState(() => _selectedPlayers.remove(index));
    } else if (result != null && result.trim().isNotEmpty) {
      setState(() => _selectedPlayers[index] = result);
    }
  }

  void _addExtraPosition() {
    setState(() {
      int newNum = _positions.length + 1;
      _positions.insert(_positions.length - 1, '追加枠$newNum');
    });
  }

  Widget _buildStaticHeader() {
    return OrderSetupStaticHeader(themeColors: _themeColors);
  }

  Future<void> _handleConfirmAndProceed(String matchType) async {
    final rule = ref.read(matchRuleProvider);

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
              backgroundColor: _themeColors.primaryAccent,
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

    if (isStartNow == null || !mounted) {
      return;
    }

    showAppDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      if (rule.isLeague) {
        if (_leagueParticipants.length < 2) {
          AppSnackBar.showError(context, 'リーグ戦には少なくとも2つのチーム・選手が必要です');
          if (mounted) Navigator.of(context, rootNavigator: true).pop();
          return;
        }
        ref
            .read(matchRuleProvider.notifier)
            .updateRule(rule.copyWith(leagueOrder: _leagueParticipants));
      }

      final double baseOrder = ref
          .read(timeSourceProvider)
          .now()
          .millisecondsSinceEpoch
          .toDouble();

      final matchesToSave = OrderSetupMatchGenerator.generateMatches(
        tournamentId: widget.tournamentId,
        rule: rule,
        positions: _positions,
        selectedPlayers: _selectedPlayers,
        opponentPlayers: _opponentPlayers,
        opponentTeamInput: _opponentTeamController.text,
        isOwnTeamRed: _isOwnTeamRed,
        leagueParticipants: _leagueParticipants,
        leagueTeamOrders: _leagueTeamOrders,
        matchType: matchType,
        isStartNow: isStartNow,
        baseOrder: baseOrder,
      );

      if (matchesToSave.isNotEmpty) {
        await ref
            .read(matchApplicationServiceProvider)
            .saveMatchesBulk(matchesToSave);
      }

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      final String senpoMatchId = matchesToSave.isNotEmpty
          ? matchesToSave.first.id
          : '';

      if (isStartNow) {
        if (senpoMatchId.isNotEmpty) {
          context.push('/match/$senpoMatchId');
        } else {
          context.go('/home/${widget.tournamentId}');
        }
      } else {
        AppSnackBar.showSuccess(context, '試合をプールしました（待機リストに追加）');
        context.go('/home/${widget.tournamentId}');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      AppSnackBar.showError(context, '保存に失敗しました: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerListAsync = ref.watch(playerListProvider);
    final rule = ref.watch(matchRuleProvider);
    final String matchType =
        ref.watch(lastUsedSettingsProvider)['matchType'] as String? ?? '';
    final enableLiquidGlass = ref.watch(settingsProvider).enableLiquidGlass;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    return LiquidBackground(
      child: Scaffold(
        backgroundColor: AppKendoColors.transparent,
        appBar: const AppHeader(
          title: 'オーダー編成',
          backgroundColor: AppKendoColors.transparent,
          actions: [
            ManualHelpButton(
              manualPath: 'docs/manuals/operator/team_registration.md',
            ),
            SizedBox(width: AppSpacing.sm),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: playerListAsync.when(
                data: (masterPlayers) => ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildStaticHeader(),
                    if (rule.isLeague)
                      OrderSetupLeagueParticipantsSection(
                        themeColors: _themeColors,
                        leagueParticipants: _leagueParticipants,
                        leagueTeamOrders: _leagueTeamOrders,
                        positions: _positions,
                        ruleTeamName: rule.teamName,
                        matchType: matchType,
                        opponentTeamSuggestions: ref.watch(
                          opponentTeamHistoryProvider,
                        ),
                        onParticipantsChanged: () => setState(() {}),
                        isDark: isDark,
                      )
                    else
                      OrderSetupMatchupConfigSection(
                        themeColors: _themeColors,
                        isOwnTeamRed: _isOwnTeamRed,
                        onIsOwnTeamRedChanged: (val) =>
                            setState(() => _isOwnTeamRed = val),
                        opponentTeamController: _opponentTeamController,
                        opponentTeamFocusNode: _opponentTeamFocusNode,
                        opponentTeamSuggestions: ref.watch(
                          opponentTeamHistoryProvider,
                        ),
                        isDark: isDark,
                      ),
                    OrderSetupBaseOrderActionsBar(
                      themeColors: _themeColors,
                      isDark: isDark,
                      canLoadBaseOrder: rule.baseOrder.isNotEmpty,
                      onSaveBaseOrder: () {
                        final currentOrder = List.generate(
                          _positions.length,
                          (i) => _selectedPlayers[i] ?? '',
                        );
                        ref
                            .read(matchRuleProvider.notifier)
                            .updateBaseOrder(currentOrder);
                        AppSnackBar.showSuccess(
                          context,
                          '現在のオーダーを「基本オーダー」として記憶しました',
                        );
                      },
                      onLoadBaseOrder: () {
                        setState(() {
                          for (
                            int i = 0;
                            i < rule.baseOrder.length && i < _positions.length;
                            i++
                          ) {
                            if (rule.baseOrder[i].isNotEmpty) {
                              _selectedPlayers[i] = rule.baseOrder[i];
                            } else {
                              _selectedPlayers.remove(i);
                            }
                          }
                        });
                        AppSnackBar.showSuccess(context, '基本オーダーを呼び出しました');
                      },
                    ),
                    OrderSetupReorderableSlotsView(
                      positions: _positions,
                      selectedPlayers: _selectedPlayers,
                      opponentPlayers: _opponentPlayers,
                      teamName: rule.teamName,
                      isLeague: rule.isLeague,
                      isDark: isDark,
                      themeColors: _themeColors,
                      masterPlayers: masterPlayers,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          final oldPlayer = _selectedPlayers[oldIndex];
                          final newPlayer = _selectedPlayers[newIndex];

                          if (oldPlayer != null) {
                            _selectedPlayers[newIndex] = oldPlayer;
                          } else {
                            _selectedPlayers.remove(newIndex);
                          }

                          if (newPlayer != null) {
                            _selectedPlayers[oldIndex] = newPlayer;
                          } else {
                            _selectedPlayers.remove(oldIndex);
                          }
                        });
                      },
                      onSelectPlayerTap: (index) async {
                        FocusManager.instance.primaryFocus?.unfocus();
                        await _selectPlayer(index, masterPlayers);
                        if (!mounted) return;
                        FocusManager.instance.primaryFocus?.unfocus();
                      },
                      onOpponentChanged: (index, val) {
                        _opponentPlayers[index] = val;
                      },
                      onVacantPressed: (index) {
                        setState(() => _opponentPlayers[index] = '欠員');
                        FocusScope.of(context).unfocus();
                      },
                    ),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('エラー: $err')),
              ),
            ),
            OrderSetupStickyBottomBar(
              themeColors: _themeColors,
              isDark: isDark,
              enableLiquidGlass: enableLiquidGlass,
              onAddExtraPosition: _addExtraPosition,
              onConfirmAndProceed: () => _handleConfirmAndProceed(matchType),
            ),
          ],
        ),
      ),
    );
  }
}
