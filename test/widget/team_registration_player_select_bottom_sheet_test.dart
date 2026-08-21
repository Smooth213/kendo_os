import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_player_select_bottom_sheet.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  testWidgets(
    'TeamRegistrationPlayerSelectBottomSheet renders player list and handles selection',
    (WidgetTester tester) async {
      final p1 = PlayerModel(
        id: 'p1',
        lastName: '山田',
        firstName: '太郎',
        lastNameKana: 'ヤマダ',
        firstNameKana: 'タロウ',
        grade: 3,
        isBeginner: false,
      );
      final p2 = PlayerModel(
        id: 'p2',
        lastName: '佐藤',
        firstName: '花子',
        lastNameKana: 'サトウ',
        firstNameKana: 'ハナコ',
        grade: 4,
        isBeginner: false,
      );

      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => TeamRegistrationPlayerSelectBottomSheet.show(
                    context: context,
                    index: 0,
                    players: [p1, p2],
                    posNames: ['先鋒', '中堅', '大将'],
                    tempSelectedPlayers: {},
                    selectedMajorCategory: '小学生',
                    selectedMinorCategory: '低学年',
                    themeColors: themeColors,
                  ),
                  child: const Text('Open Sheet'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Verify header and player list rendered
      expect(find.text('選手の選択 (先鋒)'), findsWidgets);
      expect(find.text('山田 太郎'), findsOneWidget);
      expect(find.text('佐藤 花子'), findsOneWidget);

      // Tap on player
      await tester.tap(find.text('山田 太郎'));
      await tester.pumpAndSettle();

      // Sheet closed
      expect(find.text('山田 太郎'), findsNothing);
    },
  );
}
