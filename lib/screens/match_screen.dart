import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart'; 
import 'dart:async';
import 'package:uuid/uuid.dart'; 
import 'package:flutter/services.dart'; // ★ Phase 6: バイブレーション用
import '../models/match_model.dart';
import '../models/score_event.dart';
import '../providers/match_list_provider.dart';
import '../providers/match_provider.dart';
import '../providers/match_rule_provider.dart'; 
import '../providers/match_command_provider.dart'; // ★ 追加: 書き込み専門家
import '../providers/match_timer_provider.dart';   // ★ 追加: 時計専門家
import '../providers/match_status_provider.dart'; // ★ 追加
// ★ 追加：マスタとチーム情報を参照するためのインポート
import '../models/player_model.dart';
import '../repositories/player_repository.dart';
import '../models/team_model.dart';
import '../repositories/team_repository.dart';
// ★ Phase 3: 分割した専用Widgetをインポート
import '../domain/strategy/match_strategy.dart'; // ★ Phase 5: 戦略ファクトリの読み込み

// ★ Phase 3: 分割したWidget群
import 'match/widgets/timer_widget.dart';
import 'match/widgets/action_buttons.dart';
import 'match/widgets/scoreboard.dart';
import 'match/widgets/match_header.dart';

// ★ 追加：システム設定プロバイダの読み込み
import '../providers/settings_provider.dart';
import '../providers/last_used_settings_provider.dart'; // ★ 修正：直近ルールの読み込み用に追加
import '../providers/share_provider.dart'; // ★ Phase 3: 観戦共有用に追加

final playerListProvider = StreamProvider.autoDispose<List<PlayerModel>>((ref) {
  return ref.watch(playerRepositoryProvider).getPlayers();
});
final registeredTeamsProvider = StreamProvider.family.autoDispose<List<TeamModel>, String>((ref, tournamentId) {
  return ref.watch(teamRepositoryProvider).watchTeamsByTournament(tournamentId);
});

class MatchScreen extends ConsumerStatefulWidget {
  final String matchId; 
  const MatchScreen({super.key, required this.matchId});

  @override
  ConsumerState<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends ConsumerState<MatchScreen> {
  String? _myUserId;
  Timer? _ticker; 
  bool _isProcessingFusen = false; 

  @override
  void initState() {
    super.initState();
    _myUserId = FirebaseAuth.instance.currentUser?.uid ?? 'user_${DateTime.now().millisecondsSinceEpoch}';
    
    // ★ Step 3-3: 画面全体のタイマー(Timer.periodic)を完全に削除し、
    // タイマーが動いている場合のみ、バックグラウンドの時計（MatchTimerProvider）を動かす指示を出す
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.matchId.isNotEmpty) {
        ref.read(matchCommandProvider).claimScorer(widget.matchId, _myUserId!);
        
        final match = ref.read(matchListProvider).where((m) => m.id == widget.matchId).firstOrNull;
        if (match != null) {
          _checkFusenOrFinish(match);
          if (match.timerIsRunning) {
            ref.read(matchTimerProvider).startLocalTicker(widget.matchId);
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel(); 
    if (widget.matchId.isNotEmpty) {
      try {
        // ★ 修正: matchCommandProvider を使用
        ref.read(matchCommandProvider).releaseScorer(widget.matchId, _myUserId!);
      } catch (_) {}
    }
    super.dispose();
  }

  void _checkFusenOrFinish(MatchModel next) {
    if (next.id.isEmpty) return;
    if (next.id.isEmpty) {
      return;
    }
    if ((next.status == 'waiting' || next.status == 'in_progress') && !_isProcessingFusen) {
      bool rMiss = next.redName.contains('欠員');
      bool wMiss = next.whiteName.contains('欠員');
      bool hasFusen = next.events.any((e) => e.type == PointType.fusen);

      if (rMiss || wMiss) {
        _isProcessingFusen = true; 
        Future.microtask(() async {
          if (!mounted) return;
          if (!mounted) {
            return;
          }
          final command = ref.read(matchCommandProvider); // ★ 修正
          if (rMiss && wMiss) {
          } else if (rMiss && !wMiss && !hasFusen) {
            await command.addScoreEvent(next.id, Side.white, PointType.fusen);
            await command.addScoreEvent(next.id, Side.white, PointType.fusen); 
          } else if (wMiss && !rMiss && !hasFusen) {
            await command.addScoreEvent(next.id, Side.red, PointType.fusen);
            await command.addScoreEvent(next.id, Side.red, PointType.fusen); 
          }
          final freshMatches = ref.read(matchListProvider);
          // ★ Phase 2: firstWhere廃止
          final freshMatch = freshMatches.where((m) => m.id == next.id).firstOrNull ?? next;
          if (freshMatch.status != 'finished' && freshMatch.status != 'approved') {
            await command.saveMatch(freshMatch.copyWith(status: 'finished', remainingSeconds: 0));
          }
          // ★ Step 3-4: setState を廃止。
          // _isProcessingFusen は見た目に影響しない「実行中フラグ」なので、
          // setState による Widget 全体の再構築は不要。
          _isProcessingFusen = false;
        });
      } else {
        final rule = ref.read(matchRuleProvider);
        
        // ★ Phase 5: 長々とした1本勝負判定のif文を、Strategyパターンで一撃解決！
        final strategy = MatchStrategyFactory.getStrategy(next);
        int requiredPoints = strategy.getTargetIppon(next, rule);

        // ★ Step 7-1: 自動判定による終了時も、設定に応じて確定まで自動で行う
        if (next.redScore >= requiredPoints || next.whiteScore >= requiredPoints) {
          Future.microtask(() async {
            final settings = ref.read(settingsProvider);
            if (settings.confirmBehavior == 'single') {
              await ref.read(matchActionProvider).approveMatch(next);
            } else {
              await ref.read(matchCommandProvider).saveMatch(next.copyWith(status: 'finished'));
            }
          });
        }
      }
    }
  }

  // ★ 追加：同点時の「判定ダイアログ」
  Future<String?> _showHanteiDialog(MatchModel match) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final rName = match.redName.contains(':') ? match.redName.split(':').last.trim() : match.redName;
    final wName = match.whiteName.contains(':') ? match.whiteName.split(':').last.trim() : match.whiteName;

    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('勝敗の判定', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('同点のため、判定（または引き分け）を選択してください', textAlign: TextAlign.center, style: TextStyle(color: isDark ? Colors.grey.shade300 : Colors.black87)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, 'red'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                    child: Text('赤の判定勝ち\n($rName)', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, 'white'),
                    style: ElevatedButton.styleFrom(backgroundColor: isDark ? const Color(0xFF38383A) : Colors.grey.shade300, foregroundColor: isDark ? Colors.white : Colors.black87, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                    child: Text('白の判定勝ち\n($wName)', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx, 'draw'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: BorderSide(color: isDark ? Colors.grey.shade600 : Colors.grey.shade400), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text('引き分け', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade300 : Colors.black87)),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('キャンセル（戻る）', style: TextStyle(color: Colors.grey))),
          ],
        ),
      ),
    );
  }

  // ★ Phase 6: 危険操作ガード（確認ダイアログ）
  Future<bool> _showConfirmDialog(String title, String content) async {
    HapticFeedback.heavyImpact(); // 警告の意味を込めた強い振動
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        content: Text(content),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, foregroundColor: Colors.white, elevation: 0),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('実行する', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final matchId = widget.matchId;
    // ★ Step 3-2 & Phase 2: watch最適化とnull安全の最終形態
    final match = ref.watch(matchListProvider.select((list) => 
      list.where((m) => m.id == matchId).firstOrNull
    ));

    if (match == null) return const Scaffold(body: Center(child: Text('データなし')));

    // ★ Step 3-2: この試合と同じグループのデータだけを監視（星取表の更新チェック用）
    final teamMatches = ref.watch(matchListProvider.select((list) => 
      list.where((m) => m.groupName == match.groupName).toList()
    ));

    ref.listen<MatchModel?>(
      matchListProvider.select((list) => list.where((m) => m.id == matchId).firstOrNull),
      (previous, next) {
        if (next != null) {
          _checkFusenOrFinish(next);
        }
      },
    );

    final rule = ref.watch(matchRuleProvider); 

    if (rule.isRenseikai && rule.renseikaiType == '時間制' && match.groupName != null) {
      final masterTime = ref.read(renseikaiMasterTimerProvider(match.groupName!));
      if (masterTime == -1) {
        Future.microtask(() => ref.read(renseikaiMasterTimerProvider(match.groupName!).notifier).state = rule.overallTimeMinutes * 60);
      }
    }

    bool rMiss = match.redName.contains('欠員');
    bool wMiss = match.whiteName.contains('欠員');

    final isApproved = match.status == 'approved';
    final settings = ref.watch(settingsProvider); // 設定を読み込む

    // ★ Phase 5: 記録員画面につき、ReadOnly判定を削除（ルーター側で保証済み）
    final now = DateTime.now();
    final isLockExpired = match.lockExpiresAt != null && match.lockExpiresAt!.isBefore(now);
    
    // 他の記録員が「有効なロック」を持っているかどうかの競合チェックのみを行う
    final hasLockConflict = match.scorerId != null && match.scorerId != _myUserId && !isLockExpired;
    
    // この画面では isViewOnly は「他端末との競合」時のみ true となる
    final isViewOnly = hasLockConflict;

    // ★ Step 4-3: ドメインエラーを監視し、発生したらSnackBarで通知する
    ref.listen<String?>(matchCommandErrorProvider, (previous, next) {
      if (next != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next, style: const TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // 通知したらクリア
        ref.read(matchCommandErrorProvider.notifier).state = null;
      }
    });

    // ★ Step 3-6 最適化: 
    // MatchScreen自体で isProcessing を watch すると保存のたびに画面全体がガクつくため、
    // ここでは watch せず、必要な子 Widget 内で個別に監視する。
    final isInputLocked = isViewOnly || 
                         (match.status == 'finished' && settings.isLocked) || 
                         (isApproved && settings.isLocked) || 
                         rMiss || wMiss;

    // ★ Step 3-5: 重い集計計算を build 外（Provider）へ完全移管
    // キャッシュされた計算結果を受け取るだけなので、build速度が劇的に向上します
    final groupStatus = ref.watch(groupMatchStatusProvider(matchId));
    final isAllDone = groupStatus.isAllDone;
    final isTie = groupStatus.isTie;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: true, 
      onPopInvokedWithResult: (didPop, result) {},
      child: Scaffold(
        // iOS Native: 真の黒
        backgroundColor: isDark ? Colors.black : Colors.white, 
        appBar: MatchHeader(
          match: match,
          isInputLocked: isInputLocked,
          isAllDone: isAllDone,
          isTie: isTie,
        ),
        body: Stack(
          children: [
            // ★ Phase 8-1: 全体を LayoutBuilder で包み、iPad 向けに 2カラム構造化
            LayoutBuilder(
              builder: (context, constraints) {
                // ★ 修正: iPadでも「縦向き」の時は通常のレイアウトにするため、Landscape（横向き）判定を追加
                final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
                final isTabletLandscape = isLandscape && constraints.maxWidth > 600;

                // 競合警告バナー（記録員画面専用）
                final viewOnlyBanner = (isViewOnly && !isApproved) 
                  ? Container(
                      width: double.infinity,
                      color: Colors.red.shade900.withValues(alpha: 0.9), // より警告色の強い赤へ
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 12),
                          const Expanded(child: Text('他の記録員が入力中です', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                          // 記録員画面には必ず canLockMatch 権限があるため、強制ボタンを表示
                          TextButton(
                            onPressed: () async {
                              final confirmed = await _showConfirmDialog('入力権限の奪取', '他の端末の入力を強制中断し、\nこの端末で入力を開始しますか？');
                              if (confirmed) {
                                await ref.read(matchCommandProvider).forceClaimScorer(match.id, _myUserId!);
                              }
                            },
                            style: TextButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.2), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0), minimumSize: const Size(0, 30)),
                            child: const Text('自分に切り替える', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink();

                // 共通パーツ
                final timerPart = TimerWidget(match: match, isInputLocked: isInputLocked);
                
                final groupButtonPart = Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8, // 横の隙間
                    runSpacing: 8, // はみ出して次の行に行った時の縦の隙間
                    children: [
                      if (match.groupName != null)
                        SizedBox(
                          height: 36,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              if (match.isKachinuki) {
                                context.push('/kachinuki-scoreboard/${match.groupName}');
                              } else {
                                context.push('/team-scoreboard/${match.groupName}');
                              }
                            },
                            icon: Icon(match.isKachinuki ? Icons.timeline : Icons.table_chart_outlined, size: 18, color: isDark ? Colors.indigoAccent.shade100 : Colors.indigo.shade400),
                            label: Text(match.isKachinuki ? 'タイムラインを確認' : '星取り表を確認', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.indigo.shade700)),
                            style: OutlinedButton.styleFrom(backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white, side: BorderSide(color: isDark ? const Color(0xFF38383A) : Colors.indigo.shade200), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                          ),
                        ),
                      // ★ Phase 1: 復元ボタンの追加
                      SizedBox(
                        height: 36,
                        child: OutlinedButton.icon(
                          onPressed: isInputLocked ? null : () => _showSnapshotDialog(context, ref, match),
                          icon: Icon(Icons.history, size: 18, color: isDark ? Colors.orangeAccent : Colors.orange.shade800),
                          label: Text('履歴から復元', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.orangeAccent : Colors.orange.shade800)),
                          style: OutlinedButton.styleFrom(backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white, side: BorderSide(color: isDark ? Colors.orangeAccent.withValues(alpha: 0.5) : Colors.orange.shade200), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        ),
                      ),
                      // ★ Phase 3: 観戦共有ボタンの追加
                      SizedBox(
                        height: 36,
                        child: OutlinedButton.icon(
                          onPressed: () => ref.read(shareProvider).shareMatch(match),
                          icon: Icon(Icons.ios_share, size: 18, color: isDark ? Colors.blueAccent : Colors.blue.shade700),
                          label: Text('観戦URLを共有', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.blueAccent : Colors.blue.shade700)),
                          style: OutlinedButton.styleFrom(backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white, side: BorderSide(color: isDark ? Colors.blueAccent.withValues(alpha: 0.5) : Colors.blue.shade200), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        ),
                      ),
                    ],
                  ),
                );

                final scoreboardPart = MatchScoreboard(
                  match: match, myUserId: _myUserId,
                  onNameTap: (side) => _showNameEditBottomSheet(match, side),
                );

                final actionPanelPart = Container(
                  color: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade100,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Consumer(
                    builder: (context, ref, child) {
                      final settings = ref.watch(settingsProvider);
                      final redPanel = ScoreActionPanel(matchId: match.id, side: Side.red, color: Colors.red.shade600, isLocked: isInputLocked);
                      final whitePanel = ScoreActionPanel(matchId: match.id, side: Side.white, color: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade100, textColor: isDark ? Colors.white : Colors.black87, isLocked: isInputLocked);
                      final divider = VerticalDivider(width: 1, color: isDark ? Colors.white10 : Colors.black12);
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch, // ★ Phase 8-2: ボタン群を縦いっぱいに引き伸ばす魔法
                        children: settings.leftHanded ? [whitePanel, divider, redPanel] : [redPanel, divider, whitePanel]
                      );
                    }
                  ),
                );

                final bottomButtonPart = Container(
                  color: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade100,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Builder(
                    builder: (context) {
                      final settings = ref.watch(settingsProvider);
                      
                      if (isApproved) {
                        return const SizedBox(height: 54, child: Center(child: Text('公式記録確定済み', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))));
                      }
                      
                      if (rule.isRenseikai && rule.renseikaiType == '時間制' && (match.matchType == rule.positions.last || match.matchType == '錬成会') && match.status == 'finished') {
                        return _buildRenseikaiNextButton(context, ref, match);
                      }

                      if (match.status == 'finished') {
                        final confirmAction = isViewOnly ? null : () async {
                          if (settings.haptic) HapticFeedback.heavyImpact();
                          
                          if (settings.showConfirmDialog) {
                            final confirmed = await _showConfirmDialog('記録の確定', 'この試合の記録を確定して次に進みますか？\n確定後は点数の修正ができなくなります。');
                            if (!confirmed) return;
                          }

                          await ref.read(matchActionProvider).approveMatch(match);
                          String? nextMatchId;

                          if (match.isKachinuki) {
                            final rPts = match.redScore;
                            final wPts = match.whiteScore;
                            List<String> nextRedRem = List.from(match.redRemaining);
                            List<String> nextWhiteRem = List.from(match.whiteRemaining);
                            String nextRedName = match.redName;
                            String nextWhiteName = match.whiteName;
                            bool isMatchOver = false;
                            bool isEncho = false; 

                            if (rPts == wPts) { 
                              if (nextRedRem.isEmpty && nextWhiteRem.isEmpty) {
                                if (rule.kachinukiUnlimitedType == '大将引き分け延長' && match.matchType != '大将延長戦') {
                                  isMatchOver = false;
                                  isEncho = true;
                                } else {
                                  isMatchOver = true;
                                }
                              } else if (nextRedRem.isEmpty || nextWhiteRem.isEmpty) {
                                isMatchOver = true;
                              } else {
                                nextRedName = nextRedRem.removeAt(0);
                                nextWhiteName = nextWhiteRem.removeAt(0);
                              }
                            } else if (rPts > wPts) { 
                              if (nextWhiteRem.isEmpty) {
                                isMatchOver = true; 
                              } else {
                                nextWhiteName = nextWhiteRem.removeAt(0);
                              }
                            } else { 
                              if (nextRedRem.isEmpty) {
                                isMatchOver = true;
                              } else {
                                nextRedName = nextRedRem.removeAt(0);
                              }
                            }

                            if (!isMatchOver) {
                              nextMatchId = const Uuid().v4();
                              final nextMatch = MatchModel(
                                id: nextMatchId, tournamentId: match.tournamentId, category: match.category, groupName: match.groupName,
                                matchType: isEncho ? '大将延長戦' : '勝ち抜き戦', redName: nextRedName, whiteName: nextWhiteName,
                                status: 'waiting', matchTimeMinutes: match.matchTimeMinutes, isRunningTime: match.isRunningTime,
                                remainingSeconds: match.matchTimeMinutes * 60, order: match.order + 0.1, 
                                note: isEncho ? '延長戦（1本勝負）' : match.note, isKachinuki: true,
                                redRemaining: nextRedRem, whiteRemaining: nextWhiteRem,
                              );
                              await ref.read(matchCommandProvider).saveMatch(nextMatch);
                            }
                          }

                          if (!context.mounted) return;
                          if (nextMatchId != null) {
                            context.go('/match/$nextMatchId');
                          } else {
                            final matches = ref.read(matchListProvider);
                            final next = matches.where((m) => m.groupName == match.groupName && m.order > match.order && m.status != 'approved').toList();
                            next.sort((a, b) => a.order.compareTo(b.order));
                            
                            if (next.isNotEmpty) {
                              context.go('/match/${next.first.id}');
                            } else {
                              if (isTie) {
                                context.go('/team-scoreboard/${match.groupName}');
                              } else {
                                context.go('/home/${match.tournamentId}');
                              }
                            }
                          }
                        };

                        final bool isTrulyTeamMatch = match.groupName != null && teamMatches.length > 1;

                        return GestureDetector(
                          onDoubleTap: settings.confirmBehavior == 'double' ? confirmAction : null,
                          child: ElevatedButton.icon(
                            onPressed: settings.confirmBehavior == 'single' ? confirmAction : (isViewOnly ? null : () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(settings.confirmBehavior == 'double' ? 'ダブルタップで確定してください' : '長押しで確定してください'), duration: const Duration(milliseconds: 1500)))),
                            onLongPress: settings.confirmBehavior == 'long' ? confirmAction : null,
                            icon: Icon((isTie && isTrulyTeamMatch) ? Icons.balance : (isAllDone ? Icons.emoji_events : Icons.verified), size: 24),
                            label: Text(
                              (isTie && isTrulyTeamMatch) ? '記録確定・星取表へ' : (isAllDone ? '確定・大会ホームへ' : '確定・次へ'), 
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isTie ? Colors.red.shade700 : (isAllDone ? Colors.indigo.shade700 : Colors.teal.shade600), 
                              foregroundColor: Colors.white, 
                              minimumSize: const Size(double.infinity, 54), 
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), 
                              elevation: 4
                            ),
                          ),
                        );
                      } else {
                        final finishAction = isViewOnly ? null : () async {
                          if (settings.haptic) HapticFeedback.heavyImpact();
                          final strategy = MatchStrategyFactory.getStrategy(match, teamMatches.length);
                          final lastSettings = ref.read(lastUsedSettingsProvider);
                          
                          if (match.redScore == match.whiteScore) {
                            final nextAction = strategy.getNextActionOnTie(match: match, lastSettings: lastSettings);

                            if (nextAction == NextMatchAction.startExtension) {
                              final confirmed = await _showConfirmDialog('延長戦', '延長戦に入りますか？');
                              if (!confirmed) return;

                              final dynamic rawTime = lastSettings['extensionTimeMinutes'];
                              final double extMins = (rawTime is num) ? rawTime.toDouble() : 3.0;
                              final int currentExtCount = '延長'.allMatches(match.note).length;
                              final extStr = '延長${currentExtCount + 1}回目';
                              
                              await ref.read(matchCommandProvider).saveMatch(match.copyWith(
                                remainingSeconds: (extMins * 60).toInt(),
                                timerIsRunning: false,
                                note: match.note.isEmpty ? extStr : '${match.note} ($extStr)',
                                extensionTimeMinutes: extMins.toInt(),
                              ));
                              
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$extStr（$extMins分）を開始します')));
                              return;
                            } 
                            
                            if (nextAction == NextMatchAction.showHantei) {
                              final hanteiResult = await _showHanteiDialog(match);
                              if (hanteiResult == null) return;
                              try {
                                await ref.read(matchCommandProvider).completeMatchWithHantei(match, hanteiResult, _myUserId);
                              } catch (e) {
                                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('判定の保存に失敗しました: $e')));
                              }
                              return;
                            }
                          }
                          
                          if (settings.showConfirmDialog) {
                            final confirmed = await _showConfirmDialog('試合終了', 'この試合を終了しますか？');
                            if (!confirmed) return;
                          }
                          
                          await ref.read(matchCommandProvider).saveMatch(match.copyWith(
                            status: 'finished', remainingSeconds: 0, timerIsRunning: false,
                          ));
                        };

                        return Consumer(
                          builder: (context, ref, child) {
                            final isProcessing = ref.watch(isMatchCommandProcessingProvider);
                            final effectiveFinishAction = isProcessing ? null : finishAction;

                            return GestureDetector(
                              onDoubleTap: settings.confirmBehavior == 'double' ? effectiveFinishAction : null,
                              child: ElevatedButton(
                                onPressed: settings.confirmBehavior == 'single' ? effectiveFinishAction : (isViewOnly ? null : () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(settings.confirmBehavior == 'double' ? 'ダブルタップで終了してください' : '長押しで終了してください'), duration: const Duration(milliseconds: 1500)))),
                                onLongPress: settings.confirmBehavior == 'long' ? effectiveFinishAction : null,
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo.shade600, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                                child: isProcessing 
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text('この試合を終了する', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                              ),
                            );
                          }
                        );
                      }
                    }
                  ),
                );

                if (isTabletLandscape) {
                  // ★ iPad（横画面のみ）: 左右2カラム構造
                  return Column(
                    children: [
                      viewOnlyBanner,
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 左：情報エリア（タイマー、星取表ボタン、スコア）
                            Expanded(
                              flex: 5,
                              child: Column(
                                children: [
                                  timerPart,
                                  groupButtonPart,
                                  Expanded(child: scoreboardPart),
                                ],
                              ),
                            ),
                            VerticalDivider(width: 1, thickness: 1, color: isDark ? Colors.white10 : Colors.black12),
                            // 右：操作エリア（打突パネル、確定ボタン）
                            Expanded(
                              flex: 6,
                              child: Column(
                                children: [
                                  // ★ Expandedの二重ネストを解消し、必要なここで適用
                                  Expanded(child: actionPanelPart),
                                  bottomButtonPart,
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                } else {
                // ★ スマホ・iPad縦向き: 従来の縦積み
                  return Column(
                    children: [
                      viewOnlyBanner,
                      timerPart,
                      groupButtonPart,
                      Expanded(flex: 5, child: scoreboardPart),
                    // ★ Phase 8-2: iPadの縦画面では actionPanelPart が小さくなりすぎないよう flex または固定高を考慮
                    Expanded(flex: 4, child: actionPanelPart), 
                      bottomButtonPart,
                    ],
                  );
                }
              },
            ),
            // ★ 透かし表示（未定、または生成時のデフォルト「代表選手」のままの場合にロック）
            if (match.matchType == '代表戦' && (match.redName.contains('未定') || match.whiteName.contains('未定') || match.redName.contains('代表選手') || match.whiteName.contains('代表選手')))
              Container(
                color: Colors.black.withValues(alpha: 0.8),
                width: double.infinity,
                height: double.infinity,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person_add, color: Colors.white, size: 80),
                      const SizedBox(height: 24),
                      const Text(
                        '代表戦の選手が未設定です',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: 250,
                        height: 60,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo.shade600,
                            foregroundColor: Colors.white,
                            elevation: 8,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          onPressed: () => _showDaihyoSelectDialog(match),
                          child: const Text('代表者を選択する', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
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


  // ★ 直感UX改修：試合中の選手変更を、状況（自チーム/相手チーム）に応じて分岐するモダンなボトムシートへ昇格
  void _showNameEditBottomSheet(MatchModel match, String side) {
    String fullName = side == 'red' ? match.redName : match.whiteName;
    String teamName = fullName.contains(':') ? fullName.split(':').first.trim() : '';
    String playerName = fullName.contains(':') ? fullName.split(':').last.replaceAll(')', '').trim() : fullName;
    
    final ctrl = TextEditingController(text: playerName == '欠員' ? '' : playerName);

    // 共通の保存ロジック
    Future<void> updatePlayerName(String newName) async {
      final newFullName = teamName.isNotEmpty ? '$teamName : $newName' : newName;
      final updatedMatch = side == 'red' 
          ? match.copyWith(redName: newFullName) 
          : match.copyWith(whiteName: newFullName);
      await ref.read(matchCommandProvider).saveMatch(updatedMatch);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Consumer(
        builder: (context, modalRef, child) {
          final playersAsync = modalRef.watch(playerListProvider);
          final teamsAsync = modalRef.watch(registeredTeamsProvider(match.tournamentId ?? ''));

          final registeredTeams = teamsAsync.value ?? [];
          final players = playersAsync.value ?? [];

          bool isOwnTeam = registeredTeams.any((t) => t.teamName == teamName);

          return Container(
            height: MediaQuery.of(ctx).size.height * 0.85,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              top: 16, left: 24, right: 24,
            ),
            child: Column(
              children: [
                Container(width: 48, height: 5, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 24),
                Text('選手名の変更', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                if (teamName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(teamName, style: TextStyle(color: Colors.grey.shade500, fontSize: 14, fontWeight: FontWeight.bold)),
                ],
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: ctrl,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: '名前を直接入力 (助っ人など)',
                          labelStyle: const TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true, fillColor: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade50,
                          prefixIcon: Icon(Icons.edit, color: isDark ? Colors.indigo.shade300 : Colors.indigo.shade600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        final newName = ctrl.text.trim().isEmpty ? '欠員' : ctrl.text.trim();
                        await updatePlayerName(newName);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade600, foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0
                      ),
                      child: const Text('確定', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await updatePlayerName('欠員');
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.block, size: 18),
                    label: const Text('このポジションを「欠員」にする', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade400, side: BorderSide(color: Colors.red.shade400),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                  ),
                ),

                if (isOwnTeam) ...[
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 12),
                  Align(alignment: Alignment.centerLeft, child: Text('道場の名簿から選ぶ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.indigo.shade300 : Colors.indigo))),
                  const SizedBox(height: 12),
                  Expanded(
                    child: players.isEmpty
                      ? const Center(child: Text('名簿に登録されている選手がいません', style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          itemCount: players.length,
                          itemBuilder: (context, index) {
                            final p = players[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              elevation: 0,
                              color: isDark ? Colors.indigo.shade900.withValues(alpha: 0.3) : Colors.indigo.shade50.withValues(alpha: 0.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isDark ? Colors.indigo.shade900 : Colors.indigo.shade100)),
                              child: ListTile(
                                leading: CircleAvatar(backgroundColor: isDark ? Colors.indigo.shade700 : Colors.white, child: Text(p.name.substring(0, 1), style: TextStyle(color: isDark ? Colors.white : Colors.indigo.shade700, fontWeight: FontWeight.bold))),
                                title: Text(p.name, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                                subtitle: Text(p.gradeName, style: TextStyle(color: Colors.indigo.shade400, fontSize: 12)),
                                trailing: Icon(Icons.check_circle_outline, color: isDark ? Colors.indigo.shade300 : Colors.indigo),
                                onTap: () async {
                                  await updatePlayerName(p.name);
                                  if (ctx.mounted) Navigator.pop(ctx);
                                },
                              ),
                            );
                          },
                        ),
                  ),
                ] else ...[
                  const Spacer(),
                ]
              ],
            ),
          );
        },
      ),
    );
  }

  // ★ 修正：他と同様のデザインルールとダークモードを適用した代表戦設定シート
  void _showDaihyoSelectDialog(MatchModel match) {
    String rTeam = match.redName.contains(':') ? match.redName.split(':').first.trim() : '赤';
    String wTeam = match.whiteName.contains(':') ? match.whiteName.split(':').first.trim() : '白';
    
    final allMatches = ref.read(matchListProvider);
    final teamMatches = allMatches.where((m) => m.groupName == match.groupName && m.matchType != '代表戦').toList();
    
    List<String> redPlayers = teamMatches.map((m) => m.redName.contains(':') ? m.redName.split(':').last.trim() : m.redName).where((n) => n.isNotEmpty && !n.contains('未定') && !n.contains('欠員') && !n.contains('代表選手')).toSet().toList();
    List<String> whitePlayers = teamMatches.map((m) => m.whiteName.contains(':') ? m.whiteName.split(':').last.trim() : m.whiteName).where((n) => n.isNotEmpty && !n.contains('未定') && !n.contains('欠員') && !n.contains('代表選手')).toSet().toList();

    final redCtrl = TextEditingController(text: redPlayers.isNotEmpty ? redPlayers.first : '');
    final whiteCtrl = TextEditingController(text: whitePlayers.isNotEmpty ? whitePlayers.first : '');

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final inputBg = isDark ? const Color(0xFF2C2C2E) : Colors.white;

    showModalBottomSheet(
      context: context, 
      isScrollControlled: true, 
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            height: MediaQuery.of(ctx).size.height * 0.85, 
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom, 
              top: 16, left: 24, right: 24
            ),
            child: Column(
              children: [
                Container(width: 48, height: 5, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 24),
                Text('代表戦の準備', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 8),
                Text('代表戦を戦う選手を選んでください。\n決定するとタイマーが0:00にリセットされます。', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                const SizedBox(height: 24),
                
                Expanded(
                  child: ListView(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: isDark ? Colors.red.shade900.withValues(alpha: 0.15) : Colors.red.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? Colors.red.shade900 : Colors.red.shade100)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [Icon(Icons.shield, color: isDark ? Colors.red.shade400 : Colors.red, size: 18), const SizedBox(width: 8), Text('$rTeam の代表者', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.red.shade300 : Colors.red.shade800, fontSize: 16))]),
                            const SizedBox(height: 12),
                            if (redPlayers.isNotEmpty) ...[
                              Wrap(
                                spacing: 8, runSpacing: 8,
                                children: redPlayers.map((p) => ChoiceChip(
                                  label: Text(p),
                                  selected: redCtrl.text == p,
                                  selectedColor: isDark ? Colors.red.shade700 : Colors.red.shade200,
                                  backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                                  labelStyle: TextStyle(color: redCtrl.text == p ? (isDark ? Colors.white : Colors.red.shade900) : textColor, fontWeight: FontWeight.bold),
                                  onSelected: (s) => setState(() { redCtrl.text = p; }),
                                )).toList(),
                              ),
                              const SizedBox(height: 12),
                            ],
                            TextField(
                              controller: redCtrl,
                              style: TextStyle(color: textColor),
                              onChanged: (val) => setState(() {}), 
                              decoration: InputDecoration(labelText: '名前を直接入力', labelStyle: const TextStyle(color: Colors.grey), isDense: true, prefixIcon: const Icon(Icons.edit, size: 16), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), filled: true, fillColor: inputBg),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: isDark ? Colors.blueGrey.shade900.withValues(alpha: 0.2) : Colors.grey.shade100, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? const Color(0xFF38383A) : Colors.grey.shade300)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [Icon(Icons.shield, color: Colors.grey.shade500, size: 18), const SizedBox(width: 8), Text('$wTeam の代表者', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade300 : Colors.grey.shade800, fontSize: 16))]),
                            const SizedBox(height: 12),
                            if (whitePlayers.isNotEmpty) ...[
                              Wrap(
                                spacing: 8, runSpacing: 8,
                                children: whitePlayers.map((p) => ChoiceChip(
                                  label: Text(p),
                                  selected: whiteCtrl.text == p,
                                  selectedColor: isDark ? Colors.blueGrey.shade700 : Colors.grey.shade300,
                                  backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                                  labelStyle: TextStyle(color: whiteCtrl.text == p ? (isDark ? Colors.white : Colors.black) : textColor, fontWeight: FontWeight.bold),
                                  onSelected: (s) => setState(() { whiteCtrl.text = p; }),
                                )).toList(),
                              ),
                              const SizedBox(height: 12),
                            ],
                            TextField(
                              controller: whiteCtrl,
                              style: TextStyle(color: textColor),
                              onChanged: (val) => setState(() {}),
                              decoration: InputDecoration(labelText: '名前を直接入力', labelStyle: const TextStyle(color: Colors.grey), isDense: true, prefixIcon: const Icon(Icons.edit, size: 16), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), filled: true, fillColor: inputBg),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                SafeArea(
                  top: false, 
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 24), 
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade600, 
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                      ),
                      onPressed: () async {
                        final rName = redCtrl.text.trim().isEmpty ? '代表' : redCtrl.text.trim();
                        final wName = whiteCtrl.text.trim().isEmpty ? '代表' : whiteCtrl.text.trim();
                        
                        final newRed = '$rTeam : $rName';
                        final newWhite = '$wTeam : $wName';
                        
                        final updatedMatch = match.copyWith(
                          redName: newRed, 
                          whiteName: newWhite, 
                          remainingSeconds: 0, 
                        );
                        
                        await ref.read(matchCommandProvider).saveMatch(updatedMatch);
                        if (ctx.mounted) Navigator.pop(ctx);
                      }, 
                      child: const Text('決定して準備完了', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      )
    );
  }

  Widget _buildRenseikaiNextButton(BuildContext context, WidgetRef ref, MatchModel match) {
    final masterTime = ref.watch(renseikaiMasterTimerProvider(match.groupName ?? ''));
    final isTimeUp = masterTime == 0;
    final isInputLocked = match.scorerId != null && match.scorerId != _myUserId;

    return ElevatedButton.icon(
      onPressed: (isInputLocked || isTimeUp) ? null : () => _showNextMatchDialog(context, ref, match),
      icon: const Icon(Icons.autorenew, size: 24),
      label: const Text('次の対戦者を追加して継続', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal.shade600,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 54),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _showNextMatchDialog(BuildContext context, WidgetRef ref, MatchModel currentMatch) {
    String rTeam = currentMatch.redName.contains(':') ? currentMatch.redName.split(':').first.trim() : '赤';
    String wTeam = currentMatch.whiteName.contains(':') ? currentMatch.whiteName.split(':').first.trim() : '白';
    
    final redCtrl = TextEditingController();
    final whiteCtrl = TextEditingController();

    // iOS Native カラー
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final inputBgColor = isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade100;
    final borderColor = isDark ? const Color(0xFF38383A) : Colors.grey.shade300;

    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: bgColor,
      title: Text('次の試合を追加 (錬成会)', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: redCtrl,
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: '$rTeam の選手',
              labelStyle: const TextStyle(color: Colors.grey),
              filled: true, fillColor: inputBgColor,
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.indigo.shade400, width: 2)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: whiteCtrl,
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: '$wTeam の選手',
              labelStyle: const TextStyle(color: Colors.grey),
              filled: true, fillColor: inputBgColor,
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.indigo.shade400, width: 2)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル', style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: isDark ? Colors.indigo.shade600 : Colors.indigo, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          onPressed: () async {
            if (!ctx.mounted) return;
            showDialog(context: ctx, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

            final nextMatchId = const Uuid().v4();
            final newRed = '$rTeam : ${redCtrl.text.trim().isEmpty ? '選手' : redCtrl.text.trim()}';
            final newWhite = '$wTeam : ${whiteCtrl.text.trim().isEmpty ? '選手' : whiteCtrl.text.trim()}';
            
            final rule = ref.read(matchRuleProvider);
            // ★ 追加：ルールの分数（int切り捨て）ではなく、設定に保存された正確な小数（double）を読み込む
            final lastSettings = ref.read(lastUsedSettingsProvider);
            final double exactMatchTime = (lastSettings['matchTime'] as num?)?.toDouble() ?? rule.matchTimeMinutes.toDouble();
            final int initialSeconds = (exactMatchTime * 60).toInt();

            final nextMatch = MatchModel(
              id: nextMatchId,
              tournamentId: currentMatch.tournamentId,
              category: currentMatch.category,
              groupName: currentMatch.groupName,
              matchType: '錬成会', 
              redName: newRed,
              whiteName: newWhite,
              status: 'waiting', 
              timerIsRunning: false, 
              matchTimeMinutes: exactMatchTime.toInt(),
              isRunningTime: rule.isRunningTime,
              remainingSeconds: initialSeconds, // ★ 修正：正確な秒数(initialSeconds)をセットする！
              order: currentMatch.order + 0.1,
              note: currentMatch.note,
            );
            
            await ref.read(matchCommandProvider).saveMatch(nextMatch);
            
            if (!ctx.mounted) return;
            // ★ Phase 8-1: GoRouterクラッシュ対策。ローディングダイアログを確実に閉じる
            Navigator.of(ctx, rootNavigator: true).pop(); 
            if (!ctx.mounted) return;
            Navigator.pop(ctx); // ダイアログ閉じる
            
            if (!context.mounted) return;
            context.pushReplacement('/match/$nextMatchId');
          }, 
          child: const Text('決定して開始', style: TextStyle(fontWeight: FontWeight.bold))
        ),
      ],
    ));
  }

  // =========================================================================
  // ★ Phase 1: タイムマシン（スナップショットからの復元UI）
  // =========================================================================
  void _showSnapshotDialog(BuildContext context, WidgetRef ref, MatchModel match) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // 最新のバックアップが一番上に来るように反転
    final snapshots = match.snapshots.reversed.toList(); 

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.7,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          children: [
            Container(width: 48, height: 5, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 16),
            const Text('タイムマシン（エラー復旧）', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('過去の特定の時点にスコアや時間を安全に巻き戻します。\n（復元した事実も記録されるためデータは壊れません）', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ),
            Expanded(
              child: snapshots.isEmpty
                  ? Center(child: Text('バックアップ履歴がありません', style: TextStyle(color: Colors.grey.shade500)))
                  : ListView.builder(
                      itemCount: snapshots.length,
                      itemBuilder: (context, index) {
                        final snap = snapshots[index];
                        final timeStr = '${snap.createdAt.hour}:${snap.createdAt.minute.toString().padLeft(2, '0')}:${snap.createdAt.second.toString().padLeft(2, '0')}';
                        
                        return ListTile(
                          leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.restore, color: Colors.white)),
                          title: Text(snap.reason, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                          subtitle: Text('$timeStr に自動保存', style: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey)),
                          trailing: ElevatedButton(
                            onPressed: () async {
                              final confirm = await _showConfirmDialog('この時点に復元しますか？', 'スコアと時間が「${snap.reason}」の時点に戻ります。');
                              if (confirm) {
                                await ref.read(matchCommandProvider).restoreFromSnapshot(match.id, snap);
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ 復元が完了しました')));
                              }
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, foregroundColor: Colors.white, elevation: 0),
                            child: const Text('復元', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}