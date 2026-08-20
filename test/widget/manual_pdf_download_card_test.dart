import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/manual/manual_pdf_download_card.dart';

void main() {
  group('🛡️ ManualPdfDownloadCard Widget Tests', () {
    testWidgets(
      'Renders download card and responds to download and text fallback taps',
      (tester) async {
        bool downloadPressed = false;
        bool fallbackPressed = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ManualPdfDownloadCard(
                onDownloadPressed: () => downloadPressed = true,
                onTextFallbackPressed: () => fallbackPressed = true,
              ),
            ),
          ),
        );

        // タイトルとボタンの表示確認
        expect(find.text('Kendo Sync 総合取扱説明書'), findsOneWidget);
        expect(find.text('PDF版をダウンロード (無料)'), findsOneWidget);
        expect(find.text('テキスト簡易版（オフライン対応）を読む'), findsOneWidget);

        // ダウンロードタップ
        await tester.tap(find.text('PDF版をダウンロード (無料)'));
        expect(downloadPressed, isTrue);

        // テキスト簡易版タップ
        await tester.tap(find.text('テキスト簡易版（オフライン対応）を読む'));
        expect(fallbackPressed, isTrue);
      },
    );
  });
}
