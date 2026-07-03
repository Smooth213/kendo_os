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
    'Bunaiksen calendar picker does not crash when initialDate (viewDate) is not in selectableDayPredicate',
    (WidgetTester tester) async {
      // 1. Setup mock preferences
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      // 2. We set viewDate to 2026-06-22 (which is NOT today and NOT in available dates)
      final viewDate = DateTime(2026, 6, 22);

      // We define empty available dates (so 2026-06-22 is NOT selectable)
      final Set<String> availableDates = {};

      final container = ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          bunaiksenViewDateProvider.overrideWith((ref) => viewDate),
          bunaiksenAvailableDatesProvider.overrideWith(
            (ref) => Stream.value(availableDates),
          ),
          bunaiksenMatchesProvider(
            'bunaiksen_20260622',
          ).overrideWithValue(<MatchModel>[]),
          currentDojoIdProvider.overrideWith((ref) => 'test203'),
        ],
        child: const MaterialApp(home: BunaiksenHomeScreen()),
      );

      await tester.pumpWidget(container);
      await tester.pumpAndSettle();

      // 3. Find the calendar IconButton and tap it
      final calendarFinder = find.byIcon(Icons.calendar_month);
      expect(calendarFinder, findsOneWidget);

      await tester.tap(calendarFinder);
      await tester.pumpAndSettle();

      // 4. Verify that the date picker dialog has opened successfully and no assertion crash occurred
      expect(find.byType(DatePickerDialog), findsOneWidget);
    },
  );
}
