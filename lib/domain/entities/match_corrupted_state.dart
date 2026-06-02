import 'package:kendo_os/domain/match/match_model.dart';
import 'package:kendo_os/domain/match/match_state.dart';

class MatchCorruptedState {
  final MatchModel match;

  MatchCorruptedState(this.match);

  /// 試合状態が破損しているか（未知のステータス等）を判定する
  bool get isCorrupted {
    final state = MatchLifecycleStateLegacyExt.fromLegacyString(match.status);
    return state == MatchLifecycleState.corrupted;
  }

  /// ★ Phase 2-3: 障害リカバリ防衛プロパティの定義
  /// 不正入力による状態の二次破壊を防ぐため、破損試合の新規編集（打突追加・タイマー起動等）を完全に停止
  bool get allowEdit => !isCorrupted;

  /// 電波障害による現地混乱を防ぐため、客席や保護者用の画面（Viewer）でのリアルタイム状況閲覧の継続を許可
  bool get allowViewer => true;

  /// 本部での手動復旧 drill 用に、蓄積されたイベントログ（生データ）の救済・テキスト書き出し（Export）を許可
  bool get allowExport => isCorrupted;
}
