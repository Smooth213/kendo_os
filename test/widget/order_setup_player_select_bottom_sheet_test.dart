import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/order_setup/order_setup_player_select_bottom_sheet.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';

void main() {
  final testPlayers = [
    PlayerModel(
      id: 'p1',
      lastName: '山田',
      firstName: '太郎',
      lastNameKana: 'ヤマダ',
      firstNameKana: 'タロウ',
      grade: 5,
      isBeginner: false,
    ),
    PlayerModel(
      id: 'p2',
      lastName: '佐藤',
      firstName: '次郎',
      lastNameKana: 'サトウ',
      firstNameKana: 'ジロウ',
      grade: 8,
      isBeginner: false,
    ),
  ];

  testWidgets('OrderSetupPlayerSelectBottomSheet renders options and players', (
    tester,
  ) async {
    String? selectedResult;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                selectedResult = await OrderSetupPlayerSelectBottomSheet.show(
                  context,
                  masterPlayers: testPlayers,
                  themeColors: AppThemeColors.ofMode(
                    isDark: false,
                    mode: 'normal',
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('選手の選択'), findsOneWidget);
    expect(find.text('未定（空枠）'), findsOneWidget);
    expect(find.text('欠員（不戦敗）'), findsOneWidget);
    expect(find.text('直接入力（助っ人など）'), findsOneWidget);
    expect(find.text('山田 太郎'), findsOneWidget);
    expect(find.text('佐藤 次郎'), findsOneWidget);

    await tester.tap(find.text('山田 太郎'));
    await tester.pumpAndSettle();

    expect(selectedResult, '山田 太郎');
  });
}
