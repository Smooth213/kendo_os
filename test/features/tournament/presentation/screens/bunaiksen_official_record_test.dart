import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:kendo_os/features/tournament/presentation/screens/bunaiksen_official_record_screen.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';

class FakeLocalMatchRepository implements LocalMatchRepository {
  final List<MatchModel> matches;
  FakeLocalMatchRepository(this.matches);

  @override
  Stream<List<MatchModel>> watchAllLocalMatches() => Stream.value(matches);

  @override
  Stream<List<MatchModel>> watchMatches() => Stream.value(matches);

  @override
  Stream<MatchModel?> watchSingleMatch(String matchId) =>
      Stream.value(matches.where((m) => m.id == matchId).firstOrNull);

  @override
  Future<MatchModel?> getMatch(String matchId) async =>
      matches.where((m) => m.id == matchId).firstOrNull;

  @override
  Future<void> saveMatch(MatchModel match) async {}

  @override
  Future<void> saveMatchesBulk(List<MatchModel> matches) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => Future.value(null);
}

void main() {
  group('🛡️ Bunaiksen Official Record Dual-Platform Verification', () {
    late FakeFirebaseFirestore fakeFirestore;
    final dateId = 'bunaiksen_20260703';
    final mockMatch = MatchModel(
      id: 'test_match_1',
      tournamentId: dateId,
      groupName: 'group_1',
      matchType: 'リーグ戦',
      redName: '選手A',
      whiteName: '選手B',
      redScore: 2,
      whiteScore: 0,
      status: 'finished',
      category: '一般の部',
    );

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    testWidgets(
      '1. Web Environment: Should load match records from Firestore',
      (WidgetTester tester) async {
        debugIsWebOverride = true; // Simulate Web
        addTearDown(() => debugIsWebOverride = false);

        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        // Pre-populate match in Fake Cloud Firestore
        await fakeFirestore
            .collection('organizations')
            .doc('test_dojo_id')
            .collection('tournaments')
            .doc(dateId)
            .collection('matches')
            .doc(mockMatch.id)
            .set(mockMatch.toJson());

        final container = ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            firestoreProvider.overrideWithValue(fakeFirestore),
            currentDojoIdProvider.overrideWith((ref) => 'test_dojo_id'),
            bunaiksenViewDateProvider.overrideWith(
              (ref) => DateTime(2026, 7, 3),
            ),
          ],
          child: const MaterialApp(home: BunaiksenOfficialRecordScreen()),
        );

        await tester.pumpWidget(container);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        // Verify loaded data
        expect(find.text('この日の記録データはありません'), findsNothing);
        expect(find.text('一般の部'), findsOneWidget);
        expect(find.textContaining('選手A'), findsOneWidget);
        expect(find.textContaining('選手B'), findsOneWidget);
      },
    );

    testWidgets(
      '2. Native Environment: Should load match records from Local Database (Isar)',
      (WidgetTester tester) async {
        debugIsWebOverride = false; // Simulate Native

        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        final fakeRepo = FakeLocalMatchRepository([mockMatch]);

        final container = ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            localMatchRepositoryProvider.overrideWithValue(fakeRepo),
            currentDojoIdProvider.overrideWith((ref) => 'test_dojo_id'),
            bunaiksenViewDateProvider.overrideWith(
              (ref) => DateTime(2026, 7, 3),
            ),
          ],
          child: const MaterialApp(home: BunaiksenOfficialRecordScreen()),
        );

        await tester.pumpWidget(container);
        await tester.pump();
        await tester.pumpAndSettle();

        // Verify loaded data
        expect(find.text('この日の記録データはありません'), findsNothing);
        expect(find.text('一般の部'), findsOneWidget);
        expect(find.textContaining('選手A'), findsOneWidget);
        expect(find.textContaining('選手B'), findsOneWidget);
      },
    );
  });
}
