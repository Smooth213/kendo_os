import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';

void main() {
  group('Bunaiksen Providers Dojo and Date Isolation / Sync Tests', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    test(
      'Guest players Firestore synchronization, date change and Dojo ID change isolation',
      () async {
        final container = ProviderContainer(
          overrides: [
            firestoreProvider.overrideWithValue(fakeFirestore),
            currentDojoIdProvider.overrideWith((ref) => 'test201'),
          ],
        );
        addTearDown(container.dispose);

        // 1. Initial State Check
        expect(container.read(bunaiksenGuestProvider), isEmpty);

        // 2. Add guest player under default Dojo (test201) and default Date (today)
        final notifier = container.read(bunaiksenGuestProvider.notifier);
        await notifier.addGuest('ゲストA');

        // Check local optimistic update
        expect(container.read(bunaiksenGuestProvider), contains('ゲストA'));

        // Wait for Firestore roundtrip stream update
        await Future.delayed(const Duration(milliseconds: 100));
        expect(container.read(bunaiksenGuestProvider), contains('ゲストA'));

        // Verify Firestore structure
        final todayStr = DateFormat('yyyyMMdd').format(DateTime.now());
        final doc = await fakeFirestore
            .collection('organizations')
            .doc('test201')
            .collection('tournaments')
            .doc('bunaiksen_$todayStr')
            .collection('bunaiksen_guests')
            .doc('ゲストA')
            .get();

        expect(doc.exists, true);
        expect(doc.data()?['name'], 'ゲストA');

        // 3. Switch date: Verify guest list resets/changes to the new date's Firestore collection
        // Change date to 2026-07-04
        final newDate = DateTime(2026, 7, 4);
        container.read(bunaiksenViewDateProvider.notifier).state = newDate;

        // Wait for Stream to update
        await Future.delayed(const Duration(milliseconds: 100));
        expect(container.read(bunaiksenGuestProvider), isEmpty);

        // Add guest to 2026-07-04
        await container.read(bunaiksenGuestProvider.notifier).addGuest('ゲストB');
        await Future.delayed(const Duration(milliseconds: 100));
        expect(container.read(bunaiksenGuestProvider), contains('ゲストB'));

        // Check Firestore doc under 2026-07-04
        final docNewDate = await fakeFirestore
            .collection('organizations')
            .doc('test201')
            .collection('tournaments')
            .doc('bunaiksen_20260704')
            .collection('bunaiksen_guests')
            .doc('ゲストB')
            .get();
        expect(docNewDate.exists, true);

        // 4. Switch Dojo ID: Verify guests list, queue, and streak reset completely
        // First populate queue and streak
        container
            .read(bunaiksenInfiniteQueueProvider.notifier)
            .addPlayer('選手X');
        container
            .read(bunaiksenInfiniteStreakProvider.notifier)
            .incrementStreak('選手X');

        expect(container.read(bunaiksenInfiniteQueueProvider), contains('選手X'));
        expect(container.read(bunaiksenInfiniteStreakProvider)['選手X'], 1);

        // Switch Dojo ID to test203
        container.read(currentDojoIdProvider.notifier).state = 'test203';

        // Wait for Stream to update
        await Future.delayed(const Duration(milliseconds: 100));

        // Guest list, queue, and streak should be completely empty/reset under the new Dojo ID context
        expect(container.read(bunaiksenGuestProvider), isEmpty);
        expect(container.read(bunaiksenInfiniteQueueProvider), isEmpty);
        expect(container.read(bunaiksenInfiniteStreakProvider), isEmpty);
      },
    );
  });
}
