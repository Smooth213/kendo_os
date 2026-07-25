import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:kendo_os/shared/presentation/screens/embedded_manual_screen.dart';

class FakePathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String _documentsPath;
  FakePathProviderPlatform(this._documentsPath);

  @override
  Future<String?> getApplicationDocumentsPath() async {
    return _documentsPath;
  }
}

void main() {
  group('📖 ヘルプ・マニュアル画面 (EmbeddedManualScreen) UI検証テスト', () {
    late Directory tempDir;

    setUp(() async {
      // 1. テスト用の一時ディレクトリを用意し、PathProviderをモックする
      tempDir = await Directory.systemTemp.createTemp('manual_widget_test');
      PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);

      // 2. Kendo_Sync.pdf をあらかじめ配置して「ダウンロード済み」の状態を擬似再現する
      final file = File('${tempDir.path}/Kendo_Sync.pdf');
      await file.writeAsString('dummy pdf content');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    // 検索インデックスのモックデータ
    final mockSearchIndex = [
      {
        "id": "1",
        "title": "Kendo Sync 総合取扱説明書",
        "headers": ["第1章:基本概念", "第2章:選手マスタ登録"],
        "path": "packages/documentation_runtime/manuals/manual_index.md",
      },
    ];

    Widget createTestTarget({int? initialTab, String? initialFilePath}) {
      return ProviderScope(
        overrides: [
          manualIndexProvider.overrideWith((ref) async => mockSearchIndex),
        ],
        child: MaterialApp(
          home: EmbeddedManualScreen(
            initialTab: initialTab,
            initialFilePath: initialFilePath,
          ),
        ),
      );
    }

    /// 非同期ロードとファイルI/Oチェックを実時間で解決するヘルパー
    Future<void> pumpAndCompleteLoading(
      WidgetTester tester,
      Widget widget,
    ) async {
      await tester.pumpWidget(widget);
      await Future.delayed(const Duration(milliseconds: 250));
      await tester.pump();
    }

    testWidgets('【基本表示ケース】タブレイアウトが正しく描画され、初期タブの切り替えができること', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() async {
        // 1. 通常クイックガイド(Tab 0)を初期値として起動
        await pumpAndCompleteLoading(tester, createTestTarget(initialTab: 0));

        // 3つのタブ名が表示されていることを確認
        expect(find.text('通常クイック'), findsOneWidget);
        expect(find.text('部内戦クイック'), findsOneWidget);
        expect(find.text('総合マニュアル'), findsOneWidget);

        // 通常クイックがアクティブ
        expect(find.text('ヘルプ・マニュアル'), findsOneWidget);

        // 2. タブをタップして「総合マニュアル」(Tab 2)へ切り替え
        await tester.tap(find.text('総合マニュアル'));
        // タブ切り替えアニメーション（300ms）を完了させる
        await tester.pump(const Duration(milliseconds: 500));

        // 切り替え後、総合マニュアル用のホームアイコンやタイトルが正しく描画されていること
        expect(find.byType(AppBar), findsOneWidget);
      });
    });

    testWidgets('【検索モードケース】マニュアル検索ボタンの展開・テキスト入力・検索のクリアが正常に動作すること', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() async {
        // 総合マニュアル(Tab 2)を開いて起動
        await pumpAndCompleteLoading(tester, createTestTarget(initialTab: 2));

        // 検索前：検索フォームはなく、通常のAppBarタイトルが表示されていること
        expect(find.text('ヘルプ・マニュアル'), findsOneWidget);
        expect(find.byIcon(Icons.search), findsOneWidget);

        // 1. 検索アイコンをタップして検索入力欄を展開
        await tester.tap(find.byIcon(Icons.search));
        await tester.pump(const Duration(milliseconds: 200));

        // 検索入力欄（TextField）と戻るボタンが露出することを確認
        expect(find.byType(TextField), findsOneWidget);
        expect(find.byIcon(Icons.arrow_back), findsOneWidget);
        expect(find.text('ヘルプ・マニュアル'), findsNothing); // タイトルは検索バーに置き換わる

        // 2. 文字を入力
        await tester.enterText(find.byType(TextField), '道場');
        await tester.pump(const Duration(milliseconds: 200));

        // クリアボタンが露出することを確認
        expect(find.byIcon(Icons.close), findsOneWidget);

        // 3. 検索をクリア
        await tester.tap(find.byIcon(Icons.close));
        await tester.pump(const Duration(milliseconds: 200));

        // 検索を終了
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pump(const Duration(milliseconds: 200));

        // 検索終了後、通常タイトルに戻ること
        expect(find.text('ヘルプ・マニュアル'), findsOneWidget);
        expect(find.byType(TextField), findsNothing);
      });
    });

    testWidgets(
      '【はみ出し防止ケース】横幅320pxの極小画面サイズでもAppBarやアクションボタンがRenderFlexエラーを起こさないこと',
      (WidgetTester tester) async {
        await tester.runAsync(() async {
          // 超小型スマートフォンサイズ (幅320px, 高さ480px)
          await tester.binding.setSurfaceSize(const Size(320, 480));
          addTearDown(() => tester.binding.setSurfaceSize(null));

          // 総合マニュアル(Tab 2)を開いて起動
          await pumpAndCompleteLoading(tester, createTestTarget(initialTab: 2));

          // レイアウト例外（RenderFlex overflow等）がスローされていないことを確認
          expect(tester.takeException(), isNull);

          // 検索モードを展開
          await tester.tap(find.byIcon(Icons.search));
          await tester.pump(const Duration(milliseconds: 200));

          // 文字を入力してクリアボタンを表示
          await tester.enterText(find.byType(TextField), 'テスト検索');
          await tester.pump(const Duration(milliseconds: 200));

          // 極小画面＆検索表示中でもレイアウトエラーが一切スローされていないことを確認
          expect(tester.takeException(), isNull);
        });
      },
    );
  });
}
