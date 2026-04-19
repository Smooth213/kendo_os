import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../repositories/tournament_repository.dart';
import '../models/tournament_model.dart';
import '../providers/sync_provider.dart'; // ★ Phase 6: 手動同期用Providerのインポート

// ★ 直感UXホットフィックス：アーカイブ画面の即時反映用トリガー
final archiveRefreshProvider = StateProvider.autoDispose<int>((ref) => 0);

class TournamentListScreen extends ConsumerWidget {
  final bool isArchive;
  const TournamentListScreen({super.key, this.isArchive = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isArchive) ref.watch(archiveRefreshProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // iOS Native: イメージカラー「今日の大会(ブルー)」「過去の大会(グレー)」を完全復元
    final Color accentColor = isArchive 
        ? (isDark ? Colors.blueGrey.shade400 : Colors.blueGrey.shade600)
        : (isDark ? Colors.blue.shade400 : Colors.blue.shade600);
        
    final Color softAccentColor = isArchive
        ? (isDark ? Colors.blueGrey.withValues(alpha: 0.2) : Colors.blueGrey.shade50)
        : (isDark ? Colors.blue.withValues(alpha: 0.2) : Colors.blue.shade50);
        
    // iOS Native カラーパレット
    final Color bgColor = isDark ? Colors.black : const Color(0xFFF2F2F7);
    final Color cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color subTextColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF636366);
    final Color separatorColor = isDark ? const Color(0xFF38383A) : const Color(0xFFC6C6C8);

    final titleText = isArchive ? '過去の大会' : '今日の大会';

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        // ★ 修正：白飛びして見えなくなっていた戻るボタンを、タイトルと同じ色で明示的に配置！
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: accentColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(titleText, style: TextStyle(fontWeight: FontWeight.bold, color: accentColor, letterSpacing: 1.2)),
        backgroundColor: Colors.transparent, // 透かしAppBar
        elevation: 0,
      ),
      body: StreamBuilder<List<TournamentModel>>(
        stream: isArchive 
            ? Stream.fromFuture(ref.read(tournamentRepositoryProvider).getArchivedTournaments())
            : ref.watch(tournamentRepositoryProvider).watchTournaments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('エラーが発生しました: ${snapshot.error}'));
          
          final filteredTournaments = snapshot.data ?? [];
          filteredTournaments.sort((a, b) => b.date.compareTo(a.date));

          // ★ 直感UX改修：透かしアイコン（kendo_icon.png）を用いた極上のEmpty State
          if (filteredTournaments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/kendo_icon.png', 
                    width: 80, 
                    height: 80, 
                    color: isDark ? const Color(0xFF38383A) : Colors.grey.shade300, 
                  ),
                  const SizedBox(height: 24),
                  Text(
                    isArchive ? '過去の大会記録はありません' : '今日の大会はまだありません', 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: accentColor)
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isArchive ? '終了した大会がここにアーカイブされます。' : '新しい大会を作成して、本日の運営をスタートしましょう！', 
                    textAlign: TextAlign.center,
                    style: TextStyle(color: subTextColor, fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            );
          }

          // ★ Phase 6: 手動同期トリガー（引っ張って更新）の追加
          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(syncEngineProvider).forceSync();
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), // 余白の統一
              itemCount: filteredTournaments.length,
              itemBuilder: (context, index) {
              final tournament = filteredTournaments[index];
              final id = tournament.id;
              
              final currentMonth = DateFormat('yyyy年MM月').format(tournament.date);
              final previousMonth = index == 0 ? '' : DateFormat('yyyy年MM月').format(filteredTournaments[index - 1].date);
              final showHeader = currentMonth != previousMonth;

              Widget buildUnifiedCard() {
                // ★ Phase 7-2: スワイプして一括削除（Dismissible）の追加
                return Dismissible(
                  key: Key(id),
                  direction: DismissDirection.endToStart, // 右から左へのスワイプのみ許可
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      borderRadius: BorderRadius.circular(12), // カードの丸みと合わせる
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    // ★ 誤操作防止の確認ダイアログ
                    return await showDialog<bool>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('大会の削除'),
                          content: const Text('この大会と、紐づくすべての試合データを削除します。\n本当によろしいですか？\n（※この操作は取り消せません）'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('キャンセル'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('削除する', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  onDismissed: (direction) {
                    // 一括削除処理の実行
                    ref.read(tournamentRepositoryProvider).deleteTournament(id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('大会と関連データを削除しました')),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    color: cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), 
                      side: isDark ? BorderSide.none : BorderSide(color: separatorColor.withValues(alpha: 0.5), width: 0.5),
                    ),
                    child: InkWell(
                      onTap: () => context.push('/home/$id'),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: softAccentColor, shape: BoxShape.circle),
                              child: Icon(isArchive ? Icons.history : Icons.emoji_events, color: accentColor, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tournament.name, 
                                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: textColor)
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        DateFormat('yyyy年MM月dd日').format(tournament.date), 
                                        style: TextStyle(fontSize: 14, color: subTextColor)
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: subTextColor, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }

              // ★ 修正：月別ヘッダーが背景に溶けないよう、アクセントカラーを適用
              Widget header = const SizedBox.shrink();
              if (showHeader) {
                header = Padding(
                  padding: const EdgeInsets.only(top: 24, bottom: 12, left: 4),
                  child: Text(
                    currentMonth,
                    style: TextStyle(
                      fontSize: 14, 
                      fontWeight: FontWeight.bold, 
                      color: isDark ? accentColor : Colors.grey.shade500, // ★ ダーク時はアイコンと同じ色で光らせる
                      letterSpacing: 1.5
                    ),
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  header,
                  buildUnifiedCard(),
                ],
              );
            },
            ),
          );
        },
      ),
    );
  }
}