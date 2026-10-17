import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/presentation/providers/manual_index_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/presentation/screens/embedded_manual_screen.dart';
import 'package:kendo_os/shared/presentation/screens/embedded_manual_tab_views.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/manual_help_button.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Widget] ヘルプ・マニュアル画面 ＆ タブビュー総合テスト', () {
    late Directory tempDir;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();

      // テスト用の一時ディレクトリを用意し、PathProviderをモックする
      tempDir = await Directory.systemTemp.createTemp('manual_widget_test');
      PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);

      // Kendo_Sync.pdf をあらかじめ配置して「ダウンロード済み」の状態を擬似再現する
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
          sharedPreferencesProvider.overrideWithValue(prefs),
          manualIndexProvider.overrideWith((ref) async => mockSearchIndex),
        ],
        child: MaterialApp(
          theme: ThemeData(
            extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
          ),
          home: EmbeddedManualScreen(
            initialTab: initialTab,
            initialFilePath: initialFilePath,
          ),
        ),
      );
    }

    Widget createTabViewTarget(Widget child) {
      return ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: ThemeData(
            extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
          ),
          home: Scaffold(body: child),
        ),
      );
    }

    /// 非同期ロードとファイルI/Oチェックを解決するヘルパー
    Future<void> pumpAndCompleteLoading(
      WidgetTester tester,
      Widget widget,
    ) async {
      await tester.pumpWidget(widget);
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 10));
        await Future<void>.delayed(Duration.zero);
      }
      await tester.pump();
    }

    testWidgets('基本表示ケースにおいて タブレイアウトが正しく描画され、初期タブの切り替えができること', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() async {
        await pumpAndCompleteLoading(tester, createTestTarget(initialTab: 0));

        expect(find.text('通常クイック'), findsOneWidget);
        expect(find.text('部内戦クイック'), findsOneWidget);
        expect(find.text('総合マニュアル'), findsOneWidget);
        expect(find.text('ヘルプ・マニュアル'), findsOneWidget);

        await tester.tap(find.text('総合マニュアル'));
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.byType(AppBar), findsOneWidget);
      });
    });

    testWidgets('検索モードケースにおいて マニュアル検索ボタンの展開・テキスト入力・検索のクリアが正常に動作すること', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() async {
        await pumpAndCompleteLoading(tester, createTestTarget(initialTab: 2));

        expect(find.text('ヘルプ・マニュアル'), findsOneWidget);
        expect(find.byIcon(Icons.search), findsOneWidget);

        await tester.tap(find.byIcon(Icons.search));
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byType(TextField), findsOneWidget);
        expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
        expect(find.text('ヘルプ・マニュアル'), findsNothing);

        await tester.enterText(find.byType(TextField), '道場');
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byIcon(Icons.close), findsOneWidget);

        await tester.tap(find.byIcon(Icons.close));
        await tester.pump(const Duration(milliseconds: 200));

        await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.text('ヘルプ・マニュアル'), findsOneWidget);
        expect(find.byType(TextField), findsNothing);
      });
    });

    testWidgets(
      'はみ出し防止ケースにおいて 横幅320pxの極小画面サイズでもAppBarやアクションボタンがRenderFlexエラーを起こさないこと',
      (WidgetTester tester) async {
        await tester.runAsync(() async {
          await tester.binding.setSurfaceSize(const Size(320, 480));
          addTearDown(() => tester.binding.setSurfaceSize(null));

          await pumpAndCompleteLoading(tester, createTestTarget(initialTab: 2));
          expect(tester.takeException(), isNull);

          await tester.tap(find.byIcon(Icons.search));
          await tester.pump(const Duration(milliseconds: 200));

          await tester.enterText(find.byType(TextField), 'テスト検索');
          await tester.pump(const Duration(milliseconds: 200));

          expect(tester.takeException(), isNull);
        });
      },
    );

    testWidgets('EmbeddedManualTabViewsのbuildQuickGuideTabが正常に描画されること', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTabViewTarget(
          Builder(
            builder: (context) {
              return EmbeddedManualTabViews.buildQuickGuideTab(
                context: context,
                assetPath: 'assets/manuals/quick_guide.pdf',
                fileName: 'クイックガイド.pdf',
                onPrint:
                    ({
                      required isAsset,
                      assetPath,
                      file,
                      required fileName,
                    }) async {},
                onShare:
                    ({
                      required isAsset,
                      assetPath,
                      file,
                      required fileName,
                    }) async {},
              );
            },
          ),
        ),
      );

      expect(find.text('A4印刷'), findsOneWidget);
      expect(find.text('共有/保存'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('EmbeddedManualTabViewsのbuildFullManualTabでテキスト簡易版が表示されること', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTabViewTarget(
          EmbeddedManualTabViews.buildFullManualTab(
            buildIndexPane: const Text('目次ペイン'),
            markdownPane: const Text('マークダウンペイン'),
            isPdfDownloaded: false,
            isDownloading: false,
            downloadProgress: 0.0,
            forceMarkdownFallback: true,
            localPdfFile: null,
            pdfViewerController: null,
            onStartDownload: () {},
            onEnableMarkdownFallback: () {},
            onDisableMarkdownFallback: () {},
            onPrint:
                ({
                  required isAsset,
                  assetPath,
                  file,
                  required fileName,
                }) async {},
            onShare:
                ({
                  required isAsset,
                  assetPath,
                  file,
                  required fileName,
                }) async {},
          ),
        ),
      );

      expect(find.text('目次ペイン'), findsOneWidget);
      expect(find.text('マークダウンペイン'), findsOneWidget);
      expect(find.text('PDF版に戻る'), findsOneWidget);
    });

    testWidgets('ManualHelpButtonが描画されタップ可能なこと', (tester) async {
      await tester.pumpWidget(
        createTabViewTarget(
          const ManualHelpButton(manualPath: 'assets/manuals/help.md'),
        ),
      );

      expect(find.byIcon(Icons.help_outline), findsOneWidget);
      await tester.tap(find.byType(ManualHelpButton));
      await tester.pump();
      expect(find.byType(ManualHelpButton), findsOneWidget);
    });
  });
}
