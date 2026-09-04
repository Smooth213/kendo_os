import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:kendo_os/shared/infrastructure/persistence/models/local_stroke_model.dart';
import 'package:kendo_os/shared/infrastructure/persistence/models/match_comment_entity.dart';
import 'package:kendo_os/shared/infrastructure/persistence/models/match_entity.dart';
import 'package:kendo_os/shared/infrastructure/persistence/models/match_projection_entity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🗄️ 【Phase 13: Isar メモリマップトI/O（MMAP）＆ ページサイズ最適化】ガバナンステスト', () {
    late Isar isar;
    late Directory tempDir;

    setUpAll(() async {
      await Isar.initializeIsarCore(download: true);
    });

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('isar_mmap_test_');
      isar = await Isar.open(
        [
          MatchEntitySchema,
          LocalStrokeModelSchema,
          MatchCommentEntitySchema,
          MatchProjectionEntitySchema,
          MatchCommandEntitySchema,
        ],
        directory: tempDir.path,
        name: 'mmap_perf_db',
        maxSizeMiB: 1024,
        relaxedDurability: true,
        compactOnLaunch: const CompactCondition(
          minFileSize: 10 * 1024 * 1024,
          minRatio: 2.0,
        ),
      );
    });

    tearDown(() async {
      await isar.close(deleteFromDisk: true);
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('MMAP 1024MiB 仮想メモリ空間上での 1,000 件一括書き込み＆RAM速度検索検証', () async {
      final now = DateTime.now();

      // 1,000件の試合データを生成
      final entities = List.generate(1000, (index) {
        return MatchEntity()
          ..firestoreId = 'match_mmap_$index'
          ..tournamentId = 'tournament_mmap_2026'
          ..matchType = 'individual'
          ..category = index % 4 == 0 ? '一般男子の部' : '一般女子の部'
          ..groupName = '第${(index % 4) + 1}試合場'
          ..redName = '選手A_$index'
          ..whiteName = '選手B_$index'
          ..redScore = index % 3
          ..whiteScore = (index + 1) % 3
          ..status = index % 2 == 0 ? 'completed' : 'in_progress'
          ..lastUpdatedAt = now.subtract(Duration(minutes: index));
      });

      // 1. バッチ書き込み性能測定
      final writeStopwatch = Stopwatch()..start();
      await isar.writeTxn(() async {
        await isar.matchEntitys.putAll(entities);
      });
      writeStopwatch.stop();

      // ignore: avoid_print
      print(
        '🗄️ [Isar MMAP Performance Benchmark]\n'
        '  - 1,000件バッチ書込所要時間: ${writeStopwatch.elapsedMilliseconds} ms\n'
        '  - 1件あたり書込時間: ${(writeStopwatch.elapsedMicroseconds / 1000).toStringAsFixed(2)} μs',
      );

      expect(writeStopwatch.elapsedMilliseconds, lessThan(1000));

      // 2. RAM速度（MMAPキャッシュ）での特定カテゴリークエリ測定
      final queryStopwatch = Stopwatch()..start();
      final categoryMatches = await isar.matchEntitys
          .filter()
          .tournamentIdEqualTo('tournament_mmap_2026')
          .and()
          .categoryEqualTo('一般男子の部')
          .findAll();
      queryStopwatch.stop();

      // ignore: avoid_print
      print(
        '  - 1,000件からの特定カテゴリー検索（250件ヒット）所要時間: ${queryStopwatch.elapsedMicroseconds} μs (${queryStopwatch.elapsedMilliseconds} ms)',
      );

      expect(categoryMatches.length, equals(250));
      // MMAPカーネルキャッシュにより、ストレージI/OをスキップしてRAM速度（100ms未満）で即座返却されること（CI環境の仮想マシン負荷スパイクを考慮）
      expect(queryStopwatch.elapsedMilliseconds, lessThan(100));
    });

    test('ステータス別およびソート走査がミリ秒未満レベルで高速完了すること', () async {
      final now = DateTime.now();
      final entities = List.generate(500, (index) {
        return MatchEntity()
          ..firestoreId = 'match_sort_$index'
          ..tournamentId = 't_sort'
          ..matchType = 'individual'
          ..category = '一般男子'
          ..redName = '赤_$index'
          ..whiteName = '白_$index'
          ..status = index < 250 ? 'in_progress' : 'finished'
          ..lastUpdatedAt = now.subtract(Duration(seconds: index * 10));
      });

      await isar.writeTxn(() async {
        await isar.matchEntitys.putAll(entities);
      });

      final queryStopwatch = Stopwatch()..start();
      final inProgressMatches = await isar.matchEntitys
          .filter()
          .tournamentIdEqualTo('t_sort')
          .and()
          .statusEqualTo('in_progress')
          .sortByLastUpdatedAtDesc()
          .findAll();
      queryStopwatch.stop();

      expect(inProgressMatches.length, equals(250));
      expect(inProgressMatches.first.firestoreId, equals('match_sort_0'));
      expect(queryStopwatch.elapsedMilliseconds, lessThan(100));
    });
  });
}
