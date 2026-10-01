import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_draggable_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_drawing_canvas.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_screen.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_storage_service.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('[E2E] クイックメモ ズーム＆パン操作・キーボード自動全開・全画面復元 E2E結合実証テスト', () {
    Widget buildE2EApp({required Widget child, double viewInsetsBottom = 0}) {
      return MaterialApp(
        theme: ThemeData(
          extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
        ),
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(600, 900),
            viewInsets: EdgeInsets.only(bottom: viewInsetsBottom),
            padding: const EdgeInsets.only(bottom: 20),
          ),
          child: Scaffold(resizeToAvoidBottomInset: false, body: child),
        ),
      );
    }

    testWidgets(
      'ドック展開 → 2本指ズーム＆パン → 拡大描画 → テキスト切り替えでシート自動全開 → 全画面遷移で完全復元シナリオこと',
      (tester) async {
        const testTournamentId = 'e2e_quick_memo_tournament_001';

        // 1. ドックボトムシートとして QuickMemoBottomSheet を起動
        await tester.pumpWidget(
          buildE2EApp(
            child: const QuickMemoBottomSheet(tournamentId: testTournamentId),
          ),
        );
        await tester.pumpAndSettle();

        // クイックメモが半分の高さで初期起動していること
        expect(find.text('クイックメモ'), findsOneWidget);
        expect(find.byType(QuickMemoDrawingCanvas), findsOneWidget);

        final initialScope = tester.widget<DockSheetScope>(
          find.byType(DockSheetScope),
        );
        expect(initialScope.isExpanded, isFalse);

        // 2. 2本指によるピンチズームジェスチャー
        final canvasGestureFinder = find.byWidgetPredicate(
          (w) => w is GestureDetector && w.onScaleStart != null,
        );
        final center = tester.getCenter(canvasGestureFinder);

        final touch1 = await tester.createGesture(pointer: 1);
        final touch2 = await tester.createGesture(pointer: 2);
        await touch1.down(center.translate(-30, 0));
        await touch2.down(center.translate(30, 0));
        await tester.pump(const Duration(milliseconds: 50));

        // 2本指を広げてズームイン
        for (int i = 0; i < 5; i++) {
          await touch1.moveBy(const Offset(-20, 0));
          await touch2.moveBy(const Offset(20, 0));
          await tester.pump(const Duration(milliseconds: 20));
        }

        // 「100%に戻す」ボタンが表示されること
        expect(find.text('100%に戻す'), findsOneWidget);

        // 3. 2本指によるパン移動（平行ドラッグ）
        for (int i = 0; i < 5; i++) {
          await touch1.moveBy(const Offset(10, 10));
          await touch2.moveBy(const Offset(10, 10));
          await tester.pump(const Duration(milliseconds: 20));
        }

        await touch1.up();
        await touch2.up();
        await tester.pumpAndSettle();

        // 4. 1本指で手書きストロークを描画
        final drawTouch = await tester.startGesture(center);
        await tester.pump();
        await drawTouch.moveBy(const Offset(50, 50));
        await tester.pump();
        await drawTouch.up();
        await tester.pumpAndSettle();

        // メモ保存が完了していること（1本以上のストローク）
        final savedMemo = await QuickMemoStorageService.instance.loadMemo(
          testTournamentId,
        );
        expect(savedMemo.strokes.isNotEmpty, isTrue);

        // 5. タブを「テキストメモ」に切り替え
        await tester.tap(find.text('テキストメモ'));
        await tester.pumpAndSettle();

        // 6. キーボード出現（280px）をエミュレート
        await tester.pumpWidget(
          buildE2EApp(
            viewInsetsBottom: 280,
            child: const QuickMemoBottomSheet(tournamentId: testTournamentId),
          ),
        );
        // post frame callback で _expand() が発動し、アニメーションが完了すること
        await tester.pump();
        await tester.pumpAndSettle();

        final expandedScope = tester.widget<DockSheetScope>(
          find.byType(DockSheetScope),
        );
        expect(expandedScope.isExpanded, isTrue);

        // 7. テキストを入力して保存
        final textFieldFinder = find.byType(AppTextField);
        expect(textFieldFinder, findsOneWidget);
        await tester.enterText(textFieldFinder, 'E2Eテスト実証用メモ内容テキスト');
        await tester.pumpAndSettle();

        // 8. 全画面モード（QuickMemoScreen）へ遷移
        await tester.pumpWidget(
          buildE2EApp(
            child: const QuickMemoScreen(tournamentId: testTournamentId),
          ),
        );
        await tester.pumpAndSettle();

        // 入力したテキストが保持・復元されていること
        expect(find.text('E2Eテスト実証用メモ内容テキスト'), findsOneWidget);

        // 手書きタブに切り替えて、拡大時に描いたストロークが保持されていること
        await tester.tap(find.text('手書きメモ'));
        await tester.pumpAndSettle();

        expect(find.byType(QuickMemoDrawingCanvas), findsOneWidget);
        final fullScreenCanvas = tester.widget<QuickMemoDrawingCanvas>(
          find.byType(QuickMemoDrawingCanvas),
        );
        expect(fullScreenCanvas.strokes.isNotEmpty, isTrue);
      },
    );
  });
}
