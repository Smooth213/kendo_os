import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/domain/entities/match_corrupted_state.dart';
import 'package:kendo_os/shared/domain/entities/match_corruption_exception.dart';

void main() {
  group('[Unit] 障害フェイルセーフおよび破損データ隔離モデル単体テスト', () {
    test('正常な試合状態において破損フラグが無効であり編集が許可されること', () {
      final match = MatchModel(
        id: 'match-normal-001',
        tournamentId: 't-001',
        matchType: '個人戦',
        redName: '選手A',
        whiteName: '選手B',
        status: 'in_progress',
      );

      final state = MatchCorruptedState(match);

      expect(state.isCorrupted, isFalse);
      expect(state.allowEdit, isTrue);
      expect(state.allowViewer, isTrue);
      expect(state.allowExport, isFalse);
    });

    test('破損した試合状態において二次破壊防止のため編集が遮断され救済エクスポートが有効化されること', () {
      final corruptedMatch = MatchModel(
        id: 'match-corrupted-001',
        tournamentId: 't-001',
        matchType: '個人戦',
        redName: '選手A',
        whiteName: '選手B',
        status: 'corrupted',
      );

      final state = MatchCorruptedState(corruptedMatch);

      expect(state.isCorrupted, isTrue);
      expect(state.allowEdit, isFalse);
      expect(state.allowViewer, isTrue);
      expect(state.allowExport, isTrue);
    });

    test('MatchCorruptionExceptionにおいて試合識別子を含む詳細メッセージが正しく構築されること', () {
      final exWithId = MatchCorruptionException(
        'イベント履歴のチェックサム不整合',
        matchId: 'm-999',
      );
      expect(
        exWithId.toString(),
        'MatchCorruptionException: イベント履歴のチェックサム不整合 (Match ID: m-999)',
      );

      final exWithoutId = MatchCorruptionException('不明なデコードエラー');
      expect(exWithoutId.toString(), 'MatchCorruptionException: 不明なデコードエラー');
    });
  });
}
