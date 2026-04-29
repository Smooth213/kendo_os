import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ※ パスは実際のプロジェクト構成に合わせて変更してください
// import 'package:kendo_os/models/match_model.dart';
// import 'package:kendo_os/domain/match/score_event.dart';
// import 'package:kendo_os/presentation/provider/bunaiksen_provider.dart';
// import 'package:kendo_os/screens/bunaiksen_official_record_screen.dart';

void main() {
  group('1. 部内戦プロバイダー＆ルールのテスト (Unit Test)', () {
    test('部内戦ルールの初期値が正しいこと（3分・延長なし）', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // プロバイダーからルールを取得
      // final rule = container.read(bunaiksenRuleProvider);

      // expect(rule.matchTimeMinutes, 3);
      // expect(rule.enchoTimeMinutes, 0);
      // expect(rule.isEnchoUnlimited, false);
    });
  });

  group('2. スコア文字列変換ロジックのテスト (Unit Test)', () {
    // ※ UIファイル内に書いた _getScoreMarks などのロジックをテスト可能な関数として
    // 抽出していると仮定、または抽出をおすすめします。

    test('1本目が丸囲み文字（㋱など）になり、2本目が通常文字（コなど）になること', () {
      // 疑似的な入力イベント（赤がメン、次にコテを取った場合）
      // final events = [
      //   ScoreEvent(side: Side.red, type: PointType.men),
      //   ScoreEvent(side: Side.red, type: PointType.kote),
      // ];
      // String result = TestHelper.getScoreMarks(events, isRed: true);
      // expect(result, '㋱コ'); // 1本目は丸囲み、2本目は通常文字
    });

    test('取り消し（Undo）された技がカウントされないこと', () {
      // final events = [
      //   ScoreEvent(side: Side.red, type: PointType.men, isCanceled: true),
      //   ScoreEvent(side: Side.red, type: PointType.do),
      // ];
      // String result = TestHelper.getScoreMarks(events, isRed: true);
      // expect(result, '㋣'); // isCanceledなメンは無視され、ドウが1本目（丸囲み）になる
    });
  });

  group('3. 成績一覧 UIの表示テスト (Widget Test)', () {
    testWidgets('団体戦の場合、チーム名が「赤」「白」に固定されていること', (WidgetTester tester) async {
      // モックデータの作成（団体戦）
      // final mockMatches = [
      //   MatchModel(
      //     tournamentId: 'bunaiksen_20260429',
      //     matchType: '先鋒',
      //     redName: 'Aチーム: 剣道太郎',
      //     whiteName: 'Bチーム: 剣道次郎',
      //     redScore: 1,
      //     whiteScore: 0,
      //     note: '団体戦',
      //   )
      // ];

      await tester.pumpWidget(
        ProviderScope(
          // overrides: [matchListProvider.overrideWithValue(mockMatches)],
          child: const MaterialApp(
            // home: BunaiksenOfficialRecordScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // UI上に「赤」「白」というテキストが存在し、「Aチーム」という文字列が隠蔽されているか
      // expect(find.text('赤'), findsWidgets);
      // expect(find.text('白'), findsWidgets);
      // expect(find.text('Aチーム'), findsNothing);
    });

    testWidgets('個人戦の場合、ヘッダーに選手名が表示されること', (WidgetTester tester) async {
      // 個人戦のモックデータ
      // final mockIndividualMatch = [
      //   MatchModel(
      //     tournamentId: 'bunaiksen_20260429',
      //     matchType: '個人戦',
      //     redName: '道場A: 剣道太郎',
      //     whiteName: '道場B: 剣道花子',
      //     note: '個人戦',
      //   )
      // ];

      await tester.pumpWidget(
        ProviderScope(
          // overrides: [matchListProvider.overrideWithValue(mockIndividualMatch)],
          child: const MaterialApp(
            // home: BunaiksenOfficialRecordScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 個人戦なので「剣道太郎 vs 剣道花子」のヘッダーが出ているか
      // expect(find.textContaining('剣道太郎 vs 剣道花子'), findsOneWidget);
    });

    testWidgets('引き分けの場合、スコア中央に極太の「✕」が表示されること', (WidgetTester tester) async {
      // 引き分けのモックデータ（スコア 0 - 0 または 1 - 1 など）
      
      // await tester.pumpWidget(...);
      
      // ✕ 印を持つ Text ウィジェットを探し、スタイルが極太（w900）になっているか確認
      // final xTextFinder = find.text('✕');
      // expect(xTextFinder, findsWidgets);
      
      // final Text textWidget = tester.widget(xTextFinder.first);
      // expect(textWidget.style?.fontWeight, FontWeight.w900);
    });
  });
}