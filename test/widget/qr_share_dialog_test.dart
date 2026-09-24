import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/qr_share_dialog.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  group('🥋 QrShareDialog Widget Tests', () {
    testWidgets('タイトル・説明・QRコード・URL・各ボタンが正常に描画されること', (tester) async {
      bool isClosed = false;
      const testUrl = 'https://kendo-os-beta.web.app/viewer-home/test_tour_999';

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
          ),
          home: Scaffold(
            body: QrShareDialog(
              title: '大会観戦リンク',
              themeColor: AppKendoColors.teal,
              description: '離れた場所にいる保護者や仲間も、\n試合状況をリアルタイムで安心して見守れます。',
              shareUrl: testUrl,
              shareText: '観戦URL: $testUrl',
              subtitleBadge: '大会ID: test_tour_999',
              onClose: () => isClosed = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // タイトル・説明文の検証
      expect(find.text('大会観戦リンク'), findsOneWidget);
      expect(find.textContaining('離れた場所にいる保護者や仲間も'), findsOneWidget);
      expect(find.text('大会ID: test_tour_999'), findsOneWidget);

      // QRコードの検証
      expect(find.byType(QrImageView), findsOneWidget);

      // URLフィールドとコピーボタンの検証
      expect(find.text(testUrl), findsOneWidget);
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);

      // シェアボタンの検証
      expect(find.text('LINEやSNSでURLを送る'), findsOneWidget);

      // 閉じるボタンの検証
      final closeButton = find.text('閉じる');
      expect(closeButton, findsOneWidget);
      await tester.tap(closeButton);
      await tester.pump();
      expect(isClosed, isTrue);
    });

    testWidgets('カスタム設定（Webアプリ向け）で正しく描画されること', (tester) async {
      const webUrl = 'https://kendo-os-beta.web.app';

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            extensions: [AppThemeColors.ofMode(isDark: true, mode: 'normal')],
          ),
          home: const Scaffold(
            body: QrShareDialog(
              title: 'Webアプリ版（kendo_os）',
              themeColor: AppKendoColors.blue,
              description: 'カメラでQRコードを読み取るとブラウザから開けます。',
              shareUrl: webUrl,
              shareText: 'Webアプリ版: $webUrl',
              shareButtonLabel: 'URLをシェア・共有',
              copySuccessMessage: 'WebアプリのURLをコピーしました',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Webアプリ版（kendo_os）'), findsOneWidget);
      expect(find.text('URLをシェア・共有'), findsOneWidget);
      expect(find.text(webUrl), findsOneWidget);
    });
  });
}
