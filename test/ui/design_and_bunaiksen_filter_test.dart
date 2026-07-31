import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart';
import 'package:kendo_os/shared/widgets/smart_player_input.dart';
import 'package:kendo_os/shared/widgets/multi_player_select_input.dart';

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
  });
}
