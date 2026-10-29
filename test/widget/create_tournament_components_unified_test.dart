import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/safe_pump_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/create_tournament/create_tournament_dynamic_header.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/create_tournament/create_tournament_page1.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/create_tournament/create_tournament_page2.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/create_tournament/create_tournament_sticky_bottom_action.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrapWithTheme(Widget child, {bool dark = false}) {
  final theme = ThemeData(
    brightness: dark ? Brightness.dark : Brightness.light,
    extensions: [AppThemeColors.ofMode(isDark: dark, mode: 'normal')],
  );
  return MaterialApp(
    theme: theme,
    home: Scaffold(body: child),
  );
}

List<Color?> _collectFillColors(WidgetTester tester) {
  return tester
      .widgetList<TextField>(find.byType(TextField))
      .map((field) => field.decoration?.fillColor)
      .toList();
}

List<Color?> _collectTileColors(WidgetTester tester) {
  return tester
      .widgetList<ListTile>(find.byType(ListTile))
      .map((tile) => tile.tileColor)
      .toList();
}

void main() {
  group('[Widget] 大会作成コンポーネント・視認性統合テスト', () {
    // ----------------------------------------------------------
    // 各コンポーネントの基本描画
    // ----------------------------------------------------------
    group('コンポーネント基本描画テスト', () {
      testWidgets('大会作成ダイナミックヘッダーが正しく描画されること', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CreateTournamentDynamicHeader(currentProgress: 0.5),
            ),
          ),
        );

        expect(find.text('大会を新規作成'), findsOneWidget);
      });

      testWidgets('大会作成第1ページが正しく描画されること', (tester) async {
        final nameCtrl = TextEditingController(text: '剣道大会');
        addTearDown(nameCtrl.dispose);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CreateTournamentPage1(
                nameController: nameCtrl,
                selectedDate: DateTime(2026, 8, 21),
                onPickDate: () {},
              ),
            ),
          ),
        );

        expect(find.text('大会の名前と日付を\n教えてください'), findsOneWidget);
        expect(find.text('2026年08月21日'), findsOneWidget);
      });

      testWidgets('大会作成第2ページが正しく描画されること', (tester) async {
        final venueCtrl = TextEditingController(text: '武道館');
        final noteCtrl = TextEditingController(text: 'メモ');
        addTearDown(() {
          venueCtrl.dispose();
          noteCtrl.dispose();
        });
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CreateTournamentPage2(
                venueController: venueCtrl,
                notesController: noteCtrl,
                onOpenMap: () {},
              ),
            ),
          ),
        );

        expect(find.text('開催場所とメモを\n入力してください'), findsOneWidget);
      });

      testWidgets('大会作成ボトムアクションが正しく描画されること', (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            child: MaterialApp(
              home: Scaffold(
                body: CreateTournamentStickyBottomAction(
                  currentPage: 1,
                  onPrevious: () {},
                  onNextOrSave: () {},
                ),
              ),
            ),
          ),
        );

        expect(find.text('保存してチーム登録へ'), findsOneWidget);
      });
    });

    // ----------------------------------------------------------
    // Page1 視認性ガード（ライトモード）
    // ----------------------------------------------------------
    group('Page1 ライトモード視認性テスト', () {
      late TextEditingController nameController;

      setUp(() {
        nameController = TextEditingController();
      });
      tearDown(() => nameController.dispose());

      testWidgets('大会名フィールドの背景色がテキスト色（黒）ではないこと', (tester) async {
        await tester.pumpWidget(
          _wrapWithTheme(
            CreateTournamentPage1(
              nameController: nameController,
              selectedDate: DateTime(2025, 1, 1),
              onPickDate: () {},
            ),
          ),
        );
        await tester.safePumpAndSettle();

        final fills = _collectFillColors(tester);
        expect(fills, isNotEmpty);

        for (final fill in fills) {
          expect(fill?.withAlpha(255), isNot(Colors.black));
        }
      });

      testWidgets('日付選択ListTileの背景色がテキスト色（黒）ではないこと', (tester) async {
        await tester.pumpWidget(
          _wrapWithTheme(
            CreateTournamentPage1(
              nameController: nameController,
              selectedDate: DateTime(2025, 1, 1),
              onPickDate: () {},
            ),
          ),
        );
        await tester.safePumpAndSettle();

        final tiles = _collectTileColors(tester);
        expect(tiles, isNotEmpty);

        for (final tile in tiles) {
          expect(tile?.withAlpha(255), isNot(Colors.black));
        }
      });

      testWidgets('入力欄の背景色がデザインシステムのinputBackground（明るい色）と一致すること', (
        tester,
      ) async {
        await tester.pumpWidget(
          _wrapWithTheme(
            CreateTournamentPage1(
              nameController: nameController,
              selectedDate: DateTime(2025, 1, 1),
              onPickDate: () {},
            ),
          ),
        );
        await tester.safePumpAndSettle();

        final expectedBg = Colors.grey.shade100;
        final fills = _collectFillColors(tester);

        for (final fill in fills) {
          expect(fill, expectedBg);
        }
      });
    });

    // ----------------------------------------------------------
    // Page2 視認性ガード（ライトモード）
    // ----------------------------------------------------------
    group('Page2 ライトモード視認性テスト', () {
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

      testWidgets('会場フィールドの背景色がテキスト色（黒）ではないこと', (tester) async {
        await tester.pumpWidget(
          _wrapWithTheme(
            CreateTournamentPage2(
              venueController: venueController,
              notesController: notesController,
              onOpenMap: () {},
            ),
          ),
        );
        await tester.safePumpAndSettle();

        final fills = _collectFillColors(tester);
        expect(fills, isNotEmpty);

        for (final fill in fills) {
          expect(fill?.withAlpha(255), isNot(Colors.black));
        }
      });

      testWidgets('全入力欄(会場・メモ)の背景色がinputBackgroundと一致すること', (tester) async {
        await tester.pumpWidget(
          _wrapWithTheme(
            CreateTournamentPage2(
              venueController: venueController,
              notesController: notesController,
              onOpenMap: () {},
            ),
          ),
        );
        await tester.safePumpAndSettle();

        final expectedBg = Colors.grey.shade100;
        final fills = _collectFillColors(tester);
        expect(fills.length, 2);

        for (final fill in fills) {
          expect(fill, expectedBg);
        }
      });
    });

    // ----------------------------------------------------------
    // ダークモード（回帰テスト）
    // ----------------------------------------------------------
    group('ダークモード視認性テスト', () {
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

      testWidgets('Page1 ダークモード: 入力欄の背景色が白（= 文字色）ではないこと', (tester) async {
        await tester.pumpWidget(
          _wrapWithTheme(
            CreateTournamentPage1(
              nameController: nameController,
              selectedDate: DateTime(2025, 1, 1),
              onPickDate: () {},
            ),
            dark: true,
          ),
        );
        await tester.safePumpAndSettle();

        final fills = _collectFillColors(tester);
        for (final fill in fills) {
          expect(fill?.withAlpha(255), isNot(Colors.white));
        }
      });

      testWidgets('Page2 ダークモード: 入力欄の背景色が白（= 文字色）ではないこと', (tester) async {
        await tester.pumpWidget(
          _wrapWithTheme(
            CreateTournamentPage2(
              venueController: venueController,
              notesController: notesController,
              onOpenMap: () {},
            ),
            dark: true,
          ),
        );
        await tester.safePumpAndSettle();

        final fills = _collectFillColors(tester);
        for (final fill in fills) {
          expect(fill?.withAlpha(255), isNot(Colors.white));
        }
      });
    });
  });
}
