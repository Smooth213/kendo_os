import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_retirement_dialog.dart';

void main() {
  group('🥋 MatchRetirementDialog ウィジェットテスト', () {
    const testMatch = MatchModel(
      id: 'test_match_1',
      matchType: '先鋒',
      redName: '竈門炭治郎',
      whiteName: '我妻善逸',
    );

    Widget createWidgetUnderTest({bool isDark = false}) {
      return ProviderScope(
        child: MaterialApp(
          theme: isDark ? ThemeData.dark() : ThemeData.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    MatchRetirementDialog.show(
                      context,
                      match: testMatch,
                      currentUserId: 'tester',
                      isDark: isDark,
                    );
                  },
                  child: const Text('ダイアログを開く'),
                );
              },
            ),
          ),
        ),
      );
    }

    testWidgets('1. ダイアログが正常に表示され、赤・白の棄権選択肢が表示されること', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.tap(find.text('ダイアログを開く'));
      await tester.pumpAndSettle();

      expect(find.text('途中棄権の記録'), findsOneWidget);
      expect(find.text('赤 側が棄権'), findsOneWidget);
      expect(find.text('竈門炭治郎'), findsOneWidget);
      expect(find.text('白 側が棄権'), findsOneWidget);
      expect(find.text('我妻善逸'), findsOneWidget);
      expect(
        find.text('全日本剣道連盟ルールに基づき、相手側に不戦勝（2本）が付与され、試合が終了します。'),
        findsOneWidget,
      );

      // 初期状態では確定ボタンが無効であること
      final confirmBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, '棄権を確定して終了'),
      );
      expect(confirmBtn.onPressed, isNull);
    });

    testWidgets('2. 赤の棄権を選択すると確定ボタンが有効化されること', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.tap(find.text('ダイアログを開く'));
      await tester.pumpAndSettle();

      // 赤をタップ
      await tester.tap(find.text('赤 側が棄権'));
      await tester.pumpAndSettle();

      final confirmBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, '棄権を確定して終了'),
      );
      expect(confirmBtn.onPressed, isNotNull);
    });

    testWidgets('3. キャンセルボタンでダイアログが閉じること', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.tap(find.text('ダイアログを開く'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      expect(find.text('途中棄権の記録'), findsNothing);
    });
  });
}
