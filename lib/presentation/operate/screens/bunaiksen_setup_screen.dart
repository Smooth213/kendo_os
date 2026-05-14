import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import 'package:kendo_os/domain/entities/match_model.dart';
import '../providers/bunaiksen_provider.dart';
import '../providers/match_command_provider.dart';
import 'package:kendo_os/application/usecases/match_application_service.dart'; // ★ 追加
import 'package:kendo_os/domain/entities/player_model.dart';
import '../../shared/widgets/smart_player_input.dart';
import '../../shared/widgets/multi_player_select_input.dart'; // ★追加: 複数選択ウィジェット

class BunaiksenSetupScreen extends ConsumerStatefulWidget {
  const BunaiksenSetupScreen({super.key});

  @override
  ConsumerState<BunaiksenSetupScreen> createState() => _BunaiksenSetupScreenState();
}

class _BunaiksenSetupScreenState extends ConsumerState<BunaiksenSetupScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _redPlayerController = TextEditingController();
  final _whitePlayerController = TextEditingController();

  // 団体戦用ステート
  final _poolInputController = TextEditingController();
  int _teamSize = 5;
  final List<String> _poolPlayers = [];
  bool _isPoolFolded = false; // ★ 追加：プールを折りたたむ状態管理
  List<String?> _redTeam = List.filled(5, null, growable: true); // ★ 修正：長さを変更可能(growable)にする
  List<String?> _whiteTeam = List.filled(5, null, growable: true); // ★ 修正：長さを変更可能(growable)にする

  // リーグ戦用ステート
  final _leagueInputController = TextEditingController();
  final List<String> _leagueParticipants = [];

  // 無限勝ち抜き用ステート
  final _infiniteInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // ★ 追加: デフォルトのルール設定（2分、3本勝負、延長なし）に初期化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bunaiksenRuleProvider.notifier).update((state) => state.copyWith(
        matchTimeMinutes: 2.0,
        isIpponShobu: false, // 3本勝負
        ipponLimit: 2, // ★ 追加: 試合エンジンに3本勝負(2本先取)を伝える
        isEnchoUnlimited: false,
        enchoTimeMinutes: 0.0,
        enchoCount: 0,
      ));
    });
  }

  // ★ 追加: 任意の試合時間を入力するダイアログ
  Future<double?> _showCustomTimeDialog(double currentTime) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final minController = TextEditingController(text: currentTime.toInt().toString());
    final secController = TextEditingController(text: ((currentTime % 1) * 60).toInt().toString());

    return showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        title: const Text('任意の試合時間', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Row(
          children: [
            Expanded(
              child: TextField(
                controller: minController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '分', border: OutlineInputBorder()),
              ),
            ),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 16.0), child: Text(':', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
            Expanded(
              child: TextField(
                controller: secController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '秒', border: OutlineInputBorder()),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('キャンセル', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B0000), foregroundColor: Colors.white),
            onPressed: () {
              final m = int.tryParse(minController.text) ?? 0;
              final s = int.tryParse(secController.text) ?? 0;
              final total = m + (s / 60.0);
              Navigator.pop(ctx, total);
            },
            child: const Text('設定する', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _redPlayerController.dispose();
    _whitePlayerController.dispose();
    _poolInputController.dispose();
    _leagueInputController.dispose();
    _infiniteInputController.dispose();
    super.dispose();
  }

  // ★ S字（蛇腹）学年順自動振り分けアルゴリズム
  void _autoAssignByGrade(List<PlayerModel> masterPlayers) {
    List<String> sorted = List.from(_poolPlayers);
    sorted.sort((a, b) {
      final ga = masterPlayers.where((p) => p.name == a).firstOrNull?.grade ?? 99;
      final gb = masterPlayers.where((p) => p.name == b).firstOrNull?.grade ?? 99;
      return ga.compareTo(gb);
    });

    setState(() => _isPoolFolded = true); // ★ 追加：自動振り分け時にプールを自動で閉じる

    List<String?> newRed = List.filled(_teamSize, null, growable: true); // ★ 修正：長さを変更可能(growable)にする
    List<String?> newWhite = List.filled(_teamSize, null, growable: true); // ★ 修正：長さを変更可能(growable)にする

    for (int i = 0; i < sorted.length && i < _teamSize * 2; i++) {
      int pairIndex = i ~/ 2; // 0=先鋒, 1=次鋒, 2=中堅...
      if (i % 4 == 0) {
        newRed[pairIndex] = sorted[i];     // 赤
      } else if (i % 4 == 1) {
        newWhite[pairIndex] = sorted[i];   // 白
      } else if (i % 4 == 2) {
        newWhite[pairIndex] = sorted[i];   // 白
      } else {
        newRed[pairIndex] = sorted[i];     // 赤
      }
    }

    setState(() {
      _redTeam = newRed;
      _whiteTeam = newWhite;
    });
  }

  @override
  Widget build(BuildContext context) {
    final rule = ref.watch(bunaiksenRuleProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final masterPlayers = ref.watch(bunaiksenPlayerMasterProvider).value ?? [];

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white, // ★ 修正：白背景
        foregroundColor: isDark ? Colors.white : const Color(0xFF8B0000), // ★ 修正：ボルドー文字
        title: const Text('試合セットアップ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF8B0000), // ★ 修正
          unselectedLabelColor: isDark ? Colors.grey : Colors.grey.shade600,
          indicatorColor: const Color(0xFF8B0000), // ★ 修正
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
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
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87),
            ),
            backgroundColor: isDark ? Colors.grey.shade800.withAlpha(128) : Colors.grey.shade100,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('試合時間', style: TextStyle(fontWeight: FontWeight.bold)),
                        DropdownButton<double?>(
                          value: [1.0, 1.5, 2.0, 2.5, 3.0].contains(rule.matchTimeMinutes) ? rule.matchTimeMinutes : null,
                          items: [
                            const DropdownMenuItem(value: 1.0, child: Text('1分00秒')),
                            const DropdownMenuItem(value: 1.5, child: Text('1分30秒')),
                            const DropdownMenuItem(value: 2.0, child: Text('2分00秒')),
                            const DropdownMenuItem(value: 2.5, child: Text('2分30秒')),
                            const DropdownMenuItem(value: 3.0, child: Text('3分00秒')),
                            DropdownMenuItem(value: null, child: Text('任意 (${rule.matchTimeMinutes.toInt()}分${((rule.matchTimeMinutes % 1) * 60).toInt()}秒)')),
                          ],
                          onChanged: (v) async {
                            if (v != null) {
                              ref.read(bunaiksenRuleProvider.notifier).update((state) => state.copyWith(matchTimeMinutes: v));
                            } else {
                              // ★ 任意時間が選ばれたらダイアログを表示
                              final customTime = await _showCustomTimeDialog(rule.matchTimeMinutes);
                              if (customTime != null && customTime > 0) {
                                ref.read(bunaiksenRuleProvider.notifier).update((state) => state.copyWith(matchTimeMinutes: customTime));
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
                        const Text('勝敗条件', style: TextStyle(fontWeight: FontWeight.bold)),
                        DropdownButton<bool>(
                          value: rule.isIpponShobu,
                          items: const [
                            DropdownMenuItem(value: false, child: Text('3本勝負')),
                            DropdownMenuItem(value: true, child: Text('1本勝負')),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              ref.read(bunaiksenRuleProvider.notifier).update((state) => state.copyWith(
                                isIpponShobu: v,
                                ipponLimit: v ? 1 : 2, // ★ 追加: エンジンに1本勝負(1本)か3本勝負(2本)かを伝える
                              ));
                            }
                          },
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('延長戦', style: TextStyle(fontWeight: FontWeight.bold)),
                        DropdownButton<String>(
                          value: rule.isEnchoUnlimited ? 'unlimited' : (rule.enchoTimeMinutes > 0 ? 'limited' : 'none'),
                          items: const [
                            DropdownMenuItem(value: 'none', child: Text('なし')),
                            DropdownMenuItem(value: 'limited', child: Text('区切りあり')),
                            DropdownMenuItem(value: 'unlimited', child: Text('無制限')),
                          ],
                          onChanged: (v) {
                            if (v == 'none') {
                              ref.read(bunaiksenRuleProvider.notifier).update((state) => state.copyWith(isEnchoUnlimited: false, enchoTimeMinutes: 0.0, enchoCount: 0));
                            } else if (v == 'limited') {
                              ref.read(bunaiksenRuleProvider.notifier).update((state) => state.copyWith(isEnchoUnlimited: false, enchoTimeMinutes: state.matchTimeMinutes, enchoCount: 1));
                            } else if (v == 'unlimited') {
                              ref.read(bunaiksenRuleProvider.notifier).update((state) => state.copyWith(isEnchoUnlimited: true, enchoTimeMinutes: 0.0, enchoCount: 0));
                            }
                          },
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('判定', style: TextStyle(fontWeight: FontWeight.bold)),
                        Switch(
                          value: rule.hasHantei,
                          activeTrackColor: const Color(0xFF8B0000).withValues(alpha: 0.5),
                          activeThumbColor: const Color(0xFF8B0000),
                          onChanged: (v) => ref.read(bunaiksenRuleProvider.notifier).update((state) => state.copyWith(hasHantei: v)),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildIndividualTab(context, ref),
                _buildTeamTab(context, ref, masterPlayers, isDark),
                _buildLeagueTab(context, ref),
                _buildInfiniteTab(context, ref),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔴 タブ1：個人戦（即スタート）
  Widget _buildIndividualTab(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 24.0),
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
                  accentColor: const Color(0xFF8B0000), // ★ 修正：洗練されたボルドー（深紅）に変更
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('VS', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
              ),
              Expanded(
                child: SmartPlayerInput(
                  controller: _whitePlayerController,
                  label: '白選手',
                  accentColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade300 : Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.flash_on),
              label: const Text('▶ 試合開始', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B0000), // ★ 修正
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final redName = _redPlayerController.text.trim();
                final whiteName = _whitePlayerController.text.trim();

                if (redName.isEmpty || whiteName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('両選手の名前を入力してください')));
                  return;
                }

                final rule = ref.read(bunaiksenRuleProvider);
                final matchId = const Uuid().v4();
                final todayId = 'bunaiksen_${DateFormat('yyyyMMdd').format(DateTime.now())}';

                final newMatch = MatchModel(
                  id: matchId,
                  tournamentId: todayId,
                  groupName: const Uuid().v4(),
                  matchType: '個人戦',
                  redName: redName,
                  whiteName: whiteName,
                  matchTimeMinutes: rule.matchTimeMinutes.toInt(),
                  hasExtension: rule.enchoTimeMinutes > 0 || rule.isEnchoUnlimited,
                  extensionTimeMinutes: rule.enchoTimeMinutes.toInt(),
                  status: 'in_progress',
                  order: DateTime.now().millisecondsSinceEpoch.toDouble(),
                  rule: rule,
                  note: '部内戦',
                );

                await ref.read(matchCommandProvider).addMatch(newMatch);
                if (context.mounted) context.push('/match/$matchId');
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // オーダー表での使用回数をカウント（重複バッジ用）
  int _getUsageCount(String name) {
    return _redTeam.where((n) => n == name).length + _whiteTeam.where((n) => n == name).length;
  }

  // ★ 追加：ベンチの選手を美しく表示する専用のヘルパー
  Widget _buildPlayerChip(String name, {bool isFeedback = false, bool isAssigned = false, required bool isDark}) {
    final count = _getUsageCount(name);
    return Chip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(name, style: TextStyle(color: isAssigned ? Colors.grey : (isDark ? Colors.white : Colors.black87), fontWeight: FontWeight.bold)),
          if (count > 0 && !isFeedback) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            )
          ]
        ],
      ),
      backgroundColor: isFeedback 
          ? const Color(0xFF8B0000).withValues(alpha: 0.2) 
          : (isAssigned ? (isDark ? Colors.grey.shade800 : Colors.grey.shade200) : (isDark ? Colors.grey.shade700 : Colors.white)),
      side: BorderSide(color: isAssigned ? Colors.transparent : const Color(0xFF8B0000).withValues(alpha: 0.5)),
    );
  }

  Widget _buildTeamTab(BuildContext context, WidgetRef ref, List<PlayerModel> masterPlayers, bool isDark) {
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
      padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      child: Column(
        children: [
          // ★ 参加者プールヘッダー（折りたたみトグル付き）
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('参加者プール (${_poolPlayers.length}名)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                IconButton(
                  icon: Icon(_isPoolFolded ? Icons.expand_more : Icons.expand_less, size: 20),
                  onPressed: () => setState(() => _isPoolFolded = !_isPoolFolded),
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
            const SizedBox(height: 12),
          ],

          // ★ ベンチ（横スクロール）エリア
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _poolPlayers.length,
              itemBuilder: (context, index) {
                final name = _poolPlayers[index];
                final isAssigned = _redTeam.contains(name) || _whiteTeam.contains(name);
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Draggable<String>(
                    data: name,
                    // ★ 修正2：縦に引っ張った時だけドラッグを開始する。これで横スクロールが完璧に動く！
                    affinity: Axis.vertical, 
                    feedback: Material(
                      color: Colors.transparent,
                      child: _buildPlayerChip(name, isFeedback: true, isDark: isDark),
                    ),
                    childWhenDragging: Opacity(opacity: 0.3, child: _buildPlayerChip(name, isDark: isDark)),
                    child: _buildPlayerChip(name, isAssigned: isAssigned, isDark: isDark),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8), 
          
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
                  Text('$_teamSize 対 $_teamSize', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade700, foregroundColor: Colors.black),
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
                        onAcceptWithDetails: (details) => setState(() => _redTeam[index] = details.data),
                        builder: (context, candidateData, rejectedData) {
                          return Card(
                            color: candidateData.isNotEmpty ? Colors.red.shade100 : (isDark ? Colors.grey.shade900 : Colors.white),
                            shape: RoundedRectangleBorder(
                              side: BorderSide(color: Colors.red.shade300, width: candidateData.isNotEmpty ? 2 : 1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListTile(
                              dense: true, // 少しコンパクトに
                              leading: CircleAvatar(backgroundColor: Colors.red.shade100, radius: 14, child: Text(currentPositions[index].substring(0, 1), style: TextStyle(color: Colors.red.shade800, fontSize: 10, fontWeight: FontWeight.bold))),
                              title: Text(_redTeam[index] ?? '未定', style: TextStyle(fontWeight: FontWeight.bold, color: _redTeam[index] == null ? Colors.grey : (isDark ? Colors.white : Colors.black))),
                              onTap: () => setState(() => _redTeam[index] = null), 
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // 白チーム列
                Expanded(
                  child: ListView.builder(
                    itemCount: _teamSize,
                    itemBuilder: (context, index) {
                      return DragTarget<String>(
                        onAcceptWithDetails: (details) => setState(() => _whiteTeam[index] = details.data),
                        builder: (context, candidateData, rejectedData) {
                          return Card(
                            color: candidateData.isNotEmpty ? Colors.blueGrey.shade100 : (isDark ? Colors.grey.shade900 : Colors.white),
                            shape: RoundedRectangleBorder(
                              side: BorderSide(color: Colors.blueGrey.shade300, width: candidateData.isNotEmpty ? 2 : 1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListTile(
                              dense: true, // 少しコンパクトに
                              leading: CircleAvatar(backgroundColor: Colors.blueGrey.shade100, radius: 14, child: Text(currentPositions[index].substring(0, 1), style: TextStyle(color: Colors.blueGrey.shade800, fontSize: 10, fontWeight: FontWeight.bold))),
                              title: Text(_whiteTeam[index] ?? '未定', style: TextStyle(fontWeight: FontWeight.bold, color: _whiteTeam[index] == null ? Colors.grey : (isDark ? Colors.white : Colors.black))),
                              onTap: () => setState(() => _whiteTeam[index] = null), 
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
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check_circle),
              label: const Text('確定して対戦表を作成', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B0000), // ★ 修正
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () async {
                final rule = ref.read(bunaiksenRuleProvider);
                final todayId = 'bunaiksen_${DateFormat('yyyyMMdd').format(DateTime.now())}';
                final groupId = const Uuid().v4();
                final baseOrder = DateTime.now().millisecondsSinceEpoch.toDouble();

                List<MatchModel> matchesToSave = [];
                for (int i = 0; i < _teamSize; i++) {
                  final matchId = const Uuid().v4();
                  matchesToSave.add(MatchModel(
                    id: matchId,
                    tournamentId: todayId,
                    groupName: groupId,
                    matchType: currentPositions[i],
                    redName: _redTeam[i] ?? '未定',
                    whiteName: _whiteTeam[i] ?? '未定',
                    matchTimeMinutes: rule.matchTimeMinutes.toInt(),
                    hasExtension: rule.enchoTimeMinutes > 0 || rule.isEnchoUnlimited,
                    extensionTimeMinutes: rule.enchoTimeMinutes.toInt(),
                    status: 'waiting', 
                    order: baseOrder + i,
                    rule: rule,
                    note: '部内・団体戦',
                  ));
                }

                await ref.read(matchApplicationServiceProvider).saveMatchesBulk(matchesToSave); // ★ 修正
                if (context.mounted) context.pop();
              },
            ),
          ),
        ],
      ),
    );
  }

  // リーグ戦タブのプレースホルダー
  Widget _buildLeagueTab(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
      child: Column(
        children: [
          // ★ 修正：リーグ戦も一気に複数選択できるように置き換え
          MultiPlayerSelectInput(
            initialSelected: _leagueParticipants,
            label: 'リーグ戦メンバーを選択（複数可）',
            onConfirm: (selectedList) {
              setState(() {
                _leagueParticipants.clear();
                _leagueParticipants.addAll(selectedList);
              });
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
              ),
              child: _leagueParticipants.isEmpty
                  ? Center(child: Text('選手を追加してください', style: TextStyle(color: Colors.grey.shade500)))
                  : ReorderableListView.builder(
                      itemCount: _leagueParticipants.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (oldIndex < newIndex) newIndex -= 1;
                          final item = _leagueParticipants.removeAt(oldIndex);
                          _leagueParticipants.insert(newIndex, item);
                        });
                      },
                      itemBuilder: (context, index) {
                        final p = _leagueParticipants[index];
                        return ListTile(
                          key: ValueKey(p),
                          leading: CircleAvatar(backgroundColor: const Color(0xFF8B0000).withValues(alpha: 0.2), child: Text('${index + 1}', style: const TextStyle(color: Color(0xFF8B0000), fontSize: 12, fontWeight: FontWeight.bold))),
                          title: Text(p),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey),
                            onPressed: () => setState(() => _leagueParticipants.remove(p)),
                          ),
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.grid_on),
              label: Text('総当たり対戦表を作成（${_leagueParticipants.length}人）', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B0000), // ★ 修正
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _leagueParticipants.length < 2 ? null : () async {
                final rule = ref.read(bunaiksenRuleProvider);
                final todayId = 'bunaiksen_${DateFormat('yyyyMMdd').format(DateTime.now())}';
                final groupId = const Uuid().v4();
                final baseOrder = DateTime.now().millisecondsSinceEpoch.toDouble();

                List<MatchModel> matchesToSave = [];
                int matchCount = 0;
                for (int i = 0; i < _leagueParticipants.length; i++) {
                  for (int j = i + 1; j < _leagueParticipants.length; j++) {
                    final matchId = const Uuid().v4();
                    matchesToSave.add(MatchModel(
                      id: matchId,
                      tournamentId: todayId,
                      groupName: groupId,
                      matchType: 'リーグ戦',
                      redName: _leagueParticipants[i],
                      whiteName: _leagueParticipants[j],
                      matchTimeMinutes: rule.matchTimeMinutes.toInt(),
                      hasExtension: rule.enchoTimeMinutes > 0 || rule.isEnchoUnlimited,
                      extensionTimeMinutes: rule.enchoTimeMinutes.toInt(),
                      status: 'waiting',
                      order: baseOrder + matchCount,
                      rule: rule.copyWith(isLeague: true, winPoint: 3, drawPoint: 1, lossPoint: 0), // ★ 修正：リーグ戦として認識させるためのフラグを付与
                      note: '[リーグ戦] 部内戦',
                    ));
                    matchCount++;
                  }
                }

                await ref.read(matchApplicationServiceProvider).saveMatchesBulk(matchesToSave); // ★ 修正
                if (context.mounted) context.pop();
              },
            ),
          ),
        ],
      ),
    );
  }

  // 無限勝ち抜きタブのプレースホルダー
  Widget _buildInfiniteTab(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(bunaiksenInfiniteQueueProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
      child: Column(
        children: [
          // ★ 修正：1人ずつの追加と「＋」ボタンを廃止し、ボトムシートから複数選択できるように変更
          MultiPlayerSelectInput(
            initialSelected: queue,
            label: '待機列のメンバーを選択（複数可）',
            onConfirm: (selectedList) {
              ref.read(bunaiksenInfiniteQueueProvider.notifier).setPlayers(selectedList);
            },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('待機列 (${queue.length}人)', style: const TextStyle(fontWeight: FontWeight.bold)),
              TextButton.icon(
                icon: const Icon(Icons.shuffle),
                label: const Text('シャッフル'),
                onPressed: () => ref.read(bunaiksenInfiniteQueueProvider.notifier).shuffle(),
              )
            ],
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
              ),
              child: queue.isEmpty
                  ? Center(child: Text('選手を追加してください', style: TextStyle(color: Colors.grey.shade500)))
                  : ReorderableListView.builder(
                      itemCount: queue.length,
                      onReorder: (oldIndex, newIndex) {
                        ref.read(bunaiksenInfiniteQueueProvider.notifier).reorder(oldIndex, newIndex);
                      },
                      itemBuilder: (context, index) {
                        final p = queue[index];
                        return ListTile(
                          key: ValueKey(p),
                          leading: CircleAvatar(backgroundColor: index < 2 ? Colors.red.shade100 : Colors.grey.shade300, child: Text('${index + 1}', style: TextStyle(color: index < 2 ? Colors.red.shade800 : Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.bold))),
                          title: Text(p, style: TextStyle(fontWeight: index < 2 ? FontWeight.bold : FontWeight.normal)),
                          subtitle: index == 0 ? const Text('最初の赤選手', style: TextStyle(fontSize: 10, color: Colors.red)) : index == 1 ? const Text('最初の白選手', style: TextStyle(fontSize: 10, color: Colors.blueGrey)) : null,
                          trailing: IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey),
                            onPressed: () => ref.read(bunaiksenInfiniteQueueProvider.notifier).removePlayer(p),
                          ),
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.local_fire_department),
              label: const Text('🔥 無限稽古スタート', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B0000), // ★ 修正
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: queue.length < 2 ? null : () async {
                final notifier = ref.read(bunaiksenInfiniteQueueProvider.notifier);
                final p1 = notifier.popFirst();
                final p2 = notifier.popFirst();
                if (p1 == null || p2 == null) return;

                final rule = ref.read(bunaiksenRuleProvider);
                final todayId = 'bunaiksen_${DateFormat('yyyyMMdd').format(DateTime.now())}';
                final groupId = 'infinite_${DateFormat('yyyyMMdd').format(DateTime.now())}';
                final matchId = const Uuid().v4();

                final newMatch = MatchModel(
                  id: matchId,
                  tournamentId: todayId,
                  groupName: groupId,
                  matchType: '無限勝ち抜き',
                  redName: p1,
                  whiteName: p2,
                  matchTimeMinutes: rule.matchTimeMinutes.toInt(),
                  hasExtension: false,
                  extensionTimeMinutes: 0,
                  status: 'in_progress',
                  order: DateTime.now().millisecondsSinceEpoch.toDouble(),
                  rule: rule,
                  note: '無限勝ち抜き',
                  isKachinuki: true,
                );

                ref.read(bunaiksenInfiniteStreakProvider.notifier).clearAll();

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