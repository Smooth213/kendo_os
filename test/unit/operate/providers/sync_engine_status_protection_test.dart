import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/domain/match/match_model.dart';
import 'package:kendo_os/domain/rules/match_rule.dart';
import 'package:kendo_os/application/usecases/match_usecases.dart';

// --------------------------------------------------
// モック (Fake) クラスの定義
// --------------------------------------------------
// 古いバグの挙動を再現するため、強制的にステータスを初期化(waiting)してしまう
// 悪意のある（または不完全な）UseCaseを定義します。
class FakeRebuildMatchFromEventsUseCase implements RebuildMatchFromEventsUseCase {
  @override
  MatchModel execute(MatchModel match, MatchRule rule) {
    return match.copyWith(
      status: 'waiting', // ★ バグの再現: ここで勝手に初期状態に戻してしまう
      redScore: match.redScore,
      whiteScore: match.whiteScore,
    );
  }
}

void main() {
  group('🛡️ SyncEngine Status Protection Tests (同期時のステータス巻き戻り保護テスト)', () {
    
    test('1. Drift Monitor時: 再計算ロジックがステータスを初期化しても、元の確定ステータス(finished)が維持・保護されること', () {
      // 1. テストデータの準備: ユーザーが確定させた(finished)状態の試合
      const originalStatus = 'finished';
      final match = MatchModel(
        id: 'test-match-123',
        status: originalStatus,
        matchType: '個人戦',
        redScore: 2,
        whiteScore: 0,
        redName: '赤',
        whiteName: '白',
        events: const [], 
      );

      final rebuilder = FakeRebuildMatchFromEventsUseCase();
      final rule = const MatchRule();

      // 2. sync_provider.dart で実際に行われている保護処理をシミュレート
      MatchModel rebuiltMatch = rebuilder.execute(match, rule);
      expect(rebuiltMatch.status, 'waiting', reason: 'バグ再現: Rebuildを通すとステータスが壊れることの確認');

      // ★ 修正された保護コード
      rebuiltMatch = rebuiltMatch.copyWith(status: match.status);

      // 3. 検証
      expect(rebuiltMatch.status, originalStatus, reason: '元のステータス(finished)が完全に復元・保護されているべき');
    });
    
    test('2. CRDTマージ時: 退避したステータスが正しく復元されること', () {
      const originalStatus = 'approved';
      final remoteMatch = MatchModel(id: 'test-match-456', status: originalStatus, matchType: '個人戦', redScore: 1, whiteScore: 1, redName: '赤', whiteName: '白', events: const []);
      
      final rebuilder = FakeRebuildMatchFromEventsUseCase();
      final rule = const MatchRule();

      MatchModel rebuiltMatch = remoteMatch.copyWith(); 
      final savedStatus = rebuiltMatch.status; // ★ ステータスを退避
      rebuiltMatch = rebuilder.execute(rebuiltMatch, rule); // 再計算で壊れる
      rebuiltMatch = rebuiltMatch.copyWith(status: savedStatus); // ★ 復元
      
      expect(rebuiltMatch.status, originalStatus, reason: 'CRDTマージの際も、退避したステータス(approved)が復元されるべき');
    });
  });
}