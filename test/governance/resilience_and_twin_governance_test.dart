import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/application/mappers/score_event_legacy_adapter.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🛡️ 【第17条 ガバナンス監査】ツインエンジン自己修復・現場障害耐性 ＆ 完全耐障害性規約', () {
    test('Rule 1: [ツイン永続化＆自己修復] TwinMatchPersistenceHelper 統合 ＆ 非同期I/O規約', () {
      final repoFile = File(
        'lib/shared/infrastructure/repository/local_match_repository.dart',
      );
      expect(repoFile.existsSync(), isTrue);
      final repoContent = repoFile.readAsStringSync();

      expect(repoContent.contains('TwinMatchPersistenceHelper'), isTrue);
      expect(repoContent.contains('Self-Healing'), isTrue);

      final twinFile = File(
        'lib/shared/infrastructure/persistence/twin_match_persistence_helper.dart',
      );
      expect(twinFile.existsSync(), isTrue);
      final twinContent = twinFile.readAsStringSync();

      expect(twinContent.contains('listSync('), isFalse);
      expect(twinContent.contains('deleteSync('), isFalse);
      expect(twinContent.contains('readAsStringSync('), isFalse);
    });

    test('Rule 2: [スナップショット軽量化] ドキュメント内スナップショット保持上限(1件)規約', () {
      final helperFile = File(
        'lib/features/match/application/services/match_snapshot_helper.dart',
      );
      expect(helperFile.existsSync(), isTrue);
      expect(
        helperFile.readAsStringSync().contains('this.maxSnapshots = 1'),
        isTrue,
      );

      final serviceFile = File(
        'lib/features/tournament/presentation/operate/providers/match_snapshot_service.dart',
      );
      expect(serviceFile.existsSync(), isTrue);
      final serviceContent = serviceFile.readAsStringSync();
      expect(serviceContent.contains('newSnapshots.length > 1'), isTrue);
      expect(serviceContent.contains('newSnapshots.length > 20'), isFalse);
    });

    test(
      'Rule 3: [Fatal Crash Trap] 未捕捉例外発生時に直前状態を退避する EmergencyCrashPreserver 配備規約',
      () {
        final preserverFile = File(
          'lib/shared/errors/emergency_crash_preserver.dart',
        );
        expect(preserverFile.existsSync(), isTrue);
        final preserverContent = preserverFile.readAsStringSync();
        expect(preserverContent.contains('preserveOnCrash'), isTrue);
        expect(preserverContent.contains('loadRecoverableCrashDump'), isTrue);

        final handlerFile = File('lib/shared/errors/global_error_handler.dart');
        expect(handlerFile.existsSync(), isTrue);
        expect(
          handlerFile.readAsStringSync().contains(
            'EmergencyCrashPreserver.preserveOnCrash',
          ),
          isTrue,
        );
      },
    );

    test('Rule 4: [データ消失ゼロ暗号フォールバック] saveMatchSafeMode 不正署名隔離退避規約', () async {
      final repoFile = File(
        'lib/shared/infrastructure/repository/local_match_repository.dart',
      );
      expect(repoFile.existsSync(), isTrue);
      final content = repoFile.readAsStringSync();

      expect(content.contains('saveMatchSafeMode'), isTrue);
      expect(content.contains('saveMatchesBulkSafeMode'), isTrue);
      expect(content.contains('[QUARANTINE_TAMPERED]'), isTrue);

      final tamperedEvent = ScoreEventLegacyAdapter.fromLegacy(
        type: PointType.men,
        side: Side.red,
        id: 'tampered_event_safe_test',
      ).copyWith(signature: 'invalid_tampered_signature');

      final tamperedMatch = MatchModel(
        id: 'tampered_match_safe_test',
        matchType: '個人戦',
        redName: '赤選手',
        whiteName: '白選手',
        events: [tamperedEvent],
      );

      final repo = LocalMatchRepository(null);

      expect(
        () => repo.saveMatch(tamperedMatch),
        throwsA(isA<TamperedEventException>()),
      );

      await expectLater(repo.saveMatchSafeMode(tamperedMatch), completes);
    });

    test(
      'Rule 5: [署名検証O(1)キャッシュ] LocalMatchRepository に _verifiedSignatureKeys キャッシュ配備規約',
      () {
        final repoFile = File(
          'lib/shared/infrastructure/repository/local_match_repository.dart',
        );
        expect(repoFile.existsSync(), isTrue);
        final repoContent = repoFile.readAsStringSync();

        expect(repoContent.contains('_verifiedSignatureKeys'), isTrue);
        expect(repoContent.contains('_verifyMatchSignatures('), isTrue);
      },
    );

    test('Rule 6: [完全べき等キューイング] match_command_queue.dart に重複UUIDコマンド排除配備規約', () {
      final queueFile = File(
        'lib/features/tournament/presentation/operate/providers/match_command_queue.dart',
      );
      expect(queueFile.existsSync(), isTrue);
      final content = queueFile.readAsStringSync();

      expect(content.contains('_processedCommandIds'), isTrue);
      expect(content.contains('Idempotent'), isTrue);
      expect(content.contains('backoffMs'), isTrue);
    });

    test(
      'Rule 7: [物理的誤操作ガード] match_screen.dart に PopScope が配備され、試合中の離脱ガードが行われること',
      () {
        final screenFile = File(
          'lib/features/tournament/presentation/operate/match_screen.dart',
        );
        expect(screenFile.existsSync(), isTrue);
        final content = screenFile.readAsStringSync();

        expect(content.contains('PopScope('), isTrue);
        expect(content.contains('canPop: isMatchFinished'), isTrue);
        expect(
          content.contains('EmergencyCrashPreserver.registerActiveMatch'),
          isTrue,
        );
      },
    );

    test(
      'Rule 8: [フォントオフライン耐性] app_startup.dart に enforceOfflineFontFallback が配備されていること',
      () {
        final file = File('lib/bootstrap/app_startup.dart');
        expect(file.existsSync(), isTrue);
        final content = file.readAsStringSync();

        expect(content.contains('enforceOfflineFontFallback()'), isTrue);
        expect(
          content.contains('GoogleFonts.config.allowRuntimeFetching = false'),
          isTrue,
        );
      },
    );
  });
}
