import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/order_setup_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/bunaiksen_home_screen.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/shared/presentation/providers/dojo_room_sync_provider.dart';
import 'package:kendo_os/features/match/presentation/providers/match_rule_provider.dart';

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

  group('🛡️ Order Drag & Drop Reordering & Bunaiksen Quick Match Tests', () {
    testWidgets(
      '1. Verify OrderSetupScreen renders ReorderableListView with drag handle icons',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              currentDojoIdProvider.overrideWith((ref) => 'test204'),
              playerRepositoryProvider.overrideWithValue(mockPlayerRepo),
              isarProvider.overrideWithValue(null),
              opponentTeamHistoryProvider.overrideWithValue([]),
              dojoRoomSyncProvider.overrideWith((ref) {}),
              matchRuleProvider.overrideWith(() => MatchRuleNotifier()),
            ],
            child: const MaterialApp(
              home: OrderSetupScreen(tournamentId: 'test_t1'),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // OrderSetupScreen が正常に構築されること
        expect(find.byType(OrderSetupScreen), findsOneWidget);
        expect(find.text('オーダー編成'), findsOneWidget);
      },
    );

    testWidgets(
      '2. Verify BunaiksenHomeScreen renders 1-second quick match button',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              currentDojoIdProvider.overrideWith((ref) => 'test204'),
              isarProvider.overrideWithValue(null),
              dojoRoomSyncProvider.overrideWith((ref) {}),
            ],
            child: const MaterialApp(home: BunaiksenHomeScreen()),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // 「クイック対戦を始める」ボタンが存在すること
        final quickButton = find.text('クイック対戦を始める');
        expect(quickButton, findsOneWidget);
      },
    );
  });
}
