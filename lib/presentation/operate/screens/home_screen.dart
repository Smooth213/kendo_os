import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import 'package:kendo_os/domain/entities/tournament_model.dart';
import 'package:kendo_os/infrastructure/repository/tournament_repository.dart';
import 'package:kendo_os/infrastructure/repository/player_repository.dart';

import '../providers/permission_provider.dart';
import '../providers/settings_provider.dart';

import '../../shared/widgets/liquid_background.dart';
import '../components/home/operator_action_buttons.dart';
import '../components/home/tournament_header_card.dart'; // ★ 新規作成したコンポーネント
import '../components/home/match_timeline_list.dart'; // ★ 新規作成したコンポーネント
import '../providers/match_view_model_provider.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enableLiquidGlass = ref.watch(settingsProvider).enableLiquidGlass;
    final permissions = ref.watch(permissionProvider);
    final Color textColor = isDark ? Colors.white : Colors.black;

    final activeMatches = ref.watch(activeMatchesProvider(tournamentId));
    final uniqueInProgress = activeMatches.inProgress;
    final uniqueWaiting = activeMatches.waiting;

    return PopScope(
      canPop: !permissions.isReadOnly,
      child: LiquidBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent, 
          appBar: AppBar(
            automaticallyImplyLeading: !permissions.isReadOnly, 
            title: Text('大会ホーム', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor)),
            backgroundColor: enableLiquidGlass ? Colors.transparent : (isDark ? const Color(0xFF1C1C1E) : Colors.white),
            elevation: 0,
            iconTheme: IconThemeData(color: textColor),
            actions: [
              if (!permissions.isReadOnly)
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
              // --- ★ 抽出した大会ヘッダー ---
              ref.watch(tournamentProvider(tournamentId)).when(
                data: (tournament) => tournament != null 
                  ? TournamentHeaderCard(tournament: tournament)
                  : const SizedBox.shrink(),
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
                error: (e, s) => Text('大会情報の読み込みに失敗しました: $e'),
              ),

              // --- アクティブバナー ---
              if (uniqueInProgress.isNotEmpty || uniqueWaiting.isNotEmpty)
                Container(
                  width: double.infinity, margin: const EdgeInsets.fromLTRB(16, 4, 16, 12), padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.indigo.shade800, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.indigo.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))]),
                  child: Column(
                    children: [
                      if (uniqueInProgress.isNotEmpty) _buildCallRow('進行中', uniqueInProgress.first, Colors.orangeAccent),
                      if (uniqueInProgress.isNotEmpty && uniqueWaiting.isNotEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(color: Colors.white24, height: 1)),
                      if (uniqueWaiting.isNotEmpty) _buildCallRow('次試合', uniqueWaiting.first, Colors.white),
                      if (uniqueWaiting.length > 1) Padding(padding: const EdgeInsets.only(top: 8), child: Text('次々試合: ${uniqueWaiting[1].note.isNotEmpty ? "(${uniqueWaiting[1].note}) " : ""}${_getMatchTitle(uniqueWaiting[1])}', style: const TextStyle(color: Colors.white70, fontSize: 12), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),

              // --- 操作メニュー ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: OperatorActionButtons(tournamentId: tournamentId),
              ),
              const SizedBox(height: 8),

              // --- ★ 抽出したタイムラインリスト ---
              Expanded(
                child: MatchTimelineList(tournamentId: tournamentId),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCallRow(String label, dynamic match, Color textColor) {
    return Column(
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
    if (isGrouped && !isIndividual) {
      final rTeam = match.redName.contains(':') ? match.redName.split(':').first.trim() : match.redName;
      final wTeam = match.whiteName.contains(':') ? match.whiteName.split(':').first.trim() : match.whiteName;
      return '$rTeam vs $wTeam';
    }
    return '${match.redName} vs ${_reverseWhiteName(match.whiteName)}';
  }

  String _reverseWhiteName(String whiteName) {
    if (!whiteName.contains(':')) return whiteName;
    final parts = whiteName.split(':');
    if (parts.length != 2) return whiteName;
    return '${parts[1].trim()} : ${parts[0].trim()}';
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
              const Text('この大会の全試合・スコアを\nリアルタイムで共有できます。', textAlign: TextAlign.center, style: TextStyle(fontSize: 13)),
              const SizedBox(height: 16),
              Container(padding: const EdgeInsets.all(8), color: Colors.white, child: QrImageView(data: shareUrl, version: QrVersions.auto, size: 200.0, backgroundColor: Colors.white)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => SharePlus.instance.share(ShareParams(text: '【剣道OS】大会の進行状況をリアルタイムで観戦できます！\n$shareUrl')),
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
}