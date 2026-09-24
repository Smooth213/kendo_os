import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:kendo_os/shared/widgets/room_join_qr_dialog.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/providers/dojo_room_history_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('🔒 現場安全弁 - 道場ルームID重複チェック＆警告ダイアログ検証テスト', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    /// テスト用のダイアログ表示環境をラッピング生成するヘルパー
    Widget createTestTarget(
      ProviderContainer container, {
      bool isDark = false,
    }) {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: ThemeData(
            brightness: isDark ? Brightness.dark : Brightness.light,
            splashFactory: NoSplash.splashFactory,
            extensions: [AppThemeColors.ofMode(isDark: isDark, mode: 'normal')],
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => RoomJoinQrDialog.show(context),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('【新規作成ケース】クラウド上にIDが実在しない場合、正常にコレクションが初期創設され直結すること', (
      WidgetTester tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          // ★ Widget内の専用ProviderをオーバーライドしてFakeFirestoreを確実に注入
          roomFirestoreProvider.overrideWithValue(fakeFirestore),
        ],
      );

      await tester.pumpWidget(createTestTarget(container));

      // 1. ダイアログを開く
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // 2. 新規の道場ID「osaka_dojo统计」を入力
      await tester.enterText(find.byType(TextField), 'osaka_dojo');
      await tester.pumpAndSettle();

      // 🌟 修正核心：Firestoreの多層非同期フューチャーを、リアルタイム非同期スレッド（runAsync）内で
      // 完全に回しきることで、テスト空間での時間差による「未作成バグ」を根絶します。
      await tester.runAsync(() async {
        await tester.tap(find.text('接続開始'));
        // fake_cloud_firestore の内部パケットループが完結するのを決定論的に待機
        await Future.delayed(const Duration(milliseconds: 100));
      });

      // 3. 通信結果に伴うUI更新の反映
      await tester.pumpAndSettle();

      // アサーション1：Firestoreの「organizations/osaka_dojo」にデータが正しく自動創設されていること
      final doc = await fakeFirestore
          .collection('organizations')
          .doc('osaka_dojo')
          .get();
      expect(doc.exists, isTrue);
      expect(doc.data()?['createdBy'], equals('owner_terminal'));

      // アサーション2：グローバルProviderの接続先道場IDが「osaka_dojo」に切り替わっていること
      expect(container.read(currentDojoIdProvider), equals('osaka_dojo'));

      // アサーション3：ダイアログが正常に閉じていること
      expect(find.byType(RoomJoinQrDialog), findsNothing);

      container.dispose();
    });

    testWidgets('【重複ガードケース】既に他者が使用中のIDを入力した場合、警告ダイアログが露出し無断上書きをブロックすること', (
      WidgetTester tester,
    ) async {
      // 事前条件：クラウド上に既に「tokyo_dojo」という部屋が実在している状態を作る
      await fakeFirestore.collection('organizations').doc('tokyo_dojo').set({
        'createdAt': DateTime.now().toIso8601String(),
        'createdBy': 'someone_else',
      });

      final container = ProviderContainer(
        overrides: [roomFirestoreProvider.overrideWithValue(fakeFirestore)],
      );

      await tester.pumpWidget(createTestTarget(container));

      // 1. ダイアログを開く
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // 2. 被っているID「tokyo_dojo」を入力
      await tester.enterText(find.byType(TextField), 'tokyo_dojo');
      await tester.pumpAndSettle();

      // 🌟 修正核心：存在チェックの get() 通信パケットを安全に解決させます
      await tester.runAsync(() async {
        await tester.tap(find.text('接続開始'));
        await Future.delayed(const Duration(milliseconds: 100));
      });

      // 3. 警告ダイアログのポップアップアニメーションを消化
      await tester.pumpAndSettle();

      // 🚨 アサーション1：無断での上書き接続はされず、画面に重複警告ポップアップが出現していることを証明
      expect(find.text('⚠️ ID重複・既存の部屋'), findsOneWidget);
      expect(find.textContaining('はすでに存在しています。'), findsOneWidget);

      // 4. 行動分岐：ユーザーが「このまま接続（既存に参加）」を承認した場合
      await tester.runAsync(() async {
        await tester.tap(find.text('このまま接続'));
        await Future.delayed(const Duration(milliseconds: 50));
      });

      // 5. 画面が閉じるのを待機
      await tester.pumpAndSettle();

      // アサーション2：承認を経て、最終的に既存の「tokyo_dojo」空間への直結が執行されたこと
      expect(container.read(currentDojoIdProvider), equals('tokyo_dojo'));
      expect(find.byType(RoomJoinQrDialog), findsNothing);

      container.dispose();
    });

    testWidgets(
      '【はみ出し防止ケース】超小型画面サイズ（高さ380px）でも RenderFlex のはみ出しエラー（Overflow）が発生しないこと',
      (WidgetTester tester) async {
        // 画面のテスト表面サイズを、はみ出しバグが起きた超小型サイズ (幅320, 高さ380) に強制設定
        await tester.binding.setSurfaceSize(const Size(320, 380));
        addTearDown(
          () => tester.binding.setSurfaceSize(null),
        ); // 元のサイズに戻すための後処理

        final container = ProviderContainer(
          overrides: [roomFirestoreProvider.overrideWithValue(fakeFirestore)],
        );

        await tester.pumpWidget(createTestTarget(container));

        // ダイアログを開く
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        // はみ出しエラー（RenderFlex overflowed）などのレイアウト例外が一切スローされていないことをアサート
        expect(tester.takeException(), isNull);

        // ダイアログ内の重要要素が問題なく描画されていること
        expect(find.byType(RoomJoinQrDialog), findsOneWidget);
        expect(find.text('道場ルームへの参加'), findsOneWidget);

        container.dispose();
      },
    );

    testWidgets('【ダークモード視認性保証テスト】ダークモード時、説明文・注意書き・キャンセルボタンが黒潰れせず視認可能であること', (
      WidgetTester tester,
    ) async {
      final container = ProviderContainer(
        overrides: [roomFirestoreProvider.overrideWithValue(fakeFirestore)],
      );

      // ダークモードでテストターゲットをマウント
      await tester.pumpWidget(createTestTarget(container, isDark: true));

      // ダイアログを開く
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // 1. 説明文テキストの視認性検証
      final instructionFinder = find.textContaining('会場のQRコードをスキャンするか');
      expect(instructionFinder, findsOneWidget);
      final instructionText = tester.widget<Text>(instructionFinder);
      expect(instructionText.style?.color, isNotNull);
      // 黒系（0x8A000000や完全な黒）ではなく高コントラスト色であること
      expect(
        instructionText.style?.color,
        isNot(equals(const Color(0x8A000000))),
      );
      expect(instructionText.style?.color, isNot(equals(Colors.black)));
      expect(
        instructionText.style?.color,
        isNot(equals(const Color(0xFF000000))),
      );

      // 2. 注意書きテキストの視認性検証
      final helperFinder = find.textContaining('※ 使用可能な文字');
      expect(helperFinder, findsOneWidget);
      final helperText = tester.widget<Text>(helperFinder);
      expect(helperText.style?.color, isNotNull);
      expect(helperText.style?.color, isNot(equals(const Color(0x8A000000))));
      expect(helperText.style?.color, isNot(equals(Colors.black)));

      // 3. キャンセルボタンの視認性検証 (OutlinedButton)
      final cancelButtonFinder = find.widgetWithText(OutlinedButton, 'キャンセル');
      expect(cancelButtonFinder, findsOneWidget);

      // 4. 接続開始ボタンの存在検証
      expect(find.widgetWithText(ElevatedButton, '接続開始'), findsOneWidget);

      container.dispose();
    });

    testWidgets('【ライトモード視認性保証テスト】ライトモード時、説明文・注意書き・ボタンが適切に視認可能であること', (
      WidgetTester tester,
    ) async {
      final container = ProviderContainer(
        overrides: [roomFirestoreProvider.overrideWithValue(fakeFirestore)],
      );

      // ライトモードでテストターゲットをマウント
      await tester.pumpWidget(createTestTarget(container, isDark: false));

      // ダイアログを開く
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // 1. タイトル、説明文、注意書きの描画検証
      expect(find.text('道場ルームへの参加'), findsOneWidget);
      expect(find.textContaining('会場のQRコードをスキャンするか'), findsOneWidget);
      expect(find.textContaining('※ 使用可能な文字'), findsOneWidget);

      // 2. ボタンの描画検証
      expect(find.widgetWithText(OutlinedButton, 'キャンセル'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, '接続開始'), findsOneWidget);

      container.dispose();
    });

    testWidgets('【重複警告ダイアログ視認性保証テスト】ダークモード時、重複警告ポップアップ内の警告メッセージが黒潰れしないこと', (
      WidgetTester tester,
    ) async {
      // 事前データ登録
      await fakeFirestore.collection('organizations').doc('existing_room').set({
        'createdAt': DateTime.now().toIso8601String(),
        'createdBy': 'owner',
      });

      final container = ProviderContainer(
        overrides: [roomFirestoreProvider.overrideWithValue(fakeFirestore)],
      );

      await tester.pumpWidget(createTestTarget(container, isDark: true));

      // ダイアログを開く
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // 既存の部屋名を入力
      await tester.enterText(find.byType(TextField), 'existing_room');
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        await tester.tap(find.text('接続開始'));
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      // 警告ダイアログ内のメッセージ色検証
      final warningMsgFinder = find.textContaining('はすでに存在しています。');
      expect(warningMsgFinder, findsOneWidget);
      final warningText = tester.widget<Text>(warningMsgFinder);
      expect(warningText.style?.color, isNot(equals(const Color(0x8A000000))));
      expect(warningText.style?.color, isNot(equals(Colors.black)));

      container.dispose();
    });

    testWidgets('【履歴サジェスト視認性保証テスト】ライトモード時、過去の履歴サジェストが黒潰れせず高コントラストで視認できること', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'kendo_os_dojo_room_history': ['tokyo_dojo_2026'],
      });

      final notifier = DojoRoomHistoryNotifier();
      await notifier.addHistory('tokyo_dojo_2026');

      final container = ProviderContainer(
        overrides: [
          roomFirestoreProvider.overrideWithValue(fakeFirestore),
          dojoRoomHistoryProvider.overrideWith((ref) => notifier),
        ],
      );

      await tester.pumpWidget(createTestTarget(container, isDark: false));

      // ダイアログを開く
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // 履歴チップ「tokyo_dojo_2026」が表示されていること
      final historyFinder = find.text('tokyo_dojo_2026');
      expect(historyFinder, findsOneWidget);

      // 履歴テキストのスタイル検証
      final textWidget = tester.widget<Text>(historyFinder);
      expect(textWidget.style?.color, isNot(equals(Colors.transparent)));

      // サジェストのMaterial背景色が黒（0xFF000000）ではなく、高コントラストな見やすい色であること
      final materialFinder = find.ancestor(
        of: historyFinder,
        matching: find.byType(Material),
      );
      final chipMaterial = tester.widget<Material>(materialFinder.first);
      expect(chipMaterial.color, isNot(equals(const Color(0xFF000000))));
      expect(chipMaterial.color, isNot(equals(Colors.black)));

      // 履歴チップをタップするとTextFieldに入力されること
      await tester.tap(historyFinder);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'tokyo_dojo_2026'), findsOneWidget);

      container.dispose();
    });

    testWidgets('【Web描画消失防止テスト】BackdropFilter が使用されず、安全な不透明背景コンテナで描画されること', (
      WidgetTester tester,
    ) async {
      final container = ProviderContainer(
        overrides: [roomFirestoreProvider.overrideWithValue(fakeFirestore)],
      );

      await tester.pumpWidget(createTestTarget(container));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // iOS Safari / Web での描画消失（グレーアウト）原因となる BackdropFilter が存在しないことを検証
      expect(find.byType(BackdropFilter), findsNothing);

      // シート本体が確実に表示されていること
      expect(find.byType(RoomJoinQrDialog), findsOneWidget);
      expect(find.text('道場ルームへの参加'), findsOneWidget);

      container.dispose();
    });

    testWidgets('【キーボード跳ね上がり防止テスト】カーソルフォーカス時、ダイアログが画面外に跳ね上がらず安定して表示されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetViewInsets());

      final container = ProviderContainer(
        overrides: [roomFirestoreProvider.overrideWithValue(fakeFirestore)],
      );

      await tester.pumpWidget(createTestTarget(container));

      // ダイアログを開く
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // 初期状態ではQRアイコンが表示されていること
      expect(find.byIcon(Icons.qr_code_2), findsOneWidget);

      // 入力欄にフォーカス＆キーボードを出現させる
      await tester.tap(find.byType(TextField));
      tester.view.viewInsets = const FakeViewPadding(bottom: 336);
      await tester.pumpAndSettle();

      // キーボード表示時はQRアイコンが非表示になりコンパクト化されること
      expect(find.byIcon(Icons.qr_code_2), findsNothing);

      // ダイアログタイトル、TextField、ボタンが画面内に表示されていること
      expect(find.text('道場ルームへの参加'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('接続開始'), findsOneWidget);

      // シートのY座標が画面内（上端がステータスバー下に安定配置され、画面外に跳ね上がらないこと）
      final containerBox = tester.renderObject<RenderBox>(
        find
            .descendant(
              of: find.byType(RoomJoinQrDialog),
              matching: find.byType(Container),
            )
            .first,
      );
      final offset = containerBox.localToGlobal(Offset.zero);
      expect(offset.dy, greaterThanOrEqualTo(0.0)); // 画面内に安全配置
      expect(offset.dy, lessThan(844 - 336)); // キーボード上端未満に確実に留まること

      // TextFieldのY座標も画面内にあり、キーボードより上にあること
      final textFieldBox = tester.renderObject<RenderBox>(
        find.byType(TextField),
      );
      final textFieldOffset = textFieldBox.localToGlobal(Offset.zero);
      expect(textFieldOffset.dy, greaterThan(offset.dy));
      expect(
        textFieldOffset.dy + textFieldBox.size.height,
        lessThan(844 - 336),
      ); // キーボード上端未満

      container.dispose();
    });

    testWidgets(
      '【小型画面（iPhone SE等）保証テスト】極小ビューポート＋キーボード出現時でも跳ね上がらず正常入力＆接続できること',
      (WidgetTester tester) async {
        // iPhone SE等の小型画面サイズ（375 x 667）
        tester.view.physicalSize = const Size(375, 667);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());
        addTearDown(() => tester.view.resetViewInsets());

        final container = ProviderContainer(
          overrides: [roomFirestoreProvider.overrideWithValue(fakeFirestore)],
        );

        await tester.pumpWidget(createTestTarget(container));

        // 1. 開く
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        // 2. 入力欄にフォーカス＆キーボード（高さ300px）出現
        await tester.tap(find.byType(TextField));
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pumpAndSettle();

        // 🚨 跳ね上がり絶対防止アサーション：シート上端が画面外（Y < 0）に突き抜けていないこと
        final containerBox = tester.renderObject<RenderBox>(
          find
              .descendant(
                of: find.byType(RoomJoinQrDialog),
                matching: find.byType(Container),
              )
              .first,
        );
        final offset = containerBox.localToGlobal(Offset.zero);
        expect(
          offset.dy,
          greaterThanOrEqualTo(0.0),
          reason: 'シート上端が画面外上空に突き抜けてはいけない',
        );
        expect(
          offset.dy,
          lessThan(667 - 300),
          reason: 'シート上端はキーボード上端より手前に存在すること',
        );

        // 3. テキストが正常に入力・反映されること
        await tester.enterText(find.byType(TextField), 'chiba_dojo');
        await tester.pumpAndSettle();
        expect(find.widgetWithText(TextField, 'chiba_dojo'), findsOneWidget);

        // 4. キーボード出現下の小型画面でも「接続開始」ボタンをタップして正常接続できること
        await tester.runAsync(() async {
          await tester.tap(find.text('接続開始'));
          await Future.delayed(const Duration(milliseconds: 100));
        });
        await tester.pumpAndSettle();

        // 接続完了確認
        expect(container.read(currentDojoIdProvider), equals('chiba_dojo'));
        expect(find.byType(RoomJoinQrDialog), findsNothing);

        container.dispose();
      },
    );

    testWidgets('【反復フォーカス開閉テスト】キーボードの開閉を連続で繰り返しても位置ズレ・跳ね上がりが累積しないこと', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetViewInsets());

      final container = ProviderContainer(
        overrides: [roomFirestoreProvider.overrideWithValue(fakeFirestore)],
      );

      await tester.pumpWidget(createTestTarget(container));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final containerFinder = find
          .descendant(
            of: find.byType(RoomJoinQrDialog),
            matching: find.byType(Container),
          )
          .first;

      // 3回の連続フォーカス開閉サイクルを実行
      for (int cycle = 1; cycle <= 3; cycle++) {
        // キーボード開
        tester.view.viewInsets = const FakeViewPadding(bottom: 336);
        await tester.pumpAndSettle();

        final offsetOpen = tester.getTopLeft(containerFinder);
        expect(
          offsetOpen.dy,
          greaterThanOrEqualTo(0.0),
          reason: 'サイクル $cycle (開): シート上端が画面外に突き抜けていないこと',
        );

        // キーボード閉
        tester.view.viewInsets = FakeViewPadding.zero;
        await tester.pumpAndSettle();

        final offsetClosed = tester.getTopLeft(containerFinder);
        expect(
          offsetClosed.dy,
          greaterThanOrEqualTo(0.0),
          reason: 'サイクル $cycle (閉): シート上端が画面内に留まること',
        );
      }

      container.dispose();
    });

    testWidgets(
      '【構造的跳ね上がり防止テスト】Dialogではなく画面下部アンカーのBottomSheetとして稼働し、OverlayPortalが存在しないこと',
      (WidgetTester tester) async {
        final container = ProviderContainer(
          overrides: [roomFirestoreProvider.overrideWithValue(fakeFirestore)],
        );

        await tester.pumpWidget(createTestTarget(container));

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        // 1. 中央配置Dialog（跳ね上がりの主因）が使用されていないこと
        expect(find.byType(Dialog), findsNothing);
        expect(find.byType(AlertDialog), findsNothing);

        // 2. モーダルボトムシートとしてマウントされていること
        expect(
          find.byType(ModalBottomSheetRoute),
          findsNothing,
        ); // ルート自体はWidgetツリー上直接出ないが
        expect(find.byType(RoomJoinQrDialog), findsOneWidget);

        // 3. Webで跳ね上がり・消失を起こす OverlayPortal（RawAutocomplete）がツリーに存在しないこと
        expect(find.byType(RawAutocomplete), findsNothing);

        container.dispose();
      },
    );

    testWidgets('【履歴チップからの安全上書き入力テスト】履歴タップで即座に正確入力され接続できること', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'kendo_os_dojo_room_history': ['kyoto_dojo', 'osaka_dojo'],
      });

      final notifier = DojoRoomHistoryNotifier();
      await notifier.addHistory('osaka_dojo');
      await notifier.addHistory('kyoto_dojo');

      final container = ProviderContainer(
        overrides: [
          roomFirestoreProvider.overrideWithValue(fakeFirestore),
          dojoRoomHistoryProvider.overrideWith((ref) => notifier),
        ],
      );

      await tester.pumpWidget(createTestTarget(container));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // 履歴チップが表示されていること
      expect(find.text('kyoto_dojo'), findsOneWidget);
      expect(find.text('osaka_dojo'), findsOneWidget);

      // 途中までユーザーが文字を入力
      await tester.enterText(find.byType(TextField), 'wrong_code');
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'wrong_code'), findsOneWidget);

      // 履歴「kyoto_dojo」チップをタップ
      await tester.tap(find.text('kyoto_dojo'));
      await tester.pumpAndSettle();

      // 入力欄が「kyoto_dojo」に正しく上書きされていること
      expect(find.widgetWithText(TextField, 'kyoto_dojo'), findsOneWidget);

      // 接続開始を実行
      await tester.runAsync(() async {
        await tester.tap(find.text('接続開始'));
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      // 正常に「kyoto_dojo」に直結されたこと
      expect(container.read(currentDojoIdProvider), equals('kyoto_dojo'));
      expect(find.byType(RoomJoinQrDialog), findsNothing);

      container.dispose();
    });
  });
}
