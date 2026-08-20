import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/admin/presentation/components/master_player_tile.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';

void main() {
  group('🛡️ MasterPlayerTile Widget Tests', () {
    testWidgets('Renders player details correctly', (tester) async {
      final player = PlayerModel(
        id: 'p1',
        lastName: '山田',
        firstName: '太郎',
        lastNameKana: 'ヤマダ',
        firstNameKana: 'タロウ',
        gender: '男子',
        grade: 7,
        isBeginner: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MasterPlayerTile(
              player: player,
              isReadOnly: false,
              canManageMaster: true,
              isSelectionMode: false,
              isSelected: false,
            ),
          ),
        ),
      );

      expect(find.text('山田 太郎'), findsOneWidget);
      expect(find.text('ヤマダ タロウ '), findsOneWidget);
      expect(find.text('中学1年 / 男子'), findsOneWidget);
      expect(find.text('初心者'), findsOneWidget);
    });

    testWidgets('Handles selection mode tap', (tester) async {
      final player = PlayerModel(
        id: 'p1',
        lastName: '佐藤',
        firstName: '花子',
        lastNameKana: 'サトウ',
        firstNameKana: 'ハナコ',
        gender: '女子',
        grade: 6,
      );

      bool tappedSelection = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MasterPlayerTile(
              player: player,
              isReadOnly: false,
              canManageMaster: true,
              isSelectionMode: true,
              isSelected: true,
              onTapSelection: () {
                tappedSelection = true;
              },
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      await tester.tap(find.text('佐藤 花子'));
      await tester.pump();
      expect(tappedSelection, isTrue);
    });
  });
}
