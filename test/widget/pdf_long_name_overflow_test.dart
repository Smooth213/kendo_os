import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/application/mappers/score_event_legacy_adapter.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/pdf/helpers/pdf_page_layout_helper.dart';
import 'package:kendo_os/features/pdf/widgets/pdf_individual_list.dart';
import 'package:kendo_os/features/pdf/widgets/pdf_team_table.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/time/system_time_source.dart';
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

  group('PDF長名あふれ＆大量試合改ページ 耐久テスト要塞', () {
    const extremeLongDojo = '全日本学生剣道連盟付属武道研修育成国際強化選抜選手育成会東京中央本部道場支部連合会総本部道場';
    const extremeLongPlayer = 'アレクサンダー・クリストファー・ウェリントン三世フェルディナンド';

    test('1. 極長道場名・選手名が含まれても個人戦PDFが例外なく生成される', () async {
      final matches = [
        MatchModel(
          id: 'long-match-1',
          tournamentId: 't1',
          category: '一般男子',
          groupName: '1回戦',
          redName: '$extremeLongDojo:$extremeLongPlayer',
          whiteName: '$extremeLongDojo:$extremeLongPlayer',
          redScore: 2,
          whiteScore: 1,
          matchType: 'individual',
          status: 'finished',
          order: 1.0,
          events: [
            ScoreEventLegacyAdapter.fromLegacy(
              id: 'e1',
              type: PointType.men,
              side: Side.red,
              timestamp: SystemTimeSource().now(),
            ),
            ScoreEventLegacyAdapter.fromLegacy(
              id: 'e2',
              type: PointType.kote,
              side: Side.red,
              timestamp: SystemTimeSource().now(),
            ),
            ScoreEventLegacyAdapter.fromLegacy(
              id: 'e3',
              type: PointType.doIdo,
              side: Side.white,
              timestamp: SystemTimeSource().now(),
            ),
          ],
          rule: const MatchRule(),
        ),
      ];

      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
          build: (context) => [
            PdfIndividualList.build('個人戦', matches, ttf, ttfBold),
          ],
        ),
      );

      final Uint8List bytes = await pdf.save();
      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.sublist(0, 4)), '%PDF');
    });

    test('2. 極長道場名・選手名が含まれても団体戦対戦表PDFが例外なく生成される', () async {
      final teamMatches = List.generate(5, (i) {
        final positions = ['先鋒', '次鋒', '中堅', '副将', '大将'];
        return MatchModel(
          id: 'team-pos-$i',
          tournamentId: 't1',
          category: '一般団体',
          groupName: '決勝戦',
          redName: '$extremeLongDojo:${extremeLongPlayer}_$i',
          whiteName: '$extremeLongDojo:${extremeLongPlayer}_$i',
          redScore: i % 2 == 0 ? 1 : 0,
          whiteScore: i % 2 == 1 ? 1 : 0,
          matchType: positions[i],
          status: 'finished',
          order: (i + 1).toDouble(),
          events: [
            if (i % 2 == 0)
              ScoreEventLegacyAdapter.fromLegacy(
                id: 'te_$i',
                type: PointType.men,
                side: Side.red,
                timestamp: SystemTimeSource().now(),
              )
            else
              ScoreEventLegacyAdapter.fromLegacy(
                id: 'te_$i',
                type: PointType.kote,
                side: Side.white,
                timestamp: SystemTimeSource().now(),
              ),
          ],
          rule: const MatchRule(),
        );
      });

      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
          build: (context) => [
            PdfTeamTable.build('一般団体 決勝戦', teamMatches, ttf, ttfBold),
          ],
        ),
      );

      final Uint8List bytes = await pdf.save();
      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.sublist(0, 4)), '%PDF');
    });

    test('3. 100試合超の大量試合データで自動改ページが正常に完了しPDFが生成される', () async {
      const matchCount = 120;
      final massMatches = List.generate(matchCount, (i) {
        return MatchModel(
          id: 'mass-match-$i',
          tournamentId: 't1',
          category: 'オープン個人',
          groupName: '${(i ~/ 10) + 1}組',
          redName: '選手赤_${i + 1}',
          whiteName: '選手白_${i + 1}',
          redScore: i % 3 == 0 ? 2 : (i % 3 == 1 ? 1 : 0),
          whiteScore: i % 3 == 2 ? 1 : 0,
          matchType: 'individual',
          status: 'finished',
          order: (i + 1).toDouble(),
          events: const [],
          rule: const MatchRule(),
        );
      });

      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(AppSpacing.md),
          theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
          header: (context) => pw.Text('大量試合耐久テスト ヘッダー'),
          footer: (context) => PdfPageLayoutHelper.buildFooter(context),
          build: (context) => [
            PdfIndividualList.build('オープン個人', massMatches, ttf, ttfBold),
          ],
        ),
      );

      final Uint8List bytes = await pdf.save();
      expect(bytes, isNotEmpty);
      // 大量試合のため複数ページとなりサイズが十分大きいこと
      expect(bytes.length, greaterThan(10000));
      expect(String.fromCharCodes(bytes.sublist(0, 4)), '%PDF');
    });
  });
}
