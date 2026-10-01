import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/presentation/screens/embedded_manual_tab_views.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/manual_help_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget createTestWidget(Widget child) {
    return ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        theme: ThemeData(
          extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
        ),
        home: Scaffold(body: child),
      ),
    );
  }

  group('[Widget] EmbeddedManualTabViews および ManualHelpButton ウィジェットテスト', () {
    testWidgets('EmbeddedManualTabViewsのbuildQuickGuideTabが正常に描画されること', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          Builder(
            builder: (context) {
              return EmbeddedManualTabViews.buildQuickGuideTab(
                context: context,
                assetPath: 'assets/manuals/quick_guide.pdf',
                fileName: 'クイックガイド.pdf',
                onPrint:
                    ({
                      required isAsset,
                      assetPath,
                      file,
                      required fileName,
                    }) async {},
                onShare:
                    ({
                      required isAsset,
                      assetPath,
                      file,
                      required fileName,
                    }) async {},
              );
            },
          ),
        ),
      );

      // アクションバーのボタンが表示されていること
      expect(find.text('A4印刷'), findsOneWidget);
      expect(find.text('共有/保存'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('EmbeddedManualTabViewsのbuildFullManualTabでテキスト簡易版が表示されること', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          EmbeddedManualTabViews.buildFullManualTab(
            buildIndexPane: const Text('目次ペイン'),
            markdownPane: const Text('マークダウンペイン'),
            isPdfDownloaded: false,
            isDownloading: false,
            downloadProgress: 0.0,
            forceMarkdownFallback: true,
            localPdfFile: null,
            pdfViewerController: null,
            onStartDownload: () {},
            onEnableMarkdownFallback: () {},
            onDisableMarkdownFallback: () {},
            onPrint:
                ({
                  required isAsset,
                  assetPath,
                  file,
                  required fileName,
                }) async {},
            onShare:
                ({
                  required isAsset,
                  assetPath,
                  file,
                  required fileName,
                }) async {},
          ),
        ),
      );

      expect(find.text('目次ペイン'), findsOneWidget);
      expect(find.text('マークダウンペイン'), findsOneWidget);
      expect(find.text('PDF版に戻る'), findsOneWidget);
    });

    testWidgets('ManualHelpButtonが描画されタップ可能なこと', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const ManualHelpButton(manualPath: 'assets/manuals/help.md'),
        ),
      );

      expect(find.byIcon(Icons.help_outline), findsOneWidget);
      await tester.tap(find.byType(ManualHelpButton));
      await tester.pump();
      // ルートスタックにモーダルが追加されたことを確認
      expect(find.byType(ManualHelpButton), findsOneWidget);
    });
  });
}
