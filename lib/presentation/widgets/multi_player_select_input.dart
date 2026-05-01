import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/bunaiksen_provider.dart';
import 'smart_player_input.dart'; // マスタ取得用のプロバイダを参照するため

class MultiPlayerSelectInput extends ConsumerStatefulWidget {
  final List<String> initialSelected;
  final Function(List<String>) onConfirm;
  final String label;
  final Color accentColor;

  const MultiPlayerSelectInput({
    super.key,
    required this.initialSelected,
    required this.onConfirm,
    this.label = '選手を検索して追加（複数選択可）',
    this.accentColor = const Color(0xFF8B0000),
  });

  @override
  ConsumerState<MultiPlayerSelectInput> createState() => _MultiPlayerSelectInputState();
}

class _MultiPlayerSelectInputState extends ConsumerState<MultiPlayerSelectInput> {
  Future<void> _showMultiSelectSheet() async {
    final masterPlayers = ref.read(bunaiksenPlayerMasterProvider).value ?? [];
    final guestPlayers = ref.watch(bunaiksenGuestProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    String searchText = '';
    // モーダル内でのみ操作する一時的な選択リスト
    List<String> tempSelected = List.from(widget.initialSelected);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            final filteredMaster = masterPlayers.where((p) => p.name.contains(searchText)).toList();
            final filteredGuest = guestPlayers.where((name) => name.contains(searchText)).toList();
            final isNewName = searchText.trim().isNotEmpty && 
                              !filteredMaster.any((p) => p.name == searchText.trim()) &&
                              !filteredGuest.any((name) => name == searchText.trim());

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ヘッダー（確定ボタン付き）
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context), 
                          child: Text('キャンセル', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600))
                        ),
                        Text('${tempSelected.length}名 選択中', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: widget.accentColor)),
                        TextButton(
                          onPressed: () {
                            // ★ ここで確定し、親の画面にリストを一気に渡す
                            widget.onConfirm(tempSelected);
                            Navigator.pop(context);
                          }, 
                          child: Text('確定', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: widget.accentColor))
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 検索窓
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: '名前で検索、または出稽古を追加',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                      onChanged: (val) => setStateSheet(() => searchText = val),
                      onSubmitted: (val) {
                        if (isNewName) {
                          ref.read(bunaiksenGuestProvider.notifier).update((state) => [...state, val.trim()]);
                          setStateSheet(() {
                            tempSelected.add(val.trim());
                            searchText = '';
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 選手リスト（チェックボックス式）
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.45,
                    child: ListView(
                      children: [
                        if (isNewName)
                          ListTile(
                            leading: CircleAvatar(backgroundColor: widget.accentColor.withAlpha(26), child: Icon(Icons.person_add, color: widget.accentColor, size: 20)),
                            title: Text('"${searchText.trim()}" をゲスト追加して選択', style: TextStyle(color: widget.accentColor, fontWeight: FontWeight.bold)),
                            onTap: () {
                              ref.read(bunaiksenGuestProvider.notifier).update((state) => [...state, searchText.trim()]);
                              setStateSheet(() {
                                tempSelected.add(searchText.trim());
                                searchText = '';
                              });
                            },
                          ),
                        ...filteredGuest.map((name) {
                          final isSelected = tempSelected.contains(name);
                          return CheckboxListTile(
                            activeColor: widget.accentColor,
                            value: isSelected,
                            title: Text(name),
                            subtitle: const Text('出稽古・ゲスト', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            secondary: CircleAvatar(backgroundColor: Colors.grey.withAlpha(26), child: const Icon(Icons.person_outline, color: Colors.grey, size: 20)),
                            onChanged: (bool? val) {
                              setStateSheet(() {
                                if (val == true) {
                                  tempSelected.add(name);
                                } else {
                                  tempSelected.remove(name);
                                }
                              });
                            },
                          );
                        }),
                        ...filteredMaster.map((p) {
                          final isSelected = tempSelected.contains(p.name);
                          return CheckboxListTile(
                            activeColor: widget.accentColor,
                            value: isSelected,
                            title: Text(p.name),
                            subtitle: Text(p.gradeName, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            secondary: CircleAvatar(backgroundColor: widget.accentColor.withAlpha(26), child: Icon(Icons.person, color: widget.accentColor, size: 20)),
                            onChanged: (bool? val) {
                              setStateSheet(() {
                                if (val == true) {
                                  tempSelected.add(p.name);
                                } else {
                                  tempSelected.remove(p.name);
                                }
                              });
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // 入力欄に「何人選択されているか」と「選択した名前」をサマリー表示する
    final displayText = widget.initialSelected.isEmpty 
        ? '' 
        : '${widget.initialSelected.length}名選択中: ${widget.initialSelected.join(", ")}';

    return TextField(
      readOnly: true, // キーボードは出さずボトムシートを開く
      onTap: _showMultiSelectSheet,
      controller: TextEditingController(text: displayText),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: 'タップしてメンバーを選択...',
        filled: true,
        fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
        floatingLabelStyle: TextStyle(color: widget.accentColor),
        prefixIcon: Icon(Icons.group_add, color: widget.accentColor),
        suffixIcon: const Icon(Icons.touch_app),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade400),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: widget.accentColor, width: 2),
        ),
      ),
    );
  }
}