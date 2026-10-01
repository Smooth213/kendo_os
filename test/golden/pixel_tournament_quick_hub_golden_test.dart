import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/tournament_quick_hub_banner.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Golden] 大会進行クイックハブバナー視覚整合性テスト', () {
    testWidgets('タブレット解像度においてダークテーマのクイックハブバナーが美しく描画されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final themeColors = AppThemeColors.ofMode(isDark: true, mode: 'normal');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TournamentQuickHubBanner(
                  tournamentId: 't_hub_golden',
                  isViewerMode: false,
                  themeColors: themeColors,
                  isDark: true,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(TournamentQuickHubBanner), findsOneWidget);
      expect(find.text('大会プログラム・進行表'), findsOneWidget);
      expect(find.text('手書きペン対応'), findsOneWidget);
      expect(find.byIcon(Icons.menu_book_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('スマートフォン解像度においてライトテーマでバナーが綺麗に収まり描画されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: TournamentQuickHubBanner(
                  tournamentId: 't_hub_phone',
                  isViewerMode: true,
                  themeColors: themeColors,
                  isDark: false,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(TournamentQuickHubBanner), findsOneWidget);
      expect(find.text('大会プログラム・進行表'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
