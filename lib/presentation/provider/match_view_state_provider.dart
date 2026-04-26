import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/match/score_event.dart';
import 'match_list_provider.dart';
import 'sync_provider.dart';
import 'match_command_provider.dart';
import 'settings_provider.dart'; // ★ 追加
import 'match_status_provider.dart'; // ★ 追加

// ★ テスト時にFirebase依存を回避するため、ユーザーIDの取得をProviderに分離
final matchViewStateUserIdProvider = Provider<String>((ref) {
  return FirebaseAuth.instance.currentUser?.uid ?? '';
});

// ==========================================
// ★ Step 1: ViewStateの定義 (UIが必要とする「結果」だけの箱)
// ==========================================
class MatchViewState {
  final String scoreText;
  final int redScore;
  final int whiteScore;
  final bool isEncho;
  final String? winner; // 'red', 'white', 'draw', null
  final String lastEventText;
  final bool canUndo;
  final String statusText;
  final SyncStatus syncStatus;
  // ★ Step 5 追加: UIに残っていた判定ロジックの結果を保持
  final bool isViewOnly;
  final bool isInputLocked;
  final bool isAllDone;
  final bool isTie;

  MatchViewState({
    required this.scoreText,
    required this.redScore,
    required this.whiteScore,
    required this.isEncho,
    required this.winner,
    required this.lastEventText,
    required this.canUndo,
    required this.statusText,
    required this.syncStatus,
    required this.isViewOnly,
    required this.isInputLocked,
    required this.isAllDone,
    required this.isTie,
  });
}

// ==========================================
// ★ Step 2: ViewState Providerの作成 (すべての計算ロジックをここに集約)
// ==========================================
final matchViewStateProvider = Provider.family<MatchViewState, String>((ref, matchId) {
  final match = ref.watch(matchListProvider).where((m) => m.id == matchId).firstOrNull;
  final syncStatus = ref.watch(syncStatusProvider);
  final isProcessing = ref.watch(isMatchCommandProcessingProvider);
  final settings = ref.watch(settingsProvider);
  final groupStatus = ref.watch(groupMatchStatusProvider(matchId));
  
  if (match == null) {
    return MatchViewState(
      scoreText: '0 - 0', redScore: 0, whiteScore: 0, isEncho: false, 
      winner: null, lastEventText: '', canUndo: false, statusText: '', syncStatus: syncStatus,
      isViewOnly: true, isInputLocked: true, isAllDone: false, isTie: false
    );
  }

  // 1. 勝敗判定
  String? winner;
  if (match.status == 'finished' || match.status == 'approved') {
    if (match.redScore > match.whiteScore) { winner = 'red'; } 
    else if (match.whiteScore > match.redScore) { winner = 'white'; } 
    else { winner = 'draw'; }
  }

  // 2. 権限・ロック判定（UIから完全引越し）
  final myUserId = ref.watch(matchViewStateUserIdProvider);
  final now = DateTime.now();
  final isLockExpired = match.lockExpiresAt != null && match.lockExpiresAt!.isBefore(now);
  final isViewOnly = match.scorerId != null && match.scorerId != myUserId && !isLockExpired;

  final isApproved = match.status == 'approved';
  final rMiss = match.redName.contains('欠員');
  final wMiss = match.whiteName.contains('欠員');
  final isInputLocked = isViewOnly || 
                       (match.status == 'finished' && settings.isLocked) || 
                       (isApproved && settings.isLocked) || 
                       rMiss || wMiss;

  // 3. 延長・ステータス判定
  final isEncho = match.note.contains('延長') || match.matchType.contains('延長');
  final statusText = isEncho ? '延長' : (isApproved || match.status == 'finished' ? '終了' : '試合中');

  // 4. Undoロジック
  ScoreEvent? validLastEvent;
  int undoCount = 0;
  for (int i = match.events.length - 1; i >= 0; i--) {
    final e = match.events[i];
    if (e.isCanceled || e.type == PointType.restore) continue;
    if (e.type == PointType.undo) { undoCount++; } 
    else { if (undoCount > 0) { undoCount--; } else { validLastEvent = e; break; } }
  }

  String lastEventText = '';
  if (validLastEvent != null) {
    final sideStr = validLastEvent.side == Side.red ? '赤' : '白';
    final typeMap = {PointType.men: 'メン', PointType.kote: 'コテ', PointType.doIdo: 'ドウ', PointType.tsuki: 'ツキ', PointType.hansoku: '反則', PointType.fusen: '不戦勝', PointType.hantei: '判定'};
    lastEventText = '$sideStr ${typeMap[validLastEvent.type] ?? ''}';
  }

  return MatchViewState(
    scoreText: '${match.redScore} - ${match.whiteScore}',
    redScore: match.redScore.toInt(),
    whiteScore: match.whiteScore.toInt(),
    isEncho: isEncho,
    winner: winner,
    lastEventText: lastEventText,
    canUndo: (!isViewOnly && !isApproved && validLastEvent != null && !isProcessing),
    statusText: statusText,
    syncStatus: syncStatus,
    isViewOnly: isViewOnly,
    isInputLocked: isInputLocked,
    isAllDone: groupStatus.isAllDone,
    isTie: groupStatus.isTie,
  );
});