import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ★ 不要になった go_router のインポートを削除
import '../../shared/widgets/scoreboard.dart';
// ★ TimerWidgetのインポートを削除
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/viewer_view_state_provider.dart';
import 'package:kendo_os/application/projections/match_projection.dart'; // ★ Projectionの型とUIXを使うために追加
import '../../shared/widgets/manual_help_button.dart';
import '../../shared/widgets/liquid_background.dart';

class ViewerMatchScreen extends ConsumerWidget {
  final String matchId;
  const ViewerMatchScreen({super.key, required this.matchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ★ Phase 5-3: 最適化。Scaffold全体をリビルドせず、
    // 選手名など「滅多に変わらない静的な枠組み」だけを最初に取得する。
    final viewStateAsync = ref.watch(viewerMatchProjectionProvider(matchId));

    return viewStateAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: Center(child: Text('エラーが発生しました: $e'))),
      data: (MatchProjection? projection) {
        if (projection == null) return const Scaffold(body: Center(child: Text('試合データが見つかりません')));

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final iconColor = isDark ? Colors.white : Colors.indigo.shade900;
        final textColor = isDark ? Colors.white : Colors.black;

        return LiquidBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              // ★ 修正: Webで直接開いた際にGoRouterが勝手に出す「トップ(start_screen)に戻るホームボタン」を強制消去
              automaticallyImplyLeading: false,
              title: Text('試合状況 (観戦)', style: TextStyle(fontSize: 14, color: textColor)),
              // ★ 修正: 誤って管理者ホーム(/home)に飛んでしまう扉ボタンを撤廃。
              // 履歴がある場合（試合一覧から来た場合）は標準の「戻る」ボタンを表示し、
              // 直リンクで来た場合は何も表示しない（ブラウザの戻るに委ねる）純粋なUXに統一。
              leading: context.canPop()
                  ? IconButton(
                      icon: Icon(Icons.arrow_back_ios, color: iconColor, size: 20),
                      tooltip: '戻る',
                      onPressed: () => context.pop(),
                    )
                  : null,
              actions: [
              // ★ 追加：隣の人への共有用QR
              IconButton(
                icon: Icon(Icons.qr_code_2, color: iconColor, size: 20),
                onPressed: () => _showShareDialog(context, projection.tournamentId),
              ),
              // ★ 観客が最も不安になる「点数が変わらない」等のFAQへ直行
              ManualHelpButton(manualPath: 'docs/manuals/faq/viewer_faq.md', color: iconColor),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              // 1. ステータスバー
              _buildStatusBar(projection),

              // ==========================================
              // ★ Phase 4-6: Viewerの究極の簡略化
              // 観客が混乱しないよう、モメンタムゲージとタイムラインを完全撤去。
              // タイマーもドメイン規則（ブラインドタイマー）により非表示。
              // 画面全体を使ってスコアボード（勝敗と一本）のみを強調表示する。
              // ==========================================
              Expanded(
                child: MatchScoreboard(matchId: matchId, myUserId: 'viewer', onNameTap: (side) {}),
              ),
            ],
          ), // Column
        ), // Scaffold
        ); // LiquidBackground
      },
    );
  }

  // 各パーツをメソッドに切り出し、可読性を高める（ロジックは変えず、配置のみ整理）
  Widget _buildStatusBar(MatchProjection p) {
    return Container(
      width: double.infinity, color: Colors.blueGrey.shade700,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, 
        children: [
          const Row(children: [
            Icon(Icons.visibility, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('観客席 (Viewer)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ]),
          const SizedBox(width: 12),
          // ★ 修正：テキストが長い場合は「...」で省略し、Overflow（はみ出し）を物理的に防ぐ
          Expanded(
            child: Text(
              '${p.statusText} | 直前: ${p.lastEventText}',
              style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ]
      ),
    );
  }

  void _showShareDialog(BuildContext context, String tournamentId) {
    final String shareUrl = 'https://kendo-os.web.app/viewer-home/$tournamentId?role=viewer';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('大会観戦リンク', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('このリンクを共有すると、\nリアルタイムで観戦できます。', textAlign: TextAlign.center, style: TextStyle(fontSize: 13)),
            const SizedBox(height: 16),
            Container(padding: const EdgeInsets.all(8), color: Colors.white, child: QrImageView(data: shareUrl, version: QrVersions.auto, size: 180.0)),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('閉じる'))],
      ),
    );
  }
}