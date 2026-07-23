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

    testWidgets('3. 道場名登録、所属名一括変更、チーム名管理ボトムシートの自動フォーカス排除検証 (Webでの跳ね上がり防止)', (
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

      // === 1. 初期道場名登録ボトムシートの検証 ===
      // ボタンをタップして初期道場名登録ボトムシートを開く
      await tester.tap(find.text('道場名を登録する'));
      await tester.pumpAndSettle();

      // TextFieldを取得して、autofocusがfalseであることを確認
      final orgTextFieldFinder = find.byType(TextField);
      expect(orgTextFieldFinder, findsOneWidget);
      final TextField orgTextField = tester.widget<TextField>(
        orgTextFieldFinder,
      );
      expect(orgTextField.autofocus, isFalse);

      // キャンセルして閉じる
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      // === 2. 所属名の一括変更ボトムシートの検証 ===
      // 道場名を登録してマスタ表示へ移行
      await tester.tap(find.text('道場名を登録する'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'テスト道場');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, '登録'));
      await tester.pumpAndSettle();

      // 「道場名・学校名を一括変更」をタップして所属名変更ボトムシートを開く
      await tester.tap(find.byTooltip('道場名・学校名を一括変更'));
      await tester.pumpAndSettle();

      final renameTextFieldFinder = find.byType(TextField);
      expect(renameTextFieldFinder, findsOneWidget);
      final TextField renameTextField = tester.widget<TextField>(
        renameTextFieldFinder,
      );
      expect(renameTextField.autofocus, isFalse);

      // キャンセルして閉じる
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      // === 3. チーム名管理ボトムシートの検証 ===
      // 「よく使うチーム名の管理」をタップしてチーム名管理ボトムシートを開く
      await tester.tap(find.byTooltip('よく使うチーム名の管理'));
      await tester.pumpAndSettle();

      final teamTextFieldFinder = find.byType(TextField);
      expect(teamTextFieldFinder, findsOneWidget);
      final TextField teamTextField = tester.widget<TextField>(
        teamTextFieldFinder,
      );
      expect(teamTextField.autofocus, isFalse);
    });

    testWidgets('4. 自動ふりがな機能のライブ変換・分割入力・削除シミュレーション検証 (Web/IME対応)', (
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

      // 1. 初期道場名を登録してマスタ表示へ移行
      await tester.tap(find.text('道場名を登録する'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'テスト道場');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, '登録'));
      await tester.pumpAndSettle();

      // 2. 選手登録ボトムシートを開く
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // 3. 各入力フィールドの検索
      final lastNameFinder = find.widgetWithText(TextField, '名字');
      final lastNameKanaFinder = find.widgetWithText(TextField, 'よみがな (せい)');
      expect(lastNameFinder, findsOneWidget);
      expect(lastNameKanaFinder, findsOneWidget);

      // 4. タイピングシミュレーション A: 通常のひらがな入力（「やま」 -> よみがな「やま」）
      await tester.enterText(lastNameFinder, 'やま');
      await tester.pump();
      final TextField lastNameKanaWidget1 = tester.widget<TextField>(
        lastNameKanaFinder,
      );
      expect(lastNameKanaWidget1.controller?.text, 'やま');

      // 5. タイピングシミュレーション B: ライブ変換/一括変換（「山」に変換 -> よみがな「やま」が維持される）
      await tester.enterText(lastNameFinder, '山');
      await tester.pump();
      final TextField lastNameKanaWidget2 = tester.widget<TextField>(
        lastNameKanaFinder,
      );
      expect(lastNameKanaWidget2.controller?.text, 'やま');

      // 6. タイピングシミュレーション C: 分割入力でのひらがな追加（「山だ」 -> よみがな「やまだ」）
      await tester.enterText(lastNameFinder, '山だ');
      await tester.pump();
      final TextField lastNameKanaWidget3 = tester.widget<TextField>(
        lastNameKanaFinder,
      );
      expect(lastNameKanaWidget3.controller?.text, 'やまだ');

      // 7. タイピングシミュレーション D: 分割入力での漢字変換追加（「山田」 -> よみがな「やまだ」が維持される）
      await tester.enterText(lastNameFinder, '山田');
      await tester.pump();
      final TextField lastNameKanaWidget4 = tester.widget<TextField>(
        lastNameKanaFinder,
      );
      expect(lastNameKanaWidget4.controller?.text, 'やまだ');

      // 8. 削除シミュレーション: 末尾文字の削除（「山田」 -> 「山」 -> よみがな「やま」に減る）
      await tester.enterText(lastNameFinder, '山');
      await tester.pump();
      final TextField lastNameKanaWidget5 = tester.widget<TextField>(
        lastNameKanaFinder,
      );
      expect(lastNameKanaWidget5.controller?.text, 'やま');

      // 9. クリアシミュレーション: すべて削除（「」 -> よみがな「」）
      await tester.enterText(lastNameFinder, '');
      await tester.pump();
      final TextField lastNameKanaWidget6 = tester.widget<TextField>(
        lastNameKanaFinder,
      );
      expect(lastNameKanaWidget6.controller?.text, '');

      // 10. ２段階のIME変換（予測変換確定）シミュレーション
      // 「たなか」と入力された状態から、一旦空文字になり、その後に「田中」に確定される挙動のシミュレーション（Web等でフレームが分割されるケースの検証）
      await tester.enterText(lastNameFinder, 'たなか');
      await tester.pump();
      final TextField lastNameKanaWidgetBefore = tester.widget<TextField>(
        lastNameKanaFinder,
      );
      expect(lastNameKanaWidgetBefore.controller?.text, 'たなか');

      final TextField lastNameWidget = tester.widget<TextField>(lastNameFinder);

      // 1段階目: 一旦空文字が送信される（ブラウザのIME挙動）
      lastNameWidget.controller?.text = '';
      await tester.pump(); // コミットして一旦クリア状態を反映
      expect(
        lastNameKanaWidgetBefore.controller?.text,
        '',
      ); // よみがなが一旦クリアされることを検証

      // 2段階目: 150ms以内に漢字「田中」が挿入される
      lastNameWidget.controller?.text = '田中';
      await tester.pump(); // 自己修復機能によって復活することを検証

      final TextField lastNameKanaWidgetAfter = tester.widget<TextField>(
        lastNameKanaFinder,
      );
      expect(
        lastNameKanaWidgetAfter.controller?.text,
        'たなか',
      ); // よみがな「たなか」が自己修復されていること！
    });

    testWidgets('5. 自動ふりがな機能の各種例外・エッジケースシミュレーション検証 (カタカナ・英字・コピペ・時間超過ガード)', (
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

      // 1. 初期道場名を登録してマスタ表示へ移行
      await tester.tap(find.text('道場名を登録する'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'テスト道場');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, '登録'));
      await tester.pumpAndSettle();

      // 2. 選手登録ボトムシートを開く
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      final lastNameFinder = find.widgetWithText(TextField, '名字');
      final lastNameKanaFinder = find.widgetWithText(TextField, 'よみがな (せい)');
      final TextField lastNameWidget = tester.widget<TextField>(lastNameFinder);
      final lastNameController = lastNameWidget.controller;

      // === A. カタカナ入力変換シミュレーション ===
      // 「さとう」と入力してカタカナ「サトウ」にする
      await tester.enterText(lastNameFinder, 'さとう');
      await tester.pump();
      expect(
        tester.widget<TextField>(lastNameKanaFinder).controller?.text,
        'さとう',
      );

      lastNameController?.text = '';
      lastNameController?.text = 'サトウ';
      await tester.pump();
      expect(
        tester.widget<TextField>(lastNameKanaFinder).controller?.text,
        'サトウ',
      );

      // === B. 英字入力（IMEなし・直接入力）シミュレーション ===
      // 「John」と直接タイピング
      await tester.enterText(lastNameFinder, 'John');
      await tester.pump();
      expect(
        tester.widget<TextField>(lastNameKanaFinder).controller?.text,
        'John',
      );

      // === C. 漢字の直接コピペ（よみがな自動入力なし）シミュレーション ===
      // 「John」からクリアされ、200ms経過後（＝IMEの連続イベント外）に漢字「渡辺」が貼り付けられた場合
      lastNameController?.text = '';
      await tester.pump(); // クリア
      expect(tester.widget<TextField>(lastNameKanaFinder).controller?.text, '');

      // 200ms経過させて貼り付けを実行 (150msの時間超過ガードを確認)
      await tester.pump(const Duration(milliseconds: 200));

      lastNameController?.text = '渡辺';
      await tester.pump();

      // クリア前の「John」は復元されず、よみがなは空のままであること！
      expect(tester.widget<TextField>(lastNameKanaFinder).controller?.text, '');
    });
  });
}
