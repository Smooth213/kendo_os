import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/renseikai_master_timer_widget.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_timer_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

class FakeRenseikaiMasterTimerNotifier extends RenseikaiMasterTimerNotifier {
  final int initialSeconds;
  FakeRenseikaiMasterTimerNotifier([this.initialSeconds = 120]);

  @override
  int build(String arg) => initialSeconds;
}

void main() {
  group('🛡️ RenseikaiMasterTimerWidget Widget Tests', () {
    testWidgets('Renders initial timer display and toggles on tap', (
      WidgetTester tester,
    ) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            renseikaiMasterTimerProvider.overrideWith(
              () => FakeRenseikaiMasterTimerNotifier(120),
            ),
            isMasterTimerRunningProvider('groupA').overrideWith((ref) => false),
          ],
          child: MaterialApp(
            theme: ThemeData(extensions: [themeColors]),
            home: const Scaffold(
              body: RenseikaiMasterTimerWidget(
                groupName: 'groupA',
                isInputLocked: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('トータル'), findsOneWidget);
      expect(find.text('2:00'), findsOneWidget);
      expect(find.byIcon(Icons.play_circle), findsOneWidget);
    });

    testWidgets('Renders running state and time up state correctly', (
      WidgetTester tester,
    ) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            renseikaiMasterTimerProvider.overrideWith(
              () => FakeRenseikaiMasterTimerNotifier(0),
            ),
            isMasterTimerRunningProvider('groupA').overrideWith((ref) => true),
          ],
          child: MaterialApp(
            theme: ThemeData(extensions: [themeColors]),
            home: const Scaffold(
              body: RenseikaiMasterTimerWidget(
                groupName: 'groupA',
                isInputLocked: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('0:00'), findsOneWidget);
      expect(find.byIcon(Icons.pause_circle), findsOneWidget);
    });
  });
}
