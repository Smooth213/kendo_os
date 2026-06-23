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
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';

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

  group('🛡️ MasterManagementScreen Multi-Tenant Sync Tests', () {
    testWidgets('1. 道場ID（テナント）切り替え時のリッスンパス動的追従アサート', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final fakeFirestore = FakeFirebaseFirestore();

      // test202 側の道場名と選手データを準備
      await fakeFirestore.collection('organizations').doc('test202').set({
        'name': '第二道場',
      });
      await fakeFirestore
          .collection('organizations')
          .doc('test202')
          .collection('players')
          .doc('p202_1')
          .set({
            'lastName': 'テスト',
            'firstName': '次郎',
            'lastNameKana': 'てすと',
            'firstNameKana': 'じろう',
            'grade': 3,
            'gender': '男子',
            'isBeginner': false,
            'organization': '第二道場',
          });

      // test201 側の道場名と選手データを準備
      await fakeFirestore.collection('organizations').doc('test201').set({
        'name': '第一道場',
      });
      await fakeFirestore
          .collection('organizations')
          .doc('test201')
          .collection('players')
          .doc('p201_1')
          .set({
            'lastName': 'テスト',
            'firstName': '太郎',
            'lastNameKana': 'てすと',
            'firstNameKana': 'たろう',
            'grade': 1,
            'gender': '男子',
            'isBeginner': false,
            'organization': '第一道場',
          });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            playerRepositoryProvider.overrideWithValue(mockPlayerRepo),
            isarProvider.overrideWithValue(null),
            currentUserRoleProvider.overrideWith((ref) => UserRole.admin),
            firestoreProvider.overrideWithValue(fakeFirestore),
            currentDojoIdProvider.overrideWith((ref) => 'test202'),
          ],
          child: const MaterialApp(home: MasterManagementScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // 初期状態で test202 (第二道場) のデータが表示されているか検証
      expect(find.text('第二道場'), findsOneWidget);
      expect(find.text('テスト 次郎'), findsOneWidget);
      // test201 (第一道場) のデータが混入していないか検証
      expect(find.text('第一道場'), findsNothing);
      expect(find.text('テスト 太郎'), findsNothing);

      // 動的に currentDojoIdProvider の状態を 'test201' に切り替える
      final context = tester.element(find.byType(MasterManagementScreen));
      final container = ProviderScope.containerOf(context);
      container.read(currentDojoIdProvider.notifier).state = 'test201';

      // ストリームが動的に再着火され、画面が更新されるのを待つ
      await tester.pumpAndSettle();

      // test201 (第一道場) の選手リストに入れ替わっていることを検証
      expect(find.text('第一道場'), findsOneWidget);
      expect(find.text('テスト 太郎'), findsOneWidget);
      // test202 (第二道場) のデータが表示から消えていることを検証
      expect(find.text('第二道場'), findsNothing);
      expect(find.text('テスト 次郎'), findsNothing);
    });

    testWidgets('2. 選手登録時（organizationフィールド）のクラウド完全一致マージ検証', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final fakeFirestore = FakeFirebaseFirestore();

      // 初期道場を設定しておく
      await fakeFirestore.collection('organizations').doc('test202').set({
        'name': 'テスト道場',
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            playerRepositoryProvider.overrideWithValue(mockPlayerRepo),
            isarProvider.overrideWithValue(null),
            currentUserRoleProvider.overrideWith((ref) => UserRole.admin),
            firestoreProvider.overrideWithValue(fakeFirestore),
            currentDojoIdProvider.overrideWith((ref) => 'test202'),
          ],
          child: const MaterialApp(home: MasterManagementScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // 空の一覧画面から「選手を追加」ボタンをタップ
      final fabFinder = find.byType(FloatingActionButton);
      expect(fabFinder, findsOneWidget);
      await tester.tap(fabFinder);
      await tester.pumpAndSettle();

      expect(find.text('新しい選手を登録'), findsOneWidget);

      final nameFields = find.byType(TextField);
      expect(nameFields, findsNWidgets(4));

      // 名字と名前を入力
      await tester.enterText(nameFields.at(2), '道上');
      await tester.enterText(nameFields.at(3), '太郎');
      await tester.pumpAndSettle();

      // 「保存して登録」ボタンをタップ
      final saveBtn = find.widgetWithText(ElevatedButton, '保存して登録');
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Firestore の organizations/test202/players にドキュメントが追加されているか検証
      final playersSnap = await fakeFirestore
          .collection('organizations')
          .doc('test202')
          .collection('players')
          .get();

      expect(playersSnap.docs.length, 1);
      final addedPlayer = playersSnap.docs.first.data();
      expect(addedPlayer['lastName'], '道上');
      expect(addedPlayer['firstName'], '太郎');
      // organization フィールドに 'テスト道場' が正しく焼き付けられていることを検証
      expect(addedPlayer['organization'], 'テスト道場');
    });
  });
}
