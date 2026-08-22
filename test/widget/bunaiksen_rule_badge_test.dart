import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bunaiksen_setup/bunaiksen_rule_settings_card.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// テスト用 AppThemeColors
const _testThemeColors = AppThemeColors(
  primaryAccent: Color(0xFF6366F1),
  softAccent: Color(0xFFEEF2FF),
  cardBackground: Color(0xFFFFFFFF),
  scaffoldBackground: Color(0xFFF8FAFC),
  textColor: Color(0xFF1E293B),
  subTextColor: Color(0xFF64748B),
  separatorColor: Color(0xFFE2E8F0),
  inputBackground: Color(0xFFF1F5F9),
  hintColor: Color(0xFF94A3B8),
  rosePink: Color(0xFFEC4899),
  successColor: Color(0xFF22C55E),
  warningColor: Color(0xFFF59E0B),
  errorColor: Color(0xFFEF4444),
  infoColor: Color(0xFF3B82F6),
);

/// テスト用ウィジェットラッパー
Widget _buildTestWidget(MatchRule rule) {
  return ProviderScope(
    overrides: [bunaiksenRuleProvider.overrideWith((ref) => rule)],
    child: MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: BunaiksenRuleSettingsCard(
            rule: rule,
            isDark: false,
            themeColors: _testThemeColors,
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('🏷️ 部内戦ルールバッジ表示テスト', () {
    testWidgets('1. デフォルトルール: 3分 / 3本 のみ表示 (延長・判定なし)', (
      WidgetTester tester,
    ) async {
      const rule = MatchRule(
        matchTimeMinutes: 3.0,
        isIpponShobu: false,
        enchoTimeMinutes: 0.0,
        isEnchoUnlimited: false,
        hasHantei: false,
      );

      await tester.pumpWidget(_buildTestWidget(rule));
      await tester.pumpAndSettle();

      // メインバッジ: 時間 + 勝負形式
      expect(find.text('3分 / 3本'), findsOneWidget);

      // 延長・判定バッジは表示されない
      expect(find.text('延長'), findsNothing);
      expect(find.text('延長∞'), findsNothing);
      expect(find.text('判定'), findsNothing);
    });

    testWidgets('2. 1分30秒・1本勝負: 秒も正しく表示される', (WidgetTester tester) async {
      const rule = MatchRule(
        matchTimeMinutes: 1.5,
        isIpponShobu: true,
        enchoTimeMinutes: 0.0,
        isEnchoUnlimited: false,
        hasHantei: false,
      );

      await tester.pumpWidget(_buildTestWidget(rule));
      await tester.pumpAndSettle();

      // 1.5分 → 「1分30秒」と表示
      expect(find.text('1分30秒 / 1本'), findsOneWidget);
    });

    testWidgets('3. 2分30秒・3本勝負・延長あり: 延長バッジが表示される', (WidgetTester tester) async {
      const rule = MatchRule(
        matchTimeMinutes: 2.5,
        isIpponShobu: false,
        enchoTimeMinutes: 2.0,
        isEnchoUnlimited: false,
        hasHantei: false,
      );

      await tester.pumpWidget(_buildTestWidget(rule));
      await tester.pumpAndSettle();

      expect(find.text('2分30秒 / 3本'), findsOneWidget);
      expect(find.text('延長'), findsOneWidget);
    });

    testWidgets('4. 延長無制限: 延長∞ バッジが表示される', (WidgetTester tester) async {
      const rule = MatchRule(
        matchTimeMinutes: 3.0,
        isIpponShobu: false,
        enchoTimeMinutes: 0.0,
        isEnchoUnlimited: true,
        hasHantei: false,
      );

      await tester.pumpWidget(_buildTestWidget(rule));
      await tester.pumpAndSettle();

      expect(find.text('3分 / 3本'), findsOneWidget);
      expect(find.text('延長∞'), findsOneWidget);
      expect(find.text('延長'), findsNothing); // 通常延長ではない
    });

    testWidgets('5. 判定あり: 判定バッジが表示される', (WidgetTester tester) async {
      const rule = MatchRule(
        matchTimeMinutes: 2.0,
        isIpponShobu: true,
        enchoTimeMinutes: 0.0,
        isEnchoUnlimited: false,
        hasHantei: true,
      );

      await tester.pumpWidget(_buildTestWidget(rule));
      await tester.pumpAndSettle();

      expect(find.text('2分 / 1本'), findsOneWidget);
      expect(find.text('判定'), findsOneWidget);
    });

    testWidgets('6. フルルール: 全バッジが同時に表示される', (WidgetTester tester) async {
      const rule = MatchRule(
        matchTimeMinutes: 3.0,
        isIpponShobu: false,
        enchoTimeMinutes: 0.0,
        isEnchoUnlimited: true,
        hasHantei: true,
      );

      await tester.pumpWidget(_buildTestWidget(rule));
      await tester.pumpAndSettle();

      // 3つのバッジすべてが表示される
      expect(find.text('3分 / 3本'), findsOneWidget);
      expect(find.text('延長∞'), findsOneWidget);
      expect(find.text('判定'), findsOneWidget);
    });
  });

  group('⚙️ 部内戦ルール設定変更テスト', () {
    testWidgets('7. ルール変更時にバッジがリアルタイム更新される', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const initialRule = MatchRule(
        matchTimeMinutes: 3.0,
        isIpponShobu: false,
        enchoTimeMinutes: 0.0,
        isEnchoUnlimited: false,
        hasHantei: false,
      );

      late StateController<MatchRule> ruleController;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [bunaiksenRuleProvider.overrideWith((ref) => initialRule)],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  final rule = ref.watch(bunaiksenRuleProvider);
                  ruleController = ref.read(bunaiksenRuleProvider.notifier);
                  return SingleChildScrollView(
                    child: BunaiksenRuleSettingsCard(
                      rule: rule,
                      isDark: false,
                      themeColors: _testThemeColors,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 初期状態: 3分 / 3本 のみ
      expect(find.text('3分 / 3本'), findsOneWidget);
      expect(find.text('延長∞'), findsNothing);
      expect(find.text('判定'), findsNothing);

      // ルール変更: 延長無制限 + 判定あり + 1本勝負 + 1分30秒
      ruleController.state = const MatchRule(
        matchTimeMinutes: 1.5,
        isIpponShobu: true,
        enchoTimeMinutes: 0.0,
        isEnchoUnlimited: true,
        hasHantei: true,
      );
      await tester.pumpAndSettle();

      // 更新後: 全バッジが表示される
      expect(find.text('1分30秒 / 1本'), findsOneWidget);
      expect(find.text('延長∞'), findsOneWidget);
      expect(find.text('判定'), findsOneWidget);
    });

    testWidgets('8. アコーディオン展開で設定UIが表示される', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const rule = MatchRule(
        matchTimeMinutes: 3.0,
        isIpponShobu: false,
        enchoTimeMinutes: 0.0,
        isEnchoUnlimited: false,
        hasHantei: false,
      );

      await tester.pumpWidget(_buildTestWidget(rule));
      await tester.pumpAndSettle();

      // 初期状態: アコーディオンは閉じている → 設定UIは表示されない
      expect(find.text('試合時間'), findsNothing);
      expect(find.text('勝敗条件'), findsNothing);
      expect(find.text('延長戦'), findsNothing);

      // タイトル行をタップしてアコーディオンを展開
      await tester.tap(find.text('部内戦ルール設定'));
      await tester.pumpAndSettle();

      // 展開後: 設定UIが表示される
      expect(find.text('試合時間'), findsOneWidget);
      expect(find.text('勝敗条件'), findsOneWidget);
      expect(find.text('延長戦'), findsOneWidget);
      expect(find.text('判定'), findsWidgets); // バッジ内とラベル両方
    });

    testWidgets('9. 各種試合時間の分秒表記が正確である', (WidgetTester tester) async {
      // テストケース: matchTimeMinutes → 期待される表示
      final testCases = <double, String>{
        1.0: '1分 / 3本',
        1.5: '1分30秒 / 3本',
        2.0: '2分 / 3本',
        2.5: '2分30秒 / 3本',
        3.0: '3分 / 3本',
      };

      for (final entry in testCases.entries) {
        final rule = MatchRule(
          matchTimeMinutes: entry.key,
          isIpponShobu: false,
          enchoTimeMinutes: 0.0,
          isEnchoUnlimited: false,
          hasHantei: false,
        );

        await tester.pumpWidget(_buildTestWidget(rule));
        await tester.pumpAndSettle();

        expect(
          find.text(entry.value),
          findsOneWidget,
          reason: '${entry.key}分 → "${entry.value}" と表示されるべき',
        );
      }
    });

    testWidgets('10. バッジが丸付きのContainer(ピルバッジ)スタイルで描画される', (
      WidgetTester tester,
    ) async {
      const rule = MatchRule(
        matchTimeMinutes: 3.0,
        isIpponShobu: false,
        enchoTimeMinutes: 2.0,
        isEnchoUnlimited: false,
        hasHantei: true,
      );

      await tester.pumpWidget(_buildTestWidget(rule));
      await tester.pumpAndSettle();

      // バッジテキストを持つContainerを見つける
      final mainBadgeFinder = find.text('3分 / 3本');
      expect(mainBadgeFinder, findsOneWidget);

      // Containerの親がDecoratedBoxを持つことを確認（ピルバッジスタイル）
      final badgeContainer = find.ancestor(
        of: mainBadgeFinder,
        matching: find.byType(Container),
      );
      expect(badgeContainer, findsWidgets);

      // 延長バッジも同様にContainerで囲まれている
      final enchoBadgeFinder = find.text('延長');
      expect(enchoBadgeFinder, findsOneWidget);
      final enchoContainer = find.ancestor(
        of: enchoBadgeFinder,
        matching: find.byType(Container),
      );
      expect(enchoContainer, findsWidgets);
    });
  });
}
