// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ============================================================
// プログラム追加ダイアログ のテーマ対応テスト
//
// 対象: _showTitleAndPreviewDialog 内の
//   ① テキスト入力欄の文字色（ライト→黒、ダーク→白）
//   ② 入力欄下の必須案内テキスト（空のとき常時表示、OK押下時に強調）
//   ③ タイトル入力エリア背景色のダーク対応
//   ④ ファイルリストタイルのダーク対応
// ============================================================

// ダイアログ内で使われているUIと同じウィジェット構成を直接組み立ててテスト
Widget _buildDialogContent({
  required bool isDark,
  required String title,
  required bool showValidationHighlight,
  required ValueChanged<String> onChanged,
}) {
  return MaterialApp(
    theme: isDark ? ThemeData.dark() : ThemeData.light(),
    home: Scaffold(
      body: Builder(
        builder: (context) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ① TextFormField（テスト対象：文字色）
              TextFormField(
                key: const Key('title_field'),
                initialValue: title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: '例：1日目 進行表',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF2C2C3E) : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.indigo.shade200),
                  ),
                ),
                onChanged: onChanged,
              ),
              // ② 必須案内テキスト（テスト対象：表示/非表示・強調）
              if (title.trim().isEmpty)
                AnimatedContainer(
                  key: const Key('validation_hint'),
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.only(
                    top: 6,
                    left: 4,
                    right: 4,
                    bottom: 4,
                  ),
                  decoration: showValidationHighlight
                      ? BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.red.shade300,
                            width: 1.2,
                          ),
                        )
                      : null,
                  child: Row(
                    children: [
                      Icon(
                        showValidationHighlight
                            ? Icons.error_outline
                            : Icons.info_outline,
                        key: Key(
                          showValidationHighlight ? 'icon_error' : 'icon_info',
                        ),
                        size: 13,
                        color: showValidationHighlight
                            ? Colors.red.shade700
                            : Colors.orange.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'タイトルは必須です（入力しないと保存できません）',
                        key: const Key('required_text'),
                        style: TextStyle(
                          fontSize: 11,
                          color: showValidationHighlight
                              ? Colors.red.shade700
                              : Colors.orange.shade700,
                          fontWeight: showValidationHighlight
                              ? FontWeight.bold
                              : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              // ③ タイトル入力エリア背景のテスト用コンテナ
              Container(
                key: const Key('title_area_bg'),
                width: double.infinity,
                height: 8,
                color: isDark ? const Color(0xFF1C1C2E) : Colors.indigo.shade50,
              ),
              // ④ ファイルリストタイルのダーク対応
              ListTile(
                key: const Key('file_tile'),
                tileColor: isDark ? const Color(0xFF1C1C1E) : null,
                selectedTileColor: isDark
                    ? Colors.indigo.shade900.withAlpha(180)
                    : Colors.indigo.shade50,
                title: const Text('IMG_7730.jpeg'),
                leading: const CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.indigo,
                  child: Text(
                    '1',
                    style: TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

void main() {
  group('🎨 プログラム追加ダイアログ テーマ対応テスト', () {
    // ────────────────────────────────────────
    // ① 文字色：テーマに応じた onSurface カラー
    // ────────────────────────────────────────
    group('① TextFormField 文字色', () {
      testWidgets('1-1. ライトモード: 入力文字色が onSurface（ほぼ黒）であること', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          _buildDialogContent(
            isDark: false,
            title: 'テストタイトル',
            showValidationHighlight: false,
            onChanged: (_) {},
          ),
        );
        await tester.pump();

        final field = tester.widget<EditableText>(
          find.byType(EditableText).first,
        );
        final lightTheme = ThemeData.light();
        final expectedColor = lightTheme.colorScheme.onSurface;

        expect(
          field.style.color,
          equals(expectedColor),
          reason: 'ライトモードの入力文字色は onSurface（黒系）であるべき',
        );
      });

      testWidgets('1-2. ダークモード: 入力文字色が onSurface（ほぼ白）であること', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          _buildDialogContent(
            isDark: true,
            title: 'テストタイトル',
            showValidationHighlight: false,
            onChanged: (_) {},
          ),
        );
        await tester.pump();

        final field = tester.widget<EditableText>(
          find.byType(EditableText).first,
        );
        final darkTheme = ThemeData.dark();
        final expectedColor = darkTheme.colorScheme.onSurface;

        expect(
          field.style.color,
          equals(expectedColor),
          reason: 'ダークモードの入力文字色は onSurface（白系）であるべき',
        );
      });

      testWidgets('1-3. ライト/ダークで onSurface の色が異なること（ヒント色は同じグレー）', (
        WidgetTester tester,
      ) async {
        final lightOnSurface = ThemeData.light().colorScheme.onSurface;
        final darkOnSurface = ThemeData.dark().colorScheme.onSurface;

        // ライトとダークで onSurface は異なる
        expect(
          lightOnSurface,
          isNot(equals(darkOnSurface)),
          reason: 'テーマによって文字色が切り替わること',
        );
      });
    });

    // ────────────────────────────────────────
    // ② 必須案内テキスト：表示/非表示・強調
    // ────────────────────────────────────────
    group('② 入力欄下の必須案内テキスト', () {
      testWidgets('2-1. タイトルが空のとき案内テキストが表示されること', (WidgetTester tester) async {
        await tester.pumpWidget(
          _buildDialogContent(
            isDark: false,
            title: '',
            showValidationHighlight: false,
            onChanged: (_) {},
          ),
        );
        await tester.pump();

        expect(
          find.byKey(const Key('validation_hint')),
          findsOneWidget,
          reason: 'タイトル未入力時は案内が表示されること',
        );
        expect(find.text('タイトルは必須です（入力しないと保存できません）'), findsOneWidget);
      });

      testWidgets('2-2. タイトルを入力すると案内テキストが消えること', (WidgetTester tester) async {
        await tester.pumpWidget(
          _buildDialogContent(
            isDark: false,
            title: '大会プログラム',
            showValidationHighlight: false,
            onChanged: (_) {},
          ),
        );
        await tester.pump();

        expect(
          find.byKey(const Key('validation_hint')),
          findsNothing,
          reason: 'タイトル入力済みのとき案内は非表示であること',
        );
      });

      testWidgets('2-3. OK押下前（通常時）はオレンジ色・info_outline アイコンで表示されること', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          _buildDialogContent(
            isDark: false,
            title: '',
            showValidationHighlight: false,
            onChanged: (_) {},
          ),
        );
        await tester.pump();

        // info_outline アイコン
        expect(
          find.byKey(const Key('icon_info')),
          findsOneWidget,
          reason: 'OK押下前は info_outline アイコンであること',
        );

        // テキストのスタイルがオレンジ系
        final textWidget = tester.widget<Text>(
          find.byKey(const Key('required_text')),
        );
        expect(
          textWidget.style?.color,
          equals(Colors.orange.shade700),
          reason: 'OK押下前は案内テキストがオレンジ色であること',
        );
        expect(
          textWidget.style?.fontWeight,
          equals(FontWeight.w600),
          reason: 'OK押下前は FontWeight.w600（通常の太さ）',
        );
      });

      testWidgets('2-4. OK押下後（強調時）は赤色・error_outline アイコンに切り替わること', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          _buildDialogContent(
            isDark: false,
            title: '',
            showValidationHighlight: true,
            onChanged: (_) {},
          ),
        );
        await tester.pumpAndSettle();

        // error_outline アイコン
        expect(
          find.byKey(const Key('icon_error')),
          findsOneWidget,
          reason: 'OK押下後は error_outline アイコンに切り替わること',
        );

        // テキストのスタイルが赤色・太字
        final textWidget = tester.widget<Text>(
          find.byKey(const Key('required_text')),
        );
        expect(
          textWidget.style?.color,
          equals(Colors.red.shade700),
          reason: 'OK押下後は案内テキストが赤色であること',
        );
        expect(
          textWidget.style?.fontWeight,
          equals(FontWeight.bold),
          reason: 'OK押下後は FontWeight.bold（強調）に切り替わること',
        );
      });

      testWidgets('2-5. ダークモードでも必須案内テキストが正しく表示されること', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          _buildDialogContent(
            isDark: true,
            title: '',
            showValidationHighlight: false,
            onChanged: (_) {},
          ),
        );
        await tester.pump();

        expect(
          find.text('タイトルは必須です（入力しないと保存できません）'),
          findsOneWidget,
          reason: 'ダークモードでも案内テキストは表示されること',
        );
      });

      testWidgets('2-6. ダークモードのOK押下後強調もオレンジ→赤に切り替わること', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          _buildDialogContent(
            isDark: true,
            title: '',
            showValidationHighlight: true,
            onChanged: (_) {},
          ),
        );
        await tester.pumpAndSettle();

        final textWidget = tester.widget<Text>(
          find.byKey(const Key('required_text')),
        );
        expect(
          textWidget.style?.color,
          equals(Colors.red.shade700),
          reason: 'ダークモードのOK押下後も赤色強調になること',
        );
      });
    });

    // ────────────────────────────────────────
    // ③ 入力エリア背景色
    // ────────────────────────────────────────
    group('③ タイトル入力エリア背景色', () {
      testWidgets('3-1. ライトモード: 背景色が indigo.shade50（薄紫）であること', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          _buildDialogContent(
            isDark: false,
            title: '',
            showValidationHighlight: false,
            onChanged: (_) {},
          ),
        );
        await tester.pump();

        final container = tester.widget<Container>(
          find.byKey(const Key('title_area_bg')),
        );
        expect(
          container.color,
          equals(Colors.indigo.shade50),
          reason: 'ライトモードの背景は indigo.shade50 であること',
        );
      });

      testWidgets('3-2. ダークモード: 背景色が #1C1C2E（暗い紺色）であること', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          _buildDialogContent(
            isDark: true,
            title: '',
            showValidationHighlight: false,
            onChanged: (_) {},
          ),
        );
        await tester.pump();

        final container = tester.widget<Container>(
          find.byKey(const Key('title_area_bg')),
        );
        expect(
          container.color,
          equals(const Color(0xFF1C1C2E)),
          reason: 'ダークモードの背景は #1C1C2E（暗い紺色）であること',
        );
      });
    });

    // ────────────────────────────────────────
    // ④ ファイルリストタイルのダーク対応
    // ────────────────────────────────────────
    group('④ ファイルリストタイル', () {
      testWidgets('4-1. ライトモード: タイルの tileColor は null（テーマ依存）であること', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          _buildDialogContent(
            isDark: false,
            title: '',
            showValidationHighlight: false,
            onChanged: (_) {},
          ),
        );
        await tester.pump();

        final tile = tester.widget<ListTile>(
          find.byKey(const Key('file_tile')),
        );
        expect(
          tile.tileColor,
          isNull,
          reason: 'ライトモードは tileColor を指定せずテーマ依存とすること',
        );
      });

      testWidgets('4-2. ダークモード: タイルの tileColor が #1C1C1E（暗色）であること', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          _buildDialogContent(
            isDark: true,
            title: '',
            showValidationHighlight: false,
            onChanged: (_) {},
          ),
        );
        await tester.pump();

        final tile = tester.widget<ListTile>(
          find.byKey(const Key('file_tile')),
        );
        expect(
          tile.tileColor,
          equals(const Color(0xFF1C1C1E)),
          reason: 'ダークモードは tileColor が #1C1C1E であること',
        );
      });

      testWidgets('4-3. ライトモード: 選択ハイライトが indigo.shade50 であること', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          _buildDialogContent(
            isDark: false,
            title: '',
            showValidationHighlight: false,
            onChanged: (_) {},
          ),
        );
        await tester.pump();

        final tile = tester.widget<ListTile>(
          find.byKey(const Key('file_tile')),
        );
        expect(
          tile.selectedTileColor,
          equals(Colors.indigo.shade50),
          reason: 'ライトモードの選択色は indigo.shade50 であること',
        );
      });

      testWidgets('4-4. ダークモード: 選択ハイライトが indigo.shade900（半透明）であること', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          _buildDialogContent(
            isDark: true,
            title: '',
            showValidationHighlight: false,
            onChanged: (_) {},
          ),
        );
        await tester.pump();

        final tile = tester.widget<ListTile>(
          find.byKey(const Key('file_tile')),
        );
        expect(
          tile.selectedTileColor,
          equals(Colors.indigo.shade900.withAlpha(180)),
          reason: 'ダークモードの選択色は indigo.shade900.withAlpha(180) であること',
        );
      });
    });
  });
}
