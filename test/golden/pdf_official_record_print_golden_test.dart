import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/application/mappers/score_event_legacy_adapter.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/pdf/widgets/pdf_individual_list.dart';
import 'package:kendo_os/features/pdf/widgets/pdf_team_table.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late pw.Font ttf;
  late pw.Font ttfBold;

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

  group('📸 【Golden 5/5】PDF公式記録帳票 印刷レイアウト・ページ整合性テスト', () {
    test('1. A4縦（Portrait）個人戦公式記録帳票のレイアウト整合性', () async {
      final matches = List.generate(
        10,
        (i) => MatchModel(
          id: 'pdf_indiv_$i',
          tournamentId: 't1',
          category: '高校男子の部',
          groupName: '第1コート',
          redName: '神武館:佐藤 $i',
          whiteName: '修道館:田中 $i',
          redScore: 2,
          whiteScore: 1,
          matchType: 'individual',
          status: 'finished',
          order: i.toDouble(),
          events: [
            ScoreEventLegacyAdapter.fromLegacy(
              id: 'e1_$i',
              type: PointType.men,
              side: Side.red,
              timestamp: DateTime(2026, 9, 3, 12, 0),
            ),
            ScoreEventLegacyAdapter.fromLegacy(
              id: 'e2_$i',
              type: PointType.kote,
              side: Side.red,
              timestamp: DateTime(2026, 9, 3, 12, 1),
            ),
          ],
          rule: const MatchRule(),
        ),
      );

      final doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
          build: (context) => [
            PdfIndividualList.build('高校男子の部 個人戦', matches, ttf, ttfBold),
          ],
        ),
      );

      final bytes = await doc.save();
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(1000));
      // A4縦 (595.28 x 841.89) フォーマットが崩れていないこと
      expect(PdfPageFormat.a4.width, closeTo(595.28, 0.1));
      expect(PdfPageFormat.a4.height, closeTo(841.89, 0.1));
    });

    test('2. A4横（Landscape）団体戦対戦表帳票のレイアウト整合性', () async {
      final matches = [
        const MatchModel(
          id: 'pdf_team_1',
          tournamentId: 't1',
          category: '一般団体',
          groupName: '決勝戦',
          redName: '神武館',
          whiteName: '修道館',
          redScore: 3,
          whiteScore: 2,
          matchType: 'team',
          status: 'finished',
          order: 1.0,
          events: [],
          rule: MatchRule(),
        ),
      ];

      final doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(24),
          theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
          build: (context) => [
            PdfTeamTable.build('決勝トーナメント 団体戦', matches, ttf, ttfBold),
          ],
        ),
      );

      final bytes = await doc.save();
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(1000));
      // A4横 (841.89 x 595.28) フォーマットが崩れていないこと
      expect(PdfPageFormat.a4.landscape.width, closeTo(841.89, 0.1));
      expect(PdfPageFormat.a4.landscape.height, closeTo(595.28, 0.1));
    });
  });
}
