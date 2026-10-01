import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/errors/emergency_crash_preserver.dart';
import 'package:kendo_os/shared/errors/global_error_handler.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'global_error_handler_test',
    );
    EmergencyCrashPreserver.customDirectory = tempDir;
    EmergencyCrashPreserver.isWebOverride = false;
  });

  tearDown(() async {
    EmergencyCrashPreserver.unregisterActiveMatch('test-match-1');
    await EmergencyCrashPreserver.clearCrashDump();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('[Unit] GlobalErrorHandler 単体テスト', () {
    test('runWithZoneにおいて正常処理が例外なく実行完了すること', () async {
      bool executed = false;
      GlobalErrorHandler.runWithZone(() {
        executed = true;
      });
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(executed, isTrue);
    });

    test('runWithZoneにおいて非同期例外が発生した際にゾーンエラーとして捕捉され緊急退避が実行されること', () async {
      const match = MatchModel(
        id: 'test-match-1',
        matchType: 'individual',
        redName: '選手A',
        whiteName: '選手B',
      );
      EmergencyCrashPreserver.registerActiveMatch(match);

      GlobalErrorHandler.runWithZone(() async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        throw Exception('非同期テスト例外発生');
      });

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final dump = await EmergencyCrashPreserver.loadRecoverableCrashDump();
      expect(dump, isNotNull);
      expect(dump!['match']['id'], 'test-match-1');
      expect(dump['error'].toString(), contains('非同期テスト例外発生'));
    });

    test('FlutterError発生時にハンドラ経由で緊急退避が呼び出されること', () async {
      const match = MatchModel(
        id: 'test-match-1',
        matchType: 'individual',
        redName: '選手A',
        whiteName: '選手B',
      );
      EmergencyCrashPreserver.registerActiveMatch(match);

      GlobalErrorHandler.runWithZone(() {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: Exception('UI描画エラー'),
            stack: StackTrace.current,
          ),
        );
      });

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final dump = await EmergencyCrashPreserver.loadRecoverableCrashDump();
      expect(dump, isNotNull);
      expect(dump!['match']['id'], 'test-match-1');
    });
  });
}
