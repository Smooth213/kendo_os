import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/share_import/match_format_selection_bottom_sheet.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        theme: ThemeData(
          extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
        ),
        home: Scaffold(body: child),
      ),
    );
  }

  group('[Widget] MatchFormatSelectionBottomSheet 単体検証', () {
    testWidgets('初期試合形式が正しく反映され5大分類とサブオプションが表示されること', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const MatchFormatSelectionBottomSheet(
            title: '「テストチーム」の試合形式選択',
            initialMatchType: '団体戦（5人制）',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('「テストチーム」の試合形式選択'), findsOneWidget);
      expect(find.text('団体戦'), findsWidgets);
      expect(find.text('勝ち抜き戦'), findsWidgets);
      expect(find.text('5人制'), findsWidgets);
      expect(find.text('この形式に設定'), findsOneWidget);
    });

    testWidgets('勝ち抜き戦をタップして3人制に切り替え決定すると選択結果が返されること', (tester) async {
      String? result;

      await tester.pumpWidget(
        buildTestableWidget(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  result = await MatchFormatSelectionBottomSheet.show(
                    context: context,
                    title: 'テスト形式選択',
                    initialMatchType: '団体戦（5人制）',
                  );
                },
                child: const Text('開く'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('開く'));
      await tester.pumpAndSettle();

      // 勝ち抜き戦をタップ
      await tester.tap(find.text('勝ち抜き戦').last);
      await tester.pumpAndSettle();

      // 3人制を選択
      expect(find.text('3人制'), findsWidgets);
      await tester.tap(find.text('3人制').last);
      await tester.pumpAndSettle();

      // この形式に設定をタップ
      expect(find.text('この形式に設定'), findsOneWidget);
      await tester.tap(find.text('この形式に設定'));
      await tester.pumpAndSettle();

      expect(result, equals('勝ち抜き戦（3人制）'));
    });
  });
}
