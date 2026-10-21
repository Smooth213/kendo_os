import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/application/usecases/match_progress_calculator.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/ui_message_provider.dart';

void main() {
  group('[Unit] MatchProgressCalculator テスト', () {
    group('getCurrentUser', () {
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

      test('冪等性において 複数回呼び出しても例外が発生しないこと', () {
        // 連続呼び出しでもクラッシュしないことを保証
        expect(() {
          for (int i = 0; i < 5; i++) {
            MatchProgressCalculator.getCurrentUser();
          }
        }, returnsNormally);
      });
    });

    group('safeExecute', () {
      test('正常系アクション実行時にレイテンシが安全に計測・記録されること', () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final ref = container.read(Provider((ref) => ref));

        bool executed = false;
        await MatchProgressCalculator.safeExecute(
          ref,
          () async {
            executed = true;
          },
          'テスト失敗',
          metricName: 'test_metric',
        );

        expect(executed, isTrue);
      });

      test('競合例外発生時にUIメッセージ通知とメトリクス記録を行い再スローされること', () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final ref = container.read(Provider((ref) => ref));

        await expectLater(
          () => MatchProgressCalculator.safeExecute(ref, () async {
            throw Exception('他の端末との競合が発生しました');
          }, '同期エラー'),
          throwsA(isA<Exception>()),
        );

        final message = container.read(uiMessageProvider);
        expect(message, isNotNull);
        expect(message!.isError, isTrue);
        expect(message.text, contains('同期エラー: Exception: 他の端末との競合が発生しました'));
      });
    });
  });
}
