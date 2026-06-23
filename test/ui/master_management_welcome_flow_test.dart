import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/admin/presentation/screens/master_management_screen.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/widgets/glass_button.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
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

  group('🛡️ MasterManagementScreen Welcome Flow Tests', () {
    testWidgets(
      '初期状態で道場名登録ボタンが表示され、登録後に選手登録ボタンへ切り替わり、organizationが正しくインジェクションされること',
      (WidgetTester tester) async {
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

        // 1. 初期道場名が登録されていない時のEmpty Stateを確認
        expect(
          find.text('選手を追加する前に、まずはあなたたちの道場名・学校名を登録することから始めましょう！'),
          findsOneWidget,
        );

        final registerOrgButton = find.byType(GlassButton);
        expect(registerOrgButton, findsOneWidget);
        expect(find.text('道場名を登録する'), findsOneWidget);

        // 2. 「道場名を登録する」ボタンをタップしてボトムシートを開く
        await tester.tap(registerOrgButton);
        await tester.pumpAndSettle();

        expect(find.text('道場名・学校名の登録'), findsOneWidget);

        // 3. 道場名を入力して「登録」ボタンをタップ
        final textFieldFinder = find.byType(TextField);
        expect(textFieldFinder, findsOneWidget);
        await tester.enterText(textFieldFinder, 'テスト道場');
        await tester.pumpAndSettle();

        final submitBtn = find.widgetWithText(ElevatedButton, '登録');
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();

        // 4. 空の一覧画面（土台）が立ち上がり、道場名「テスト道場」が表示されていることを確認
        expect(find.text('テスト道場'), findsOneWidget);
        expect(find.byIcon(Icons.account_balance), findsOneWidget);

        // 5. 右下のFAB（選手を追加）をタップして選手登録ボトムシートを開く
        final fabFinder = find.byType(FloatingActionButton);
        expect(fabFinder, findsOneWidget);
        await tester.tap(fabFinder);
        await tester.pumpAndSettle();

        expect(find.text('新しい選手を登録'), findsOneWidget);

        // 6. 選手情報を入力して保存
        final nameFields = find.byType(TextField);
        // 選手登録ボトムシートには、よみがな(せい/めい)と名字/名前の計4つのTextFieldがある
        expect(nameFields, findsNWidgets(4));

        // 名字/名前フィールドに文字を入力（TextFieldの3番目と4番目が名字と名前）
        await tester.enterText(nameFields.at(2), '道上');
        await tester.enterText(nameFields.at(3), '太郎');
        await tester.pumpAndSettle();

        final savePlayerBtn = find.widgetWithText(ElevatedButton, '保存して登録');
        await tester.tap(savePlayerBtn);
        await tester.pumpAndSettle();

        // 7. addPlayerの代わりにFirestoreへ直接ドキュメントが追加され、かつorganizationフィールドに「テスト道場」が注入されていることを検証
        final playersSnap = await fakeFirestore
            .collection('organizations')
            .doc('default_dojo_room')
            .collection('players')
            .get();
        expect(playersSnap.docs.length, 1);
        final playerMap = playersSnap.docs.first.data();
        expect(playerMap['lastName'], '道上');
        expect(playerMap['firstName'], '太郎');
        expect(playerMap['organization'], 'テスト道場');
      },
    );

    testWidgets('道場名登録前にFABをタップした際、先行入力強制ダイアログが表示され、ジャンプしてボトムシートが開くこと', (
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

      // 1. FAB (選手を追加) を探してタップ
      final fabFinder = find.byType(FloatingActionButton);
      expect(fabFinder, findsOneWidget);
      await tester.tap(fabFinder);
      await tester.pumpAndSettle();

      // 2. 先行入力強制ダイアログが表示されていることを検証
      expect(find.text('道場名の登録が必要です'), findsOneWidget);
      expect(find.text('選手を登録する前に、まずは道場名・学校名を登録してください。'), findsOneWidget);

      // 3. 「道場名を入力」アクションをタップしてボトムシートにフォーカスが移ることを検証
      final actionBtn = find.widgetWithText(ElevatedButton, '道場名を入力');
      expect(actionBtn, findsOneWidget);
      await tester.tap(actionBtn);
      await tester.pumpAndSettle();

      // ダイアログは閉じされ、道場名登録ボトムシートが開いていること
      expect(find.text('道場名の登録が必要です'), findsNothing);
      expect(find.text('道場名・学校名の登録'), findsOneWidget);
    });

    group('iOSカプセルスタイル検証', () {
      testWidgets('Empty UIの登録ボタンが幅240に制限されていること', (WidgetTester tester) async {
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

        // SizedBox (width: 240) の存在確認
        final sizedBoxFinder = find.descendant(
          of: find.byType(Column),
          matching: find.byWidgetPredicate(
            (widget) => widget is SizedBox && widget.width == 240,
          ),
        );
        expect(sizedBoxFinder, findsOneWidget);
      });
    });
  });
}
