import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/team_model.dart';
import '../repositories/team_repository.dart';
import '../models/player_model.dart';
import '../repositories/player_repository.dart';
import '../providers/team_name_history_provider.dart'; // ★ 追加：履歴プロバイダ
import '../utils/text_sanitizer.dart'; // ★ お掃除フィルターを追加

// ★ 安定したProvider定義
final registeredTeamsProvider = StreamProvider.family.autoDispose<List<TeamModel>, String>((ref, tournamentId) {
  return ref.watch(teamRepositoryProvider).watchTeamsByTournament(tournamentId);
});

final playerListProvider = StreamProvider.autoDispose<List<PlayerModel>>((ref) {
  return ref.watch(playerRepositoryProvider).getPlayers();
});

// ★ 追加：登録した「よく使う自チーム名」をマスタから取得するプロバイダー
final customTeamNamesProvider = StreamProvider.autoDispose<List<String>>((ref) {
  return ref.watch(playerRepositoryProvider).watchCustomTeamNames();
});

class TeamRegistrationScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  const TeamRegistrationScreen({super.key, required this.tournamentId});

  @override
  ConsumerState<TeamRegistrationScreen> createState() => _TeamRegistrationScreenState();
}

class _TeamRegistrationScreenState extends ConsumerState<TeamRegistrationScreen> {
  // ★ 修正：2段階選択用の状態（初期値を「小学生」に）
  String _selectedMajorCategory = '小学生';
  String _selectedMinorCategory = '低学年';

  // ★ 修正：最終的なカテゴリ名を生成。マスタ画面の判定と文字列を100%一致させる
  String get _selectedCategory {
    if (_selectedMajorCategory == '初心者') return '初心者の部';
    if (_selectedMajorCategory == '幼年') return '幼年の部';
    if (_selectedMinorCategory == '全体') return '$_selectedMajorCategoryの部';
    if (_selectedMajorCategory == '大学・一般') return '$_selectedMinorCategoryの部';
    return '$_selectedMajorCategory$_selectedMinorCategoryの部';
  }

  // ★ 修正：編集時に文字列からUI状態を復元するロジック
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
    for (var major in ['幼年', '小学生', '中学生', '高校生']) {
      if (cleanCat.startsWith(major)) {
        _selectedMajorCategory = major;
        final minor = cleanCat.substring(major.length);
        _selectedMinorCategory = minor.isEmpty ? '全体' : minor;
        return;
      }
    }
  }

  // ★ 修正：カテゴリ大分類を分け、「もっと見る」対応にする
  final List<String> _mainMajorCategories = ['初心者', '幼年', '小学生', '中学生'];
  final List<String> _extraMajorCategories = ['高校生', '大学・一般'];
  bool _showExtraMajorCategories = false;

  List<String> _getMinorCategories(String major) {
    if (major == '初心者' || major == '幼年') return ['全体', '男子', '女子'];
    if (major == '小学生') return ['全体', '低学年', '高学年', '1年', '2年', '3年', '4年', '5年', '6年', '男子', '女子'];
    if (major == '中学生' || major == '高校生') return ['全体', '1年', '2年', '3年', '男子', '女子'];
    if (major == '大学・一般') return ['全体', '大学生', '一般', 'シニア', '男子', '女子'];
    return ['全体'];
  }

  String _matchType = '団体戦（5人制）';
  String? _editingTeamId; 
  
  int _substituteCount = 0;
  
  final _teamNameController = TextEditingController();
  
  // ★ 修正：ルール設定画面と完全に一致するよう「勝ち抜き戦」と「団体戦（それ以上）」を追加
  final List<String> _mainMatchTypes = ['団体戦（5人制）', '団体戦（3人制）', '勝ち抜き戦', '個人戦'];
  final List<String> _extraMatchTypes = ['リーグ団体戦', 'リーグ個人戦', '団体戦（7人制）', '団体戦（それ以上）'];
  bool _showExtraMatchTypes = false;

  final Map<int, String> _tempSelectedPlayers = {};

  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _teamNameController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // ★ 没入型AppBar
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

  // ★ Tealグラデーションヘッダー
  Widget _buildDynamicHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final t = (_currentPage / 2).clamp(0.0, 1.0); 
        final gradientColor = Color.lerp(Colors.teal.shade400, Colors.teal.shade700, t)!;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [gradientColor, Colors.teal.shade300],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('チームとオーダー登録', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.0)),
              const SizedBox(height: 8),
              Text('魔法のウィザードに従って、\n3つのステップで編成を完了しましょう', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w500)),
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

  // ★ 修正：カテゴリ連動フィルタリング ＋ よみがな順ソートを搭載した最強の選択ダイアログ
  Future<void> _selectPlayerDialog(int index, List<PlayerModel> players, List<String> posNames) async {
    final TextEditingController customNameController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBgColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final inputBgColor = isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade50;
    final borderColor = isDark ? const Color(0xFF38383A) : Colors.grey.shade300;

    // 手入力選手の抽出
    final helperEntries = _tempSelectedPlayers.entries
        .where((e) => e.value.isNotEmpty && e.value != '欠員')
        .where((e) => !players.any((p) => p.name == e.value))
        .toList();

    bool showAllPlayers = false; // フィルタ解除フラグ

    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder( // 内部で「全員表示」を切り替えるため
        builder: (context, setStateBottomSheet) {
          
          // --- フィルタリングロジックの実行 ---
          List<PlayerModel> displayList = players;
          if (!showAllPlayers) {
            if (_selectedMajorCategory == '初心者') {
              displayList = players.where((p) => p.isBeginner).toList();
            } else if (_selectedMajorCategory == '幼年') {
              displayList = players.where((p) => p.grade == 0).toList();
            } else if (_selectedMajorCategory == '小学生') {
              if (_selectedMinorCategory == '低学年') {
                displayList = players.where((p) => p.grade >= 1 && p.grade <= 4).toList();
              } else if (_selectedMinorCategory == '高学年') {
                displayList = players.where((p) => p.grade >= 5 && p.grade <= 6).toList();
              } else if (_selectedMinorCategory.contains('年')) {
                int targetGrade = int.tryParse(_selectedMinorCategory.replaceAll('年', '')) ?? 0;
                displayList = players.where((p) => p.grade == targetGrade).toList();
              } else {
                displayList = players.where((p) => p.grade >= 1 && p.grade <= 6).toList();
              }
            } else if (_selectedMajorCategory == '中学生') {
              displayList = players.where((p) => p.grade >= 7 && p.grade <= 9).toList();
            } else if (_selectedMajorCategory == '高校生') {
              displayList = players.where((p) => p.grade >= 10 && p.grade <= 12).toList();
            } else if (_selectedMajorCategory == '大学・一般') {
              displayList = players.where((p) => p.grade >= 13).toList();
            }
          }

          // よみがな順でソート（常に美しく並ぶ）
          displayList.sort((a, b) => a.nameKana.compareTo(b.nameKana));

          // ★ Phase 8-3: BottomSheetをキーボードの上に「スライド」させる魔法
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              // 固定heightをやめ、maxHeightにすることでキーボード分上に持ち上がる
              constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
              decoration: BoxDecoration(color: sheetBgColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
              padding: const EdgeInsets.only(top: 16, left: 24, right: 24),
              child: Column(
                children: [
                  Container(width: 48, height: 5, decoration: BoxDecoration(color: borderColor, borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 24),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text('選手の選択 (${posNames[index]})', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor))),
                    // ★ 修正：フィルタ切り替えボタン
                    TextButton.icon(
                      onPressed: () => setStateBottomSheet(() => showAllPlayers = !showAllPlayers),
                      icon: Icon(showAllPlayers ? Icons.filter_alt : Icons.filter_alt_off, size: 14),
                      label: Text(showAllPlayers ? 'フィルタ適用' : '全員表示', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      style: TextButton.styleFrom(foregroundColor: Colors.teal.shade700, backgroundColor: Colors.teal.withValues(alpha: 0.05)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // 助っ人直接入力
                TextField(
                  controller: customNameController,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: '助っ人の名前を直接入力',
                    prefixIcon: Icon(Icons.person_add_alt_1, color: Colors.teal.shade700),
                    suffixIcon: Padding(
                      padding: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, customNameController.text),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade600, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0),
                        child: const Text('確定'),
                      ),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true, fillColor: inputBgColor,
                  ),
                ),
                const SizedBox(height: 24),

                Expanded(
                  child: ListView(
                    children: [
                      if (helperEntries.isNotEmpty) ...[
                        Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('現在チームにいる手入力選手', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange.shade800))),
                        ...helperEntries.map((entry) {
                          if (entry.key == index) return const SizedBox.shrink();
                          return _buildSelectionCard(entry.value, '手入力選手', isUsed: true, usedPos: posNames[entry.key], isDark: isDark, isHelper: true, onTap: () => Navigator.pop(ctx, entry.value));
                        }),
                        const SizedBox(height: 16),
                      ],

                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8), 
                        child: Text(showAllPlayers ? '名簿の全選手' : 'おすすめの選手', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal.shade800))
                      ),
                      
                      // 欠員・未定ボタン
                      Row(
                        children: [
                          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx, 'CLEAR_FLAG'), child: const Text('未定'))),
                          const SizedBox(width: 12),
                          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx, '欠員'), style: OutlinedButton.styleFrom(foregroundColor: Colors.red), child: const Text('欠員'))),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (displayList.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(Icons.person_search, size: 48, color: Colors.grey.withValues(alpha: 0.3)),
                              const SizedBox(height: 16),
                              Text('該当する選手がいません', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                            ],
                          ),
                        ),

                      ...displayList.map((p) {
                        int? usedIdx;
                        _tempSelectedPlayers.forEach((k, v) { if (v == p.name) usedIdx = k; });
                        final isUsed = usedIdx != null && usedIdx != index;

                        return _buildSelectionCard(
                          p.name, 
                          '${p.gradeName}${p.isBeginner ? " (🔰初心者)" : ""}', 
                          isUsed: isUsed, 
                          usedPos: usedIdx != null ? (usedIdx! < posNames.length ? posNames[usedIdx!] : '補欠') : '',
                          isDark: isDark,
                          isBeginner: p.isBeginner,
                          onTap: () => Navigator.pop(ctx, p.name)
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          );
        }
      ),
    );
    if (selected == 'CLEAR_FLAG') {
      setState(() => _tempSelectedPlayers.remove(index));
    } else if (selected != null && selected.trim().isNotEmpty) {
      setState(() {
        int existingIndex = -1;
        _tempSelectedPlayers.forEach((key, value) {
          if (value == selected) existingIndex = key;
        });

        if (existingIndex != -1 && existingIndex != index) {
          final currentOccupant = _tempSelectedPlayers[index];
          if (currentOccupant != null) {
            _tempSelectedPlayers[existingIndex] = currentOccupant;
          } else {
            _tempSelectedPlayers.remove(existingIndex);
          }
        }
        _tempSelectedPlayers[index] = selected;
      });
    }
  }

  // ★ 追加：選手選択ダイアログ内の共通カードUI
  Widget _buildSelectionCard(
    String name,
    String subtitle, {
    required bool isUsed,
    required String usedPos,
    required bool isDark,
    bool isHelper = false,
    bool isBeginner = false,
    required VoidCallback onTap,
  }) {
    final textColor = isDark ? Colors.white : Colors.black87;

    // 状態に応じて色を決定 (助っ人 or 使用済み or 選択可能)
    final Color cardColor;
    final Color borderColor;
    final Color leadingTextColor;
    final Color subtitleColor;

    if (isHelper || isUsed) {
      cardColor = isDark ? Colors.orange.shade900.withAlpha(77) : Colors.orange.shade50.withAlpha(128);
      borderColor = isDark ? Colors.transparent : Colors.orange.shade100;
      leadingTextColor = isDark ? Colors.orange.shade400 : Colors.orange.shade700;
      subtitleColor = Colors.orange;
    } else {
      cardColor = isDark ? Colors.teal.shade900.withAlpha(77) : Colors.teal.shade50.withAlpha(128);
      borderColor = isDark ? Colors.transparent : Colors.teal.shade100;
      leadingTextColor = isDark ? Colors.teal.shade400 : Colors.teal.shade700;
      subtitleColor = Colors.teal.shade600;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
          child: Text(
            name.isNotEmpty ? name.substring(0, 1) : '？',
            style: TextStyle(color: leadingTextColor, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: subtitleColor, fontWeight: isHelper ? FontWeight.bold : FontWeight.normal)),
        trailing: (isHelper || isUsed)
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.shade200)),
                child: Text('$usedPosと入替', style: TextStyle(color: Colors.orange.shade700, fontSize: 11, fontWeight: FontWeight.bold)),
              )
            : Icon(Icons.check_circle_outline, color: Colors.teal.shade600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerListAsync = ref.watch(playerListProvider);
    final registeredTeamsAsync = ref.watch(registeredTeamsProvider(widget.tournamentId));

    int basePlayerCount = 5;
    List<String> posNames = ['先鋒', '次鋒', '中堅', '副将', '大将'];
    if (_matchType.contains('3人制')) {
      basePlayerCount = 3; posNames = ['先鋒', '中堅', '大将'];
    } else if (_matchType.contains('個人戦')) {
      basePlayerCount = 1; posNames = ['選手'];
    } else if (_matchType.contains('7人制')) {
      basePlayerCount = 7; posNames = ['先鋒', '次鋒', '五将', '中堅', '三将', '副将', '大将'];
    }

    // ★ 新機能：ベースの人数に補欠の人数を足す
    int totalPlayerCount = basePlayerCount + _substituteCount;
    for (int i = 0; i < _substituteCount; i++) {
      posNames.add('補欠'); // 役職名として「補欠」を追加
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ★ Phase 8-3: キーボードが開いているかを検知
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF2F2F7),
      body: Column(
        children: [
          // ★ キーボードが開いた時はヘッダーをスッと隠し、入力エリアを最大化する
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: isKeyboardOpen ? const SizedBox.shrink() : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildImmersiveAppBar(context),
                _buildDynamicHeader(),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(), 
              onPageChanged: (index) => setState(() => _currentPage = index),
              children: [
                _buildPage1CategoryFormat(),
                playerListAsync.when(
                  data: (players) => _buildPage2TeamAndOrder(totalPlayerCount, posNames, players), 
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Center(child: Text('エラー: $e')),
                ),
                _buildPage3Confirm(registeredTeamsAsync, totalPlayerCount), 
              ],
            ),
          ),
          // ★ キーボードが開いた時は下のボタンも隠し、画面を押し潰さないようにする
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: isKeyboardOpen ? const SizedBox.shrink() : _buildStickyBottomAction(totalPlayerCount),
          ),
        ],
      ),
    );
  }

  // ===== ウィザード構成部品 =====

  Widget _buildPage1CategoryFormat() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final selectedChipColor = isDark ? Colors.teal.shade900.withValues(alpha: 0.5) : Colors.teal.shade100;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('出場するカテゴリと\n試合形式を選んでください', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.4, color: textColor)),
        const SizedBox(height: 32),
        
        // ★ 修正：カテゴリ大分類
        _buildSectionTitle('1. 出場カテゴリ（大分類）'),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: [
            ..._mainMajorCategories.map((cat) => ChoiceChip(
              label: Text(cat, style: TextStyle(fontWeight: _selectedMajorCategory == cat ? FontWeight.bold : FontWeight.normal)), 
              selected: _selectedMajorCategory == cat, 
              selectedColor: selectedChipColor, 
              onSelected: (s) => s ? setState(() { _selectedMajorCategory = cat; _selectedMinorCategory = '全体'; }) : null
            )),
            if (_showExtraMajorCategories)
              ..._extraMajorCategories.map((cat) => ChoiceChip(
                label: Text(cat, style: TextStyle(fontWeight: _selectedMajorCategory == cat ? FontWeight.bold : FontWeight.normal)), 
                selected: _selectedMajorCategory == cat, 
                selectedColor: selectedChipColor, 
                onSelected: (s) => s ? setState(() { _selectedMajorCategory = cat; _selectedMinorCategory = '全体'; }) : null
              )),
            ActionChip(
              avatar: Icon(_showExtraMajorCategories ? Icons.expand_less : Icons.expand_more, size: 18), 
              label: Text(_showExtraMajorCategories ? '閉じる' : 'もっと見る', style: const TextStyle(fontSize: 12)), 
              onPressed: () => setState(() => _showExtraMajorCategories = !_showExtraMajorCategories)
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // ★ 修正：カテゴリ小分類（大分類に応じて動的に現れる）
        _buildSectionTitle('2. 出場カテゴリ（小分類）'),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _getMinorCategories(_selectedMajorCategory).map((cat) {
            // ★ 小学生の時だけ、学年範囲をラベルに補足（内部データは変えない）
            String label = cat;
            if (_selectedMajorCategory == '小学生') {
              if (cat == '低学年') label = '低学年 (1-4年)';
              if (cat == '高学年') label = '高学年 (5-6年)';
            }
            return ChoiceChip(
              label: Text(label, style: TextStyle(fontWeight: _selectedMinorCategory == cat ? FontWeight.bold : FontWeight.normal)), 
              selected: _selectedMinorCategory == cat, 
              selectedColor: selectedChipColor, 
              onSelected: (s) => s ? setState(() => _selectedMinorCategory = cat) : null
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        
        // ★ 修正：最終的に生成されるカテゴリ名のプレビュー表示
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
                    Text('生成されるカテゴリ名', style: TextStyle(fontSize: 12, color: isDark ? Colors.teal.shade200 : Colors.teal.shade800)),
                    const SizedBox(height: 4),
                    Text(_selectedCategory, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _buildSectionTitle('3. 試合形式'),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: [
            ..._mainMatchTypes.map((type) => ChoiceChip(label: Text(type), selected: _matchType == type, selectedColor: selectedChipColor, 
              // ★ 形式変更時に補欠カウントもリセットする
              onSelected: (s) => s ? setState(() { _matchType = type; _tempSelectedPlayers.clear(); _substituteCount = 0; }) : null
            )),
            if (_showExtraMatchTypes) ..._extraMatchTypes.map((type) => ChoiceChip(label: Text(type), selected: _matchType == type, selectedColor: selectedChipColor, 
              onSelected: (s) => s ? setState(() { _matchType = type; _tempSelectedPlayers.clear(); _substituteCount = 0; }) : null
            )),
            ActionChip(avatar: Icon(_showExtraMatchTypes ? Icons.expand_less : Icons.expand_more, size: 18), label: Text(_showExtraMatchTypes ? '閉じる' : 'もっと見る', style: const TextStyle(fontSize: 12)), onPressed: () => setState(() => _showExtraMatchTypes = !_showExtraMatchTypes)),
          ],
        ),
      ],
    );
  }

  Widget _buildPage2TeamAndOrder(int playerCount, List<String> posNames, List<PlayerModel> players) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final inputBgColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF38383A) : Colors.grey.shade200;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        Text('チーム名とオーダーを\n入力してください', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.4, color: textColor)),
        const SizedBox(height: 24),
        // ★ 修正：通常のTextFieldと履歴チップを廃止し、マスタ連動のサジェスト入力に統合！
        _buildTeamAutocomplete(
          controller: _teamNameController,
          suggestions: ref.watch(customTeamNamesProvider).value ?? [],
          labelText: 'チーム名 (例: 道上剣友会A)',
          hintText: 'タップして登録済みリストから選択',
          fillColor: inputBgColor,
          borderColor: borderColor,
          textColor: textColor,
          subTextColor: Colors.teal.shade700,
          isDark: isDark,
        ),
        const SizedBox(height: 32),
        _buildSectionTitle('オーダー編成（タップして選択）'),
        Container(
          decoration: BoxDecoration(
            color: inputBgColor, 
            borderRadius: BorderRadius.circular(12), 
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: List.generate(playerCount, (index) {
              // ★ 補欠かどうかの判定
              final bool isSubstitute = index >= (playerCount - _substituteCount);

              return Column(
                children: [
                  ListTile(
                    // ★ 変更：役職名(posNames)もダイアログに渡す
                    onTap: () => _selectPlayerDialog(index, players, posNames),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), 
                    leading: CircleAvatar(
                      radius: 22,
                      // 補欠枠は少し色を変えて差別化
                      backgroundColor: isSubstitute ? (isDark ? Colors.orange.shade900.withValues(alpha: 0.3) : Colors.orange.shade50) : (isDark ? Colors.teal.shade900.withValues(alpha: 0.3) : Colors.teal.shade50), 
                      child: Text(
                        isSubstitute ? '補' : posNames[index].substring(0, 1), 
                        style: TextStyle(color: isSubstitute ? (isDark ? Colors.orange.shade400 : Colors.orange.shade700) : (isDark ? Colors.teal.shade400 : Colors.teal.shade700), fontWeight: FontWeight.bold, fontSize: 16)
                      )
                    ),
                    title: Text(
                      _tempSelectedPlayers[index] ?? '未選択', 
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold, 
                        color: _tempSelectedPlayers[index] == null ? (isDark ? Colors.grey.shade600 : Colors.grey.shade400) : textColor
                      )
                    ),
                    subtitle: Text(
                      posNames[index],
                      style: TextStyle(color: isSubstitute ? Colors.orange.shade600 : Colors.teal.shade600, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    // 補欠行には「削除」ボタンを表示
                    trailing: isSubstitute
                        ? IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                            tooltip: 'この補欠枠を削除',
                            onPressed: () {
                              setState(() {
                                // ★ 削除時の詰め処理を汎用化（MAX4名など複数対応）
                                for (int i = index; i < playerCount - 1; i++) {
                                  if (_tempSelectedPlayers.containsKey(i + 1)) {
                                    _tempSelectedPlayers[i] = _tempSelectedPlayers[i + 1]!;
                                  } else {
                                    _tempSelectedPlayers.remove(i);
                                  }
                                }
                                // 一番後ろの枠を消去
                                _tempSelectedPlayers.remove(playerCount - 1);
                                _substituteCount--;
                              });
                            },
                          )
                        : const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ),
                  if (index < playerCount - 1) 
                    Divider(height: 1, indent: 20, endIndent: 20, color: isDark ? const Color(0xFF38383A) : Colors.grey.shade100),
                ],
              );
            }),
          ),
        ),
        
        // ★ 上限を4名に変更
        if (_substituteCount < 4 && !_matchType.contains('個人戦')) ...[
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _substituteCount++),
              icon: Icon(Icons.person_add_alt_1, color: Colors.teal.shade600, size: 18),
              // ★ ラベルも 4 に変更
              label: Text('補欠を追加 ($_substituteCount/4)', style: TextStyle(color: Colors.teal.shade700, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: isDark ? const Color(0xFF38383A) : Colors.teal.shade300, width: 1.5),
                backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.teal.shade50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          )
        ],
      ],
    );
  }

  Widget _buildPage3Confirm(AsyncValue<List<TeamModel>> registeredTeamsAsync, int playerCount) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final inputBgColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF38383A) : Colors.grey.shade300;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('登録内容の確認と\n登録済みの一覧です', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.4, color: textColor)),
        const SizedBox(height: 32),
        _buildSectionTitle('今回登録するチームのプレビュー'),
        Card(
          elevation: 0, 
          color: inputBgColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.teal.shade400, width: 2)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text('$_selectedCategory : ${_teamNameController.text.isEmpty ? "(チーム名未入力)" : _teamNameController.text}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8), 
              child: Text('$_matchType\n選手: ${List.generate(playerCount, (i) => _tempSelectedPlayers[i] ?? '').where((n) => n.isNotEmpty).join(", ")}', style: TextStyle(height: 1.5, color: isDark ? Colors.grey.shade300 : Colors.grey.shade800))
            ),
          ),
        ),
        const SizedBox(height: 32),
        _buildSectionTitle('現在の登録済み一覧'),
        registeredTeamsAsync.when(
          data: (teams) {
            if (teams.isEmpty) return const Text('まだ登録されたチームはありません', style: TextStyle(color: Colors.grey));
            return Column(
              children: teams.map((t) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                elevation: 0,
                color: inputBgColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: borderColor)),
                child: ListTile(
                  title: Text('${t.category} : ${t.teamName}', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                  subtitle: Text('${t.matchType} / 選手: ${t.playerNames.where((n) => n.isNotEmpty).join(", ")}', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.teal.shade600),
                        onPressed: () {
                          setState(() {
                            _editingTeamId = t.id; 
                            _parseCategoryToState(t.category); // ★ 修正：逆算して大分類と小分類を美しく復元
                            _matchType = t.matchType; 
                            _teamNameController.text = t.teamName;
                            _tempSelectedPlayers.clear();
                            for (int i = 0; i < t.playerNames.length; i++) { _tempSelectedPlayers[i] = t.playerNames[i]; }
                            
                            // ★ 編集時に補欠の人数を逆算して復元する（上限4へ変更）
                            int baseLen = 5;
                            if (t.matchType.contains('3人制')) {
                              baseLen = 3;
                            } else if (t.matchType.contains('個人戦')) {
                              baseLen = 1;
                            } else if (t.matchType.contains('7人制')) {
                              baseLen = 7;
                            }
                            _substituteCount = (t.playerNames.length - baseLen).clamp(0, 4);

                            _currentPage = 0; 
                          });
                          _pageController.jumpToPage(0);
                        },
                      ),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => ref.read(teamRepositoryProvider).deleteTeam(t.id)),
                    ],
                  ),
                ),
              )).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Text('エラー: $e'),
        ),
      ],
    );
  }

  Widget _buildStickyBottomAction(int playerCount) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF38383A) : Colors.grey.shade300;

    return Container(
      padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(color: bottomColor, border: Border(top: BorderSide(color: borderColor, width: 0.5))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (_currentPage > 0)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: OutlinedButton(
                    onPressed: () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16), shape: const CircleBorder(), side: BorderSide(color: borderColor)),
                    child: Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.teal.shade700),
                  ),
                ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    if (_currentPage == 2) {
                      if (_teamNameController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('チーム名を入力してください')));
                        return;
                      }
                      final cleanTeamName = TextSanitizer.clean(_teamNameController.text);
                      final team = TeamModel(
                        id: _editingTeamId ?? '',
                        tournamentId: widget.tournamentId,
                        category: _selectedCategory,
                        teamName: cleanTeamName,
                        matchType: _matchType,
                        playerNames: List.generate(playerCount, (i) => _tempSelectedPlayers[i] ?? ''), // ★ 補欠も含めて保存！
                      );
                      await ref.read(teamRepositoryProvider).saveTeam(team);
                      
                      // ★ 履歴に保存
                      ref.read(teamNameHistoryProvider.notifier).addHistory(_teamNameController.text);
                      
                      if (!mounted) return;
                      setState(() { _editingTeamId = null; _teamNameController.clear(); _tempSelectedPlayers.clear(); _substituteCount = 0; _currentPage = 0; });
                      _pageController.jumpToPage(0);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('登録しました。続けて登録できます。')));
                    } else {
                      if (_currentPage == 1 && _teamNameController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('チーム名を入力してください')));
                        return;
                      }
                      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade600, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                  child: Text(
                    _currentPage == 2 ? (_editingTeamId != null ? '変更を保存' : '登録して、続けてチームを追加') : '次へ進む', 
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold) // 長い文字が収まるよう16に調整
                  ),
                ),
              ),
            ],
          ),
          if (_currentPage == 2) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                // ★ 自動保存機能
                if (_teamNameController.text.trim().isNotEmpty) {
                  try {
                    final cleanTeamName = TextSanitizer.clean(_teamNameController.text);
                    await ref.read(teamRepositoryProvider).saveTeam(TeamModel(
                      id: _editingTeamId ?? '',
                      tournamentId: widget.tournamentId,
                      category: _selectedCategory,
                      teamName: cleanTeamName,
                      matchType: _matchType,
                      playerNames: List.generate(playerCount, (i) => _tempSelectedPlayers[i] ?? ''),
                    ));
                    // ★ 履歴に保存
                    ref.read(teamNameHistoryProvider.notifier).addHistory(_teamNameController.text.trim());
                  } catch (e) {
                    debugPrint('チーム自動保存エラー: $e');
                  }
                }
                
                if (!mounted) return;
                context.go('/home/${widget.tournamentId}');
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('すべての登録を完了して大会画面へ', style: TextStyle(fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                // iOS Native: ボタンの色と角丸(12px)の調整
                foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.teal.shade400 : Colors.teal.shade700, 
                minimumSize: const Size(double.infinity, 54), 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
                side: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.teal.shade400 : Colors.teal.shade700)
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // iOS Native: ダークモード時は文字色をパステル調にして視認性を確保
    final color = isDark ? Colors.teal.shade400 : Colors.teal.shade700;
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)));
  }

  // ★ 追加：予測変換（サジェスト）と手入力を両立する入力フィールドビルダー
  Widget _buildTeamAutocomplete({
    required TextEditingController controller,
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
      focusNode: FocusNode(),
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) return suggestions;
        return suggestions.where((option) => option.contains(textEditingValue.text));
      },
      fieldViewBuilder: (context, fieldController, focusNode, onFieldSubmitted) {
        return TextField(
          controller: fieldController,
          focusNode: focusNode,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            labelText: labelText,
            labelStyle: TextStyle(color: subTextColor, fontWeight: FontWeight.bold),
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.teal.shade500)),
            prefixIcon: Icon(Icons.shield, color: Colors.teal.shade600),
            suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
            fillColor: fillColor,
            filled: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8.0,
            borderRadius: BorderRadius.circular(12),
            color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
            child: ConstrainedBox(
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
                    onTap: () => onSelected(option),
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