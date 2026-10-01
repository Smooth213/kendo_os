import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('[Governance] イベントソーシングリポジトリ50件スナップショットおよび競合オートリペア保証規約', () {
    test('MatchAggregateRepository実装において50イベントごとの自動スナップショット生成契機が存在すること', () {
      final file = File(
        'lib/shared/infrastructure/repository/match_aggregate_repository.dart',
      );
      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();

      expect(content.contains('newEvents.length % 50 == 0'), isTrue);
      expect(content.contains('snapshotStore.save'), isTrue);
    });

    test('MatchAggregateRepository実装において最大3回の楽観的ロック競合オートリペアループが存在すること', () {
      final file = File(
        'lib/shared/infrastructure/repository/match_aggregate_repository.dart',
      );
      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();

      expect(content.contains('attempts < 3'), isTrue);
      expect(content.contains('on ConcurrencyException'), isTrue);
      expect(content.contains('attempts >= 3'), isTrue);
      expect(content.contains('rethrow'), isTrue);
    });
  });
}
