import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/admin/presentation/components/master_empty_state_card.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('🛡️ MasterEmptyStateCard Widget Tests', () {
    testWidgets(
      'Renders empty state texts and registration button when not readOnly',
      (WidgetTester tester) async {
        bool buttonTapped = false;
        final themeColors = AppThemeColors.ofMode(
          isDark: false,
          mode: 'normal',
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: ThemeData(extensions: [themeColors]),
              home: Scaffold(
                body: MasterEmptyStateCard(
                  primaryColor: Colors.purple,
                  isReadOnly: false,
                  iconWidget: const Icon(Icons.shield, size: 80),
                  buttonWidget: ElevatedButton.icon(
                    onPressed: () => buttonTapped = true,
                    icon: const Icon(Icons.account_balance),
                    label: const Text('道場名を登録する'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('まだ選手が登録されていません'), findsOneWidget);
        expect(
          find.text('選手を追加する前に、まずはあなたたちの道場名・学校名を登録することから始めましょう！'),
          findsOneWidget,
        );
        expect(find.text('道場名を登録する'), findsOneWidget);

        await tester.tap(find.text('道場名を登録する'));
        await tester.pump();
        expect(buttonTapped, isTrue);
      },
    );

    testWidgets('Hides registration button when isReadOnly is true', (
      WidgetTester tester,
    ) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData(extensions: [themeColors]),
            home: const Scaffold(
              body: MasterEmptyStateCard(
                primaryColor: Colors.blue,
                isReadOnly: true,
                iconWidget: Icon(Icons.shield, size: 80),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('まだ選手が登録されていません'), findsOneWidget);
      expect(find.text('道場名を登録する'), findsNothing);
    });
  });
}
