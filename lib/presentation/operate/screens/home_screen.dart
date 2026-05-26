import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import 'package:kendo_os/domain/entities/tournament_model.dart';
import 'package:kendo_os/infrastructure/repository/tournament_repository.dart';
import 'package:kendo_os/infrastructure/repository/player_repository.dart';

// ★ 古い permission_provider を排除し、新セキュリティ一元管理システムを導入
import '../../../domain/entities/user_role.dart';
import '../../shared/providers/current_user_role_provider.dart';
import '../providers/settings_provider.dart';

import '../../shared/widgets/liquid_background.dart';
import '../components/home/match_timeline_list.dart'; 
import '../components/home/operator_action_buttons.dart';
import '../providers/match_list_provider.dart';
import 'package:kendo_os/domain/match/match_model.dart';
import 'package:kendo_os/presentation/public/viewer/viewer_home_screen.dart';

final tournamentProvider = StreamProvider.family<TournamentModel?, String>((ref, id) {
  final repo = ref.watch(tournamentRepositoryProvider);
  return repo.getTournamentStream(id);
});

final categorySortProvider = StateProvider.autoDispose<bool>((ref) => true);
final searchQueryProvider = StateProvider.autoDispose<String>((ref) => '');
final isSearchVisibleProvider = StateProvider.autoDispose<bool>((ref) => false);

final customTeamNamesProvider = StreamProvider.autoDispose<List<String>>((ref) {
  return ref.watch(playerRepositoryProvider).watchCustomTeamNames();
});

class HomeScreen extends ConsumerWidget {
  final String tournamentId;
  const HomeScreen({super.key, required this.tournamentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ★ 状態を監視：現在のロールを取得
    final currentRole = ref.watch(currentUserRoleProvider);

    // ★ 核心: Viewerモードで入った場合は、自動的にViewer専用の美しい画面へルーティングする
    if (currentRole == UserRole.viewer) {
      return ViewerHomeScreen(tournamentId: tournamentId);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enableLiquidGlass = ref.watch(settingsProvider).enableLiquidGlass;    
    final bool isReadOnly = (currentRole == UserRole.viewer);
    final Color textColor = isDark ? Colors.white : Colors.black;

    final allMatchesList = ref.watch(matchListProvider).where((m) => m.tournamentId == tournamentId).toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    final uniqueInProgress = <MatchModel>[];
    final uniqueWaiting = <MatchModel>[];
    final seenMatchups = <String>{};

    for (var match in allMatchesList) {
      if (match.status == 'finished' || match.status == 'approved') continue;
      
      String key;
      if (match.note.contains('[リーグ戦]')) {
        final t1 = match.redName.split(':').first.trim();
        final t2 = match.whiteName.split(':').first.trim();
        final sortedTeams = [t1, t2]..sort();
        key = 'league_${match.groupName}_${sortedTeams.join("_")}';
      } else if (match.isKachinuki) {
        key = 'kachinuki_${match.groupName}';
      } else if (match.groupName != null && match.groupName!.isNotEmpty) {
        key = 'group_${match.groupName}';
      } else {
        key = 'match_${match.id}';
      }

      if (!seenMatchups.contains(key)) {
        seenMatchups.add(key);
        if (match.status == 'in_progress') {
          uniqueInProgress.add(match);
        } else if (match.status == 'waiting') {
          uniqueWaiting.add(match);
        }
      }
    }

    return PopScope(
      canPop: !isReadOnly,
      child: LiquidBackground(
        child: Column(
          children: [
            // =========================================================================
            // 🛡️ Phase 3 - STEP 3-3 要件：オフライン画面防衛インジケータバナー
            // 試合中に通信が途絶した際、操作員に「Isarによる现场継続エンジンが正常稼働していること」を
            // 明示し、視覚的な安心感を提供します。画面サイズを崩さないオーバーレイバー設計です。
            // =========================================================================
            Builder(
              builder: (context) {
                // 将来的に connectivity_plus または SyncEngine の保留キュー件数からリアルタイム判定
                // 暫定的にローカルDBストリームの異常状態をネットワーク切断として扱う
                final hasNetworkIssue = ref.watch(matchStreamProvider).hasError;
                if (!hasNetworkIssue) return const SizedBox.shrink();

                return SafeArea(
                  bottom: false,
                  child: Container(
                    width: double.infinity,
                    color: Colors.amber.shade900,
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '⚠️ 体育館オフライン運営モード：ローカルDB（Isar）へ即時保存中',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            Expanded(
              child: Scaffold(
                backgroundColor: Colors.transparent, 
                appBar: AppBar(
                  automaticallyImplyLeading: !isReadOnly, 
                  title: Text('大会ホーム', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor)),
                  backgroundColor: enableLiquidGlass ? Colors.transparent : (isDark ? const Color(0xFF1C1C1E) : Colors.white),
                  elevation: 0,
                  iconTheme: IconThemeData(color: textColor),
                  actions: [
                    if (!isReadOnly)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        child: ElevatedButton.icon(
                          onPressed: () => context.go('/'), 
                          icon: Icon(Icons.home, color: isDark ? Colors.white : Colors.indigo.shade700, size: 18),
                          label: Text('トップへ', style: TextStyle(color: isDark ? Colors.white : Colors.indigo.shade700, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.indigo.shade50, 
                            elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                      ),
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
                    // --- アクティブバナー ---
                    if (uniqueInProgress.isNotEmpty || uniqueWaiting.isNotEmpty)
                      Container(
                        width: double.infinity, margin: const EdgeInsets.fromLTRB(16, 4, 16, 12), padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.indigo.shade800, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.indigo.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))]),
                        child: Column(
                          mainAxisSize: MainAxisSize.min, // ★ 修正: Web特有のレイアウト（無限高）エラー対策
                          children: [
                            if (uniqueInProgress.isNotEmpty) _buildCallRow('進行中', uniqueInProgress.first, Colors.orangeAccent),
                            if (uniqueInProgress.isNotEmpty && uniqueWaiting.isNotEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(color: Colors.white24, height: 1)),
                            if (uniqueWaiting.isNotEmpty) _buildCallRow('次試合', uniqueWaiting.first, Colors.white),
                            if (uniqueWaiting.length > 1) Padding(padding: const EdgeInsets.only(top: 8), child: Text('次々試合: ${uniqueWaiting[1].note.isNotEmpty ? "(${uniqueWaiting[1].note}) " : ""}${_getMatchTitle(uniqueWaiting[1])}', style: const TextStyle(color: Colors.white70, fontSize: 12), overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ),

                    // --- 操作メニュー（権限に応じて表示自体を動的に制御するガードを適用） ---
                    // ★ 修正: Viewer（閲覧専用）以外には、試合記録者を含めてすべてのボタンを表示する
                    if (!isReadOnly)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
                        child: OperatorActionButtons(tournamentId: tournamentId),
                      ),

                    // --- タイムラインリスト（スクロール領域） ---
                    Expanded(
                      child: MatchTimelineList(tournamentId: tournamentId),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showShareDialog(BuildContext context, String tournamentId) {
    final String shareUrl = 'https://kendo-os.web.app/viewer-home/$tournamentId?role=viewer';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('大会観戦リンク', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            const Text('離れた場所にいる保護者や仲間も、\n試合状況をリアルタイムで安心して見守れます。', textAlign: TextAlign.center, style: TextStyle(fontSize: 13)),
              const SizedBox(height: 16),
              Container(padding: const EdgeInsets.all(8), color: Colors.white, child: QrImageView(data: shareUrl, version: QrVersions.auto, size: 200.0, backgroundColor: Colors.white)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => SharePlus.instance.share(ShareParams(text: 
                  '【剣道リアルタイムViewer共有】このリンクから今日の試合結果・スコアをリアルタイムにその場で観戦・確認できます！\n'
                  'アプリ名: 剣道リアルタイムViewer共有＋スコア記録 (kendo_os)\n'
                  'リンク: $shareUrl'
                )),
                icon: const Icon(Icons.share), label: const Text('LINEやSNSでURLを送る'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, elevation: 0),
              ),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('閉じる', style: TextStyle(color: Colors.grey)))],
      ),
    );
  }

  Widget _buildCallRow(String label, dynamic match, Color textColor) {
    return Column(
      mainAxisSize: MainAxisSize.min, // ★ 修正: Web特有のレイアウト（無限高）エラー対策
      children: [
        if (match.note.isNotEmpty) Text(match.note, style: TextStyle(color: textColor.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.bold)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
            const SizedBox(width: 12),
            Flexible(child: Text(_getMatchTitle(match), style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
          ],
        ),
      ],
    );
  }

  String _getMatchTitle(dynamic match) {
    final isGrouped = match.groupName != null && match.groupName!.isNotEmpty;
    final isIndividual = match.matchType == 'individual' || match.matchType == '選手' || match.matchType.contains('個人戦');
    if (isGrouped && !isIndividual) return '${match.redName.contains(':') ? match.redName.split(':').first.trim() : match.redName} vs ${match.whiteName.contains(':') ? match.whiteName.split(':').first.trim() : match.whiteName}';
    return '${match.redName} vs ${match.whiteName.contains(':') ? '${match.whiteName.split(':')[1].trim()} : ${match.whiteName.split(':')[0].trim()}' : match.whiteName}';
  }
}