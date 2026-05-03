import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'settings_provider.dart'; // sharedPreferencesProvider を使うため
import '../../../infrastructure/repository/player_repository.dart'; // ★ 追加: repositoryへアクセスするため

class TeamNameHistoryNotifier extends Notifier<List<String>> {
  static const _key = 'kendo_team_name_history';
  static const _maxItems = 10; // 最大10件を記憶

  @override
  List<String> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final jsonString = prefs.getString(_key);
    if (jsonString != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonString);
        return decoded.cast<String>();
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  // チーム名を追加（古いものから押し出し）
  Future<void> addHistory(String name) async {
    if (name.trim().isEmpty) return;
    
    final currentList = List<String>.from(state);
    
    // 既に存在する場合は一旦削除して先頭（最新）に持ってくる
    currentList.remove(name);
    currentList.insert(0, name);
    
    if (currentList.length > _maxItems) {
      currentList.removeLast();
    }
    
    state = currentList;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_key, jsonEncode(currentList));
  }

  // ★ Phase 7: UIからの「追加」指示を受け取る窓口
  Future<void> addName(String name, String orgName) async {
    await ref.read(playerRepositoryProvider).addCustomTeamName(name, organization: orgName);
    // ★ 修正：画面のリストに即時反映させるため、ローカルのstateも更新する
    await addHistory(name);
  }

  // ★ Phase 7: UIからの「削除」指示を受け取る窓口
  Future<void> deleteName(String name, String orgName) async {
    await ref.read(playerRepositoryProvider).deleteCustomTeamName(name, organization: orgName);
    // ★ 修正：画面のリストに即時反映させるため、ローカルのstateからも削除する
    final currentList = List<String>.from(state);
    currentList.remove(name);
    state = currentList;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_key, jsonEncode(currentList));
  }
}

final teamNameHistoryProvider = NotifierProvider<TeamNameHistoryNotifier, List<String>>(() {
  return TeamNameHistoryNotifier();
});