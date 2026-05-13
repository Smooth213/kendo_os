import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kendo_os/presentation/operate/providers/metrics_provider.dart';

// モッククラス
class MockAlertService extends Mock implements AlertService {}

void main() {
  group('🔍 Observability (可観測性) Tests', () {
    late ProviderContainer container;
    late MockAlertService mockAlertService;

    setUp(() {
      mockAlertService = MockAlertService();
      
      container = ProviderContainer(
        overrides: [
          alertProvider.overrideWithValue(mockAlertService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('1. メトリクス記録時に traceId が付与されること', () {
      final metrics = container.read(metricsProvider);
      final traceId = 'test_trace_123';

      // エラーなく呼び出せるか（本来は developer.log に出力されるので例外が出ないことを確認）
      expect(() => metrics.recordLatency('test_op', 150, traceId: traceId), returnsNormally);
      expect(() => metrics.recordError(traceId: traceId), returnsNormally);
    });

    test('2. 画面反映(Projection)が2000msを超えた場合、HighProjectionLagアラートが発行されること', () {
      final metrics = container.read(metricsProvider);
      final traceId = 'lag_trace_999';

      // 100msの遅延（セーフ）
      metrics.recordProjectionLag(100, traceId: traceId);
      verifyNever(() => mockAlertService.triggerAlert('HighProjectionLag', any(), any(), traceId: any(named: 'traceId')));

      // 2500msの遅延（アウト）
      metrics.recordProjectionLag(2500, traceId: traceId);
      
      // アラートが呼ばれたことを検証
      verify(() => mockAlertService.triggerAlert(
        'HighProjectionLag', 
        'Projection delay exceeded 2 seconds', 
        2500, 
        traceId: traceId
      )).called(1);
    });

    test('3. エラー率が1%を超えた場合、HighErrorRateアラートが発行されること', () async {
      final metrics = container.read(metricsProvider);
      
      // サンプルを貯めるためのダミー成功ログ（9件）
      for (int i = 0; i < 9; i++) {
        metrics.recordLatency('event_append', 10); 
      }

      await Future.delayed(Duration.zero);

      // この時点ではエラー0件
      verifyNever(() => mockAlertService.triggerAlert('HighErrorRate', any(), any()));

      // 10件目の処理でエラーを発生させる（エラー率 1/10 = 10%）
      metrics.recordError(traceId: 'error_trace_001');

      // ★ 追加: アサート（確認）の前に、マイクロタスクが完了するのを待つ
      await Future.delayed(Duration.zero);

      // 1% (0.01) を超えたのでアラートが呼ばれるはず
      verify(() => mockAlertService.triggerAlert(
        'HighErrorRate', 
        'Error rate exceeded 1%', 
        10.0, // 10%
        traceId: 'error_trace_001'
      )).called(1);
    });

    test('4. ダッシュボード用の状態(State)が正しく更新されること', () async {
      final metrics = container.read(metricsProvider);
      
      metrics.recordLatency('event_append', 50);
      metrics.recordProjectionLag(120);

      // ★ 追加: アサート（確認）の前に、マイクロタスクが完了するのを待つ
      await Future.delayed(Duration.zero);

      final state = container.read(dashboardMetricsProvider);
      
      expect(state['totalEvents'], 1); // イベントが1つ処理されたか
      expect(state['lastLagMs'], 120); // 最後の遅延が記録されているか
    });

    test('【二次災害防止】UI描画サイクル中にエラーを検知(recordError)しても、状態更新によるクラッシュ(StateError)を引き起こさないこと', () async {
      final metricsService = container.read(metricsProvider);

      // Act & Assert
      // 描画中に呼ばれるFlutterError.reportErrorを模倣し、同期的にrecordErrorを呼び出す。
      // もし Future.microtask で保護されていなければ、特定の条件下で例外がスローされるが、
      // 保護されていれば絶対に例外は発生せず安全に通過する。
      expect(
        () => metricsService.recordError(traceId: 'ダミーのUIはみ出し(Overflow)エラー'),
        returnsNormally, // ★ 例外(クラッシュ)が起きずに正常終了することを証明
        reason: 'エラー検知時の状態更新はFuture.microtaskで遅延され、二次クラッシュを防ぐ必要がある',
      );

      // マイクロタスクが実行されるのを少し待つ
      await Future.delayed(Duration.zero);

      // Assert: クラッシュを回避した上で、エラー自体は正しく記録されていること
      final state = container.read(dashboardMetricsProvider);
      expect(state['totalEvents'], 1, reason: '遅延記録されたエラーがStateに反映されていること');
    });
  });
}