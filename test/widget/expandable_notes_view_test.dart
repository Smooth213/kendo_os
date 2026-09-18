import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/widgets/expandable_notes_view.dart';

void main() {
  group('ExpandableNotesView Widget Tests', () {
    testWidgets('短いメモの場合は展開ボタンが表示されないこと', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ExpandableNotesView(
              notes: '短いメモです。',
              backgroundColor: Colors.grey,
              textColor: Colors.black,
              accentColor: Colors.blue,
            ),
          ),
        ),
      );

      expect(find.text('連絡事項・メモ'), findsOneWidget);
      expect(find.text('短いメモです。'), findsOneWidget);
      expect(find.text('もっと見る'), findsNothing);
      expect(find.text('閉じる'), findsNothing);
    });

    testWidgets('長いメモの場合は「もっと見る」が表示され、タップで「閉じる」に切り替わること', (tester) async {
      const longNotes = '''
開館: 7時30分
開会式: 9時00分
集合場所: JA道上
遠征責任者: 橋本
乗り合わせで行きます。
防具の点検をお願いします。
''';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ExpandableNotesView(
              notes: longNotes,
              backgroundColor: Colors.grey,
              textColor: Colors.black,
              accentColor: Colors.blue,
            ),
          ),
        ),
      );

      expect(find.text('もっと見る'), findsOneWidget);
      expect(find.text('閉じる'), findsNothing);

      // 「もっと見る」をタップ
      await tester.tap(find.text('もっと見る'));
      await tester.pumpAndSettle();

      expect(find.text('もっと見る'), findsNothing);
      expect(find.text('閉じる'), findsOneWidget);

      // 「閉じる」をタップして再度折りたたむ
      await tester.tap(find.text('閉じる'));
      await tester.pumpAndSettle();

      expect(find.text('もっと見る'), findsOneWidget);
      expect(find.text('閉じる'), findsNothing);
    });
  });
}
