import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/sync_downstream_helper.dart';

class _FakeLocalMatchRepo implements LocalMatchRepository {
  final List<MatchModel> currentMatches;
  final List<MatchModel> savedMatches = [];
  final List<String> deletedMatchIds = [];

  _FakeLocalMatchRepo(this.currentMatches);

  @override
  Stream<List<MatchModel>> watchAllLocalMatches() {
    return Stream.value(currentMatches);
  }

  @override
  Future<void> saveMatchesBulk(
    List<MatchModel> matches, {
    bool skipTwin = false,
  }) async {
    savedMatches.addAll(matches);
  }

  @override
  Future<void> deleteMatch(String id) async {
    deletedMatchIds.add(id);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('[Unit] オフラインダーティ保護およびリモート同期上書き防止単体テスト', () {
    test('ローカルで未送信変更がある試合はリモートデータによる上書きが防止されること', () async {
      final dirtyLocalMatch = MatchModel(
        id: 'm-dirty-1',
        tournamentId: 't-1',
        matchType: '個人戦',
        redName: '地元選手',
        whiteName: '遠征選手',
        status: 'ongoing',
        syncState: SyncState.localOnly,
      );

      final cleanLocalMatch = MatchModel(
        id: 'm-clean-2',
        tournamentId: 't-1',
        matchType: '個人戦',
        redName: '選手A',
        whiteName: '選手B',
        status: 'pending',
        syncState: SyncState.synced,
      );

      final repo = _FakeLocalMatchRepo([dirtyLocalMatch, cleanLocalMatch]);

      // リモートからの更新データ（dirtyな試合も上書きしようとする）
      final remoteMatches = [
        dirtyLocalMatch.copyWith(redName: 'リモート上書き選手'),
        cleanLocalMatch.copyWith(status: 'ongoing'),
      ];

      await SyncDownstreamHelper.applyRemoteMatches(
        localRepo: repo,
        remoteMatches: remoteMatches,
        tournamentId: 't-1',
      );

      // dirtyLocalMatchはsafeMatchesから除外され、cleanLocalMatchのみが保存される
      expect(repo.savedMatches.length, 1);
      expect(repo.savedMatches.first.id, 'm-clean-2');
      expect(repo.savedMatches.first.status, 'ongoing');
    });

    test('リモートで削除された試合であってもローカルダーティ状態であれば削除が防止されること', () async {
      final dirtyLocalMatch = MatchModel(
        id: 'm-dirty-del',
        tournamentId: 't-1',
        matchType: '個人戦',
        redName: '保護対象選手',
        whiteName: '対戦相手',
        status: 'finished',
        syncState: SyncState.localOnly,
      );

      final cleanLocalMatch = MatchModel(
        id: 'm-clean-del',
        tournamentId: 't-1',
        matchType: '個人戦',
        redName: '削除対象選手',
        whiteName: '対戦相手',
        status: 'finished',
        syncState: SyncState.synced,
      );

      final repo = _FakeLocalMatchRepo([dirtyLocalMatch, cleanLocalMatch]);

      // リモートで両方が削除されたと通知された場合
      await SyncDownstreamHelper.applyRemoteMatches(
        localRepo: repo,
        remoteMatches: const [],
        tournamentId: 't-1',
        removedIds: {'m-dirty-del', 'm-clean-del'},
      );

      // cleanな試合のみ削除され、dirtyな試合は保護される
      expect(repo.deletedMatchIds.contains('m-clean-del'), isTrue);
      expect(repo.deletedMatchIds.contains('m-dirty-del'), isFalse);
    });
  });
}
