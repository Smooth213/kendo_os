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

  group(
    '🛡️ MasterManagementScreen Welcome & Initial Flow Integration Tests',
    () {
      testWidgets('1. 完全初期状態（選手0人・道場名未入力）：Empty UI案内文および幅240のカプセルボタン描画検証', (
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

        // 案内文の検証
        expect(
          find.text('選手を追加する前に、まずはあなたたちの道場名・学校名を登録することから始めましょう！'),
          findsOneWidget,
        );

        // カプセルボタン（幅240）の検証
        final sizedBoxFinder = find.byWidgetPredicate(
          (widget) => widget is SizedBox && widget.width == 240,
        );
        expect(sizedBoxFinder, findsOneWidget);

        final glassBtn = find.descendant(
          of: sizedBoxFinder,
          matching: find.byType(GlassButton),
        );
        expect(glassBtn, findsOneWidget);
        expect(find.text('道場名を登録する'), findsOneWidget);
      });

      testWidgets(
        '2. 道場名登録後：Empty UIバイパスと空一覧画面へのダイレクト遷移検証（StateErrorクラッシュ防止）',
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

          // 道場名ボトムシートを開く
          await tester.tap(find.text('道場名を登録する'));
          await tester.pumpAndSettle();

          // TextFieldに入力して登録
          await tester.enterText(find.byType(TextField), 'テスト道場');
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(ElevatedButton, '登録'));
          await tester.pumpAndSettle();

          // アサーション：エラーがなく描画されていることを検証
          expect(tester.takeException(), isNull);

          // Empty UI案内文が完全に消滅していることを検証
          expect(
            find.text('選手を追加する前に、まずはあなたたちの道場名・学校名を登録することから始めましょう！'),
            findsNothing,
          );

          // ヘッダーに登録した道場名が表示されていることを検証
          expect(find.text('テスト道場'), findsOneWidget);
          expect(find.byIcon(Icons.account_balance), findsOneWidget);

          // セグメントボタン等の土台コンポーネントが描画されていることを検証
          expect(find.text('学年別'), findsOneWidget);
          expect(find.text('カテゴリ別'), findsOneWidget);
        },
      );

      testWidgets('3. 「保存して登録」ボタンの個別純白カラー ＆ 太字仕様検証', (
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

        // 道場名を登録して一覧画面を立ち上げる
        await tester.tap(find.text('道場名を登録する'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'テスト道場');
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(ElevatedButton, '登録'));
        await tester.pumpAndSettle();

        // FAB「選手を追加」をタップ
        final fabFinder = find.byType(FloatingActionButton);
        await tester.tap(fabFinder);
        await tester.pumpAndSettle();

        // 「保存して登録」ボタンのアイコン（Icons.save）色検証
        final iconFinder = find.byIcon(Icons.save);
        expect(iconFinder, findsOneWidget);
        final Icon iconWidget = tester.widget<Icon>(iconFinder);
        expect(iconWidget.color, Colors.white);

        // 「保存して登録」ボタンのテキスト色と太字の検証
        final labelFinder = find.text('保存して登録');
        expect(labelFinder, findsOneWidget);
        final Text labelText = tester.widget<Text>(labelFinder);
        expect(labelText.style?.color, Colors.white);
        expect(labelText.style?.fontWeight, FontWeight.bold);
      });
    },
  );
}
