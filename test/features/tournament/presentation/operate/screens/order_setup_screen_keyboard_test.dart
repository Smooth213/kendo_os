import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/order_setup_screen.dart';
import 'package:kendo_os/shared/widgets/glass_button.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';

class MockPlayerRepository extends Mock implements PlayerRepository {}

void main() {
  late MockPlayerRepository mockPlayerRepo;

  setUp(() {
    mockPlayerRepo = MockPlayerRepository();
    when(() => mockPlayerRepo.getPlayers()).thenAnswer((_) => Stream.value([]));
    when(
      () => mockPlayerRepo.watchCustomTeamNames(),
    ).thenAnswer((_) => Stream.value([]));
  });

  group('🛡️ OrderSetupScreen Keyboard Avoidance Layout Tests', () {
    testWidgets(
      '1. Bottom button area should be hidden when text input is focused to prevent keyboard crowding',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              playerRepositoryProvider.overrideWithValue(mockPlayerRepo),
              isarProvider.overrideWithValue(null),
              opponentTeamHistoryProvider.overrideWithValue([]),
            ],
            child: const MaterialApp(
              home: OrderSetupScreen(tournamentId: 'test_id'),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify screen rendered and confirm button is initially visible
        expect(find.byType(OrderSetupScreen), findsOneWidget);
        expect(find.byType(GlassButton), findsOneWidget);
        expect(find.text('このオーダーで確定して進む'), findsOneWidget);

        // Find the Autocomplete/TextField for opponent team name
        final teamInputFinder = find.byType(TextField).first;
        expect(teamInputFinder, findsOneWidget);

        // Focus on the team name input field (simulates keyboard opening)
        final FocusNode node = tester
            .widget<TextField>(teamInputFinder)
            .focusNode!;
        node.requestFocus();
        await tester.pump(); // Processes focus change and triggers setState
        await tester
            .pump(); // Renders the rebuild frame with updated isKeyboardOpen state

        // Verify that the bottom confirm button is now hidden to save space
        expect(find.byType(GlassButton), findsNothing);
        expect(find.text('このオーダーで確定して進む'), findsNothing);

        // Unfocus (simulates keyboard dismissing)
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();

        // Verify that the bottom confirm button becomes visible again
        expect(find.byType(GlassButton), findsOneWidget);
        expect(find.text('このオーダーで確定して進む'), findsOneWidget);
      },
    );
  });
}
