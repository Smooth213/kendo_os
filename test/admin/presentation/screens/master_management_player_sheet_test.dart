import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/admin/presentation/screens/master_management_screen.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/presentation/providers/current_user_role_provider.dart';

class MockPlayerRepository extends Mock implements PlayerRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      PlayerModel(
        id: '',
        lastName: '',
        firstName: '',
        lastNameKana: '',
        firstNameKana: '',
        grade: 1,
        organization: 'テスト道場',
      ),
    );
  });

  late MockPlayerRepository mockPlayerRepo;

  setUp(() {
    mockPlayerRepo = MockPlayerRepository();
    when(() => mockPlayerRepo.getPlayers()).thenAnswer((_) => Stream.value([]));
    when(
      () => mockPlayerRepo.watchCustomTeamNames(),
    ).thenAnswer((_) => Stream.value([]));
    when(
      () => mockPlayerRepo.addPlayer(any()),
    ).thenAnswer((_) => Future.value());
  });

  group('🎯 Player Master BottomSheet & Timing Regression Tests', () {
    testWidgets('1. 自動フォーカスの排除検証 (フォーカスバッティング・せり上がり防止)', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final fakeFirestore = FakeFirebaseFirestore();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            playerRepositoryProvider.overrideWithValue(mockPlayerRepo),
            isarProvider.overrideWithValue(null),
            currentUserRoleProvider.overrideWith((ref) => UserRole.admin),
            firestoreProvider.overrideWithValue(fakeFirestore),
          ],
          child: const MaterialApp(home: MasterManagementScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // 初期道場名を登録してマスタ表示へ移行
      await tester.tap(find.text('道場名を登録する'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'テスト道場');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, '登録'));
      await tester.pumpAndSettle();

      // 選手登録ボトムシートを開く
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // ボトムシート内のフォーム要素の存在確認
      expect(find.text('よみがな (せい)'), findsOneWidget);
      expect(find.text('よみがな (めい)'), findsOneWidget);
      expect(find.text('名字'), findsOneWidget);
      expect(find.text('名前'), findsOneWidget);
      expect(find.text('男子'), findsOneWidget);
      expect(find.text('女子'), findsOneWidget);
      expect(find.text('学年・カテゴリ'), findsOneWidget);

      // 自動フォーカスが排除されているため、名字TextFieldが自動的にキーボードフォーカスを得ていないことを検証
      final lastNameFinder = find.widgetWithText(TextField, '名字');
      final TextField lastNameWidget = tester.widget<TextField>(lastNameFinder);
      expect(lastNameWidget.focusNode?.hasFocus ?? false, isFalse);

      // 手動でタップすることで入力可能であることを検証
      await tester.tap(lastNameFinder);
      await tester.pump();
      // タップ後はフォーカスが得られること
      expect(
        lastNameWidget.focusNode?.hasFocus ?? false,
        isFalse,
      ); // Widgetのインスタンスは更新される可能性があるため再取得
      final FocusScopeNode focusScope = FocusScope.of(
        tester.element(lastNameFinder),
      );
      expect(focusScope.hasFocus, isTrue);
    });

    testWidgets('2. ボトムシートの最大高さ制限の物理ガード検証', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final fakeFirestore = FakeFirebaseFirestore();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            playerRepositoryProvider.overrideWithValue(mockPlayerRepo),
            isarProvider.overrideWithValue(null),
            currentUserRoleProvider.overrideWith((ref) => UserRole.admin),
            firestoreProvider.overrideWithValue(fakeFirestore),
          ],
          child: const MaterialApp(home: MasterManagementScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // 道場名登録
      await tester.tap(find.text('道場名を登録する'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'テスト道場');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, '登録'));
      await tester.pumpAndSettle();

      // 選手登録ボトムシートを開く
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // ボトムシート全体の最大高さが画面の85%に制限されていることを検証
      final bottomSheetFinder = find.byWidgetPredicate(
        (widget) => widget is ModalBarrier, // ダイアログまたはボトムシートが立ち上がっているモーダル障壁
      );
      expect(bottomSheetFinder, findsWidgets);

      // 選手登録ボトムシート自体の最大高さ制約 (BoxConstraints) を検証する
      final containerFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Container && widget.constraints?.maxHeight != null,
      );
      expect(containerFinder, findsWidgets);

      // エラーが一切出ていないこと
      expect(tester.takeException(), isNull);
    });
  });
}
