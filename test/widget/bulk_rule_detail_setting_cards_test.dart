import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bulk_rule_detail_setting_cards.dart';

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
  });
}
