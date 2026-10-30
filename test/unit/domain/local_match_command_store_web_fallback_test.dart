import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_command_provider.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_command_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Unit] LocalMatchCommandStore Web/SharedPreferences フォールバック結合テスト', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test(
      '単体コマンド保存＆取得に関して、isar=null (Web環境) でも SharedPreferences に保存され復元できること',
      () async {
        final cmd = MatchCommandModel(
          id: 'cmd-web-001',
          type: CommandType.addScore,
          payload: {'id': 'match-101', 'pointType': 'men', 'target': 'red'},
          createdAt: DateTime(2026, 9, 25, 12, 0, 0),
          status: CommandStatus.pending,
        );

        // Web環境 (isar: null) で保存
        await LocalMatchCommandStore.savePendingCommand(null, cmd);

        // Web環境 (isar: null) で取得
        final retrieved = await LocalMatchCommandStore.getPendingCommands(null);
        expect(retrieved.length, equals(1));
        expect(retrieved.first.id, equals('cmd-web-001'));
        expect(retrieved.first.type, equals(CommandType.addScore));
        expect(retrieved.first.payload['id'], equals('match-101'));
        expect(retrieved.first.payload['pointType'], equals('men'));
        expect(retrieved.first.status, equals(CommandStatus.pending));
      },
    );

    test('バルク保存＆作成日時昇順ソートに関して、複数コマンドが正しく時系列順に保持されること', () async {
      final cmd1 = MatchCommandModel(
        id: 'cmd-web-002',
        type: CommandType.addScore,
        payload: {'id': 'match-101', 'pointType': 'kote'},
        createdAt: DateTime(2026, 9, 25, 12, 1, 0),
        status: CommandStatus.pending,
      );
      final cmd2 = MatchCommandModel(
        id: 'cmd-web-001',
        type: CommandType.updateMatch,
        payload: {'id': 'match-101'},
        createdAt: DateTime(2026, 9, 25, 12, 0, 0),
        status: CommandStatus.pending,
      );

      // 逆順で一括保存
      await LocalMatchCommandStore.savePendingCommandsBulk(null, [cmd1, cmd2]);

      final retrieved = await LocalMatchCommandStore.getPendingCommands(null);
      expect(retrieved.length, equals(2));
      // 時系列順 (cmd2 -> cmd1)
      expect(retrieved[0].id, equals('cmd-web-001'));
      expect(retrieved[1].id, equals('cmd-web-002'));
    });

    test('個別コマンド削除に関して、完了したコマンドが確実にストレージから消去されること', () async {
      final cmd1 = MatchCommandModel(
        id: 'cmd-del-001',
        type: CommandType.addScore,
        payload: {'id': 'match-201'},
        createdAt: DateTime(2026, 9, 25, 12, 0, 0),
        status: CommandStatus.pending,
      );
      final cmd2 = MatchCommandModel(
        id: 'cmd-del-002',
        type: CommandType.addScore,
        payload: {'id': 'match-201'},
        createdAt: DateTime(2026, 9, 25, 12, 0, 10),
        status: CommandStatus.pending,
      );

      await LocalMatchCommandStore.savePendingCommandsBulk(null, [cmd1, cmd2]);
      expect(
        (await LocalMatchCommandStore.getPendingCommands(null)).length,
        equals(2),
      );

      // cmd1 を削除
      await LocalMatchCommandStore.deleteCommand(null, 'cmd-del-001');

      final remaining = await LocalMatchCommandStore.getPendingCommands(null);
      expect(remaining.length, equals(1));
      expect(remaining.first.id, equals('cmd-del-002'));
    });

    test('試合単位一括削除に関して、指定された試合IDに属する未送信コマンドが一括消去されること', () async {
      final cmdMatchA1 = MatchCommandModel(
        id: 'cmd-a-1',
        type: CommandType.addScore,
        payload: {'id': 'match-AAA'},
        createdAt: DateTime(2026, 9, 25, 12, 0, 0),
        status: CommandStatus.pending,
      );
      final cmdMatchA2 = MatchCommandModel(
        id: 'cmd-a-2',
        type: CommandType.undoLastEvent,
        payload: {'id': 'match-AAA'},
        createdAt: DateTime(2026, 9, 25, 12, 1, 0),
        status: CommandStatus.pending,
      );
      final cmdMatchB = MatchCommandModel(
        id: 'cmd-b-1',
        type: CommandType.addScore,
        payload: {'id': 'match-BBB'},
        createdAt: DateTime(2026, 9, 25, 12, 2, 0),
        status: CommandStatus.pending,
      );

      await LocalMatchCommandStore.savePendingCommandsBulk(null, [
        cmdMatchA1,
        cmdMatchA2,
        cmdMatchB,
      ]);
      expect(
        (await LocalMatchCommandStore.getPendingCommands(null)).length,
        equals(3),
      );

      // match-AAA のコマンドを一括削除
      await LocalMatchCommandStore.deletePendingCommandsForMatches(null, [
        'match-AAA',
      ]);

      final remaining = await LocalMatchCommandStore.getPendingCommands(null);
      expect(remaining.length, equals(1));
      expect(remaining.first.id, equals('cmd-b-1'));
    });

    test(
      'ストレージ直接永続化検証に関して、SharedPreferencesのキーを直接確認し、JSON配列として保存されていること',
      () async {
        final cmd = MatchCommandModel(
          id: 'cmd-json-check',
          type: CommandType.approveMatch,
          payload: {'id': 'match-999'},
          createdAt: DateTime(2026, 9, 25, 15, 0, 0),
          status: CommandStatus.pending,
        );

        await LocalMatchCommandStore.savePendingCommand(null, cmd);

        final prefs = await SharedPreferences.getInstance();
        final rawJson = prefs.getString('kendo_os_pending_commands_queue');
        expect(rawJson, isNotNull);
        expect(rawJson!.contains('cmd-json-check'), isTrue);
        expect(rawJson.contains('approveMatch'), isTrue);
        expect(rawJson.contains('match-999'), isTrue);
      },
    );

    test('ストレージ破損耐性に関して、不正なJSONデータが混入していてもクラッシュせず空リストへ安全フォールバックすること', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'kendo_os_pending_commands_queue',
        '{{MALFORMED_CORRUPTED_JSON_DATA}}',
      );

      final result = await LocalMatchCommandStore.getPendingCommands(null);
      expect(result, isNotNull);
      expect(result, isEmpty);
    });

    test(
      'アプリ再起動復旧シナリオに関して、SharedPreferencesに事前永続化された未送信キューが起動時に作成日時順で完全復元されること',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final preExistingJson =
            '[{"id":"restart-cmd-2","type":"addScore","payload":{"id":"m1"},"createdAt":"2026-10-30T10:05:00.000","status":"pending"},'
            '{"id":"restart-cmd-1","type":"updateMatch","payload":{"id":"m1"},"createdAt":"2026-10-30T10:00:00.000","status":"pending"},'
            '{"id":"restart-cmd-3","type":"undoLastEvent","payload":{"id":"m1"},"createdAt":"2026-10-30T10:02:00.000","status":"done"}]';

        await prefs.setString(
          'kendo_os_pending_commands_queue',
          preExistingJson,
        );

        final restored = await LocalMatchCommandStore.getPendingCommands(null);
        expect(restored.length, equals(2));
        expect(restored[0].id, equals('restart-cmd-1'));
        expect(restored[1].id, equals('restart-cmd-2'));
        expect(restored.any((c) => c.id == 'restart-cmd-3'), isFalse);
      },
    );
  });
}
