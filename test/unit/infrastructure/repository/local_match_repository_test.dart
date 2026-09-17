@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';

import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/shared/infrastructure/persistence/models/match_entity.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import '../../../helpers/test_isar_helper.dart';

void main() {
  group('LocalMatchRepository (Isar Database) Tests', () {
    late TestIsarContext isarContext;
    late Isar isar;
    late LocalMatchRepository repository;

    setUpAll(() async {
      isarContext = await TestIsarHelper.openContext(
        schemas: [
          MatchEntitySchema,
          MatchEventArchiveEntitySchema,
          MatchCommandEntitySchema,
        ],
        prefix: 'isar_repo_test',
      );
      isar = isarContext.isar;
      repository = LocalMatchRepository(isar);
    });

    tearDownAll(() async {
      await isarContext.dispose();
    });

    setUp(() async {
      await isarContext.clear();
    });

    // =========================================================================
    // テストケース
    // =========================================================================
    test('saveMatch: MatchModelをIsarデータベースに正常に保存できること', () async {
      // Given: 保存するためのモックデータを作成
      final match = const MatchModel(
        id: 'repo_test_1',
        tournamentId: 'test_tournament',
        matchType: '個人戦',
        redName: '赤太郎',
        whiteName: '白次郎',
        status: 'in_progress',
      );

      // When: リポジトリを経由して保存を実行
      await repository.saveMatchSafeMode(match);

      // Then: 保存されたデータをストリームから取得して検証
      final stream = repository.watchMatches();
      final savedMatches = await stream.first;

      expect(savedMatches.length, 1, reason: 'データベースに1件の試合が保存されているべき');
      expect(savedMatches.first.id, 'repo_test_1');
      expect(savedMatches.first.redName, '赤太郎');
      expect(savedMatches.first.status, 'in_progress');
    });

    test('saveMatch (Update): 既存の試合データを上書き更新できること', () async {
      // Given: 初期データを保存
      final initialMatch = const MatchModel(
        id: 'repo_test_2',
        matchType: '先鋒',
        redScore: 0,
        redName: '赤選手', // 追加
        whiteScore: 0,
        whiteName: '白選手', // 追加
      );
      await repository.saveMatch(initialMatch);

      // When: スコアが更新された同IDのデータを再度保存（上書き）
      final updatedMatch = initialMatch.copyWith(redScore: 1);
      await repository.saveMatch(updatedMatch);

      // Then: データが重複せず、1件のまま内容が更新されていることを検証
      final stream = repository.watchMatches();
      final savedMatches = await stream.first;

      expect(savedMatches.length, 1, reason: '同IDで保存した場合は新規追加ではなく上書きされるべき');
      expect(savedMatches.first.redScore, 1, reason: 'スコアの更新が正しく反映されているべき');
    });

    test('長期運用: 201件以上のイベントを分離保存し、全履歴を復元できること', () async {
      final events = List.generate(
        450,
        (index) => ScoreEvent(
          id: 'long_event_$index',
          side: Side.red,
          timestamp: DateTime.fromMillisecondsSinceEpoch(index),
          sequence: index,
        ),
      );
      final match = MatchModel(
        id: 'long_running_match',
        tournamentId: 'long_tournament',
        matchType: '個人戦',
        redName: '赤',
        whiteName: '白',
        events: events,
      );

      await repository.saveMatchSafeMode(match);

      final entity = await isar.matchEntitys
          .filter()
          .firestoreIdEqualTo(match.id)
          .findFirst();
      final archives = await isar.matchEventArchiveEntitys
          .filter()
          .matchIdEqualTo(match.id)
          .findAll();
      final restored = await repository.getMatch(match.id);

      expect(entity?.events.length, 200);
      expect(archives.length, 2);
      expect(restored?.events.length, events.length);
      expect(
        restored?.events.map((event) => event.id),
        orderedEquals(events.map((event) => event.id)),
      );
    });

    test(
      'deletePendingCommandsForMatches: 指定された試合IDの保留コマンドのみが正確に削除されること',
      () async {
        // Given: 保留コマンドをいくつか登録
        final cmd1 = MatchCommandEntity()
          ..commandId = 'cmd_1'
          ..type = 'saveMatch'
          ..payloadJson = '{"id":"match_target","redName":"赤"}'
          ..createdAt = DateTime.now()
          ..status = 'pending';

        final cmd2 = MatchCommandEntity()
          ..commandId = 'cmd_2'
          ..type = 'saveMatch'
          ..payloadJson = '{"id":"match_other","redName":"白"}'
          ..createdAt = DateTime.now()
          ..status = 'pending';

        final cmd3 = MatchCommandEntity()
          ..commandId = 'cmd_3'
          ..type = 'saveMatch'
          ..payloadJson = '{"id":"match_target","redName":"赤2"}'
          ..createdAt = DateTime.now()
          ..status = 'done'; // 既に完了しているもの

        await isar.writeTxn(() async {
          await isar.matchCommandEntitys.putAll([cmd1, cmd2, cmd3]);
        });

        // When: match_target の保留コマンドを削除
        await repository.deletePendingCommandsForMatch('match_target');

        // Then: match_targetの保留コマンドのみが削除され、他や完了済みは残る
        final remaining = await isar.matchCommandEntitys.where().findAll();
        expect(remaining.length, 2);
        expect(remaining.any((c) => c.commandId == 'cmd_1'), isFalse);
        expect(remaining.any((c) => c.commandId == 'cmd_2'), isTrue);
        expect(remaining.any((c) => c.commandId == 'cmd_3'), isTrue);
      },
    );
  });
}
