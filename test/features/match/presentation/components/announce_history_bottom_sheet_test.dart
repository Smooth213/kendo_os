import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kendo_os/features/match/presentation/components/announce_history_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';

void main() {
  group('🛡️ AnnounceHistoryBottomSheet Widget Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      fakeFirestore = FakeFirebaseFirestore();
    });

    Widget createTestTarget({
      required ProviderContainer container,
      required String tournamentId,
      required bool isStaffRoom,
    }) {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AnnounceHistoryBottomSheet.show(
                  context,
                  tournamentId,
                  isStaffRoom,
                ),
                child: const Text('Open Bottom Sheet'),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets(
      '1. Should show both all and staff notifications in staff room',
      (WidgetTester tester) async {
        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            firestoreProvider.overrideWithValue(fakeFirestore),
          ],
        );

        // Add emergency announcement targeted to 'all'
        await fakeFirestore.collection('announcements').add({
          'tournamentId': 'tourney_999',
          'title': '全員向け避難警報',
          'body': 'グラウンドへ避難してください。',
          'timestamp': Timestamp.now(),
          'type': 'emergency',
          'target': 'all',
          'isRead': false,
        });

        // Add emergency announcement targeted to 'staff'
        await fakeFirestore.collection('announcements').add({
          'tournamentId': 'tourney_999',
          'title': 'スタッフ連絡',
          'body': '第2コートの審判交代をお願いします。',
          'timestamp': Timestamp.now(),
          'type': 'emergency',
          'target': 'staff',
          'isRead': false,
        });

        // Render button
        await tester.pumpWidget(
          createTestTarget(
            container: container,
            tournamentId: 'tourney_999',
            isStaffRoom: true,
          ),
        );
        await tester.pumpAndSettle();

        // Tap button to open bottom sheet
        await tester.tap(find.text('Open Bottom Sheet'));
        await tester.pumpAndSettle();

        // Both should be found
        expect(find.text('全員向け避難警報'), findsOneWidget);
        expect(find.text('【スタッフ限定】'), findsOneWidget);
      },
    );

    testWidgets(
      '2. Should show only all notifications in non-staff room (viewer)',
      (WidgetTester tester) async {
        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            firestoreProvider.overrideWithValue(fakeFirestore),
          ],
        );

        // Add emergency announcement targeted to 'all'
        await fakeFirestore.collection('announcements').add({
          'tournamentId': 'tourney_999',
          'title': '全員向け避難警報',
          'body': 'グラウンドへ避難してください。',
          'timestamp': Timestamp.now(),
          'type': 'emergency',
          'target': 'all',
          'isRead': false,
        });

        // Add emergency announcement targeted to 'staff'
        await fakeFirestore.collection('announcements').add({
          'tournamentId': 'tourney_999',
          'title': 'スタッフ連絡',
          'body': '第2コートの審判交代をお願いします。',
          'timestamp': Timestamp.now(),
          'type': 'emergency',
          'target': 'staff',
          'isRead': false,
        });

        // Render button for viewer
        await tester.pumpWidget(
          createTestTarget(
            container: container,
            tournamentId: 'tourney_999',
            isStaffRoom: false,
          ),
        );
        await tester.pumpAndSettle();

        // Tap button to open bottom sheet
        await tester.tap(find.text('Open Bottom Sheet'));
        await tester.pumpAndSettle();

        // 'all' is found, but 'staff' is filtered out
        expect(find.text('全員向け避難警報'), findsOneWidget);
        expect(find.text('【スタッフ限定】'), findsNothing);
      },
    );

    testWidgets(
      '3. Tapping unread card should mark it as read and clear pink dot',
      (WidgetTester tester) async {
        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            firestoreProvider.overrideWithValue(fakeFirestore),
          ],
        );

        // Add unread announcement
        final docRef = await fakeFirestore.collection('announcements').add({
          'tournamentId': 'tourney_999',
          'title': '避難警報',
          'body': 'グラウンドへ避難してください。',
          'timestamp': Timestamp.now(),
          'type': 'emergency',
          'target': 'all',
          'isRead': false,
        });

        await tester.pumpWidget(
          createTestTarget(
            container: container,
            tournamentId: 'tourney_999',
            isStaffRoom: true,
          ),
        );
        await tester.pumpAndSettle();

        // Open bottom sheet
        await tester.tap(find.text('Open Bottom Sheet'));
        await tester.pumpAndSettle();

        // Find unread indicator (pink dot Container)
        final pinkDotFinder = find.byWidgetPredicate((widget) {
          if (widget is Container && widget.decoration is BoxDecoration) {
            final boxDec = widget.decoration as BoxDecoration;
            return boxDec.color == const Color(0xFFFF69B4) &&
                boxDec.shape == BoxShape.circle;
          }
          return false;
        });

        expect(pinkDotFinder, findsOneWidget);

        // Tap the card to read
        await tester.tap(find.text('避難警報'));
        await tester.pumpAndSettle();

        // Pink dot should disappear (local read cache updates UI immediately)
        expect(pinkDotFinder, findsNothing);

        // Verify local state notifier got updated with read doc ID
        expect(container.read(readAnnouncementsProvider), contains(docRef.id));

        // Verify Firestore database doc remains unchanged (false) to preserve local-only read state
        final updatedSnapshot = await docRef.get();
        expect(updatedSnapshot.data()?['isRead'], isFalse);
      },
    );

    testWidgets(
      '4. NotificationBellButton should display sakura pink dot if unread notifications exist',
      (WidgetTester tester) async {
        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            firestoreProvider.overrideWithValue(fakeFirestore),
          ],
        );

        // Render NotificationBellButton directly
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: NotificationBellButton(
                  tournamentId: 'tourney_999',
                  isStaffRoom: true,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Initial State: No unread documents
        final badgeDotFinder = find.byWidgetPredicate((widget) {
          if (widget is Container && widget.decoration is BoxDecoration) {
            final boxDec = widget.decoration as BoxDecoration;
            return boxDec.color == const Color(0xFFFF69B4) &&
                boxDec.shape == BoxShape.circle;
          }
          return false;
        });

        expect(badgeDotFinder, findsNothing);

        // 2. Add unread document
        await fakeFirestore.collection('announcements').add({
          'tournamentId': 'tourney_999',
          'title': '新着通知',
          'body': '未読のアナウンスがあります。',
          'timestamp': Timestamp.now(),
          'type': 'emergency',
          'target': 'all',
          'isRead': false,
        });

        // Trigger stream update
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        // 3. Dot should appear
        expect(badgeDotFinder, findsOneWidget);
      },
    );
  });
}
