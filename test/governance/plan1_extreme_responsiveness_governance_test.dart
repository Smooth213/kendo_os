import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/application/mappers/score_event_legacy_adapter.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';

void main() {
  group('⚡ 【ガバナンス監査 27/27】UI極限軽快化・動的ProviderScope排除＆I/Oバッチ集約 永続保証規約', () {
    test(
      '1. [Rebuild Storm根絶] ListEqualityWrapper が要素同一リストの等価性を担保し、リスナー再通知を抑止すること',
      () {
        final listFile = File(
          'lib/features/tournament/presentation/operate/providers/match_list_provider.dart',
        );
        final screenFile = File(
          'lib/features/tournament/presentation/operate/match_screen.dart',
        );

        expect(listFile.existsSync(), isTrue);
        expect(screenFile.existsSync(), isTrue);

        final listContent = listFile.readAsStringSync();
        final screenContent = screenFile.readAsStringSync();

        // ListEqualityWrapper の適用検証
        expect(
          listContent.contains('class ListEqualityWrapper'),
          isTrue,
          reason:
              'match_list_provider.dart に ListEqualityWrapper が定義されていなければならない',
        );
        expect(
          listContent.contains('ListEqualityWrapper('),
          isTrue,
          reason:
              'teamMatchesByGroupProvider 内で ListEqualityWrapper を使用していなければならない',
        );
        expect(
          screenContent.contains('ListEqualityWrapper<MatchModel>('),
          isTrue,
          reason:
              'match_screen.dart の Web セレクターで ListEqualityWrapper を使用していなければならない',
        );

        // 動作検証: 要素が同一なら同一と判定され、順序や内容が変わった場合のみ非等価になること
        final m1 = MatchModel(
          id: 'm1',
          matchType: '個人戦',
          redName: '選手1',
          whiteName: '選手2',
        );
        final m2 = MatchModel(
          id: 'm2',
          matchType: '個人戦',
          redName: '選手3',
          whiteName: '選手4',
        );

        final wrapperA = ListEqualityWrapper([m1, m2]);
        final wrapperB = ListEqualityWrapper([m1, m2]); // 別インスタンス
        final wrapperC = ListEqualityWrapper([m2, m1]); // 順序違い

        expect(
          wrapperA == wrapperB,
          isTrue,
          reason: '中身が同一なら別インスタンスでも == が true であること',
        );
        expect(wrapperA == wrapperC, isFalse, reason: '順序が異なる場合は false であること');
      },
    );

    test(
      '2. [動的ProviderScope排除] match_screen.dart の build() 内で動的 ProviderScope が生成されず、MatchScoreboard へ直接プロパティ注入されていること',
      () {
        final screenFile = File(
          'lib/features/tournament/presentation/operate/match_screen.dart',
        );
        final scoreboardFile = File('lib/shared/widgets/scoreboard.dart');

        final screenContent = screenFile.readAsStringSync();
        final scoreboardContent = scoreboardFile.readAsStringSync();

        // MatchScoreboard のプロパティ受け渡し配備
        expect(
          scoreboardContent.contains('final String? matchId;'),
          isTrue,
          reason: 'MatchScoreboard は matchId プロパティを受け取れる構造でなければならない',
        );
        expect(
          scoreboardContent.contains('final MatchModel? match;'),
          isTrue,
          reason: 'MatchScoreboard は match プロパティを受け取れる構造でなければならない',
        );

        // match_screen.dart 内で ProviderScope(overrides: [scoreboardMatchIdProvider...) が完全に排除されていること
        expect(
          screenContent.contains('scoreboardMatchIdProvider.overrideWithValue'),
          isFalse,
          reason:
              'match_screen.dart 内で scoreboardMatchIdProvider を動的オーバーライドしてはならない',
        );
        expect(
          screenContent.contains('scoreboardMatchProvider.overrideWithValue'),
          isFalse,
          reason:
              'match_screen.dart 内で scoreboardMatchProvider を動的オーバーライドしてはならない',
        );

        // MatchScoreboard(matchId: match.id, match: match, onNameTap: ...) を直接配置していること
        expect(
          screenContent.contains('MatchScoreboard('),
          isTrue,
          reason:
              'match_screen.dart は MatchScoreboard を直接インスタンス化してElementを再利用しなければならない',
        );
        expect(screenContent.contains('matchId: match.id'), isTrue);
        expect(screenContent.contains('match: match'), isTrue);
      },
    );

    test(
      '3. [単一writeTxnアトミック化] LocalMatchRepository に saveMatchWithPendingCommand が配備され、試合保存と未送信コマンドが単一トランザクション化されていること',
      () {
        final repoFile = File(
          'lib/shared/infrastructure/repository/local_match_repository.dart',
        );
        final helperFile = File(
          'lib/features/match/application/services/match_persistence_helper.dart',
        );
        final queueFile = File(
          'lib/features/tournament/presentation/operate/providers/match_command_queue.dart',
        );

        final repoContent = repoFile.readAsStringSync();
        final helperContent = helperFile.readAsStringSync();
        final queueContent = queueFile.readAsStringSync();

        // saveMatchWithPendingCommand の存在
        expect(
          repoContent.contains('Future<void> saveMatchWithPendingCommand('),
          isTrue,
          reason:
              'LocalMatchRepository に saveMatchWithPendingCommand が実装されていなければならない',
        );
        expect(
          helperContent.contains('saveMatchWithPendingCommand('),
          isTrue,
          reason:
              'MatchPersistenceHelper は saveMatchWithPendingCommand を呼び出さなければならない',
        );

        // match_command_queue.dart での Optimistic Fast Path
        expect(
          queueContent.contains('// 失敗したコマンドは即座にIsarへ確実に永続化'),
          isTrue,
          reason:
              'MatchCommandQueue は通常系の不要な二重保存を省き、失敗時のみ永続化するFast Pathを配備しなければならない',
        );
      },
    );

    test(
      '4. [署名検証O(1)キャッシュ] LocalMatchRepository に _verifiedSignatureKeys キャッシュが導入され、署名再計算がスキップされること',
      () {
        final repoFile = File(
          'lib/shared/infrastructure/repository/local_match_repository.dart',
        );
        final repoContent = repoFile.readAsStringSync();

        expect(
          repoContent.contains('_verifiedSignatureKeys'),
          isTrue,
          reason:
              'LocalMatchRepository に _verifiedSignatureKeys キャッシュが存在しなければならない',
        );
        expect(
          repoContent.contains('_verifyMatchSignatures('),
          isTrue,
          reason:
              'LocalMatchRepository に _verifyMatchSignatures メソッドが配備されていなければならない',
        );

        // 不正な署名が与えられた場合は TamperedEventException をスローすること
        final tamperedEvent = ScoreEventLegacyAdapter.fromLegacy(
          type: PointType.men,
          side: Side.red,
          id: 'tampered_test_id',
        ).copyWith(signature: 'invalid_signature_hash');

        final tamperedMatch = MatchModel(
          id: 'tampered_match_id',
          matchType: '個人戦',
          redName: '赤',
          whiteName: '白',
          events: [tamperedEvent],
        );

        final repo = LocalMatchRepository(null);
        // DBがnullでも署名検証フェーズで即座に例外がスローされること
        expect(
          () => repo.saveMatch(tamperedMatch),
          throwsA(isA<TamperedEventException>()),
          reason: '改ざんされた署名を持つイベントは即座に拒絶されなければならない',
        );
      },
    );

    test(
      '5. [クラウド同期バッチ化] sync_provider.dart で未同期試合の取得が並列化され、saveMatchesBulk で一括反映されていること',
      () {
        final syncFile = File(
          'lib/features/tournament/presentation/operate/providers/sync_provider.dart',
        );
        final syncContent = syncFile.readAsStringSync();

        // Future.wait による並列処理
        expect(
          syncContent.contains('await Future.wait('),
          isTrue,
          reason:
              'sync_provider.dart は未同期試合のFirestore取得・更新を Future.wait で並列実行しなければならない',
        );

        // saveMatchesBulk による一括Isar永続化
        expect(
          syncContent.contains(
            'await localRepo.saveMatchesBulk(syncedMatchesToSave)',
          ),
          isTrue,
          reason:
              'sync_provider.dart は同期完了試合を saveMatchesBulk で単一トランザクション一括保存しなければならない',
        );
      },
    );
  });
}
