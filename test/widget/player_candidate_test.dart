import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/widgets/smart_player_input.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart';

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
              firestoreProvider.overrideWithValue(fakeFirestore),
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
              firestoreProvider.overrideWithValue(fakeFirestore),
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

    testWidgets(
      '5. SmartPlayerInput - Filtering by Category Chips and Sorting (Bunaiksen Mode)',
      (WidgetTester tester) async {
        // Set larger screen size to ensure all items are visible without scrolling
        tester.view.physicalSize = const Size(800, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        // 1. Prepare fake Firestore data with diverse players
        final playersData = [
          {
            'id': 'player_1',
            'lastName': '山田',
            'firstName': '太郎',
            'lastNameKana': 'ヤマダ',
            'firstNameKana': 'タロウ',
            'grade': 3, // 低学年
            'organization': '千代田道場',
            'isBeginner': false,
          },
          {
            'id': 'player_2',
            'lastName': '佐藤',
            'firstName': '次郎',
            'lastNameKana': 'サトウ',
            'firstNameKana': 'ジロウ',
            'grade': 5, // 高学年
            'organization': '千代田道場',
            'isBeginner': false,
          },
          {
            'id': 'player_3',
            'lastName': '鈴木',
            'firstName': '三郎',
            'lastNameKana': 'スズキ',
            'firstNameKana': 'サブロウ',
            'grade': 8, // 中学生
            'organization': '千代田道場',
            'isBeginner': false,
          },
          {
            'id': 'player_4',
            'lastName': '木村',
            'firstName': '初心者',
            'lastNameKana': 'キムラ',
            'firstNameKana': 'ショシンシャ',
            'grade': 2,
            'organization': '千代田道場',
            'isBeginner': true, // 初心者
          },
        ];

        for (final p in playersData) {
          await fakeFirestore
              .collection('organizations')
              .doc('chiyoda_dojo_id')
              .collection('players')
              .doc(p['id'] as String)
              .set(p);
        }

        // Write guest data under the fixed date (matching targetTournamentId)
        await fakeFirestore
            .collection('organizations')
            .doc('chiyoda_dojo_id')
            .collection('tournaments')
            .doc('bunaiksen_20260724')
            .collection('bunaiksen_guests')
            .doc('田中 ゲスト')
            .set({'name': '田中 ゲスト'});

        final controller = TextEditingController();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              firestoreProvider.overrideWithValue(fakeFirestore),
              currentDojoIdProvider.overrideWith((ref) => 'chiyoda_dojo_id'),
              bunaiksenViewDateProvider.overrideWith(
                (ref) => DateTime(2026, 7, 24),
              ),
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
                    ref.watch(bunaiksenPlayerMasterProvider);
                    ref.watch(bunaiksenGuestProvider);
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

        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        // 3. Tap on SmartPlayerInput to trigger the player select sheet
        await tester.tap(find.byType(SmartPlayerInput));
        await tester.pumpAndSettle();

        // 4. By default ('すべて'), all players and guest are displayed
        expect(find.text('山田 太郎'), findsOneWidget);
        expect(find.text('佐藤 次郎'), findsOneWidget);
        expect(find.text('鈴木 三郎'), findsOneWidget);
        expect(find.text('木村 初心者'), findsOneWidget);
        expect(find.text('田中 ゲスト'), findsOneWidget);

        // 五十音順（よみがな順）のソート並び順をアサーション検証
        final listTiles = tester.widgetList<ListTile>(find.byType(ListTile));
        final names = listTiles.map((tile) {
          final titleWidget = tile.title as Text;
          return titleWidget.data;
        }).toList();
        expect(names, [
          '田中 ゲスト', // ゲスト（出稽古）が最優先
          '木村 初心者', // きむら（五十音順）
          '佐藤 次郎', // さとう
          '鈴木 三郎', // すずき
          '山田 太郎', // やまだ
        ]);

        // 5. Tap '低学年' filter chip
        final lowGradeChip = find.widgetWithText(ChoiceChip, '低学年');
        await tester.ensureVisible(lowGradeChip);
        await tester.tap(lowGradeChip);
        await tester.pumpAndSettle();

        // Verify only '山田 太郎' is displayed (elementary low)
        expect(find.text('山田 太郎'), findsOneWidget);
        expect(find.text('佐藤 次郎'), findsNothing);
        expect(find.text('鈴木 三郎'), findsNothing);
        expect(find.text('木村 初心者'), findsNothing);
        expect(find.text('田中 ゲスト'), findsNothing);

        // 6. Tap '初心者' filter chip
        final beginnerChip = find.widgetWithText(ChoiceChip, '初心者');
        await tester.ensureVisible(beginnerChip);
        await tester.tap(beginnerChip);
        await tester.pumpAndSettle();

        // Verify only '木村 初心者' is displayed
        expect(find.text('木村 初心者'), findsOneWidget);
        expect(find.text('山田 太郎'), findsNothing);

        // 7. Tap 'ゲスト' filter chip
        final guestChip = find.widgetWithText(ChoiceChip, 'ゲスト');
        await tester.ensureVisible(guestChip);
        await tester.tap(guestChip);
        await tester.pumpAndSettle();

        // Verify only '田中 ゲスト' is displayed
        expect(find.text('田中 ゲスト'), findsOneWidget);
        expect(find.text('木村 初心者'), findsNothing);

        // 8. Tap 'すべて' to restore all
        final allChip = find.widgetWithText(ChoiceChip, 'すべて');
        await tester.ensureVisible(allChip);
        await tester.tap(allChip);
        await tester.pumpAndSettle();
        expect(find.text('山田 太郎'), findsOneWidget);
      },
    );
  });
}
