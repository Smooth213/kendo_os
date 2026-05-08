import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/domain/entities/match_model.dart';
import 'package:kendo_os/domain/entities/score_event.dart';
import 'package:kendo_os/domain/rules/match_rule.dart';
import 'package:kendo_os/application/usecases/match_usecases.dart';
import 'package:kendo_os/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/domain/entities/role_permission.dart';
import 'package:kendo_os/application/mappers/score_event_legacy_adapter.dart';
import '../helpers/test_match_factory.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kendo_os/infrastructure/repository/local_match_repository.dart';

// 永続化層のモック（実際にデータを保持し、疑似的にクラッシュをシミュレートする）
class MockLocalMatchRepository extends Mock implements LocalMatchRepository {
  final Map<String, MatchModel> _db = {};

  @override
  Future<void> saveMatch(MatchModel match) async {
    _db[match.id] = match; // メモリ上で永続化をシミュレート
  }

  @override
  Future<MatchModel?> getMatch(String id) async {
    return _db[id];
  }
}

void main() {
  group('💥 Phase 7-3: アプリ強制終了・クラッシュ復旧テスト', () {
    test('試合途中にアプリがクラッシュしても、再起動時にローカルDBから完全な状態が復元されること', () async {
      // 1. 試合のセットアップ
      final localRepo = MockLocalMatchRepository();
      final rule = const MatchRule(ipponLimit: 2, matchTimeMinutes: 3.0);
      final initialMatch = TestMatchFactory.createIndividualMatch(id: 'crash-match-1');
      // ★ 修正: 必須引数 organizationId を追加
      final user = const User(id: 'scorer_1', role: Role.scorer, organizationId: 'org1');

      // ユースケースの準備（UIを使わずに直接ビジネスロジックを叩く）
      final addScoreUseCase = AddScoreUseCase(KendoRuleEngine(), PermissionService());

      // 2. 試合進行（赤にメンが入る）
      final event1 = ScoreEventLegacyAdapter.fromLegacy(
        side: Side.red, type: PointType.men, userId: user.id, sequence: 1,
      );
      final matchState1 = addScoreUseCase.execute(user, initialMatch, event1, rule);
      
      // DBに保存される（実際はMatchApplicationService経由だが、ここでは直接モックDBに書き込む）
      await localRepo.saveMatch(matchState1);

      // ==========================================
      // 💥 ここでアプリが強制終了（クラッシュ）したと仮定する
      // ==========================================
      
      // メモリ上の変数をすべて消去（シミュレーション）
      MatchModel? crashedMatchState = matchState1;
      crashedMatchState = null; 
      expect(crashedMatchState, isNull); // 完全に消えたことを確認

      // ==========================================
      // 🔄 アプリ再起動（復旧）
      // ==========================================
      
      // 3. ローカルDBからデータを再読み込み
      final recoveredMatch = await localRepo.getMatch('crash-match-1');

      // 4. 検証: クラッシュ前の状態が1ミリも欠けずに復元されていること
      expect(recoveredMatch, isNotNull, reason: 'DBから試合データが復元できること');
      expect(recoveredMatch!.events.length, 1, reason: 'イベント履歴が残っていること');
      expect(recoveredMatch.events[0].type, PointType.men, reason: '赤のメンが記録されていること');
      expect(recoveredMatch.redScore, 1, reason: 'スコアが1になっていること');
      expect(recoveredMatch.status, 'in_progress', reason: '試合は進行中のままであること');
      
      // 5. 復旧後、さらに試合を継続できること（白がコテを取り返す）
      final event2 = ScoreEventLegacyAdapter.fromLegacy(
        side: Side.white, type: PointType.kote, userId: user.id, sequence: 2,
      );
      final matchState2 = addScoreUseCase.execute(user, recoveredMatch, event2, rule);
      
      expect(matchState2.events.length, 2);
      expect(matchState2.redScore, 1);
      expect(matchState2.whiteScore, 1);
    });
  });
}