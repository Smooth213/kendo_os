import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_command_provider.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_command_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🌐 LocalMatchCommandStore Web/SharedPreferences フォールバック結合テスト', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test(
      '1. [単体コマンド保存＆取得] isar=null (Web環境) でも SharedPreferences に保存され復元できること',
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

    test('2. [バルク保存＆作成日時昇順ソート] 複数コマンドが正しく時系列順に保持されること', () async {
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

    test('3. [個別コマンド削除] 完了したコマンドが確実にストレージから消去されること', () async {
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

    test('4. [試合単位一括削除] 指定された試合IDに属する未送信コマンドが一括消去されること', () async {
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
      '5. [ストレージ直接永続化検証] SharedPreferencesのキーを直接確認し、JSON配列として保存されていること',
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
  });
}
