import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_hantei_dialog.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('🛡️ MatchHanteiDialog Widget Tests', () {
    testWidgets(
      'Renders MatchHanteiDialog and responds to selection (Red, White, Draw, Cancel)',
      (WidgetTester tester) async {
        String? selectedResult = 'initial';

        final themeColors = AppThemeColors.ofMode(
          isDark: false,
          mode: 'normal',
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(extensions: [themeColors]),
            home: Scaffold(
              body: MatchHanteiDialog(
                redName: 'チームA: 山田',
                whiteName: 'チームB: 佐藤',
                isDark: false,
                onSelected: (result) {
                  selectedResult = result;
                },
              ),
            ),
          ),
        );

        expect(find.text('勝敗の判定'), findsOneWidget);
        expect(find.textContaining('同点のため、判定'), findsOneWidget);
        expect(find.textContaining('赤の判定勝ち'), findsOneWidget);
        expect(find.textContaining('白の判定勝ち'), findsOneWidget);
        expect(find.text('引き分け'), findsOneWidget);
        expect(find.text('キャンセル（戻る）'), findsOneWidget);

        // 赤タップ
        await tester.tap(find.textContaining('赤の判定勝ち'));
        await tester.pump();
        expect(selectedResult, 'red');

        // 白タップ
        await tester.tap(find.textContaining('白の判定勝ち'));
        await tester.pump();
        expect(selectedResult, 'white');

        // 引き分けタップ
        await tester.tap(find.text('引き分け'));
        await tester.pump();
        expect(selectedResult, 'draw');

        // キャンセルタップ
        await tester.tap(find.text('キャンセル（戻る）'));
        await tester.pump();
        expect(selectedResult, isNull);
      },
    );
  });
}
