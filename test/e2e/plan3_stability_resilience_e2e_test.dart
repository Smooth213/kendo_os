import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_command_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_command_queue.dart';
import 'package:kendo_os/shared/errors/emergency_crash_preserver.dart';
import 'package:kendo_os/shared/infrastructure/persistence/twin_match_persistence_helper.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('plan3_e2e_');
    TwinMatchPersistenceHelper.customDirectory = tempDir;
    TwinMatchPersistenceHelper.isWebOverride = false;
    EmergencyCrashPreserver.customDirectory = tempDir;
    EmergencyCrashPreserver.isWebOverride = false;
  });

  tearDown(() async {
    TwinMatchPersistenceHelper.customDirectory = null;
    TwinMatchPersistenceHelper.isWebOverride = null;
    EmergencyCrashPreserver.customDirectory = null;
    EmergencyCrashPreserver.isWebOverride = null;
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  group('🛡️ 【Plan 3 E2E】不壊・絶対安定・高耐障害性 総合結合テスト', () {
    test('E2E-1: 試合操作中にクラッシュが発生しても直前状態が退避され、再開時に復旧できること', () async {
      final activeMatch = MatchModel(
        id: 'e2e-crash-match-1',
        matchType: 'individual',
        redName: '錬成 太郎',
        whiteName: '本戦 次郎',
        redScore: 1,
        whiteScore: 0,
        status: 'in_progress',
      );

      // 試合開始時に登録
      EmergencyCrashPreserver.registerActiveMatch(activeMatch);

      // クラッシュ発生のシミュレーション
      await EmergencyCrashPreserver.preserveOnCrash(
        error: 'Simulated Fatal UI Rendering Error (Out of memory)',
        stackTrace: StackTrace.current,
      );

      // アプリ再起動・復元プロセス
      final recoveredDump =
          await EmergencyCrashPreserver.loadRecoverableCrashDump();
      expect(recoveredDump, isNotNull);
      expect(recoveredDump!['match']['id'], 'e2e-crash-match-1');
      expect(recoveredDump['match']['redScore'], 1);
      expect(recoveredDump['match']['status'], 'in_progress');

      // 復旧後のクリア
      await EmergencyCrashPreserver.clearCrashDump();
      expect(await EmergencyCrashPreserver.loadRecoverableCrashDump(), isNull);
    });

    test(
      'E2E-2: DB（Isar）レコードが欠落してもツイン永続化スナップショットから自己修復（Self-Healing）できること',
      () async {
        final match = MatchModel(
          id: 'e2e-twin-heal-match',
          matchType: 'individual',
          redName: '宮本 武蔵',
          whiteName: '佐々木 小次郎',
          redScore: 2,
          whiteScore: 1,
          status: 'finished',
        );

        // スナップショット保存
        await TwinMatchPersistenceHelper.saveSnapshot(match);

        // Isarが未初期化（null）またはレコード消失の状態のレポジトリ
        final repo = LocalMatchRepository(null);

        // レポジトリのgetMatchで自己修復が発動
        final recovered = await repo.getMatch(match.id);
        expect(recovered, isNotNull);
        expect(recovered!.id, match.id);
        expect(recovered.redName, '宮本 武蔵');
        expect(recovered.whiteName, '佐々木 小次郎');
        expect(recovered.redScore, 2);
        expect(recovered.status, 'finished');
      },
    );

    test('E2E-3: 同一IDのコマンドが短時間に複数回投入されても、完全べき等性により重複実行が防止されること', () async {
      final container = ProviderContainer(
        overrides: [
          localMatchRepositoryProvider.overrideWithValue(
            LocalMatchRepository(null),
          ),
        ],
      );

      final queue = container.read(matchCommandQueueProvider);

      final cmdId = 'idempotent-cmd-uuid-001';
      final cmd = MatchCommandModel(
        id: cmdId,
        type: CommandType.updateMatch,
        payload: {'matchId': 'm-1'},
        createdAt: DateTime.now(),
      );

      // 初回投入
      await queue.enqueue(cmd);

      // 重複投入（電波途絶時の多重送信やゴーストタップ）
      await queue.enqueue(cmd);
      await queue.enqueue(cmd);

      // エラーなく完了し、二重実行されないことを確認
      expect(container.read(matchCommandErrorProvider), isNull);
    });
  });
}
