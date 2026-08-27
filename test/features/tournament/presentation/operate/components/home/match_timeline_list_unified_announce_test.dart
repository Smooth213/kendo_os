import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_timeline_list.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/timeline_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';

// Mock CommentCommandService
class MockCommentCommandService extends Mock implements CommentCommandService {}

void main() {
  group('🛡️ Unified Announce Dialog Widget Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late SharedPreferences prefs;
    late MockCommentCommandService mockCommentService;
    late List<Map<String, dynamic>> addedComments;

    setUp(() async {
      registerFallbackValue(const Color(0xFFFF69B4));
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      fakeFirestore = FakeFirebaseFirestore();
      mockCommentService = MockCommentCommandService();
      addedComments = [];

      // Stub addComment
      when(
        () => mockCommentService.addComment(
          tournamentId: any(named: 'tournamentId'),
          category: any(named: 'category'),
          groupName: any(named: 'groupName'),
          text: any(named: 'text'),
          order: any(named: 'order'),
          matchGroupId: any(named: 'matchGroupId'),
        ),
      ).thenAnswer((invocation) async {
        addedComments.add({
          'tournamentId': invocation.namedArguments[#tournamentId],
          'category': invocation.namedArguments[#category],
          'groupName': invocation.namedArguments[#groupName],
          'text': invocation.namedArguments[#text],
          'order': invocation.namedArguments[#order],
          'matchGroupId': invocation.namedArguments[#matchGroupId],
        });
      });
    });

    Widget createTestTarget({
      required ProviderContainer container,
      required String tournamentId,
    }) {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Consumer(
                builder: (context, ref, _) {
                  return ElevatedButton(
                    onPressed: () {
                      showUnifiedAnnounceDialog(
                        context,
                        ref,
                        tournamentId,
                        '一般の部',
                        '第一会場',
                        1.0,
                      );
                    },
                    child: const Text('Open Unified Dialog'),
                  );
                },
              ),
            ),
          ),
        ),
      );
    }

    testWidgets(
      '1. Should post announcement and timeline comment for "all" target',
      (WidgetTester tester) async {
        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            firestoreProvider.overrideWithValue(fakeFirestore),
            commentCommandProvider.overrideWithValue(mockCommentService),
          ],
        );

        await tester.pumpWidget(
          createTestTarget(container: container, tournamentId: 'tourney_abc'),
        );
        await tester.pumpAndSettle();

        // Open Dialog
        await tester.tap(find.text('Open Unified Dialog'));
        await tester.pumpAndSettle();

        // Check fields exist
        expect(find.text('公式アナウンス・コメントの一斉発信'), findsOneWidget);

        // Enter title and body
        await tester.enterText(
          find.widgetWithText(TextField, 'タイトル（例：【緊急】会場変更）'),
          '【緊急連絡】',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'アナウンス本文内容'),
          '昼食休憩に入ります。',
        );
        await tester.pumpAndSettle();

        // Tap Send and Save
        await tester.tap(find.text('一斉発信して保存'));
        await tester.pumpAndSettle();

        // Check SnackBar appeared
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.text('全員向け緊急アナウンスを一斉配信しました'), findsOneWidget);

        // Verify Firestore announcement document
        final announceSnapshot = await fakeFirestore
            .collection('announcements')
            .get();
        expect(announceSnapshot.docs.length, 1);
        final docData = announceSnapshot.docs.first.data();
        expect(docData['title'], '【緊急連絡】');
        expect(docData['body'], '昼食休憩に入ります。');
        expect(docData['target'], 'all');
        expect(docData['type'], 'emergency');

        // Verify Local/Isar Comment command invocation
        expect(addedComments.length, 1);
        expect(addedComments.first['text'], '【緊急連絡】\n昼食休憩に入ります。');
      },
    );

    testWidgets('2. Should post staff-only announcement and timeline comment', (
      WidgetTester tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          firestoreProvider.overrideWithValue(fakeFirestore),
          commentCommandProvider.overrideWithValue(mockCommentService),
        ],
      );

      await tester.pumpWidget(
        createTestTarget(container: container, tournamentId: 'tourney_abc'),
      );
      await tester.pumpAndSettle();

      // Open Dialog
      await tester.tap(find.text('Open Unified Dialog'));
      await tester.pumpAndSettle();

      // Enter body
      await tester.enterText(
        find.widgetWithText(TextField, 'アナウンス本文内容'),
        '審判員は本部に集合してください。',
      );
      await tester.pumpAndSettle();

      // Select Staff Only ChoiceChip
      await tester.tap(find.text('スタッフ限定'));
      await tester.pumpAndSettle();

      // Tap Send and Save
      await tester.tap(find.text('一斉発信して保存'));
      await tester.pumpAndSettle();

      // Check SnackBar
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('スタッフ限定業務連絡を発信しました'), findsOneWidget);

      // Verify Firestore document targeting staff
      final announceSnapshot = await fakeFirestore
          .collection('announcements')
          .get();
      expect(announceSnapshot.docs.length, 1);
      final docData = announceSnapshot.docs.first.data();
      expect(docData['title'], '大会本部からのお知らせ');
      expect(docData['body'], '審判員は本部に集合してください。');
      expect(docData['target'], 'staff');

      // Verify Comment command text
      expect(addedComments.length, 1);
      expect(addedComments.first['text'], '審判員は本部に集合してください。');
    });
  });
}
