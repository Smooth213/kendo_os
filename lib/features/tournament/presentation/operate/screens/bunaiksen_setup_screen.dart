import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart';
import '../providers/match_command_provider.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart'; // ★ 追加
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/widgets/smart_player_input.dart';
import 'package:kendo_os/shared/widgets/multi_player_select_input.dart'; // ★追加: 複数選択ウィジェット
import 'package:kendo_os/shared/widgets/liquid_background.dart';
import 'package:kendo_os/shared/widgets/glass_button.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/time/time_source.dart'; // ★ 追加
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/bunaiksen_custom_time_dialog.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bunaiksen_setup/bunaiksen_infinite_tab.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bunaiksen_setup/bunaiksen_league_tab.dart';

class BunaiksenSetupScreen extends ConsumerStatefulWidget {
  const BunaiksenSetupScreen({super.key});

  @override
  ConsumerState<BunaiksenSetupScreen> createState() =>
      _BunaiksenSetupScreenState();
}

class _BunaiksenSetupScreenState extends ConsumerState<BunaiksenSetupScreen>
    with SingleTickerProviderStateMixin {
  late AppThemeColors _themeColors;
  late TabController _tabController;
  final _redPlayerController = TextEditingController();
  final _whitePlayerController = TextEditingController();

  // 団体戦用ステート
  final _poolInputController = TextEditingController();
  int _teamSize = 5;
  final List<String> _poolPlayers = [];
  bool _isPoolFolded = false; // ★ 追加：プールを折りたたむ状態管理
  List<String?> _redTeam = List.filled(
    5,
    null,
    growable: true,
  ); // ★ 修正：長さを変更可能(growable)にする
  List<String?> _whiteTeam = List.filled(
    5,
    null,
    growable: true,
  ); // ★ 修正：長さを変更可能(growable)にする

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // ★ 追加: デフォルトのルール設定（2分、3本勝負、延長なし）に初期化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(bunaiksenRuleProvider.notifier)
          .update(
            (state) => state.copyWith(
              matchTimeMinutes: 2.0,
              isIpponShobu: false, // 3本勝負
              ipponLimit: 2, // ★ 追加: 試合エンジンに3本勝負(2本先取)を伝える
              isEnchoUnlimited: false,
              enchoTimeMinutes: 0.0,
              enchoCount: 0,
            ),
          );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _redPlayerController.dispose();
    _whitePlayerController.dispose();
    _poolInputController.dispose();
    super.dispose();
  }

  // ★ S字（蛇腹）学年順自動振り分けアルゴリズム
  void _autoAssignByGrade(List<PlayerModel> masterPlayers) {
    List<String> sorted = List.from(_poolPlayers);
    sorted.sort((a, b) {
      final ga =
          masterPlayers.where((p) => p.name == a).firstOrNull?.grade ?? 99;
      final gb =
          masterPlayers.where((p) => p.name == b).firstOrNull?.grade ?? 99;
      return ga.compareTo(gb);
    });

    setState(() => _isPoolFolded = true); // ★ 追加：自動振り分け時にプールを自動で閉じる

    List<String?> newRed = List.filled(
      _teamSize,
      null,
      growable: true,
    ); // ★ 修正：長さを変更可能(growable)にする
    List<String?> newWhite = List.filled(
      _teamSize,
      null,
      growable: true,
    ); // ★ 修正：長さを変更可能(growable)にする

    for (int i = 0; i < sorted.length && i < _teamSize * 2; i++) {
      int pairIndex = i ~/ 2; // 0=先鋒, 1=次鋒, 2=中堅...
      if (i % 4 == 0) {
        newRed[pairIndex] = sorted[i]; // 赤
      } else if (i % 4 == 1) {
        newWhite[pairIndex] = sorted[i]; // 白
      } else if (i % 4 == 2) {
        newWhite[pairIndex] = sorted[i]; // 白
      } else {
        newRed[pairIndex] = sorted[i]; // 赤
      }
    }

    setState(() {
      _redTeam = newRed;
      _whiteTeam = newWhite;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'bunaiksen');
    final rule = ref.watch(bunaiksenRuleProvider);
    final enableLiquidGlass = ref.watch(settingsProvider).enableLiquidGlass;
    final masterPlayers = ref.watch(bunaiksenPlayerMasterProvider).value ?? [];

    return LiquidBackground(
      child: Scaffold(
        backgroundColor: AppKendoColors.transparent,
        appBar: AppHeader(
          backgroundColor: enableLiquidGlass
              ? AppKendoColors.transparent
              : _themeColors.cardBackground,
          foregroundColor: _themeColors.textColor,
          title: '試合セットアップ',
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: TabBar(
            controller: _tabController,
            labelColor: _themeColors.primaryAccent,
            unselectedLabelColor: isDark
                ? AppKendoColors.grey
                : const Color(0x8A000000),
            indicatorColor: _themeColors.primaryAccent,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: AppFontWeight.bold),
            tabs: const [
              Tab(text: '個人'),
              Tab(text: '団体'),
              Tab(text: 'リーグ'),
              Tab(text: '無限'),
            ],
          ),
        ),
        body: Column(
          children: [
            // ルールアコーディオン
            ExpansionTile(
              title: Text(
                // ★ 修正: 小数点や1本勝負の表示に対応
                '⚙️ 試合ルール: ${rule.matchTimeMinutes == rule.matchTimeMinutes.toInt() ? rule.matchTimeMinutes.toInt() : rule.matchTimeMinutes.toStringAsFixed(1)}分 / ${(rule.isIpponShobu) ? '1' : '3'}本勝負 / 延長${(rule.enchoTimeMinutes > 0 || rule.isEnchoUnlimited) ? 'あり' : 'なし'}',
                style: TextStyle(
                  fontSize: AppFontSize.body,
                  fontWeight: AppFontWeight.bold,
                  color: context.appColors.subTextColor,
                ),
              ),
              backgroundColor: context.appColors.cardBackground,
              collapsedBackgroundColor: context.appColors.cardBackground,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.lg,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: _themeColors.primaryAccent,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              '💡 設定したルールは、試合を追加したあとでも「一括ルール変更」からいつでも変更できます。',
                              style: TextStyle(
                                fontSize: AppFontSize.caption,
                                color: isDark
                                    ? AppKendoColors.white60
                                    : const Color(
                                        0xFF000000,
                                      ).withValues(alpha: 0.54),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '試合時間',
                            style: TextStyle(fontWeight: AppFontWeight.bold),
                          ),
                          DropdownButton<double?>(
                            value:
                                [
                                  1.0,
                                  1.5,
                                  2.0,
                                  2.5,
                                  3.0,
                                ].contains(rule.matchTimeMinutes)
                                ? rule.matchTimeMinutes
                                : null,
                            items: [
                              const DropdownMenuItem(
                                value: 1.0,
                                child: Text('1分00秒'),
                              ),
                              const DropdownMenuItem(
                                value: 1.5,
                                child: Text('1分30秒'),
                              ),
                              const DropdownMenuItem(
                                value: 2.0,
                                child: Text('2分00秒'),
                              ),
                              const DropdownMenuItem(
                                value: 2.5,
                                child: Text('2分30秒'),
                              ),
                              const DropdownMenuItem(
                                value: 3.0,
                                child: Text('3分00秒'),
                              ),
                              DropdownMenuItem(
                                value: null,
                                child: Text(
                                  '任意 (${rule.matchTimeMinutes.toInt()}分${((rule.matchTimeMinutes % 1) * 60).toInt()}秒)',
                                ),
                              ),
                            ],
                            onChanged: (v) async {
                              if (v != null) {
                                ref
                                    .read(bunaiksenRuleProvider.notifier)
                                    .update(
                                      (state) =>
                                          state.copyWith(matchTimeMinutes: v),
                                    );
                              } else {
                                // ★ 任意時間が選ばれたらダイアログを表示
                                final customTime =
                                    await BunaiksenCustomTimeDialog.show(
                                      context,
                                      currentTime: rule.matchTimeMinutes,
                                      isDark: isDark,
                                      primaryAccent: _themeColors.primaryAccent,
                                      subTextColor: _themeColors.subTextColor,
                                      hintColor: _themeColors.hintColor,
                                      inputBackground:
                                          _themeColors.inputBackground,
                                      separatorColor:
                                          _themeColors.separatorColor,
                                    );
                                if (customTime != null && customTime > 0) {
                                  ref
                                      .read(bunaiksenRuleProvider.notifier)
                                      .update(
                                        (state) => state.copyWith(
                                          matchTimeMinutes: customTime,
                                        ),
                                      );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                      const Divider(),
                      // ★ 追加: 1本勝負 / 3本勝負の選択
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '勝敗条件',
                            style: TextStyle(fontWeight: AppFontWeight.bold),
                          ),
                          DropdownButton<bool>(
                            value: rule.isIpponShobu,
                            items: const [
                              DropdownMenuItem(
                                value: false,
                                child: Text('3本勝負'),
                              ),
                              DropdownMenuItem(
                                value: true,
                                child: Text('1本勝負'),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                ref
                                    .read(bunaiksenRuleProvider.notifier)
                                    .update(
                                      (state) => state.copyWith(
                                        isIpponShobu: v,
                                        ipponLimit: v
                                            ? 1
                                            : 2, // ★ 追加: エンジンに1本勝負(1本)か3本勝負(2本)かを伝える
                                      ),
                                    );
                              }
                            },
                          ),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '延長戦',
                            style: TextStyle(fontWeight: AppFontWeight.bold),
                          ),
                          DropdownButton<String>(
                            value: rule.isEnchoUnlimited
                                ? 'unlimited'
                                : (rule.enchoTimeMinutes > 0
                                      ? 'limited'
                                      : 'none'),
                            items: const [
                              DropdownMenuItem(
                                value: 'none',
                                child: Text('なし'),
                              ),
                              DropdownMenuItem(
                                value: 'limited',
                                child: Text('区切りあり'),
                              ),
                              DropdownMenuItem(
                                value: 'unlimited',
                                child: Text('無制限'),
                              ),
                            ],
                            onChanged: (v) {
                              if (v == 'none') {
                                ref
                                    .read(bunaiksenRuleProvider.notifier)
                                    .update(
                                      (state) => state.copyWith(
                                        isEnchoUnlimited: false,
                                        enchoTimeMinutes: 0.0,
                                        enchoCount: 0,
                                      ),
                                    );
                              } else if (v == 'limited') {
                                ref
                                    .read(bunaiksenRuleProvider.notifier)
                                    .update(
                                      (state) => state.copyWith(
                                        isEnchoUnlimited: false,
                                        enchoTimeMinutes:
                                            state.matchTimeMinutes,
                                        enchoCount: 1,
                                      ),
                                    );
                              } else if (v == 'unlimited') {
                                ref
                                    .read(bunaiksenRuleProvider.notifier)
                                    .update(
                                      (state) => state.copyWith(
                                        isEnchoUnlimited: true,
                                        enchoTimeMinutes: 0.0,
                                        enchoCount: 0,
                                      ),
                                    );
                              }
                            },
                          ),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '判定',
                            style: TextStyle(fontWeight: AppFontWeight.bold),
                          ),
                          Switch(
                            value: rule.hasHantei,
                            activeTrackColor: _themeColors.primaryAccent
                                .withValues(alpha: 0.5),
                            activeThumbColor: _themeColors.primaryAccent,
                            onChanged: (v) => ref
                                .read(bunaiksenRuleProvider.notifier)
                                .update(
                                  (state) => state.copyWith(hasHantei: v),
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildIndividualTab(context, ref),
                  _buildTeamTab(context, ref, masterPlayers, isDark),
                  BunaiksenLeagueTab(themeColors: _themeColors),
                  BunaiksenInfiniteTab(themeColors: _themeColors),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔴 タブ1：個人戦（即スタート）
  Widget _buildIndividualTab(BuildContext context, WidgetRef ref) {
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
                  controller: _redPlayerController,
                  label: '赤の選手',
                  accentColor: _themeColors.primaryAccent,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  'VS',
                  style: TextStyle(
                    fontSize: AppFontSize.display,
                    fontWeight: AppFontWeight.bold,
                    color: const Color(0x8A000000),
                  ),
                ),
              ),
              Expanded(
                child: SmartPlayerInput(
                  controller: _whitePlayerController,
                  label: '白選手',
                  accentColor: Theme.of(context).brightness == Brightness.dark
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
              color: _themeColors.primaryAccent,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              expandContent: false,
              onPressed: () async {
                final redName = _redPlayerController.text.trim();
                final whiteName = _whitePlayerController.text.trim();

                if (redName.isEmpty || whiteName.isEmpty) {
                  AppSnackBar.showError(context, '両選手の名前を入力してください');
                  return;
                }

                final rule = ref.read(bunaiksenRuleProvider);
                final matchId = const Uuid().v4();
                final now = ref.read(timeSourceProvider).now();
                final dateStr = DateFormat('yyyyMMdd').format(
                  DateTime.now(),
                ); // 🍏 タイムゾーン修正：常に日本時間(JST)を基準に今日の日付文字列を生成する
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

  // オーダー表での使用回数をカウント（重複バッジ用）
  int _getUsageCount(String name) {
    return _redTeam.where((n) => n == name).length +
        _whiteTeam.where((n) => n == name).length;
  }

  // ★ 追加：ベンチの選手を美しく表示する専用のヘルパー
  Widget _buildPlayerChip(
    String name, {
    bool isFeedback = false,
    bool isAssigned = false,
    required bool isDark,
  }) {
    final count = _getUsageCount(name);
    return AppActionChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: TextStyle(
              color: isAssigned
                  ? (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))
                  : (context.appColors.textColor),
              fontWeight: AppFontWeight.bold,
            ),
          ),
          if (count > 0 && !isFeedback) ...[
            const SizedBox(width: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: const BoxDecoration(
                color: AppKendoColors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: AppKendoColors.pureWhite,
                  fontSize: AppFontSize.badge,
                  fontWeight: AppFontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      backgroundColor: isFeedback
          ? _themeColors.primaryAccent.withValues(alpha: 0.2)
          : (isAssigned
                ? (context.appColors.separatorColor)
                : (isDark
                      ? const Color(0xFFFFFFFF)
                      : context.appColors.textColor)),
      side: BorderSide(
        color: isAssigned
            ? AppKendoColors.transparent
            : _themeColors.primaryAccent.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildTeamTab(
    BuildContext context,
    WidgetRef ref,
    List<PlayerModel> masterPlayers,
    bool isDark,
  ) {
    final positions = ['先鋒', '次鋒', '五将', '中堅', '三将', '副将', '大将'];
    List<String> getPositions(int size) {
      if (size == 3) return ['先鋒', '中堅', '大将'];
      if (size == 5) return ['先鋒', '次鋒', '中堅', '副将', '大将'];
      if (size == 7) return positions;
      return List.generate(size, (i) => '${i + 1}番手');
    }

    final currentPositions = getPositions(_teamSize);

    return Padding(
      // ★ 修正1：上部の余白(Top)を 0 にして上に詰める
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0.0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        children: [
          // ★ 参加者プールヘッダー（折りたたみトグル付き）
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '参加者プール (${_poolPlayers.length}名)',
                  style: const TextStyle(
                    fontWeight: AppFontWeight.bold,
                    fontSize: AppFontSize.bodySmall,
                    color: AppKendoColors.grey,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isPoolFolded ? Icons.expand_more : Icons.expand_less,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _isPoolFolded = !_isPoolFolded),
                ),
              ],
            ),
          ),

          if (!_isPoolFolded) ...[
            MultiPlayerSelectInput(
              initialSelected: _poolPlayers,
              label: '団体戦メンバーを選択（複数可）',
              onConfirm: (selectedList) {
                setState(() {
                  _poolPlayers.clear();
                  _poolPlayers.addAll(selectedList);
                });
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // ★ ベンチ（横スクロール）エリア
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _poolPlayers.length,
              itemBuilder: (context, index) {
                final name = _poolPlayers[index];
                final isAssigned =
                    _redTeam.contains(name) || _whiteTeam.contains(name);

                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: Draggable<String>(
                    data: name,
                    // ★ 修正2：縦に引っ張った時だけドラッグを開始する。これで横スクロールが完璧に動く！
                    affinity: Axis.vertical,
                    feedback: Material(
                      color: AppKendoColors.transparent,
                      child: _buildPlayerChip(
                        name,
                        isFeedback: true,
                        isDark: isDark,
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.3,
                      child: _buildPlayerChip(name, isDark: isDark),
                    ),
                    child: _buildPlayerChip(
                      name,
                      isAssigned: isAssigned,
                      isDark: isDark,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // コントロールエリア（枠数変更・S字振り分け）
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () {
                      if (_teamSize > 1) {
                        setState(() {
                          _teamSize--;
                          _redTeam.removeLast();
                          _whiteTeam.removeLast();
                        });
                      }
                    },
                  ),
                  Text(
                    '$_teamSize 対 $_teamSize',
                    style: const TextStyle(
                      fontWeight: AppFontWeight.bold,
                      fontSize: AppFontSize.subhead,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () {
                      setState(() {
                        _teamSize++;
                        _redTeam.add(null);
                        _whiteTeam.add(null);
                      });
                    },
                  ),
                ],
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.auto_awesome),
                label: const Text('学年順 自動振り分け'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppKendoColors.ipponGold,
                  foregroundColor: AppKendoColors.pureBlack,
                ),
                onPressed: () => _autoAssignByGrade(masterPlayers),
              ),
            ],
          ),
          const Divider(height: 16),

          // オーダー表 (ドラッグ＆ドロップ対象)
          Expanded(
            child: Row(
              children: [
                // 赤チーム列
                Expanded(
                  child: ListView.builder(
                    itemCount: _teamSize,
                    itemBuilder: (context, index) {
                      return DragTarget<String>(
                        onAcceptWithDetails: (details) =>
                            setState(() => _redTeam[index] = details.data),
                        builder: (context, candidateData, rejectedData) {
                          return Card(
                            color: candidateData.isNotEmpty
                                ? AppKendoColors.hansokuRed.withValues(
                                    alpha: 0.2,
                                  )
                                : (isDark
                                      ? const Color(0xFF2C1C1E)
                                      : const Color(0xFFFFF5F5)),
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                color: AppKendoColors.hansokuRed,
                                width: candidateData.isNotEmpty ? 2 : 1,
                              ),
                              borderRadius: AppRadius.large,
                            ),
                            child: ListTile(
                              dense: true, // 少しコンパクトに
                              leading: CircleAvatar(
                                backgroundColor: AppKendoColors.hansokuRed,
                                radius: 14,
                                child: Text(
                                  currentPositions[index].substring(0, 1),
                                  style: const TextStyle(
                                    color: AppKendoColors.pureWhite,
                                    fontSize: AppFontSize.badge,
                                    fontWeight: AppFontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                _redTeam[index] ?? '未定',
                                style: TextStyle(
                                  fontWeight: AppFontWeight.bold,
                                  color: _redTeam[index] == null
                                      ? (isDark
                                            ? const Color(0xFF94A3B8)
                                            : const Color(0xFF64748B))
                                      : (context.appColors.textColor),
                                ),
                              ),
                              onTap: () =>
                                  setState(() => _redTeam[index] = null),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // 白チーム列
                Expanded(
                  child: ListView.builder(
                    itemCount: _teamSize,
                    itemBuilder: (context, index) {
                      return DragTarget<String>(
                        onAcceptWithDetails: (details) =>
                            setState(() => _whiteTeam[index] = details.data),
                        builder: (context, candidateData, rejectedData) {
                          return Card(
                            color: candidateData.isNotEmpty
                                ? const Color(0xFF607D8B).withValues(alpha: 0.2)
                                : (isDark
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFFF8FAFC)),
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                color: const Color(0xFF607D8B),
                                width: candidateData.isNotEmpty ? 2 : 1,
                              ),
                              borderRadius: AppRadius.large,
                            ),
                            child: ListTile(
                              dense: true, // 少しコンパクトに
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF607D8B),
                                radius: 14,
                                child: Text(
                                  currentPositions[index].substring(0, 1),
                                  style: const TextStyle(
                                    color: AppKendoColors.pureWhite,
                                    fontSize: AppFontSize.badge,
                                    fontWeight: AppFontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                _whiteTeam[index] ?? '未定',
                                style: TextStyle(
                                  fontWeight: AppFontWeight.bold,
                                  color: _whiteTeam[index] == null
                                      ? (isDark
                                            ? const Color(0xFF94A3B8)
                                            : const Color(0xFF64748B))
                                      : (context.appColors.textColor),
                                ),
                              ),
                              onTap: () =>
                                  setState(() => _whiteTeam[index] = null),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // 確定ボタン
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: GlassButton(
              icon: Icons.check_circle,
              label: '確定して対戦表を作成',
              color: _themeColors.primaryAccent,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              expandContent: false,
              onPressed: () async {
                final rule = ref.read(bunaiksenRuleProvider);
                final now = ref.read(timeSourceProvider).now();
                final dateStr = DateFormat('yyyyMMdd').format(
                  DateTime.now(),
                ); // 🍏 タイムゾーン修正：常に日本時間(JST)を基準に今日の日付文字列を生成する
                final todayId = 'bunaiksen_$dateStr';
                final groupId = const Uuid().v4();
                final baseOrder = now.millisecondsSinceEpoch.toDouble();

                List<MatchModel> matchesToSave = [];
                for (int i = 0; i < _teamSize; i++) {
                  final matchId = const Uuid().v4();
                  matchesToSave.add(
                    MatchModel(
                      id: matchId,
                      tournamentId: todayId,
                      groupName: groupId,
                      matchType: currentPositions[i],
                      redName: _redTeam[i] ?? '未定',
                      whiteName: _whiteTeam[i] ?? '未定',
                      matchTimeMinutes: rule.matchTimeMinutes,
                      hasExtension:
                          rule.enchoTimeMinutes > 0 || rule.isEnchoUnlimited,
                      extensionTimeMinutes: rule.enchoTimeMinutes,
                      status: 'waiting',
                      order: baseOrder + i,
                      rule: rule,
                      note: '部内・団体戦',
                    ),
                  );
                }

                await ref
                    .read(matchApplicationServiceProvider)
                    .saveMatchesBulk(matchesToSave); // ★ 修正
                if (context.mounted) context.pop();
              },
            ),
          ),
        ],
      ),
    );
  }
}
