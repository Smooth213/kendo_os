import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kendo_os/domain/services/kendo_rule_engine.dart'; // PointDisplay用

part 'match_projection.freezed.dart';

@freezed
abstract class MatchProjection with _$MatchProjection {
  const factory MatchProjection({
    required String id,
    required String tournamentId,
    required int matchOrder,
    required String matchType,
    required String status, // 'waiting', 'in_progress', 'finished', 'approved' のString
    
    // UI互換用プロパティ
    required String groupName, // ★追加
    required bool isKachinuki, // ★追加
    
    // 選手情報
    required String redName,
    required String whiteName,
    @Default([]) List<String> redRemaining,
    @Default([]) List<String> whiteRemaining,
    
    // スコアと表示データ
    required int redScore,
    required int whiteScore,
    @Default([]) List<PointDisplay> redDisplays,
    @Default([]) List<PointDisplay> whiteDisplays,
    
    // UI特有の表示マーク（公式記録等用）
    @Default('') String firstPointSide,
    @Default([]) List<String> redPointMarks,
    @Default([]) List<String> whitePointMarks,
    
    // タイマー・その他
    required int remainingSeconds,
    required bool timerIsRunning,
    required String note,
  }) = _MatchProjection;
}

// ★ Freezedクラスの制約を回避するため、UI互換用の独自のgetterはextensionとして定義する
extension MatchProjectionUIX on MatchProjection {
  String get matchId => id;
  int get order => matchOrder;
  
  String get statusText {
    switch (status) {
      case 'waiting': return '待機中';
      case 'in_progress': return '進行中';
      case 'finished': return '試合終了';
      case 'approved': return '承認済';
      default: return '不明';
    }
  }

  String get lastEventText {
    // Projectionは具体的なイベント履歴を持たないため、簡易的なテキストを返すか、空文字にする
    if (status == 'finished') return '試合が終了しました';
    if (status == 'in_progress') return '試合が進行中です';
    return '';
  }
}