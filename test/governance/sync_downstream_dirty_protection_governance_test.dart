import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/sync_downstream_helper.dart';

class _FakeRepo implements LocalMatchRepository {
  final List<MatchModel> matches;
  final List<MatchModel> saved = [];

  _FakeRepo(this.matches);

  @override
  Stream<List<MatchModel>> watchAllLocalMatches() => Stream.value(matches);

  @override
  Future<void> saveMatchesBulk(
    List<MatchModel> m, {
    bool skipTwin = false,
  }) async {
    saved.addAll(m);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('[Governance] オフラインダーティ保護およびリモート同期上書き防止保証規約', () {
    test('未送信データを持つ試合がリモートデータによって上書きされないこと', () async {
      final dirtyMatch = MatchModel(
        id: 'gov-dirty-1',
        tournamentId: 't-1',
        matchType: '個人戦',
        redName: '端末A',
        whiteName: '端末B',
        syncState: SyncState.localOnly,
      );

      final repo = _FakeRepo([dirtyMatch]);

      await SyncDownstreamHelper.applyRemoteMatches(
        localRepo: repo,
        remoteMatches: [dirtyMatch.copyWith(redName: 'クラウド上書き名')],
        tournamentId: 't-1',
      );

      // 上書き保存リストに含まれていないこと
      expect(repo.saved, isEmpty);
    });

    test('静的解析においてSyncDownstreamHelperがダーティ保護判定を行っていること', () {
      final file = File(
        'lib/shared/infrastructure/repository/sync_downstream_helper.dart',
      );
      expect(file.existsSync(), isTrue);

      final content = file.readAsStringSync();
      expect(content.contains('!local.isDirty'), isTrue);
    });
  });
}
