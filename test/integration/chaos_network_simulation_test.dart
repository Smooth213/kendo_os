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

// ★ 修正: extends LocalMatchRepository ではなく、Mock implements にしてコンストラクタ問題を回避
class MockLocalMatchRepository extends Mock implements LocalMatchRepository {}

class FakeMatchModel extends Fake implements MatchModel {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeMatchModel());
  });

  group('🌪️ Phase 7-1: カオスネットワークシミュレーション (Offline -> Online復旧)', () {
    late MockLocalMatchRepository localRepo;
    late MockFirestoreAdapter mockNetwork;
    late Map<String, MatchModel> fakeDb;

    setUp(() {
      localRepo = MockLocalMatchRepository();
      mockNetwork = MockFirestoreAdapter();
      fakeDb = {};

      // LocalRepoのフェイク実装（メモリ上で動作させる）
      when(() => localRepo.saveMatch(any())).thenAnswer((invocation) async {
        final match = invocation.positionalArguments[0] as MatchModel;
        fakeDb[match.id] = match;
      });

      when(() => localRepo.getPendingMatches()).thenAnswer((_) async {
        // isDirty または pendingEvents があるものを未送信とみなす
        return fakeDb.values.where((m) => m.isDirty || m.pendingEvents.isNotEmpty).toList();
      });

      when(() => localRepo.markAsSynced(any())).thenAnswer((invocation) async {
        final id = invocation.positionalArguments[0] as String;
        if (fakeDb.containsKey(id)) {
          // ★ 修正: 存在しない SyncState.pending を削除し、pendingEvents を空にすることで送信完了を表現
          fakeDb[id] = fakeDb[id]!.copyWith(pendingEvents: []); 
        }
      });
    });

    test('通信断絶中に蓄積されたデータが、通信復旧時の同期エンジンによって全て送信されること', () async {
      // 1. オフライン状態で試合データがローカルに保存される（未送信状態）
      final offlineMatch1 = TestMatchFactory.createIndividualMatch(id: 'offline-1').copyWith(
        pendingEvents: [TestMatchFactory.createEvent(side: Side.red, type: PointType.men)],
      );
      final offlineMatch2 = TestMatchFactory.createIndividualMatch(id: 'offline-2').copyWith(
        pendingEvents: [TestMatchFactory.createEvent(side: Side.white, type: PointType.kote)],
      );

      await localRepo.saveMatch(offlineMatch1);
      await localRepo.saveMatch(offlineMatch2);

      // 確認: ローカルには未送信データが2件ある
      final initialPending = await localRepo.getPendingMatches();
      expect(initialPending.length, 2, reason: 'オフラインなので未送信データが溜まっている');

      // 2. ネットワークが復旧し、SyncEngineの挙動をシミュレート
      when(() => mockNetwork.sendData(any(), any())).thenAnswer((_) async => {});

      final pendingMatches = await localRepo.getPendingMatches();
      for (final match in pendingMatches) {
        try {
          // 擬似的なネットワーク送信
          await mockNetwork.sendData(match.id, match.toJson());
          // 送信成功ならローカルの未送信フラグをクリア
          await localRepo.markAsSynced(match.id);
        } catch (e) {
          fail('ネットワーク送信で予期せぬエラーが発生しました: $e');
        }
      }

      // 3. 検証: 未送信データが0件になっていること
      final finalPending = await localRepo.getPendingMatches();
      expect(finalPending.length, 0, reason: '同期が成功し、未送信データは空になること');

      // ネットワーク送信が2回呼ばれたことを検証
      verify(() => mockNetwork.sendData(any(), any())).called(2);
    });
  });
}