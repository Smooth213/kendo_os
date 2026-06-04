import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/config/beta_feature_flags.dart';
import 'package:kendo_os/shared/widgets/sync_status_bar.dart';
import 'package:kendo_os/presentation/operate/providers/sync_provider.dart';
import 'package:kendo_os/presentation/operate/providers/role_provider.dart';
import 'package:kendo_os/presentation/operate/providers/match_command_provider.dart';

// ウィジェットテスト中に未初期化のIsarタイマーや非同期バックグラウンド処理を走らせないためのダミーSyncEngine
class MockSyncEngine implements SyncEngine {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// NotifierProvider の型チェック（引数なしクロージャ）に完全適合させる継承モック
class MockDeadLetterQueueNotifier extends DeadLetterQueueNotifier {
  @override
  List<MatchCommandModel> build() => []; // テスト用に空のエラーキュー状態を確定
}

void main() {
  group('🛡️ [Phase 3] Observability 統一ロケーション隔離検証テスト', () {
    testWidgets('同期バーが、一般ユーザー向けに定義された安心日本語表現（保存済み）を出力すること', (
      WidgetTester tester,
    ) async {
      // 1. ProviderScope内で、例外を投げる依存プロバイダ群（IsarおよびFirebase）を安全に固定（override）
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // タイマーリークとUnimplementedErrorの原因となるSyncEngineを安全にモック化
            syncEngineProvider.overrideWith((ref) => MockSyncEngine()),
            // NotifierProvider の正しい型定義に合わせてオーバーライド
            deadLetterQueueProvider.overrideWith(
              () => MockDeadLetterQueueNotifier(),
            ),

            // 🌟 修正: プロジェクトの実際の定義（OperationMode.tournament）に完全シンクロさせ、コンパイルエラーを根絶
            activeRoleProvider.overrideWith((ref) => Role.scorer),
            operationModeProvider.overrideWith(
              (ref) => OperationMode.tournament,
            ),

            // テスト表示用のステータスプロバイダを健全な初期値に固定
            syncStatusProvider.overrideWith((ref) => SyncStatus.synced),
            isOnlineProvider.overrideWith((ref) => true),
            isSyncingStateProvider.overrideWith((ref) => false),
          ],
          child: const MaterialApp(
            home: Scaffold(bottomNavigationBar: SyncStatusBar()),
          ),
        ),
      );

      // 初期フレームの描画
      await tester.pump();

      // 2. 画面上に「Firebase」「Socket」等のシステム内部用語が露出していないことをアサート
      expect(find.textContaining('Firebase'), findsNothing);
      expect(find.textContaining('Web Socket'), findsNothing);
      expect(find.textContaining('Establishing'), findsNothing);

      // 3. 縮退された安心日本語表現（保存済み）が正常に出力されていることを実証
      expect(find.text('保存済み'), findsOneWidget);
    });

    test('内部メトリクスプロバイダがUI露出禁止（showInternalMetrics == false）に完全統制されていること', () {
      expect(BetaFeatureFlags.showInternalMetrics, false);
    });
  });
}
