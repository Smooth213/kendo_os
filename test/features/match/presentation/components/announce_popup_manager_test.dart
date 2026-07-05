import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kendo_os/features/match/presentation/components/announce_popup_manager.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';

void main() {
  group('🛡️ Global Announcement Popup Manager Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late SharedPreferences prefs;

    setUp(() async {
      resetAnnouncePopupManager();
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
              builder: (context) => Consumer(
                builder: (context, ref, _) {
                  // Trigger listenGlobalAnnouncements
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) {
                      listenGlobalAnnouncements(
                        context,
                        ref,
                        tournamentId,
                        isStaffRoom: isStaffRoom,
                      );
                    }
                  });
                  return const Text('Home Screen Content');
                },
              ),
            ),
          ),
        ),
      );
    }

    testWidgets(
      '1. Should show dialog for recent emergency announcement (target: all)',
      (WidgetTester tester) async {
        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            firestoreProvider.overrideWithValue(fakeFirestore),
          ],
        );

        // Create screen (Viewer / non-staff room)
        await tester.pumpWidget(
          createTestTarget(
            container: container,
            tournamentId: 'tourney_123',
            isStaffRoom: false,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);

        // Add emergency announcement doc targeting 'all'
        await fakeFirestore.collection('announcements').add({
          'tournamentId': 'tourney_123',
          'title': '避難警報',
          'body': '落雷の恐れがあるため体育館内に避難してください。',
          'timestamp': Timestamp.now(),
          'type': 'emergency',
          'target': 'all',
          'isRead': false,
        });

        // Pump to trigger snapshot stream listener
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        // Dialog should appear
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('避難警報'), findsOneWidget);

        // Tap confirm button to close
        final confirmBtn = find.text('内容を確認しました');
        expect(confirmBtn, findsOneWidget);
        await tester.tap(confirmBtn);
        await tester.pumpAndSettle();

        // Dialog should be gone
        expect(find.byType(AlertDialog), findsNothing);
      },
    );

    testWidgets(
      '2. Should NOT show dialog if notifyOnEmergency settings is disabled',
      (WidgetTester tester) async {
        // Set settings to disable notifyOnEmergency in SharedPreferences
        await prefs.setString(
          'kendo_sync_settings',
          '{"notifyOnEmergency":false}',
        );

        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            firestoreProvider.overrideWithValue(fakeFirestore),
          ],
        );

        // Build target
        await tester.pumpWidget(
          createTestTarget(
            container: container,
            tournamentId: 'tourney_123',
            isStaffRoom: true,
          ),
        );
        await tester.pumpAndSettle();

        // Add emergency announcement
        await fakeFirestore.collection('announcements').add({
          'tournamentId': 'tourney_123',
          'title': 'テスト緊急タイトル',
          'body': 'テスト緊急本文',
          'timestamp': Timestamp.now(),
          'type': 'emergency',
          'target': 'all',
          'isRead': false,
        });

        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        // Should NOT find dialog
        expect(find.byType(AlertDialog), findsNothing);
      },
    );

    testWidgets(
      '3. Should NOT show dialog for announcements older than 30 minutes',
      (WidgetTester tester) async {
        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            firestoreProvider.overrideWithValue(fakeFirestore),
          ],
        );

        await tester.pumpWidget(
          createTestTarget(
            container: container,
            tournamentId: 'tourney_123',
            isStaffRoom: true,
          ),
        );
        await tester.pumpAndSettle();

        // Add old announcement (31 minutes ago)
        final oldTime = DateTime.now().subtract(const Duration(minutes: 31));
        await fakeFirestore.collection('announcements').add({
          'tournamentId': 'tourney_123',
          'title': '過去のアナウンス',
          'body': 'これは古い内容です。',
          'timestamp': Timestamp.fromDate(oldTime),
          'type': 'emergency',
          'target': 'all',
          'isRead': false,
        });

        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
      },
    );

    testWidgets(
      '4. Staff target announcement: Should show in staff room, but skip in non-staff room',
      (WidgetTester tester) async {
        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            firestoreProvider.overrideWithValue(fakeFirestore),
          ],
        );

        // Case A: Non-staff room (ViewerHomeScreen)
        await tester.pumpWidget(
          createTestTarget(
            container: container,
            tournamentId: 'tourney_123',
            isStaffRoom: false,
          ),
        );
        await tester.pumpAndSettle();

        // Add staff-only emergency announcement
        await fakeFirestore.collection('announcements').add({
          'tournamentId': 'tourney_123',
          'title': '本部業務連絡',
          'body': '第2コートのスコア用紙を回収してください。',
          'timestamp': Timestamp.now(),
          'type': 'emergency',
          'target': 'staff',
          'isRead': false,
        });

        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        // Dialog should NOT appear on non-staff screen (skipped)
        expect(find.byType(AlertDialog), findsNothing);

        // Case B: Staff room (HomeScreen)
        await tester.pumpWidget(
          createTestTarget(
            container: container,
            tournamentId: 'tourney_123',
            isStaffRoom: true,
          ),
        );
        await tester.pumpAndSettle();

        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        // Dialog should now appear on staff screen
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('【スタッフ限定業務連絡】'), findsOneWidget);
        expect(find.text('第2コートのスコア用紙を回収してください。'), findsOneWidget);
      },
    );
  });
}
