import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/widgets/smart_player_input.dart';

void main() {
  group('Player Candidate Integration Tests under Any Dojo Name', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    test(
      '1. Provider level verification - arbitrary dojo name (e.g. 千代田道場)',
      () async {
        // 1. Prepare fake Firestore data
        await fakeFirestore
            .collection('organizations')
            .doc('chiyoda_dojo_id')
            .collection('players')
            .doc('player_1')
            .set({
              'id': 'player_1',
              'lastName': '山田',
              'firstName': '太郎',
              'lastNameKana': 'ヤマダ',
              'firstNameKana': 'タロウ',
              'grade': 3,
              'organization': '千代田道場',
              'isBeginner': false,
            });

        // 2. Set up ProviderContainer with overrides
        final container = ProviderContainer(
          overrides: [
            currentDojoIdProvider.overrideWith((ref) => 'chiyoda_dojo_id'),
            playerRepositoryProvider.overrideWith((ref) {
              final dojoId = ref.watch(currentDojoIdProvider);
              return PlayerRepository(dojoId: dojoId, firestore: fakeFirestore);
            }),
          ],
        );
        addTearDown(container.dispose);

        // 3. Watch player list
        final playerRepository = container.read(playerRepositoryProvider);
        final stream = playerRepository.getPlayers();
        final playerList = await stream.first;

        expect(playerList, hasLength(1));
        expect(playerList.first.name, '山田 太郎');
        expect(playerList.first.organization, '千代田道場');
      },
    );

    test(
      '2. Provider level verification - another arbitrary dojo name (e.g. 港武道館)',
      () async {
        // 1. Prepare fake Firestore data
        await fakeFirestore
            .collection('organizations')
            .doc('minato_budokan_id')
            .collection('players')
            .doc('player_2')
            .set({
              'id': 'player_2',
              'lastName': '佐藤',
              'firstName': '次郎',
              'lastNameKana': 'サトウ',
              'firstNameKana': 'ジロウ',
              'grade': 4,
              'organization': '港武道館',
              'isBeginner': false,
            });

        // 2. Set up ProviderContainer with overrides
        final container = ProviderContainer(
          overrides: [
            currentDojoIdProvider.overrideWith((ref) => 'minato_budokan_id'),
            playerRepositoryProvider.overrideWith((ref) {
              final dojoId = ref.watch(currentDojoIdProvider);
              return PlayerRepository(dojoId: dojoId, firestore: fakeFirestore);
            }),
          ],
        );
        addTearDown(container.dispose);

        // 3. Watch player list
        final playerRepository = container.read(playerRepositoryProvider);
        final stream = playerRepository.getPlayers();
        final playerList = await stream.first;

        expect(playerList, hasLength(1));
        expect(playerList.first.name, '佐藤 次郎');
        expect(playerList.first.organization, '港武道館');
      },
    );

    testWidgets(
      '3. Widget level verification - Bunaiksen Mode (SmartPlayerInput)',
      (WidgetTester tester) async {
        // 1. Prepare fake Firestore data
        await fakeFirestore
            .collection('organizations')
            .doc('chiyoda_dojo_id')
            .collection('players')
            .doc('player_1')
            .set({
              'id': 'player_1',
              'lastName': '山田',
              'firstName': '太郎',
              'lastNameKana': 'ヤマダ',
              'firstNameKana': 'タロウ',
              'grade': 3,
              'organization': '千代田道場',
              'isBeginner': false,
            });

        final controller = TextEditingController();

        // 2. Render SmartPlayerInput widget inside ProviderScope wrapped in Consumer to pre-warm stream
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentDojoIdProvider.overrideWith((ref) => 'chiyoda_dojo_id'),
              playerRepositoryProvider.overrideWith((ref) {
                final dojoId = ref.watch(currentDojoIdProvider);
                return PlayerRepository(
                  dojoId: dojoId,
                  firestore: fakeFirestore,
                );
              }),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, child) {
                    // Keep StreamProvider active
                    ref.watch(bunaiksenPlayerMasterProvider);
                    return SmartPlayerInput(
                      controller: controller,
                      label: '選手テスト',
                    );
                  },
                ),
              ),
            ),
          ),
        );

        // Wait for stream to emit values
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        // 3. Tap on SmartPlayerInput to trigger the player select sheet
        await tester.tap(find.byType(SmartPlayerInput));
        await tester.pumpAndSettle();

        // 4. Verify candidate is displayed inside the bottom sheet
        expect(find.text('選手を選択'), findsOneWidget);
        expect(find.text('山田 太郎'), findsOneWidget);

        // 5. Select the player and verify it fills the controller
        await tester.tap(find.text('山田 太郎'));
        await tester.pumpAndSettle();

        expect(controller.text, '山田 太郎');
      },
    );

    testWidgets(
      '4. Widget level verification - Offline / Empty Dojo ID Fallback (Bunaiksen Mode)',
      (WidgetTester tester) async {
        // 1. Prepare fake Firestore data under default test201
        await fakeFirestore
            .collection('organizations')
            .doc('test201')
            .collection('players')
            .doc('player_default')
            .set({
              'id': 'player_default',
              'lastName': '鈴木',
              'firstName': '一郎',
              'lastNameKana': 'スズキ',
              'firstNameKana': 'イチロウ',
              'grade': 2,
              'organization': 'テスト道場',
              'isBeginner': false,
            });

        final controller = TextEditingController();

        // 2. Render SmartPlayerInput widget inside ProviderScope wrapped in Consumer to pre-warm stream
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentDojoIdProvider.overrideWith(
                (ref) => '',
              ), // empty string to trigger fallback
              playerRepositoryProvider.overrideWith((ref) {
                final dojoId = ref.watch(currentDojoIdProvider);
                return PlayerRepository(
                  dojoId: dojoId,
                  firestore: fakeFirestore,
                );
              }),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, child) {
                    // Keep StreamProvider active
                    ref.watch(bunaiksenPlayerMasterProvider);
                    return SmartPlayerInput(
                      controller: controller,
                      label: '選手テスト',
                    );
                  },
                ),
              ),
            ),
          ),
        );

        // Wait for stream to emit values
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        // 3. Tap on SmartPlayerInput to trigger the player select sheet
        await tester.tap(find.byType(SmartPlayerInput));
        await tester.pumpAndSettle();

        // 4. Verify candidate is displayed inside the bottom sheet (under fallback test201)
        expect(find.text('選手を選択'), findsOneWidget);
        expect(find.text('鈴木 一郎'), findsOneWidget);

        // 5. Select the player and verify it fills the controller
        await tester.tap(find.text('鈴木 一郎'));
        await tester.pumpAndSettle();

        expect(controller.text, '鈴木 一郎');
      },
    );
  });
}
