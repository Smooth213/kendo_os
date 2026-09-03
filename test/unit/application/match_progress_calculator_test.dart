import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/application/usecases/match_progress_calculator.dart';

void main() {
  group('MatchProgressCalculator.getCurrentUser', () {
    test('Firebase未初期化またはオフライン環境でも安全にUserが返ること', () {
      // Firebase未初期化状態でもクラッシュせず、フォールバック値が返ることを確認
      final user = MatchProgressCalculator.getCurrentUser();

      // Firebaseが初期化されていないため 'test_user' または 'unknown_user' にフォールバックする
      expect(user.id, isNotEmpty);
      expect(
        ['test_user', 'unknown_user'].contains(user.id),
        isTrue,
        reason: 'Firebase未初期化時は test_user か unknown_user にフォールバックすること',
      );
    });

    test('返されたUserオブジェクトが適切なorganizationIdを持つこと', () {
      final user = MatchProgressCalculator.getCurrentUser();

      expect(user.organizationId, equals('default_org'));
    });

    test('返されたUserオブジェクトのidが空文字でないこと', () {
      final user = MatchProgressCalculator.getCurrentUser();

      expect(user.id, isNotEmpty);
      expect(user.id.length, greaterThan(0));
    });

    test('複数回呼び出しても例外が発生しないこと（冪等性）', () {
      // 連続呼び出しでもクラッシュしないことを保証
      expect(() {
        for (int i = 0; i < 5; i++) {
          MatchProgressCalculator.getCurrentUser();
        }
      }, returnsNormally);
    });
  });
}
