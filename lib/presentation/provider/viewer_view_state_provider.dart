import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/match/score_event.dart'; // PointType 等のために追加
import './match_list_provider.dart';

class ViewerViewState {
  final int redScore;
  final int whiteScore;
  final String lastEventText;
  final String statusText;
  // 以下3つを追加
  final bool isKachinuki;
  final String groupName;
  final String tournamentId;

  ViewerViewState({
    required this.redScore,
    required this.whiteScore,
    required this.lastEventText,
    required this.statusText,
    required this.isKachinuki,
    required this.groupName,
    required this.tournamentId,
  });
}

final viewerViewStateProvider = Provider.family<ViewerViewState, String>((ref, matchId) {
  final match = ref.watch(matchListProvider.select((list) => 
    list.where((m) => m.id == matchId).firstOrNull
  ));

  if (match == null) {
    return ViewerViewState(
      redScore: 0,
      whiteScore: 0,
      lastEventText: '試合が見つかりません',
      statusText: 'エラー',
      isKachinuki: false,
      groupName: '',
      tournamentId: '',
    );
  }

  // キャンセルされていない有効なイベントから最新の操作を抽出
  final validEvents = match.events.where((e) => !e.isCanceled && e.type != PointType.undo).toList();
  String lastEventText = '待機中';
  if (validEvents.isNotEmpty) {
    final lastE = validEvents.last;
    final sideStr = lastE.side == Side.red ? '赤' : (lastE.side == Side.white ? '白' : '');
    String typeStr = '';
    switch (lastE.type) {
      case PointType.men: typeStr = 'メン'; break;
      case PointType.kote: typeStr = 'コテ'; break;
      case PointType.doIdo: typeStr = 'ドウ'; break;
      case PointType.tsuki: typeStr = 'ツキ'; break;
      case PointType.hansoku: typeStr = '反則(▲)'; break;
      case PointType.fusen: typeStr = '不戦勝'; break;
      case PointType.hantei: typeStr = '判定'; break;
      default: typeStr = 'ポイント'; break;
    }
    lastEventText = sideStr.isNotEmpty ? '$sideStr $typeStr' : typeStr;
  }

  String statusText = '準備中';
  if (match.status == 'finished' || match.status == 'approved') {
    statusText = '試合終了';
  } else if (match.timerIsRunning) {
    statusText = '試合中';
  } else if (match.remainingSeconds > 0 && match.remainingSeconds < (match.matchTimeMinutes * 60)) {
    statusText = '時計停止';
  }

  return ViewerViewState(
    redScore: (match.redScore as num).toInt(),
    whiteScore: (match.whiteScore as num).toInt(),
    lastEventText: lastEventText,
    statusText: statusText,
    isKachinuki: match.isKachinuki,
    groupName: match.groupName ?? '',
    tournamentId: match.tournamentId ?? '',
  );
});
