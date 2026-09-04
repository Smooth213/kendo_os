import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_screen.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createTestWidget({required Widget child}) {
    return MaterialApp(
      theme: ThemeData(
        extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
      ),
      home: child,
    );
  }

  group('🥋 QuickMemoScreen Widget Tests', () {
    testWidgets('白紙メモ画面がレンダリングされ、タイトル「クイックメモ」とガイダンスが表示されること', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: const QuickMemoScreen(tournamentId: 'test_tournament'),
        ),
      );
      await tester.pumpAndSettle();

      // タイトル「クイックメモ」が存在すること
      expect(find.text('クイックメモ'), findsOneWidget);

      // 初期空状態のガイダンステキストが存在すること
      expect(find.text('ここに指やペンでメモを自由に書けます'), findsOneWidget);

      // タブのラベルが存在すること
      expect(find.text('手書きメモ'), findsOneWidget);
      expect(find.text('テキストメモ'), findsOneWidget);

      // 下部ツールバーの消しゴムアイコンが存在すること
      expect(find.byIcon(Icons.auto_fix_normal_rounded), findsOneWidget);
    });

    testWidgets('キャンバス上をドラッグすると手書きストロークが追加されガイダンスが非表示になること', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: const QuickMemoScreen(tournamentId: 'test_tournament'),
        ),
      );
      await tester.pumpAndSettle();

      // キャンバスの CustomPaint を検索
      final canvasCustomPaintFinder = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is MemoCanvasPainter,
      );
      final canvasOrigin = tester.getTopLeft(canvasCustomPaintFinder);

      // キャンバス内の相対座標 (50, 60) からドラッグ
      await tester.dragFrom(
        canvasOrigin + const Offset(50, 60),
        const Offset(30, 20),
      );
      await tester.pumpAndSettle();

      // 描画後は空状態のガイダンスが非表示になること
      expect(find.text('ここに指やペンでメモを自由に書けます'), findsNothing);

      // 描画されたストロークの開始位置が、タップした相対位置 (50, 60) と完全一致すること
      final customPaint = tester.widget<CustomPaint>(canvasCustomPaintFinder);
      final painter = customPaint.painter as MemoCanvasPainter;
      expect(painter.strokes.isNotEmpty, isTrue);
      expect(painter.strokes.first.points.first.dx, closeTo(50.0, 0.01));
      expect(painter.strokes.first.points.first.dy, closeTo(60.0, 0.01));

      // 1つ戻す（Undo）ボタンをタップ
      final undoBtn = find.byIcon(Icons.undo_rounded);
      expect(undoBtn, findsOneWidget);
      await tester.tap(undoBtn);
      await tester.pumpAndSettle();

      // ストロークが戻って再びガイダンスが表示されること
      expect(find.text('ここに指やペンでメモを自由に書けます'), findsOneWidget);
    });

    testWidgets('タブで「テキストメモ」に切り替えると入力欄とクイックアクションバーが表示され、時刻挿入ができること', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          child: const QuickMemoScreen(tournamentId: 'test_tournament'),
        ),
      );
      await tester.pumpAndSettle();

      // モード切り替えタブが存在すること
      expect(find.text('手書きメモ'), findsOneWidget);
      expect(find.text('テキストメモ'), findsOneWidget);

      // 「テキストメモ」タブをタップ
      await tester.tap(find.text('テキストメモ'));
      await tester.pumpAndSettle();

      // 手書きガイダンスと手書きツールバーが非表示になり、テキスト入力欄が表示されること
      expect(find.text('ここに指やペンでメモを自由に書けます'), findsNothing);
      expect(find.byIcon(Icons.auto_fix_normal_rounded), findsNothing);
      expect(find.byType(TextField), findsOneWidget);

      // 下部クイックアクションバー（時刻挿入・コピー・全消去・文字数）が表示されること
      expect(find.text('時刻挿入'), findsOneWidget);
      expect(find.text('コピー'), findsOneWidget);
      expect(find.text('全消去'), findsOneWidget);
      expect(find.text('0 文字'), findsOneWidget);

      // テキストを入力
      await tester.enterText(find.byType(TextField), '第1試合: 赤コート 延長戦へ突入');
      await tester.pumpAndSettle();
      expect(find.text('第1試合: 赤コート 延長戦へ突入'), findsOneWidget);
      expect(find.text('17 文字'), findsOneWidget);

      // 下部クイックアクションバーの「時刻挿入」ボタンをタップ
      await tester.tap(find.text('時刻挿入'));
      await tester.pumpAndSettle();

      // 時刻形式 '[' が挿入されていること
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text.contains('['), isTrue);
    });

    testWidgets('画面を一度閉じて再オープンしても、入力したテキストと手書きストロークが保持・自動復元されること', (
      tester,
    ) async {
      const tournamentId = 'persist_tournament_1';

      // 1回目のオープン
      await tester.pumpWidget(
        createTestWidget(
          child: const QuickMemoScreen(tournamentId: tournamentId),
        ),
      );
      await tester.pumpAndSettle();

      // テキストメモに切り替えて入力
      await tester.tap(find.text('テキストメモ'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '大会記録メモ: 永続化テスト');
      await tester.pumpAndSettle();

      // 手書きメモに戻して描画
      await tester.tap(find.text('手書きメモ'));
      await tester.pumpAndSettle();
      await tester.dragFrom(const Offset(150, 250), const Offset(80, 40));
      await tester.pumpAndSettle();

      // 画面を破棄（別のウィジェットに切り替えてアンマウント）
      await tester.pumpWidget(createTestWidget(child: const SizedBox()));
      await tester.pumpAndSettle();

      // 再度 QuickMemoScreen をオープン
      await tester.pumpWidget(
        createTestWidget(
          child: const QuickMemoScreen(tournamentId: tournamentId),
        ),
      );
      await tester.pumpAndSettle();

      // 手書きストロークが存在するため、初期空状態ガイダンスが表示されていないこと
      expect(find.text('ここに指やペンでメモを自由に書けます'), findsNothing);

      // テキストメモに切り替えると、前回のテキストが復元されていること
      await tester.tap(find.text('テキストメモ'));
      await tester.pumpAndSettle();
      expect(find.text('大会記録メモ: 永続化テスト'), findsOneWidget);
    });
  });
}
