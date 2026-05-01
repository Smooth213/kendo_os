import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

// ※プロジェクトのパスに合わせてインポートを調整してください
import 'package:kendo_os/repositories/match_repository.dart';

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

    test('watchInProgressMatches: 進行中(in_progress)の試合だけを抽出して監視できるか', () async {
      // 実行
      final stream = repository.watchInProgressMatches();
      final activeMatches = await stream.first;

      // 検証: 3件中、1件だけがヒットするはず
      expect(activeMatches.length, 1, reason: '進行中の試合は1件だけのはず');
      expect(activeMatches.first.id, 'match_active');
      expect(activeMatches.first.status, 'in_progress');
    });

    test('getStaticMatches: 進行中以外(finished, waiting等)の試合を1回だけ取得できるか', () async {
      // 実行
      final staticMatches = await repository.getStaticMatches();

      // 検証: 3件中、進行中を除いた2件がヒットするはず
      expect(staticMatches.length, 2, reason: '進行中以外の試合は2件のはず');
      
      final ids = staticMatches.map((m) => m.id).toList();
      expect(ids.contains('match_done'), isTrue);
      expect(ids.contains('match_waiting'), isTrue);
      expect(ids.contains('match_active'), isFalse, reason: '進行中の試合は含まれてはいけない');
    });
  });
}