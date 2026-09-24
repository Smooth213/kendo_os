import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/domain/entities/settings_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/settings_screen.dart';

void main() {
  testWidgets('SettingsModel contains textSizeMode and updates correctly', (
    tester,
  ) async {
    const settings = SettingsModel();
    expect(settings.textSizeMode, 'normal');

    final largeSettings = settings.copyWith(textSizeMode: 'large');
    expect(largeSettings.textSizeMode, 'large');

    final extraLargeSettings = settings.copyWith(textSizeMode: 'extraLarge');
    expect(extraLargeSettings.textSizeMode, 'extraLarge');
  });

  testWidgets('SettingsScreen displays text size selector', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: SettingsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('文字サイズ'), findsOneWidget);
  });
}
