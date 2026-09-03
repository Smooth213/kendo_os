import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/admin/providers/metrics_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/ui_message_provider.dart';
import 'package:kendo_os/shared/domain/entities/role_permission.dart';

/// MatchApplicationService の共通ヘルパーメソッド群
///
/// [MatchApplicationService] から分離された「現在ユーザー取得」と
/// 「安全実行ラッパー」の2つのユーティリティを提供する。
class MatchProgressCalculator {
  const MatchProgressCalculator._();

  /// Firebase Auth から現在ログイン中のユーザー情報を安全に取得する。
  ///
  /// テスト環境や未ログイン時も 'test_user' / 'unknown_user' で安全にフォールバックする。
  static User getCurrentUser() {
    String uid = 'unknown_user';
    try {
      uid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown_user';
    } catch (_) {
      uid = 'test_user';
    }
    return User(id: uid, role: Role.admin, organizationId: 'default_org');
  }

  /// アクションを安全に実行し、レイテンシ計測・エラーメトリクス記録・UIエラー表示を行う。
  ///
  /// - [action] 実行する非同期アクション
  /// - [errorPrefix] エラー時にユーザーに表示するプレフィックスメッセージ
  /// - [metricName] レイテンシを記録するメトリクス名（省略可）
  /// - [traceId] トレースID（省略可）
  static Future<void> safeExecute(
    Ref ref,
    Future<void> Function() action,
    String errorPrefix, {
    String? metricName,
    String? traceId,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      await action();
      stopwatch.stop();
      if (metricName != null) {
        ref
            .read(metricsProvider)
            .recordLatency(
              metricName,
              stopwatch.elapsedMilliseconds,
              traceId: traceId,
            );
      }
    } catch (e) {
      stopwatch.stop();
      if (e.toString().contains('Concurrency') ||
          e.toString().contains('競合') ||
          e.toString().contains('他の端末')) {
        ref.read(metricsProvider).recordConcurrencyConflict(traceId: traceId);
      } else {
        ref.read(metricsProvider).recordError(traceId: traceId);
      }
      ref.read(uiMessageProvider.notifier).showError('$errorPrefix: $e');
      rethrow;
    }
  }
}
