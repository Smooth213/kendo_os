import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bulk_rule_detail_setting_cards.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('🛡️ BulkRuleDetailSettingCards Widget Tests', () {
    testWidgets('Renders cards and triggers change callbacks', (tester) async {
      double matchTime = 3.0;
      bool isIpponShobu = false;
      bool hasExtension = false;
      final controller = TextEditingController(text: '30');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SingleChildScrollView(
                  child: BulkRuleDetailSettingCards(
                    matchTime: matchTime,
                    isIpponShobu: isIpponShobu,
                    hasExtension: hasExtension,
                    enchoTime: 3.0,
                    enchoCount: 1,
                    isEnchoUnlimited: false,
                    hasHantei: false,
                    hasRepresentativeMatch: true,
                    isDaihyoIpponShobu: true,
                    isRenseikai: false,
                    renseikaiType: '一試合制',
                    overallTimeController: controller,
                    primaryAccent: Colors.blue,
                    isDark: false,
                    onMatchTimeChanged: (v) => matchTime = v,
                    onIpponShobuChanged: (v) => isIpponShobu = v,
                    onExtensionChanged: (v) => hasExtension = v,
                    onEnchoTimeChanged: (v) {},
                    onEnchoCountChanged: (v) {},
                    onEnchoUnlimitedChanged: (v) {},
                    onHanteiChanged: (v) {},
                    onRepresentativeMatchChanged: (v) {},
                    onDaihyoIpponShobuChanged: (v) {},
                    onRenseikaiChanged: (v) {},
                    onRenseikaiTypeChanged: (v) {},
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('⏱️ 基本ルール'), findsOneWidget);
      expect(find.text('🔄 延長ルール（本戦・通常試合）'), findsOneWidget);
      expect(find.text('⚖️ 個人戦ルール'), findsOneWidget);
      expect(find.text('⚔️ 団体戦・代表戦ルール'), findsOneWidget);
      expect(find.text('🏆 錬成会（練習マッチ）設定'), findsOneWidget);
      expect(find.text('一本勝負形式にする'), findsOneWidget);

      await tester.tap(find.text('一本勝負形式にする'));
      await tester.pumpAndSettle();
      expect(isIpponShobu, isTrue);
    });

    testWidgets(
      '【ダークモード視認性保証テスト】ダークモード時、カード背景色が灰色に濁らず、テキストとのコントラストが確保されていること',
      (tester) async {
        final controller = TextEditingController(text: '30');

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              brightness: Brightness.dark,
              extensions: [AppThemeColors.ofMode(isDark: true, mode: 'normal')],
            ),
            home: Scaffold(
              body: SingleChildScrollView(
                child: BulkRuleDetailSettingCards(
                  matchTime: 2.0,
                  isIpponShobu: false,
                  hasExtension: true,
                  enchoTime: 3.0,
                  enchoCount: 1,
                  isEnchoUnlimited: false,
                  hasHantei: false,
                  hasRepresentativeMatch: true,
                  isDaihyoIpponShobu: true,
                  isRenseikai: false,
                  renseikaiType: '一試合制',
                  overallTimeController: controller,
                  primaryAccent: Colors.indigo,
                  isDark: true,
                  onMatchTimeChanged: (_) {},
                  onIpponShobuChanged: (_) {},
                  onExtensionChanged: (_) {},
                  onEnchoTimeChanged: (_) {},
                  onEnchoCountChanged: (_) {},
                  onEnchoUnlimitedChanged: (_) {},
                  onHanteiChanged: (_) {},
                  onRepresentativeMatchChanged: (_) {},
                  onDaihyoIpponShobuChanged: (_) {},
                  onRenseikaiChanged: (_) {},
                  onRenseikaiTypeChanged: (_) {},
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 1. 各カードのMaterial背景色が半透明グレー（Color(0x80FFFFFF)など）ではなくダーク背景であること
        final materialFinder = find.byType(Material);
        final materials = tester.widgetList<Material>(materialFinder);
        for (final m in materials) {
          if (m.borderRadius == BorderRadius.circular(16) ||
              m.borderRadius == BorderRadius.circular(12)) {
            // 背景色が 0x80... (textColor.withAlpha(128)) 等の薄暗い灰色ではないことを確認
            expect(m.color, isNot(equals(const Color(0x80FFFFFF))));
            expect(m.color, isNot(equals(Colors.grey)));
          }
        }

        // 2. タイトルおよびラベルテキストが正常に描画されていること
        expect(find.text('⏱️ 基本ルール'), findsOneWidget);
        expect(find.text('試合時間'), findsOneWidget);
        expect(find.text('🔄 延長ルール（本戦・通常試合）'), findsOneWidget);
        expect(find.text('延長時間'), findsOneWidget);

        final matchTimeLabel = tester.widget<Text>(find.text('試合時間'));
        expect(matchTimeLabel.style?.color, isNotNull);
        expect(matchTimeLabel.style?.color, isNot(equals(Colors.black)));
      },
    );

    testWidgets('【ライトモード視認性保証テスト】ライトモード時、適切な背景と文字色で描画されること', (tester) async {
      final controller = TextEditingController(text: '30');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: Brightness.light,
            extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: BulkRuleDetailSettingCards(
                matchTime: 2.0,
                isIpponShobu: false,
                hasExtension: false,
                enchoTime: 3.0,
                enchoCount: 1,
                isEnchoUnlimited: false,
                hasHantei: false,
                hasRepresentativeMatch: true,
                isDaihyoIpponShobu: true,
                isRenseikai: false,
                renseikaiType: '一試合制',
                overallTimeController: controller,
                primaryAccent: Colors.indigo,
                isDark: false,
                onMatchTimeChanged: (_) {},
                onIpponShobuChanged: (_) {},
                onExtensionChanged: (_) {},
                onEnchoTimeChanged: (_) {},
                onEnchoCountChanged: (_) {},
                onEnchoUnlimitedChanged: (_) {},
                onHanteiChanged: (_) {},
                onRepresentativeMatchChanged: (_) {},
                onDaihyoIpponShobuChanged: (_) {},
                onRenseikaiChanged: (_) {},
                onRenseikaiTypeChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('⏱️ 基本ルール'), findsOneWidget);
      expect(find.text('試合時間'), findsOneWidget);
      final matchTimeLabel = tester.widget<Text>(find.text('試合時間'));
      expect(matchTimeLabel.style?.color, isNotNull);
      expect(matchTimeLabel.style?.color, isNot(equals(Colors.white)));
    });
  });
}
