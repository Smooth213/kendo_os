import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/application/clipboard_import_service.dart';
import 'package:kendo_os/features/tournament/presentation/components/share_import/clipboard_import_button.dart';
import 'package:kendo_os/features/tournament/presentation/components/share_import/tournament_share_import_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/team_registration_screen.dart'
    show playerListProvider;
import 'package:intl/date_symbol_data_local.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('ja');
  });

  group('🛡️ ClipboardImportButton 視認性・スタイリング保証テスト', () {
    testWidgets('1. ライトモード（白背景）: 高コントラストディープアンバーと円形枠線コンテナで視認性が保証されていること', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const Scaffold(body: Center(child: ClipboardImportButton())),
        ),
      );
      await tester.pumpAndSettle();

      // アイコンの存在確認
      final iconFinder = find.byIcon(Icons.content_paste_go_rounded);
      expect(iconFinder, findsOneWidget);

      final icon = tester.widget<Icon>(iconFinder);
      // ライトモードでは濃いディープアンバー (Color(0xFFB45309))
      expect(icon.color, equals(const Color(0xFFB45309)));

      // 背景コンテナの装飾（円形・境界線）を確認
      final containerFinder = find.ancestor(
        of: find.byType(IconButton),
        matching: find.byType(Container),
      );
      expect(containerFinder, findsWidgets);

      final container = tester.widget<Container>(containerFinder.first);
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration, isNotNull);
      expect(decoration!.shape, equals(BoxShape.circle));
      expect(decoration.border, isNotNull);
    });

    testWidgets('2. ダークモード（黒背景）: 鮮やかなアンバーゴールドで視認性が保証されていること', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(body: Center(child: ClipboardImportButton())),
        ),
      );
      await tester.pumpAndSettle();

      final iconFinder = find.byIcon(Icons.content_paste_go_rounded);
      expect(iconFinder, findsOneWidget);

      final icon = tester.widget<Icon>(iconFinder);
      // ダークモードでは鮮やかなアンバーゴールド (Color(0xFFFBBF24))
      expect(icon.color, equals(const Color(0xFFFBBF24)));
    });

    testWidgets('3. ツールチップが「クリップボードから取り込み」に設定されていること', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: ClipboardImportButton())),
        ),
      );
      await tester.pumpAndSettle();

      final buttonFinder = find.byType(IconButton);
      expect(buttonFinder, findsOneWidget);
      final iconButton = tester.widget<IconButton>(buttonFinder);
      expect(iconButton.tooltip, equals('クリップボードから取り込み'));
    });
  });

  group('🛡️ ClipboardImportService 誤爆防止＆取り込み判定保証テスト', () {
    testWidgets('4. クリップボードが空の場合: 「テキストがコピーされていません」と案内されシートは開かないこと', (
      tester,
    ) async {
      // クリップボードをクリア
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'Clipboard.getData') {
            return <String, dynamic>{'text': ''};
          }
          return null;
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.dark().copyWith(
              extensions: [AppThemeColors.ofMode(isDark: true, mode: 'normal')],
            ),
            home: Scaffold(
              body: Builder(
                builder: (context) => Consumer(
                  builder: (context, ref, _) => ElevatedButton(
                    onPressed: () => ref
                        .read(clipboardImportServiceProvider)
                        .importManually(context),
                    child: const Text('取り込みテスト'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('取り込みテスト'));
      await tester.pumpAndSettle();

      // スナックバーメッセージの検証
      expect(find.text('クリップボードにテキストがコピーされていません'), findsOneWidget);
      // シートは開いていないこと
      expect(find.byType(TournamentShareImportSheet), findsNothing);
    });

    testWidgets(
      '5. 無関係なテキスト（Gitコマンド等）の場合: 「大会情報やオーダーが見つかりませんでした」と案内されシートは開かないこと',
      (tester) async {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (MethodCall methodCall) async {
            if (methodCall.method == 'Clipboard.getData') {
              return <String, dynamic>{
                'text': 'git add .\ngit push origin stage2-beta',
              };
            }
            return null;
          },
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: ThemeData.dark().copyWith(
                extensions: [
                  AppThemeColors.ofMode(isDark: true, mode: 'normal'),
                ],
              ),
              home: Scaffold(
                body: Builder(
                  builder: (context) => Consumer(
                    builder: (context, ref, _) => ElevatedButton(
                      onPressed: () => ref
                          .read(clipboardImportServiceProvider)
                          .importManually(context),
                      child: const Text('取り込みテスト'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('取り込みテスト'));
        await tester.pumpAndSettle();

        // 誤爆防止メッセージの検証
        expect(find.text('クリップボードに大会情報やオーダーが見つかりませんでした'), findsOneWidget);
        // シートは開いていないこと
        expect(find.byType(TournamentShareImportSheet), findsNothing);
      },
    );

    testWidgets('6. 正常な大会テキストの場合: TournamentShareImportSheet が正常に開くこと', (
      tester,
    ) async {
      const validTournamentText = '''
第30回 広島県少年剣道選手権大会
日時: 2026年10月10日
会場: 広島県立総合体育館
低学年の部
先鋒: 皿田 脩人
中堅: 塚本 大道
大将: 久安 智也
''';
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'Clipboard.getData') {
            return <String, dynamic>{'text': validTournamentText};
          }
          return null;
        },
      );

      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playerListProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: MaterialApp(
            theme: ThemeData.dark().copyWith(
              extensions: [AppThemeColors.ofMode(isDark: true, mode: 'normal')],
            ),
            home: Scaffold(
              body: Builder(
                builder: (context) => Consumer(
                  builder: (context, ref, _) => ElevatedButton(
                    onPressed: () => ref
                        .read(clipboardImportServiceProvider)
                        .importManually(context),
                    child: const Text('取り込みテスト'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('取り込みテスト'));
      await tester.pumpAndSettle();

      // シートが正常に表示されること
      expect(find.byType(TournamentShareImportSheet), findsOneWidget);
      expect(find.text('第30回 広島県少年剣道選手権大会'), findsOneWidget);
    });
  });
}
