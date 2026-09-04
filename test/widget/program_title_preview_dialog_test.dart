import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/program_title_preview_dialog.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final dummyFiles = [
    PlatformFile(
      name: '第41回油木高校杯争奪少年剣道大会.pdf',
      size: 1024,
      bytes: null,
      path: 'dummy/path/file1.pdf',
    ),
    PlatformFile(
      name: '2日目_決勝トーナメント.pdf',
      size: 2048,
      bytes: null,
      path: 'dummy/path/file2.pdf',
    ),
  ];

  Widget createDialogTestWidget({
    required bool isDark,
    required List<PlatformFile> files,
  }) {
    final themeColors = AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
    return MaterialApp(
      theme: (isDark ? ThemeData.dark() : ThemeData.light()).copyWith(
        extensions: [themeColors],
      ),
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  ProgramTitlePreviewDialog.show(
                    context: context,
                    files: files,
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          );
        },
      ),
    );
  }

  group('🥋 ProgramTitlePreviewDialog 視認性・コントラスト保護テスト', () {
    testWidgets('☀️ ライトモード: 選択中ファイル名・ラベル・ガイドが背景と同化せず、高コントラストで視認できること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        createDialogTestWidget(isDark: false, files: dummyFiles),
      );
      await tester.pumpAndSettle();

      // ダイアログを開く
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // 1. ラベル「📝 プログラム名（ベースタイトル）」の視認性検証
      final labelFinder = find.text('📝 プログラム名（ベースタイトル）');
      expect(labelFinder, findsOneWidget);
      final Text labelText = tester.widget(labelFinder);
      final TextStyle labelStyle = labelText.style!;

      // 背景コンテナの取得
      final containerFinder = find.ancestor(
        of: labelFinder,
        matching: find.byWidgetPredicate(
          (widget) => widget is Container && widget.color != null,
        ),
      );
      expect(containerFinder, findsWidgets);
      final Container parentContainer = tester.widget(containerFinder.first);

      expect(
        labelStyle.color,
        isNot(equals(parentContainer.color)),
        reason: 'ヘッダーのラベルが背景色と同化してはいけません',
      );

      // 2. 選択中アイテム（1つ目）のファイル名テキストと背景のコントラスト検証
      final firstFileTextFinder = find.text('第41回油木高校杯争奪少年剣道大会.pdf');
      expect(firstFileTextFinder, findsOneWidget);
      final Text firstFileText = tester.widget(firstFileTextFinder);
      final TextStyle firstFileStyle = firstFileText.style!;

      // 選択中タイルの Material を取得
      final tileMaterialFinder = find.ancestor(
        of: firstFileTextFinder,
        matching: find.byWidgetPredicate(
          (widget) => widget is Material && widget.color != null,
        ),
      );
      expect(tileMaterialFinder, findsWidgets);
      final Material tileMaterial = tester.widget(tileMaterialFinder.first);

      // 文字色と背景色が同じ（以前のバグ: 濃い青に濃い青文字）になっていないこと
      expect(
        firstFileStyle.color,
        isNot(equals(tileMaterial.color)),
        reason: '選択中ファイル名の文字色がタイル背景色と同化してはいけません',
      );
      expect(
        firstFileStyle.color,
        isNot(equals(const Color(0xFF3F51B5))),
        reason: '暗い同系色でコントラスト崩壊してはいけません',
      );

      // 3. CircleAvatar バッジの視認性検証
      final badgeFinder = find.text('1');
      expect(badgeFinder, findsOneWidget);
      final Text badgeText = tester.widget(badgeFinder);
      final CircleAvatar badgeAvatar = tester.widget(
        find.ancestor(of: badgeFinder, matching: find.byType(CircleAvatar)),
      );

      expect(
        badgeText.style?.color,
        isNot(equals(badgeAvatar.backgroundColor)),
        reason: 'バッジ内の数字とアバター背景が同化してはいけません',
      );
      expect(badgeText.style?.color, equals(AppKendoColors.pureWhite));

      // 4. ガイドメッセージの視認性検証
      final guideFinder = find.textContaining('複数アップロードのガイド');
      expect(guideFinder, findsOneWidget);
      final Text guideText = tester.widget(guideFinder);
      expect(
        guideText.style?.color,
        isNotNull,
        reason: 'ガイドテキストに視認性の高いスタイルが適用されていること',
      );
    });

    testWidgets('🌙 ダークモード: 選択中ファイル名・ラベル・バッジが高コントラストで視認できること', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        createDialogTestWidget(isDark: true, files: dummyFiles),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // 1. ラベル「📝 プログラム名（ベースタイトル）」が白系でクッキリ視認できること
      final labelFinder = find.text('📝 プログラム名（ベースタイトル）');
      expect(labelFinder, findsOneWidget);
      final Text labelText = tester.widget(labelFinder);
      expect(labelText.style?.color, equals(AppKendoColors.pureWhite));

      // 2. 選択中ファイル名が白系でクッキリ視認できること
      final firstFileTextFinder = find.text('第41回油木高校杯争奪少年剣道大会.pdf');
      expect(firstFileTextFinder, findsOneWidget);
      final Text firstFileText = tester.widget(firstFileTextFinder);
      expect(firstFileText.style?.color, equals(AppKendoColors.pureWhite));

      // 3. バッジ内の数字が白文字で視認できること
      final badgeFinder = find.text('1');
      expect(badgeFinder, findsOneWidget);
      final Text badgeText = tester.widget(badgeFinder);
      expect(badgeText.style?.color, equals(AppKendoColors.pureWhite));
    });
  });
}
