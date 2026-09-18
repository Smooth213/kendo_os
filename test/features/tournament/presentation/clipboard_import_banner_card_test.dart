import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/application/clipboard_import_service.dart';
import 'package:kendo_os/features/tournament/presentation/components/share_import/clipboard_import_banner_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/create_tournament/create_tournament_page1.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// テスト用のフェイク ClipboardImportService
class FakeClipboardImportService extends ClipboardImportService {
  int importManuallyCallCount = 0;
  BuildContext? lastContext;

  @override
  Future<void> importManually(BuildContext context) async {
    importManuallyCallCount++;
    lastContext = context;
  }
}

/// テーマ付きラッパー
Widget _buildTestApp({
  required Widget child,
  bool isDark = false,
  List<dynamic> overrides = const [],
}) {
  final theme = ThemeData(
    brightness: isDark ? Brightness.dark : Brightness.light,
    extensions: [AppThemeColors.ofMode(isDark: isDark, mode: 'normal')],
  );

  return ProviderScope(
    overrides: overrides.cast(),
    child: MaterialApp(
      theme: theme,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('📋 ClipboardImportBannerCard 単体テスト', () {
    testWidgets('ライトモードで基本UI（タイトル・バッジ・説明文・アイコン）が正しく表示されること', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(isDark: false, child: const ClipboardImportBannerCard()),
      );

      // タイトルとバッジ
      expect(find.text('クリップボードから自動入力'), findsOneWidget);
      expect(find.text('便利'), findsOneWidget);

      // 説明テキスト
      expect(
        find.text('共有された大会テキストをコピーしていれば、大会名・日程・チーム情報をワンタップで反映できます'),
        findsOneWidget,
      );

      // アイコン
      expect(find.byIcon(Icons.content_paste_go_rounded), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_ios_rounded), findsOneWidget);

      // コンテナスタイルの検証
      final containerFinder = find
          .descendant(
            of: find.byType(ClipboardImportBannerCard),
            matching: find.byType(Container),
          )
          .first;
      final container = tester.widget<Container>(containerFinder);
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration, isNotNull);
      expect(decoration?.color, const Color(0xFFFFFBEB)); // ライトモード背景色
      expect(decoration?.borderRadius, AppRadius.large);
    });

    testWidgets('ダークモードで基本UIが崩れず正しく描画されること', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(isDark: true, child: const ClipboardImportBannerCard()),
      );

      expect(find.text('クリップボードから自動入力'), findsOneWidget);
      expect(find.text('便利'), findsOneWidget);
      expect(find.byIcon(Icons.content_paste_go_rounded), findsOneWidget);

      final containerFinder = find
          .descendant(
            of: find.byType(ClipboardImportBannerCard),
            matching: find.byType(Container),
          )
          .first;
      final container = tester.widget<Container>(containerFinder);
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.color, const Color(0xFF231F17)); // ダークモード背景色
    });

    testWidgets('指定したマージンが外側コンテナに適用されること', (tester) async {
      const customMargin = EdgeInsets.all(18.0);
      await tester.pumpWidget(
        _buildTestApp(
          child: const ClipboardImportBannerCard(margin: customMargin),
        ),
      );

      final containerFinder = find
          .descendant(
            of: find.byType(ClipboardImportBannerCard),
            matching: find.byType(Container),
          )
          .first;
      final container = tester.widget<Container>(containerFinder);
      expect(container.margin, customMargin);
    });

    testWidgets('タップ時に importManually と onImportCompleted が正しく実行されること', (
      tester,
    ) async {
      final fakeService = FakeClipboardImportService();
      bool onCompletedCalled = false;

      await tester.pumpWidget(
        _buildTestApp(
          overrides: [
            clipboardImportServiceProvider.overrideWithValue(fakeService),
          ],
          child: ClipboardImportBannerCard(
            onImportCompleted: () {
              onCompletedCalled = true;
            },
          ),
        ),
      );

      // タップ前の状態
      expect(fakeService.importManuallyCallCount, 0);
      expect(onCompletedCalled, isFalse);

      // カードをタップ
      await tester.tap(find.byType(ClipboardImportBannerCard));
      await tester.pumpAndSettle();

      // サービスメソッドとコールバック双方が呼び出されたことを検証
      expect(fakeService.importManuallyCallCount, 1);
      expect(onCompletedCalled, isTrue);
      expect(fakeService.lastContext, isNotNull);
    });
  });

  group('🏆 CreateTournamentPage1 統合テスト (解説付きインポートUI)', () {
    late TextEditingController nameController;

    setUp(() {
      nameController = TextEditingController();
    });

    tearDown(() {
      nameController.dispose();
    });

    testWidgets(
      'ステップ1に手動入力フォーム、「または」区切り線、ClipboardImportBannerCardが整然と配置されること',
      (tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            isDark: false,
            child: CreateTournamentPage1(
              nameController: nameController,
              selectedDate: DateTime(2026, 9, 20),
              onPickDate: () {},
            ),
          ),
        );

        // 1. ヘッダーテキスト・大会名フォーム・開催日タイルが存在すること
        expect(find.text('大会の名前と日付を\n教えてください'), findsOneWidget);
        expect(find.byType(TextFormField), findsOneWidget);
        expect(find.text('開催年月日'), findsOneWidget);
        expect(find.text('2026年09月20日'), findsOneWidget);

        // 2. 「または」の区切り線ラベルが存在すること
        expect(find.text('または'), findsOneWidget);
        expect(find.byType(Divider), findsNWidgets(2)); // 「または」の左右に2本

        // 3. クリップボードインポートカードが存在すること
        expect(find.byType(ClipboardImportBannerCard), findsOneWidget);
        expect(find.text('クリップボードから自動入力'), findsOneWidget);
      },
    );

    testWidgets('CreateTournamentPage1 上でインポートカードを直接タップしてサービスが起動すること', (
      tester,
    ) async {
      final fakeService = FakeClipboardImportService();

      await tester.pumpWidget(
        _buildTestApp(
          overrides: [
            clipboardImportServiceProvider.overrideWithValue(fakeService),
          ],
          child: CreateTournamentPage1(
            nameController: nameController,
            selectedDate: DateTime(2026, 9, 20),
            onPickDate: () {},
          ),
        ),
      );

      expect(fakeService.importManuallyCallCount, 0);

      // バナーカードをタップ
      await tester.tap(find.byType(ClipboardImportBannerCard));
      await tester.pumpAndSettle();

      expect(fakeService.importManuallyCallCount, 1);
    });

    testWidgets('ダークモードでも CreateTournamentPage1 内で視認性よくレンダリングされること', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(
          isDark: true,
          child: CreateTournamentPage1(
            nameController: nameController,
            selectedDate: DateTime(2026, 9, 20),
            onPickDate: () {},
          ),
        ),
      );

      expect(find.text('または'), findsOneWidget);
      expect(find.byType(ClipboardImportBannerCard), findsOneWidget);
      expect(find.text('クリップボードから自動入力'), findsOneWidget);
    });
  });
}
