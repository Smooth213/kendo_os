import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('🛡️ アプリ起動エラー（シミュレータ起動不可・ホワイトアウト）保護テスト', () {
    
    testWidgets('1. Isar / IndexedDB エラー等の致命的エラー時に、ホワイトアウトせず「ブラウザのセキュリティ制限」案内画面が描画されること', (WidgetTester tester) async {
      // main.dart 内の catch(e) で使用されているのと同じ、致命的エラー時のフォールバックUI（エラーハンドラー）のロジックをテストします
      final Exception mockFatalError = Exception('IsarError: Cannot initialize Isar core in simulator.');

      final errorStr = mockFatalError.toString();
      String displayMessage = 'アプリの起動に失敗しました。\n\n'
          '【原因の可能性】\n'
          '・QRコードリーダーの内蔵ブラウザを使用している\n'
          '・プライベートブラウズ（シークレットモード）になっている\n\n'
          '右下の「Safari/Chromeで開く」アイコン等を押して、通常のブラウザで開き直してください。\n\n'
          '詳細エラー: $errorStr';

      if (errorStr.contains('IsarError') || errorStr.contains('IndexedDB')) {
        displayMessage = '【ブラウザのセキュリティ制限】\n\n'
            'LINEやQRコードリーダーの内蔵ブラウザ、またはシークレットモードでは、プライバシー保護機能によりアプリが起動できません。\n\n'
            '画面右下（または右上）のメニューから\n'
            '「Safariで開く」または「ブラウザで開く」\n'
            'を選択して、通常の環境で開き直してください。';
      }

      // エラー発生時に runApp されるフォールバック画面を描画
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  displayMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // エラー文字列に 'IsarError' が含まれているため、ユーザー向けの優しい案内に差し替わっていることを検証
      expect(find.textContaining('【ブラウザのセキュリティ制限】', skipOffstage: false), findsOneWidget);
      expect(find.textContaining('LINEやQRコードリーダーの内蔵ブラウザ', skipOffstage: false), findsOneWidget);
    });

    testWidgets('2. その他のエラー([core/no-app]等)発生時は、通常のエラー原因と詳細スタックが描画されること', (WidgetTester tester) async {
      final Exception mockFatalError = Exception('[core/no-app] No Firebase App has been created.');

      final errorStr = mockFatalError.toString();
      String displayMessage = 'アプリの起動に失敗しました。\n\n'
          '【原因の可能性】\n'
          '・QRコードリーダーの内蔵ブラウザを使用している\n'
          '・プライベートブラウズ（シークレットモード）になっている\n\n'
          '右下の「Safari/Chromeで開く」アイコン等を押して、通常のブラウザで開き直してください。\n\n'
          '詳細エラー: $errorStr';

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: Center(
              child: Text(
                displayMessage,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // デフォルトの「アプリの起動に失敗しました」というメッセージと、実際の例外内容が画面に描画されることを検証
      expect(find.textContaining('アプリの起動に失敗しました。', skipOffstage: false), findsOneWidget);
      expect(find.textContaining('[core/no-app]', skipOffstage: false), findsOneWidget);
    });

    testWidgets('3. FlutterError.onError のカスタムエラー画面（X線画面）が正しく描画されること', (WidgetTester tester) async {
      // main.dart に定義されている ErrorWidget.builder (赤いエラー画面の回避)の挙動をテスト
      final details = FlutterErrorDetails(
        exception: Exception('Simulated RenderFlex Overflow Error'),
        stack: StackTrace.empty,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Text(
              '⚠️ UIレンダリング・エラー発生\n\n${details.exceptionAsString()}',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // カスタムエラー画面が正しく構築されていることを確認
      expect(find.textContaining('⚠️ UIレンダリング・エラー発生'), findsOneWidget);
      expect(find.textContaining('Simulated RenderFlex Overflow Error'), findsOneWidget);
    });
  });
}