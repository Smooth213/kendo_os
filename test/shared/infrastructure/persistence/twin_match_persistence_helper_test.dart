import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/infrastructure/persistence/twin_match_persistence_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('twin_test_');
    TwinMatchPersistenceHelper.customDirectory = tempDir;
    TwinMatchPersistenceHelper.isWebOverride = false;
  });

  tearDown(() async {
    TwinMatchPersistenceHelper.customDirectory = null;
    TwinMatchPersistenceHelper.isWebOverride = null;
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  group('TwinMatchPersistenceHelper Tests (Native)', () {
    test('Native: スナップショット保存と復元が正常に動作すること', () async {
      final match = MatchModel(
        id: 'test-twin-match-001',
        matchType: 'individual',
        matchOrder: 1,
        redName: '山田',
        whiteName: '佐藤',
        status: 'in_progress',
        redScore: 1,
        whiteScore: 0,
      );

      await TwinMatchPersistenceHelper.saveSnapshot(match);
      final recovered = await TwinMatchPersistenceHelper.recoverMatch(match.id);

      expect(recovered, isNotNull);
      expect(recovered!.id, match.id);
      expect(recovered.redName, '山田');
      expect(recovered.redScore, 1);
    });

    test('Native: 全スナップショットの一括復元が正常に動作すること', () async {
      final match1 = MatchModel(
        id: 'twin-all-1',
        matchType: 'individual',
        redName: '選手A',
        whiteName: '選手B',
      );
      final match2 = MatchModel(
        id: 'twin-all-2',
        matchType: 'individual',
        redName: '選手C',
        whiteName: '選手D',
      );

      await TwinMatchPersistenceHelper.saveSnapshot(match1);
      await TwinMatchPersistenceHelper.saveSnapshot(match2);

      final allRecovered = await TwinMatchPersistenceHelper.recoverAllMatches();
      expect(allRecovered.any((m) => m.id == 'twin-all-1'), isTrue);
      expect(allRecovered.any((m) => m.id == 'twin-all-2'), isTrue);
    });
  });

  group('TwinMatchPersistenceHelper Tests (Web Fallback)', () {
    setUp(() {
      TwinMatchPersistenceHelper.isWebOverride = true;
    });

    test('Web: SharedPreferencesへのスナップショット保存と復元が正常に動作すること', () async {
      final match = MatchModel(
        id: 'test-web-match-001',
        matchType: 'individual',
        redName: 'Web選手赤',
        whiteName: 'Web選手白',
        redScore: 2,
      );

      await TwinMatchPersistenceHelper.saveSnapshot(match);
      final recovered = await TwinMatchPersistenceHelper.recoverMatch(match.id);

      expect(recovered, isNotNull);
      expect(recovered!.id, match.id);
      expect(recovered.redName, 'Web選手赤');
      expect(recovered.redScore, 2);
    });
  });
}
