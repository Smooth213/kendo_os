import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

// ※プロジェクトのパスに合わせてインポートを調整してください
import 'package:kendo_os/infrastructure/repository/match_repository.dart';

void main() {
  group('Phase 1: MatchRepository Optimization Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MatchRepository repository;

    setUp(() async {
      // 1. 本物のFirestoreの代わりに、超高速なダミー(Fake)を用意する
      fakeFirestore = FakeFirebaseFirestore();
      repository = MatchRepository(fakeFirestore);

      // 2. テスト用のダミーデータを投入（ステータスがバラバラの3試合）
      final matchesCollection = fakeFirestore.collection('matches');
      
      await matchesCollection.doc('match_active').set({
        'matchType': '先鋒',
        'redName': '赤',
        'whiteName': '白',
        'status': 'in_progress', // 進行中
      });
      
      await matchesCollection.doc('match_done').set({
        'matchType': '次鋒',
        'redName': '赤',
        'whiteName': '白',
        'status': 'finished', // 終了済み
      });
      
      await matchesCollection.doc('match_waiting').set({
        'matchType': '中堅',
        'redName': '赤',
        'whiteName': '白',
        'status': 'waiting', // 待機中
      });
    });

    test('watchActiveMatches: 進行中(in_progress)と待機中(waiting)の試合を抽出して監視できるか', () async {
      // 実行
      final stream = repository.watchActiveMatches();
      final activeMatches = await stream.first;

      // 検証: 3件中、進行中と待機中の2件がヒットするはず
      expect(activeMatches.length, 2, reason: '進行中と待機中の試合が2件ヒットするはず');
      final ids = activeMatches.map((m) => m.id).toList();
      expect(ids.contains('match_active'), isTrue);
      expect(ids.contains('match_waiting'), isTrue);
    });

    test('getStaticMatches: 終了済み(finished, approved)の試合を1回だけ取得できるか', () async {
      // 実行
      final staticMatches = await repository.getStaticMatches();

      // 検証: 3件中、終了済みの1件がヒットするはず
      expect(staticMatches.length, 1, reason: '終了済みの試合は1件のはず');
      
      final ids = staticMatches.map((m) => m.id).toList();
      expect(ids.contains('match_done'), isTrue);
      expect(ids.contains('match_waiting'), isFalse);
      expect(ids.contains('match_active'), isFalse);
    });
  });
}