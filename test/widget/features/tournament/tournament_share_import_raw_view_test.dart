import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/share_import/tournament_share_import_raw_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Widget] TournamentShareImportRawView ウィジェットテスト', () {
    testWidgets('テキストの入力と再解析ボタン押下コールバックが正常に動作すること', (tester) async {
      final controller = TextEditingController();
      bool reparseCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TournamentShareImportRawView(
                rawTextController: controller,
                onReparse: () {
                  reparseCalled = true;
                },
                accentColor: Colors.blue,
                textColor: Colors.black,
                subTextColor: Colors.grey,
                isDark: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('TimeTreeやLINE、メモ等のテキストを貼り付けて解析できます。'), findsOneWidget);
      expect(find.text('テキストを再解析する'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '第1回 練習試合大会');
      expect(controller.text, '第1回 練習試合大会');

      await tester.tap(find.text('テキストを再解析する'));
      await tester.pump();

      expect(reparseCalled, isTrue);
    });

    testWidgets('ダークモード時も正常に描画されること', (tester) async {
      final controller = TextEditingController(text: 'ダークモードテスト');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: TournamentShareImportRawView(
                rawTextController: controller,
                onReparse: () {},
                accentColor: Colors.red,
                textColor: Colors.white,
                subTextColor: Colors.grey,
                isDark: true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('ダークモードテスト'), findsOneWidget);
      expect(find.byIcon(Icons.psychology), findsOneWidget);
    });
  });
}
