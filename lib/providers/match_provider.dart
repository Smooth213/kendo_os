import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/match_model.dart';
import '../models/score_event.dart';
import '../repositories/match_repository.dart';
import '../domain/kendo_rule_engine.dart'; 
import '../usecase/match_usecase.dart';    
import '../providers/match_rule_provider.dart';
import 'match_command_provider.dart';
import 'audit_provider.dart'; // ★ Phase 5: 監査ログを記録するために追加
import 'match_list_provider.dart'; // ★ _autoActivateNextMatch でリストを参照するために必要
import 'settings_provider.dart';
import '../services/sound_service.dart';

// 1. 現在選択されている試合ID
class CurrentMatchIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void setId(String id) { state = id; }
}

final currentMatchIdProvider = NotifierProvider<CurrentMatchIdNotifier, String?>(() {
  return CurrentMatchIdNotifier();
});

// 2. 選択中の試合データをFirestoreからリアルタイム取得
final currentMatchStreamProvider = StreamProvider<MatchModel?>((ref) {
  final matchId = ref.watch(currentMatchIdProvider);
  if (matchId == null) return Stream.value(null);
  return ref.read(matchRepositoryProvider).watchSingleMatch(matchId);
});

final kendoRuleEngineProvider = Provider<KendoRuleEngine>((ref) {
  return KendoRuleEngine();
});

final matchUseCaseProvider = Provider<MatchUseCase>((ref) {
  final engine = ref.watch(kendoRuleEngineProvider);
  return MatchUseCase(engine);
});

// 3. コントローラー
class MatchActionController {
  final Ref ref;
  MatchActionController(this.ref);

  MatchUseCase get _useCase => ref.read(matchUseCaseProvider);
  AuditService get _audit => ref.read(auditProvider); // ★ Phase 5: 監査ログサービスを取得
  
  Future<void> _safeSave(MatchModel match) async {
    await ref.read(matchCommandProvider).saveMatch(match);
  }

  Future<void> processScoreEvent(MatchModel currentMatch, ScoreEvent event) async {
    try {
      final rule = ref.read(matchRuleProvider);
      final settings = ref.read(settingsProvider); // ★ Step 7-1: 設定を読み込む
      final updatedMatch = _useCase.addScore(currentMatch, event, rule);
      
      // ★ デバッグ用: 現在のサウンド設定がどうなっているか出力
      debugPrint('🔊 [Sound Check] settings.sound is: ${settings.sound}');

      // ★ Step 7-2: 陣営に応じた音のフィードバックを実行
      // ★ 修正: 設定がオンの時だけ鳴るように元に戻す
      if (settings.sound) {
        if (event.type == PointType.hansoku) {
          ref.read(soundServiceProvider).playHansokuSound();
        } else {
          ref.read(soundServiceProvider).playScoreSound(event.side == Side.red);
        }
      }

      // ★ 追加: 2本先取などで試合が「終了」になった瞬間に終了音（ファンファーレ）を鳴らす
      if (updatedMatch.status == 'finished' && currentMatch.status != 'finished') {
        if (settings.sound) {
          ref.read(soundServiceProvider).playFinishFanfare();
        }
      }

      // ★ Step 7-1: フルオート・モード（自動確定）の判定
      // 試合が終了状態(finished)になり、かつ設定で自動確定がONの場合
      if (updatedMatch.status == 'finished' && settings.confirmBehavior == 'single') {
        // 直接確定(approveMatch)処理へ流し込む
        await approveMatch(updatedMatch);
        debugPrint('🚀 Full Auto: Match approved automatically.');
      } else {
        // 通常の保存処理
        await _safeSave(updatedMatch); 
        
        // 試合が決着したが自動確定でない場合は、次の試合のアクティブ化のみ行う
        if (updatedMatch.status == 'finished' && currentMatch.status != 'finished') {
          _autoActivateNextMatch(updatedMatch);
        }
      }

      // 成功した場合のみ、監査ログを送信
      final pointName = event.type == PointType.hansoku ? '反則' :
                        event.type == PointType.fusen ? '不戦勝' : event.type.name;
      final sideName = event.side == Side.red ? '赤' : '白';
      await _audit.logAction(matchId: currentMatch.id, action: 'add_score', details: '$sideName $pointName');
      
    } on DomainException catch (e) {
      debugPrint('🛡️ Validation Blocked: ${e.message}');
    } catch (e) {
      if (e.toString().contains('他の端末でデータが更新されました')) {
        debugPrint('🔄 データの競合が発生しました。画面は自動的に最新状態に同期されます。');
      } else {
        debugPrint('予期せぬエラー: $e');
      }
    }
  }

  Future<void> undoEvent(MatchModel currentMatch) async {
    try {
      debugPrint('🔙 [UndoEvent] Starting undo for match: ${currentMatch.id}');
      final rule = ref.read(matchRuleProvider);
      final updatedMatch = _useCase.undoLastEvent(currentMatch, rule);
      debugPrint('🔙 [UndoEvent] redScore: ${currentMatch.redScore} -> ${updatedMatch.redScore}');
      debugPrint('🔙 [UndoEvent] whiteScore: ${currentMatch.whiteScore} -> ${updatedMatch.whiteScore}'); // ★ デバッグ改善
      debugPrint('🔙 [UndoEvent] Events count: ${currentMatch.events.length} -> ${updatedMatch.events.length}');
      await _safeSave(updatedMatch);
      await _audit.logAction(matchId: currentMatch.id, action: 'undo', details: '直前の操作を取り消し');
      
      // ★ 取り消し時の音フィードバック
      if (ref.read(settingsProvider).sound) {
        ref.read(soundServiceProvider).playUndoSound();
      }
      
      // ★ UI側のデータを強制的にリフレッシュして、新しい Firestore データを取得させる
      // これにより、複数連続のUndo操作でも常に最新のデータを使用できる
      await Future.delayed(const Duration(milliseconds: 100));
      ref.invalidate(matchListProvider);
      
      debugPrint('🔙 [UndoEvent] Success!');
    } catch (e) {
      debugPrint('❌ Undoエラー: $e');
    }
  }

  Future<void> handleTimeUp(MatchModel currentMatch, bool isEnchoEnabled) async {
    try {
      final rule = ref.read(matchRuleProvider); 
      final updatedMatch = _useCase.handleTimeUp(currentMatch, isEnchoEnabled, rule);
      await _safeSave(updatedMatch);
      await _audit.logAction(matchId: currentMatch.id, action: 'time_up', details: '時間切れ判定処理の実行');
    } catch (e) {
      debugPrint('TimeUpエラー: $e');
    }
  }

  void updateScore(MatchModel currentMatch, int redScore, int whiteScore) async {
    final updatedMatch = currentMatch.copyWith(redScore: redScore, whiteScore: whiteScore, status: 'in_progress');
    await _safeSave(updatedMatch).catchError((e) => debugPrint('保存エラー: $e'));

    // ★ Phase 5: 手動スコア修正の証拠ログ
    await _audit.logAction(matchId: currentMatch.id, action: 'manual_update', details: '手動スコア修正 (赤:$redScore 白:$whiteScore)');
  }

  // ★ Step 5-3: 記録の「確定」プロセスをここに集約
  // 確定した瞬間に、次の試合のアクティブ化と名前の流し込みを同時に行います
  Future<void> approveMatch(MatchModel match) async {
    final updatedMatch = match.copyWith(status: 'approved');
    await _safeSave(updatedMatch);

    // 1. 次の試合を「進行中」へ自動昇格（Step 5-1）
    _autoActivateNextMatch(updatedMatch);

    // 2. 勝者・敗者の名前を次の試合（プレースホルダー）へ流し込む（Step 5-3）
    await _propagateResultsToNextMatches(updatedMatch);

    // 3. 監査ログ
    await _audit.logAction(matchId: match.id, action: 'approve_match', details: '記録確定（自動連動実行）');
  }

  void finishMatch(MatchModel currentMatch) async {
    final updatedMatch = currentMatch.copyWith(status: 'finished', timerIsRunning: false);
    await _safeSave(updatedMatch).catchError((e) => debugPrint('保存エラー: $e'));

    if (ref.read(settingsProvider).sound) {
      ref.read(soundServiceProvider).playFinishFanfare();
    }

    // 試合終了（仮）の時点では名前の流し込みは行わず、確定（approve）を待ちます
    await _audit.logAction(matchId: currentMatch.id, action: 'finish_match', details: '試合終了');
  }

  // ★ Phase 2: データ破損時の魔法の修復コマンド（イベント履歴からの完全復元）
  void rebuildMatch(MatchModel currentMatch) async {
    try {
      final rule = ref.read(matchRuleProvider);
      final rebuiltMatch = _useCase.rebuildFromEvents(currentMatch, rule);
      await _safeSave(rebuiltMatch);
      await _audit.logAction(matchId: currentMatch.id, action: 'rebuild', details: 'イベント履歴から状態を完全復元');
      debugPrint('♻️ データの完全修復に成功しました');
    } catch (e) {
      debugPrint('Rebuildエラー: $e');
    }
  }

  // ★ Step 5-3: 【Winner Progression Logic】
  // 終わった試合の勝者（または敗者）を探している他の試合枠を検索し、自動で名前を書き換えます
  Future<void> _propagateResultsToNextMatches(MatchModel finishedMatch) async {
    final matches = ref.read(matchListProvider);
    final winnerName = finishedMatch.redScore > finishedMatch.whiteScore ? finishedMatch.redName : finishedMatch.whiteName;
    final loserName = finishedMatch.redScore > finishedMatch.whiteScore ? finishedMatch.whiteName : finishedMatch.redName;

    // プレースホルダーの形式: [[Winner:試合ID]] または [[Loser:試合ID]]
    final winnerTag = '[[Winner:${finishedMatch.id}]]';
    final loserTag = '[[Loser:${finishedMatch.id}]]';

    for (var m in matches) {
      if (m.status == 'approved') continue; // 確定済みの試合は触らない

      bool updated = false;
      String nextRed = m.redName;
      String nextWhite = m.whiteName;

      if (nextRed.contains(winnerTag)) { nextRed = nextRed.replaceFirst(winnerTag, winnerName); updated = true; }
      if (nextRed.contains(loserTag)) { nextRed = nextRed.replaceFirst(loserTag, loserName); updated = true; }
      if (nextWhite.contains(winnerTag)) { nextWhite = nextWhite.replaceFirst(winnerTag, winnerName); updated = true; }
      if (nextWhite.contains(loserTag)) { nextWhite = nextWhite.replaceFirst(loserTag, loserName); updated = true; }

      if (updated) {
        await _safeSave(m.copyWith(redName: nextRed, whiteName: nextWhite));
        debugPrint('🪄 Propagated name to Match ID: ${m.id}');
      }
    }
  }

  // ★ Step 5-1: 団体戦において、終わった試合の「次」を自動的に進行中にする魔法のメソッド
  void _autoActivateNextMatch(MatchModel finishedMatch) async {
    // 団体戦ではない、またはグループIDがない場合は何もしない
    if (finishedMatch.groupName == null || finishedMatch.groupName!.isEmpty) return;

    // 現在の最新リストから、同じグループの試合を取得
    final matches = ref.read(matchListProvider);
    final groupMatches = matches.where((m) => m.groupName == finishedMatch.groupName).toList();
    
    // 並び順（order）でソート
    groupMatches.sort((a, b) => a.order.compareTo(b.order));

    // 今終わった試合のインデックスを探す
    final currentIndex = groupMatches.indexWhere((m) => m.id == finishedMatch.id);
    
    // 次の試合が存在し、かつ「待機中」であれば「進行中」へ自動昇格
    if (currentIndex != -1 && currentIndex < groupMatches.length - 1) {
      final nextMatch = groupMatches[currentIndex + 1];
      if (nextMatch.status == 'waiting') {
        await _safeSave(nextMatch.copyWith(status: 'in_progress'));
        debugPrint('🪄 Auto-Activated next match: ${nextMatch.matchType}');
      }
    }
  }
}

final matchActionProvider = Provider<MatchActionController>((ref) {
  return MatchActionController(ref);
});