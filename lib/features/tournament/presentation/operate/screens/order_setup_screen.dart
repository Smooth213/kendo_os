import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/presentation/providers/match_rule_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/order_setup/order_setup_base_order_actions_bar.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/order_setup/order_setup_league_participants_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/order_setup/order_setup_matchup_config_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/order_setup/order_setup_player_select_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/order_setup/order_setup_position_slot.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/order_setup/order_setup_static_header.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/time/time_source.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/utils/text_sanitizer.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:kendo_os/shared/widgets/liquid_background.dart';
import 'package:kendo_os/shared/widgets/manual_help_button.dart';
import 'package:uuid/uuid.dart';
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

  @override
  Widget build(BuildContext context) {
    final playerListAsync = ref.watch(playerListProvider);
    final rule = ref.watch(matchRuleProvider);
    // ★ 追加：lastSettings から試合形式の文字列(matchType)を取得する
    final String matchType =
        ref.watch(lastUsedSettingsProvider)['matchType'] as String? ?? '';
    final enableLiquidGlass = ref.watch(settingsProvider).enableLiquidGlass;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
    final inputBgColor = themeColors.cardBackground;
    final borderColor = isDark
        ? const Color(0xFF38383A)
        : context.appColors.separatorColor;
    final subTextColor = isDark
        ? const Color(0xFF8E8E93)
        : context.appColors.subTextColor;

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
                    // ★ 直感UX向上：ドラッグ＆ドロップ（長押し並び替え）対応のオーダー登録スロット一覧
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.xs,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.swap_vert,
                            size: 16,
                            color: _themeColors.primaryAccent,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '長押しドラッグで選手の配置・順番を自由に入れ替えできます',
                            style: TextStyle(
                              fontSize: AppFontSize.caption,
                              fontWeight: AppFontWeight.bold,
                              color: subTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        AppSpacing.lg,
                      ),
                      itemCount: _positions.length,
                      onReorderItem: (oldIndex, newIndex) {
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
                      itemBuilder: (context, index) {
                        final posName = _positions[index];
                        final playerName = _selectedPlayers[index] ?? '未定';
                        final isSelected = _selectedPlayers.containsKey(index);

                        return Padding(
                          key: ValueKey(
                            'order_slot_${_positions[index]}_$index',
                          ),
                          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                          child: OrderSetupPositionSlot(
                            index: index,
                            posName: posName,
                            playerName: playerName,
                            teamName: rule.teamName,
                            isSelected: isSelected,
                            onTap: () async {
                              FocusManager.instance.primaryFocus?.unfocus();
                              await _selectPlayer(index, masterPlayers);
                              if (!mounted) return;
                              FocusManager.instance.primaryFocus?.unfocus();
                            },
                            isDark: isDark,
                            showOpponentField: !rule.isLeague,
                            opponentPlayerName: _opponentPlayers[index] ?? '',
                            onOpponentChanged: (val) =>
                                _opponentPlayers[index] = val,
                            onVacantPressed: () {
                              setState(() => _opponentPlayers[index] = '欠員');
                              FocusScope.of(context).unfocus();
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('エラー: $err')),
              ),
            ),
            Container(
              padding: EdgeInsets.only(
                left: AppSpacing.xl,
                right: AppSpacing.xl,
                top: AppSpacing.xl,
                bottom: MediaQuery.of(context).padding.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: enableLiquidGlass
                    ? AppKendoColors.transparent
                    : inputBgColor,
                border: Border(
                  top: BorderSide(
                    color: enableLiquidGlass
                        ? AppKendoColors.transparent
                        : borderColor,
                    width: 0.5,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton.icon(
                    onPressed: _addExtraPosition,
                    icon: Icon(
                      Icons.add_circle_outline,
                      color: isDark
                          ? const Color(0xFF64B5F6)
                          : _themeColors.primaryAccent,
                    ),
                    label: Text(
                      'イレギュラー枠を追加する（錬成会用）',
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF64B5F6)
                            : _themeColors.primaryAccent,
                        fontWeight: AppFontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        // ★ 修正：ここではチェックせず、後の pairings 生成直前のバリデーションに集約します
                        final bool? isStartNow = await showAppDialog<bool>(
                          context: context,
                          builder: (context) => AppDialog(
                            title: '試合の登録',
                            content: const Text(
                              'このオーダーで試合を登録します。今すぐ試合画面に進みますか？',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text(
                                  '後で（リストに保存）',
                                  style: TextStyle(color: AppKendoColors.grey),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _themeColors.primaryAccent,
                                  foregroundColor: AppKendoColors.pureWhite,
                                  elevation: 0,
                                ),
                                child: const Text(
                                  '今すぐ試合開始',
                                  style: TextStyle(
                                    fontWeight: AppFontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (isStartNow == null) {
                          return;
                        }

                        if (!context.mounted) {
                          return;
                        }
                        // ★ Phase 8-1: ダイアログの「戻る」が画面を消さないように、rootNavigatorを使う
                        showAppDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) =>
                              const Center(child: CircularProgressIndicator()),
                        );

                        try {
                          // ★ 修正：不要になった古い変数を綺麗にお掃除
                          String senpoMatchId = '';
                          double baseOrder = ref
                              .read(timeSourceProvider)
                              .now()
                              .millisecondsSinceEpoch
                              .toDouble();
                          List<MatchModel> matchesToSave = [];

                          // ★ 追加：リーグ戦であることを明示するタグを生成し、後で全試合のnoteに付与する
                          final String saveNote = rule.isLeague
                              ? '[リーグ戦] ${rule.note}'.trim()
                              : rule.note;
                          // ★ 追加：リーグ全体を1つのアコーディオンにまとめるための共通ID
                          final String leagueGroupId = rule.isLeague
                              ? const Uuid().v4()
                              : '';

                          List<List<String>> pairings = [];
                          // ★ 修正：入力された相手チーム名をお掃除フィルターに通す！
                          String myTeamName = rule.teamName.isNotEmpty
                              ? rule.teamName
                              : '自チーム';
                          String opTeamName = TextSanitizer.clean(
                            _opponentTeamController.text,
                          );
                          if (opTeamName.isEmpty) opTeamName = '対戦相手';

                          if (rule.isLeague) {
                            if (_leagueParticipants.length < 2) {
                              AppSnackBar.showError(
                                context,
                                'リーグ戦には少なくとも2つのチーム・選手が必要です',
                              );
                              Navigator.of(context, rootNavigator: true).pop();
                              return;
                            }

                            // ★ 修正：並び替えた順序をルールに記憶させる
                            ref
                                .read(matchRuleProvider.notifier)
                                .updateRule(
                                  rule.copyWith(
                                    leagueOrder: _leagueParticipants,
                                  ),
                                );

                            // ★ 修正：並び替えたリストに基づいて総当たりのペアを生成
                            for (
                              int i = 0;
                              i < _leagueParticipants.length;
                              i++
                            ) {
                              for (
                                int j = i + 1;
                                j < _leagueParticipants.length;
                                j++
                              ) {
                                pairings.add([
                                  _leagueParticipants[i],
                                  _leagueParticipants[j],
                                ]);
                              }
                            }
                          } else {
                            if (_isOwnTeamRed) {
                              pairings.add([myTeamName, opTeamName]);
                            } else {
                              pairings.add([opTeamName, myTeamName]);
                            }
                          }

                          await Future.microtask(() {
                            for (
                              int pIndex = 0;
                              pIndex < pairings.length;
                              pIndex++
                            ) {
                              final pair = pairings[pIndex];
                              // ★ 修正：リーグ戦なら共通IDを使い、通常なら個別のIDを発行
                              final String teamGroupId = rule.isLeague
                                  ? leagueGroupId
                                  : const Uuid().v4();

                              if (rule.isKachinuki) {
                                List<String> redFull = [];
                                List<String> whiteFull = [];

                                for (int i = 0; i < _positions.length; i++) {
                                  String myP = _selectedPlayers[i] ?? '未定';
                                  if (myP.isEmpty) myP = '未定';
                                  String opP =
                                      _opponentPlayers[i]?.trim() ?? '';
                                  if (opP.isEmpty) opP = '選手';
                                  String myFull = '$myTeamName : $myP';
                                  String opFull = '$opTeamName : $opP';
                                  String rN, wN;
                                  if (rule.isLeague) {
                                    // ★ 修正：入力されたオーダーを呼び出して完璧にセットする！
                                    String rTeam = pair[0];
                                    String wTeam = pair[1];
                                    String rPlayer = (rTeam == '自チーム')
                                        ? myP
                                        : (_leagueTeamOrders[rTeam]?[i] ??
                                              '選手');
                                    if (rPlayer.isEmpty) rPlayer = '選手';
                                    String wPlayer = (wTeam == '自チーム')
                                        ? myP
                                        : (_leagueTeamOrders[wTeam]?[i] ??
                                              '選手');
                                    if (wPlayer.isEmpty) wPlayer = '選手';

                                    rN = (rTeam == '自チーム')
                                        ? myFull
                                        : '$rTeam : $rPlayer';
                                    wN = (wTeam == '自チーム')
                                        ? myFull
                                        : '$wTeam : $wPlayer';
                                  } else {
                                    rN = _isOwnTeamRed ? myFull : opFull;
                                    wN = _isOwnTeamRed ? opFull : myFull;
                                  }
                                  redFull.add(rN);
                                  whiteFull.add(wN);
                                }

                                final matchId = const Uuid().v4();
                                if (senpoMatchId.isEmpty) {
                                  senpoMatchId = matchId;
                                }

                                final newMatch = MatchModel(
                                  id: matchId,
                                  tournamentId: widget.tournamentId,
                                  category: rule.category.isNotEmpty
                                      ? rule.category
                                      : null,
                                  groupName: teamGroupId,
                                  matchType: _positions[0],
                                  whiteName: whiteFull[0],
                                  redName: redFull[0],
                                  status: (isStartNow && pIndex == 0)
                                      ? 'in_progress'
                                      : 'waiting',
                                  refereeNames: [],

                                  // ★ 全て rule からもらう
                                  matchTimeMinutes: rule.matchTimeMinutes,
                                  isRunningTime: rule.isRunningTime,
                                  hasExtension:
                                      rule.enchoTimeMinutes > 0 ||
                                      rule.isEnchoUnlimited,
                                  extensionTimeMinutes: rule.enchoTimeMinutes,
                                  extensionCount: rule.enchoCount,
                                  hasHantei: rule.hasHantei,

                                  order: baseOrder + (pIndex * 10),
                                  note: saveNote,
                                  isKachinuki: true,
                                  matchScene: rule.matchScene != 'honsen'
                                      ? rule.matchScene
                                      : (rule.isRenseikai
                                            ? 'renseikai'
                                            : 'honsen'),
                                  rule: rule,
                                  redRemaining: redFull.length > 1
                                      ? redFull.sublist(1)
                                      : [],
                                  whiteRemaining: whiteFull.length > 1
                                      ? whiteFull.sublist(1)
                                      : [],
                                );
                                matchesToSave.add(newMatch);
                              } else {
                                for (int i = 0; i < _positions.length; i++) {
                                  final String matchId = const Uuid().v4();
                                  if (senpoMatchId.isEmpty) {
                                    senpoMatchId = matchId;
                                  }
                                  final posName = _positions[i];
                                  String myP = _selectedPlayers[i] ?? '未定';
                                  if (myP.isEmpty) myP = '未定';
                                  String opP =
                                      _opponentPlayers[i]?.trim() ?? '';
                                  if (opP.isEmpty) opP = '選手';
                                  String myFull = '$myTeamName : $myP';
                                  String opFull = '$opTeamName : $opP';
                                  String rName, wName;
                                  if (rule.isLeague) {
                                    // ★ 修正：入力されたオーダーと「個人戦/団体戦」の違いを反映！
                                    String rTeam = pair[0];
                                    String wTeam = pair[1];
                                    String rPlayer = (rTeam == '自チーム')
                                        ? myP
                                        : (_leagueTeamOrders[rTeam]?[i] ??
                                              '選手');
                                    if (rPlayer.isEmpty) rPlayer = '選手';
                                    String wPlayer = (wTeam == '自チーム')
                                        ? myP
                                        : (_leagueTeamOrders[wTeam]?[i] ??
                                              '選手');
                                    if (wPlayer.isEmpty) wPlayer = '選手';

                                    // ★ 修正：画面上部で既に取得している matchType をそのまま利用する
                                    if (matchType.contains('個人戦')) {
                                      // ★ 修正：ダイアログの時点で既に「所属 : 名前」になっているので、そのまま使う！
                                      rName = (rTeam == '自チーム')
                                          ? myFull
                                          : rTeam;
                                      wName = (wTeam == '自チーム')
                                          ? myFull
                                          : wTeam;
                                    } else {
                                      rName = (rTeam == '自チーム')
                                          ? myFull
                                          : '$rTeam : $rPlayer';
                                      wName = (wTeam == '自チーム')
                                          ? myFull
                                          : '$wTeam : $wPlayer';
                                    }
                                  } else {
                                    rName = _isOwnTeamRed ? myFull : opFull;
                                    wName = _isOwnTeamRed ? opFull : myFull;
                                  }
                                  bool isFirstMatchOfAll =
                                      (pIndex == 0 && i == 0);
                                  final newMatch = MatchModel(
                                    id: matchId,
                                    tournamentId: widget.tournamentId,
                                    category: rule.category.isNotEmpty
                                        ? rule.category
                                        : null,
                                    groupName: teamGroupId,
                                    matchType: posName,
                                    redName: rName,
                                    whiteName: wName,
                                    status: (isStartNow && isFirstMatchOfAll)
                                        ? 'in_progress'
                                        : 'waiting',
                                    refereeNames: [],

                                    // ★ 修正：すべて完璧な状態の「rule」から直接もらう！
                                    matchTimeMinutes: rule.matchTimeMinutes,
                                    isRunningTime: rule.isRunningTime,
                                    hasExtension:
                                        rule.enchoTimeMinutes > 0 ||
                                        rule.isEnchoUnlimited ||
                                        posName.contains('代表'),
                                    extensionTimeMinutes: rule.enchoTimeMinutes,
                                    extensionCount: rule.enchoCount,
                                    hasHantei: rule.hasHantei,

                                    order: baseOrder + (pIndex * 10) + i,
                                    note: saveNote,
                                    matchScene: rule.matchScene != 'honsen'
                                        ? rule.matchScene
                                        : (rule.isRenseikai
                                              ? 'renseikai'
                                              : 'honsen'),
                                    rule: rule, // ★ これだけで全てが封印されます
                                  );
                                  debugPrint(
                                    '📦 [1. 生成センサー] MatchId: $matchId, Ruleがnullか?: ${newMatch.rule == null}',
                                  ); // ★ デバッグ用センサー
                                  matchesToSave.add(newMatch);
                                }
                              }
                            }
                          });

                          if (matchesToSave.isNotEmpty) {
                            await ref
                                .read(matchApplicationServiceProvider)
                                .saveMatchesBulk(matchesToSave); // ★ 修正
                          }

                          if (!context.mounted) {
                            return;
                          }
                          Navigator.of(
                            context,
                            rootNavigator: true,
                          ).pop(); // ★ Phase 8-1: ローディングダイアログだけを確実に閉じる！

                          if (isStartNow) {
                            if (senpoMatchId.isNotEmpty) {
                              context.push('/match/$senpoMatchId');
                            } else {
                              context.go('/home/${widget.tournamentId}');
                            }
                          } else {
                            AppSnackBar.showSuccess(
                              context,
                              '試合をプールしました（待機リストに追加）',
                            );
                            context.go('/home/${widget.tournamentId}');
                          }
                        } catch (e) {
                          if (!context.mounted) {
                            return;
                          }
                          Navigator.of(context, rootNavigator: true).pop();
                          AppSnackBar.showError(context, '保存に失敗しました: $e');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _themeColors.primaryAccent,
                        foregroundColor: AppKendoColors.pureWhite,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.medium,
                        ),
                        elevation: 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.check_circle, size: 20),
                          SizedBox(width: AppSpacing.sm),
                          Text(
                            'このオーダーで確定して進む',
                            style: TextStyle(
                              fontSize: AppFontSize.subhead,
                              fontWeight: AppFontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
