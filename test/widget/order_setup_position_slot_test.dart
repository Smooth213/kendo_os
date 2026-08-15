import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/order_setup/order_setup_position_slot.dart';

void main() {
  group('🛡️ OrderSetupPositionSlot Widget Tests', () {
    testWidgets(
      'Renders position slot with player name, change button, and handles vacant',
      (WidgetTester tester) async {
        bool tapped = false;
        bool vacantTapped = false;
        String opponent = '田中 次郎';

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: OrderSetupPositionSlot(
                  key: const ValueKey('slot_0'),
                  index: 0,
                  posName: '先鋒',
                  playerName: '佐藤 太郎',
                  teamName: '東京剣道クラブ',
                  isSelected: true,
                  onTap: () => tapped = true,
                  isDark: false,
                  showOpponentField: true,
                  opponentPlayerName: opponent,
                  onOpponentChanged: (val) => opponent = val,
                  onVacantPressed: () => vacantTapped = true,
                ),
              ),
            ),
          ),
        );

        expect(find.text('東京剣道クラブ : 先鋒'), findsOneWidget);
        expect(find.text('佐藤 太郎'), findsOneWidget);
        expect(find.text('変更'), findsOneWidget);
        expect(find.text('対戦相手 (先鋒)'), findsOneWidget);
        expect(find.text('欠員'), findsOneWidget);

        await tester.tap(find.text('変更'));
        expect(tapped, isTrue);

        await tester.tap(find.text('欠員'));
        expect(vacantTapped, isTrue);
      },
    );
  });
}
