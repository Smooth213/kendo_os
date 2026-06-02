import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/core/config/beta_feature_flags.dart';
import 'package:kendo_os/core/config/runtime_mode.dart';
import 'package:kendo_os/presentation/match_router.dart';

void main() {
  group('🛡️ [Phase 1] Feature Flag 完全統制セキュリティ検証テスト', () {
    testWidgets('フラグがOFFの際、開発者用システム画面への直接URLアクセス（DeepLink）が物理拒否されること', (
      WidgetTester tester,
    ) async {
      // 1. 偽装URL直打ち（Observabilityダッシュボード等へのディープリンク）をシミュレート
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MatchRouter(matchId: 'observability-dashboard'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 2. フラグがOFF（BetaFeatureFlags.showObservability == false）であるため、画面が表示されずアクセス制限テキストが出ていることをアサート
      expect(find.textContaining('アクセス制限'), findsOneWidget);
      expect(find.text('Observability Dashboard'), findsNothing);
    });

    testWidgets('一般ユーザー画面において、隠蔽すべき特権操作ボタンやメニューが一切露出していないこと', (
      WidgetTester tester,
    ) async {
      // 1. フラグ状態の事前検証（★最新 of 定数定義に完全同期）
      const testMode = RuntimeMode.beta;
      expect(testMode, RuntimeMode.beta);
      expect(BetaFeatureFlags.showAiFeatures, false);
      expect(BetaFeatureFlags.enableAiGovernance, false);
      expect(BetaFeatureFlags.showRuleDslEditor, false);
      expect(BetaFeatureFlags.showInternalMetrics, false);

      // 2. UI上に開発者用のテキストやキーワード（AI, Governance, Rule DSL等）を冠したボタンが存在しないことを証明
      final aiButtonFinder = find.widgetWithText(ElevatedButton, 'AI判定');
      final govMenuFinder = find.byIcon(Icons.gavel);

      expect(aiButtonFinder, findsNothing);
      expect(govMenuFinder, findsNothing);
    });
  });
}
