import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../operate/providers/bunaiksen_provider.dart';
import 'package:kendo_os/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/domain/entities/player_model.dart';

// 部内戦機能で利用する選手マスタを取得する専用Provider
final bunaiksenPlayerMasterProvider = StreamProvider.autoDispose<List<PlayerModel>>((ref) {
  // 既存のplayerRepositoryProviderをwatchして選手リストを取得
  return ref.watch(playerRepositoryProvider).getPlayers();
});

class SmartPlayerInput extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final String label;
  final Color accentColor;

  const SmartPlayerInput({
    super.key,
    required this.controller,
    required this.label,
    this.accentColor = const Color(0xFF8B0000), // ★ 修正：洗練されたボルドー（深紅）に変更
  });

  @override
  ConsumerState<SmartPlayerInput> createState() => _SmartPlayerInputState();
}

class _SmartPlayerInputState extends ConsumerState<SmartPlayerInput> {
  // ボトムシートを開いて選手を選択・追加するメソッド
  Future<void> _showPlayerSelectSheet() async {
    final masterPlayers = ref.read(bunaiksenPlayerMasterProvider).value ?? [];
    final guestPlayers = ref.watch(bunaiksenGuestProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    String searchText = '';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            // 検索文字で絞り込み
            final filteredMaster = masterPlayers.where((p) => p.name.contains(searchText)).toList();
            final filteredGuest = guestPlayers.where((name) => name.contains(searchText)).toList();
            
            // 入力文字が完全に新しい場合のみ「追加」ボタンを表示
            final isNewName = searchText.trim().isNotEmpty && 
                              !filteredMaster.any((p) => p.name == searchText.trim()) &&
                              !filteredGuest.any((name) => name == searchText.trim());

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom, // キーボードを避ける
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('選手を選択', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: widget.accentColor)),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      autofocus: true, // 開いた瞬間にキーボードを出す
                      decoration: InputDecoration(
                        hintText: '名前で検索、または出稽古を追加',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                      onChanged: (val) {
                        setStateSheet(() => searchText = val);
                      },
                      onSubmitted: (val) {
                        if (val.trim().isNotEmpty) {
                          if (isNewName) {
                            ref.read(bunaiksenGuestProvider.notifier).update((state) => [...state, val.trim()]);
                          }
                          widget.controller.text = val.trim();
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.4, // リストの高さ
                    child: ListView(
                      children: [
                        if (isNewName)
                          ListTile(
                            leading: CircleAvatar(backgroundColor: widget.accentColor.withAlpha(26), child: Icon(Icons.person_add, color: widget.accentColor, size: 20)),
                            title: Text('"${searchText.trim()}" をゲストとして追加', style: TextStyle(color: widget.accentColor, fontWeight: FontWeight.bold)),
                            onTap: () {
                              ref.read(bunaiksenGuestProvider.notifier).update((state) => [...state, searchText.trim()]);
                              widget.controller.text = searchText.trim();
                              Navigator.pop(context);
                            },
                          ),
                        ...filteredGuest.map((name) => ListTile(
                          leading: CircleAvatar(backgroundColor: Colors.grey.withAlpha(26), child: const Icon(Icons.person_outline, color: Colors.grey, size: 20)),
                          title: Text(name),
                          subtitle: const Text('出稽古・ゲスト', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          onTap: () {
                            widget.controller.text = name;
                            Navigator.pop(context);
                          },
                        )),
                        ...filteredMaster.map((p) => ListTile(
                          leading: CircleAvatar(backgroundColor: widget.accentColor.withAlpha(26), child: Icon(Icons.person, color: widget.accentColor, size: 20)),
                          title: Text(p.name),
                          subtitle: Text(p.gradeName, style: const TextStyle(fontSize: 12, color: Colors.grey)), // ★ 修正：マスタの学年を表示
                          onTap: () {
                            widget.controller.text = p.name;
                            Navigator.pop(context);
                          },
                        )),
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

    return TextField(
      controller: widget.controller,
      readOnly: true, // 直接入力させず、ボトムシートに誘導する
      onTap: _showPlayerSelectSheet, // タップでボトムシートを開く
      decoration: InputDecoration(
        labelText: widget.label,
        filled: true,
        fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
        floatingLabelStyle: TextStyle(color: widget.accentColor),
        suffixIcon: const Icon(Icons.arrow_drop_down), // ボトムシートが開くことを示唆するアイコン
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