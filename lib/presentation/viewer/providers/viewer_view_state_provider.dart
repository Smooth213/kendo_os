import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/application/projections/match_projection.dart';
import 'package:kendo_os/application/mappers/match_projection_mapper.dart';
import 'package:kendo_os/infrastructure/repository/match_repository.dart';
import 'package:kendo_os/domain/entities/score_event.dart'; // PointType 等のために追加
import '../../operate/providers/match_list_provider.dart';
import 'package:kendo_os/infrastructure/repository/tournament_repository.dart';
import 'package:kendo_os/application/projections/tournament_projection.dart';
import 'package:kendo_os/application/projections/tournament_projection_mapper.dart';
import 'package:kendo_os/domain/services/kendo_rule_engine.dart';

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

// ★ CQRS: クエリ専用プロバイダ。UIには絶対に MatchModel を渡さず、軽量な Projection だけを渡す
final viewerMatchProjectionProvider = StreamProvider.family<MatchProjection?, String>((ref, matchId) {
  final matchRepo = ref.watch(matchRepositoryProvider);
  
  // 1. DBから生のモデルを監視
  return matchRepo.watchSingleMatch(matchId).map((model) {
    final engine = KendoRuleEngine();
    final analysis = engine.analyzeHistory(model.events, model, model.rule);
    // 2. Mapperを通して、UI専用の安全な Projection に変換して流す
    return MatchProjectionMapper.toProjection(model, analysis);
  });
});

// ★ 大会全体の安全な Projection
final viewerTournamentProjectionProvider = StreamProvider.family<TournamentProjection?, String>((ref, tournamentId) {
  // 1. 大会情報のStreamを監視
  final tournamentStream = ref.watch(tournamentRepositoryProvider).getTournamentStream(tournamentId);
  
  // 2. 試合リスト（Streamではなく同期的なList）を監視
  // ※Riverpodの性質上、このリストに変更があれば自動的にこのProvider自体が再評価されます。
  final matchesList = ref.watch(matchListProvider.select(
    (list) => list.where((m) => m.tournamentId == tournamentId).toList()
  ));

  // 3. Streamに流れてくる大会情報に、最新の試合リストを結合して返す
  return tournamentStream.map((tournament) {
    if (tournament == null) return null;
    return TournamentProjectionMapper.fromModels(tournament, matchesList);
  });
});
