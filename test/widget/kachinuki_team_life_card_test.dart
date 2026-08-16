import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/kachinuki/kachinuki_team_life_card.dart';

void main() {
  group('🛡️ KachinukiTeamLifeCard Widget Tests', () {
    testWidgets('Renders team names, title, and shields correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: KachinukiTeamLifeCard(
              redTeamName: '赤道場',
              whiteTeamName: '白道場',
              redTotal: 5,
              redDead: 2,
              whiteTotal: 5,
              whiteDead: 3,
              isDark: false,
            ),
          ),
        ),
      );

      expect(find.text('チーム生存状況（残機）'), findsOneWidget);
      expect(find.text('赤道場'), findsOneWidget);
      expect(find.text('白道場'), findsOneWidget);
      expect(find.text('VS'), findsOneWidget);
      // 合計 10 個の shield アイコンが表示されていること
      expect(find.byIcon(Icons.shield), findsNWidgets(10));
    });

    testWidgets(
      'Renders in dark mode with styled shields without assertion errors',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: KachinukiTeamLifeCard(
                redTeamName: '紅組',
                whiteTeamName: '白組',
                redTotal: 3,
                redDead: 1,
                whiteTotal: 3,
                whiteDead: 0,
                isDark: true,
              ),
            ),
          ),
        );

        expect(find.text('紅組'), findsOneWidget);
        expect(find.text('白組'), findsOneWidget);
        expect(find.byIcon(Icons.shield), findsNWidgets(6));
      },
    );
  });
}
