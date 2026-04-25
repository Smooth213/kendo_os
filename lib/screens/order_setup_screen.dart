import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/player_model.dart';
import '../models/match_model.dart';
import '../providers/match_command_provider.dart';
import '../repositories/player_repository.dart';
import 'package:uuid/uuid.dart';
import '../providers/match_rule_provider.dart';
import '../providers/last_used_settings_provider.dart'; // ★ 追加：正確な小数の時間を取得するため
import '../utils/text_sanitizer.dart'; // ★ 追加：お掃除フィルター
import '../providers/match_list_provider.dart'; // ★ 追加：試合履歴の取得に必要

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
    if (m.redName.contains(':')) history.add(m.redName.split(':').first.trim());
    if (m.whiteName.contains(':')) history.add(m.whiteName.split(':').first.trim());
  }
  return history.toList()..sort();
});

class OrderSetupScreen extends ConsumerStatefulWidget {
  final String tournamentId;

  const OrderSetupScreen({
    super.key, 
    required this.tournamentId, 
  });

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

  // ★ リーグ戦拡張：参加者リストと追加用コントローラー
  final List<String> _leagueParticipants = [];
  final Map<String, List<String>> _leagueTeamOrders = {}; // ★ 追加：参加チームごとのオーダーを保持
  final TextEditingController _addParticipantController = TextEditingController();
  final FocusNode _addParticipantFocusNode = FocusNode(); // ★ 追加：フォーカス状態を永続化

  @override
  void initState() {
    super.initState();
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
    _opponentTeamController.dispose();
    _opponentTeamFocusNode.dispose(); // ★ 追加：メモリリーク防止
    _addParticipantController.dispose();
    _addParticipantFocusNode.dispose(); // ★ 追加：メモリリーク防止
    super.dispose();
  }

  Future<String?> _showManualInputDialog() async {
    String manualName = '';
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('選手名を直接入力', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(hintText: '助っ人選手名などを入力', border: OutlineInputBorder()),
          onChanged: (val) => manualName = val,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, manualName),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade600, foregroundColor: Colors.white),
            child: const Text('決定'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectPlayer(int index, List<PlayerModel> masterPlayers) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBgColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final dividerColor = isDark ? const Color(0xFF38383A) : Colors.grey.shade300;

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: sheetBgColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 16, left: 24, right: 24),
        child: Column(
          children: [
            Container(width: 48, height: 5, decoration: BoxDecoration(color: dividerColor, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 24),
            Text('選手の選択', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.teal.shade300 : Colors.teal.shade900)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context, 'CLEAR_FLAG'),
                    icon: const Icon(Icons.person_outline, size: 16),
                    label: const Text('未定（空枠）', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.grey.shade700, side: BorderSide(color: Colors.grey.shade300), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context, '欠員'),
                    icon: const Icon(Icons.block, size: 16),
                    label: const Text('欠員（不戦敗）', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade600, side: BorderSide(color: Colors.red.shade200), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final inputName = await _showManualInputDialog();
                if (context.mounted && inputName != null) Navigator.pop(context, inputName);
              },
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('直接入力（助っ人など）', style: TextStyle(fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.teal.shade700, side: BorderSide(color: Colors.teal.shade200), minimumSize: const Size(double.infinity, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('登録選手から選択', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.teal.shade800))),
                  ...masterPlayers.map((p) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: 0,
                    color: isDark ? Colors.teal.shade900.withValues(alpha: 0.3) : Colors.teal.shade50.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isDark ? Colors.transparent : Colors.teal.shade100)),
                    child: ListTile(
                      leading: CircleAvatar(backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.white, child: Text(p.name.substring(0, 1), style: TextStyle(color: isDark ? Colors.teal.shade400 : Colors.teal.shade700, fontWeight: FontWeight.bold))),
                      title: Text(p.name, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                      subtitle: Text(p.gradeName, style: TextStyle(color: Colors.teal.shade600, fontSize: 12)),
                      trailing: Icon(Icons.check_circle_outline, color: Colors.teal.shade600),
                      onTap: () => Navigator.pop(context, p.name),
                    ),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
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

  // ★ 追加：団体リーグ戦で参加チームのオーダー（先鋒〜大将）を入力するダイアログ
  Future<List<String>?> _showLeagueOrderDialog(String teamName, List<String> positions) async {
    List<TextEditingController> controllers = List.generate(positions.length, (i) => TextEditingController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showDialog<List<String>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        title: Text('$teamName のオーダー', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.teal.shade300 : Colors.teal.shade800)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: positions.length,
            itemBuilder: (context, i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: controllers[i],
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    labelText: positions[i],
                    labelStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                    isDense: true,
                    filled: true,
                    fillColor: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              List<String> order = controllers.map((c) => TextSanitizer.clean(c.text)).toList();
              Navigator.pop(ctx, order);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade600, foregroundColor: Colors.white, elevation: 0),
            child: const Text('決定して追加', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ★ 修正：個人リーグ戦で「所属」と「名前」をセットで入力するダイアログ（サジェスト付き）
  Future<Map<String, String>?> _showIndividualLeagueEntryDialog(String initialName) async {
    final affiController = TextEditingController();
    final affiFocusNode = FocusNode(); // ★ 追加
    final nameController = TextEditingController(text: initialName);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final history = ref.read(opponentTeamHistoryProvider); // ★ 履歴を読み込む

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        title: const Text('リーグ参加者の登録', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ★ 所属（チーム名）のサジェスト付き入力欄
            _buildTeamAutocomplete(
              controller: affiController,
              focusNode: affiFocusNode, // ★ 追加
              suggestions: history,
              labelText: '所属（例：広島剣道会）',
              hintText: '空欄でもOK',
              fillColor: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade50,
              borderColor: isDark ? const Color(0xFF38383A) : Colors.grey.shade300,
              textColor: isDark ? Colors.white : Colors.black87,
              subTextColor: Colors.grey,
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: '選手名（例：田中太郎）',
                filled: true, fillColor: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? const Color(0xFF38383A) : Colors.grey.shade300)),
              ),
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, {
              'affiliation': TextSanitizer.clean(affiController.text),
              'name': TextSanitizer.clean(nameController.text),
            }),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade600, foregroundColor: Colors.white, elevation: 0),
            child: const Text('追加', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    affiController.dispose(); // ★ 追加：メモリリーク防止
    affiFocusNode.dispose(); // ★ 追加：メモリリーク防止
    return result; // ★ 追加
  }

  // ★ フェーズ3：没入型AppBar（戻るボタンの色をTealへ統一）
  Widget _buildImmersiveAppBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, bottom: 8, left: 16, right: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          IconButton(
            // ★ 修正：ここも Teal.shade700 でアクセントを合わせます
            icon: Icon(Icons.arrow_back_ios_new, color: Colors.teal.shade700, size: 24),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildStaticHeader() {
    // ★ Phase 8-1: 横画面ではヘッダーを隠す
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    if (isLandscape && MediaQuery.of(context).size.height < 500) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // iOS Native: ダークモード時は彩度を抑えた深みのあるTealへ
    final color1 = isDark ? Colors.teal.shade800 : Colors.teal.shade400;
    final endColor = isDark ? Colors.teal.shade800 : Colors.teal.shade300;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color1, endColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('最終ステップ: オーダー編成', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.0)),
          const SizedBox(height: 8),
          Text('対戦相手と出場選手を決定し、\n試合枠を生成します', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w500)),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            value: 1.0, 
            backgroundColor: Colors.white.withValues(alpha: 0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerListAsync = ref.watch(playerListProvider);
    final rule = ref.watch(matchRuleProvider);
    // ★ 追加：lastSettings から試合形式の文字列(matchType)を取得する
    final String matchType = ref.watch(lastUsedSettingsProvider)['matchType'] as String? ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final inputBgColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF38383A) : Colors.grey.shade300;
    final subTextColor = isDark ? const Color(0xFF8E8E93) : Colors.grey.shade600;

    // ★ Phase 8-3: キーボードが開いているかを検知
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF2F2F7),
      body: Column(
        children: [
          // ★ キーボードが開いた時はヘッダーをスッと隠す
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: isKeyboardOpen ? const SizedBox.shrink() : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildImmersiveAppBar(context),
                _buildStaticHeader(),
              ],
            ),
          ),
          Expanded(
            child: playerListAsync.when(
              // ★ Phase 8-1: ColumnをListViewに変更し、画面全体をスクロール可能にして縦幅エラー(63px)を解消
              data: (masterPlayers) => ListView(
                padding: EdgeInsets.zero,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: isDark ? Colors.teal.shade900.withValues(alpha: 0.2) : Colors.teal.shade50,
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: isDark ? Colors.teal.shade400 : Colors.teal.shade700),
                        const SizedBox(width: 8),
                        Expanded(child: Text('自チームの選手を選択し、必要に応じて相手のチーム・選手名を入力してください。', style: TextStyle(color: isDark ? Colors.teal.shade100 : Colors.black87))),
                      ],
                    ),
                  ),
                  if (rule.isLeague)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('1. リーグ参加者リストの作成', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade800, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('大会パンフレットの番号順に並べ替えてください（長押しで移動）', style: TextStyle(fontSize: 11, color: subTextColor)),
                          const SizedBox(height: 16),
                          
                          // 参加者追加フォーム
                          _buildTeamAutocomplete(
                            controller: _addParticipantController,
                            focusNode: _addParticipantFocusNode, // ★ 追加
                            suggestions: ref.watch(opponentTeamHistoryProvider),
                            // ★ 修正：rule ではなく、取得した matchType 変数を使用
                            labelText: matchType.contains('個人戦') ? '参加選手名を追加' : '参加チーム名を追加',
                            hintText: '入力または履歴から選択',
                            fillColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                            borderColor: borderColor,
                            textColor: textColor,
                            subTextColor: subTextColor,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final input = TextSanitizer.clean(_addParticipantController.text);
                                if (input.isEmpty && !matchType.contains('個人戦')) return;

                                if (matchType.contains('個人戦')) {
                                  // ★ 修正：個人戦は「所属」と「名前」を入力する専用ダイアログを表示
                                  final result = await _showIndividualLeagueEntryDialog(input);
                                  if (result != null) {
                                    final fullName = result['affiliation']!.isNotEmpty 
                                        ? '${result['affiliation']} : ${result['name']}' 
                                        : result['name']!;
                                    if (!_leagueParticipants.contains(fullName)) {
                                      setState(() {
                                        _leagueParticipants.add(fullName);
                                        _leagueTeamOrders[fullName] = [result['name']!];
                                        _addParticipantController.clear();
                                      });
                                    }
                                  }
                                } else {
                                  // 団体戦：既存のロジック
                                  if (input.isEmpty || _leagueParticipants.contains(input)) return;
                                  final order = await _showLeagueOrderDialog(input, _positions);
                                  if (order != null) {
                                    setState(() {
                                      _leagueParticipants.add(input);
                                      _leagueTeamOrders[input] = order;
                                      _addParticipantController.clear();
                                    });
                                  }
                                }
                              },
                              icon: const Icon(Icons.person_add),
                              label: const Text('リストに追加', style: TextStyle(fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade600, foregroundColor: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // 並び替え可能なリスト
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: borderColor),
                            ),
                            child: ReorderableListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _leagueParticipants.length,
                              onReorder: (oldIndex, newIndex) {
                                setState(() {
                                  if (oldIndex < newIndex) newIndex -= 1;
                                  final item = _leagueParticipants.removeAt(oldIndex);
                                  _leagueParticipants.insert(newIndex, item);
                                });
                              },
                              itemBuilder: (context, index) {
                                final name = _leagueParticipants[index];
                                return ListTile(
                                  key: ValueKey(name),
                                  leading: CircleAvatar(
                                    backgroundColor: name.contains('自チーム') || name == rule.teamName 
                                      ? Colors.teal.shade100 : Colors.grey.shade200,
                                    child: Text('${index + 1}', style: TextStyle(color: Colors.teal.shade900, fontWeight: FontWeight.bold)),
                                  ),
                                  title: Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                                  trailing: const Icon(Icons.drag_handle, color: Colors.grey),
                                  onLongPress: () {}, // ReorderableListViewのトリガー用
                                  subtitle: (name.contains('自チーム') || name == rule.teamName) 
                                    ? Text('（自チーム）', style: TextStyle(fontSize: 10, color: Colors.teal.shade700)) : null,
                                  onTap: (name.contains('自チーム') || name == rule.teamName) ? null : () {
                                    setState(() => _leagueParticipants.removeAt(index));
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text('2. 自チームのオーダーを確認', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade800, fontSize: 16)),
                        ],
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('自チームの紅白（タスキ）', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade800)),
                          const SizedBox(height: 4),
                          const Text('※数字の小さい方または上・左のチーム（選手）が赤になります', style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Container(
                            // ★ 修正：外枠を沈み込むダークグレーへ
                            decoration: BoxDecoration(color: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.all(4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _isOwnTeamRed = true),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        // ★ 修正：選択時のツマミ部分を少し浮かせる明るめのグレーへ
                                        color: _isOwnTeamRed ? (isDark ? const Color(0xFF2C2C2E) : Colors.white) : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: (_isOwnTeamRed && !isDark) ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))] : [],
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.looks_one, size: 18, color: _isOwnTeamRed ? Colors.red.shade700 : (isDark ? Colors.grey.shade600 : Colors.grey)),
                                          const SizedBox(width: 8),
                                          Text('赤 (左側)', style: TextStyle(color: _isOwnTeamRed ? Colors.red.shade700 : subTextColor, fontWeight: FontWeight.bold, fontSize: 14)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _isOwnTeamRed = false),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: !_isOwnTeamRed ? (isDark ? const Color(0xFF2C2C2E) : Colors.white) : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: (!_isOwnTeamRed && !isDark) ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))] : [],
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.looks_two, size: 18, color: !_isOwnTeamRed ? (isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade700) : (isDark ? Colors.grey.shade600 : Colors.grey)),
                                          const SizedBox(width: 8),
                                          // ★ 修正：白チーム選択時の文字色を純白へ
                                          Text('白 (右側)', style: TextStyle(color: !_isOwnTeamRed ? (isDark ? Colors.white : Colors.blueGrey.shade700) : subTextColor, fontWeight: FontWeight.bold, fontSize: 14)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                              const SizedBox(height: 24), // 余白を広げる
                              // ★ 直感UX改修：相手チームの入力を明確なブロック（カード風）で囲み、迷いをなくす
                              Container(
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade100, // 背景を少し落とす
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: borderColor, width: 1.5),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.shield, color: isDark ? Colors.blueGrey.shade400 : Colors.blueGrey.shade600, size: 18),
                                        const SizedBox(width: 8),
                                        Text('相手チームの情報を入力', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade800)),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    // ★ 修正：先ほど作ったヘルパー関数を使ってサジェスト（予測変換）対応にする
                                    _buildTeamAutocomplete(
                                      controller: _opponentTeamController,
                                      focusNode: _opponentTeamFocusNode, // ★ 追加
                                      suggestions: ref.watch(opponentTeamHistoryProvider),
                                      labelText: '相手チーム名・所属名（任意）',
                                      hintText: 'タップして登録済みリストから選択',
                                      fillColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                                      borderColor: borderColor,
                                      textColor: textColor,
                                      subTextColor: subTextColor,
                                      isDark: isDark,
                                    ),
                                  ],
                                ),
                          ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              final currentOrder = List.generate(_positions.length, (i) => _selectedPlayers[i] ?? '');
                              ref.read(matchRuleProvider.notifier).updateBaseOrder(currentOrder);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('現在のオーダーを「基本オーダー」として記憶しました')));
                            },
                            icon: const Icon(Icons.save_alt, size: 16),
                            label: const Text('基本オーダーに登録', style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.teal.shade700, side: BorderSide(color: Colors.teal.shade300)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: rule.baseOrder.isEmpty ? null : () {
                              setState(() {
                                for (int i = 0; i < rule.baseOrder.length && i < _positions.length; i++) {
                                  if (rule.baseOrder[i].isNotEmpty) {
                                    _selectedPlayers[i] = rule.baseOrder[i];
                                  } else {
                                    _selectedPlayers.remove(i);
                                  }
                                }
                              });
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('基本オーダーを呼び出しました')));
                            },
                            icon: const Icon(Icons.download, size: 16),
                            label: const Text('基本オーダーを呼出', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade50, foregroundColor: Colors.teal.shade800, elevation: 0),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ★ Phase 8-1: 親がListViewになったので、ここはExpandedを外してshrinkWrapを付与
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: _positions.length,
                    itemBuilder: (context, index) {
                        final posName = _positions[index];
                        final playerName = _selectedPlayers[index] ?? '未定';
                        final isSelected = _selectedPlayers.containsKey(index);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 0,
                          color: inputBgColor,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(color: isSelected ? Colors.teal.shade300 : borderColor, width: isSelected ? 2 : 1),
                            borderRadius: BorderRadius.circular(12)
                          ),
                          child: Column(
                            children: [
                              InkWell(
                                // ★ 真の解決：ダイアログ終了後に自動でフォーカスが戻ってサジェストが暴発する「ゴーストフォーカス」を完全に殺す
                                onTap: () async {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  await _selectPlayer(index, masterPlayers);
                                  if (!mounted) return;
                                  FocusManager.instance.primaryFocus?.unfocus();
                                },
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: isSelected ? (isDark ? Colors.teal.shade900.withValues(alpha: 0.3) : Colors.teal.shade100) : (isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade200),
                                        child: Text(posName.substring(0, 1), style: TextStyle(color: isSelected ? Colors.teal.shade400 : subTextColor, fontWeight: FontWeight.bold)),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(rule.teamName.isNotEmpty ? '${rule.teamName} : $posName' : posName, style: TextStyle(fontSize: 12, color: Colors.teal.shade600, fontWeight: FontWeight.bold)),
                                            Text(playerName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isSelected ? textColor : subTextColor)),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(color: isSelected ? (isDark ? Colors.teal.shade900.withValues(alpha: 0.3) : Colors.teal.shade50) : (isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade100), borderRadius: BorderRadius.circular(20)),
                                        child: Text(isSelected ? '変更' : '選択', style: TextStyle(color: isSelected ? Colors.teal.shade500 : subTextColor, fontSize: 13, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // ★ 修正：画像でご指摘いただいた通り、リーグ戦では相手の個別入力を非表示にしてスッキリさせる！
                              if (!rule.isLeague) ...[
                                Divider(height: 1, indent: 16, endIndent: 16, color: isDark ? const Color(0xFF38383A) : Colors.grey.shade200),
                                Container(
                                  decoration: BoxDecoration(color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12))),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: TextFormField(
                                    key: ValueKey(_opponentPlayers[index]), 
                                    initialValue: _opponentPlayers[index],
                                  onChanged: (val) => _opponentPlayers[index] = val,
                                  style: TextStyle(color: textColor),
                                  decoration: InputDecoration(
                                    labelText: '対戦相手 ($posName)',
                                    labelStyle: TextStyle(color: subTextColor),
                                    hintText: '相手選手名（任意）',
                                    hintStyle: TextStyle(color: subTextColor),
                                    isDense: true,
                                    prefixIcon: const Icon(Icons.person_outline, size: 20, color: Colors.blueGrey),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.teal.shade300)),
                                    fillColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                                    filled: true,
                                    suffixIcon: Padding(
                                      padding: const EdgeInsets.only(right: 4.0),
                                      child: TextButton.icon(
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 8), 
                                          minimumSize: Size.zero,
                                          backgroundColor: Colors.red.shade50, 
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                        ),
                                        icon: const Icon(Icons.block, color: Colors.redAccent, size: 14), 
                                        label: const Text('欠員', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                                        onPressed: () {
                                          setState(() => _opponentPlayers[index] = '欠員');
                                          FocusScope.of(context).unfocus(); 
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              ], // ★ if (!rule.isLeague) を閉じる
                            ],
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
          // ★ キーボードが開いた時は下のボタンエリアも隠す
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: isKeyboardOpen ? const SizedBox.shrink() : SafeArea(
              top: false, // 下側だけSafeAreaを効かせる
              child: Container(
                decoration: BoxDecoration(color: inputBgColor, border: Border(top: BorderSide(color: borderColor, width: 0.5))),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      onPressed: _addExtraPosition,
                      icon: Icon(Icons.add_circle_outline, color: Colors.teal.shade600),
                      label: Text('イレギュラー枠を追加する（錬成会用）', style: TextStyle(color: isDark ? Colors.teal.shade400 : Colors.teal.shade700, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          // ★ 修正：ここではチェックせず、後の pairings 生成直前のバリデーションに集約します
                          final bool? isStartNow = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('試合の登録', style: TextStyle(fontWeight: FontWeight.bold)),
                              content: const Text('このオーダーで試合を登録します。今すぐ試合画面に進みますか？'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('後で（リストに保存）', style: TextStyle(color: Colors.grey))),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true), 
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade600, foregroundColor: Colors.white, elevation: 0),
                                  child: const Text('今すぐ試合開始', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );

                          if (isStartNow == null) return; 

                          if (!context.mounted) return;
                          // ★ Phase 8-1: ダイアログの「戻る」が画面を消さないように、rootNavigatorを使う
                          showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));

                          try {
                            // ★ 修正：不要になった古い変数を綺麗にお掃除
                            String senpoMatchId = '';
                            double baseOrder = DateTime.now().millisecondsSinceEpoch.toDouble();
                            List<MatchModel> matchesToSave = []; 
                            
                            // ★ 追加：リーグ戦であることを明示するタグを生成し、後で全試合のnoteに付与する
                            final String saveNote = rule.isLeague ? '[リーグ戦] ${rule.note}'.trim() : rule.note;
                            // ★ 追加：リーグ全体を1つのアコーディオンにまとめるための共通ID
                            final String leagueGroupId = rule.isLeague ? const Uuid().v4() : '';

                            List<List<String>> pairings = [];
                            // ★ 修正：入力された相手チーム名をお掃除フィルターに通す！
                            String myTeamName = rule.teamName.isNotEmpty ? rule.teamName : '自チーム';
                            String opTeamName = TextSanitizer.clean(_opponentTeamController.text);
                            if (opTeamName.isEmpty) opTeamName = '対戦相手';

                            if (rule.isLeague) {
                              if (_leagueParticipants.length < 2) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('リーグ戦には少なくとも2つのチーム・選手が必要です')));
                                Navigator.of(context, rootNavigator: true).pop();
                                return;
                              }
                              
                              // ★ 修正：並び替えた順序をルールに記憶させる
                              ref.read(matchRuleProvider.notifier).updateRule(rule.copyWith(
                                leagueOrder: _leagueParticipants,
                              ));

                              // ★ 修正：並び替えたリストに基づいて総当たりのペアを生成
                              for (int i = 0; i < _leagueParticipants.length; i++) {
                                for (int j = i + 1; j < _leagueParticipants.length; j++) {
                                  pairings.add([_leagueParticipants[i], _leagueParticipants[j]]);
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
                              for (int pIndex = 0; pIndex < pairings.length; pIndex++) {
                                final pair = pairings[pIndex];
                                // ★ 修正：リーグ戦なら共通IDを使い、通常なら個別のIDを発行
                                final String teamGroupId = rule.isLeague ? leagueGroupId : const Uuid().v4();

                                if (rule.isKachinuki) {
                                  List<String> redFull = [];
                                  List<String> whiteFull = [];
                                  
                                  for (int i = 0; i < _positions.length; i++) {
                                    String myP = _selectedPlayers[i] ?? '未定';
                                    if (myP.isEmpty) myP = '未定';
                                    String opP = _opponentPlayers[i]?.trim() ?? '';
                                    if (opP.isEmpty) opP = '選手';
                                    String myFull = '$myTeamName : $myP';
                                    String opFull = '$opTeamName : $opP';
                                    String rN, wN;
                                    if (rule.isLeague) {
                                      // ★ 修正：入力されたオーダーを呼び出して完璧にセットする！
                                      String rTeam = pair[0];
                                      String wTeam = pair[1];
                                      String rPlayer = (rTeam == '自チーム') ? myP : (_leagueTeamOrders[rTeam]?[i] ?? '選手');
                                      if (rPlayer.isEmpty) rPlayer = '選手';
                                      String wPlayer = (wTeam == '自チーム') ? myP : (_leagueTeamOrders[wTeam]?[i] ?? '選手');
                                      if (wPlayer.isEmpty) wPlayer = '選手';
                                      
                                      rN = (rTeam == '自チーム') ? myFull : '$rTeam : $rPlayer';
                                      wN = (wTeam == '自チーム') ? myFull : '$wTeam : $wPlayer';
                                    } else {
                                      rN = _isOwnTeamRed ? myFull : opFull;
                                      wN = _isOwnTeamRed ? opFull : myFull;
                                    }
                                    redFull.add(rN);
                                    whiteFull.add(wN);
                                  }
                                  
                                  final matchId = const Uuid().v4();
                                  if (senpoMatchId.isEmpty) senpoMatchId = matchId;
                                  
                                  final newMatch = MatchModel(
                                    id: matchId, tournamentId: widget.tournamentId, category: rule.category.isNotEmpty ? rule.category : null,
                                    groupName: teamGroupId, matchType: _positions[0], whiteName: whiteFull[0], redName: redFull[0],
                                    status: (isStartNow && pIndex == 0) ? 'in_progress' : 'waiting', refereeNames: [],
                                    
                                    // ★ 全て rule からもらう
                                    matchTimeMinutes: rule.matchTimeMinutes.toInt(), 
                                    isRunningTime: rule.isRunningTime, 
                                    remainingSeconds: (rule.matchTimeMinutes * 60).toInt(),
                                    hasExtension: rule.enchoTimeMinutes > 0 || rule.isEnchoUnlimited, 
                                    extensionTimeMinutes: rule.enchoTimeMinutes.toInt(), 
                                    extensionCount: rule.enchoCount, 
                                    hasHantei: rule.hasHantei, 
                                    
                                    order: baseOrder + (pIndex * 10), note: saveNote, isKachinuki: true,
                                    rule: rule, 
                                    redRemaining: redFull.length > 1 ? redFull.sublist(1) : [], whiteRemaining: whiteFull.length > 1 ? whiteFull.sublist(1) : [],
                                  );
                                  matchesToSave.add(newMatch); 

                                } else {
                                  for (int i = 0; i < _positions.length; i++) {
                                    final String matchId = const Uuid().v4();
                                    if (senpoMatchId.isEmpty) senpoMatchId = matchId; 
                                    final posName = _positions[i];
                                    String myP = _selectedPlayers[i] ?? '未定';
                                    if (myP.isEmpty) myP = '未定'; 
                                    String opP = _opponentPlayers[i]?.trim() ?? '';
                                    if (opP.isEmpty) opP = '選手';
                                    String myFull = '$myTeamName : $myP';
                                    String opFull = '$opTeamName : $opP';
                                    String rName, wName;
                                    if (rule.isLeague) {
                                      // ★ 修正：入力されたオーダーと「個人戦/団体戦」の違いを反映！
                                      String rTeam = pair[0];
                                      String wTeam = pair[1];
                                      String rPlayer = (rTeam == '自チーム') ? myP : (_leagueTeamOrders[rTeam]?[i] ?? '選手');
                                      if (rPlayer.isEmpty) rPlayer = '選手';
                                      String wPlayer = (wTeam == '自チーム') ? myP : (_leagueTeamOrders[wTeam]?[i] ?? '選手');
                                      if (wPlayer.isEmpty) wPlayer = '選手';
                                      
                                      // ★ 修正：画面上部で既に取得している matchType をそのまま利用する
                                      if (matchType.contains('個人戦')) {
                                        // ★ 修正：ダイアログの時点で既に「所属 : 名前」になっているので、そのまま使う！
                                        rName = (rTeam == '自チーム') ? myFull : rTeam;
                                        wName = (wTeam == '自チーム') ? myFull : wTeam;
                                      } else {
                                        rName = (rTeam == '自チーム') ? myFull : '$rTeam : $rPlayer';
                                        wName = (wTeam == '自チーム') ? myFull : '$wTeam : $wPlayer';
                                      }
                                    } else {
                                      rName = _isOwnTeamRed ? myFull : opFull;
                                      wName = _isOwnTeamRed ? opFull : myFull;
                                    }
                                    bool isFirstMatchOfAll = (pIndex == 0 && i == 0);
                                    final newMatch = MatchModel(
                                      id: matchId, tournamentId: widget.tournamentId, category: rule.category.isNotEmpty ? rule.category : null,
                                      groupName: teamGroupId, matchType: posName, redName: rName, whiteName: wName,
                                      status: (isStartNow && isFirstMatchOfAll) ? 'in_progress' : 'waiting', refereeNames: [],
                                      
                                      // ★ 修正：すべて完璧な状態の「rule」から直接もらう！
                                      matchTimeMinutes: rule.matchTimeMinutes.toInt(), 
                                      isRunningTime: rule.isRunningTime, 
                                      remainingSeconds: (rule.matchTimeMinutes * 60).toInt(),
                                      hasExtension: rule.enchoTimeMinutes > 0 || rule.isEnchoUnlimited || posName.contains('代表'),
                                      extensionTimeMinutes: rule.enchoTimeMinutes.toInt(), 
                                      extensionCount: rule.enchoCount, 
                                      hasHantei: rule.hasHantei, 
                                      
                                      order: baseOrder + (pIndex * 10) + i, 
                                      note: saveNote, 
                                      rule: rule, // ★ これだけで全てが封印されます
                                    );
                                    debugPrint('📦 [1. 生成センサー] MatchId: $matchId, Ruleがnullか?: ${newMatch.rule == null}'); // ★ デバッグ用センサー
                                    matchesToSave.add(newMatch); 
                                  }
                                }
                              }
                            });

                            if (matchesToSave.isNotEmpty) await ref.read(matchCommandProvider).saveMatchesBulk(matchesToSave);
                            
                            if (!context.mounted) return;
                            Navigator.of(context, rootNavigator: true).pop(); // ★ Phase 8-1: ローディングダイアログだけを確実に閉じる！
                            
                            if (isStartNow) {
                              if (senpoMatchId.isNotEmpty) {
                                context.push('/match/$senpoMatchId');
                              } else {
                                context.go('/home/${widget.tournamentId}'); 
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('試合をプールしました（待機リストに追加）')));
                              context.go('/home/${widget.tournamentId}'); 
                            }
                          } catch (e) {
                            if (!context.mounted) return;
                            Navigator.of(context, rootNavigator: true).pop();
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存に失敗しました: $e')));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          // iOS Native: ダークモード時に沈まないTeal
                          backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.teal.shade600 : Colors.teal.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // 角丸をiOS標準の12に
                          elevation: 0,
                        ),
                        child: const Text('このオーダーで確定して進む', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ★ 追加：予測変換（サジェスト）と手入力を両立する、最強の入力フィールドビルダー
  Widget _buildTeamAutocomplete({
    required TextEditingController controller,
    required FocusNode focusNode, // ★ 追加：親で管理しているFocusNodeを受け取る
    required List<String> suggestions,
    required String labelText,
    required String hintText,
    required Color fillColor,
    required Color borderColor,
    required Color textColor,
    required Color subTextColor,
    required bool isDark,
  }) {
    return RawAutocomplete<String>(
      textEditingController: controller,
      focusNode: focusNode, // ★ 修正：毎回の再生成をやめる（setState時の誤発火防止）
      // ユーザーが文字を打つたびに候補を絞り込む
      optionsBuilder: (TextEditingValue textEditingValue) {
        // ★ 真の解決：IME入力（日本語変換中）のゴースト状態を正確に捉えるため、textEditingValueを使用する
        final text = textEditingValue.text;
        
        if (text.isEmpty) {
          return suggestions;
        }
        return suggestions.where((option) => option.contains(text));
      },
      // 実際の入力欄のデザイン（今までと同じ見た目を維持しつつ、右端に▼をつける）
      fieldViewBuilder: (context, fieldController, focusNode, onFieldSubmitted) {
        return TextField(
          controller: fieldController,
          focusNode: focusNode,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            labelText: labelText,
            labelStyle: TextStyle(color: subTextColor),
            hintText: hintText,
            hintStyle: TextStyle(color: subTextColor),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.teal.shade500)),
            prefixIcon: Icon(Icons.shield_outlined, color: isDark ? Colors.blueGrey.shade400 : Colors.blueGrey.shade400),
            suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.grey), // ▼アイコン
            fillColor: fillColor,
            filled: true,
            isDense: true,
          ),
        );
      },
      // 浮かび上がる候補リストのデザイン
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8.0,
            borderRadius: BorderRadius.circular(12),
            color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
            child: ConstrainedBox(
              // 幅を画面に合わせる
              constraints: BoxConstraints(maxHeight: 250, maxWidth: MediaQuery.of(context).size.width - 48),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    title: Text(option, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                    trailing: const Icon(Icons.add_circle_outline, color: Colors.teal, size: 18),
                    onTap: () {
                      onSelected(option); // 選んだら入力完了
                      FocusScope.of(context).unfocus(); // ★ 追加：フォーカスを外してサジェストとキーボードをスッと消す
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}