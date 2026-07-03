import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kendo_os/features/tournament/presentation/operate/screens/bunaiksen_home_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';

void main() {
  testWidgets(
    'BunaiksenHomeScreen displays today\'s date and "今日の部内戦" by default',
    (WidgetTester tester) async {
      // 1. Setup mock preferences
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      // 2. We compute today's dateId
      final today = DateTime.now();
      final yyyy = today.year.toString();
      final mm = today.month.toString().padLeft(2, '0');
      final dd = today.day.toString().padLeft(2, '0');
      final todayDateId = 'bunaiksen_$yyyy$mm$dd';

      final container = ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          // Do NOT override bunaiksenViewDateProvider so it uses the default DateTime.now()
          bunaiksenAvailableDatesProvider.overrideWith(
            (ref) => Stream.value(<String>{}),
          ),
          bunaiksenMatchesProvider(
            todayDateId,
          ).overrideWithValue(<MatchModel>[]),
          currentDojoIdProvider.overrideWith((ref) => 'test203'),
        ],
        child: const MaterialApp(home: BunaiksenHomeScreen()),
      );

      await tester.pumpWidget(container);
      await tester.pumpAndSettle();

      // 3. Verify that the bunaiksenViewDateProvider default value is indeed today
      final WidgetRef ref =
          tester.element(find.byType(BunaiksenHomeScreen)) as WidgetRef;
      final viewDate = ref.read(bunaiksenViewDateProvider);

      expect(viewDate.year, equals(today.year));
      expect(viewDate.month, equals(today.month));
      expect(viewDate.day, equals(today.day));

      // 4. Verify that the app bar title is displayed as "今日の部内戦"
      expect(find.text('今日の部内戦'), findsOneWidget);
    },
  );
}
