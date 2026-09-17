@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/infrastructure/persistence/models/match_entity.dart';
import 'test_isar_helper.dart';

void main() {
  group('🛡️ TestIsarHelper 単体テスト', () {
    test('オープン、クリア、および安全な破棄が正常に行われること', () async {
      final context = await TestIsarHelper.openContext(
        schemas: [
          MatchEntitySchema,
          MatchEventArchiveEntitySchema,
          MatchCommandEntitySchema,
        ],
        prefix: 'test_helper_verify',
      );

      expect(context.isar.isOpen, isTrue);
      expect(context.directory.existsSync(), isTrue);

      // 書き込みとクリアの検証
      final testEntity = MatchCommandEntity()
        ..commandId = 'cmd_test_1'
        ..type = 'testType'
        ..payloadJson = '{}'
        ..createdAt = DateTime.now()
        ..status = 'pending';
      await context.isar.writeTxn(() async {
        await context.isar.matchCommandEntitys.put(testEntity);
      });

      final count = await context.isar.matchCommandEntitys.count();
      expect(count, 1);

      await context.clear();
      final countAfterClear = await context.isar.matchCommandEntitys.count();
      expect(countAfterClear, 0);

      // 破棄の検証
      await context.dispose();
      expect(context.isar.isOpen, isFalse);
      expect(context.directory.existsSync(), isFalse);

      // 二重disposeでも例外が発生しないこと
      await expectLater(context.dispose(), completes);
    });
  });
}
