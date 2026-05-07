import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:collection';

// ==========================================
// ★ Phase 2-Step 4: アラート設定（AlertService）
// ==========================================
final alertProvider = Provider<AlertService>((ref) => AlertService());

class AlertService {
  void triggerAlert(String name, String reason, num value, {String? traceId}) {
    final alertData = {
      'alert': name,
      'reason': reason,
      'value': value,
      'traceId': ?traceId,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'level': 'CRITICAL',
    };
    developer.log(jsonEncode(alertData), name: 'KendoOS.Alert', level: 1000);
  }
}

// ==========================================
// ★ Phase 2-Step 5: ダッシュボード用の状態管理を追加
// ==========================================
final dashboardMetricsProvider = StateProvider<Map<String, dynamic>>((ref) => {
  'totalEvents': 0,
  'errorRate': 0.0,
  'conflictRate': 0.0,
  'lastLagMs': 0,
});

final metricsProvider = Provider<MetricsService>((ref) {
  return MetricsService(ref.read(alertProvider), ref); // ★ 修正: refを渡して状態を更新できるようにする
});

class MetricsService {
  final AlertService _alertService;
  final Ref _ref; // ★ 追加
  MetricsService(this._alertService, this._ref);

  final Queue<String> _recentOperations = Queue<String>();
  static const int _windowSize = 100;
  int _totalEvents = 0; // ★ 追加

  void _recordOperationResult(String result, {String? traceId}) {
    _totalEvents++;
    _recentOperations.addLast(result);
    if (_recentOperations.length > _windowSize) {
      _recentOperations.removeFirst();
    }
    _evaluateAlerts(traceId: traceId);
  }

  void recordLatency(String operationName, int latencyMs, {String? traceId}) {
    _emitMetric('${operationName}_count', 1, 'count', traceId: traceId);
    _emitMetric('${operationName}_latency_ms', latencyMs, 'histogram', traceId: traceId);
    
    if (operationName == 'event_append' || operationName == 'event_undo') {
      _recordOperationResult('success', traceId: traceId);
    }
  }

  void recordError({String? traceId}) {
    _emitMetric('system_error_count', 1, 'count', traceId: traceId);
    _recordOperationResult('error', traceId: traceId);
  }

  void recordConcurrencyConflict({String? traceId}) {
    _emitMetric('concurrency_conflict_count', 1, 'count', traceId: traceId);
    _recordOperationResult('conflict', traceId: traceId);
  }

  void recordProjectionLag(int lagMs, {String? traceId}) {
    _emitMetric('projection_lag_ms', lagMs, 'histogram', traceId: traceId);
    
    // ★ ダッシュボード用状態更新
    _ref.read(dashboardMetricsProvider.notifier).update((state) => {
      ...state,
      'lastLagMs': lagMs,
    });

    if (lagMs > 2000) {
      _alertService.triggerAlert('HighProjectionLag', 'Projection delay exceeded 2 seconds', lagMs, traceId: traceId);
    }
  }

  void _evaluateAlerts({String? traceId}) {
    final total = _recentOperations.length;
    if (total == 0) return;

    final errors = _recentOperations.where((r) => r == 'error').length;
    final conflicts = _recentOperations.where((r) => r == 'conflict').length;

    final errorRate = errors / total;
    final conflictRate = conflicts / total;

    // ★ ダッシュボード用状態更新
    _ref.read(dashboardMetricsProvider.notifier).state = {
      'totalEvents': _totalEvents,
      'errorRate': errorRate,
      'conflictRate': conflictRate,
      'lastLagMs': _ref.read(dashboardMetricsProvider)['lastLagMs'],
    };

    if (total < 10) return; // サンプルが少ないうちはアラートを鳴らさない

    if (errorRate > 0.01) {
      _alertService.triggerAlert('HighErrorRate', 'Error rate exceeded 1%', errorRate * 100, traceId: traceId);
    }

    if (conflictRate > 0.05) {
      _alertService.triggerAlert('HighConflictRate', 'Conflict rate exceeded 5%', conflictRate * 100, traceId: traceId);
    }
  }

  void _emitMetric(String name, num value, String type, {String? traceId}) {
    final metricData = {
      'metric': name,
      'value': value,
      'type': type,
      'traceId': ?traceId, 
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };
    developer.log(jsonEncode(metricData), name: 'KendoOS.Metrics');
  }
}