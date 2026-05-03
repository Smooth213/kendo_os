import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ※ プロジェクトの実際のパスに合わせてインポートを調整してください
import 'package:kendo_os/domain/entities/match_model.dart';
import 'package:kendo_os/presentation/operate/providers/bunaiksen_provider.dart';
// ★ 追加：本番環境のヘルパークラスをインポート
import 'package:kendo_os/domain/services/bunaiksen_helper.dart';

// ============================================================================
// 【単体テスト（Unit Test）実行部】
// 以前の仮設モック（BunaiksenLogicHelper）を削除し、
// 分離が完了した本番用の BunaiksenHelper を直接テストします！
// ============================================================================
void main() {
  group('カテゴリ1: 部内戦ルールのテスト', () {
    test('部内戦の基本ルールが正しく定義されていること（3分・延長なし）', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final rule = container.read(bunaiksenRuleProvider);

      expect(rule.matchTimeMinutes, 3, reason: '試合時間は3分であるべき');
      expect(rule.enchoTimeMinutes, 0, reason: '基本ルールでは延長戦は無し(0分)であるべき');
      expect(rule.isEnchoUnlimited, false, reason: '無限延長は無効であるべき');
    });
  });

  group('カテゴリ2: 技（スコアマーク）変換ロジックのテスト', () {
    test('赤が先取（メン）、白が取り返し（コテ）、赤が勝負あり（ドウ）の場合の正確な変換', () {
      final mockEvents = [
        {'side': 'red', 'type': 'men'},
        {'side': 'white', 'type': 'kote'},
        {'side': 'red', 'type': 'do'},
      ];

      // ★ 本番の BunaiksenHelper を使用
      final redMarks = BunaiksenHelper.extractMarks(mockEvents, true);
      final whiteMarks = BunaiksenHelper.extractMarks(mockEvents, false);

      expect(redMarks.length, 2);
      expect(redMarks[0], '㋱', reason: '試合全体の先取技なので丸囲みの「㋱」になるべき');
      expect(redMarks[1], 'ド', reason: '3本目の技なので通常の「ド」になるべき');

      expect(whiteMarks.length, 1);
      expect(whiteMarks[0], 'コ', reason: '2本目の技なので通常の「コ」になるべき');
    });

    test('取り消し（Undo/isCanceled）された技が無視され、次の技が正しく先取（丸囲み）扱いになること', () {
      final mockEvents = [
        {'side': 'red', 'type': 'men', 'isCanceled': true},
        {'side': 'white', 'type': 'tsuki'},
      ];

      final redMarks = BunaiksenHelper.extractMarks(mockEvents, true);
      final whiteMarks = BunaiksenHelper.extractMarks(mockEvents, false);

      expect(redMarks.isEmpty, true, reason: '取り消された技はリストに入らないべき');
      expect(whiteMarks.length, 1);
      expect(whiteMarks[0], '㋡', reason: '取り消し後の有効な最初の技なので丸囲みになるべき');
    });
  });

  group('カテゴリ3: 表示チーム名・選手名抽出ロジックのテスト', () {
    test('個人戦の場合、フォーマットから選手名のみが抽出されること', () {
      // parseName を使用した検証
      final parsed = BunaiksenHelper.parseName('道場A: 剣道太郎');
      expect(parsed['last'], '剣道太郎');
    });

    test('欠員の場合、空文字が返されること', () {
      final parsed = BunaiksenHelper.parseName('欠員');
      expect(parsed['last'], '');
    });
  });

  group('カテゴリ4: リーグ戦勝点（ポイント）計算ロジックのテスト', () {
    test('勝利した場合は勝ち点「3」、引き分けは「1」、敗北は「0」が付与されること', () {
      final mockMatches = [
        MatchModel(id: '1', tournamentId: 'test', order: 1, matchType: 'リーグ', redName: 'Aチーム: 太郎', whiteName: 'Bチーム: 次郎', redScore: 2, whiteScore: 0, status: 'finished', events: []),
        MatchModel(id: '2', tournamentId: 'test', order: 2, matchType: 'リーグ', redName: 'Aチーム: 太郎', whiteName: 'Cチーム: 三郎', redScore: 1, whiteScore: 1, status: 'finished', events: []),
        MatchModel(id: '3', tournamentId: 'test', order: 3, matchType: 'リーグ', redName: 'Aチーム: 太郎', whiteName: 'Dチーム: 四郎', redScore: 0, whiteScore: 1, status: 'finished', events: []),
      ];

      final teamList = ['Aチーム', 'Bチーム', 'Cチーム', 'Dチーム'];

      final pointsA = BunaiksenHelper.calculateCustomLeaguePoints('Aチーム', teamList, mockMatches);
      // 2-0 (勝=3) + 1-1 (分=1) + 0-1 (負=0) = 4ポイント
      expect(pointsA, 4);
    });
  });
}