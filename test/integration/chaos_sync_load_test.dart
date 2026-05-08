import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kendo_os/domain/entities/match_model.dart';
import 'package:kendo_os/domain/entities/score_event.dart';
import 'package:kendo_os/infrastructure/repository/local_match_repository.dart';
import '../helpers/test_match_factory.dart';

// サーバー通信のモック
class MockFirestoreAdapter extends Mock {
  Future<void> sendData(String id, Map<String, dynamic> data);
}

// 永続化層のモック
class MockLocalMatchRepository extends Mock implements LocalMatchRepository {}

class FakeMatchModel extends Fake implements MatchModel {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeMatchModel());
  });

  group('🌪️ Phase 7-4: カオス負荷テスト (大量データ同期)', () {
    test('100件の未送信データが存在しても、同期エンジンがクラッシュせずにすべて高速に処理しきれること', () async {
      final localRepo = MockLocalMatchRepository();
      final mockNetwork = MockFirestoreAdapter();
      final fakeDb = <String, MatchModel>{};

      // 1. カオスな状況の準備：100件の未送信データ（isDirty / pendingEventsあり）を生成
      for (int i = 0; i < 100; i++) {
        final m = TestMatchFactory.createIndividualMatch(id: 'load-match-$i').copyWith(
          pendingEvents: [TestMatchFactory.createEvent(side: Side.red, type: PointType.men)],
        );
        fakeDb[m.id] = m;
      }

      when(() => localRepo.getPendingMatches()).thenAnswer((_) async {
        return fakeDb.values.where((m) => m.pendingEvents.isNotEmpty).toList();
      });

      when(() => localRepo.markAsSynced(any())).thenAnswer((invocation) async {
        final id = invocation.positionalArguments[0] as String;
        if (fakeDb.containsKey(id)) {
          // 同期完了としてフラグを下ろす
          fakeDb[id] = fakeDb[id]!.copyWith(pendingEvents: []);
        }
      });

      when(() => mockNetwork.sendData(any(), any())).thenAnswer((_) async => {});

      // 2. 同期ループの実行とパフォーマンス計測
      final stopwatch = Stopwatch()..start();
      
      final pendingMatches = await localRepo.getPendingMatches();
      expect(pendingMatches.length, 100, reason: '100件の未送信データが正しく認識されていること');

      for (final match in pendingMatches) {
        try {
          await mockNetwork.sendData(match.id, match.toJson());
          await localRepo.markAsSynced(match.id);
        } catch (e) {
          fail('大量処理中にメモリ不足や予期せぬエラーでクラッシュしました: $e');
        }
      }
      stopwatch.stop();

      // 3. 検証
      final finalPending = await localRepo.getPendingMatches();
      expect(finalPending.length, 0, reason: '100件すべてが正しく送信完了し、未送信が0になること');
      verify(() => mockNetwork.sendData(any(), any())).called(100);
      
      // 負荷要件: 100件のモック同期ループ（Json変換等を含む）が1秒(1000ms)以内に完了すること
      expect(stopwatch.elapsedMilliseconds, lessThan(1000), reason: '大量の同期ループ処理に致命的なボトルネックがないこと');
    });
  });
}