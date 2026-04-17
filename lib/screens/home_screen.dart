import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/match_model.dart';
import '../providers/match_list_provider.dart';
import '../providers/match_command_provider.dart';
import 'standings_screen.dart';
import 'official_record_screen.dart';
import 'team_scoreboard_screen.dart'; 
import 'kachinuki_scoreboard_screen.dart'; 
import '../models/tournament_model.dart';
import '../repositories/tournament_repository.dart';
import 'package:intl/intl.dart';

final tournamentProvider = StreamProvider.family<TournamentModel?, String>((ref, id) {
  final repo = ref.watch(tournamentRepositoryProvider);
  return repo.getTournamentStream(id);
});

// ★ 追加：カテゴリの並び順（昇順/降順）を管理するプロバイダ (true: 昇順, false: 降順)
final categorySortProvider = StateProvider.autoDispose<bool>((ref) => true);

class HomeScreen extends ConsumerWidget {
  final String tournamentId;
  const HomeScreen({super.key, required this.tournamentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // iOS Native カラーパレット
    final Color bgColor = isDark ? Colors.black : const Color(0xFFF2F2F7);
    final Color textColor = isDark ? Colors.white : Colors.black;

    // ★ Step 3-2: watch最適化。他の大会の試合が更新されても、このホーム画面はリビルドされない
    final matches = ref.watch(matchListProvider.select((list) => 
      list.where((m) => m.tournamentId == tournamentId).toList()
    ));

    // ★ 修正：追加した順に並び替え（orderフィールドを使用）
    matches.sort((a, b) => a.order.compareTo(b.order));

    // ★ 直感UX改修：団体戦の先鋒開始から大将終了まで（対戦間も含めて）常に「進行中」と判定する賢いロジック
    final uniqueInProgress = <MatchModel>[];
    final uniqueWaiting = <MatchModel>[];
    final seenGroups = <String>{};

    for (var m in matches) {
      final isGrouped = m.groupName != null && m.groupName!.isNotEmpty;

      if (isGrouped) {
        if (seenGroups.contains(m.groupName)) continue; // すでに処理済みの団体戦はスキップ
        seenGroups.add(m.groupName!);

        // この団体戦（グループ）に属するすべての試合を取得
        final groupMatches = matches.where((gm) => gm.groupName == m.groupName).toList();

        // 団体戦全体の状態を判定
        final allWaiting = groupMatches.every((gm) => gm.status == 'waiting');
        final allDone = groupMatches.every((gm) => gm.status == 'finished' || gm.status == 'approved');

        if (!allWaiting && !allDone) {
          // 一部だけ終わっている、または進行中の試合が含まれている＝「団体戦として進行中」
          uniqueInProgress.add(m);
        } else if (allWaiting) {
          // まだどのポジションの試合も始まっていない＝「待機中（次試合候補）」
          uniqueWaiting.add(m);
        }
      } else {
        // 個人戦などの場合（グループ化されていない）
        if (m.status == 'in_progress') {
          uniqueInProgress.add(m);
        } else if (m.status == 'waiting') {
          uniqueWaiting.add(m);
        }
      }
    }

    final matchesByCategory = <String, List<MatchModel>>{};
    for (var m in matches) {
      final cat = (m.category != null && m.category!.isNotEmpty) ? m.category! : 'カテゴリ未設定（全体）';
      matchesByCategory.putIfAbsent(cat, () => []).add(m);
    }

    return Scaffold(
      backgroundColor: bgColor, 
      appBar: AppBar(
        title: Text('大会ホーム', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor)),
        backgroundColor: Colors.transparent, 
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: () => context.go('/'), 
              icon: Icon(Icons.home, color: isDark ? Colors.white : Colors.indigo.shade700, size: 18),
              label: Text('トップへ', style: TextStyle(color: isDark ? Colors.white : Colors.indigo.shade700, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.indigo.shade50, 
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ★ uniqueInProgress, uniqueWaiting を使用して、時系列順に表示
          if (uniqueInProgress.isNotEmpty || uniqueWaiting.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.indigo.shade800,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.indigo.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  if (uniqueInProgress.isNotEmpty)
                    _buildCallRow('進行中', uniqueInProgress.first, Colors.orangeAccent),
                  if (uniqueInProgress.isNotEmpty && uniqueWaiting.isNotEmpty) 
                    const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(color: Colors.white24, height: 1)),
                  if (uniqueWaiting.isNotEmpty)
                    _buildCallRow('次試合', uniqueWaiting.first, Colors.white),
                  if (uniqueWaiting.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        // ★ 修正：次々試合も、団体戦ならチーム名を表示
                        '次々試合: ${uniqueWaiting[1].note.isNotEmpty ? "(${uniqueWaiting[1].note}) " : ""}${_getMatchTitle(uniqueWaiting[1])}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 60, 
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade600, 
                    borderRadius: BorderRadius.circular(16), 
                    boxShadow: [BoxShadow(color: Colors.indigo.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))], 
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/setup-match/$tournamentId'),
                    icon: const Icon(Icons.add_circle, color: Colors.white, size: 24),
                    label: const Text('この大会に試合を追加する', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => StandingsScreen(tournamentId: tournamentId))),
                        icon: Icon(Icons.emoji_events, size: 18, color: Colors.amber.shade600),
                        label: Text('自チーム成績', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : Colors.grey.shade800)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: isDark ? const Color(0xFF38383A) : Colors.grey.shade300),
                          backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => OfficialRecordScreen(tournamentId: tournamentId))),
                        icon: Icon(Icons.print, size: 18, color: isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade600),
                        label: Text('出力用スコア', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : Colors.grey.shade800)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: isDark ? const Color(0xFF38383A) : Colors.grey.shade300),
                          backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 80),
              children: [
                ref.watch(tournamentProvider(tournamentId)).when(
                  data: (tournament) => tournament != null 
                    ? _buildTournamentInfoCard(context, ref, tournament)
                    : const SizedBox.shrink(),
                  loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
                  error: (e, s) => Text('大会情報の読み込みに失敗しました: $e'),
                ),
                
                // ★ 追加：並び替え操作UI
                if (matchesByCategory.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('試合リスト', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700)),
                        OutlinedButton.icon(
                          onPressed: () => ref.read(categorySortProvider.notifier).state = !ref.read(categorySortProvider),
                          icon: Icon(ref.watch(categorySortProvider) ? Icons.arrow_downward : Icons.arrow_upward, size: 16),
                          label: Text(ref.watch(categorySortProvider) ? 'カテゴリ昇順' : 'カテゴリ降順', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? Colors.indigo.shade300 : Colors.indigo.shade700,
                            side: BorderSide(color: isDark ? const Color(0xFF38383A) : Colors.indigo.shade200),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                            minimumSize: const Size(0, 32),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // ★ 修正：カテゴリを単なるあいうえお順ではなく「年齢・学年順」で賢くソートする
                ...(() {
                  final sortedEntries = matchesByCategory.entries.toList();
                  final isAscending = ref.watch(categorySortProvider);
                  
                  // カテゴリの論理的な強さ（年齢順）を計算する魔法のヘルパー
                  int getWeight(String cat) {
                    if (cat.contains('初心者')) return 10;
                    if (cat.contains('幼年')) return 20;
                    if (cat.contains('小学生')) {
                      if (cat.contains('1年')) return 31;
                      if (cat.contains('2年')) return 32;
                      if (cat.contains('3年')) return 33;
                      if (cat.contains('4年')) return 34;
                      if (cat.contains('5年')) return 35;
                      if (cat.contains('6年')) return 36;
                      if (cat.contains('低学年')) return 38;
                      if (cat.contains('高学年')) return 39;
                      return 30; // 学年指定なしの小学生
                    }
                    if (cat.contains('中学生')) return 40;
                    if (cat.contains('高校生')) return 50;
                    if (cat.contains('大学') || cat.contains('一般') || cat.contains('シニア')) return 60;
                    return 999;
                  }

                  sortedEntries.sort((a, b) {
                    final weightA = getWeight(a.key);
                    final weightB = getWeight(b.key);
                    if (weightA != weightB) {
                      return isAscending ? weightA.compareTo(weightB) : weightB.compareTo(weightA);
                    }
                    // 重みが同じ場合（例：小学生男子と小学生女子など）は文字列表現でソート
                    return isAscending ? a.key.compareTo(b.key) : b.key.compareTo(a.key);
                  });

                  return sortedEntries.map((catEntry) {
                    final categoryName = catEntry.key;
                    final catMatches = catEntry.value;

                    final catGroupedMatches = <String, List<MatchModel>>{};
                  final catIndividualMatches = <MatchModel>[];

                  for (var m in catMatches) {
                    if (m.groupName != null && m.groupName!.isNotEmpty) {
                      catGroupedMatches.putIfAbsent(m.groupName!, () => []).add(m);
                    } else {
                      catIndividualMatches.add(m);
                    }
                  }

                // ★ 修正：1試合しかないグループは「団体戦」の折りたたみを作らず、単発の個人試合としてリストに直接出す
                final actualGroupedMatches = <String, List<MatchModel>>{};
                for (var entry in catGroupedMatches.entries) {
                  if (entry.value.length > 1) {
                    actualGroupedMatches[entry.key] = entry.value;
                  } else {
                    // 1試合しかないなら、単発試合のリストへ合流させる
                    catIndividualMatches.addAll(entry.value);
                  }
                }

                // ★ 修正：再分類されたリストでソートを行う
                for (var list in actualGroupedMatches.values) {
                    list.sort((a, b) => a.order.compareTo(b.order));
                  }
                  catIndividualMatches.sort((a, b) => b.order.compareTo(a.order));

                final sortedGroups = actualGroupedMatches.entries.toList();
                  sortedGroups.sort((a, b) {
                    final aOrder = a.value.first.order;
                    final bOrder = b.value.first.order;
                    return bOrder.compareTo(aOrder); 
                  });

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 16, 8),
                        child: Text(categoryName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 1.2)),
                      ),
                      ...sortedGroups.map((entry) {
                        final groupList = entry.value;
                        final firstMatch = groupList.first;
                        final rTeam = firstMatch.redName.contains(':') ? firstMatch.redName.split(':').first.trim() : firstMatch.redName;
                        final wTeam = firstMatch.whiteName.contains(':') ? firstMatch.whiteName.split(':').first.trim() : firstMatch.whiteName;
                        final groupTitle = '$rTeam vs $wTeam';
                        
                        final hasInProgress = groupList.any((m) => m.status == 'in_progress');
                        final allFinished = groupList.every((m) => m.status == 'finished' || m.status == 'approved');

                        final cardColor = hasInProgress ? (isDark ? const Color(0xFF1C1C1E) : Colors.white) : (allFinished ? (isDark ? const Color(0xFF121212) : Colors.grey.shade200) : (isDark ? const Color(0xFF1C1C1E) : Colors.white));
                        final borderColor = hasInProgress ? Colors.indigo.shade400 : (allFinished ? (isDark ? const Color(0xFF38383A) : Colors.grey.shade300) : (isDark ? const Color(0xFF38383A) : Colors.grey.shade300));
                        final double borderWidth = hasInProgress ? 2.0 : (isDark ? 0.5 : 1.0);
                        final titleColor = hasInProgress ? (isDark ? Colors.indigo.shade300 : Colors.indigo.shade900) : (allFinished ? Colors.grey.shade500 : textColor);
                        final subTitleColor = hasInProgress ? (isDark ? Colors.indigo.shade400 : Colors.indigo.shade600) : (allFinished ? Colors.grey.shade500 : (isDark ? const Color(0xFF8E8E93) : Colors.grey.shade700));

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          elevation: hasInProgress ? 4 : 0, 
                          color: cardColor,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(color: borderColor, width: borderWidth),
                            borderRadius: BorderRadius.circular(12), // iOS標準
                          ),
                          child: ExpansionTile(
                            shape: const Border(), 
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (firstMatch.note.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(firstMatch.note, style: TextStyle(fontSize: 11, color: subTitleColor, fontWeight: FontWeight.bold)),
                                  ),
                                Text('団体戦: $groupTitle', style: TextStyle(fontWeight: FontWeight.bold, color: titleColor)),
                              ],
                            ),
                            subtitle: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${groupList.length}試合 • ${allFinished ? '全試合終了' : (hasInProgress ? '試合進行中' : '待機中')}',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: subTitleColor, fontSize: 12, fontWeight: hasInProgress ? FontWeight.bold : FontWeight.normal),
                                  ),
                                ),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                    minimumSize: const Size(0, 32),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    foregroundColor: allFinished ? Colors.grey.shade600 : (isDark ? Colors.indigo.shade300 : Colors.indigo.shade600),
                                    side: BorderSide(color: allFinished ? (isDark ? const Color(0xFF38383A) : Colors.grey.shade400) : Colors.indigo.shade200),
                                    backgroundColor: allFinished ? (isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100) : (isDark ? const Color(0xFF2C2C2E) : Colors.white),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: const Icon(Icons.grid_on, size: 14),
                                  label: const Text('スコア', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)), 
                                  onPressed: () {
                                    if (firstMatch.isKachinuki) {
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => KachinukiScoreboardScreen(groupName: entry.key)));
                                    } else {
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => TeamScoreboardScreen(groupName: entry.key)));
                                    }
                                  },
                                ),
                              ],
                            ),
                            children: groupList.map((match) => _buildMatchListTile(context, ref, match)).toList(),
                          ),
                        );
                      }),
                      
                      // 個人戦用のリスト描画
                      if (catIndividualMatches.isNotEmpty) ...catIndividualMatches.map((match) {
                        final isFinished = match.status == 'finished' || match.status == 'approved';
                        final isPlaying = match.status == 'in_progress';
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          elevation: isPlaying ? 4 : 0,
                          color: isFinished ? (isDark ? const Color(0xFF121212) : Colors.grey.shade200) : (isDark ? const Color(0xFF1C1C1E) : Colors.white),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12), 
                            side: BorderSide(
                              color: isPlaying ? Colors.indigo.shade400 : (isFinished ? (isDark ? const Color(0xFF38383A) : Colors.grey.shade300) : (isDark ? const Color(0xFF38383A) : Colors.grey.shade300)),
                              width: isPlaying ? 2 : (isDark ? 0.5 : 1.0)
                            )
                          ),
                          child: _buildMatchListTile(context, ref, match),
                        );
                      }),
                      const SizedBox(height: 8),
                    ],
                  );
                }); // ★ 修正1：return文を終わらせるため「,」ではなく「;」にする
              })(), // ★ 修正2：囲った関数を実行する「()」を追加して「,」で繋ぐ
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTournamentInfoCard(BuildContext context, WidgetRef ref, TournamentModel tournament) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF38383A) : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? const Color(0xFF8E8E93) : Colors.grey.shade700;
    final iconBgColor = isDark ? Colors.amber.shade900.withValues(alpha: 0.3) : Colors.amber.shade50;
    final popupIconColor = isDark ? Colors.grey.shade400 : Colors.grey.shade500;
    final noteBgColor = isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade50;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: borderColor, width: isDark ? 0.5 : 1.0)),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
                  child: const Icon(Icons.emoji_events, color: Colors.amber, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(tournament.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_horiz, color: popupIconColor),
                  color: cardColor,
                  onSelected: (value) async {
                    if (value == 'edit') {
                      final nameController = TextEditingController(text: tournament.name);
                      final venueController = TextEditingController(text: tournament.venue);
                      final notesController = TextEditingController(text: tournament.notes);
                      DateTime selectedDate = tournament.date;

                      showDialog(
                        context: context,
                        builder: (ctx) => StatefulBuilder( 
                          builder: (context, setState) {
                            return AlertDialog(
                              backgroundColor: cardColor,
                              title: Text('大会情報の編集', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              content: SingleChildScrollView( 
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextField(controller: nameController, style: TextStyle(color: textColor), decoration: InputDecoration(labelText: '大会名', labelStyle: TextStyle(color: subTextColor), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: borderColor)))),
                                    const SizedBox(height: 12),
                                    InkWell(
                                      onTap: () async {
                                        final DateTime? picked = await showDatePicker(
                                          context: context, initialDate: selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2030),
                                        );
                                        if (picked != null && picked != selectedDate) setState(() => selectedDate = picked);
                                      },
                                      child: InputDecorator(
                                        decoration: InputDecoration(labelText: '開催年月日', labelStyle: TextStyle(color: subTextColor), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: borderColor))),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(DateFormat('yyyy年MM月dd日').format(selectedDate), style: TextStyle(color: textColor)),
                                            Icon(Icons.calendar_today, size: 20, color: isDark ? Colors.indigo.shade400 : Colors.indigo.shade600),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(controller: venueController, style: TextStyle(color: textColor), decoration: InputDecoration(labelText: '会場・住所', labelStyle: TextStyle(color: subTextColor), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: borderColor)))),
                                    const SizedBox(height: 12),
                                    TextField(controller: notesController, style: TextStyle(color: textColor), decoration: InputDecoration(labelText: '大会メモ（任意）', labelStyle: TextStyle(color: subTextColor), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: borderColor))), maxLines: 3),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル', style: TextStyle(color: Colors.grey))),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo.shade600, foregroundColor: Colors.white, elevation: 0),
                                  onPressed: () async {
                                    await ref.read(tournamentRepositoryProvider).updateTournamentDetails(
                                      tournament.id, name: nameController.text, venue: venueController.text, notes: notesController.text, date: selectedDate,
                                    );
                                    if (ctx.mounted) Navigator.pop(ctx);
                                  },
                                  child: const Text('保存'),
                                ),
                              ],
                            );
                          }
                        ),
                      );
                    } else if (value == 'delete') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: cardColor,
                          title: Text('大会の削除', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                          content: Text('この大会を削除しますか？', style: TextStyle(color: textColor)),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('キャンセル')),
                            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('削除', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await ref.read(tournamentRepositoryProvider).deleteTournament(tournament.id);
                        if (context.mounted) context.go('/');
                      }
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18, color: textColor), const SizedBox(width: 8), Text('編集', style: TextStyle(color: textColor))])),
                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 18), SizedBox(width: 8), Text('削除', style: TextStyle(color: Colors.red))])),
                  ],
                ),
              ],
            ),
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: borderColor)),
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.grey.shade500, size: 16),
                const SizedBox(width: 8),
                Text(DateFormat('yyyy年MM月dd日').format(tournament.date), style: TextStyle(color: subTextColor, fontSize: 13)),
                const SizedBox(width: 16),
                Icon(Icons.location_on, color: Colors.grey.shade500, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(tournament.venue, style: TextStyle(color: subTextColor, fontSize: 13), overflow: TextOverflow.ellipsis)),
              ],
            ),
            if (tournament.notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: noteBgColor, borderRadius: BorderRadius.circular(8)),
                child: Text(tournament.notes, style: TextStyle(color: textColor, fontSize: 13)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMatchListTile(BuildContext context, WidgetRef ref, MatchModel match) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFinished = match.status == 'finished' || match.status == 'approved';
    final isPlaying = match.status == 'in_progress';
    final isApproved = match.status == 'approved';

    final bgColor = Colors.transparent; 
    final iconBgColor = isPlaying ? Colors.indigo.shade600 : (isApproved ? (isDark ? Colors.teal.shade900.withValues(alpha: 0.5) : Colors.teal.shade100) : (isFinished ? (isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade300) : (isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade100)));
    final iconColor = isPlaying ? Colors.white : (isApproved ? (isDark ? Colors.teal.shade400 : Colors.teal.shade700) : (isFinished ? Colors.grey.shade500 : (isDark ? Colors.grey.shade400 : Colors.grey.shade600)));
    final iconData = isPlaying ? Icons.play_arrow_rounded : (isApproved ? Icons.verified : (isFinished ? Icons.check_rounded : Icons.schedule_rounded));

    final noteColor = isPlaying ? (isDark ? Colors.indigo.shade300 : Colors.indigo.shade600) : (isFinished ? Colors.grey.shade500 : Colors.blueGrey);
    final titleColor = isFinished ? Colors.grey.shade500 : (isDark ? Colors.white : Colors.black87);

    return Container(
      color: bgColor,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(isPlaying ? 8 : 18), 
            boxShadow: isPlaying ? [BoxShadow(color: Colors.indigo.withValues(alpha: 0.3), blurRadius: 4)] : null,
          ),
          child: Icon(iconData, color: iconColor, size: 20),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (match.note.isNotEmpty)
              Text(match.note, style: TextStyle(fontSize: 10, color: noteColor, fontWeight: FontWeight.bold)),
            Text(
              // ★ 修正：個人戦などで表示される「【選手】」のみを非表示にする（団体戦の役職名はそのまま）
              (match.matchType.isNotEmpty && match.matchType != '選手') 
                ? '【${match.matchType}】 ${match.redName} vs ${_reverseWhiteName(match.whiteName)}' 
                : '${match.redName} vs ${_reverseWhiteName(match.whiteName)}', 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: titleColor)
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: Colors.grey.shade400, size: 20),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                title: Text('試合の削除', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                content: Text('削除しますか？', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('キャンセル')),
                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('削除', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                ],
              ),
            );
            // ★ 修正: matchCommandProvider を使用
            if (confirm == true) await ref.read(matchCommandProvider).deleteMatch(match.id);
          },
        ),
        onTap: () => context.push('/match/${match.id}'),
      ),
    );
  }

  Widget _buildCallRow(String label, dynamic match, Color textColor) {
    return Column(
      children: [
        if (match.note.isNotEmpty)
          Text(match.note, style: TextStyle(color: textColor.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.bold)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
            const SizedBox(width: 12),
            // ★ 個人の名前ではなく、団体戦ならチーム名を表示
            Text(_getMatchTitle(match), style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  // ★ 団体戦か個人戦かを判定してタイトルを返すヘルパー
  String _getMatchTitle(dynamic match) {
    final isGrouped = match.groupName != null && match.groupName!.isNotEmpty;
    
    if (isGrouped) {
      final rTeam = match.redName.contains(':') ? match.redName.split(':').first.trim() : match.redName;
      final wTeam = match.whiteName.contains(':') ? match.whiteName.split(':').first.trim() : match.whiteName;
      return '$rTeam vs $wTeam';
    }
    
    return '${match.redName} vs ${_reverseWhiteName(match.whiteName)}';
  }

  String _reverseWhiteName(String whiteName) {
    if (!whiteName.contains(':')) {
      return whiteName;
    }
    final parts = whiteName.split(':');
    if (parts.length != 2) {
      return whiteName;
    }
    final teamName = parts[0].trim();
    final playerName = parts[1].trim();
    return '$playerName : $teamName';
  }
}