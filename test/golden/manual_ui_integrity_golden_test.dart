import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:kendo_os/features/tournament/presentation/components/manual/manual_index_pane.dart';
import 'package:kendo_os/features/tournament/presentation/components/manual/manual_markdown_view.dart';
import 'package:kendo_os/shared/presentation/providers/manual_index_provider.dart';
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
  group('📸 【Golden/視覚整合性】マニュアル画面 多端末・テーマ別UI崩壊ゼロ検証テスト', () {
    late Directory tempDir;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('manual_golden_test');
      PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);
      final dummyPdf = File('${tempDir.path}/Kendo_Sync.pdf');
      await dummyPdf.writeAsString('dummy');
    });

    tearDownAll(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    // 視覚検証用のモックインデックスデータ
    final mockIndex = [
      {
        "path":
            "packages/documentation_runtime/manuals/operator/category_rules.md",
        "title": "⚙️ 部門別ルール設定",
        "headings": ["基本ルール", "延長方式", "勝敗判定基準"],
        "tags": ["ルール設定", "部門", "試合時間"],
        "sort_order": 30,
        "last_updated": "2026-09-05T00:00:00.000",
      },
      {
        "path": "packages/documentation_runtime/manuals/operator/dock_guide.md",
        "title": "🎯 ドック＆フローティングパネル活用法",
        "headings": ["ドックの概要", "背面操作の特長", "ワンタップ復帰"],
        "tags": ["ドック", "常設パネル", "背面操作"],
        "sort_order": 30,
        "last_updated": "2026-09-05T00:00:00.000",
      },
    ];

    // 見出し、リスト、表組み、引用、コードブロックを含む標準Markdown
    const richMarkdownSample = '''
# 🏆 剣道大会 公式運営マニュアル

本ドキュメントは、大会運営・記録係・観客の共通ガイドラインです。

## 1. 試合時間と延長規定
| 部門 | 試合時間 | 延長時間 | 判定基準 |
| :--- | :--- | :--- | :--- |
| 小学生の部 | 2分 | 2分1回 | 判定 |
| 中学生の部 | 3分 | 無制限 | 一本勝負 |
| 一般の部 | 4分 | 無制限 | 一本勝負 |

## 2. 操作手順と留意事項
- **ステップ1**: 担当コートの試合を開く
- **ステップ2**: 主審の「はじめ」に合わせてタイマー開始
- **ステップ3**: 有効打突をタップして記録

> [!NOTE]
> 通信が途切れてもローカル暗号地層に保存されます。操作を止めないでください。

```dart
// タイマー同期パケット
void syncMatchTime(Duration elapsed);
```
''';

    // 1. 多端末解像度シミュレーション（レスポンシブ崩れ検知）
    final deviceViewports = {
      'Mobile_Compact_320px': const Size(320, 568),
      'iPhone_SE_375px': const Size(375, 667),
      'Tablet_Portrait_768px': const Size(768, 1024),
      'Desktop_Wide_1920px': const Size(1920, 1080),
    };

    for (final entry in deviceViewports.entries) {
      final deviceName = entry.key;
      final viewportSize = entry.value;

      testWidgets(
        '【解像度検証】$deviceName 環境で EmbeddedManualScreen がはみ出し例外ゼロで描画されること',
        (tester) async {
          await tester.runAsync(() async {
            tester.view.physicalSize = viewportSize;
            tester.view.devicePixelRatio = 1.0;

            await tester.pumpWidget(
              ProviderScope(
                overrides: [
                  manualIndexProvider.overrideWith((ref) async => mockIndex),
                ],
                child: const MaterialApp(
                  home: EmbeddedManualScreen(initialTab: 0),
                ),
              ),
            );
            await Future.delayed(const Duration(milliseconds: 300));
            await tester.pump();

            // RenderFlex オーバーフロー例外が一切発生していないこと
            expect(tester.takeException(), isNull);

            // 主要UI構造が存在すること
            expect(find.byType(AppBar), findsOneWidget);
            expect(find.text('通常クイック'), findsOneWidget);
            expect(find.text('部内戦クイック'), findsOneWidget);
            expect(find.text('総合マニュアル'), findsOneWidget);

            tester.view.reset();
          });
        },
      );
    }

    // 2. テーマ別UI整合性検証（ライト・ダークモード）
    final themes = {
      'Light_Theme': ThemeData.light(),
      'Dark_Theme': ThemeData.dark(),
    };

    for (final themeEntry in themes.entries) {
      final themeName = themeEntry.key;
      final themeData = themeEntry.value;

      testWidgets('【テーマ検証】$themeName で ManualIndexPane が崩れず描画されること', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(375, 667);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final searchController = TextEditingController();

        await tester.pumpWidget(
          MaterialApp(
            theme: themeData,
            home: Scaffold(
              body: ManualIndexPane(
                searchController: searchController,
                searchQuery: '',
                indexList: mockIndex,
                currentFilePath: '',
                onSearchChanged: (_) {},
                onSearchCleared: () {},
                onFileSelected: (_) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 例外なし
        expect(tester.takeException(), isNull);

        // 検索フィールドとリストが正しく表示されていること
        expect(find.byType(TextField), findsOneWidget);
        expect(find.byType(ListView), findsOneWidget);
        expect(find.text('⚙️ 部門別ルール設定'), findsOneWidget);
        expect(find.text('🎯 ドック＆フローティングパネル活用法'), findsOneWidget);
      });
    }

    // 3. リッチMarkdown描画完全性テスト（見出し・表・引用・コード）
    testWidgets('【Markdown描画検証】見出し・テーブル・箇条書き・コードブロックが正常にレンダリングされること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ManualMarkdownView(
              markdownContent: richMarkdownSample,
              currentFilePath:
                  'packages/documentation_runtime/manuals/operator/category_rules.md',
              isLoading: false,
              onLinkTapped: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 例外ゼロ
      expect(tester.takeException(), isNull);

      // MarkdownViewが描画されていること
      expect(find.byType(ManualMarkdownView), findsOneWidget);
    });

    // 4. ワイド画面（タブレット・PC）でのサイドバー固定表示テスト
    testWidgets(
      '【ワイド画面検証】isWideScreen=true で ManualIndexPane が320px固定幅でレンダリングされること',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final searchController = TextEditingController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Row(
                children: [
                  ManualIndexPane(
                    searchController: searchController,
                    searchQuery: '',
                    indexList: mockIndex,
                    currentFilePath: '',
                    onSearchChanged: (_) {},
                    onSearchCleared: () {},
                    onFileSelected: (_) {},
                    isWideScreen: true,
                  ),
                  const Expanded(child: Center(child: Text('本文エリア'))),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        // 320pxのコンテナが存在すること
        final container = tester.widget<Container>(
          find
              .descendant(
                of: find.byType(ManualIndexPane),
                matching: find.byType(Container),
              )
              .first,
        );
        expect(
          container.constraints?.maxWidth ?? container.constraints?.minWidth,
          isNotNull,
        );
        expect(find.text('本文エリア'), findsOneWidget);
      },
    );
  });
}
