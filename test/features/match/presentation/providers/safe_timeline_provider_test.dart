import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_timeline_list.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';

void main() {
  // テスト用のダミー試合データ
  final testMatch1 = MatchModel(
    id: 'match1',
    tournamentId: 'test_tournament',
    category: '一般の部',
    groupName: 'Aリーグ',
    redName: 'Aチーム : 選手A',
    whiteName: 'Bチーム : 選手B',
    order: 1.0,
    matchType: '団体戦',
    status: 'waiting',
    note: '',
  );

  final testMatch2 = MatchModel(
    id: 'match2',
    tournamentId: 'test_tournament',
    category: '一般の部',
    groupName: 'Aリーグ',
    redName: 'Cチーム : 選手C',
    whiteName: 'Dチーム : 選手D',
    order: 2.0,
    matchType: '団体戦',
    status: 'waiting',
    note: '',
  );

  final testMatch3 = MatchModel(
    id: 'match3',
    tournamentId: 'test_tournament',
    category: '女子の部',
    groupName: 'Bトーナメント',
    redName: 'Eチーム : 選手E',
    whiteName: 'Fチーム : 選手F',
    order: 3.0,
    matchType: '団体戦',
    status: 'waiting',
    note: '',
  );

  // テスト環境のプロバイダコンテナを作成するヘルパー
  ProviderContainer createContainer({List<Override> overrides = const []}) {
    final container = ProviderContainer(
      overrides: [isarProvider.overrideWithValue(null), ...overrides],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('safeTimelineProvider Tests', () {
    test('全試合がカテゴリごとに正しくグループ化されること', () async {
      final container = createContainer(
        overrides: [
          matchListProvider.overrideWith(
            (ref) => [testMatch1, testMatch2, testMatch3],
          ),
          matchListByTournamentProvider.overrideWith(
            (ref, id) => Stream.value([testMatch1, testMatch2, testMatch3]),
          ),
        ],
      );

      // autoDispose & StreamProvider が即時破棄・空振りしないようにリスナーを登録
      container.listen(safeTimelineProvider('test_tournament'), (_, _) {});

      // Providerの評価を待つ
      await Future.delayed(const Duration(milliseconds: 200));
      final result = container.read(safeTimelineProvider('test_tournament'));

      expect(result.isLoading, false);
      expect(result.hasError, false);

      // カテゴリは2つ（一般の部、女子の部）
      expect(result.entries.length, 2);

      final cats = result.entries.map((e) => e.key).toList();
      expect(cats, contains('一般の部'));
      expect(cats, contains('女子の部'));

      // 「一般の部」には2つの試合が含まれていること
      final ippanMatches = result.entries
          .firstWhere((e) => e.key == '一般の部')
          .value;
      expect(ippanMatches.length, 2);
      expect(ippanMatches.map((m) => m.id), containsAll(['match1', 'match2']));
    });

    test('検索クエリに合致する試合・グループのみが抽出されること', () async {
      final container = createContainer(
        overrides: [
          matchListProvider.overrideWith(
            (ref) => [testMatch1, testMatch2, testMatch3],
          ),
          matchListByTournamentProvider.overrideWith(
            (ref, id) => Stream.value([testMatch1, testMatch2, testMatch3]),
          ),
          searchQueryProvider.overrideWith((ref) => 'Aチーム'),
        ],
      );

      container.listen(safeTimelineProvider('test_tournament'), (_, _) {});

      await Future.delayed(const Duration(milliseconds: 200));
      final result = container.read(safeTimelineProvider('test_tournament'));

      // Aチームが含まれるのは一般の部のみ
      expect(result.entries.length, 1);
      expect(result.entries.first.key, '一般の部');

      // Aチームに合致したのは match1 だが、groupNameが 'Aリーグ' なので
      // 同じグループの match2 も一緒に抽出される仕様になっているかを検証
      expect(result.matchedGroupNames, contains('Aリーグ'));
      expect(result.matchedMatchIds, contains('match1'));
      expect(result.entries.first.value.length, 2);
    });

    test('カテゴリのソート（昇順・降順）が切り替わること', () async {
      final container = createContainer(
        overrides: [
          matchListProvider.overrideWith((ref) => [testMatch1, testMatch3]),
          matchListByTournamentProvider.overrideWith(
            (ref, id) => Stream.value([testMatch1, testMatch3]),
          ),
          categorySortProvider.overrideWith((ref) => false), // false = 降順
        ],
      );

      container.listen(safeTimelineProvider('test_tournament'), (_, _) {});

      await Future.delayed(const Duration(milliseconds: 200));
      final resultDesc = container.read(
        safeTimelineProvider('test_tournament'),
      );
      final keysDesc = resultDesc.entries.map((e) => e.key).toList();

      // 降順ソートの検証
      final sortedKeysDesc = List<String>.from(keysDesc)
        ..sort((a, b) => b.compareTo(a));
      expect(keysDesc, sortedKeysDesc);

      // 昇順に変更
      container.read(categorySortProvider.notifier).state = true;
      await Future.delayed(const Duration(milliseconds: 200));
      final resultAsc = container.read(safeTimelineProvider('test_tournament'));
      final keysAsc = resultAsc.entries.map((e) => e.key).toList();

      // 昇順ソートの検証
      final sortedKeysAsc = List<String>.from(keysAsc)
        ..sort((a, b) => a.compareTo(b));
      expect(keysAsc, sortedKeysAsc);
    });

    test('データ取得エラー時(ネイティブ環境では空リスト)に安全に状態を反映すること', () async {
      final container = createContainer(
        overrides: [
          matchListProvider.overrideWith((ref) => []),
          matchListByTournamentProvider.overrideWith(
            (ref, id) => Stream.error(Exception('Network Error')),
          ),
        ],
      );

      container.listen(safeTimelineProvider('test_tournament'), (_, _) {});

      await Future.delayed(const Duration(milliseconds: 200));
      final result = container.read(safeTimelineProvider('test_tournament'));

      // ネイティブ環境(テスト実行環境)ではmatchListProviderの空リストが返るためエラーにはならない
      expect(result.hasError, false);
      expect(result.entries, isEmpty);
    });
  });
}
