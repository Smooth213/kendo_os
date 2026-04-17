import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ★ 追加：全角半角の自動変換に必要
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/last_used_settings_provider.dart';
import '../providers/match_rule_provider.dart'; 
import '../models/match_rule.dart'; // ★ MatchRuleモデルを読み込む
import '../repositories/team_repository.dart'; 
import '../models/team_model.dart';
import '../models/player_model.dart';
import '../repositories/player_repository.dart';

final noteHistoryProvider = StateProvider<List<String>>((ref) {
  return ['1回戦', '2回戦', '準決勝', '決勝', '第1試合', '第2コート'];
});

// ★ 選手一覧を取得するProviderを追加
final playerListProvider = StreamProvider.autoDispose<List<PlayerModel>>((ref) {
  return ref.watch(playerRepositoryProvider).getPlayers();
});

class SetupMatchFormatScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  const SetupMatchFormatScreen({super.key, required this.tournamentId});

  @override
  ConsumerState<SetupMatchFormatScreen> createState() => _SetupMatchFormatScreenState();
}

class _SetupMatchFormatScreenState extends ConsumerState<SetupMatchFormatScreen> {
  late String _matchType;
  late bool _hasExtension; 
  late bool _hasHantei;
  late double _matchTime;
  late bool _isRunningTime;
  late bool _isRenseikai;
  String? _selectedTeamId; 

  late String _kachinukiUnlimitedType;
  late bool _hasLeagueDaihyo;
  late String _renseikaiType;
  final _overallTimeController = TextEditingController(text: '30'); 
  late bool _isDaihyoIpponShobu; 

  final PageController _pageController = PageController();
  int _currentPage = 0;

  // ★ 追加：2段階選択用の状態変数
  late String _selectedMajorCategory;
  late String _selectedMinorCategory;

  // ★ 追加：チーム登録画面と共通！最終的なカテゴリ名を生成
  String get _category {
    if (_selectedMajorCategory == '初心者') return '初心者の部';
    if (_selectedMajorCategory == '幼年') return '幼年の部';
    if (_selectedMinorCategory == '全体') return '$_selectedMajorCategoryの部';
    if (_selectedMajorCategory == '大学・一般') return '$_selectedMinorCategoryの部';
    return '$_selectedMajorCategory$_selectedMinorCategoryの部';
  }

  // ★ 追加：初期化時に文字列からUI状態を復元するロジック
  void _parseCategoryToState(String categoryName) {
    if (categoryName == '初心者の部') {
      _selectedMajorCategory = '初心者'; _selectedMinorCategory = '全体'; return;
    }
    if (categoryName == '幼年の部') {
      _selectedMajorCategory = '幼年'; _selectedMinorCategory = '全体'; return;
    }
    final cleanCat = categoryName.replaceAll('の部', '');
    if (['大学生', '一般', 'シニア'].contains(cleanCat)) {
      _selectedMajorCategory = '大学・一般'; _selectedMinorCategory = cleanCat; return;
    }
    for (var major in ['小学生', '中学生', '高校生']) {
      if (cleanCat.startsWith(major)) {
        _selectedMajorCategory = major;
        final minor = cleanCat.substring(major.length);
        _selectedMinorCategory = minor.isEmpty ? '全体' : minor;
        return;
      }
    }
    _selectedMajorCategory = '小学生';
    _selectedMinorCategory = '低学年';
  }

  final List<String> _majorCategories = ['初心者', '幼年', '小学生', '中学生', '高校生', '大学・一般'];

  List<String> _getMinorCategories(String major) {
    if (major == '初心者' || major == '幼年') return ['全体', '男子', '女子'];
    if (major == '小学生') return ['全体', '低学年', '高学年', '1年', '2年', '3年', '4年', '5年', '6年', '男子', '女子'];
    if (major == '中学生' || major == '高校生') return ['全体', '1年', '2年', '3年', '男子', '女子'];
    if (major == '大学・一般') return ['全体', '大学生', '一般', 'シニア', '男子', '女子'];
    return ['全体'];
  }

  @override
  void initState() {
    super.initState();
    final lastSettings = ref.read(lastUsedSettingsProvider);
    _matchType = lastSettings['matchType'];
    
    // ★ 修正：前回のカテゴリ設定を2段階UIの状態に美しく復元
    _parseCategoryToState(lastSettings['category'] ?? '小学生低学年の部');
    
    _matchTime = lastSettings['matchTime'];
    _isRunningTime = lastSettings['isRunningTime'];
    _hasExtension = lastSettings['hasExtension'];
    _hasHantei = lastSettings['hasHantei'];
    _isRenseikai = lastSettings['isRenseikai'] ?? false;
    
    _kachinukiUnlimitedType = lastSettings['kachinukiUnlimitedType'] ?? '大将対大将';
    _hasLeagueDaihyo = lastSettings['hasLeagueDaihyo'] ?? false;
    _renseikaiType = lastSettings['renseikaiType'] ?? '一試合制';
    _isDaihyoIpponShobu = lastSettings['isDaihyoIpponShobu'] ?? true; 
  }
  
  final _customTeamSizeController = TextEditingController(text: '9');
  final _noteController = TextEditingController();
  final _customMatchTimeController = TextEditingController();

  int _extCount = -2; 
  final _customExtCountController = TextEditingController();
  double _extTime = -2.0; 
  final _customExtTimeController = TextEditingController();

  final List<double> _mainTimeOptions = [1.5, 2.0, 2.5, 3.0];
  final List<double> _extraTimeOptions = [4.0, 5.0];
  bool _showExtraMatchTime = false;
  bool _showExtraExtTime = false;

  @override
  void dispose() {
    _customTeamSizeController.dispose();
    _customMatchTimeController.dispose();
    _customExtCountController.dispose();
    _customExtTimeController.dispose();
    _overallTimeController.dispose(); 
    _pageController.dispose(); 
    super.dispose();
  }

  // ★ 修正：詳細ダイアログ内でスマート・スワップを実行し、保存まで行う
  void _showTeamDetailDialog(BuildContext context, TeamModel team) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder( // ダイアログ内の状態更新のため
        builder: (context, setDialogState) {
          final List<String> posNames = _generatePositions(team.playerNames.length);

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: Colors.white,
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 400,
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.teal.shade700, Colors.teal.shade500], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(backgroundColor: Colors.white24, child: Icon(Icons.shield, color: Colors.white)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(team.teamName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('${team.category} / ${team.matchType}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 16, left: 24),
                    child: Align(alignment: Alignment.centerLeft, child: Text('オーダー（タップして入れ替え）', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey))),
                  ),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(20),
                      itemCount: team.playerNames.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final String posName = i < posNames.length ? posNames[i] : '補欠';
                        final String name = team.playerNames[i].isEmpty ? '未設定' : team.playerNames[i];
                        final bool isSub = posName == '補欠';

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          onTap: () async {
                            // 選手選択とスワップを実行
                            final newTeam = await _selectAndSwapPlayer(context, i, team, posNames);
                            if (newTeam != null) {
                              setDialogState(() { team = newTeam; }); // ダイアログの表示を更新
                              setState(() {}); // 親画面のリストも更新
                            }
                          },
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: isSub ? Colors.orange.shade50 : Colors.teal.shade50,
                            child: Text(
                              isSub ? '補' : posName.substring(0, 1), 
                              style: TextStyle(color: isSub ? Colors.orange.shade700 : Colors.teal.shade700, fontWeight: FontWeight.bold, fontSize: 13)
                            ),
                          ),
                          title: Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: name == '未設定' ? Colors.grey : Colors.black87)),
                          subtitle: Text(posName, style: TextStyle(color: isSub ? Colors.orange.shade600 : Colors.teal.shade600, fontSize: 11)),
                          trailing: const Icon(Icons.swap_vert, color: Colors.grey, size: 20),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('完了', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal))),
                  ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  // ★ スマート・スワップを実行してDBに保存するヘルパー
  Future<TeamModel?> _selectAndSwapPlayer(BuildContext context, int index, TeamModel team, List<String> posNames) async {
    final playerListAsync = ref.read(playerListProvider);
    final players = playerListAsync.value ?? [];
    
    // 現在のチームメンバーのうち、名簿にいない「手入力選手」を抽出
    final helperEntries = team.playerNames.asMap().entries
        .where((e) => e.value.isNotEmpty && e.value != '欠員')
        .where((e) => !players.any((p) => p.name == e.value))
        .toList();

    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.75,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, top: 16, left: 24, right: 24),
        child: Column(
          children: [
            Container(width: 48, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 24),
            Text('${posNames[index]} の選択', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: [
                  if (helperEntries.isNotEmpty) ...[
                    const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('手入力選手から選ぶ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange))),
                    ...helperEntries.map((entry) => Card(
                      color: Colors.orange.shade50,
                      child: ListTile(
                        title: Text(entry.value, style: const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: Text('${entry.key < posNames.length ? posNames[entry.key] : "補欠"}と入替', style: const TextStyle(fontSize: 11, color: Colors.orange)),
                        onTap: () => Navigator.pop(ctx, entry.value),
                      ),
                    )),
                  ],
                  const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('登録名簿から選ぶ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal))),
                  ...players.map((p) {
                    final usedIdx = team.playerNames.indexOf(p.name);
                    final isUsed = usedIdx != -1 && usedIdx != index;
                    return ListTile(
                      title: Text(p.name),
                      trailing: isUsed ? Text('${usedIdx < posNames.length ? posNames[usedIdx] : "補欠"}と入替', style: const TextStyle(fontSize: 11, color: Colors.orange)) : null,
                      onTap: () => Navigator.pop(ctx, p.name),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (selected != null) {
      List<String> newOrder = List.from(team.playerNames);
      int existingIdx = newOrder.indexOf(selected);
      
      if (existingIdx != -1) {
        // スワップ
        String currentOccupant = newOrder[index];
        newOrder[existingIdx] = currentOccupant;
      }
      newOrder[index] = selected;

      final updatedTeam = team.copyWith(playerNames: newOrder);
      await ref.read(teamRepositoryProvider).saveTeam(updatedTeam);
      return updatedTeam;
    }
    return null;
  }

  List<String> _generatePositions(int size) {
    if (size <= 0) return [];
    if (size == 1) return ['選手'];
    if (size == 3) return ['先鋒', '中堅', '大将'];
    if (size == 5) return ['先鋒', '次鋒', '中堅', '副将', '大将'];
    
    List<String> positions = [];
    positions.add('先鋒');
    if (size >= 2) positions.add('次鋒');
    
    for (int i = 3; i <= size - 2; i++) {
      if (size % 2 != 0 && i == (size + 1) ~/ 2) {
        positions.add('中堅');
      } else {
        int k = size - i + 1;
        positions.add('$k将');
      }
    }
    
    if (size >= 4) positions.add('副将');
    if (size >= 3) positions.add('大将');
    
    return positions;
  }

  Widget _buildDynamicSectionBox({required String title, required IconData icon, required Color color, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05), 
        borderRadius: BorderRadius.circular(12), 
        border: Border.all(color: color.withValues(alpha: 0.2))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: color), const SizedBox(width: 8), Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16))]),
          const Divider(),
          child,
        ],
      ),
    );
  }

  List<Widget> _buildExtensionSettings(Color accentColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      const Padding(padding: EdgeInsets.only(top: 8), child: Text('延長回数', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8, runSpacing: 8,
        children: [
          _buildStyledChoiceChip('無制限', _extCount == -2, () => setState(() => _extCount = -2), accentColor),
          _buildStyledChoiceChip('1回', _extCount == 1, () => setState(() => _extCount = 1), accentColor),
          _buildStyledChoiceChip('2回', _extCount == 2, () => setState(() => _extCount = 2), accentColor),
          _buildStyledChoiceChip('任意', _extCount == -1, () => setState(() => _extCount = -1), accentColor),
        ],
      ),
      if (_extCount == -1) ...[
        const SizedBox(height: 12),
        // ★ 修正：inputFormatters を追加
        TextField(
          controller: _customExtCountController, 
          keyboardType: TextInputType.number, 
          inputFormatters: [_NumericInputFormatter()], // ★ 追加
          style: TextStyle(color: isDark ? Colors.white : Colors.black87), 
          decoration: InputDecoration(labelText: '最大延長回数を入力', labelStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF38383A) : Colors.grey.shade400)), suffixText: '回', filled: true, fillColor: isDark ? const Color(0xFF1C1C1E) : Colors.white)
        ),
      ],
      const SizedBox(height: 24),
      
      const Text('延長時間', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8, runSpacing: 8,
        children: [
          _buildStyledChoiceChip('無制限', _extTime == -2.0, () => setState(() => _extTime = -2.0), accentColor),
          ..._mainTimeOptions.map((t) => _buildStyledChoiceChip('${t == 1.5 || t == 2.5 ? t : t.toInt()}分', _extTime == t, () => setState(() => _extTime = t), accentColor)),
          if (_showExtraExtTime) ...[
            ..._extraTimeOptions.map((t) => _buildStyledChoiceChip('${t == 1.5 || t == 2.5 ? t : t.toInt()}分', _extTime == t, () => setState(() => _extTime = t), accentColor)),
            _buildStyledChoiceChip('任意', _extTime == -1.0, () => setState(() => _extTime = -1.0), accentColor),
          ],
          ActionChip(
            avatar: Icon(_showExtraExtTime ? Icons.expand_less : Icons.expand_more, size: 18, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700),
            label: Text(_showExtraExtTime ? '閉じる' : 'もっと見る', style: TextStyle(color: isDark ? Colors.grey.shade300 : Colors.grey.shade700, fontWeight: FontWeight.bold)),
            onPressed: () => setState(() => _showExtraExtTime = !_showExtraExtTime),
            backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade200, 
            side: BorderSide(color: isDark ? const Color(0xFF38383A) : Colors.grey.shade300),
          ),
        ],
      ),
      if (_extTime == -1.0) ...[
        const SizedBox(height: 12),
        // ★ 修正：inputFormatters を追加
        TextField(
          controller: _customExtTimeController, 
          keyboardType: const TextInputType.numberWithOptions(decimal: true), 
          inputFormatters: [_NumericInputFormatter()], // ★ 追加
          style: TextStyle(color: isDark ? Colors.white : Colors.black87), 
          decoration: InputDecoration(labelText: '延長時間（分）を入力', labelStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF38383A) : Colors.grey.shade400)), suffixText: '分', filled: true, fillColor: isDark ? const Color(0xFF1C1C1E) : Colors.white)
        ),
      ],
      const SizedBox(height: 16),
    ];
  }

  // ★ 共通の美しいChip構築メソッド（_buildTimeChipをアップグレードして汎用化）
  Widget _buildStyledChoiceChip(String label, bool isSelected, VoidCallback onSelected, Color accentColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
      selectedColor: isDark ? Colors.teal.shade800.withValues(alpha: 0.5) : accentColor.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected 
            ? (isDark ? Colors.teal.shade100 : Colors.teal.shade900) 
            : (isDark ? Colors.white : Colors.black87), 
        fontWeight: FontWeight.bold
      ),
      side: BorderSide(color: isSelected ? Colors.transparent : (isDark ? const Color(0xFF38383A) : Colors.grey.shade300)),
      onSelected: (s) => s ? onSelected() : null,
    );
  }

  Widget _buildImmersiveAppBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, bottom: 8, left: 16, right: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: Colors.grey.shade800, size: 24),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final t = (_currentPage / 2).clamp(0.0, 1.0); 
        
        // iOS Native: ダークモード時は彩度を抑えた深みのあるTealへ
        final color1 = isDark ? Colors.teal.shade800 : Colors.teal.shade400;
        final color2 = isDark ? Colors.teal.shade900 : Colors.teal.shade700;
        final endColor = isDark ? Colors.teal.shade800 : Colors.teal.shade300;
        
        final gradientColor = Color.lerp(color1, color2, t)!;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [gradientColor, endColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('試合ルールの設定', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.0)),
              const SizedBox(height: 8),
              Text('魔法のウィザードに従って、\n3つのステップで条件を設定しましょう', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w500)),
              const SizedBox(height: 20),
              LinearProgressIndicator(
                value: (_currentPage + 1) / 3,
                backgroundColor: Colors.white.withValues(alpha: 0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : Colors.grey.shade50;

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          _buildImmersiveAppBar(context),
          _buildDynamicHeader(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(), 
              onPageChanged: (index) => setState(() => _currentPage = index),
              children: [
                _buildPage1Category(),
                _buildPage2Format(),
                _buildPage3Details(),
              ],
            ),
          ),
          _buildStickyBottomAction(),
        ],
      ),
    );
  }

  Widget _buildPage1Category() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final inputBgColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final selectedChipColor = isDark ? Colors.teal.shade900.withValues(alpha: 0.5) : Colors.teal.shade100;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        Text(
          '対象のカテゴリと\n自チームを選んでください', 
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.4, color: textColor)
        ),
        const SizedBox(height: 32),
        
        // ★ 修正：カテゴリ大分類
        _buildSectionTitle('1. 対象カテゴリを選択（大分類）'),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _majorCategories.map((cat) => ChoiceChip(
            label: Text(cat, style: TextStyle(fontWeight: _selectedMajorCategory == cat ? FontWeight.bold : FontWeight.normal)), 
            selected: _selectedMajorCategory == cat, 
            selectedColor: selectedChipColor, 
            onSelected: (s) => s ? setState(() { _selectedMajorCategory = cat; _selectedMinorCategory = '全体'; _selectedTeamId = null; }) : null
          )).toList(),
        ),
        const SizedBox(height: 24),
        
        // ★ 修正：カテゴリ小分類（大分類に応じて動的に現れる）
        _buildSectionTitle('2. 対象カテゴリを選択（小分類）'),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _getMinorCategories(_selectedMajorCategory).map((cat) {
            String label = cat;
            if (_selectedMajorCategory == '小学生') {
              if (cat == '低学年') label = '低学年 (1-4年)';
              if (cat == '高学年') label = '高学年 (5-6年)';
            }
            return ChoiceChip(
              label: Text(label, style: TextStyle(fontWeight: _selectedMinorCategory == cat ? FontWeight.bold : FontWeight.normal)), 
              selected: _selectedMinorCategory == cat, 
              selectedColor: selectedChipColor, 
              onSelected: (s) => s ? setState(() { _selectedMinorCategory = cat; _selectedTeamId = null; }) : null
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        
        // ★ 修正：最終的に設定されるカテゴリ名のプレビュー表示
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.teal.shade900.withValues(alpha: 0.2) : Colors.teal.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? Colors.teal.shade800 : Colors.teal.shade200)
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: isDark ? Colors.teal.shade400 : Colors.teal.shade600),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('設定されるカテゴリ名', style: TextStyle(fontSize: 12, color: isDark ? Colors.teal.shade200 : Colors.teal.shade800)),
                    const SizedBox(height: 4),
                    Text(_category, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor)),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 40),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildSectionTitle('3. 出場する自チームを選択'), // ★ 番号を3に修正
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextButton.icon(
                onPressed: () => context.push('/team-registration/${widget.tournamentId}'),
                icon: const Icon(Icons.group_add, size: 18),
                label: const Text('チームを追加・編集', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                style: TextButton.styleFrom(foregroundColor: isDark ? Colors.teal.shade300 : Colors.teal.shade700, padding: const EdgeInsets.symmetric(horizontal: 8)),
              ),
            ),
          ],
        ),
        
        ref.watch(registeredTeamsProvider(widget.tournamentId)).when(
          data: (teams) {
            final filteredTeams = teams.where((t) => t.category == _category).toList();
            
            if (filteredTeams.isEmpty) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                decoration: BoxDecoration(
                  // ★ 修正：赤系の警告色を完全に廃止し、iOS風の上品なEmpty State（空状態）デザインへ
                  color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade50, 
                  borderRadius: BorderRadius.circular(16), 
                  border: Border.all(color: isDark ? const Color(0xFF38383A) : Colors.grey.shade200, width: 1.5)
                ),
                child: Column(
                  children: [
                    Icon(Icons.group_off_outlined, color: isDark ? Colors.grey.shade500 : Colors.grey.shade400, size: 40),
                    const SizedBox(height: 16),
                    Text(
                      '「$_category」のチームが未登録です。\n右上の「チームを追加・編集」から\n登録を行ってください。', 
                      textAlign: TextAlign.center,
                      style: TextStyle(color: isDark ? Colors.grey.shade300 : Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.bold, height: 1.5)
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: filteredTeams.map((team) {
                final isSelected = _selectedTeamId == team.id;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: isSelected ? (isDark ? 0 : 2) : 0,
                  color: isSelected ? (isDark ? Colors.teal.shade900.withValues(alpha: 0.3) : Colors.teal.shade50.withValues(alpha: 0.5)) : inputBgColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isSelected ? Colors.teal.shade400 : (isDark ? const Color(0xFF38383A) : Colors.grey.shade200),
                      width: isSelected ? 2 : 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        onTap: () => setState(() {
                          _selectedTeamId = team.id;
                          _matchType = team.matchType; 
                        }),
                        contentPadding: EdgeInsets.only(left: 20, right: 16, top: 12, bottom: isSelected ? 4 : 12),
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: isSelected ? (isDark ? Colors.teal.shade800 : Colors.teal.shade100) : (isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade100),
                          child: Icon(Icons.shield, color: isSelected ? (isDark ? Colors.teal.shade200 : Colors.teal.shade700) : (isDark ? Colors.grey.shade600 : Colors.grey.shade400), size: 24),
                        ),
                        title: Text(
                          team.teamName, 
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 18,
                            color: isSelected ? (isDark ? Colors.teal.shade100 : Colors.teal.shade900) : textColor,
                          )
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${team.matchType} / 選手: ${team.playerNames.where((n) => n.isNotEmpty).join(", ")}', 
                            style: TextStyle(fontSize: 12, color: isSelected ? (isDark ? Colors.teal.shade300 : Colors.teal.shade700) : (isDark ? Colors.grey.shade500 : Colors.grey.shade600)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        trailing: Icon(
                          isSelected ? Icons.check_circle : Icons.circle_outlined, 
                          color: isSelected ? Colors.teal.shade500 : (isDark ? Colors.grey.shade600 : Colors.grey.shade300),
                          size: 28,
                        ),
                      ),
                      
                      if (isSelected)
                        Padding(
                          padding: const EdgeInsets.only(left: 20, right: 16, bottom: 16, top: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => _showTeamDetailDialog(context, team),
                                icon: Icon(Icons.swap_horizontal_circle, color: isDark ? Colors.teal.shade300 : Colors.teal.shade700, size: 20),
                                label: Text('オーダーを調整', style: TextStyle(color: isDark ? Colors.teal.shade300 : Colors.teal.shade700, fontWeight: FontWeight.bold)),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                                  side: BorderSide(color: isDark ? Colors.teal.shade500 : Colors.teal.shade400, width: 1.5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
          error: (e, s) => Text('エラー: $e', style: TextStyle(color: textColor)),
        ),
      ],
    );
  }

  Widget _buildPage2Format() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final inputBgColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('試合形式の確認と\n時間を設定してください', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.4, color: textColor)),
        const SizedBox(height: 32),
        
        _buildSectionTitle('試合形式（チーム設定より自動適用）'),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? Colors.teal.shade900.withValues(alpha: 0.3) : Colors.teal.shade50.withValues(alpha: 0.5), 
            borderRadius: BorderRadius.circular(16), 
            border: Border.all(color: isDark ? Colors.teal.shade700 : Colors.teal.shade200, width: 2)
          ),
          child: Row(
            children: [
              Icon(Icons.verified, color: isDark ? Colors.teal.shade400 : Colors.teal.shade600, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  _matchType, 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.teal.shade100 : Colors.teal.shade900)
                ),
              ),
            ],
          ),
        ),
        
        if (_matchType == '団体戦（それ以上）') ...[
          const SizedBox(height: 16),
          TextField(
            controller: _customTeamSizeController, 
            keyboardType: TextInputType.number, 
            inputFormatters: [_NumericInputFormatter()], // ★ 追加：全角を自動で半角に変換
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              labelText: 'チームの人数を入力（例：11）', 
              labelStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), 
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF38383A) : Colors.grey.shade400)),
              suffixText: '人制', prefixIcon: Icon(Icons.groups, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600), 
              filled: true, fillColor: inputBgColor
            )
          ),
        ],
        const SizedBox(height: 32),
        
        _buildSectionTitle('試合時間'),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: [
            // ★ 新設した共通メソッド（_buildStyledChoiceChip）にすべて置き換え！
            ..._mainTimeOptions.map((t) => _buildStyledChoiceChip('${t == 1.5 || t == 2.5 ? t : t.toInt()}分', _matchTime == t, () => setState(() => _matchTime = t), Colors.teal.shade600)),
            if (_showExtraMatchTime) ...[
              ..._extraTimeOptions.map((t) => _buildStyledChoiceChip('${t == 1.5 || t == 2.5 ? t : t.toInt()}分', _matchTime == t, () => setState(() => _matchTime = t), Colors.teal.shade600)),
              _buildStyledChoiceChip('任意', _matchTime == -1.0, () => setState(() => _matchTime = -1.0), Colors.teal.shade600),
            ],
            ActionChip(
              avatar: Icon(_showExtraMatchTime ? Icons.expand_less : Icons.expand_more, size: 18, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700),
              label: Text(_showExtraMatchTime ? '閉じる' : 'もっと見る', style: TextStyle(color: isDark ? Colors.grey.shade300 : Colors.grey.shade700, fontWeight: FontWeight.bold)),
              onPressed: () => setState(() => _showExtraMatchTime = !_showExtraMatchTime),
              backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade200, 
              side: BorderSide(color: isDark ? const Color(0xFF38383A) : Colors.grey.shade300),
            ),
          ],
        ),
        if (_matchTime == -1.0) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _customMatchTimeController, 
            keyboardType: const TextInputType.numberWithOptions(decimal: true), 
            inputFormatters: [_NumericInputFormatter()], // ★ 追加
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              labelText: '試合時間（分）を入力', 
              labelStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), 
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF38383A) : Colors.grey.shade400)),
              suffixText: '分', 
              filled: true, fillColor: inputBgColor
            )
          ),
        ],
        const SizedBox(height: 32),
        
        Container(
          decoration: BoxDecoration(color: inputBgColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? const Color(0xFF38383A) : Colors.grey.shade300)),
          child: SwitchListTile(
            title: Text('錬成会モードにする', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
            subtitle: Text('チェックを入れると専用のルール設定が表示されます。', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
            value: _isRenseikai,
            activeThumbColor: isDark ? Colors.teal.shade400 : Colors.teal.shade600,
            onChanged: (v) => setState(() => _isRenseikai = v),
          ),
        ),
      ],
    );
  }

  Widget _buildPage3Details() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final inputBgColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('特別ルールと\n試合のメモを入力します', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.4, color: textColor)),
        
        Builder(
          builder: (context) {
            bool isLeague = _matchType.contains('リーグ');
            bool isKachinuki = _matchType == '勝ち抜き戦';
            bool isIndividual = _matchType.contains('個人戦');
            bool isTeamMatch = _matchType.contains('団体戦') && !isLeague;

            if (_isRenseikai) {
              return _buildDynamicSectionBox(
                title: '錬成会 専用設定', icon: Icons.autorenew, color: Colors.teal.shade700,
                child: Column(
                  children: [
                    const Align(alignment: Alignment.centerLeft, child: Text('試合の進行方式', style: TextStyle(fontWeight: FontWeight.bold))),
                    RadioGroup<String>(
                      groupValue: _renseikaiType,
                      onChanged: (val) { if (val != null) setState(() => _renseikaiType = val); },
                      child: Column(
                        children: [
                          RadioListTile<String>(title: const Text('一試合制'), subtitle: const Text('通常の試合のように、決着がついたら終了'), value: '一試合制', activeColor: Colors.teal.shade600),
                          RadioListTile<String>(title: const Text('時間制'), subtitle: const Text('時間が来るまで、次の対戦者を次々と追加して戦う'), value: '時間制', activeColor: Colors.teal.shade600),
                          if (_renseikaiType == '時間制') 
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: TextField(
                                controller: _overallTimeController, 
                                keyboardType: TextInputType.number, 
                                inputFormatters: [_NumericInputFormatter()], // ★ 追加
                                style: TextStyle(color: textColor),
                                decoration: InputDecoration(
                                  labelText: '錬成会全体の制限時間', 
                                  labelStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                  suffixText: '分間', 
                                  border: const OutlineInputBorder(), 
                                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: isDark ? const Color(0xFF38383A) : Colors.grey)),
                                  isDense: true
                                )
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Divider(),
                    SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('ランニング計測', style: TextStyle(fontWeight: FontWeight.bold)), subtitle: const Text('審判の「止め」でも時間は進み続けます'), value: _isRunningTime, activeThumbColor: Colors.teal.shade600, onChanged: (val) => setState(() => _isRunningTime = val)),
                  ],
                ),
              );
            } else if (isTeamMatch) {
              return _buildDynamicSectionBox(
                title: '代表戦の取り扱い（通常団体戦）', icon: Icons.shield, color: Colors.teal.shade700,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(padding: EdgeInsets.only(top: 8, bottom: 4, left: 16), child: Text('代表戦の勝敗数', style: TextStyle(fontWeight: FontWeight.bold))),
                    RadioGroup<bool>(
                      groupValue: _isDaihyoIpponShobu,
                      onChanged: (v) { if (v != null) setState(() => _isDaihyoIpponShobu = v); },
                      child: Row(
                        children: [
                          Expanded(child: RadioListTile<bool>(title: const Text('1本勝負'), value: true, activeColor: Colors.teal.shade600, contentPadding: const EdgeInsets.only(left: 8))),
                          Expanded(child: RadioListTile<bool>(title: const Text('3本勝負'), value: false, activeColor: Colors.teal.shade600, contentPadding: EdgeInsets.zero)),
                        ],
                      ),
                    ),
                    const Divider(),
                    SwitchListTile(title: const Text('延長戦を行う'), value: _hasExtension, activeThumbColor: Colors.teal.shade600, onChanged: (v) => setState(() => _hasExtension = v), contentPadding: EdgeInsets.zero),
                    if (_hasExtension) ..._buildExtensionSettings(Colors.teal.shade600),
                    SwitchListTile(title: const Text('延長戦で決着がつかない場合に「判定」を行う'), value: _hasHantei, activeThumbColor: Colors.teal.shade600, onChanged: (v) => setState(() => _hasHantei = v), contentPadding: EdgeInsets.zero),
                  ],
                ),
              );
            } else if (isIndividual) {
              return _buildDynamicSectionBox(
                title: '延長戦と判定（個人戦）', icon: Icons.person, color: Colors.teal.shade700,
                child: Column(
                  children: [
                    SwitchListTile(title: const Text('延長戦を行う'), value: _hasExtension, activeThumbColor: Colors.teal.shade600, onChanged: (v) => setState(() => _hasExtension = v), contentPadding: EdgeInsets.zero),
                    if (_hasExtension) ..._buildExtensionSettings(Colors.teal.shade600),
                    SwitchListTile(title: const Text('決着がつかない場合に「判定」を行う'), value: _hasHantei, activeThumbColor: Colors.teal.shade600, onChanged: (v) => setState(() => _hasHantei = v), contentPadding: EdgeInsets.zero),
                  ],
                ),
              );
            } else if (isKachinuki) {
              return _buildDynamicSectionBox(
                title: '無制限ルール（勝ち抜き戦）', icon: Icons.sports_martial_arts, color: Colors.teal.shade700,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RadioGroup<String>(
                      groupValue: _kachinukiUnlimitedType,
                      onChanged: (val) { if (val != null) setState(() => _kachinukiUnlimitedType = val); },
                      child: Column(
                        children: [
                          RadioListTile<String>(title: const Text('大将対大将のときに無制限'), value: '大将対大将', activeColor: Colors.teal.shade600, contentPadding: EdgeInsets.zero),
                          RadioListTile<String>(title: const Text('どちらかの大将が出たら無制限'), value: 'どちらかの大将', activeColor: Colors.teal.shade600, contentPadding: EdgeInsets.zero),
                          RadioListTile<String>(title: const Text('大将対大将が引き分けのとき、１本勝負の延長戦'), value: '大将引き分け延長', activeColor: Colors.teal.shade600, contentPadding: EdgeInsets.zero),
                        ],
                      ),
                    ),
                    if (_kachinukiUnlimitedType == '大将引き分け延長') ...[
                      const Divider(),
                      const Padding(
                        padding: EdgeInsets.only(top: 8, bottom: 8),
                        child: Text('延長戦の設定', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                      ),
                      ..._buildExtensionSettings(Colors.teal.shade600),
                    ]
                  ],
                ),
              );
            } else if (isLeague) {
              return _buildDynamicSectionBox(
                title: 'リーグ戦 特別ルール', icon: Icons.table_view, color: Colors.teal.shade700,
                child: SwitchListTile(title: const Text('代表戦あり'), subtitle: const Text('リーグ戦において同点の場合に代表戦を行うか'), value: _hasLeagueDaihyo, activeThumbColor: Colors.teal.shade600, onChanged: (v) => setState(() => _hasLeagueDaihyo = v), contentPadding: EdgeInsets.zero),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        const SizedBox(height: 32),

        _buildSectionTitle('試合詳細（任意）'),
        TextField(
          controller: _noteController,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: '例：1回戦 第3試合、準決勝 など',
            hintStyle: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF38383A) : Colors.grey.shade400)),
            prefixIcon: Icon(Icons.edit_note, color: isDark ? Colors.teal.shade400 : Colors.teal.shade600),
            filled: true, fillColor: inputBgColor,
          ),
        ),
        const SizedBox(height: 12),
        Consumer(
          builder: (context, ref, child) {
            final history = ref.watch(noteHistoryProvider);
            return Wrap(
              spacing: 8, runSpacing: 8,
              children: history.map((note) => ActionChip(
                label: Text(note, style: TextStyle(color: isDark ? Colors.teal.shade100 : Colors.teal.shade800, fontSize: 13, fontWeight: FontWeight.bold)),
                backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.teal.shade50,
                side: BorderSide(color: isDark ? const Color(0xFF38383A) : Colors.teal.shade100),
                avatar: Icon(Icons.add, size: 16, color: isDark ? Colors.teal.shade300 : Colors.teal.shade500),
                onPressed: () {
                  final currentText = _noteController.text;
                  _noteController.text = currentText.isEmpty ? note : '$currentText $note';
                  _noteController.selection = TextSelection.fromPosition(TextPosition(offset: _noteController.text.length));
                },
              )).toList(),
            );
          },
        ),
        const SizedBox(height: 48),
      ],
    );
  }

  Widget _buildStickyBottomAction() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLastPage = _currentPage == 2;
    
    // iOS Native: ボトムバーの色と区切り線
    final bottomColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF38383A) : Colors.grey.shade300;

    return Container(
      padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: bottomColor,
        border: Border(top: BorderSide(color: borderColor, width: 0.5)),
      ),
      child: Row(
        children: [
          if (_currentPage > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: OutlinedButton(
                onPressed: () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16), 
                  shape: const CircleBorder(), 
                  side: BorderSide(color: borderColor),
                ),
                child: Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.teal.shade500), // ダークでも見やすいTeal
              ),
            ),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                if (!isLastPage) {
                  if (_currentPage == 0 && _selectedTeamId == null) {
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('出場する自チームを選択してください')));
                     return;
                  }
                  _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                } else {
                  final newNote = _noteController.text.trim();
                  if (newNote.isNotEmpty) {
                    final words = newNote.split(' ');
                    final currentHistory = ref.read(noteHistoryProvider);
                    final updatedHistory = {...words, ...currentHistory}.toList().take(10).toList();
                    ref.read(noteHistoryProvider.notifier).state = updatedHistory;
                  }

                  int teamSize = 5;
                  bool isLeague = _matchType.contains('リーグ');
                  bool isKachinuki = _matchType == '勝ち抜き戦';

                  if (_matchType == '団体戦（3人制）') {
                    teamSize = 3;
                  } else if (_matchType == '個人戦' || _matchType == 'リーグ個人戦') {
                    teamSize = 1;
                  } else if (_matchType == '団体戦（7人制）') {
                    teamSize = 7;
                  } else if (_matchType == '団体戦（それ以上）') {
                    teamSize = int.tryParse(_customTeamSizeController.text) ?? 9;
                  }

                  final generatedPositions = _generatePositions(teamSize);
                  double finalTime = _matchTime == -1.0 ? (double.tryParse(_customMatchTimeController.text) ?? 3.0) : _matchTime;

                  // ★ 修正：錬成会以外のときは強制的にランニング計測をOFFにする（隠れランニング計測バグの完全防止）
                  bool finalIsRunningTime = _isRenseikai ? _isRunningTime : false;

                  // ★ 修正：延長回数と延長時間も確実に保存するようにします
                  ref.read(lastUsedSettingsProvider.notifier).state = {
                    'matchType': _matchType, 
                    'category': _category, 
                    'matchTime': finalTime, 
                    'isRunningTime': finalIsRunningTime,
                    'hasExtension': _hasExtension, 
                    'hasHantei': _hasHantei, 
                    'extensionCount': _extCount == -1 ? (int.tryParse(_customExtCountController.text) ?? 1) : _extCount,
                    'extensionTimeMinutes': _extTime == -1.0 ? (double.tryParse(_customExtTimeController.text) ?? 3.0) : _extTime,
                    'isRenseikai': _isRenseikai, 
                    'kachinukiUnlimitedType': _kachinukiUnlimitedType, 
                    'hasLeagueDaihyo': _hasLeagueDaihyo, 
                    'renseikaiType': _renseikaiType,
                    'isDaihyoIpponShobu': _isDaihyoIpponShobu, 
                  };

                  List<String> selectedBaseOrder = [];
                  String teamNamePrefix = '';
                  if (_selectedTeamId != null) {
                    final teams = ref.read(registeredTeamsProvider(widget.tournamentId)).value ?? [];
                    for (var t in teams) {
                      if (t.id == _selectedTeamId) {
                        selectedBaseOrder = t.playerNames;
                        teamNamePrefix = t.teamName;
                        break;
                      }
                    }
                  }

                  ref.read(matchRuleProvider.notifier).updateRule(MatchRule(
                    positions: generatedPositions, matchTimeMinutes: finalTime.toInt(), isRunningTime: finalIsRunningTime,
                    isLeague: isLeague, category: _category, note: _noteController.text, isRenseikai: _isRenseikai, 
                    baseOrder: selectedBaseOrder, teamName: teamNamePrefix, isKachinuki: isKachinuki, 
                    kachinukiUnlimitedType: _kachinukiUnlimitedType, hasLeagueDaihyo: _hasLeagueDaihyo, 
                    renseikaiType: _renseikaiType, overallTimeMinutes: int.tryParse(_overallTimeController.text) ?? 30,
                    isDaihyoIpponShobu: _isDaihyoIpponShobu,
                  ));

                  context.push('/order-setup/${widget.tournamentId}');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade600, foregroundColor: Colors.white, 
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0,
              ),
              child: Text(isLastPage ? 'このルールで枠を作成' : '次へ進む', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12), 
      child: Text(
        title, 
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.teal.shade300 : Colors.teal.shade800)
      )
    );
  }
}

// ★ 追加：全角数字を半角に、句読点をドットに瞬時に変換する魔法のフォーマッター
class _NumericInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text;
    
    // 全角数字と全角ドット・句読点を半角に変換
    const fullToHalf = {
      '０':'0', '１':'1', '２':'2', '３':'3', '４':'4',
      '５':'5', '６':'6', '７':'7', '８':'8', '９':'9',
      '．':'.', '。':'.', '、':'.'
    };
    fullToHalf.forEach((k, v) => text = text.replaceAll(k, v));
    
    // 半角数字とドット以外をすべて削除（安全対策）
    text = text.replaceAll(RegExp(r'[^0-9.]'), '');
    
    return TextEditingValue(
      text: text, 
      selection: TextSelection.collapsed(offset: text.length)
    );
  }
}