import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/errors/emergency_crash_preserver.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('preserver_test_');
    EmergencyCrashPreserver.customDirectory = tempDir;
    EmergencyCrashPreserver.isWebOverride = false;
  });

  tearDown(() async {
    EmergencyCrashPreserver.customDirectory = null;
    EmergencyCrashPreserver.isWebOverride = null;
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  group('EmergencyCrashPreserver Tests', () {
    test('アクティブ試合が登録されている場合、クラッシュ退避と復旧が正常に行われること', () async {
      final match = MatchModel(
        id: 'crash-test-match-999',
        matchType: 'individual',
        redName: '選手赤',
        whiteName: '選手白',
        redScore: 1,
        whiteScore: 0,
        status: 'in_progress',
      );

      EmergencyCrashPreserver.registerActiveMatch(match);
      expect(EmergencyCrashPreserver.activeMatch?.id, match.id);

      await EmergencyCrashPreserver.preserveOnCrash(
        error: 'Simulated OutOfMemory or Exception',
        stackTrace: StackTrace.current,
      );

      final dump = await EmergencyCrashPreserver.loadRecoverableCrashDump();
      expect(dump, isNotNull);
      expect(dump!['error'], contains('Simulated OutOfMemory'));
      expect(dump['match']['id'], match.id);
      expect(dump['match']['redName'], '選手赤');

      await EmergencyCrashPreserver.clearCrashDump();
      final dumpAfterClear =
          await EmergencyCrashPreserver.loadRecoverableCrashDump();
      expect(dumpAfterClear, isNull);
    });

    test('アクティブ試合が登録解除された後は退避が行われないこと', () async {
      final match = MatchModel(
        id: 'crash-test-match-888',
        matchType: 'individual',
        redName: 'A',
        whiteName: 'B',
      );

      EmergencyCrashPreserver.registerActiveMatch(match);
      EmergencyCrashPreserver.unregisterActiveMatch(match.id);
      expect(EmergencyCrashPreserver.activeMatch, isNull);

      await EmergencyCrashPreserver.preserveOnCrash(error: 'Some error');
      final dump = await EmergencyCrashPreserver.loadRecoverableCrashDump();
      expect(dump, isNull);
    });
  });
}
