import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/domain/entities/match_model.dart';
import 'package:kendo_os/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/presentation/operate/providers/match_view_model_provider.dart';
import 'package:kendo_os/presentation/operate/screens/home_screen.dart';

void main() {
  // テスト用のMatchModel生成ヘルパー
  MatchModel createMatch({
    required String id,
    String? tournamentId,
    String? category,
    String? groupName,
    required String redName,
    required String whiteName,
    required String status,
    required double order,
  }) {
    return MatchModel(
      id: id,
      matchType: '個人戦',
      redName: redName,
      whiteName: whiteName,
      status: status,
      order: order,
      tournamentId: tournamentId,
      category: category,
      groupName: groupName,
    );
  }

  group('🛡️ MatchViewModelProvider Tests (UI Projection Logic)', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('1. tournamentMatchesProvider: 特定のtournamentIdの試合のみ抽出し、order順にソートされること', () {
      final m1 = createMatch(id: '1', tournamentId: 't1', redName: 'A', whiteName: 'B', status: 'waiting', order: 200.0);
      final m2 = createMatch(id: '2', tournamentId: 't2', redName: 'C', whiteName: 'D', status: 'waiting', order: 100.0);
      final m3 = createMatch(id: '3', tournamentId: 't1', redName: 'E', whiteName: 'F', status: 'waiting', order: 50.0);

      container = ProviderContainer(overrides: [
        matchListProvider.overrideWith((ref) => [m1, m2, m3]),
      ]);

      final result = container.read(tournamentMatchesProvider('t1'));
      
      expect(result.length, 2, reason: 'tournamentIdが一致する試合のみ抽出されるべき');
      expect(result[0].id, '3', reason: 'orderの昇順でソートされるべき (50.0 < 200.0)');
      expect(result[1].id, '1');
    });

    test('2. activeMatchesProvider: in_progressとwaitingが正しく分類・グループ化されること', () {
      final m1 = createMatch(id: '1', tournamentId: 't1', groupName: 'g1', redName: 'A', whiteName: 'B', status: 'in_progress', order: 10.0);
      final m2 = createMatch(id: '2', tournamentId: 't1', groupName: 'g1', redName: 'C', whiteName: 'D', status: 'waiting', order: 20.0);
      final m3 = createMatch(id: '3', tournamentId: 't1', groupName: null, redName: 'E', whiteName: 'F', status: 'waiting', order: 30.0);
      final m4 = createMatch(id: '4', tournamentId: 't1', groupName: 'g2', redName: 'G', whiteName: 'H', status: 'finished', order: 40.0);

      container = ProviderContainer(overrides: [
        matchListProvider.overrideWith((ref) => [m1, m2, m3, m4]),
      ]);

      final activeMatches = container.read(activeMatchesProvider('t1'));

      expect(activeMatches.inProgress.length, 1, reason: 'グループ内にin_progressが含まれていれば代表として選出される');
      expect(activeMatches.inProgress[0].id, '1'); 

      expect(activeMatches.waiting.length, 1, reason: '単独のwaiting試合が正しく分類される');
      expect(activeMatches.waiting[0].id, '3');
    });

    test('3. timelineMatchesByCategoryProvider: 検索クエリで正しくフィルタリングされること', () {
      final m1 = createMatch(id: '1', tournamentId: 't1', category: '小学生', groupName: 'g1', redName: 'チームA : 太郎', whiteName: 'チームB : 次郎', status: 'waiting', order: 10.0);
      final m2 = createMatch(id: '2', tournamentId: 't1', category: '中学生', groupName: null, redName: 'チームC : 三郎', whiteName: 'チームD : 四郎', status: 'waiting', order: 20.0);

      container = ProviderContainer(overrides: [
        matchListProvider.overrideWith((ref) => [m1, m2]),
      ]);

      // '太郎' で検索
      container.read(searchQueryProvider.notifier).state = '太郎';

      final result = container.read(timelineMatchesByCategoryProvider('t1'));
      
      expect(result.matchedMatchIds.contains('1'), isTrue, reason: '検索キーワードを含む試合IDがマッチリストに追加される');
      expect(result.matchedMatchIds.contains('2'), isFalse);
      
      expect(result.entries.length, 1, reason: 'マッチした試合を含むカテゴリのみが残る');
      expect(result.entries.first.key, '小学生');
    });

    test('4. timelineMatchesByCategoryProvider: 重み付けによるカテゴリソートが機能すること', () {
      final m1 = createMatch(id: '1', tournamentId: 't1', category: '中学生', redName: 'A', whiteName: 'B', status: 'waiting', order: 10.0);
      final m2 = createMatch(id: '2', tournamentId: 't1', category: '小学生1年', redName: 'C', whiteName: 'D', status: 'waiting', order: 20.0);
      final m3 = createMatch(id: '3', tournamentId: 't1', category: '一般', redName: 'E', whiteName: 'F', status: 'waiting', order: 30.0);

      container = ProviderContainer(overrides: [
        matchListProvider.overrideWith((ref) => [m1, m2, m3]),
      ]);

      // 昇順 (デフォルト設定)
      container.read(categorySortProvider.notifier).state = true;
      var resultAsc = container.read(timelineMatchesByCategoryProvider('t1'));
      
      expect(resultAsc.entries[0].key, '小学生1年', reason: '設定されたWeightに基づき、小学生 -> 中学生 -> 一般 の順に並ぶ');
      expect(resultAsc.entries[1].key, '中学生');
      expect(resultAsc.entries[2].key, '一般');

      // 降順
      container.read(categorySortProvider.notifier).state = false;
      var resultDesc = container.read(timelineMatchesByCategoryProvider('t1'));

      expect(resultDesc.entries[0].key, '一般', reason: '降順に切り替えた場合は逆順になる');
      expect(resultDesc.entries[1].key, '中学生');
      expect(resultDesc.entries[2].key, '小学生1年');
    });

    test('5. bunaiksenMatchesProvider: 進行中 -> 待機中 -> 終了済み の優先度でソートされること', () {
      final m1 = createMatch(id: '1', tournamentId: 'b1', redName: 'A', whiteName: 'B', status: 'finished', order: 10.0);
      final m2 = createMatch(id: '2', tournamentId: 'b1', redName: 'C', whiteName: 'D', status: 'in_progress', order: 20.0);
      final m3 = createMatch(id: '3', tournamentId: 'b1', redName: 'E', whiteName: 'F', status: 'waiting', order: 30.0);

      container = ProviderContainer(overrides: [
        matchListProvider.overrideWith((ref) => [m1, m2, m3]),
      ]);

      final result = container.read(bunaiksenMatchesProvider('b1'));

      expect(result.length, 3);
      expect(result[0].id, '2', reason: 'in_progressが最優先で上にくる');
      expect(result[1].id, '3', reason: 'waitingが次点');
      expect(result[2].id, '1', reason: 'finishedが最下部に配置される');
    });
  });
}
