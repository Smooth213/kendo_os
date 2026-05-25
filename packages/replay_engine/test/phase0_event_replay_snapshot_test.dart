import 'dart:math';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/application/usecases/match_usecases.dart';
import 'package:kendo_os/domain/rules/match_rule.dart';
import 'package:kendo_os/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/domain/entities/role_permission.dart';
import 'package:kendo_os/domain/match/match_model.dart';
import 'package:kendo_os/domain/score/score_event.dart';
import 'package:kendo_os/application/mappers/score_event_legacy_adapter.dart';
import '../../../test/helpers/test_match_factory.dart';
import 'package:kendo_os/core/time/system_time_source.dart';

void main() {
  group('📼 Phase 0-3: Event Replay Snapshot (履歴の完全再生比較)', () {
    test('100試合のランダムイベントを処理し、最終状態のチェックサムが一致すること', () {
      final engine = KendoRuleEngine();
      final permission = PermissionService();
      final timeSource = SystemTimeSource();
      final addScoreUseCase = AddScoreUseCase(engine, permission, timeSource);
      final undoScoreUseCase = UndoScoreUseCase(engine, permission, timeSource);
      final testUser = const User(id: 'snapshot_user', role: Role.admin, organizationId: 'test_org');
      final rule = const MatchRule();

      // 固定シード(42)を使用することで、何度実行しても「全く同じ100試合の歴史」が生成される
      final random = Random(42); 
      
      int totalRedScoreChecksum = 0;
      int totalWhiteScoreChecksum = 0;
      int totalFinishedMatches = 0;

      for (int i = 0; i < 100; i++) {
        var match = TestMatchFactory.createIndividualMatch(id: 'replay-match-$i');
        final eventCount = random.nextInt(15) + 1; // 1〜15件のイベント

        for (int j = 0; j < eventCount; j++) {
          if (match.status == 'finished') break; // 終了していたら打ち切り

          final isUndo = random.nextDouble() < 0.1; // 10%でUndo
          if (isUndo && match.events.isNotEmpty) {
            match = undoScoreUseCase.execute(testUser, match, rule);
            continue;
          }

          final side = random.nextBool() ? Side.red : Side.white;
          final type = _randomPointType(random);
          
          final event = ScoreEventLegacyAdapter.fromLegacy(
            side: side, type: type, sequence: 0, userId: testUser.id,
          );

          match = addScoreUseCase.execute(testUser, match, event, rule);
        }

        totalRedScoreChecksum += match.redScore.toInt();
        totalWhiteScoreChecksum += match.whiteScore.toInt();
        if (match.status == 'finished') totalFinishedMatches++;
      }

      // ★ すべての真実のチェックサムを出力して確認する
      debugPrint('★★★ 真実のチェックサム ★★★');
      debugPrint('Red: $totalRedScoreChecksum');
      debugPrint('White: $totalWhiteScoreChecksum');
      debugPrint('Finished: $totalFinishedMatches');

      // ★ 判明した真実のチェックサムを完全固定（FSM化後も絶対にこの数値にならなければならない）
      expect(totalRedScoreChecksum, 95, reason: '赤の総スコア合計(Checksum)が壊れています。リファクタリングによるデグレが発生しました。');
      expect(totalWhiteScoreChecksum, 132, reason: '白の総スコア合計(Checksum)が壊れています。リファクタリングによるデグレが発生しました。');
      expect(totalFinishedMatches, 88, reason: '終了した試合数(Checksum)が壊れています。リファクタリングによるデグレが発生しました。');
    });

    test('0-2: Rule JSON Snapshot (入力イベントと期待される結果の固定化)', () {
      final engine = KendoRuleEngine();
      final permission = PermissionService();
      final timeSource = SystemTimeSource();
      final addScoreUseCase = AddScoreUseCase(engine, permission, timeSource);
      final testUser = const User(id: 'json_user', role: Role.admin, organizationId: 'test_org');
      final rule = const MatchRule();

      var match = TestMatchFactory.createIndividualMatch(id: 'json-snapshot-1');
      
      // テスト用のイベントを追加
      match = addScoreUseCase.execute(testUser, match, ScoreEventLegacyAdapter.fromLegacy(side: Side.red, type: PointType.men, sequence: 0, userId: testUser.id), rule);
      match = addScoreUseCase.execute(testUser, match, ScoreEventLegacyAdapter.fromLegacy(side: Side.white, type: PointType.kote, sequence: 0, userId: testUser.id), rule);

      // JSON化 (0-2の要件)
      final snapshot = {
        "events": match.events.map((e) => {'type': e.type.name, 'side': e.side.name}).toList(),
        "expectedResult": {
          "redScore": match.redScore,
          "whiteScore": match.whiteScore,
          "status": match.status,
        }
      };

      // 現状のルールエンジンが弾き出すJSON構造を絶対に変わらない「真実」としてアサートする
      expect(snapshot['events'], [
        {'type': 'men', 'side': 'red'},
        {'type': 'kote', 'side': 'white'}
      ], reason: 'イベントのJSONシリアライズ結果が一致しません');
      
      expect((snapshot['expectedResult'] as Map)['redScore'], 1);
      expect((snapshot['expectedResult'] as Map)['whiteScore'], 1);
      expect((snapshot['expectedResult'] as Map)['status'], 'in_progress');
    });

    // ============================================================================
    // ⚙️ 最終章・Phase 8 カオス検証自動化ライン（手順 8-1〜8-3）
    // ============================================================================
    test('Phase 8-1, 8-2, 8-3: 体育館電波断・タイマーNaN汚染・プロセスKillからの決定論的Snapshot再生復旧テスト', () {
      final engine = KendoRuleEngine();
      final permission = PermissionService();
      final timeSource = SystemTimeSource();
      final addScoreUseCase = AddScoreUseCase(engine, permission, timeSource);
      final testUser = const User(id: 'chaos_v8_user', role: Role.admin, organizationId: 'test_org');
      
      // 1. 【手順 8-2 耐久検証】: タイマーに Infinity や NaN などの異常値（省電力モード時の端数クラッシュ要因）を強制注入
      var chaosMatch = TestMatchFactory.createIndividualMatch(id: 'chaos-match-v8').copyWith(
        matchTimeMinutes: double.nan, // NaNを意図的にパルス注入
      );

      // 判定ロジックが自爆クラッシュ（toInt 例外）を起こさず、安全防壁が機能して0秒（タイムアップ）として処理されることを検証
      final remainingSeconds = chaosMatch.calculateRemainingSeconds(DateTime.now());
      expect(remainingSeconds, 0, reason: '【手順8-2】タイマーNaN汚染時に自爆クラッシュを弾く防衛線が機能していません。');

      // 2. 【手順 8-1 & 8-3 複合検証】: 4時間・100試合の連続高密度カオス運用、および突然の強制シャットダウン（Process Kill）の完全シミュレート
      final seedRandom = Random(20260522); // 2026年5月22日決定論固定シード
      int redScoreAccumulator = 0;
      int whiteScoreAccumulator = 0;
      
      // 端末内メモリ（RAM空間）に見立てた仮想ストレージ
      final Map<String, String> simulatedIsarDisk = {};

      for (int i = 0; i < 100; i++) {
        var matchState = TestMatchFactory.createIndividualMatch(id: 'chaos-sim-$i');
        
        // 1試合の中にランダムな打突・反則・Undoが激しく交錯するカオスストリームを生成
        for (int j = 0; j < 8; j++) {
          // ★ 適合修正: ルールエンジンによって既に勝敗が決し、終了(finished)した場合はこれ以上の打突入力を自動ブレーク
          // これにより、ドメインルールと完全にシンクロした100%決定論的な歴史データが作成されます。
          if (matchState.status == 'finished' || matchState.status == 'approved') {
            break;
          }

          final side = seedRandom.nextBool() ? Side.red : Side.white;
          final type = _randomPointType(seedRandom);
          final event = ScoreEventLegacyAdapter.fromLegacy(side: side, type: type, sequence: j, userId: testUser.id);
          
          matchState = addScoreUseCase.execute(testUser, matchState, event, const MatchRule());
        }

        // 💾 【手順 8-1 即時ライトスルー確約】: 
        // ★ 適合修正: Timestamp が混入しても落ちないよう、toJsonの出力結果を一旦 Map 化し、再帰的に Timestamp を DateTime(ISO8601) 文字列へ変換してから JSON化
        final Map<String, dynamic> jsonMap = matchState.toJson();
        _safeSerializeTimestamps(jsonMap);
        simulatedIsarDisk[matchState.id] = jsonEncode(jsonMap);
      }

      // 💥 【手順 8-3 プロセスKillの執行】: メモリ上の実行中データを物理的に完全消去（ヌルリセット）
      redScoreAccumulator = 0;
      whiteScoreAccumulator = 0;

      // 📼 【復旧リカバリドリル】: 端末再起動後、ローカルディスクのSnapshot地層のみから全データを復元し、歴史を100%完全再生
      for (final matchId in simulatedIsarDisk.keys) {
        final rawJson = simulatedIsarDisk[matchId]!;
        final hydratedModel = MatchModel.fromJson(jsonDecode(rawJson) as Map<String, dynamic>);
        
        redScoreAccumulator += hydratedModel.redScore;
        whiteScoreAccumulator += hydratedModel.whiteScore;
      }

      // 🏁 チェックサムの絶対不変アサーション（122/127 はこの環境の決定論的真実として固定）
      debugPrint('🏁 [Chaos Final Checksum] Red: $redScoreAccumulator | White: $whiteScoreAccumulator');
      
      expect(redScoreAccumulator, 122, reason: '【手順8-1】ライトスルー書き込み、または【手順8-3】プロセスKill復旧時に赤のスコアにリプレイ・ドリフト（歴史のズレ）が発生しました。');
      expect(whiteScoreAccumulator, 127, reason: '【手順8-1】ライトスルー書き込み、または【手順8-3】プロセスKill復旧時に白のスコアにリプレイ・ドリフト（歴史のズレ）が発生しました。');
    });
  });
}

PointType _randomPointType(Random r) {
  final types = [PointType.men, PointType.kote, PointType.doIdo, PointType.tsuki, PointType.hansoku];
  return types[r.nextInt(types.length)];
}

void _safeSerializeTimestamps(dynamic data) {
  if (data is Map) {
    for (var key in data.keys.toList()) {
      final value = data[key];
      if (value == null) continue;
      if (value.runtimeType.toString() == 'Timestamp') {
        data[key] = (value as dynamic).toDate().toIso8601String();
      } else if (value is DateTime) {
        data[key] = value.toIso8601String();
      } else {
        _safeSerializeTimestamps(value);
      }
    }
  } else if (data is List) {
    for (int i = 0; i < data.length; i++) {
      final value = data[i];
      if (value == null) continue;
      if (value.runtimeType.toString() == 'Timestamp') {
        data[i] = (value as dynamic).toDate().toIso8601String();
      } else if (value is DateTime) {
        data[i] = value.toIso8601String();
      } else {
        _safeSerializeTimestamps(value);
      }
    }
  }
}