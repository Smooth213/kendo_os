import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
// ※ libフォルダ内のファイルをテストから読み込むためのパッケージパス
import 'package:kendo_os/providers/match_list_provider.dart';
import 'package:kendo_os/models/match_model.dart';
import 'package:kendo_os/models/score_event.dart';
import 'package:kendo_os/providers/match_command_provider.dart';
import 'package:kendo_os/providers/match_timer_provider.dart';

void main() {
  group('MatchListProvider (Score Logic) Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late ProviderContainer container;

    setUp(() {
      // 毎回テストの前に、まっさらな「偽データベース」を用意する
      fakeFirestore = FakeFirebaseFirestore();
      
      // コンテナを作り、本物のFirestoreを「偽物」に強制的にすり替える！
      container = ProviderContainer(
        overrides: [
          firestoreProvider.overrideWithValue(fakeFirestore),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('addScoreEventで「面」が正しく追加され、スコアが増えるか', () async {
      // 1. 偽のデータベースに初期データをセット
      final testMatch = const MatchModel(
        id: 'test_1', matchType: '先鋒', redName: '赤', whiteName: '白'
      );
      await fakeFirestore.collection('matches').doc('test_1').set(testMatch.toJson());
      
      // 2. Providerを初期化し、偽データベースからデータを読み込ませる
      container.read(matchListProvider);
      await Future.delayed(const Duration(milliseconds: 100)); // 読み込みのタイムラグを待つ

      // 3. 赤に「面」を追加
      await container.read(matchCommandProvider).addScoreEvent('test_1', Side.red, PointType.men);
      await Future.delayed(const Duration(milliseconds: 100)); // 保存と反映を待つ

      // 4. 検証！
      final match = container.read(matchListProvider).firstWhere((m) => m.id == 'test_1');
      expect(match.redScore, 1, reason: '赤のスコアが1に増えているはず');
      expect(match.events.length, 1, reason: 'イベントログが1つ追加されているはず');
      expect(match.events.first.type, PointType.men, reason: '記録されたのは「面」のはず');
    });

    test('addScoreEventで、反則2回目で相手に1本入るか', () async {
      final testMatch = const MatchModel(id: 'test_2', matchType: '次鋒', redName: '赤', whiteName: '白');
      await fakeFirestore.collection('matches').doc('test_2').set(testMatch.toJson());
      
      container.read(matchListProvider);
      await Future.delayed(const Duration(milliseconds: 100));

      final command = container.read(matchCommandProvider);

      // 1回目の反則（赤）
      await command.addScoreEvent('test_2', Side.red, PointType.hansoku);
      await Future.delayed(const Duration(milliseconds: 100));
      var match = container.read(matchListProvider).firstWhere((m) => m.id == 'test_2');
      expect(match.whiteScore, 0, reason: '反則1回目では相手（白）にポイントは入らないはず');

      // 2回目の反則（赤）
      await command.addScoreEvent('test_2', Side.red, PointType.hansoku);
      await Future.delayed(const Duration(milliseconds: 100));
      match = container.read(matchListProvider).firstWhere((m) => m.id == 'test_2');
      expect(match.whiteScore, 1, reason: '反則2回目で相手（白）に1ポイント入るはず');
    });

    test('undoLastEventで「2回目の反則」を取り消すと、相手の得点も正しく減るか', () async {
      final testMatch = const MatchModel(id: 'test_3', matchType: '中堅', redName: '赤', whiteName: '白');
      await fakeFirestore.collection('matches').doc('test_3').set(testMatch.toJson());
      
      container.read(matchListProvider);
      await Future.delayed(const Duration(milliseconds: 100));

      final command = container.read(matchCommandProvider);

      // 反則を2回追加（白に1本入る）
      // ★ 修正：プログラムの連打が早すぎるため、1回目の反則がDBに反映されるのを待ってから2回目を打つ
      await command.addScoreEvent('test_3', Side.red, PointType.hansoku);
      await Future.delayed(const Duration(milliseconds: 100)); 
      
      await command.addScoreEvent('test_3', Side.red, PointType.hansoku);
      await Future.delayed(const Duration(milliseconds: 100));
      
      var match = container.read(matchListProvider).firstWhere((m) => m.id == 'test_3');
      expect(match.whiteScore, 1, reason: 'この時点では白に1点入っているはず');

      // Undo（1つ前に戻す）を実行
      await command.undoLastEvent('test_3');
      await Future.delayed(const Duration(milliseconds: 100));

      match = container.read(matchListProvider).firstWhere((m) => m.id == 'test_3');
      expect(match.whiteScore, 0, reason: '2回目の反則が取り消されたので、白の得点も0に戻るはず');
      expect(match.events.length, 1, reason: 'イベントログは反則1回分だけ残っているはず');
    });

    test('異常系ガード: 終了した試合(finished)にはスコアが追加されないか', () async {
      final testMatch = const MatchModel(
        id: 'test_4', matchType: '副将', redName: '赤', whiteName: '白', status: 'finished'
      );
      await fakeFirestore.collection('matches').doc('test_4').set(testMatch.toJson());
      
      container.read(matchListProvider);
      await Future.delayed(const Duration(milliseconds: 100));

      // 終了した試合に「面」を追加しようとする
      await container.read(matchCommandProvider).addScoreEvent('test_4', Side.red, PointType.men);
      await Future.delayed(const Duration(milliseconds: 100));

      final match = container.read(matchListProvider).firstWhere((m) => m.id == 'test_4');
      expect(match.redScore, 0, reason: '終了済みの試合なのでスコアは0のまま弾かれるはず');
      expect(match.events.isEmpty, true, reason: 'イベントも追加されないはず');
    });

    test('異常系ガード: 残り時間が0秒の時はタイマーがスタートしないか', () async {
      final testMatch = const MatchModel(
        id: 'test_5', matchType: '大将', redName: '赤', whiteName: '白', remainingSeconds: 0, timerIsRunning: false
      );
      await fakeFirestore.collection('matches').doc('test_5').set(testMatch.toJson());
      
      container.read(matchListProvider);
      await Future.delayed(const Duration(milliseconds: 100));

      // タイマーをトグル（スタート）しようとする
      await container.read(matchTimerProvider).toggleTimer('test_5');
      await Future.delayed(const Duration(milliseconds: 100));

      final match = container.read(matchListProvider).firstWhere((m) => m.id == 'test_5');
      expect(match.timerIsRunning, false, reason: '残り0秒なのでスタートできずにfalseのままのはず');
    });

    test('異常系ガード: イベントが0件の時にUndoを押してもクラッシュしないか', () async {
      final testMatch = const MatchModel(id: 'test_6', matchType: '先鋒', redName: '赤', whiteName: '白', events: []);
      await fakeFirestore.collection('matches').doc('test_6').set(testMatch.toJson());
      
      container.read(matchListProvider);
      await Future.delayed(const Duration(milliseconds: 100));

      // 履歴が何もないのにUndoを呼ぶ（アプリが落ちないことがゴール）
      await container.read(matchCommandProvider).undoLastEvent('test_6');
      await Future.delayed(const Duration(milliseconds: 100));

      final match = container.read(matchListProvider).firstWhere((m) => m.id == 'test_6');
      expect(match.events.isEmpty, true, reason: '何も起きていない（クラッシュせずにスルーされた）はず');
    });

    test('排他制御(claimScorer): 他の人がスコアラーになっている時は横取りできないか', () async {
      final testMatch = const MatchModel(
        id: 'test_8', matchType: '中堅', redName: '赤', whiteName: '白', scorerId: 'User_A'
      );
      await fakeFirestore.collection('matches').doc('test_8').set(testMatch.toJson());
      
      container.read(matchListProvider);
      await Future.delayed(const Duration(milliseconds: 100));

      // 別のユーザー（User_B）がスコアラー権限を取ろうとする
      final success = await container.read(matchCommandProvider).claimScorer('test_8', 'User_B');
      await Future.delayed(const Duration(milliseconds: 100));

      final match = container.read(matchListProvider).firstWhere((m) => m.id == 'test_8');
      expect(success, false, reason: 'User_Aがすでに取っているので、User_Bは失敗(false)するはず');
      expect(match.scorerId, 'User_A', reason: 'スコアラーはUser_Aのまま維持されるはず');
    });
  });
}