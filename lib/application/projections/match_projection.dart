import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kendo_os/domain/services/kendo_rule_engine.dart'; // PointDisplay用
import 'package:kendo_os/presentation/operate/providers/sync_provider.dart'; // SyncStatus用

part 'match_projection.freezed.dart';

/// ① UX強化のためのTimelineEvent（全Projectionで共用）
@freezed
abstract class TimelineEvent with _$TimelineEvent {
  const factory TimelineEvent({
    required String id,
    required DateTime timestamp,
    required String side,       
    required String actionName, 
    required bool isImportant,  
  }) = _TimelineEvent;
}

/// ② リスト表示・団体戦集計用の軽量Projection
/// ★ Phase 5: 団体戦の集計に必要な groupName や marks を追加しつつ、重い timeline 等は排除
@freezed
abstract class MatchListProjection with _$MatchListProjection {
  const factory MatchListProjection({
    required String id,
    required String tournamentId,
    required int matchOrder,
    required String matchType,
    required String status,
    required String redName,
    required String whiteName,
    required int redScore,
    required int whiteScore,
    // 集計・表示用に必須のフィールドを追加
    @Default('') String groupName,
    @Default(false) bool isKachinuki,
    @Default('') String note,
    @Default('') String firstPointSide,
    @Default([]) List<String> redPointMarks,
    @Default([]) List<String> whitePointMarks,
  }) = _MatchListProjection;
}

/// ③ 試合詳細Viewer用のリッチProjection (アニメーションや詳細軌跡を含む)
@freezed
abstract class MatchProjection with _$MatchProjection {
  const factory MatchProjection({
    required String id,
    required String tournamentId,
    required int matchOrder,
    required String matchType,
    required String status,
    required String groupName, 
    required bool isKachinuki, 
    required String redName,
    required String whiteName,
    @Default([]) List<String> redRemaining,
    @Default([]) List<String> whiteRemaining,
    required int redScore,
    required int whiteScore,
    @Default([]) List<PointDisplay> redDisplays,
    @Default([]) List<PointDisplay> whiteDisplays,
    
    // ★ 復元: 公式記録画面やスコアボードで必須の表示用フィールド
    @Default('') String firstPointSide,
    @Default([]) List<String> redPointMarks,
    @Default([]) List<String> whitePointMarks,

    required int remainingSeconds,
    required bool timerIsRunning,
    required String note,
    @Default([]) List<TimelineEvent> timeline, 
    @Default(0.0) double momentum,             
  }) = _MatchProjection;
}

/// ④ 監査・公式記録用のAuditProjection (不正監視データを含む)
@freezed
abstract class MatchAuditProjection with _$MatchAuditProjection {
  const factory MatchAuditProjection({
    required String id,
    required String status,
    @Default([]) List<TimelineEvent> fullHistory,
    String? scorerId,
    @Default(0) int eventCount,
    @Default(SyncStatus.synced) SyncStatus syncStatus,
  }) = _MatchAuditProjection;
}

// ★ 軽量版向け UI互換用extension
extension MatchListProjectionUIX on MatchListProjection {
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
}

// UI互換用extension
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
    if (timeline.isNotEmpty) {
      final last = timeline.last;
      final prefix = last.side == 'red' ? '【赤】' : (last.side == 'white' ? '【白】' : '【審判】');
      return '$prefix ${last.actionName}';
    }
    if (status == 'finished') return '試合が終了しました';
    if (status == 'in_progress') return '試合が進行中です';
    return '';
  }
}