import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/kata_score_action_section.dart';

void main() {
  group('[Widget] KataScoreActionSection 判定アクションUIテスト', () {
    Widget buildTestWidget({
      required String matchId,
      required bool isInputLocked,
      required bool isDark,
      required bool hasEvents,
    }) {
      return ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: KataScoreActionSection(
              matchId: matchId,
              isInputLocked: isInputLocked,
              isDark: isDark,
              hasEvents: hasEvents,
            ),
          ),
        ),
      );
    }

    testWidgets('初期状態で各旗判定ボタンおよび不戦勝ボタンが正しく描画されること', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          matchId: 'match_1',
          isInputLocked: false,
          isDark: false,
          hasEvents: false,
        ),
      );

      expect(find.text('赤 3 - 0 白'), findsOneWidget);
      expect(find.text('赤 2 - 1 白'), findsOneWidget);
      expect(find.text('赤 0 - 3 白'), findsOneWidget);
      expect(find.text('赤 1 - 2 白'), findsOneWidget);
      expect(find.text('赤 不戦勝'), findsOneWidget);
      expect(find.text('白 不戦勝'), findsOneWidget);

      // イベントがないときはUndoボタンは非表示
      expect(find.text('直前の判定を取り消す (Undo)'), findsNothing);
    });

    testWidgets('イベントが存在する場合においてUndoボタンが描画されること', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          matchId: 'match_1',
          isInputLocked: false,
          isDark: false,
          hasEvents: true,
        ),
      );

      expect(find.text('直前の判定を取り消す (Undo)'), findsOneWidget);
    });

    testWidgets('isInputLockedがtrueのとき各ボタンが無効化されていること', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          matchId: 'match_1',
          isInputLocked: true,
          isDark: false,
          hasEvents: true,
        ),
      );

      final undoButton = tester.widget<TextButton>(
        find.widgetWithText(TextButton, '直前の判定を取り消す (Undo)'),
      );
      expect(undoButton.onPressed, isNull);
    });
  });
}
