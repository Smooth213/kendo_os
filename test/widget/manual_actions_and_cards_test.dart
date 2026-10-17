import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/manual/manual_floating_action_bar.dart';
import 'package:kendo_os/features/tournament/presentation/components/manual/manual_pdf_download_card.dart';

void main() {
  group('[Widget] マニュアルアクション・カード（FAB・ダウンロードカード）統合ウィジェットテスト', () {
    testWidgets('ManualFloatingActionBarにおいて ボタン一覧が表示され各タップが動作すること', (
      WidgetTester tester,
    ) async {
      bool primaryTapped = false;
      bool secondaryTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ManualFloatingActionBar(
              primaryLabel: 'A4印刷',
              primaryIcon: Icons.print,
              onPrimaryPressed: () => primaryTapped = true,
              secondaryLabel: '共有/保存',
              secondaryIcon: Icons.share,
              onSecondaryPressed: () => secondaryTapped = true,
              isDark: false,
            ),
          ),
        ),
      );

      expect(find.text('A4印刷'), findsOneWidget);
      expect(find.text('共有/保存'), findsOneWidget);

      await tester.tap(find.text('A4印刷'));
      expect(primaryTapped, isTrue);

      await tester.tap(find.text('共有/保存'));
      expect(secondaryTapped, isTrue);
    });

    testWidgets('ManualFloatingActionBarにおいて ダークモード環境で正しく描画されること', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ManualFloatingActionBar(
              primaryLabel: 'PDFを開く',
              primaryIcon: Icons.open_in_new,
              secondaryLabel: '共有する',
              secondaryIcon: Icons.share,
              isDark: true,
            ),
          ),
        ),
      );

      expect(find.text('PDFを開く'), findsOneWidget);
      expect(find.text('共有する'), findsOneWidget);
    });

    testWidgets('ManualPdfDownloadCardにおいて ダウンロードとテキスト簡易版のタップが正しく動作すること', (
      tester,
    ) async {
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
    });
  });
}
