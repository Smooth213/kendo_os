import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/home_screen_qr_dialog.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('🛡️ HomeScreenQrDialog Widget Tests', () {
    testWidgets(
      'Renders HomeScreenQrDialog with shareUrl and responds to close button',
      (WidgetTester tester) async {
        bool isClosed = false;

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              extensions: [
                AppThemeColors.ofMode(isDark: false, mode: 'normal'),
              ],
            ),
            home: Scaffold(
              body: HomeScreenQrDialog(
                shareUrl:
                    'https://kendo-os-beta.web.app/viewer-home/test_tour_1',
                onClose: () {
                  isClosed = true;
                },
              ),
            ),
          ),
        );

        expect(find.text('大会観戦リンク'), findsOneWidget);
        expect(find.textContaining('離れた場所にいる保護者や仲間も'), findsOneWidget);
        expect(find.text('LINEやSNSでURLを送る'), findsOneWidget);
        expect(find.text('閉じる'), findsOneWidget);

        await tester.tap(find.text('閉じる'));
        await tester.pump();
        expect(isClosed, isTrue);
      },
    );
  });
}
