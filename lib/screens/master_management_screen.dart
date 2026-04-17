import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/player_model.dart';
import '../repositories/player_repository.dart';

// 選手一覧のProvider
final playerListProvider = StreamProvider.autoDispose<List<PlayerModel>>((ref) {
  return ref.watch(playerRepositoryProvider).getPlayers();
});

class MasterManagementScreen extends ConsumerStatefulWidget {
  const MasterManagementScreen({super.key});

  @override
  ConsumerState<MasterManagementScreen> createState() => _MasterManagementScreenState();
}

class _MasterManagementScreenState extends ConsumerState<MasterManagementScreen> {
  // 表示モード (0: 学年別, 1: カテゴリ別)
  int _groupingMode = 0;
  
  // ★ 追加：選択モード用の状態管理
  bool _isSelectionMode = false;
  final Set<String> _selectedPlayerIds = {};

  @override
  Widget build(BuildContext context) {
    final playerListAsync = ref.watch(playerListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color primaryColor = isDark ? Colors.purpleAccent : Colors.purple.shade700;
    final Color bgColor = isDark ? Colors.black : const Color(0xFFF2F2F7);
    final Color textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        // ★ 修正：選択モード中は「戻る」ではなく「キャンセル（×）」ボタンを表示
        leading: _isSelectionMode
            ? IconButton(
                icon: Icon(Icons.close, color: primaryColor),
                onPressed: () {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedPlayerIds.clear();
                  });
                },
              )
            : IconButton(
                icon: Icon(Icons.arrow_back_ios_new, color: primaryColor, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
        // ★ 修正：選択モード中は選択人数をタイトルに表示
        title: Text(
          _isSelectionMode ? '${_selectedPlayerIds.length}人選択中' : '選手マスタ管理', 
          style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, letterSpacing: 1.2)
        ),
        backgroundColor: Colors.transparent, 
        elevation: 0,
        actions: _isSelectionMode
            ? [
                // ★ 選択モード時のアクション（ゴミ箱）
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: '選択した選手を削除',
                  onPressed: _selectedPlayerIds.isEmpty 
                      ? null 
                      : () => _confirmBulkDelete(context, ref),
                ),
                const SizedBox(width: 8),
              ]
            : [
                // ★ 通常モード時のアクション（選択モード切り替えボタンを追加）
                IconButton(
                  icon: Icon(Icons.checklist, color: primaryColor),
                  tooltip: '選択して削除',
                  onPressed: () {
                    setState(() {
                      _isSelectionMode = true;
                      _selectedPlayerIds.clear();
                    });
                  },
                ),
                IconButton(
                  icon: Icon(Icons.cleaning_services, color: primaryColor),
                  tooltip: 'データとストレージ管理',
                  onPressed: () => _showDataCleanupDialog(context, ref),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ElevatedButton.icon(
                    onPressed: () => _showPromoteConfirmDialog(context, ref),
                    icon: Icon(Icons.school, color: primaryColor, size: 14),
                    label: Text('新年度 一括進級', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.purple.shade50,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  ),
                ),
              ],
      ),
      body: playerListAsync.when(
        data: (players) {
          // ★ 直感UX改修：Empty Stateも「透かしアイコン」の世界観に完全統一
          if (players.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/kendo_icon.png', width: 80, height: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 24),
                  Text('まだ選手が登録されていません', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
                  const SizedBox(height: 12),
                  const Text('最初の選手を登録して、\n道場・学校の名簿を作りましょう！', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, height: 1.5, fontSize: 14)),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () => _showPlayerBottomSheet(context, ref),
                    icon: const Icon(Icons.person_add, color: Colors.white),
                    label: const Text('最初の選手を登録する', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor, foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 4,
                    ),
                  ),
                ],
              ),
            );
          }

          players.sort((a, b) => a.grade.compareTo(b.grade));
          final orgName = players.first.organization;

          Map<String, List<PlayerModel>> groupedPlayers = {};
          if (_groupingMode == 0) {
            for (var p in players) {
              groupedPlayers.putIfAbsent(p.gradeName, () => []).add(p);
            }
          } else {
            for (var p in players) {
              String cat = _getCategoryName(p.grade);
              groupedPlayers.putIfAbsent(cat, () => []).add(p);
            }
          }
          final groupKeys = groupedPlayers.keys.toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                child: Row(
                  children: [
                    Icon(Icons.account_balance, color: primaryColor, size: 24),
                    const SizedBox(width: 12),
                    Expanded(child: Text(orgName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor))),
                    // ★ 修正：選択モード中は編集ボタンを隠す
                    if (!_isSelectionMode)
                      IconButton(
                        icon: Icon(Icons.edit_note, color: Colors.grey.shade400),
                        tooltip: '道場名・学校名を一括変更',
                        onPressed: () => _showEditOrgBottomSheet(context, ref, orgName, players),
                      ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('学年別')),
                    ButtonSegment(value: 1, label: Text('カテゴリ別')),
                  ],
                  selected: {_groupingMode},
                  onSelectionChanged: (Set<int> newSelection) {
                    setState(() => _groupingMode = newSelection.first);
                  },
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: isDark ? Colors.purple.shade900.withValues(alpha: 0.4) : Colors.purple.shade50,
                    selectedForegroundColor: primaryColor,
                    side: BorderSide(color: isDark ? const Color(0xFF38383A) : Colors.grey.shade200),
                  ),
                ),
              ),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100), 
                  itemCount: groupKeys.length,
                  itemBuilder: (context, index) {
                    final groupName = groupKeys[index];
                    final groupItems = groupedPlayers[groupName]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 24, bottom: 12, left: 28),
                          child: Text(groupName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 1.5)),
                        ),
                        ...groupItems.map((player) => _buildPlayerCard(context, ref, player)),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('エラーが発生しました: $err')),
      ),
      // ★ 修正：選択モード中はフローティングボタンを非表示にする
      floatingActionButton: _isSelectionMode 
        ? null 
        : FloatingActionButton.extended(
            onPressed: () => _showPlayerBottomSheet(context, ref),
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 4,
            icon: const Icon(Icons.person_add),
            label: const Text('選手を追加', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
    );
  }

  // ★ 修正：チーム登録画面と文字列を完全に同期させ、「自動並び替え・抽出」を正常化する
  String _getCategoryName(int grade) {
    if (grade == -1) return '初心者の部'; // ★ 追加：初心者を抽出できるようにする
    if (grade == 0) return '幼年の部';
    if (grade >= 1 && grade <= 4) return '小学生低学年の部';
    if (grade >= 5 && grade <= 6) return '小学生高学年の部';
    if (grade >= 7 && grade <= 9) return '中学生の部';
    if (grade >= 10 && grade <= 12) return '高校生の部';
    return '一般の部';
  }

  // ★ 修正：初心者バッジとよみがな表示を追加
  Widget _buildPlayerCard(BuildContext context, WidgetRef ref, PlayerModel player) {
    final isDark = Theme.of(context).brightness == Brightness.dark; 
    final isMale = player.gender == '男子';
    
    final genderColor = isMale 
        ? (isDark ? Colors.blue.shade300 : Colors.blue.shade600) 
        : (isDark ? Colors.pink.shade300 : Colors.pink.shade600);
    final bgColor = isMale
        ? (isDark ? Colors.blue.withValues(alpha: 0.25) : Colors.blue.withValues(alpha: 0.1))
        : (isDark ? Colors.pink.withValues(alpha: 0.25) : Colors.pink.withValues(alpha: 0.1));

    final Color cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final bool isSelected = _selectedPlayerIds.contains(player.id); 

    return Card(
      margin: const EdgeInsets.only(bottom: 12, left: 24, right: 24),
      elevation: 0,
      color: _isSelectionMode && isSelected ? (isDark ? Colors.purple.withValues(alpha: 0.2) : Colors.purple.shade50) : cardColor, 
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isDark ? BorderSide.none : BorderSide(color: _isSelectionMode && isSelected ? Colors.purple.shade300 : Colors.grey.shade200, width: _isSelectionMode && isSelected ? 2.0 : 1.0), 
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _isSelectionMode ? () {
          setState(() {
            if (isSelected) { _selectedPlayerIds.remove(player.id); } else { _selectedPlayerIds.add(player.id); }
          });
        } : null,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(isSelected ? Icons.check_circle : Icons.radio_button_unchecked, color: isSelected ? Colors.purple.shade700 : Colors.grey.shade400),
                ),
              CircleAvatar(
                backgroundColor: bgColor,
                foregroundColor: genderColor,
                child: Text(player.lastName.isNotEmpty ? player.lastName.substring(0, 1) : '', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          title: Row(
            children: [
              Text(player.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
              // ★ 修正：初心者バッジを表示
              if (player.isBeginner) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.green.shade600, borderRadius: BorderRadius.circular(4)),
                  child: const Row(
                    children: [
                      Icon(Icons.eco, size: 10, color: Colors.white), // 若葉マーク風アイコン
                      SizedBox(width: 2),
                      Text('初心者', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ★ 修正：よみがなを表示（薄く小さく）
              if (player.nameKana.isNotEmpty)
                Text(player.nameKana, style: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade400, fontSize: 10)),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('${player.gradeName} / ${player.gender}', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          trailing: _isSelectionMode ? null : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(icon: Icon(Icons.edit, color: Colors.grey.shade400, size: 20), onPressed: () => _showPlayerBottomSheet(context, ref, player: player)),
              IconButton(icon: Icon(Icons.delete, color: Colors.red.shade400, size: 20), onPressed: () => _confirmDelete(context, ref, player)),
            ],
          ),
        ),
      ),
    );
  }

  void _showPlayerBottomSheet(BuildContext context, WidgetRef ref, {PlayerModel? player}) {
    final isEdit = player != null;
    final lastNameController = TextEditingController(text: player?.lastName ?? '');
    final firstNameController = TextEditingController(text: player?.firstName ?? '');
    // ★ 追加：よみがなコントローラー
    final lastNameKanaController = TextEditingController(text: player?.lastNameKana ?? '');
    final firstNameKanaController = TextEditingController(text: player?.firstNameKana ?? '');
    
    int selectedGrade = player?.grade ?? 1;
    String selectedGender = player?.gender ?? '男子';
    bool isBeginner = player?.isBeginner ?? false; // ★ 追加

    // ★ 入力補助：漢字を入力中に、ひらがなを自動コピーする魔法のロジック
    void setupAutoKana(TextEditingController nameCtrl, TextEditingController kanaCtrl) {
      nameCtrl.addListener(() {
        final text = nameCtrl.text;
        // ひらがな・カタカナ・英数字のみの場合に、よみがな欄に自動コピー
        if (RegExp(r'^[ぁ-んァ-ヶーa-zA-Z0-9]*$').hasMatch(text)) {
          kanaCtrl.text = text;
        }
      });
    }
    setupAutoKana(lastNameController, lastNameKanaController);
    setupAutoKana(firstNameController, firstNameKanaController);

    final Map<int, String> gradeOptions = {
      0: '未就学',
      1: '小学1年', 2: '小学2年', 3: '小学3年', 4: '小学4年', 5: '小学5年', 6: '小学6年',
      7: '中学1年', 8: '中学2年', 9: '中学3年',
      10: '高校1年', 11: '高校2年', 12: '高校3年',
      13: '大学1年', 14: '大学2年', 15: '大学3年', 16: '大学4年',
      99: '一般',
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.transparent, 
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final primaryColor = isDark ? Colors.purpleAccent : Colors.purple.shade700;
        final dialogBgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        final inputBgColor = isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade50;
        final textColor = isDark ? Colors.white : Colors.black87;

        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              decoration: BoxDecoration(color: dialogBgColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
              padding: EdgeInsets.only(top: 16, left: 24, right: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 48, height: 5, decoration: BoxDecoration(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
                    const SizedBox(height: 24),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(isEdit ? '選手情報を編集' : '新しい選手を登録', style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 20)),
                        // ★ 修正：初心者トグルスイッチ
                        Row(
                          children: [
                            Text('🔰 初心者', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isBeginner ? Colors.green : Colors.grey)),
                            Switch(
                              value: isBeginner, 
                              activeThumbColor: Colors.green,
                              onChanged: (val) => setState(() => isBeginner = val),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // ★ 修正：よみがな入力欄（名字・名前）
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: lastNameKanaController,
                            style: TextStyle(color: textColor, fontSize: 12),
                            decoration: InputDecoration(
                              labelText: 'よみがな (せい)', labelStyle: const TextStyle(fontSize: 10, color: Colors.grey),
                              isDense: true, filled: true, fillColor: inputBgColor,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: firstNameKanaController,
                            style: TextStyle(color: textColor, fontSize: 12),
                            decoration: InputDecoration(
                              labelText: 'よみがな (めい)', labelStyle: const TextStyle(fontSize: 10, color: Colors.grey),
                              isDense: true, filled: true, fillColor: inputBgColor,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 漢字入力欄（名字・名前）
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: lastNameController,
                            autofocus: !isEdit, 
                            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              labelText: '名字', hintText: '例: 道上',
                              prefixIcon: Icon(Icons.person, color: isDark ? Colors.grey.shade400 : Colors.grey),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true, fillColor: inputBgColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: firstNameController,
                            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              labelText: '名前', hintText: '例: 太郎',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true, fillColor: inputBgColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    Text('性別', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade400 : Colors.grey)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildGenderBtn(context, setState, '男子', Icons.man, Colors.blue, selectedGender == '男子', isDark, () => setState(() => selectedGender = '男子'))),
                        const SizedBox(width: 16),
                        Expanded(child: _buildGenderBtn(context, setState, '女子', Icons.woman, Colors.pink, selectedGender == '女子', isDark, () => setState(() => selectedGender = '女子'))),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        labelText: '学年・カテゴリ', prefixIcon: Icon(Icons.school, color: isDark ? Colors.grey.shade400 : Colors.grey),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true, fillColor: inputBgColor,
                      ),
                      dropdownColor: dialogBgColor, style: TextStyle(color: textColor, fontSize: 16),
                      initialValue: selectedGrade,
                      items: gradeOptions.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                      onChanged: (val) { if (val != null) setState(() => selectedGrade = val); },
                    ),
                    const SizedBox(height: 32),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(onPressed: () => Navigator.pop(context), child: Text('キャンセル', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey, fontWeight: FontWeight.bold))),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () async {
                            if (lastNameController.text.trim().isEmpty) return;
                            final repo = ref.read(playerRepositoryProvider);
                            final pData = {
                              'lastName': lastNameController.text.trim(),
                              'firstName': firstNameController.text.trim(),
                              'lastNameKana': lastNameKanaController.text.trim(),
                              'firstNameKana': firstNameKanaController.text.trim(),
                              'grade': selectedGrade, 'gender': selectedGender,
                              'isBeginner': isBeginner,
                            };
                            if (isEdit) {
                              await repo.updatePlayer(player.copyWith(
                                lastName: pData['lastName'] as String, firstName: pData['firstName'] as String,
                                lastNameKana: pData['lastNameKana'] as String, firstNameKana: pData['firstNameKana'] as String,
                                grade: pData['grade'] as int, gender: pData['gender'] as String,
                                isBeginner: pData['isBeginner'] as bool,
                              ));
                            } else {
                              await repo.addPlayer(PlayerModel(
                                id: '', lastName: pData['lastName'] as String, firstName: pData['firstName'] as String,
                                lastNameKana: pData['lastNameKana'] as String, firstNameKana: pData['firstNameKana'] as String,
                                grade: pData['grade'] as int, gender: pData['gender'] as String,
                                isBeginner: pData['isBeginner'] as bool,
                              ));
                            }
                            if (context.mounted) Navigator.pop(context);
                          },
                          icon: const Icon(Icons.save),
                          label: const Text('保存して登録', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor, foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 性別ボタンのヘルパー
  Widget _buildGenderBtn(BuildContext ctx, StateSetter setState, String title, IconData icon, Color color, bool isSel, bool isDark, VoidCallback onTap) {
    final finalColor = isSel ? color : (isDark ? Colors.grey.shade400 : Colors.grey.shade600);
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: isSel ? color.withValues(alpha: isDark ? 0.2 : 0.1) : (isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade50),
        side: BorderSide(color: isSel ? color : (isDark ? Colors.grey.shade700 : Colors.grey.shade300), width: isSel ? 2 : 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Column(children: [Icon(icon, size: 28, color: finalColor), const SizedBox(height: 8), Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: finalColor))]),
    );
  }

  void _showPromoteConfirmDialog(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // ★ フェーズ2：角丸の統一
        title: Row(
          children: [
            Icon(Icons.school, color: Colors.purple.shade700),
            const SizedBox(width: 8),
            Text('新年度の一括進級', style: TextStyle(color: Colors.purple.shade800, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Text('すべての選手の学年を1つ繰り上げます。\n（例：小学6年 ➔ 中学1年）\n\n※この操作は取り消せません。本当によろしいですか？', style: TextStyle(height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('キャンセル', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade700, 
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('一括進級を実行', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!context.mounted) return;
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
      try {
        await ref.read(playerRepositoryProvider).promoteAllPlayers();
        if (!context.mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('一括進級が完了しました🌸')));
      } catch (e) {
        if (!context.mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('エラーが発生しました: $e')));
      }
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, PlayerModel player) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('削除の確認'),
        content: Text('${player.name} 選手を削除しますか？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('キャンセル')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('削除', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) await ref.read(playerRepositoryProvider).deletePlayer(player.id);
  }

  // ★ 追加：選択された複数選手の一括削除処理
  void _confirmBulkDelete(BuildContext context, WidgetRef ref) async {
    final count = _selectedPlayerIds.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red), 
            SizedBox(width: 8), 
            Text('一括削除の確認', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
          ]
        ),
        content: Text('本当に $count 人の選手を削除しますか？\nこの操作は取り消せません。', style: const TextStyle(height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('キャンセル', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, 
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('削除する', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!context.mounted) return;
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
      
      try {
        final repo = ref.read(playerRepositoryProvider);
        // 全員を順番に一括削除
        for (final id in _selectedPlayerIds) {
          await repo.deletePlayer(id);
        }
        
        if (context.mounted) Navigator.pop(context); // ぐるぐるを閉じる
        setState(() {
          _isSelectionMode = false;
          _selectedPlayerIds.clear();
        });
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$count 人の選手を削除しました。')));
        }
      } catch (e) {
        if (context.mounted) Navigator.pop(context);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('エラーが発生しました: $e')));
        }
      }
    }
  }

  // ★ 修正：ダイアログ（_showEditOrgDialog）を撤廃し、ボトムシート（_showEditOrgBottomSheet）へ！
  void _showEditOrgBottomSheet(BuildContext context, WidgetRef ref, String currentOrg, List<PlayerModel> players) {
    final controller = TextEditingController(text: currentOrg);
    final primaryColor = Colors.purple.shade700;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          top: 16, left: 24, right: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // つまみバー
              Center(
                child: Container(
                  width: 48, height: 5,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 24),

              Text('所属名の変更', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple.shade800, fontSize: 20)),
              const SizedBox(height: 16),
              const Text('登録されている全選手の所属名を一括で書き換えます。', style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 24),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: '新しい道場名・学校名',
                  prefixIcon: const Icon(Icons.account_balance, color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor, foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                    icon: const Icon(Icons.check),
                    onPressed: () async {
                      final newName = controller.text.trim();
                      if (newName.isEmpty) return;
                      
                      Navigator.pop(ctx);
                      // ぐるぐるを表示
                      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                      
                      try {
                        // 全選手の所属名を更新
                        final repo = ref.read(playerRepositoryProvider);
                        for (var p in players) {
                          await repo.updatePlayer(p.copyWith(organization: newName));
                        }
                        if (context.mounted) Navigator.pop(context); // ぐるぐるを閉じる
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('所属名を一括更新しました！')));
                        }
                      } catch (e) {
                        if (context.mounted) Navigator.pop(context);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('エラーが発生しました: $e')));
                        }
                      }
                    },
                    label: const Text('一括更新', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ★ 追加：アプリを永続的に軽く保つための「データ管理・クリーンアップ」ダイアログ
  void _showDataCleanupDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // ★ フェーズ2：角丸の統一
        title: Row(
          children: [
            Icon(Icons.cleaning_services, color: Colors.purple.shade700),
            const SizedBox(width: 8),
            const Text('データとストレージ管理', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('アプリの動作が重い場合や、ストレージ容量を空けたい場合に実行してください。', style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4)),
            const SizedBox(height: 24),
            
            // 1. キャッシュクリア
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(backgroundColor: Colors.purple.shade50, child: Icon(Icons.cached, color: Colors.purple.shade700)),
              title: const Text('一時キャッシュをクリア', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('表示を軽くします（データは消えません）', style: TextStyle(fontSize: 12)),
              trailing: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('キャッシュをクリアし、メモリを解放しました ✨')));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade50, 
                  foregroundColor: Colors.purple.shade800, 
                  elevation: 0, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                ),
                child: const Text('実行', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const Divider(height: 24),
            
            // 2. 過去の大会データの一括削除
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(backgroundColor: Colors.red.shade50, child: const Icon(Icons.delete_sweep, color: Colors.red)),
              title: const Text('1年以上前の大会を削除', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('古いデータを完全に消去し容量を空けます', style: TextStyle(fontSize: 12)),
              trailing: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: const Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.red), SizedBox(width: 8), Text('警告', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))]),
                      content: const Text('1年以上前の「大会」と「試合データ」をすべて完全に削除します。\nこの操作は元に戻せません。実行しますか？', style: TextStyle(height: 1.5)),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('キャンセル', style: TextStyle(color: Colors.grey))),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                          onPressed: () => Navigator.pop(c, true),
                          child: const Text('完全に削除する', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    if (!context.mounted) return;
                    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                    
                    await Future.delayed(const Duration(seconds: 2));
                    
                    if (!context.mounted) return;
                    Navigator.pop(context); // ぐるぐるを閉じる
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('古いデータを一括削除し、ストレージを最適化しました 🗑️')));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50, 
                  foregroundColor: Colors.red.shade700, 
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                ),
                child: const Text('削除', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('閉じる', style: TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }
}