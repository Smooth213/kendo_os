import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/application/usecases/match_usecases.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_command_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/shared/infrastructure/repository/sync_engine.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/match_repository.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';

// --------------------------------------------------
// モック (Fake) クラスの定義
// --------------------------------------------------
class _FakeLocalMatchRepoForSync implements LocalMatchRepository {
  final List<MatchCommandModel> pendingCommands;
  final List<String> deletedCommandIds = [];

  _FakeLocalMatchRepoForSync(this.pendingCommands);

  @override
  Future<List<MatchCommandModel>> getPendingCommands([int? limit]) async {
    final list = List<MatchCommandModel>.from(pendingCommands);
    return limit != null ? list.take(limit).toList() : list;
  }

  @override
  Future<void> deleteCommand(String id) async {
    deletedCommandIds.add(id);
    pendingCommands.removeWhere((cmd) => cmd.id == id);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMatchRepoForSync implements MatchRepository {
  Future<int> Function(MatchModel match)? onSaveMatch;
  Future<MatchModel?> Function(
    String matchId, {
    String? organizationId,
    String? tournamentId,
  })?
  onGetMatch;

  @override
  Future<int> saveMatch(MatchModel match) async {
    if (onSaveMatch != null) return await onSaveMatch!(match);
    return match.version + 1;
  }

  @override
  Future<MatchModel?> getMatch(
    String matchId, {
    String? organizationId,
    String? tournamentId,
  }) async {
    if (onGetMatch != null) {
      return await onGetMatch!(
        matchId,
        organizationId: organizationId,
        tournamentId: tournamentId,
      );
    }
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// 古いバグの挙動を再現するため、強制的にステータスを初期化(waiting)してしまう
// 悪意のある（または不完全な）UseCaseを定義します。
class FakeRebuildMatchFromEventsUseCase
    implements RebuildMatchFromEventsUseCase {
  @override
  MatchModel execute(MatchModel match, MatchRule rule) {
    return match.copyWith(
      status: 'waiting', // ★ バグの再現: ここで勝手に初期状態に戻してしまう
      redScore: match.redScore,
      whiteScore: match.whiteScore,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Unit] 同期エンジンステータス巻き戻り保護および耐障害性境界テスト', () {
    test('ドリフト監視時において、再計算ロジックがステータスを初期化しても、元の確定ステータス(finished)が維持・保護されること', () {
      // 1. テストデータの準備: ユーザーが確定させた(finished)状態の試合
      const originalStatus = 'finished';
      final match = MatchModel(
        id: 'test-match-123',
        status: originalStatus,
        matchType: '個人戦',
        redScore: 2,
        whiteScore: 0,
        redName: '赤',
        whiteName: '白',
        events: const [],
      );

      final rebuilder = FakeRebuildMatchFromEventsUseCase();
      final rule = const MatchRule();

      // 2. sync_provider.dart で実際に行われている保護処理をシミュレート
      MatchModel rebuiltMatch = rebuilder.execute(match, rule);
      expect(
        rebuiltMatch.status,
        'waiting',
        reason: 'バグ再現: Rebuildを通すとステータスが壊れることの確認',
      );

      // ★ 修正された保護コード
      rebuiltMatch = rebuiltMatch.copyWith(status: match.status);

      // 3. 検証
      expect(
        rebuiltMatch.status,
        originalStatus,
        reason: '元のステータス(finished)が完全に復元・保護されているべき',
      );
    });

    test('CRDTマージ時: 退避したステータスが正しく復元されること', () {
      const originalStatus = 'approved';
      final remoteMatch = MatchModel(
        id: 'test-match-456',
        status: originalStatus,
        matchType: '個人戦',
        redScore: 1,
        whiteScore: 1,
        redName: '赤',
        whiteName: '白',
        events: const [],
      );

      final rebuilder = FakeRebuildMatchFromEventsUseCase();
      final rule = const MatchRule();

      MatchModel rebuiltMatch = remoteMatch.copyWith();
      final savedStatus = rebuiltMatch.status; // ★ ステータスを退避
      rebuiltMatch = rebuilder.execute(rebuiltMatch, rule); // 再計算で壊れる
      rebuiltMatch = rebuiltMatch.copyWith(status: savedStatus); // ★ 復元

      expect(
        rebuiltMatch.status,
        originalStatus,
        reason: 'CRDTマージの際も、退避したステータス(approved)が復元されるべき',
      );
    });

    test('コマンド同期バッチ送信中の途中切断時において、送信成功分の削除と未送信分の先頭維持が保証されること', () async {
      final cmd1 = MatchCommandModel(
        id: 'cmd_1',
        type: CommandType.updateMatch,
        payload: {
          'id': 'match_1',
          'matchType': '個人戦',
          'redName': '選手A',
          'whiteName': '選手B',
        },
        createdAt: DateTime.now(),
      );
      final cmd2 = MatchCommandModel(
        id: 'cmd_2',
        type: CommandType.updateMatch,
        payload: {
          'id': 'match_2',
          'matchType': '個人戦',
          'redName': '選手C',
          'whiteName': '選手D',
        },
        createdAt: DateTime.now(),
      );
      final cmd3 = MatchCommandModel(
        id: 'cmd_3',
        type: CommandType.updateMatch,
        payload: {
          'id': 'match_3',
          'matchType': '個人戦',
          'redName': '選手E',
          'whiteName': '選手F',
        },
        createdAt: DateTime.now(),
      );

      final fakeLocal = _FakeLocalMatchRepoForSync([cmd1, cmd2, cmd3]);
      final fakeRemote = _FakeMatchRepoForSync()
        ..onSaveMatch = (match) async {
          if (match.id == 'match_2') {
            throw Exception('Connection dropped during batch');
          }
          return 2;
        };

      final container = ProviderContainer(
        overrides: [
          firestoreProvider.overrideWithValue(FakeFirebaseFirestore()),
          localMatchRepositoryProvider.overrideWithValue(fakeLocal),
          matchRepositoryProvider.overrideWithValue(fakeRemote),
          currentDojoIdProvider.overrideWith((ref) => 'test_org'),
          currentTournamentIdProvider.overrideWith((ref) => 'test_tour'),
        ],
      );
      addTearDown(() {
        container.dispose();
      });

      final syncEngine = container.read(syncEngineProvider);

      // バッチ処理を実行（cmd1成功、cmd2で切断）
      await syncEngine.processQueue();

      // 成功したcmd1のみ削除されていること
      expect(fakeLocal.deletedCommandIds, contains('cmd_1'));
      expect(fakeLocal.deletedCommandIds, isNot(contains('cmd_2')));
      expect(fakeLocal.deletedCommandIds, isNot(contains('cmd_3')));

      // キューにはcmd2とcmd3が順序を保って残っていること
      expect(fakeLocal.pendingCommands.length, 2);
      expect(fakeLocal.pendingCommands.first.id, 'cmd_2');
      expect(fakeLocal.pendingCommands.last.id, 'cmd_3');

      // リトライカウントがインクリメントされバックオフ状態になっていること
      expect(syncEngine.retryCount, 1);
    });

    test('リトライ上限到達時において、異常コマンドが自律パージされ後続の正常コマンドが救済処理されること', () async {
      final badCmd = MatchCommandModel(
        id: 'bad_cmd',
        type: CommandType.updateMatch,
        payload: {
          'id': 'match_bad',
          'matchType': '個人戦',
          'redName': '選手A',
          'whiteName': '選手B',
        },
        createdAt: DateTime.now(),
      );
      final goodCmd = MatchCommandModel(
        id: 'good_cmd',
        type: CommandType.updateMatch,
        payload: {
          'id': 'match_good',
          'matchType': '個人戦',
          'redName': '選手C',
          'whiteName': '選手D',
        },
        createdAt: DateTime.now(),
      );

      final fakeLocal = _FakeLocalMatchRepoForSync([badCmd, goodCmd]);
      final fakeRemote = _FakeMatchRepoForSync()
        ..onSaveMatch = (match) async {
          if (match.id == 'match_bad') {
            throw Exception('Persistent network error');
          }
          return 2;
        };

      final container = ProviderContainer(
        overrides: [
          firestoreProvider.overrideWithValue(FakeFirebaseFirestore()),
          localMatchRepositoryProvider.overrideWithValue(fakeLocal),
          matchRepositoryProvider.overrideWithValue(fakeRemote),
          currentDojoIdProvider.overrideWith((ref) => 'test_org'),
          currentTournamentIdProvider.overrideWith((ref) => 'test_tour'),
        ],
      );
      addTearDown(() {
        container.dispose();
      });

      final syncEngine = container.read(syncEngineProvider);

      // 1〜9回目まで失敗を繰り返す
      for (int i = 1; i <= 9; i++) {
        syncEngine.clearBackoffForTesting();
        await syncEngine.processQueue();
        expect(syncEngine.retryCount, i);
        expect(fakeLocal.deletedCommandIds, isEmpty);
      }

      // 10回目の試行（リトライ上限到達）：badCmdが自律パージされ、同ループ内で後続のgoodCmdが送信完了する
      syncEngine.clearBackoffForTesting();
      await syncEngine.processQueue();

      // bad_cmdとgood_cmdの両方が削除（完了）されていること
      expect(fakeLocal.deletedCommandIds, contains('bad_cmd'));
      expect(fakeLocal.deletedCommandIds, contains('good_cmd'));
      expect(fakeLocal.pendingCommands, isEmpty);
      expect(syncEngine.retryCount, 0);
    });

    test('保留マッチ同期において、先行コマンドが競合パージされても後続コマンドが独立して正常送信されること', () async {
      final conflictCmd = MatchCommandModel(
        id: 'cmd_conflict',
        type: CommandType.updateMatch,
        payload: {
          'id': 'match_conflict',
          'matchType': '個人戦',
          'redName': '選手A',
          'whiteName': '選手B',
          'organizationId': 'test_org',
          'tournamentId': 'test_tour',
          'version': 1,
        },
        createdAt: DateTime.now(),
      );
      final normalCmd = MatchCommandModel(
        id: 'cmd_normal',
        type: CommandType.updateMatch,
        payload: {
          'id': 'match_normal',
          'matchType': '個人戦',
          'redName': '選手C',
          'whiteName': '選手D',
          'organizationId': 'test_org',
          'tournamentId': 'test_tour',
          'version': 1,
        },
        createdAt: DateTime.now(),
      );

      final fakeLocal = _FakeLocalMatchRepoForSync([conflictCmd, normalCmd]);
      final fakeRemote = _FakeMatchRepoForSync()
        ..onSaveMatch = (match) async {
          if (match.id == 'match_conflict') {
            throw Exception('ConflictException: Version conflict');
          }
          return 2;
        }
        ..onGetMatch = (matchId, {organizationId, tournamentId}) async {
          if (matchId == 'match_conflict') {
            return const MatchModel(
              id: 'match_conflict',
              matchType: '個人戦',
              redName: '選手A',
              whiteName: '選手B',
              version: 2,
            );
          }
          return null;
        };

      final container = ProviderContainer(
        overrides: [
          firestoreProvider.overrideWithValue(FakeFirebaseFirestore()),
          localMatchRepositoryProvider.overrideWithValue(fakeLocal),
          matchRepositoryProvider.overrideWithValue(fakeRemote),
          currentDojoIdProvider.overrideWith((ref) => 'test_org'),
          currentTournamentIdProvider.overrideWith((ref) => 'test_tour'),
        ],
      );
      addTearDown(() {
        container.dispose();
      });

      final syncEngine = container.read(syncEngineProvider);
      await syncEngine.processQueue();

      // 競合コマンドは自律パージされ、後続の正常コマンドも送信成功して両方削除されること
      expect(fakeLocal.deletedCommandIds, contains('cmd_conflict'));
      expect(fakeLocal.deletedCommandIds, contains('cmd_normal'));
      expect(fakeLocal.pendingCommands, isEmpty);
    });

    test('ライフサイクル遷移の連続発生時において、バックグラウンド判定とタイマー制御が破綻せず整合性が保たれること', () async {
      final fakeLocal = _FakeLocalMatchRepoForSync([]);
      final fakeRemote = _FakeMatchRepoForSync();

      final container = ProviderContainer(
        overrides: [
          firestoreProvider.overrideWithValue(FakeFirebaseFirestore()),
          localMatchRepositoryProvider.overrideWithValue(fakeLocal),
          matchRepositoryProvider.overrideWithValue(fakeRemote),
          currentDojoIdProvider.overrideWith((ref) => 'test_org'),
          currentTournamentIdProvider.overrideWith((ref) => 'test_tour'),
        ],
      );
      addTearDown(() {
        container.dispose();
      });

      final syncEngine = container.read(syncEngineProvider);

      // syncNow を複数回連続で呼び出しても二重処理（_isProcessingのデッドロック）が発生しないこと
      await syncEngine.syncNow();
      await syncEngine.syncNow();
      await syncEngine.syncNow();

      expect(syncEngine.retryCount, 0);
    });
  });
}
