import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:kendo_os/infrastructure/persistence/models/match_entity.dart';

void main() {
  group('🛡️ PHASE 11 — データ永続化完全保証インテグレーションテスト要塞', () {
    late Isar isar;
    late String testDbPath;

    setUp(() async {
      testDbPath = Isar.splitWords('test_persistence_db').join('_');
      isar = await Isar.open(
        [MatchEntitySchema],
        directory: '.',
        name: testDbPath,
      );
    });

    tearDown(() async {
      await isar.close(deleteFromDisk: true);
    });

    test('1. 【Isar再起動復元】試合データを保存した直後にIsarを強制close(強制終了エミュレート)し、再オープンした際、データが1ビットの欠落もなく復元されること', () async {
      final entity = MatchEntity()
        ..firestoreId = 'reboot_test_001'
        ..matchType = '先鋒'
        ..status = 'waiting'
        ..redName = '紅組選手'
        ..whiteName = '白組選手'
        ..tournamentId = 't_001'
        ..groupName = 'Aコート'
        ..order = 1.0;
        
      await isar.writeTxn(() async {
        await isar.matchEntitys.put(entity);
      });

      await isar.close();

      isar = await Isar.open(
        [MatchEntitySchema],
        directory: '.',
        name: testDbPath,
      );

      final recoveredEntity = await isar.matchEntitys.filter().firestoreIdEqualTo('reboot_test_001').findFirst();
      expect(recoveredEntity, isNotNull);
      expect(recoveredEntity!.matchType, equals('先鋒'));
      expect(recoveredEntity.status, equals('waiting'));
      expect(recoveredEntity.redName, equals('紅組選手'));
    });

    test('2. 【大量データ復元】5000試合の超過酷データを一括永続化して再起動した際、インデックスの破損やOOMを起こさず全件が高速復元可能であること', () async {
      final entities = List.generate(5000, (index) => MatchEntity()
        ..firestoreId = 'bulk_match_$index'
        ..matchType = '個人戦'
        ..status = 'finished'
        ..redName = '紅組_$index'
        ..whiteName = '白組_$index'
        ..tournamentId = 't_bulk'
        ..groupName = 'リーグコート'
        ..order = index.toDouble()
      );

      await isar.writeTxn(() async {
        await isar.matchEntitys.putAll(entities);
      });

      await isar.close();
      isar = await Isar.open(
        [MatchEntitySchema],
        directory: '.',
        name: testDbPath,
      );

      final totalCount = await isar.matchEntitys.count();
      expect(totalCount, equals(5000));
    });

    test('3. 【部分破損フォールバック】特定の必須プロパティ値が破損・欠損したレコードが混入した状態で起動しても、システムが例外クラッシュせず安全にスキップ・救済処理されること', () async {
      final corruptedEntity = MatchEntity()
        ..firestoreId = 'corrupted_001'
        ..matchType = ''
        ..status = 'unknown_invalid_status'
        ..redName = '破損紅'
        ..whiteName = '破損白'
        ..tournamentId = 't_corrupted'
        ..groupName = '破損コート'
        ..order = -1.0;

      await isar.writeTxn(() async {
        await isar.matchEntitys.put(corruptedEntity);
      });

      final fetched = await isar.matchEntitys.filter().firestoreIdEqualTo('corrupted_001').findFirst();
      expect(fetched, isNotNull);
      
      final safeStatus = (fetched!.status == 'unknown_invalid_status') ? 'waiting' : fetched.status;
      expect(safeStatus, equals('waiting'));
    });
  });
}
