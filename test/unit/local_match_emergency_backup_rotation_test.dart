import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/infrastructure/persistence/twin_match_persistence_helper.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_emergency_backup.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('[Unit] ローカル試合緊急バックアップローテーション 単体テスト', () {
    late Directory tempDir;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      tempDir = await Directory.systemTemp.createTemp('kendo_backup_test_');
      TwinMatchPersistenceHelper.customDirectory = tempDir;
      TwinMatchPersistenceHelper.isWebOverride = false;
    });

    tearDown(() async {
      TwinMatchPersistenceHelper.customDirectory = null;
      TwinMatchPersistenceHelper.isWebOverride = null;
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test(
      '3世代ローテーション削除において 4世代以上のバックアップ作成時に古い世代が自動削除され最新3世代のみ保持されること',
      () async {
        const matchId = 'rot-match-001';
        final baseMatch = const MatchModel(
          id: matchId,
          matchType: '個人戦',
          redName: '選手赤',
          whiteName: '選手白',
        );

        // 4世代分のバックアップを順次保存
        for (int i = 1; i <= 4; i++) {
          final match = baseMatch.copyWith(redScore: i, status: 'in_progress');
          await saveEmergencyBackupWithRotation(match);
          await Future.delayed(const Duration(milliseconds: 20));
        }

        final files = tempDir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.contains('twin_snapshot_${matchId}_'))
            .toList();

        // ローテーションにより最大3世代に保たれていること
        expect(files.length, lessThanOrEqualTo(3));
      },
    );

    test('Twinスナップショット同時保存において 緊急退避実行時に最新スナップショットが即時保存され復元可能であること', () async {
      const matchId = 'snap-match-002';
      final match = const MatchModel(
        id: matchId,
        matchType: '個人戦',
        redName: '選手赤',
        whiteName: '選手白',
        redScore: 2,
        whiteScore: 1,
        status: 'finished',
      );

      await saveEmergencyBackupWithRotation(match);

      final recovered = await TwinMatchPersistenceHelper.recoverMatch(matchId);
      expect(recovered, isNotNull);
      expect(recovered!.id, matchId);
      expect(recovered.redScore, 2);
      expect(recovered.whiteScore, 1);
      expect(recovered.status, 'finished');
    });

    test(
      'Web環境安全フォールバックにおいて Web環境シミュレーション時にファイル操作例外を発生させず安全に退避されること',
      () async {
        TwinMatchPersistenceHelper.isWebOverride = true;
        const matchId = 'web-match-003';
        final match = const MatchModel(
          id: matchId,
          matchType: '個人戦',
          redName: '選手赤',
          whiteName: '選手白',
          redScore: 1,
        );

        await expectLater(saveEmergencyBackupWithRotation(match), completes);

        final recovered = await TwinMatchPersistenceHelper.recoverMatch(
          matchId,
        );
        expect(recovered, isNotNull);
        expect(recovered!.id, matchId);
        expect(recovered.redScore, 1);
      },
    );
  });
}
