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

final playerListProvider = StreamProvider.autoDispose<List<PlayerModel>>((ref) {
  return ref.watch(playerRepositoryProvider).getPlayers();
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
  final Map<int, String> _opponentPlayers = {};
  bool _isOwnTeamRed = true;

  final List<TextEditingController> _leagueOpponentControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

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
  }

  @override
  void dispose() {
    _opponentTeamController.dispose();
    for (var ctrl in _leagueOpponentControllers) {
      ctrl.dispose();
    }
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final inputBgColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF38383A) : Colors.grey.shade300;
    final subTextColor = isDark ? const Color(0xFF8E8E93) : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF2F2F7),
      body: Column(
        children: [
          _buildImmersiveAppBar(context),
          _buildStaticHeader(),
          Expanded(
            child: playerListAsync.when(
              data: (masterPlayers) => Column(
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
                          Text('リーグ戦の対戦チームを入力', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade700)),
                          const SizedBox(height: 8),
                          ...List.generate(_leagueOpponentControllers.length, (i) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: TextField(
                              controller: _leagueOpponentControllers[i],
                              style: TextStyle(color: textColor),
                              decoration: InputDecoration(
                                labelText: 'リーグ相手 ${i + 1} (チーム名/選手名)',
                                labelStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: borderColor)),
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.shield),
                                fillColor: isDark ? const Color(0xFF2C2C2E) : Colors.red.shade50,
                                filled: true,
                                isDense: true,
                              ),
                            ),
                          )),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () => setState(() => _leagueOpponentControllers.add(TextEditingController())),
                              icon: const Icon(Icons.add),
                              label: const Text('相手チームを追加'),
                              style: TextButton.styleFrom(foregroundColor: Colors.teal.shade700),
                            ),
                          )
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
                                    TextField(
                                      controller: _opponentTeamController,
                                      style: TextStyle(color: textColor),
                                      decoration: InputDecoration(
                                        labelText: '相手チーム名・所属名（任意）',
                                        labelStyle: TextStyle(color: subTextColor),
                                        hintText: '例：広島剣道クラブ',
                                        hintStyle: TextStyle(color: subTextColor),
                                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.teal.shade500)),
                                        prefixIcon: Icon(Icons.shield_outlined, color: isDark ? Colors.blueGrey.shade400 : Colors.blueGrey.shade400),
                                        fillColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                                        filled: true,
                                        isDense: true,
                                      ),
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
                  Expanded(
                    child: ListView.builder(
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
                                onTap: () => _selectPlayer(index, masterPlayers),
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
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('エラー: $err')),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
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
                    if (rule.isLeague) {
                      bool hasOpponent = _leagueOpponentControllers.any((ctrl) => ctrl.text.trim().isNotEmpty);
                      if (!hasOpponent) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('リーグ戦を行うには、少なくとも1つの相手チームを入力してください。')));
                        return; 
                      }
                    }

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
                    showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));

                    try {
                      // ★ 追加：ルールの分数（int切り捨て）ではなく、設定に保存された正確な小数（double）を読み込む
                      final lastSettings = ref.read(lastUsedSettingsProvider);
                      final double exactMatchTime = (lastSettings['matchTime'] as num?)?.toDouble() ?? rule.matchTimeMinutes.toDouble();
                      final int initialSeconds = (exactMatchTime * 60).toInt(); // 1.5 なら 90秒 になる！

                      String senpoMatchId = '';
                      double baseOrder = DateTime.now().millisecondsSinceEpoch.toDouble();
                      List<MatchModel> matchesToSave = []; 

                      List<List<String>> pairings = [];
                      String myTeamName = rule.teamName.isNotEmpty ? rule.teamName : '自チーム';
                      String opTeamName = _opponentTeamController.text.trim();
                      if (opTeamName.isEmpty) opTeamName = '対戦相手';

                      if (rule.isLeague) {
                        List<String> leagueTeams = ['自チーム'];
                        for (var ctrl in _leagueOpponentControllers) {
                          if (ctrl.text.trim().isNotEmpty) leagueTeams.add(ctrl.text.trim());
                        }
                        for (int i = 0; i < leagueTeams.length; i++) {
                          for (int j = i + 1; j < leagueTeams.length; j++) {
                            pairings.add([leagueTeams[i], leagueTeams[j]]);
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
                          final String teamGroupId = const Uuid().v4();

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
                                rN = pair[0] == '自チーム' ? myFull : '${pair[0]} : 選手';
                                wN = pair[1] == '自チーム' ? myFull : '${pair[1]} : 選手';
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
                              // ★ 修正：算出した正確な秒数(initialSeconds)をセットする！
                              matchTimeMinutes: exactMatchTime.toInt(), isRunningTime: rule.isRunningTime, remainingSeconds: initialSeconds,
                              order: baseOrder + (pIndex * 10), note: rule.note, isKachinuki: true,
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
                                rName = pair[0] == '自チーム' ? myFull : '${pair[0]} : 選手';
                                wName = pair[1] == '自チーム' ? myFull : '${pair[1]} : 選手';
                              } else {
                                rName = _isOwnTeamRed ? myFull : opFull;
                                wName = _isOwnTeamRed ? opFull : myFull;
                              }
                              bool isFirstMatchOfAll = (pIndex == 0 && i == 0);
                              final newMatch = MatchModel(
                                id: matchId, tournamentId: widget.tournamentId, category: rule.category.isNotEmpty ? rule.category : null,
                                groupName: teamGroupId, matchType: posName, redName: rName, whiteName: wName,
                                status: (isStartNow && isFirstMatchOfAll) ? 'in_progress' : 'waiting', refereeNames: [],
                                // ★ 修正：算出した正確な秒数(initialSeconds)をセットする！
                                matchTimeMinutes: exactMatchTime.toInt(), isRunningTime: rule.isRunningTime, remainingSeconds: initialSeconds,
                                order: baseOrder + (pIndex * 10) + i, note: rule.note, 
                              );
                              matchesToSave.add(newMatch); 
                            }
                          }
                        }
                      });

                      if (matchesToSave.isNotEmpty) await ref.read(matchCommandProvider).saveMatchesBulk(matchesToSave);
                      
                      if (!context.mounted) return;
                      Navigator.pop(context); 
                      
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
                      Navigator.pop(context);
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
    );
  }
}