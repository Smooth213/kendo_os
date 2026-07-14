import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:kendo_os/shared/widgets/room_join_qr_dialog.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';

void main() {
  group('🔒 現場安全弁 - 道場ルームID重複チェック＆警告ダイアログ検証テスト', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    /// テスト用のダイアログ表示環境をラッピング生成するヘルパー
    Widget createTestTarget(ProviderContainer container) {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: ThemeData(splashFactory: NoSplash.splashFactory),
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
  });
}
