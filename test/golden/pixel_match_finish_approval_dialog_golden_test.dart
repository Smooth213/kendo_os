import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_finished_navigation_dialog.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('[Golden] 試合確定・承認ダイアログ ピクセル・視覚完全性テスト', () {
    testWidgets('勝敗確定時および錬成会続行時のダイアログピクセル配置が検証されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(extensions: [themeColors]),
          home: Scaffold(
            body: Center(
              child: MatchFinishedNavigationDialog(
                isRenseikai: true,
                hasGroupName: true,
                isKachinuki: false,
                isDark: false,
                onAddNextRenseikaiMatch: () {},
                onGoToNextMatch: () {},
                onGoHome: () {},
                onShowScoreboard: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(MatchFinishedNavigationDialog), findsOneWidget);
      expect(find.text('対戦終了'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
