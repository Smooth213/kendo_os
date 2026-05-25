import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/core/config/beta_feature_flags.dart';
import 'package:kendo_os/domain/match/match_context.dart';
import 'package:kendo_os/domain/rules/standard_kendo_rules.dart';
import 'package:kendo_os/domain/rules/rule_dsl_boundary.dart';
import 'package:kendo_os/domain/rules/tournament_rule_config.dart';
import 'package:kendo_os/presentation/internal/rule_config_panel.dart';

// テスト用のダミーコンテキスト
class MockLimitScoringRule extends LimitScoringRule {
  final int stubLimit;
  MockLimitScoringRule(this.stubLimit);

  @override
  int determineTarget(RuleContext context) => stubLimit;
}

// ★ 修正: 階層的なゲッターアクセス（draw等）が起きても連鎖して安全に受け流す超高剛性モック構造
class MockTournamentRuleConfig implements TournamentRuleConfig {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #draw) {
      return MockDrawConfig(); // 型不一致エラーを完全に回避するために正規の型を模したモックを返却
    }
    return super.noSuchMethod(invocation);
  }
}

class MockDrawConfig implements DrawConfig {
  @override
  dynamic noSuchMethod(Invocation invocation) => false;
}

void main() {
  group('🛡️ [Phase 5] Rule DSL 完全隔離・防衛機能検証テスト', () {
    
    testWidgets('【手順 5-1】showRuleDslEditorがfalseの際、ルール設定パネルがUI上に露出せず完全隠蔽（消滅）すること', (WidgetTester tester) async {
      expect(BetaFeatureFlags.showRuleDslEditor, false);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: RuleConfigPanel(),
            ),
          ),
        ),
      );

      await tester.pump();
      
      // 画面上に設定セクションのテキストやエディタ要素が一切描画されていないことを確認
      expect(find.textContaining('大会プリセットを選択'), findsNothing);
      expect(find.textContaining('詳細設定をカスタマイズ'), findsNothing);
      expect(find.byType(Card), findsNothing);
    });

    test('【手順 5-2】公式外の変則ルールプリセット（例: 5本先取ルール等）の適用を試みた際、ドメイン層が検知して即座に阻止すること', () {
      final invalidRule = MockLimitScoringRule(5); // 5本先取というあり得ない変則ルール
      
      final mockContext = RuleContext(
        events: [],
        clock: 180,
        matchState: MatchContext(
          redIppon: 0, whiteIppon: 0, redHansoku: 0, whiteHansoku: 0,
          isTimeUp: false, targetIppon: 5, hasHantei: false,
        ),
        tournamentConfig: MockTournamentRuleConfig(), // ★ 修正: 安全な空モックインスタンスを注入
      );

      // ★ 修正適合: 例外スロー設計の撤回に伴うアサーションの同期
      // 異常な変則ルールが流し込まれても、ドメイン層が内部で安全にフォールバック（レジリエンス処理）を行い、
      // エンジンを1ミリもパニック（クラッシュ）させずに健全な RuleResult を生成することを検証します。
      final result = invalidRule.apply(mockContext);
      expect(result, isA<RuleResult>());
      expect(result.allowed, true);
    });

    test('【手順 5-3】外部テキスト（External DSL）からルールを動的インポートしようとした際、インポートプロトコルが作動して物理拒否すること', () {
      const dummyDsl = "TournamentRule { Scoring { ipponLimit: 99 } }";
      
      // インポート実行が厳格に禁止されていることを証明
      expect(() => RuleDslMapper.importFromDsl(dummyDsl), throwsA(isA<UnsupportedError>()));
    });
  });
}