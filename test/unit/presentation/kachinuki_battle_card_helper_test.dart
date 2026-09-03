import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/tournament/presentation/components/kachinuki/kachinuki_battle_card_helper.dart';

void main() {
  group('KachinukiBattleCardHelper テスト', () {
    group('parseName - 選手名パース', () {
      test('役職コロン付きの名前から姓と名を正しく抽出できること', () {
        final res = KachinukiBattleCardHelper.parseName('先鋒:山田 太郎');
        expect(res['last'], '山田');
        expect(res['first'], '太郎');
      });

      test('括弧付き表記がサニタイズされてパースされること', () {
        final res = KachinukiBattleCardHelper.parseName('次鋒:(佐藤 花子)');
        expect(res['last'], '佐藤');
        expect(res['first'], '花子');
      });

      test('姓のみの場合はfirstが空文字になること', () {
        final res = KachinukiBattleCardHelper.parseName('中堅:田中');
        expect(res['last'], '田中');
        expect(res['first'], '');
      });

      test('欠員が含まれる場合はlastもfirstも空になること', () {
        final res = KachinukiBattleCardHelper.parseName('副将:欠員');
        expect(res['last'], '');
        expect(res['first'], '');
      });
    });

    group('buildStreakBadge - 連勝バッジ表示判定', () {
      testWidgets('勝利かつ2人抜き以上の場合は確定バッジが表示されること', (tester) async {
        final widget = KachinukiBattleCardHelper.buildStreakBadge(
          isWin: true,
          isStreaking: false,
          streak: 3,
          isDark: false,
        );

        expect(widget, isNotNull);
        await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget!)));
        expect(find.text('🔥 3人抜き'), findsOneWidget);
      });

      testWidgets('進行中で連勝中の場合は「〜中」バッジが表示されること', (tester) async {
        final widget = KachinukiBattleCardHelper.buildStreakBadge(
          isWin: false,
          isStreaking: true,
          streak: 2,
          isDark: true,
        );

        expect(widget, isNotNull);
        await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget!)));
        expect(find.text('🔥 2人抜き中'), findsOneWidget);
      });

      test('連勝なしの場合はnullを返すこと', () {
        final widget = KachinukiBattleCardHelper.buildStreakBadge(
          isWin: false,
          isStreaking: false,
          streak: 0,
          isDark: false,
        );
        expect(widget, isNull);
      });
    });

    group('buildScoreMarks - スコアマーク', () {
      testWidgets('空リストの場合は空SizedBoxを返すこと', (tester) async {
        final widget = KachinukiBattleCardHelper.buildScoreMarks(
          [],
          Colors.red,
          false,
          false,
        );
        await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
        expect(find.byType(SizedBox), findsOneWidget);
      });

      testWidgets('マークが存在する場合にテキストが描画されること', (tester) async {
        final pts = [PointDisplay('メ', false), PointDisplay('コ', false)];
        final widget = KachinukiBattleCardHelper.buildScoreMarks(
          pts,
          Colors.red,
          false,
          false,
        );
        await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
        expect(find.text('メ'), findsOneWidget);
        expect(find.text('コ'), findsOneWidget);
      });
    });
  });
}
