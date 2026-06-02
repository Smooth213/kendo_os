import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart'; // kIsWeb用

import '../../shared/widgets/scoreboard.dart';
import '../../shared/widgets/manual_help_button.dart';
import '../../shared/widgets/liquid_background.dart';
import 'package:kendo_os/presentation/viewer/providers/viewer_view_state_provider.dart';
import 'package:kendo_os/application/projections/match_projection.dart';
import '../../operate/providers/match_list_provider.dart';
import 'package:kendo_os/application/mappers/match_projection_mapper.dart';
import 'package:kendo_os/domain/services/kendo_rule_engine.dart';

// ★ Phase 10: 運営モードへの最速復帰用プロバイダーとロール定義のインポート
import '../../../domain/entities/user_role.dart';
import '../../shared/providers/auth_session_provider.dart';
import '../../shared/providers/current_sync_context_provider.dart';

class ViewerMatchScreen extends ConsumerWidget {
  final String matchId;
  const ViewerMatchScreen({super.key, required this.matchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewStateAsync = kIsWeb
        ? null
        : ref.watch(viewerMatchProjectionProvider(matchId));
    final asyncWebMatch = kIsWeb
        ? ref.watch(webScoreboardMatchProvider(matchId))
        : null;

    // 🌟 ずっとクルクルする（無限ローディング）不具合修正パッチ
    // Projectionストリームの初回パケットを待機中で loading に陥っている場合でも、
    // ローカルキャッシュ(matchListProvider)から即座に状態を生成して表示を点火し、
    // 画面のフリーズを完全回避する最強のフォールバック防衛線。
    MatchProjection? fallbackProjection;
    if (kIsWeb) {
      if (asyncWebMatch?.value != null) {
        final match = asyncWebMatch!.value!;
        try {
          final engine = KendoRuleEngine();
          final analysis = engine.analyzeHistory(
            match.events,
            match,
            match.rule,
          );
          fallbackProjection = MatchProjectionMapper.toProjection(
            match,
            analysis,
          );
        } catch (_) {}
      }
    } else if (viewStateAsync!.isLoading || viewStateAsync.value == null) {
      final match = ref
          .watch(matchListProvider)
          .where((m) => m.id == matchId)
          .firstOrNull;
      if (match != null) {
        try {
          final engine = KendoRuleEngine();
          final analysis = engine.analyzeHistory(
            match.events,
            match,
            match.rule,
          );
          fallbackProjection = MatchProjectionMapper.toProjection(
            match,
            analysis,
          );
        } catch (_) {}
      }
    }

    if (kIsWeb) {
      if (asyncWebMatch!.isLoading && fallbackProjection == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      } else if (asyncWebMatch.hasError) {
        return Scaffold(
          body: Center(child: Text('エラーが発生しました: ${asyncWebMatch.error}')),
        );
      } else {
        if (fallbackProjection == null) {
          return const Scaffold(body: Center(child: Text('試合データが見つかりません')));
        }
        return _buildScreen(context, ref, fallbackProjection);
      }
    } else {
      return viewStateAsync!.when(
        loading: () {
          if (fallbackProjection != null) {
            return _buildScreen(context, ref, fallbackProjection);
          }
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
        error: (e, s) => Scaffold(body: Center(child: Text('エラーが発生しました: $e'))),
        data: (MatchProjection? projection) {
          final target = projection ?? fallbackProjection;
          if (target == null) {
            return const Scaffold(body: Center(child: Text('試合データが見つかりません')));
          }
          return _buildScreen(context, ref, target);
        },
      );
    }
  }

  Widget _buildScreen(
    BuildContext context,
    WidgetRef ref,
    MatchProjection projection,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white : Colors.indigo.shade900;
    final textColor = isDark ? Colors.white : Colors.black;

    return LiquidBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            '試合状況 (観戦)',
            style: TextStyle(fontSize: 14, color: textColor),
          ),
          leading: context.canPop()
              ? IconButton(
                  icon: Icon(Icons.arrow_back_ios, color: iconColor, size: 20),
                  tooltip: '戻る',
                  onPressed: () => context.pop(),
                )
              : null,
          actions: [
            IconButton(
              icon: Icon(Icons.qr_code_2, color: iconColor, size: 20),
              tooltip: 'この試合の観戦QRコード・リンクを共有',
              onPressed: () =>
                  _showShareDialog(context, ref, projection.tournamentId),
            ),
            ManualHelpButton(
              manualPath: 'docs/manuals/faq/viewer_faq.md',
              color: iconColor,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            // ★ 1. ステータスバー（Phase 10 クイックモード切替導線を統合）
            _buildStatusBar(context, ref, projection),

            // 2. スコアボード
            Expanded(
              child: ProviderScope(
                overrides: [
                  scoreboardMatchIdProvider.overrideWithValue(matchId),
                  scoreboardNameTapProvider.overrideWithValue(null),
                ],
                child: const MatchScoreboard(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ★ Phase 10: 現場運営スタッフが3タップ以内で試合作成・入力へ戻れる動的ヘッダー
  Widget _buildStatusBar(
    BuildContext context,
    WidgetRef ref,
    MatchProjection p,
  ) {
    return Container(
      width: double.infinity,
      color: Colors.blueGrey.shade700,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.visibility, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              const Text(
                '閲覧モード',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              // クイック切替用ボタン（現場での迷子を物理的にゼロにする）
              TextButton(
                style: TextButton.styleFrom(
                  // ★ 修正：非推奨の withOpacity(0.2) を最新の withValues(alpha: 0.2) へ刷新
                  backgroundColor: Colors.orangeAccent.withValues(alpha: 0.2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => _showModeSwitchDialog(context, ref),
                child: const Text(
                  '運営モードへ切替',
                  style: TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${p.statusText} | 直前: ${p.lastEventText}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  // ★ Phase 10: 運営モードへの切替確認ポップアップダイアログ
  void _showModeSwitchDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'モード切替確認',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: const Text(
          '現在の端末を「閲覧専用」から「運営者（Operator）」に変更しますか？\n変更すると、試合作成やスコア入力画面への進入が可能になります。',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              // 1タップ目: 状態を運営者へ書き換え（MatchRouterが即座に検知して画面を自動再描画します）
              ref
                  .read(authSessionProvider.notifier)
                  .establishSession(
                    UserRole.operator,
                    ref.read(currentDojoIdProvider),
                  );
              Navigator.pop(ctx); // 2タップ目: ダイアログを閉じる
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('運営者モードへ切り替えました。試合操作が可能です。')),
              );
            },
            child: const Text('運営モードへ変更'),
          ),
        ],
      ),
    );
  }

  void _showShareDialog(
    BuildContext context,
    WidgetRef ref,
    String tournamentId,
  ) {
    final dojoId = ref.read(currentDojoIdProvider);
    final bool isBunaiksen = tournamentId.startsWith('bunaiksen_');
    final String shareUrl = isBunaiksen
        ? 'https://kendo-os.web.app/bunaiksen-viewer-home/$tournamentId?role=viewer&dojoId=$dojoId'
        : 'https://kendo-os.web.app/viewer-home/$tournamentId?role=viewer&dojoId=$dojoId';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isBunaiksen ? '部内戦観戦リンク' : '大会観戦リンク',
          style: const TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'このリンクを共有すると、\nリアルタイムで観戦できます。',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.white,
                child: QrImageView(
                  data: shareUrl,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => SharePlus.instance.share(
                  ShareParams(
                    text:
                        '【剣道リアルタイムViewer共有】この試合（コート）のリアルタイム打突一本速報・タイマー状態をその場で確認できます！\n'
                        'アプリ名: 剣道リアルタイムViewer共有＋スコア記録 (kendo_os)\n'
                        '試合速報リンク: $shareUrl',
                  ),
                ),
                icon: const Icon(Icons.share),
                label: const Text('LINEやSNSでURLを送る'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey.shade700,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
}
