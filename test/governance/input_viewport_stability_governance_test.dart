import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/band/presentation/components/band_group_edit_dialog.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/create_tournament/create_tournament_page1.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/create_tournament/create_tournament_page2.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_edit_comment_dialog.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_unified_announce_dialog.dart';
import 'package:kendo_os/shared/domain/entities/match_comment_model.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';
import 'package:kendo_os/shared/widgets/room_join_qr_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================================
// 🥋 【第5条 第4項 ガバナンス監査】入力フォーカス時ビューポート安定性・跳ね上がり防止保証テスト
// ============================================================================
// ソフトウェアキーボード表示時に入力欄やダイアログが画面外へ跳ね上がる現象を
// 恒久的に根絶するため、静的コード解析およびウィジェットテストにより厳密に検証します。
// ============================================================================
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('🌐 【第5条 第4項】入力フォーカス時ビューポート安定性・跳ね上がり防止ガバナンス監査', () {
    // -------------------------------------------------------------------------
    // 1. 静的アーキテクチャ規約検証
    // -------------------------------------------------------------------------
    test(
      '1. [基盤統一TextField] AppTextField のデフォルト scrollPadding が EdgeInsets.zero であること',
      () {
        const field = AppTextField();
        expect(
          field.scrollPadding,
          equals(EdgeInsets.zero),
          reason:
              'AppTextField のデフォルト scrollPadding は余計な強制スクロール（跳ね上がり）を防ぐため EdgeInsets.zero でなければなりません',
        );
      },
    );

    test(
      '2. [主要入力モーダル] アナウンス・コメント・道場ID・選手マスタ登録が showAppBottomSheet かつ isScrollControlled: true であること',
      () {
        final targets = [
          'lib/features/tournament/presentation/operate/components/timeline/timeline_unified_announce_dialog.dart',
          'lib/features/tournament/presentation/operate/components/timeline/timeline_edit_comment_dialog.dart',
          'lib/shared/widgets/room_join_qr_dialog.dart',
          'lib/admin/presentation/components/master_player_edit_bottom_sheet.dart',
        ];

        for (final path in targets) {
          final file = File(path);
          expect(file.existsSync(), isTrue, reason: '$path が存在すること');
          final content = file.readAsStringSync();

          expect(
            content.contains('showAppDialog('),
            isFalse,
            reason: '$path では跳ね上がり防止のため showAppDialog の使用は禁止されています',
          );
          expect(
            content.contains('showAppBottomSheet('),
            isTrue,
            reason: '$path では下部固定・キーボード追従のため showAppBottomSheet を使用してください',
          );
          expect(
            content.contains('isScrollControlled: true'),
            isTrue,
            reason:
                '$path ではキーボード出現時の高さ制限破綻を防ぐため isScrollControlled: true が必須です',
          );
        }
      },
    );

    test(
      '3. [全入力フィールド規約] lib/配下の TextField / TextFormField は AppTextField または scrollPadding: EdgeInsets.zero が保証されていること',
      () {
        final libDir = Directory('lib');
        final dartFiles = libDir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))
            .where(
              (f) =>
                  !f.path.endsWith('.freezed.dart') &&
                  !f.path.endsWith('.g.dart'),
            )
            .where(
              (f) =>
                  !f.path.endsWith('app_text_field.dart') &&
                  !f.path.endsWith('web_viewer_html.dart'),
            );

        final violations = <String>[];
        for (final file in dartFiles) {
          final content = file.readAsStringSync();
          final matches = RegExp(
            r'(?<!App)\b(TextField|TextFormField)\s*\(',
          ).allMatches(content);

          for (final m in matches) {
            final start = m.start;
            final snippet = content.substring(
              start,
              (start + 800 < content.length) ? start + 800 : content.length,
            );
            if (!snippet.contains('scrollPadding: EdgeInsets.zero')) {
              final lineNum = content.substring(0, start).split('\n').length;
              violations.add('${file.path}:$lineNum (${m.group(1)})');
            }
          }
        }

        expect(
          violations,
          isEmpty,
          reason:
              '生の TextField/TextFormField で scrollPadding: EdgeInsets.zero が指定されていない箇所が検出されました:\n${violations.join('\n')}',
        );
      },
    );

    test(
      '4. [基盤Scaffold二重リサイズ防止] lib/main.dart のベース Scaffold に resizeToAvoidBottomInset: false が設定されていること',
      () {
        final mainFile = File('lib/main.dart');
        expect(mainFile.existsSync(), isTrue);
        final content = mainFile.readAsStringSync();

        expect(
          content.contains('resizeToAvoidBottomInset: false'),
          isTrue,
          reason:
              'lib/main.dart のベース Scaffold に resizeToAvoidBottomInset: false が設定されていないと、'
              'キーボード出現時に外側と内側で二重リサイズが発生し、入力欄やダイアログが画面外へ跳ね上がってしまいます。',
        );
      },
    );

    // -------------------------------------------------------------------------
    // 2. ウィジェット・キーボード出現時跳ね上がり・破綻防止テスト
    // -------------------------------------------------------------------------
    testWidgets(
      '4. [ウィジェット検証] TimelineUnifiedAnnounceDialog でキーボード出現時 (viewInsets: 320) も画面外へ跳ね上がらず正常表示されること',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390 * 2, 844 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final themeColors = AppThemeColors.ofMode(
          isDark: false,
          mode: 'normal',
        );
        final prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            child: MaterialApp(
              theme: ThemeData.light().copyWith(extensions: [themeColors]),
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, child) {
                    return ElevatedButton(
                      onPressed: () {
                        TimelineUnifiedAnnounceDialog.show(
                          context,
                          ref,
                          'test_tourney',
                          '一般の部',
                          'Aリーグ',
                          1.0,
                        );
                      },
                      child: const Text('開く'),
                    );
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('開く'));
        await tester.pumpAndSettle();

        // ダイアログ・ボトムシートが開いていること
        expect(find.text('公式アナウンス・コメントの一斉発信'), findsOneWidget);

        // ソフトウェアキーボード出現シミュレーション (320px)
        tester.view.viewInsets = const FakeViewPadding(bottom: 320);
        addTearDown(() => tester.view.viewInsets = FakeViewPadding.zero);
        await tester.pumpAndSettle();

        // キーボード出現後もタイトルおよび入力欄が消滅・跳ね上がらず、画面内に存在すること
        expect(find.text('公式アナウンス・コメントの一斉発信'), findsOneWidget);
        expect(
          find.byKey(const Key('timeline_submit_announce_button')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '5. [ウィジェット検証] TimelineEditCommentDialog でキーボード出現時 (viewInsets: 320) も破綻なく正常表示されること',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390 * 2, 844 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final themeColors = AppThemeColors.ofMode(
          isDark: false,
          mode: 'normal',
        );
        final prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            child: MaterialApp(
              theme: ThemeData.light().copyWith(extensions: [themeColors]),
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, child) {
                    return ElevatedButton(
                      onPressed: () {
                        TimelineEditCommentDialog.show(
                          context,
                          ref,
                          const MatchCommentModel(id: 'c1', text: '既存コメント'),
                        );
                      },
                      child: const Text('開く'),
                    );
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('開く'));
        await tester.pumpAndSettle();

        expect(find.text('見出し（コメント）の編集'), findsOneWidget);

        // ソフトウェアキーボード出現シミュレーション (320px)
        tester.view.viewInsets = const FakeViewPadding(bottom: 320);
        addTearDown(() => tester.view.viewInsets = FakeViewPadding.zero);
        await tester.pumpAndSettle();

        expect(find.text('見出し（コメント）の編集'), findsOneWidget);
        expect(find.text('保存'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '6. [ウィジェット検証] RoomJoinQrDialog (道場ID入力) でキーボード出現時 (viewInsets: 320) も正常描画されること',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390 * 2, 844 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final themeColors = AppThemeColors.ofMode(
          isDark: false,
          mode: 'normal',
        );
        final prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            child: MaterialApp(
              theme: ThemeData.light().copyWith(extensions: [themeColors]),
              home: Scaffold(
                body: Builder(
                  builder: (context) {
                    return ElevatedButton(
                      onPressed: () => RoomJoinQrDialog.show(context),
                      child: const Text('開く'),
                    );
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('開く'));
        await tester.pumpAndSettle();

        expect(find.text('道場ルームへの参加'), findsOneWidget);

        // ソフトウェアキーボード出現シミュレーション (320px)
        tester.view.viewInsets = const FakeViewPadding(bottom: 320);
        addTearDown(() => tester.view.viewInsets = FakeViewPadding.zero);
        await tester.pumpAndSettle();

        expect(find.text('道場ルームへの参加'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '7. [ウィジェット検証] 外側ベースScaffold配下のAppDialogでキーボード出現時 (viewInsets: 320) も画面上部へ跳ね上がらず正常に画面内に留まること',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390 * 2, 844 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final themeColors = AppThemeColors.ofMode(
          isDark: false,
          mode: 'normal',
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light().copyWith(extensions: [themeColors]),
            builder: (context, child) {
              // main.dart と同一の外側ベースScaffold構成
              return Scaffold(
                backgroundColor: Colors.white,
                resizeToAvoidBottomInset: false,
                body: child ?? const SizedBox.shrink(),
              );
            },
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('テスト入力ダイアログ'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text('ダイアログ本文'),
                              TextField(scrollPadding: EdgeInsets.zero),
                            ],
                          ),
                        ),
                      );
                    },
                    child: const Text('ダイアログ開く'),
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('ダイアログ開く'));
        await tester.pumpAndSettle();

        expect(find.text('テスト入力ダイアログ'), findsOneWidget);

        // キーボード出現 (320px)
        tester.view.viewInsets = const FakeViewPadding(bottom: 320);
        addTearDown(() => tester.view.viewInsets = FakeViewPadding.zero);
        await tester.pumpAndSettle();

        // ダイアログのタイトルが画面内に存在すること
        final titleFinder = find.text('テスト入力ダイアログ');
        expect(titleFinder, findsOneWidget);

        // ダイアログのY座標が画面外（負の座標）へ跳ね上がっていないことを検証
        final titleTopY = tester.getTopLeft(titleFinder).dy;
        expect(
          titleTopY > 0,
          isTrue,
          reason: 'ダイアログのタイトルが画面上部外(Y < 0)へ跳ね上がっていないこと (実際: $titleTopY)',
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '8. [ウィジェット検証] 外側ベースScaffold配下の通常画面入力欄でキーボード出現時 (viewInsets: 320) も画面外へ跳ね上がらず正常表示されること',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390 * 2, 844 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final themeColors = AppThemeColors.ofMode(
          isDark: false,
          mode: 'normal',
        );

        final controller = TextEditingController();

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light().copyWith(extensions: [themeColors]),
            builder: (context, child) {
              return Scaffold(
                backgroundColor: Colors.white,
                resizeToAvoidBottomInset: false,
                body: child ?? const SizedBox.shrink(),
              );
            },
            home: Scaffold(
              appBar: AppBar(title: const Text('大会新規作成')),
              body: ListView(
                children: [
                  const Text('大会の名前と日付'),
                  AppTextField(controller: controller, labelText: '大会名'),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('大会の名前と日付'), findsOneWidget);
        expect(find.text('大会名'), findsOneWidget);

        // キーボード出現 (320px)
        tester.view.viewInsets = const FakeViewPadding(bottom: 320);
        addTearDown(() => tester.view.viewInsets = FakeViewPadding.zero);
        await tester.pumpAndSettle();

        // キーボード出現後も通常画面のAppBarおよびヘッダー・入力欄が正常に画面内に存在すること
        final headerFinder = find.text('大会の名前と日付');
        expect(headerFinder, findsOneWidget);
        final headerTopY = tester.getTopLeft(headerFinder).dy;
        expect(
          headerTopY > 0,
          isTrue,
          reason: '通常画面の見出しが画面外(Y < 0)へ跳ね上がっていないこと (実際: $headerTopY)',
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '9. [カーソルフォーカス時跳ね上がりゼロ検証] 入力欄をタップしてカーソルを合わせた瞬間にビューポートスクロールオフセットがゼロを維持し、不自然な跳ね上がり変位（ΔY）がゼロであること',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390 * 2, 844 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final scrollController = ScrollController();
        final focusNode = FocusNode();
        final textController = TextEditingController();

        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) {
              return Scaffold(
                backgroundColor: Colors.white,
                resizeToAvoidBottomInset: false,
                body: child ?? const SizedBox.shrink(),
              );
            },
            home: Scaffold(
              body: ListView(
                controller: scrollController,
                children: [
                  const SizedBox(height: 50),
                  const Text('ヘッダータイトル'),
                  const SizedBox(height: 20),
                  AppTextField(
                    key: const Key('focus_test_field'),
                    controller: textController,
                    focusNode: focusNode,
                    labelText: 'フォーカステスト入力欄',
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final initialOffset = scrollController.offset;
        final initialFieldY = tester
            .getTopLeft(find.byKey(const Key('focus_test_field')))
            .dy;
        expect(initialOffset, equals(0.0));

        // 🎯 入力欄をタップしてカーソルを合わせる（フォーカス付与）
        await tester.tap(find.byKey(const Key('focus_test_field')));
        await tester.pumpAndSettle();

        expect(focusNode.hasFocus, isTrue);

        // カーソルフォーカス直後のスクロールオフセットおよびY座標が跳ね上がっていないこと（ΔY == 0）
        final focusedOffset = scrollController.offset;
        final focusedFieldY = tester
            .getTopLeft(find.byKey(const Key('focus_test_field')))
            .dy;

        expect(
          focusedOffset,
          equals(0.0),
          reason: 'カーソルフォーカス時に scrollPadding によりスクロール位置が勝手に跳ね上がっていないこと',
        );
        expect(
          (focusedFieldY - initialFieldY).abs() < 1.0,
          isTrue,
          reason:
              'カーソルフォーカス時に入力欄の垂直位置（Y座標）が跳ね上がっていないこと (初期: $initialFieldY, フォーカス後: $focusedFieldY)',
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '10. [実機画面検証: 大会新規作成] CreateTournamentPage1 の大会名入力欄をタップしてカーソルを合わせた際、見出しおよび入力欄が一切跳ね上がらず正常表示されること',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390 * 2, 844 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final themeColors = AppThemeColors.ofMode(
          isDark: false,
          mode: 'normal',
        );
        final nameController = TextEditingController();

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: ThemeData.light().copyWith(extensions: [themeColors]),
              builder: (context, child) {
                return Scaffold(
                  backgroundColor: Colors.white,
                  resizeToAvoidBottomInset: false,
                  body: child ?? const SizedBox.shrink(),
                );
              },
              home: Scaffold(
                body: CreateTournamentPage1(
                  nameController: nameController,
                  selectedDate: DateTime(2026, 9, 25),
                  onPickDate: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final titleFinder = find.text('大会の名前と日付を\n教えてください');
        expect(titleFinder, findsOneWidget);
        final initialTitleY = tester.getTopLeft(titleFinder).dy;

        // 🎯 大会名入力欄をタップしてカーソルを合わせる
        final inputFinder = find.byType(TextFormField);
        expect(inputFinder, findsOneWidget);
        await tester.tap(inputFinder);
        await tester.pumpAndSettle();

        // キーボード出現シミュレーション (320px)
        tester.view.viewInsets = const FakeViewPadding(bottom: 320);
        addTearDown(() => tester.view.viewInsets = FakeViewPadding.zero);
        await tester.pumpAndSettle();

        // フォーカス＆キーボード出現後も見出しが画面上部外(Y < 0)へ跳ね上がらず、画面内に保持されていること
        final currentTitleY = tester.getTopLeft(titleFinder).dy;
        expect(
          currentTitleY >= 0,
          isTrue,
          reason:
              '大会作成画面の見出しが画面外(Y < 0)へ跳ね上がっていないこと (初期: $initialTitleY, 現行: $currentTitleY)',
        );
        expect(find.text('大会の名前と日付を\n教えてください'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '11. [実機画面検証: 大会会場・備考入力] CreateTournamentPage2 の会場名・備考入力欄をタップしてフォーカス移動した際にも跳ね上がらず安定描画されること',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390 * 2, 844 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final themeColors = AppThemeColors.ofMode(
          isDark: false,
          mode: 'normal',
        );
        final venueController = TextEditingController();
        final notesController = TextEditingController();

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: ThemeData.light().copyWith(extensions: [themeColors]),
              builder: (context, child) {
                return Scaffold(
                  backgroundColor: Colors.white,
                  resizeToAvoidBottomInset: false,
                  body: child ?? const SizedBox.shrink(),
                );
              },
              home: Scaffold(
                body: CreateTournamentPage2(
                  venueController: venueController,
                  notesController: notesController,
                  onOpenMap: () {},
                ),
              ),
            ),
          ),
        );
        expect(find.text('会場・住所'), findsOneWidget);
        expect(find.text('大会メモ（任意）'), findsOneWidget);

        // 🎯 会場名入力欄をタップしてカーソルを合わせる
        final venueFinder = find.byType(TextFormField).first;
        await tester.tap(venueFinder);
        await tester.pumpAndSettle();

        // キーボード出現
        tester.view.viewInsets = const FakeViewPadding(bottom: 320);
        addTearDown(() => tester.view.viewInsets = FakeViewPadding.zero);
        await tester.pumpAndSettle();

        expect(find.text('会場・住所'), findsOneWidget);

        // 🎯 備考欄へカーソル移動
        final notesFinder = find.byType(TextFormField).last;
        await tester.tap(notesFinder);
        await tester.pumpAndSettle();

        expect(find.text('大会メモ（任意）'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '12. [実機ダイアログ検証: BANDグループ編集] BandGroupEditDialog の名前・URL入力欄にカーソルを合わせた際、ダイアログが画面上部外へ跳ね上がらず中央に保持されること',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390 * 2, 844 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final themeColors = AppThemeColors.ofMode(
          isDark: false,
          mode: 'normal',
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: ThemeData.light().copyWith(extensions: [themeColors]),
              builder: (context, child) {
                return Scaffold(
                  backgroundColor: Colors.white,
                  resizeToAvoidBottomInset: false,
                  body: child ?? const SizedBox.shrink(),
                );
              },
              home: Scaffold(
                body: Builder(
                  builder: (context) {
                    return ElevatedButton(
                      onPressed: () => BandGroupEditDialog.show(context),
                      child: const Text('ダイアログ開く'),
                    );
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('ダイアログ開く'));
        await tester.pumpAndSettle();

        expect(find.text('新しいBANDグループを追加'), findsOneWidget);

        // 🎯 グループ名入力欄にカーソルを合わせる
        final nameField = find.byType(AppTextField).first;
        await tester.tap(nameField);
        await tester.pumpAndSettle();

        // キーボード出現 (320px)
        tester.view.viewInsets = const FakeViewPadding(bottom: 320);
        addTearDown(() => tester.view.viewInsets = FakeViewPadding.zero);
        await tester.pumpAndSettle();

        // ダイアログのタイトルが画面内に存在し、上端が正の座標（Y > 0）に留まること
        final dialogTitleFinder = find.text('新しいBANDグループを追加');
        expect(dialogTitleFinder, findsOneWidget);
        final dialogTopY = tester.getTopLeft(dialogTitleFinder).dy;
        expect(
          dialogTopY > 0,
          isTrue,
          reason: 'BAND編集ダイアログが画面外(Y < 0)へ跳ね上がっていないこと (実際: $dialogTopY)',
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '13. [フォーム内複数入力欄のフォーカス連続遷移検証] フォーム内の複数入力フィールド間をフォーカス遷移（Tab移動/次へ）した際にもビューポートが跳ね上がらず安定描画されること',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390 * 2, 844 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final node1 = FocusNode();
        final node2 = FocusNode();
        final node3 = FocusNode();
        final scrollController = ScrollController();

        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) {
              return Scaffold(
                backgroundColor: Colors.white,
                resizeToAvoidBottomInset: false,
                body: child ?? const SizedBox.shrink(),
              );
            },
            home: Scaffold(
              body: ListView(
                controller: scrollController,
                children: [
                  const SizedBox(height: 40),
                  const Text('フォーム見出し'),
                  AppTextField(
                    key: const Key('field_item_1'),
                    focusNode: node1,
                    labelText: '項目1',
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    key: const Key('field_item_2'),
                    focusNode: node2,
                    labelText: '項目2',
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    key: const Key('field_item_3'),
                    focusNode: node3,
                    labelText: '項目3',
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // キーボード常時出現 (320px)
        tester.view.viewInsets = const FakeViewPadding(bottom: 320);
        addTearDown(() => tester.view.viewInsets = FakeViewPadding.zero);
        await tester.pumpAndSettle();

        // 1番目をタップしてフォーカス
        await tester.tap(find.byKey(const Key('field_item_1')));
        await tester.pumpAndSettle();
        expect(node1.hasFocus, isTrue);
        expect(tester.getTopLeft(find.text('フォーム見出し')).dy >= 0, isTrue);

        // 2番目をタップしてフォーカス遷移
        await tester.tap(find.byKey(const Key('field_item_2')));
        await tester.pumpAndSettle();
        expect(node2.hasFocus, isTrue);
        expect(tester.getTopLeft(find.text('フォーム見出し')).dy >= 0, isTrue);

        // 3番目をタップしてフォーカス遷移
        await tester.tap(find.byKey(const Key('field_item_3')));
        await tester.pumpAndSettle();
        expect(node3.hasFocus, isTrue);
        expect(tester.getTopLeft(find.text('フォーム見出し')).dy >= 0, isTrue);

        expect(tester.takeException(), isNull);
      },
    );
  });
}
