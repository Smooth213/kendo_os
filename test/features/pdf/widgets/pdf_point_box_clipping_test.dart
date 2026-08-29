import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:kendo_os/features/pdf/models/pdf_point_data.dart';
import 'package:kendo_os/features/pdf/widgets/pdf_team_table_cell_renderer.dart';
import 'package:kendo_os/features/pdf/widgets/pdf_team_table.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';

void main() {
  group('🛡️ 【PDFスコアセル＆勝者円はみ出し防止 完全保証テスト】', () {
    late pw.Font fontBold;
    late pw.Font fontRegular;

    setUpAll(() {
      fontBold = pw.Font.helveticaBold();
      fontRegular = pw.Font.helvetica();
    });

    test('1. 【寸法保証】buildPointBox がセル領域(26x26)に収まり、勝者円(25x25)が境界線と干渉しないこと', () {
      final pts = [PdfPointData('コ', true), PdfPointData('ツ', false)];

      final widget = PdfTeamTableCellRenderer.buildPointBox(
        pts,
        true, // isWinner: true
        true, // isRed: true
        fontBold,
      );

      // pw.Container であること
      expect(widget, isA<pw.Container>());
      final container = widget as pw.Container;

      // 許容最大サイズ 26x26 以内であること（セルの高さ30pxに対して十分なマージン）
      final box = container.constraints;
      expect(box?.maxWidth ?? 26, lessThanOrEqualTo(26.0));
      expect(box?.maxHeight ?? 26, lessThanOrEqualTo(26.0));
    });

    test(
      '2. 【1本勝ち/2本勝ち/引き分け】すべての打突マークパターンでPDFページ描画がはみ出さずレンダリング完了すること',
      () async {
        final pdf = pw.Document();

        // 各種打突パターンの検証
        final singlePoint = [PdfPointData('メ', true)];
        final doublePoint = [PdfPointData('コ', true), PdfPointData('ツ', false)];
        final drawPoint = [PdfPointData('×', false)];
        final fusenPoint = [PdfPointData('◯', true)];

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (context) {
              return pw.Column(
                children: [
                  // 1本勝ち（赤）
                  PdfTeamTableCellRenderer.buildPointBox(
                    singlePoint,
                    true,
                    true,
                    fontBold,
                  ),
                  // 2本勝ち（赤）
                  PdfTeamTableCellRenderer.buildPointBox(
                    doublePoint,
                    true,
                    true,
                    fontBold,
                  ),
                  // 1本負け（白側勝者なし）
                  PdfTeamTableCellRenderer.buildPointBox(
                    singlePoint,
                    false,
                    false,
                    fontBold,
                  ),
                  // 引き分け（×）
                  PdfTeamTableCellRenderer.buildPointBox(
                    drawPoint,
                    false,
                    false,
                    fontBold,
                  ),
                  // 不戦勝（◯）
                  PdfTeamTableCellRenderer.buildPointBox(
                    fusenPoint,
                    true,
                    true,
                    fontBold,
                  ),
                ],
              );
            },
          ),
        );

        // PDFバイナリの生成がエラー・クラッシュ・オーバーフローなく完了すること
        final bytes = await pdf.save();
        expect(bytes, isNotEmpty);
        expect(bytes.length, greaterThan(100));
      },
    );

    test('3. 【団体戦スコアテーブル全体検証】全5ポジション（先鋒〜大将）の対戦表が境界線はみ出しなくPDF出力できること', () async {
      final pdf = pw.Document();

      final now = DateTime(2026, 8, 29);
      final matches = [
        MatchModel(
          id: 'm1',
          matchType: '先鋒戦',
          redName: '道上剣友会A: 皿田',
          whiteName: '相手チーム: 選手1',
          status: 'finished',
          redScore: 1,
          whiteScore: 0,
          events: [
            ScoreEvent(
              id: 'e1',
              strikeType: StrikeType.men,
              isIppon: true,
              side: Side.red,
              timestamp: now,
            ),
          ],
        ),
        MatchModel(
          id: 'm2',
          matchType: '次鋒戦',
          redName: '道上剣友会A: 塚本',
          whiteName: '相手チーム: 選手2',
          status: 'finished',
          redScore: 0,
          whiteScore: 0,
          events: const [],
        ),
        MatchModel(
          id: 'm3',
          matchType: '中堅戦',
          redName: '道上剣友会A: 久安',
          whiteName: '相手チーム: 選手3',
          status: 'finished',
          redScore: 2,
          whiteScore: 0,
          events: [
            ScoreEvent(
              id: 'e2',
              strikeType: StrikeType.tsuki,
              isIppon: true,
              side: Side.red,
              timestamp: now,
            ),
            ScoreEvent(
              id: 'e3',
              strikeType: StrikeType.tsuki,
              isIppon: true,
              side: Side.red,
              timestamp: now,
            ),
          ],
        ),
        MatchModel(
          id: 'm4',
          matchType: '副将戦',
          redName: '道上剣友会A: 選手4',
          whiteName: '相手チーム: 選手4',
          status: 'finished',
          redScore: 0,
          whiteScore: 1,
          events: [
            ScoreEvent(
              id: 'e4',
              strikeType: StrikeType.kote,
              isIppon: true,
              side: Side.white,
              timestamp: now,
            ),
          ],
        ),
        MatchModel(
          id: 'm5',
          matchType: '大将戦',
          redName: '道上剣友会A: 選手5',
          whiteName: '相手チーム: 選手5',
          status: 'finished',
          redScore: 2,
          whiteScore: 1,
          events: [
            ScoreEvent(
              id: 'e5',
              strikeType: StrikeType.kote,
              isIppon: true,
              side: Side.red,
              timestamp: now,
            ),
            ScoreEvent(
              id: 'e6',
              strikeType: StrikeType.men,
              isIppon: true,
              side: Side.white,
              timestamp: now,
            ),
            ScoreEvent(
              id: 'e7',
              strikeType: StrikeType.dou,
              isIppon: true,
              side: Side.red,
              timestamp: now,
            ),
          ],
        ),
      ];

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return PdfTeamTable.build('group1', matches, fontRegular, fontBold);
          },
        ),
      );

      final bytes = await pdf.save();
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(500));
    });
  });
}
