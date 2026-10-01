import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_micro_batch.dart';

void main() {
  group('[Unit] ローカル試合マイクロバッチ 単体テスト', () {
    test('遅延バッチ蓄積において 非クリティカル更新時はタイマー満了までフラッシュが保留されること', () async {
      final savedMatches = <MatchModel>[];
      final savedBulkMatches = <List<MatchModel>>[];

      final batch = LocalMatchMicroBatch(
        saveMatch: (m) async => savedMatches.add(m),
        saveMatchesBulk: (list) async => savedBulkMatches.add(list),
      );

      final match = const MatchModel(
        id: 'mb-match-1',
        matchType: '個人戦',
        redName: '選手赤',
        whiteName: '選手白',
        status: 'waiting',
      );

      // 非クリティカル更新
      await batch.saveMatchBatched(match, isCritical: false);

      // タイマー前はまだ保存関数が呼ばれていないこと
      expect(savedMatches.isEmpty, isTrue);
      expect(savedBulkMatches.isEmpty, isTrue);

      // 明示的にフラッシュ実行
      await batch.flush();

      expect(savedMatches.length, 1);
      expect(savedMatches.first.id, 'mb-match-1');
      batch.dispose();
    });

    test('クリティカル変更即時フラッシュにおいて 得点や試合終了などの変更時に即座に保存が実行されること', () async {
      final savedMatches = <MatchModel>[];

      final batch = LocalMatchMicroBatch(
        saveMatch: (m) async => savedMatches.add(m),
        saveMatchesBulk: (list) async => savedMatches.addAll(list),
      );

      final scoreMatch = const MatchModel(
        id: 'mb-match-score',
        matchType: '個人戦',
        redName: '選手赤',
        whiteName: '選手白',
        redScore: 1,
      );

      await batch.saveMatchBatched(scoreMatch);
      // 得点変更はクリティカル判定のため即座に保存されること
      expect(savedMatches.length, 1);
      expect(savedMatches.first.redScore, 1);

      final finishMatch = const MatchModel(
        id: 'mb-match-finish',
        matchType: '個人戦',
        redName: '選手赤',
        whiteName: '選手白',
        status: 'finished',
      );

      await batch.saveMatchBatched(finishMatch);
      expect(savedMatches.length, 2);
      expect(savedMatches.last.status, 'finished');

      batch.dispose();
    });

    test('インフライト並行保護において 先行フラッシュ実行中の多重呼び出しが安全に待機制御されること', () async {
      final savedMatches = <MatchModel>[];
      var delayedSave = false;

      final batch = LocalMatchMicroBatch(
        saveMatch: (m) async {
          if (delayedSave) {
            await Future.delayed(const Duration(milliseconds: 30));
          }
          savedMatches.add(m);
        },
        saveMatchesBulk: (list) async {
          if (delayedSave) {
            await Future.delayed(const Duration(milliseconds: 30));
          }
          savedMatches.addAll(list);
        },
      );

      delayedSave = true;
      final match1 = const MatchModel(
        id: 'mb-match-concurrent-1',
        matchType: '個人戦',
        redName: '選手赤1',
        whiteName: '選手白1',
      );
      final match2 = const MatchModel(
        id: 'mb-match-concurrent-2',
        matchType: '個人戦',
        redName: '選手赤2',
        whiteName: '選手白2',
      );

      await batch.saveMatchBatched(match1, isCritical: false);
      final firstFlush = batch.flush();

      // インフライト中に次の試合を追加してフラッシュ
      await batch.saveMatchBatched(match2, isCritical: false);
      final secondFlush = batch.flush();

      await Future.wait([firstFlush, secondFlush]);

      final ids = savedMatches.map((m) => m.id).toSet();
      expect(ids.contains('mb-match-concurrent-1'), isTrue);
      expect(ids.contains('mb-match-concurrent-2'), isTrue);

      batch.dispose();
    });

    test('廃棄時安全性において dispose実行時にタイマーが破棄され残存バッファがフラッシュされること', () async {
      final savedMatches = <MatchModel>[];

      final batch = LocalMatchMicroBatch(
        saveMatch: (m) async => savedMatches.add(m),
        saveMatchesBulk: (list) async => savedMatches.addAll(list),
      );

      final match = const MatchModel(
        id: 'mb-match-dispose',
        matchType: '個人戦',
        redName: '選手赤',
        whiteName: '選手白',
      );

      await batch.saveMatchBatched(match, isCritical: false);
      batch.dispose();

      // dispose内のunawaited(flush())の完了を少し待つ
      await Future.delayed(const Duration(milliseconds: 10));
      expect(savedMatches.length, 1);
      expect(savedMatches.first.id, 'mb-match-dispose');
    });
  });
}
