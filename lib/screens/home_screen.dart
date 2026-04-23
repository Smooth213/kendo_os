import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/match_model.dart';
import '../providers/match_list_provider.dart';
import '../providers/match_command_provider.dart';
import 'standings_screen.dart';
import 'official_record_screen.dart';
import '../models/tournament_model.dart';
import '../repositories/tournament_repository.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../repositories/player_repository.dart';

// ★ Phase 7: 閲覧権限によるUI制御のため追加
import '../providers/permission_provider.dart';

final tournamentProvider = StreamProvider.family<TournamentModel?, String>((ref, id) {
  final repo = ref.watch(tournamentRepositoryProvider);
  return repo.getTournamentStream(id);
});

// ★ 追加：カテゴリの並び順（昇順/降順）を管理するプロバイダ (true: 昇順, false: 降順)
final categorySortProvider = StateProvider.autoDispose<bool>((ref) => true);

// ★ 追加：マスタで登録された「自チーム名」を取得して、ホーム画面の箱を作る基準にする
final customTeamNamesProvider = StreamProvider.autoDispose<List<String>>((ref) {
  return ref.watch(playerRepositoryProvider).watchCustomTeamNames();
});

class HomeScreen extends ConsumerWidget {
  final String tournamentId;
  const HomeScreen({super.key, required this.tournamentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // ★ Phase 7: 現在の権限（Permission）を取得
    final permissions = ref.watch(permissionProvider);
    
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

    // ★ Phase 7: 閲覧者の場合は「戻る」を禁止し、大会内にロックする
    return PopScope(
      canPop: !permissions.isReadOnly, // 閲覧者はシステムの戻るボタンを無効化
      child: Scaffold(
        backgroundColor: bgColor, 
        appBar: AppBar(
          automaticallyImplyLeading: !permissions.isReadOnly, // 閲覧者には左側の「戻る」を出さない
          title: Text('大会ホーム', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor)),
          backgroundColor: Colors.transparent, 
          elevation: 0,
          iconTheme: IconThemeData(color: textColor),
          actions: [
            // ★ Phase 7: 閲覧専用モードでは「トップへ」を隠し、QR共有を置く
            if (!permissions.isReadOnly)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: ElevatedButton.icon(
                onPressed: () => context.go('/'), 
                icon: Icon(Icons.home, color: isDark ? Colors.white : Colors.indigo.shade700, size: 18),
                label: Text('トップへ', style: TextStyle(color: isDark ? Colors.white : Colors.indigo.shade700, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.indigo.shade50, 
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
          // ★ 案A：AppBarの右端にQR共有ボタンを集約
          IconButton(
            icon: Icon(Icons.qr_code_2, color: isDark ? Colors.white : Colors.indigo.shade900),
            tooltip: '大会を共有する',
            onPressed: () => _showShareDialog(context, tournamentId),
          ),
          const SizedBox(width: 8),
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
                // ★ 修正：試合作成権限（canCreateMatch）がある場合のみ表示（管理者・記録係）
                if (permissions.canCreateMatch) ...[
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
                ],
                
                // ★ Step 2-3: プログラム画面への入り口（全員が見えるが、権限でラベルが変わる）
                Container(
                  width: double.infinity,
                  height: 50,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/tournament/$tournamentId/programs'),
                    icon: Icon(
                      Icons.picture_as_pdf, 
                      size: 20, 
                      color: isDark ? Colors.redAccent.shade100 : Colors.red.shade600
                    ),
                    label: Text(
                      permissions.isReadOnly ? '大会プログラムを見る' : '大会プログラムの管理', 
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : Colors.grey.shade800)
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: isDark ? const Color(0xFF38383A) : Colors.grey.shade300),
                      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ★ Phase 7: 閲覧専用モードでは「自チーム成績」を非表示にする
                    if (!permissions.isReadOnly) ...[
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
                    ],
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => OfficialRecordScreen(tournamentId: tournamentId))),
                        icon: Icon(Icons.print, size: 18, color: isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade600),
                        // ★ Phase 7: 役割に応じてボタンのラベルを変更（現場UX対応）
                        label: Text(
                          permissions.isReadOnly ? '全試合スコア' : '出力用スコア', 
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : Colors.grey.shade800)
                        ),
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
                
                // ★ 修正：カテゴリを単なるあいうえお順ではなく「年齢・学年順」で賢くソートし、さらにチーム別ツリー構造にする
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
                      return 30;
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
                    return isAscending ? a.key.compareTo(b.key) : b.key.compareTo(a.key);
                  });

                  return sortedEntries.map((catEntry) {
                    final categoryName = catEntry.key;
                    final catMatches = catEntry.value;

                    // ★ 1. 修正：「マスタに登録されている自チーム」だけの箱を作る最強ロジック
                    final ownTeams = ref.watch(customTeamNamesProvider).value ?? [];
                    final matchesByTeam = <String, List<MatchModel>>{};
                    
                    for (var m in catMatches) {
                      String rTeam = m.redName.contains(':') ? m.redName.split(':').first.trim() : m.redName;
                      String wTeam = m.whiteName.contains(':') ? m.whiteName.split(':').first.trim() : m.whiteName;
                      
                      bool isRedOwn = ownTeams.contains(rTeam);
                      bool isWhiteOwn = ownTeams.contains(wTeam);

                      // 自チームが赤なら赤の箱へ
                      if (isRedOwn) matchesByTeam.putIfAbsent(rTeam, () => []).add(m);
                      // 自チームが白なら白の箱へ
                      if (isWhiteOwn && wTeam != rTeam) matchesByTeam.putIfAbsent(wTeam, () => []).add(m);
                      
                      // ※もし手入力ミスなどで「両方とも自チームリストにない」場合は、迷子を防ぐため強引に赤チームの箱を作る
                      if (!isRedOwn && !isWhiteOwn && rTeam.isNotEmpty && !rTeam.contains('代表')) {
                         matchesByTeam.putIfAbsent(rTeam, () => []).add(m);
                      }
                    }

                    // チーム名でソート（あいうえお順）
                    final sortedTeams = matchesByTeam.entries.toList();
                    sortedTeams.sort((a, b) => a.key.compareTo(b.key));

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        // --- カテゴリのヘッダー ---
                      Padding(
                          padding: const EdgeInsets.fromLTRB(24, 24, 16, 12),
                          child: Text(categoryName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.indigo.shade300 : Colors.indigo.shade800, letterSpacing: 1.2)),
                      ),
                        
                        // --- ★ 2. 各チームの専用ブロック（ツリー構造）を描画 ---
                        ...sortedTeams.map((teamEntry) {
                          final teamName = teamEntry.key;
                          final teamMatchesList = teamEntry.value;

                          // 1. 表示ラベルを判定する賢い関数
                          String getMatchLabel(MatchModel m) {
                            final bool isLeague = m.matchType == 'league';
                            final bool isIndividual = m.matchType == 'individual';
                            final bool isKachinuki = m.isKachinuki;

                            if (isLeague) return isIndividual ? '個人戦/リーグ戦' : '団体戦/リーグ戦';
                            if (isKachinuki) return '団体戦/勝ち抜き戦';
                            return isIndividual ? '個人戦' : '団体戦';
                          }

                          // 2. 団体戦（グループ名あり）と個人戦（単発）に分類
                          final catGroupedMatches = <String, List<MatchModel>>{};
                          final catIndividualMatches = <MatchModel>[];

                          for (var m in teamMatchesList) {
                            if (m.groupName != null && m.groupName!.isNotEmpty) {
                              catGroupedMatches.putIfAbsent(m.groupName!, () => []).add(m);
                            } else {
                              catIndividualMatches.add(m);
                            }
                          }

                          // 3. 団体戦リストの整理（1試合しかないグループは個人戦へ）
                          final actualGroupedMatches = <String, List<MatchModel>>{};
                          for (var entry in catGroupedMatches.entries) {
                            if (entry.value.length > 1) {
                              actualGroupedMatches[entry.key] = entry.value;
                            } else {
                              catIndividualMatches.addAll(entry.value);
                            }
                          }

                          // 4. ★個人戦を「選手名」でさらにまとめる（ご要望の階層構造）
                          final matchesByPlayer = <String, List<MatchModel>>{};
                          for (var m in catIndividualMatches) {
                            String playerName = '選手名不明';
                            if (m.redName.contains(teamName)) {
                              playerName = m.redName.contains(':') ? m.redName.split(':').last.trim() : m.redName;
                            } else if (m.whiteName.contains(teamName)) {
                              playerName = m.whiteName.contains(':') ? m.whiteName.split(':').last.trim() : m.whiteName;
                            }
                            matchesByPlayer.putIfAbsent(playerName, () => []).add(m);
                          }

                          // ソート
                          final sortedGroups = actualGroupedMatches.entries.toList()
                            ..sort((a, b) => b.value.first.order.compareTo(a.value.first.order));
                          final sortedPlayers = matchesByPlayer.entries.toList()
                            ..sort((a, b) => a.key.compareTo(b.key));

                          return Container(
                            margin: const EdgeInsets.only(left: 12, right: 12, bottom: 24),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF161618) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isDark ? const Color(0xFF38383A) : Colors.grey.shade300, width: 2),
                              boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 4))],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // --- 🏢 チーム名ヘッダー ---
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.indigo.shade900.withValues(alpha: 0.3) : Colors.indigo.shade50,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                                    border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF38383A) : Colors.indigo.shade100)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.business, color: isDark ? Colors.indigo.shade300 : Colors.indigo.shade700, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(teamName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.indigo.shade900))),
                                      
                                      // ★ 修正：管理者・記録係のみチーム名の編集（一括統合）を許可する
                                      if (!permissions.isReadOnly)
                                        IconButton(
                                          icon: Icon(Icons.edit_note, color: isDark ? Colors.indigo.shade400 : Colors.indigo.shade300, size: 20),
                                          tooltip: 'チーム名を修正して統合',
                                          onPressed: () => _showRenameTeamSheet(context, ref, tournamentId, teamName),
                                        ),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(height: 8),

                                // --- 👥 団体戦セクション ---
                                ...(() {
                                  String lastGroupLabel = ''; // 前の試合のラベルを記憶する変数
                                  
                                  return sortedGroups.map((entry) {
                                    final groupList = entry.value;
                                    final firstMatch = groupList.first;
                                    final label = getMatchLabel(firstMatch); // ★新ラベル取得
                                    
                                    Widget? headerWidget;
                                    // ★ 修正：前のグループと試合形式（ラベル）が変わった時だけ、新しいヘッダーを表示する
                                    if (label != lastGroupLabel) {
                                      headerWidget = Padding(
                                        padding: const EdgeInsets.only(left: 16, top: 12, bottom: 4),
                                        child: Row(
                                          children: [
                                            Icon(Icons.groups, color: isDark ? Colors.indigo.shade300 : Colors.indigo.shade700, size: 16),
                                            const SizedBox(width: 4),
                                            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.indigo.shade300 : Colors.indigo.shade700)),
                                          ],
                                        ),
                                      );
                                      lastGroupLabel = label;
                                    }
                                    
                                    final rTeam = firstMatch.redName.contains(':') ? firstMatch.redName.split(':').first.trim() : firstMatch.redName;
                                    final wTeam = firstMatch.whiteName.contains(':') ? firstMatch.whiteName.split(':').first.trim() : firstMatch.whiteName;
                                    
                                    final hasInProgress = groupList.any((m) => m.status == 'in_progress');
                                    final allFinished = groupList.every((m) => m.status == 'finished' || m.status == 'approved');
                                    final subTitleColor = hasInProgress ? (isDark ? Colors.indigo.shade400 : Colors.indigo.shade600) : (allFinished ? Colors.grey.shade500 : (isDark ? const Color(0xFF8E8E93) : Colors.grey.shade700));

                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // ★ ヘッダーが必要な時だけ出力
                                        ?headerWidget,
                                        
                                        Card(
                                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          elevation: hasInProgress ? 4 : 0, 
                                          color: allFinished ? (isDark ? const Color(0xFF121212) : Colors.grey.shade100) : (isDark ? const Color(0xFF1C1C1E) : Colors.white),
                                          shape: RoundedRectangleBorder(
                                            side: BorderSide(color: hasInProgress ? Colors.indigo.shade400 : (isDark ? const Color(0xFF38383A) : Colors.grey.shade300), width: hasInProgress ? 2.0 : 1.0),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: ExpansionTile(
                                            title: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                if (firstMatch.note.isNotEmpty)
                                                  Padding(
                                                    padding: const EdgeInsets.only(bottom: 4),
                                                    child: Text(firstMatch.note, style: TextStyle(fontSize: 11, color: subTitleColor, fontWeight: FontWeight.bold)),
                                                  ),
                                                Row(
                                                  children: [
                                                    // ★ 修正：タイトルから "$label: " を削除し、純粋な「チーム vs チーム」にする！
                                                    Expanded(child: Text('$rTeam vs $wTeam', style: TextStyle(fontWeight: FontWeight.bold, color: hasInProgress ? (isDark ? Colors.indigo.shade300 : Colors.indigo.shade900) : textColor))),
                                                    
                                                    // 同門対決バッジ
                                                    if (ownTeams.contains(rTeam) && ownTeams.contains(wTeam))
                                                      Container(
                                                        margin: const EdgeInsets.only(left: 8),
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                        decoration: BoxDecoration(color: Colors.pink.shade100, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.pink.shade300)),
                                                        child: Text('⚔️ 同門対決', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.pink.shade800)),
                                                      ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            subtitle: Text('${groupList.length}試合 • ${allFinished ? '終了' : '進行中'}', style: TextStyle(color: subTitleColor, fontSize: 12)),
                                            children: groupList.map((match) => _buildMatchListTile(context, ref, match)).toList(),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList();
                                })(),

                                // --- 👤 個人戦セクション（選手ごとにまとめる） ---
                                if (sortedPlayers.isNotEmpty) ...[
                                  Padding(
                                    padding: const EdgeInsets.only(left: 16, top: 4, bottom: 8),
                                    child: Row(
                                      children: [
                                        Icon(Icons.person, color: Colors.orange.shade700, size: 16),
                                        const SizedBox(width: 4),
                                        Text('個人戦', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.orange.shade700)),
                                      ],
                                    ),
                                  ),
                                  ...sortedPlayers.map((playerEntry) {
                                    final playerName = playerEntry.key;
                                    final playerMatches = playerEntry.value;
                                    final firstMatch = playerMatches.first;
                                    final label = getMatchLabel(firstMatch); // ★新ラベル取得

                                    return Card(
                                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      elevation: 0,
                                      color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isDark ? const Color(0xFF38383A) : Colors.grey.shade300)),
                                      child: ExpansionTile(
                                        leading: CircleAvatar(backgroundColor: Colors.orange.shade100, child: Text(playerName[0], style: TextStyle(color: Colors.orange.shade800, fontSize: 12, fontWeight: FontWeight.bold))),
                                        title: Text(playerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                        subtitle: Text('$label • ${playerMatches.length}試合', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                        children: playerMatches.map((match) => _buildMatchListTile(context, ref, match)).toList(),
                                      ),
                                    );
                                  }),
                                ],
                                const SizedBox(height: 8),
                              ],
                            ),
                          );
                        }),
                    ],
                  );
                }); // ★ 修正1：return文を終わらせるため「,」ではなく「;」にする
              })(), // ★ 修正2：囲った関数を実行する「()」を追加して「,」で繋ぐ
              ],
            ),
          ),
        ],
      ),
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
                // ★ 修正：大会管理権限（canManageTournament）がある場合のみ表示（管理者限定）
                if (ref.watch(permissionProvider).canManageTournament)
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
        // ★ Phase 7: 閲覧専用モードではゴミ箱（削除）ボタンを完全に隠す
        trailing: ref.watch(permissionProvider).isReadOnly ? null : IconButton(
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

  // ★ Phase 7: 大会全体の共有ダイアログ
  void _showShareDialog(BuildContext context, String tournamentId) {
    final String shareUrl = 'https://kendo-os.web.app/home/$tournamentId?role=viewer';
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('大会観戦リンク', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('この大会の全試合・スコアを\nリアルタイムで共有できます。', textAlign: TextAlign.center, style: TextStyle(fontSize: 13)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.white,
                child: QrImageView(
                  data: shareUrl,
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => SharePlus.instance.share(
                  ShareParams(text: '【剣道OS】大会の進行状況をリアルタイムで観戦できます！\n$shareUrl'),
                ),
                icon: const Icon(Icons.share),
                label: const Text('LINEやSNSでURLを送る'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, elevation: 0),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('閉じる', style: TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }

  // ★ 追加：チーム名を一括置換して合流させるためのボトムシート
  void _showRenameTeamSheet(BuildContext context, WidgetRef ref, String tournamentId, String oldName) {
    final controller = TextEditingController(text: oldName);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? Colors.indigo.shade300 : Colors.indigo.shade700;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(top: 16, left: 24, right: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 48, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 24),
            Text('チーム名の修正・統合', style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 18)),
            const SizedBox(height: 8),
            const Text('名前を修正すると、この大会内のすべての試合データが自動で書き換わり、同じ名前のチームと合流します。', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 24),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: '新しいチーム名',
                filled: true,
                fillColor: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final newName = controller.text.trim();
                  if (newName.isEmpty || newName == oldName) {
                    Navigator.pop(ctx);
                    return;
                  }
                  
                  // 実行
                  await ref.read(matchCommandProvider).renameTeamBulk(
                    tournamentId: tournamentId,
                    oldTeamName: oldName,
                    newTeamName: newName,
                  );
                  
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('チーム名を一括更新しました ✨')));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('一括修正して統合する', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}