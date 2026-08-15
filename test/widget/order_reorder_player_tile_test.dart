import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/sheets/order_reorder_player_tile.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('🛡️ OrderReorderPlayerTile Widget Tests', () {
    testWidgets('Renders position player tile correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
          ),
          home: const Scaffold(
            body: OrderReorderPlayerTile(
              label: '先鋒',
              playerName: '佐藤 健太',
              isPosition: true,
              isDark: false,
            ),
          ),
        ),
      );

      expect(find.text('先鋒'), findsOneWidget);
      expect(find.text('佐藤 健太'), findsOneWidget);
      expect(find.byIcon(Icons.drag_handle), findsOneWidget);
    });

    testWidgets('Renders reserve player tile correctly in dark mode', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: Brightness.dark,
            extensions: [AppThemeColors.ofMode(isDark: true, mode: 'normal')],
          ),
          home: const Scaffold(
            body: OrderReorderPlayerTile(
              label: '控1',
              playerName: '田中 太郎',
              isPosition: false,
              isDark: true,
            ),
          ),
        ),
      );

      expect(find.text('控1'), findsOneWidget);
      expect(find.text('田中 太郎'), findsOneWidget);
    });
  });
}
