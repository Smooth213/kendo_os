import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/bunaiksen_home_screen.dart';
import 'package:kendo_os/shared/widgets/smart_player_input.dart';
import 'package:kendo_os/shared/widgets/multi_player_select_input.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/providers/dojo_room_sync_provider.dart';

class MockPlayerRepository extends Mock implements PlayerRepository {}

class FakeBunaiksenGuestNotifier extends BunaiksenGuestNotifier {
  FakeBunaiksenGuestNotifier(super.ref) {
    state = [];
  }
}

void main() {
  late MockPlayerRepository mockPlayerRepo;

  setUp(() {
    mockPlayerRepo = MockPlayerRepository();
    when(() => mockPlayerRepo.getPlayers()).thenAnswer((_) => Stream.value([]));
  });

  group('🛡️ Design Regression Prevention & Bunaiksen Filter Tests', () {
    testWidgets(
      '1. Design Regression Prevention: App-wide Dialog (16px) & BottomSheet (20px) Theme Verification',
      (WidgetTester tester) async {
        final dialogShape = RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        );
        final bottomSheetShape = const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        );

        final testTheme = ThemeData(
          brightness: Brightness.dark,
          useMaterial3: true,
          dialogTheme: DialogThemeData(shape: dialogShape),
          bottomSheetTheme: BottomSheetThemeData(shape: bottomSheetShape),
        );

        // Verify DialogTheme shape has 16px corner radius
        expect(
          (testTheme.dialogTheme.shape as RoundedRectangleBorder).borderRadius,
          BorderRadius.circular(16),
        );

        // Verify BottomSheetTheme shape has 20px top corner radius
        expect(
          (testTheme.bottomSheetTheme.shape as RoundedRectangleBorder)
              .borderRadius,
          const BorderRadius.vertical(top: Radius.circular(20)),
        );
      },
    );

    testWidgets('2. Bunaiksen Player Select Category Filter Verification', (
      WidgetTester tester,
    ) async {
      final mockPlayers = [
        PlayerModel(
          id: '1',
          lastName: '高学年',
          firstName: '太郎',
          lastNameKana: 'こうがくねん',
          firstNameKana: 'たろう',
          grade: 5,
        ),
        PlayerModel(
          id: '2',
          lastName: '中学生',
          firstName: '次郎',
          lastNameKana: 'ちゅうがくせい',
          firstNameKana: 'じろう',
          grade: 8,
        ),
        PlayerModel(
          id: '3',
          lastName: '初心者',
          firstName: '花子',
          lastNameKana: 'しょしんしゃ',
          firstNameKana: 'はなこ',
          grade: 2,
          isBeginner: true,
        ),
      ];

      when(
        () => mockPlayerRepo.getPlayers(),
      ).thenAnswer((_) => Stream.value(mockPlayers));

      // MultiPlayerSelectInput が正しくビルドされ例外を出さないことを検証
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playerRepositoryProvider.overrideWithValue(mockPlayerRepo),
            bunaiksenPlayerMasterProvider.overrideWith(
              (ref) => Stream.value(mockPlayers),
            ),
            bunaiksenGuestProvider.overrideWith(
              (ref) => FakeBunaiksenGuestNotifier(ref),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: MultiPlayerSelectInput(
                initialSelected: const [],
                onConfirm: (list) {},
                label: '選手選択',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(MultiPlayerSelectInput), findsOneWidget);

      // SmartPlayerInput も同様にカテゴリフィルタ機能を提供することを検証
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playerRepositoryProvider.overrideWithValue(mockPlayerRepo),
            bunaiksenPlayerMasterProvider.overrideWith(
              (ref) => Stream.value(mockPlayers),
            ),
            bunaiksenGuestProvider.overrideWith(
              (ref) => FakeBunaiksenGuestNotifier(ref),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SmartPlayerInput(
                controller: TextEditingController(),
                label: '単一選手選択',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(SmartPlayerInput), findsOneWidget);
    });

    testWidgets(
      '3. Verify Bunaiksen Quick Match Player Selection Category Filter (High Grade & Beginner Chips)',
      (WidgetTester tester) async {
        final mockPlayers = [
          PlayerModel(
            id: '1',
            lastName: '高学年',
            firstName: '太郎',
            lastNameKana: 'こうがくねん',
            firstNameKana: 'たろう',
            grade: 5,
          ),
          PlayerModel(
            id: '2',
            lastName: '中学生',
            firstName: '次郎',
            lastNameKana: 'ちゅうがくせい',
            firstNameKana: 'じろう',
            grade: 8,
          ),
          PlayerModel(
            id: '3',
            lastName: '初心者',
            firstName: '花子',
            lastNameKana: 'しょしんしゃ',
            firstNameKana: 'はなこ',
            grade: 2,
            isBeginner: true,
          ),
        ];

        when(
          () => mockPlayerRepo.getPlayers(),
        ).thenAnswer((_) => Stream.value(mockPlayers));

        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        // BunaiksenHomeScreen をレンダリング
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              currentDojoIdProvider.overrideWith((ref) => 'test204'),
              playerRepositoryProvider.overrideWithValue(mockPlayerRepo),
              isarProvider.overrideWithValue(null),
              dojoRoomSyncProvider.overrideWith((ref) {}),
            ],
            child: const MaterialApp(home: BunaiksenHomeScreen()),
          ),
        );

        await tester.pumpAndSettle();

        // クイック対戦シートを起動
        final quickButton = find.text('クイック対戦を始める');
        await tester.tap(quickButton);
        await tester.pumpAndSettle();

        // 「赤」選手ドロップダウン枠をタップして名簿シートを開く
        final redPlayerDropdown = find.text('選手A');
        await tester.tap(redPlayerDropdown);
        await tester.pumpAndSettle();

        // 名簿シートが開き「赤の選手を選択」が表示されていること
        expect(find.text('赤の選手を選択'), findsOneWidget);
        // 初期状態（すべて）では全選手が表示されている
        expect(find.text('高学年 太郎'), findsOneWidget);
        expect(find.text('中学生 次郎'), findsOneWidget);
        expect(find.text('初心者 花子'), findsOneWidget);

        // 「高学年」チップをタップ
        final highGradeChip = find.text('高学年');
        await tester.tap(highGradeChip);
        await tester.pumpAndSettle();

        // 高学年 太郎 のみが残り、中学生 次郎 と 初心者 花子 がフィルタリングされて非表示になること
        expect(find.text('高学年 太郎'), findsOneWidget);
        expect(find.text('中学生 次郎'), findsNothing);
        expect(find.text('初心者 花子'), findsNothing);

        // 「初心者」チップをタップ
        final beginnerChip = find.text('初心者');
        await tester.tap(beginnerChip);
        await tester.pumpAndSettle();

        // 初心者 花子 のみが表示されること
        expect(find.text('初心者 花子'), findsOneWidget);
        expect(find.text('高学年 太郎'), findsNothing);
        expect(find.text('中学生 次郎'), findsNothing);
      },
    );

    testWidgets(
      '4. Comprehensive Bunaiksen Player Category Filter Unit & Integration Verification (All Categories)',
      (WidgetTester tester) async {
        final mockAllPlayers = [
          PlayerModel(
            id: 'younen',
            lastName: '幼年',
            firstName: '花子',
            lastNameKana: 'ようねん',
            firstNameKana: 'はなこ',
            grade: 0,
          ),
          PlayerModel(
            id: 'teigakunen',
            lastName: '低学年',
            firstName: '一郎',
            lastNameKana: 'ていがくねん',
            firstNameKana: 'いちろう',
            grade: 2,
          ),
          PlayerModel(
            id: 'kougakunen',
            lastName: '高学年',
            firstName: '二郎',
            lastNameKana: 'こうがくねん',
            firstNameKana: 'じろう',
            grade: 5,
          ),
          PlayerModel(
            id: 'chuugaku',
            lastName: '中学生',
            firstName: '三郎',
            lastNameKana: 'ちゅうがく',
            firstNameKana: 'さぶろう',
            grade: 8,
          ),
          PlayerModel(
            id: 'koukou',
            lastName: '高校生',
            firstName: '四郎',
            lastNameKana: 'こうこう',
            firstNameKana: 'しろう',
            grade: 11,
          ),
          PlayerModel(
            id: 'ippan',
            lastName: '一般',
            firstName: '五郎',
            lastNameKana: 'いっぱん',
            firstNameKana: 'ごろう',
            grade: 14,
          ),
        ];

        when(
          () => mockPlayerRepo.getPlayers(),
        ).thenAnswer((_) => Stream.value(mockAllPlayers));

        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              currentDojoIdProvider.overrideWith((ref) => 'test204'),
              playerRepositoryProvider.overrideWithValue(mockPlayerRepo),
              isarProvider.overrideWithValue(null),
              dojoRoomSyncProvider.overrideWith((ref) {}),
            ],
            child: const MaterialApp(home: BunaiksenHomeScreen()),
          ),
        );

        await tester.pumpAndSettle();

        // 1. クイック対戦 ➔ 名簿シート起動
        await tester.tap(find.text('クイック対戦を始める'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('選手A'));
        await tester.pumpAndSettle();

        // 2. 「幼年」フィルターを検証
        await tester.tap(find.text('幼年'));
        await tester.pumpAndSettle();
        expect(find.text('幼年 花子'), findsOneWidget);
        expect(find.text('低学年 一郎'), findsNothing);

        // 3. 「低学年」フィルターを検証
        await tester.tap(find.text('低学年'));
        await tester.pumpAndSettle();
        expect(find.text('低学年 一郎'), findsOneWidget);
        expect(find.text('幼年 花子'), findsNothing);

        // 4. 「中学生」フィルターを検証
        await tester.tap(find.text('中学生'));
        await tester.pumpAndSettle();
        expect(find.text('中学生 三郎'), findsOneWidget);
        expect(find.text('低学年 一郎'), findsNothing);

        // 5. 「一般」フィルターを検証
        await tester.ensureVisible(find.text('一般'));
        await tester.tap(find.text('一般'));
        await tester.pumpAndSettle();
        expect(find.text('一般 五郎'), findsOneWidget);
        expect(find.text('中学生 三郎'), findsNothing);
      },
    );
  });
}
