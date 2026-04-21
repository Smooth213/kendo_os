import 'package:freezed_annotation/freezed_annotation.dart';
import 'json_converters.dart'; // ★ 追加：作ったコンバーターを読み込む
import 'score_event.dart';

part 'match_model.freezed.dart';
part 'match_model.g.dart';

// ★ Phase 1: 復元用のスナップショットモデル
@freezed
abstract class MatchSnapshot with _$MatchSnapshot {
  const factory MatchSnapshot({
    required String id,
    @TimestampConverter() required DateTime createdAt,
    required String reason,
    @Default([]) List<ScoreEvent> events,
  }) = _MatchSnapshot;

  factory MatchSnapshot.fromJson(Map<String, dynamic> json) => _$MatchSnapshotFromJson(json);
}

@freezed
abstract class MatchModel with _$MatchModel {
  // ★ フェーズ4：イベントリストからスコアを算出するなど、将来的にカスタムメソッド(派生データ)を持たせるための準備
  const MatchModel._(); 

  const factory MatchModel({
    required String id,
    required String matchType,
    required String redName,
    required String whiteName,
    @Default(0) int redScore,
    @Default(0) int whiteScore,
    @Default('waiting') String status,
    @Default([]) List<ScoreEvent> events, // ★ これが「真実のデータ（Single Source of Truth）」となる
    @Default([]) List<MatchSnapshot> snapshots, // ★ Phase 1: 保存されたスナップショットの履歴
    @Default(false) bool isDirty, // ローカルで変更があり、同期が必要な場合に true
    @TimestampConverter() DateTime? lastUpdatedAt, // 競合解決のための最終更新日時
    @Default([]) List<String> refereeNames,
    @Default(true) bool countForStandings,
    String? scorerId,
    @TimestampConverter() DateTime? lockExpiresAt, // ★ Phase 3: デッドロック防止の有効期限
    @Default(1) int version,
    @Default(false) bool isAutoAssigned,
    @DoubleConverter() @Default(0.0) double order,
    @Default('manual') String source,
    String? tournamentId,
    String? category,
    String? groupName,
    int? matchOrder,
    // ★ intに戻します
    @Default(3) int matchTimeMinutes,
    @Default(false) bool isRunningTime,
    @Default(false) bool hasExtension,
    int? extensionTimeMinutes,
    int? extensionCount,
    @Default(false) bool hasHantei,
    @Default(180) int remainingSeconds,
    @Default(false) bool timerIsRunning,
    @Default('') String note,
    @Default(false) bool isKachinuki, 
    @Default([]) List<String> redRemaining, 
    @Default([]) List<String> whiteRemaining,
  }) = _MatchModel;

  factory MatchModel.fromJson(Map<String, dynamic> json) => _$MatchModelFromJson(json);
}