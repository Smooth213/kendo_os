import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/domain/entities/player_model.dart';
import 'package:kendo_os/infrastructure/repository/player_repository.dart';
import '../providers/permission_provider.dart';
import '../../shared/widgets/manual_help_button.dart'; // ★ 追加
// ★ Phase 2: JSONエクスポートに必要なパッケージを追加
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../providers/match_list_provider.dart';
import 'package:kendo_os/core/utils/text_sanitizer.dart';
import '../providers/team_name_history_provider.dart'; // ★ 新規追加
import 'package:flutter/services.dart'; // ★ 長押し時のバイブレーション用
import 'package:flutter_slidable/flutter_slidable.dart'; // ★ iPhoneライクなスワイプ用

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
    final permissions = ref.watch(permissionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color primaryColor = isDark ? Colors.purpleAccent : Colors.purple.shade700;
    final Color bgColor = isDark ? Colors.black : const Color(0xFFF2F2F7);
    final Color textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
        // ★ 修正1: 左側（Leading）の「✕」にキャンセル機能を割り当て
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedPlayerIds.clear();
                  });
                },
              )
            : null,
        title: Text(
          _isSelectionMode ? '${_selectedPlayerIds.length}人選択中' : '選手マスタ管理', 
          style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, letterSpacing: 1.2)
        ),
        backgroundColor: Colors.transparent, 
        elevation: 0,
        actions: _isSelectionMode
            ? [
                // ★ 修正2: 右側の「✕」ボタンを削除（削除ボタンのみ残す）
                if (!permissions.isReadOnly)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: '選択した選手を削除',
                    onPressed: _selectedPlayerIds.isEmpty ? null : () => _confirmBulkDelete(context, ref),
                  ),
                const SizedBox(width: 8),
              ]
            : (permissions.isReadOnly 
                ? [] 
                : [
                    // ★ 変更：チェックリスト（一括選択）ボタンを廃止し、スッキリさせる
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: primaryColor),
                      onSelected: (value) {
                        if (value == 'cleanup') _showDataCleanupDialog(context, ref);
                        if (value == 'promote') _showPromoteConfirmDialog(context, ref);
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'cleanup',
                          child: Row(children: [Icon(Icons.cleaning_services, size: 20), SizedBox(width: 12), Text('データ掃除')]),
                        ),
                        const PopupMenuItem(
                          value: 'promote',
                          child: Row(children: [Icon(Icons.school, size: 20), SizedBox(width: 12), Text('新年度の一括進級')]),
                        ),
                      ],
                    ),
                    ManualHelpButton(manualPath: 'docs/manuals/operator/settings.md', color: primaryColor),
                    const SizedBox(width: 8),
                  ]),
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
                padding: const EdgeInsets.only(top: 16, left: 32, right: 32, bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.account_balance, color: primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(orgName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor))),
                    
                    // ★ 閲覧制限がかかっていない場合のみ表示
                    if (!_isSelectionMode && !permissions.isReadOnly) ...[
                      // 1. よく使うチーム名の管理ボタン
                      IconButton(
                        icon: Icon(Icons.format_list_bulleted_add, color: primaryColor.withValues(alpha: 0.7)),
                        tooltip: 'よく使うチーム名の管理',
                        onPressed: () => _showCustomTeamNameManagementSheet(context, ref, orgName),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                      ),
                      // 2. 道場名の一括変更ボタン
                      IconButton(
                        icon: Icon(Icons.edit_note, color: Colors.grey.shade400),
                        tooltip: '道場名・学校名を一括変更',
                        onPressed: () => _showEditOrgBottomSheet(context, ref, orgName, players),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                      ),
                    ],
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
                          padding: const EdgeInsets.only(top: 24, bottom: 8, left: 32),
                          child: Text(groupName.toUpperCase(), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.grey.shade500 : Colors.grey.shade600, letterSpacing: 0.5)),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: groupItems.asMap().entries.map((entry) {
                              final int idx = entry.key;
                              final PlayerModel player = entry.value;
                              final bool isLast = idx == groupItems.length - 1;
                              return Column(
                                children: [
                                  _buildPlayerTile(context, ref, player),
                                  if (!isLast)
                                    Divider(height: 1, thickness: 0.5, color: isDark ? const Color(0xFF38383A) : const Color(0xFFC6C6C8), indent: 68, endIndent: 0),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
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
      // ★ Phase 8: 閲覧のみ（記録係）の場合は、追加ボタンを表示しない
      floatingActionButton: permissions.isReadOnly || _isSelectionMode 
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
  Widget _buildPlayerTile(BuildContext context, WidgetRef ref, PlayerModel player) {
    final permissions = ref.watch(permissionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark; 
    final isMale = player.gender == '男子';
    
    final genderColor = isMale 
        ? (isDark ? Colors.blue.shade300 : Colors.blue.shade600) 
        : (isDark ? Colors.pink.shade300 : Colors.pink.shade600);
    final bgColor = isMale
        ? (isDark ? Colors.blue.withValues(alpha: 0.25) : Colors.blue.withValues(alpha: 0.1))
        : (isDark ? Colors.pink.withValues(alpha: 0.25) : Colors.pink.withValues(alpha: 0.1));

    final bool isSelected = _selectedPlayerIds.contains(player.id); 
    final selectedColor = isDark ? Colors.purple.withValues(alpha: 0.2) : Colors.purple.shade50;

    final tile = Material(
      color: _isSelectionMode && isSelected ? selectedColor : Colors.transparent,
      child: InkWell(
        onTap: _isSelectionMode ? () {
          setState(() {
            if (isSelected) { _selectedPlayerIds.remove(player.id); } else { _selectedPlayerIds.add(player.id); }
          });
        } : null,
        onLongPress: () {
          if (!_isSelectionMode && !ref.read(permissionProvider).isReadOnly) {
            HapticFeedback.heavyImpact(); // ブルッと震えさせる
            setState(() {
              _isSelectionMode = true;
              _selectedPlayerIds.add(player.id);
            });
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              if (_isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(isSelected ? Icons.check_circle : Icons.circle_outlined, color: isSelected ? Colors.purple.shade700 : Colors.grey.shade400, size: 22),
                ),
              CircleAvatar(
                backgroundColor: bgColor,
                foregroundColor: genderColor,
                radius: 18,
                child: Text(player.lastName.isNotEmpty ? player.lastName.substring(0, 1) : '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(player.name, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: isDark ? Colors.white : Colors.black87), overflow: TextOverflow.ellipsis),
                        ),
                        if (player.isBeginner) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.green.shade600, borderRadius: BorderRadius.circular(4)),
                            child: const Row(
                              children: [
                                Icon(Icons.eco, size: 10, color: Colors.white), 
                                SizedBox(width: 2),
                                Text('初心者', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (player.nameKana.isNotEmpty)
                          Text('${player.nameKana} ', style: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade400, fontSize: 11)),
                        Text('${player.gradeName} / ${player.gender}', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade500, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // 選択モード中、または閲覧専用の場合はスワイプさせない
    if (_isSelectionMode || permissions.isReadOnly) {
      return tile;
    }

    // ★ 追加：通常時は iPhone ライクなスワイプメニュー (Slidable) を提供する
    return Slidable(
      key: ValueKey(player.id),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) => _showPlayerBottomSheet(context, ref, player: player),
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: '編集',
          ),
          // ★ 修正：厳格な canDeleteData の縛りを外し、誰でも（Viewer以外）削除ボタンを見えるようにする
          if (!permissions.isReadOnly)
            SlidableAction(
                onPressed: (context) => _confirmSingleDelete(context, ref, player),
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                icon: Icons.delete,
                label: '削除',
              ),
        ],
      ),
      child: tile,
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

  void _confirmSingleDelete(BuildContext context, WidgetRef ref, PlayerModel player) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('削除の確認'),
        content: const Text('選手データを完全に削除します。この操作は取り消せません。よろしいですか？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(playerRepositoryProvider).deletePlayer(player.id);
            },
            child: const Text('削除', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ★ 追加：選択された複数選手の一括削除処理
  void _confirmBulkDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('一括削除の確認'),
        content: Text('${_selectedPlayerIds.length}人の選手データを完全に削除します。この操作は取り消せません。よろしいですか？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
          TextButton(
            onPressed: () async {
              final idsToDelete = _selectedPlayerIds.toList();
              Navigator.pop(ctx);
              
              for (final id in idsToDelete) {
                await ref.read(playerRepositoryProvider).deletePlayer(id);
              }
              
              setState(() {
                _isSelectionMode = false;
                _selectedPlayerIds.clear();
              });
            },
            child: const Text('すべて削除', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
                      // ★ 修正：一括修正する道場名もお掃除フィルターに通す！
                      final newName = TextSanitizer.clean(controller.text);
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
            
            // ★ Phase 2: JSONエクスポート（物理バックアップ）
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(backgroundColor: Colors.blue.shade50, child: Icon(Icons.download, color: Colors.blue.shade700)),
              title: const Text('全データをJSONでバックアップ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('端末内に完全な状態のファイルを書き出します', style: TextStyle(fontSize: 12)),
              trailing: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    // 全試合データを取得してJSON文字列に変換
                    final matches = ref.read(matchListProvider);
                    // ★ 修正：Timestamp型のエンコードエラーを回避する変換ルールを追加
                    final jsonStr = jsonEncode(
                      matches.map((m) => m.toJson()).toList(),
                      toEncodable: (dynamic item) {
                        if (item is DateTime) return item.toIso8601String();
                        if (item.runtimeType.toString() == 'Timestamp') {
                          try { return (item as dynamic).toDate().toIso8601String(); } catch (_) { return item.toString(); }
                        }
                        return item.toString();
                      },
                    );
                    
                    // 端末のドキュメントディレクトリに保存
                    final dir = await getApplicationDocumentsDirectory();
                    final file = File('${dir.path}/kendo_backup_${DateTime.now().millisecondsSinceEpoch}.json');
                    await file.writeAsString(jsonStr);
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ バックアップ完了\n${file.path}'), duration: const Duration(seconds: 4)));
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ バックアップ失敗: $e')));
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade50, 
                  foregroundColor: Colors.blue.shade800, 
                  elevation: 0, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                ),
                child: const Text('書き出し', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const Divider(height: 24),
            
            // 2. 過去の大会データの一括削除（★ Phase 8: 削除権限がない場合は非表示）
            if (ref.watch(permissionProvider).canDeleteData)
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

  // ★ Phase 7: UIから直接のDBアクセスを排除し、専用のプロバイダに委譲
  void _showCustomTeamNameManagementSheet(BuildContext context, WidgetRef ref, String orgName) {
    final nameController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? Colors.purpleAccent : Colors.purple.shade700;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.7,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(top: 16, left: 24, right: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 48, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 24),
            Text('チーム名の管理', style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 20)),
            const Text('試合作成時にボタンで選べる「自チーム名」を登録します。', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 24),
            
            // 入力エリア
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: nameController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: '例：道上剣友会A',
                      filled: true,
                      fillColor: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () async {
                    final name = TextSanitizer.clean(nameController.text);
                    if (name.isNotEmpty) {
                      // ⭕️ UIはプロバイダに「追加して」と伝えるだけ
                      await ref.read(teamNameHistoryProvider.notifier).addName(name, orgName);
                      nameController.clear();
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('追加'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // リスト表示
            Expanded(
              // ⭕️ UIはプロバイダから提供されるList<String>をそのまま監視するだけ
              child: Consumer(
                builder: (context, ref, child) {
                  final names = ref.watch(teamNameHistoryProvider);
                  
                  if (names.isEmpty) {
                    return const Center(child: Text('登録されたチーム名はありません', style: TextStyle(color: Colors.grey, fontSize: 13)));
                  }
                  
                  return ListView.builder(
                    itemCount: names.length,
                    itemBuilder: (context, index) => Card(
                      elevation: 0,
                      color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade50,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(names[index], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        trailing: ref.watch(permissionProvider).canDeleteData // ★ Phase 8: 削除権限でロック
                            ? IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                onPressed: () => ref.read(teamNameHistoryProvider.notifier).deleteName(names[index], orgName),
                              )
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}