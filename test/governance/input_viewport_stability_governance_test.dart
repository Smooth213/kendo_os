import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
  });
}
