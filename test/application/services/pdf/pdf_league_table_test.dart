import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/application/services/pdf/widgets/pdf_league_table.dart';
import 'package:kendo_os/domain/match/match_model.dart';
import 'package:kendo_os/domain/score/score_event.dart';
import 'package:kendo_os/domain/rules/match_rule.dart';
import 'package:kendo_os/application/mappers/score_event_legacy_adapter.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:kendo_os/shared/time/system_time_source.dart';

// テスト用のMatchModelを簡単に作成するためのヘルパー関数
MatchModel createMockMatch({
  required String id,
  required String redName,
  required String whiteName,
  required int redScore,
  required int whiteScore,
  String matchType = 'individual',
  String status = 'finished',
  List<Map<String, dynamic>> eventsData = const [],
  MatchRule? rule,
  double order = 1.0,
}) {
  return MatchModel(
    id: id,
    tournamentId: 'test-tournament',
    category: 'test-category',
    redName: redName,
    whiteName: whiteName,
    redScore: redScore,
    whiteScore: whiteScore,
    matchType: matchType,
    status: status,
    order: order,
    note: '[リーグ戦]',
    events: eventsData.isEmpty
        ? <ScoreEvent>[
            ...List.generate(
              redScore,
              (i) => ScoreEventLegacyAdapter.fromLegacy(
                id: 'r$i',
                type: PointType.men,
                side: Side.red,
                timestamp: SystemTimeSource().now().add(Duration(seconds: i)),
              ),
            ),
            ...List.generate(
              whiteScore,
              (i) => ScoreEventLegacyAdapter.fromLegacy(
                id: 'w$i',
                type: PointType.kote,
                side: Side.white,
                timestamp: SystemTimeSource().now().add(
                  Duration(seconds: 10 + i),
                ),
              ),
            ),
          ]
        : eventsData
              .map(
                (e) => ScoreEventLegacyAdapter.fromLegacy(
                  id: e['id']?.toString() ?? 'temp_id',
                  type: e['type'] == 'men' ? PointType.men : PointType.kote,
                  side: e['side'] == 'red' ? Side.red : Side.white,
                  timestamp: (e['isFirstOverall'] as bool? ?? false)
                      ? SystemTimeSource().now()
                      : SystemTimeSource().now().add(
                          const Duration(seconds: 1),
                        ),
                ),
              )
              .toList(),
    rule: rule ?? const MatchRule(isLeague: true),
  );
}

void main() {
  // テスト内で日本語フォントを読み込むための初期設定
  TestWidgetsFlutterBinding.ensureInitialized();

  late pw.Font ttf;
  late pw.Font ttfBold;

  // 全テストの開始前に一度だけフォントを読み込む
  setUpAll(() async {
    final fontData = await rootBundle.load(
      'assets/fonts/NotoSansJP-Regular.ttf',
    );
    ttf = pw.Font.ttf(fontData.buffer.asByteData());
    final fontBoldData = await rootBundle.load(
      'assets/fonts/NotoSansJP-Bold.ttf',
    );
    ttfBold = pw.Font.ttf(fontBoldData.buffer.asByteData());
  });

  group('PdfLeagueTable Widget Tests', () {
    test('試合リストが空の場合、SizedBoxが返されるべき', () {
      final result = PdfLeagueTable.build('空のグループ', [], ttf, ttfBold);
      expect(result, isA<pw.SizedBox>());
    });

    test('個人戦リーグのセルは、取得技を「縦並び(Column)」で表示するべき', () {
      final matches = [
        createMockMatch(
          id: 'm1',
          redName: '選手A',
          whiteName: '選手B',
          redScore: 2,
          whiteScore: 0,
          matchType: 'individual',
          // 1本目は丸付き(isFirstOverall: true)、2本目は丸なし(isFirstOverall: false)
          eventsData: [
            {'type': 'men', 'side': 'red', 'isFirstOverall': true},
            {'type': 'kote', 'side': 'red', 'isFirstOverall': false},
          ],
        ),
        // リーグ表を成立させるためのダミー試合
        createMockMatch(
          id: 'm2',
          redName: '選手A',
          whiteName: '選手C',
          redScore: 0,
          whiteScore: 0,
        ),
        createMockMatch(
          id: 'm3',
          redName: '選手B',
          whiteName: '選手C',
          redScore: 0,
          whiteScore: 0,
        ),
      ];

      final pdfTable =
          PdfLeagueTable.build('個人戦リーグ', matches, ttf, ttfBold) as pw.Table;

      // 生成されたPDFテーブルから「選手A vs 選手B」のセルを特定
      // ヘッダーが1行目、選手Aの行が2行目(index:1)
      // 選手リストはソートされるため、選手A -> 0, 選手B -> 1, 選手C -> 2
      // 選手Aの行(index:1)の、選手Bに対するセルは3番目(index:2)
      final tableRow = pdfTable.children[1]; // 選手Aの行
      final cellContainer = tableRow.children[2] as pw.Container; // vs 選手B のセル
      final cellStack = cellContainer.child as pw.Stack;

      // Stackの2番目の要素が、技マークを表示するウィジェット
      final contentWidget = cellStack.children[1];
      expect(
        contentWidget,
        isA<pw.Column>(),
        reason: '個人戦では取得技はColumnで縦並びに表示されるべきです',
      );

      // Columnの中身を検証
      final column = contentWidget as pw.Column;
      expect(
        column.children.length,
        3,
        reason: '2本取得しているので、2つの技マークと間に横線が表示されるべきです',
      );

      // 1本目の技マーク(丸付き)を検証
      final firstMarkWidget = column.children[0];
      expect(
        firstMarkWidget,
        isA<pw.Container>(),
        reason: '1本目は丸で囲まれる(Container)べきです',
      );
      expect(
        (firstMarkWidget as pw.Container).child,
        isA<pw.Text>(),
        reason: 'Containerの子はTextであるべきです',
      );
      expect(((firstMarkWidget).child as pw.Text).text.toPlainText(), 'メ');

      // 中間の区切り線
      expect(
        column.children[1],
        isA<pw.Container>(),
        reason: '2つの技の間に区切り線が表示されるべきです',
      );

      // 2本目の技マーク(丸なし)を検証
      final secondMarkWidget = column.children[2];
      expect(secondMarkWidget, isA<pw.Text>(), reason: '2本目は丸で囲まれない(Text)べきです');
      expect((secondMarkWidget as pw.Text).text.toPlainText(), 'コ');
    });

    test('団体戦リーグのセルは、取得本数/勝者数を「縦並び(Column)」で表示するべき', () {
      final matches = [
        createMockMatch(
          id: 'm1',
          redName: 'チームA:先鋒',
          whiteName: 'チームB:先鋒',
          redScore: 1,
          whiteScore: 0,
          matchType: '団体戦',
        ),
        createMockMatch(
          id: 'm2',
          redName: 'チームA:中堅',
          whiteName: 'チームB:中堅',
          redScore: 0,
          whiteScore: 0,
          matchType: '団体戦',
        ),
        createMockMatch(
          id: 'm3',
          redName: 'チームA:大将',
          whiteName: 'チームB:大将',
          redScore: 2,
          whiteScore: 1,
          matchType: '団体戦',
        ),
        // リーグ表を成立させるためのダミー試合
        createMockMatch(
          id: 'm4',
          redName: 'チームA',
          whiteName: 'チームC',
          redScore: 0,
          whiteScore: 0,
          matchType: '団体戦',
        ),
        createMockMatch(
          id: 'm5',
          redName: 'チームB',
          whiteName: 'チームC',
          redScore: 0,
          whiteScore: 0,
          matchType: '団体戦',
        ),
      ];

      final pdfTable =
          PdfLeagueTable.build('団体戦リーグ', matches, ttf, ttfBold) as pw.Table;

      // 「チームA vs チームB」のセルを特定
      final tableRow = pdfTable.children[1]; // チームAの行
      final cellContainer = tableRow.children[2] as pw.Container; // vs チームB のセル
      final cellStack = cellContainer.child as pw.Stack;

      // Stackの2番目の要素が、スコアを表示するウィジェット
      final contentWidget = cellStack.children[1];
      expect(
        contentWidget,
        isA<pw.Column>(),
        reason: '団体戦では取得本数/勝者数はColumnで縦並びに表示されるべきです',
      );

      // Columnの中身を検証
      final column = contentWidget as pw.Column;
      expect(column.children.length, 3, reason: '取得本数、区切り線、勝者数の3つの要素を持つべきです');

      // 取得本数 (aPts)
      final pointsText = column.children[0] as pw.Text;
      expect(
        pointsText.text.toPlainText(),
        '3',
        reason: 'チームAは合計3本取得しているはずです (1+0+2)',
      );

      // 区切り線
      final divider = column.children[1] as pw.Container;
      expect(divider.constraints!.maxHeight, 0.5);

      // 勝者数 (aWins)
      final winsText = column.children[2] as pw.Text;
      expect(
        winsText.text.toPlainText(),
        '2',
        reason: 'チームAは2人勝利しているはずです (先鋒と大将)',
      );
    });

    test('団体戦リーグのセルで引き分け(draw)の場合、例外なく描画が完了するべき', () {
      final matches = [
        createMockMatch(
          id: 'm1',
          redName: 'チームA:先鋒',
          whiteName: 'チームB:先鋒',
          redScore: 1,
          whiteScore: 1,
          matchType: '団体戦',
        ),
        createMockMatch(
          id: 'm2',
          redName: 'チームA:中堅',
          whiteName: 'チームB:中堅',
          redScore: 0,
          whiteScore: 0,
          matchType: '団体戦',
        ),
        createMockMatch(
          id: 'm3',
          redName: 'チームA:大将',
          whiteName: 'チームB:大将',
          redScore: 1,
          whiteScore: 1,
          matchType: '団体戦',
        ),
        // リーグ表を成立させるためのダミー試合
        createMockMatch(
          id: 'm4',
          redName: 'チームA',
          whiteName: 'チームC',
          redScore: 0,
          whiteScore: 0,
          matchType: '団体戦',
        ),
        createMockMatch(
          id: 'm5',
          redName: 'チームB',
          whiteName: 'チームC',
          redScore: 0,
          whiteScore: 0,
          matchType: '団体戦',
        ),
      ];

      final pdfTable =
          PdfLeagueTable.build('団体戦リーグ', matches, ttf, ttfBold) as pw.Table;

      // 「チームA vs チームB」のセルを特定
      final tableRow = pdfTable.children[1]; // チームAの行
      final cellContainer = tableRow.children[2] as pw.Container; // vs チームB のセル

      expect(
        cellContainer.child,
        isA<pw.Stack>(),
        reason: '引き分けの場合でもStackベースで背景とスコアが描画されるべきです',
      );
      final cellStack = cellContainer.child as pw.Stack;

      // 引き分け時でもCustomPaintとColumnが生成されていることを確認
      expect(
        cellStack.children[0],
        isA<pw.CustomPaint>(),
        reason: '背景の図形(四角形)を描画するCustomPaintが含まれるべきです',
      );
      expect(
        cellStack.children[1],
        isA<pw.Column>(),
        reason: 'スコアを描画するColumnが含まれるべきです',
      );
    });

    test('全試合が完了していない(waitingがある)場合、勝敗の図形は描画されないべき', () {
      final matches = [
        createMockMatch(
          id: 'm1',
          redName: 'チームA:先鋒',
          whiteName: 'チームB:先鋒',
          redScore: 1,
          whiteScore: 0,
          matchType: '団体戦',
          status: 'finished',
        ),
        createMockMatch(
          id: 'm2',
          redName: 'チームA:大将',
          whiteName: 'チームB:大将',
          redScore: 0,
          whiteScore: 0,
          matchType: '団体戦',
          status: 'waiting',
        ), // 未実施
        // リーグ表を成立させるためのダミー試合
        createMockMatch(
          id: 'm3',
          redName: 'チームA',
          whiteName: 'チームC',
          redScore: 0,
          whiteScore: 0,
          matchType: '団体戦',
        ),
      ];

      final pdfTable =
          PdfLeagueTable.build('団体戦リーグ未完了', matches, ttf, ttfBold) as pw.Table;

      final tableRow = pdfTable.children[1]; // チームAの行
      final cellContainer = tableRow.children[2] as pw.Container; // vs チームB のセル

      // 未完了の場合は空のコンテナ（height: 40, childなし）が返されるはず
      expect(
        cellContainer.child,
        isNull,
        reason: '全試合が完了していない対戦カードは、図形やスコアを描画しない空のContainerになるべきです',
      );
    });

    test('リーグ戦の勝ち点はMatchRuleに基づいて計算されるべき', () {
      final rule = const MatchRule(
        isLeague: true,
        winPoint: 3,
        drawPoint: 1,
        lossPoint: 0,
      );
      final matches = [
        createMockMatch(
          id: 'm1',
          redName: '選手A',
          whiteName: '選手B',
          redScore: 1,
          whiteScore: 0,
          rule: rule,
          matchType: 'individual',
        ),
        createMockMatch(
          id: 'm2',
          redName: '選手A',
          whiteName: '選手C',
          redScore: 0,
          whiteScore: 0,
          rule: rule,
          matchType: 'individual',
        ),
        createMockMatch(
          id: 'm3',
          redName: '選手B',
          whiteName: '選手C',
          redScore: 2,
          whiteScore: 0,
          rule: rule,
          matchType: 'individual',
        ),
      ];

      final pdfTable =
          PdfLeagueTable.build('個人戦リーグ', matches, ttf, ttfBold) as pw.Table;

      // Player A: 1 win, 1 draw -> rule points = 3 + 1 = 4
      // Player B: 1 win, 1 loss -> rule points = 3 + 0 = 3
      // Player C: 1 draw, 1 loss -> rule points = 1 + 0 = 1

      final tableRows = pdfTable.children;

      final rowA = tableRows[1];
      expect(
        ((rowA.children[rowA.children.length - 2] as pw.Container).child
                as pw.Text)
            .text
            .toPlainText(),
        '4',
      );

      final rowB = tableRows[2];
      expect(
        ((rowB.children[rowB.children.length - 2] as pw.Container).child
                as pw.Text)
            .text
            .toPlainText(),
        '3',
      );

      final rowC = tableRows[3];
      expect(
        ((rowC.children[rowC.children.length - 2] as pw.Container).child
                as pw.Text)
            .text
            .toPlainText(),
        '1',
      );
    });
  });
}
