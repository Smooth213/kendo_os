import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/create_tournament/create_tournament_page1.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/create_tournament/create_tournament_page2.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

// ============================================================
//  ⚠️  視認性ガードテスト
//  「入力欄の背景色が文字色（黒）と同一になっていないか」を検証する。
//  過去に ライトモードで inputBgColor = textColor（黒）が
//  誤って設定され、入力欄が真っ黒になる不具合が発生した。
//  このテストが失敗したときは、create_tournament_page*.dart の
//  inputBgColor の設定が textColor になっていないか確認すること。
// ============================================================

/// テーマ付きのウィジェットラッパーを生成するヘルパー
Widget _wrap(Widget child, {bool dark = false}) {
  final theme = ThemeData(
    brightness: dark ? Brightness.dark : Brightness.light,
    extensions: [AppThemeColors.ofMode(isDark: dark, mode: 'normal')],
  );
  return MaterialApp(
    theme: theme,
    home: Scaffold(body: child),
  );
}

/// ウィジェットツリーから全 TextField(TextFormField内部)の fillColor を取得する
List<Color?> _collectFillColors(WidgetTester tester) {
  return tester
      .widgetList<TextField>(find.byType(TextField))
      .map((field) => field.decoration?.fillColor)
      .toList();
}

/// ウィジェットツリーから全 ListTile の tileColor を取得する
List<Color?> _collectTileColors(WidgetTester tester) {
  return tester
      .widgetList<ListTile>(find.byType(ListTile))
      .map((tile) => tile.tileColor)
      .toList();
}

void main() {
  group('🚨 大会作成画面 視認性ガードテスト', () {
    // ----------------------------------------------------------
    // Page1 ライトモード
    // ----------------------------------------------------------
    group('CreateTournamentPage1 / ライトモード', () {
      late TextEditingController nameController;

      setUp(() {
        nameController = TextEditingController();
      });
      tearDown(() => nameController.dispose());

      testWidgets('1. 大会名フィールドの背景色がテキスト色（黒）ではない', (tester) async {
        await tester.pumpWidget(
          _wrap(
            CreateTournamentPage1(
              nameController: nameController,
              selectedDate: DateTime(2025, 1, 1),
              onPickDate: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        final fills = _collectFillColors(tester);
        expect(fills, isNotEmpty, reason: 'TextFormField が1件以上存在すること');

        for (final fill in fills) {
          // 背景色が黒でないことを検証（透明度を無視して比較）
          expect(
            fill?.withAlpha(255),
            isNot(Colors.black),
            reason:
                'ライトモードで入力欄の背景色が黒(textColor)になってはいけない。\n'
                'create_tournament_page1.dart の inputBgColor が '
                'context.appColors.inputBackground を使っているか確認。',
          );
        }
      });

      testWidgets('2. 日付選択ListTileの背景色がテキスト色（黒）ではない', (tester) async {
        await tester.pumpWidget(
          _wrap(
            CreateTournamentPage1(
              nameController: nameController,
              selectedDate: DateTime(2025, 1, 1),
              onPickDate: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        final tiles = _collectTileColors(tester);
        expect(tiles, isNotEmpty, reason: 'ListTile が1件以上存在すること');

        for (final tile in tiles) {
          expect(
            tile?.withAlpha(255),
            isNot(Colors.black),
            reason:
                'ライトモードで日付ListTileの背景色が黒になってはいけない。\n'
                'create_tournament_page1.dart の tileColor 設定を確認。',
          );
        }
      });

      testWidgets('3. 入力欄の背景色がデザインシステムのinputBackground（明るい色）と一致する', (
        tester,
      ) async {
        await tester.pumpWidget(
          _wrap(
            CreateTournamentPage1(
              nameController: nameController,
              selectedDate: DateTime(2025, 1, 1),
              onPickDate: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        // ライトモードの inputBackground = Colors.grey.shade100
        final expectedBg = Colors.grey.shade100;
        final fills = _collectFillColors(tester);

        for (final fill in fills) {
          expect(
            fill,
            expectedBg,
            reason:
                'ライトモードの入力欄背景色は Colors.grey.shade100 (inputBackground) であるべき。',
          );
        }
      });
    });

    // ----------------------------------------------------------
    // Page2 ライトモード
    // ----------------------------------------------------------
    group('CreateTournamentPage2 / ライトモード', () {
      late TextEditingController venueController;
      late TextEditingController notesController;

      setUp(() {
        venueController = TextEditingController();
        notesController = TextEditingController();
      });
      tearDown(() {
        venueController.dispose();
        notesController.dispose();
      });

      testWidgets('4. 会場フィールドの背景色がテキスト色（黒）ではない', (tester) async {
        await tester.pumpWidget(
          _wrap(
            CreateTournamentPage2(
              venueController: venueController,
              notesController: notesController,
              onOpenMap: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        final fills = _collectFillColors(tester);
        expect(fills, isNotEmpty, reason: 'TextFormField が1件以上存在すること');

        for (final fill in fills) {
          expect(
            fill?.withAlpha(255),
            isNot(Colors.black),
            reason:
                'ライトモードで入力欄の背景色が黒(textColor)になってはいけない。\n'
                'create_tournament_page2.dart の inputBgColor が '
                'context.appColors.inputBackground を使っているか確認。',
          );
        }
      });

      testWidgets('5. 全入力欄(会場・メモ)の背景色がinputBackgroundと一致する', (tester) async {
        await tester.pumpWidget(
          _wrap(
            CreateTournamentPage2(
              venueController: venueController,
              notesController: notesController,
              onOpenMap: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        final expectedBg = Colors.grey.shade100;
        final fills = _collectFillColors(tester);
        expect(fills.length, 2, reason: '会場フィールドとメモフィールドの2件');

        for (final fill in fills) {
          expect(
            fill,
            expectedBg,
            reason:
                'ライトモードの入力欄背景色は Colors.grey.shade100 (inputBackground) であるべき。',
          );
        }
      });
    });

    // ----------------------------------------------------------
    // ダークモード（既存動作が壊れていないことを保証）
    // ----------------------------------------------------------
    group('ダークモード（回帰テスト）', () {
      late TextEditingController nameController;
      late TextEditingController venueController;
      late TextEditingController notesController;

      setUp(() {
        nameController = TextEditingController();
        venueController = TextEditingController();
        notesController = TextEditingController();
      });
      tearDown(() {
        nameController.dispose();
        venueController.dispose();
        notesController.dispose();
      });

      testWidgets('6. Page1 ダークモード: 入力欄の背景色が白（= 文字色）ではない', (tester) async {
        await tester.pumpWidget(
          _wrap(
            CreateTournamentPage1(
              nameController: nameController,
              selectedDate: DateTime(2025, 1, 1),
              onPickDate: () {},
            ),
            dark: true,
          ),
        );
        await tester.pumpAndSettle();

        final fills = _collectFillColors(tester);
        for (final fill in fills) {
          expect(
            fill?.withAlpha(255),
            isNot(Colors.white),
            reason: 'ダークモードで入力欄の背景色が白（textColor）になってはいけない。',
          );
        }
      });

      testWidgets('7. Page2 ダークモード: 入力欄の背景色が白（= 文字色）ではない', (tester) async {
        await tester.pumpWidget(
          _wrap(
            CreateTournamentPage2(
              venueController: venueController,
              notesController: notesController,
              onOpenMap: () {},
            ),
            dark: true,
          ),
        );
        await tester.pumpAndSettle();

        final fills = _collectFillColors(tester);
        for (final fill in fills) {
          expect(
            fill?.withAlpha(255),
            isNot(Colors.white),
            reason: 'ダークモードで入力欄の背景色が白（textColor）になってはいけない。',
          );
        }
      });
    });

    // ----------------------------------------------------------
    // テキスト・ラベルの視認性
    // ----------------------------------------------------------
    group('テキスト視認性テスト', () {
      testWidgets('8. Page1 ライトモード: 見出しテキストが表示される', (tester) async {
        final ctrl = TextEditingController();
        addTearDown(ctrl.dispose);
        await tester.pumpWidget(
          _wrap(
            CreateTournamentPage1(
              nameController: ctrl,
              selectedDate: DateTime(2025, 8, 22),
              onPickDate: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('大会の名前と日付を\n教えてください'), findsOneWidget);
        expect(find.text('2025年08月22日'), findsOneWidget);
      });

      testWidgets('9. Page2 ライトモード: 見出しテキストが表示される', (tester) async {
        final venue = TextEditingController();
        final notes = TextEditingController();
        addTearDown(() {
          venue.dispose();
          notes.dispose();
        });
        await tester.pumpWidget(
          _wrap(
            CreateTournamentPage2(
              venueController: venue,
              notesController: notes,
              onOpenMap: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('開催場所とメモを\n入力してください'), findsOneWidget);
      });
    });
  });
}
