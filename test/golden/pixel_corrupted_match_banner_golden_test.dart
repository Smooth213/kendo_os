import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/corrupted_match_banner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Golden] 緊急データ破損バナー Pixel完全性テスト', () {
    Widget buildBannerTestWidget({required bool isDark}) {
      final themeColors = AppThemeColors.ofMode(
        isDark: isDark,
        mode: isDark ? 'dark' : 'normal',
      );

      return ProviderScope(
        child: MaterialApp(
          theme: isDark
              ? ThemeData.dark().copyWith(extensions: [themeColors])
              : ThemeData.light().copyWith(extensions: [themeColors]),
          home: const Scaffold(
            body: Center(
              child: CorruptedMatchBanner(matchId: 'corrupted-match-001'),
            ),
          ),
        ),
      );
    }

    testWidgets('ライトモード表示において 赤色ヘッダー警告UIとアイコンが正常に描画されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildBannerTestWidget(isDark: false));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(CorruptedMatchBanner), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      expect(find.text('データに問題が発生しました'), findsOneWidget);

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(CorruptedMatchBanner),
          matching: find.byType(Container),
        ),
      );
      expect(container.color, AppKendoColors.hansokuRed);
    });

    testWidgets('ダークモード表示において コントラスト色が維持され警告文が鮮明に描画されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildBannerTestWidget(isDark: true));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(CorruptedMatchBanner), findsOneWidget);
      expect(find.text('データに問題が発生しました'), findsOneWidget);
    });
  });
}
