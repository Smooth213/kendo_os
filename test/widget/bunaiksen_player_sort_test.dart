import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bunaiksen/bunaiksen_single_player_select_sheet.dart';
import 'package:kendo_os/shared/widgets/smart_player_input.dart';
import 'package:kendo_os/shared/widgets/multi_player_select_input.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';

class MockPlayerRepository extends Mock implements PlayerRepository {}

void main() {
  late MockPlayerRepository mockPlayerRepo;
  late FakeFirebaseFirestore fakeFirestore;

  final samplePlayers = [
    PlayerModel(
      id: 'p_younen',
      lastName: '幼年',
      firstName: '太郎',
      lastNameKana: 'ヨウネン',
      firstNameKana: 'タロウ',
      grade: 0, // 幼年
    ),
    PlayerModel(
      id: 'p_teigakunen',
      lastName: '低学年',
      firstName: '一郎',
      lastNameKana: 'テイガクネン',
      firstNameKana: 'イチロウ',
      grade: 2, // 小2
    ),
    PlayerModel(
      id: 'p_kougakunen',
      lastName: '高学年',
      firstName: '次郎',
      lastNameKana: 'コウガクネン',
      firstNameKana: 'ジロウ',
      grade: 5, // 小5
    ),
    PlayerModel(
      id: 'p_chugaku',
      lastName: '中学生',
      firstName: '三郎',
      lastNameKana: 'チュウガク',
      firstNameKana: 'サブロウ',
      grade: 8, // 中2
    ),
    PlayerModel(
      id: 'p_ippan',
      lastName: '一般',
      firstName: '四郎',
      lastNameKana: 'イッパン',
      firstNameKana: 'シロウ',
      grade: 14, // 一般
    ),
  ];

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockPlayerRepo = MockPlayerRepository();
    when(
      () => mockPlayerRepo.getPlayers(),
    ).thenAnswer((_) => Stream.value(samplePlayers));
  });

  group('🥋 Bunaiksen Player Sorting & Asc/Desc Toggle Tests', () {
    testWidgets(
      '1. BunaiksenSinglePlayerSelectSheet - Default Grade Ascending & Toggle to Descending',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        String? selectedResult;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () async {
                      selectedResult = await showModalBottomSheet<String>(
                        context: context,
                        builder: (_) => BunaiksenSinglePlayerSelectSheet(
                          sideName: '赤',
                          accentColor: const Color(0xFFE53935),
                          masterPlayers: samplePlayers,
                        ),
                      );
                    },
                    child: const Text('Open Sheet'),
                  );
                },
              ),
            ),
          ),
        );

        // Open sheet
        await tester.tap(find.text('Open Sheet'));
        await tester.pumpAndSettle();

        // 1. Initial State: 学年昇順 (0 -> 2 -> 5 -> 8 -> 14)
        expect(find.text('学年 昇順'), findsOneWidget);

        var listTiles = tester.widgetList<ListTile>(find.byType(ListTile));
        var names = listTiles.map((tile) => (tile.title as Text).data).toList();

        expect(names, ['幼年 太郎', '低学年 一郎', '高学年 次郎', '中学生 三郎', '一般 四郎']);

        // 2. Toggle to 学年降順 (14 -> 8 -> 5 -> 2 -> 0)
        await tester.tap(find.text('学年 昇順'));
        await tester.pumpAndSettle();

        expect(find.text('学年 降順'), findsOneWidget);
        listTiles = tester.widgetList<ListTile>(find.byType(ListTile));
        names = listTiles.map((tile) => (tile.title as Text).data).toList();

        expect(names, ['一般 四郎', '中学生 三郎', '高学年 次郎', '低学年 一郎', '幼年 太郎']);

        // 3. Tap on a player to confirm selection
        await tester.tap(find.text('中学生 三郎'));
        await tester.pumpAndSettle();

        expect(selectedResult, '中学生 三郎');
      },
    );

    testWidgets('2. SmartPlayerInput - Header Sort Toggle & Grade Ordering', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = TextEditingController();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            firestoreProvider.overrideWithValue(fakeFirestore),
            currentDojoIdProvider.overrideWith((ref) => 'test_dojo'),
            playerRepositoryProvider.overrideWithValue(mockPlayerRepo),
            bunaiksenPlayerMasterProvider.overrideWith(
              (ref) => Stream.value(samplePlayers),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
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

      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      // Tap SmartPlayerInput to trigger sheet
      await tester.tap(find.byType(SmartPlayerInput));
      await tester.pumpAndSettle();

      // 1. Initial State: 学年昇順
      expect(find.text('学年 昇順'), findsOneWidget);
      var listTiles = tester.widgetList<ListTile>(find.byType(ListTile));
      var names = listTiles.map((tile) => (tile.title as Text).data).toList();

      expect(names, ['幼年 太郎', '低学年 一郎', '高学年 次郎', '中学生 三郎', '一般 四郎']);

      // 2. Tap Sort Toggle in Header
      await tester.tap(find.text('学年 昇順'));
      await tester.pumpAndSettle();

      expect(find.text('学年 降順'), findsOneWidget);
      listTiles = tester.widgetList<ListTile>(find.byType(ListTile));
      names = listTiles.map((tile) => (tile.title as Text).data).toList();

      expect(names, ['一般 四郎', '中学生 三郎', '高学年 次郎', '低学年 一郎', '幼年 太郎']);

      // 3. Select player
      await tester.tap(find.text('高学年 次郎'));
      await tester.pumpAndSettle();

      expect(controller.text, '高学年 次郎');
    });

    testWidgets(
      '3. MultiPlayerSelectInput - Header Sort Toggle & Multi Selection',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        List<String> confirmedPlayers = [];

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              firestoreProvider.overrideWithValue(fakeFirestore),
              currentDojoIdProvider.overrideWith((ref) => 'test_dojo'),
              playerRepositoryProvider.overrideWithValue(mockPlayerRepo),
              bunaiksenPlayerMasterProvider.overrideWith(
                (ref) => Stream.value(samplePlayers),
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, child) {
                    ref.watch(bunaiksenPlayerMasterProvider);
                    return MultiPlayerSelectInput(
                      initialSelected: const [],
                      onConfirm: (selected) {
                        confirmedPlayers = selected;
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 50));
        await tester.pumpAndSettle();

        // Tap to open multi-select sheet
        await tester.tap(find.byType(MultiPlayerSelectInput));
        await tester.pumpAndSettle();

        // 1. Initial State: 学年昇順
        expect(find.text('学年 昇順'), findsOneWidget);
        var checkTiles = tester.widgetList<CheckboxListTile>(
          find.byType(CheckboxListTile),
        );
        var names = checkTiles
            .map((tile) => (tile.title as Text).data)
            .toList();

        expect(names, ['幼年 太郎', '低学年 一郎', '高学年 次郎', '中学生 三郎', '一般 四郎']);

        // 2. Select '低学年 一郎'
        await tester.tap(find.text('低学年 一郎'));
        await tester.pumpAndSettle();
        expect(find.text('1名 選択中'), findsOneWidget);

        // 3. Tap sort toggle to 降順
        await tester.tap(find.text('学年 昇順'));
        await tester.pumpAndSettle();

        expect(find.text('学年 降順'), findsOneWidget);
        checkTiles = tester.widgetList<CheckboxListTile>(
          find.byType(CheckboxListTile),
        );
        names = checkTiles.map((tile) => (tile.title as Text).data).toList();

        expect(names, ['一般 四郎', '中学生 三郎', '高学年 次郎', '低学年 一郎', '幼年 太郎']);

        // 4. Select '一般 四郎'
        await tester.tap(find.text('一般 四郎'));
        await tester.pumpAndSettle();
        expect(find.text('2名 選択中'), findsOneWidget);

        // 5. Confirm
        await tester.tap(find.text('確定'));
        await tester.pumpAndSettle();

        expect(confirmedPlayers, containsAll(['低学年 一郎', '一般 四郎']));
      },
    );
  });
}
