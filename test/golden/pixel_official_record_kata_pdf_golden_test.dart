import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/pdf/widgets/pdf_individual_list.dart';
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

  group('[Golden] 剣道形および基本判定公式記録帳票 PDF印刷レイアウト整合性テスト', () {
    const kataRule = MatchRule(
      isKataMatch: true,
      matchTimeMinutes: 0.0,
      hasHantei: true,
    );

    test('A4縦において剣道形ペア戦の打太刀仕太刀連名と旗判定スコアがミリ規格通り出力されること', () async {
      final kataMatches = List.generate(
        6,
        (i) => MatchModel(
          id: 'pdf_kata_$i',
          tournamentId: 't_kata_pdf',
          category: '形の部',
          groupName: '第1試合場',
          redName: '道上剣友会 : 皿田・塚本',
          whiteName: '修道館 : 佐藤・鈴木',
          redScore: 3,
          whiteScore: 0,
          matchType: '日本剣道形',
          status: 'finished',
          order: i.toDouble(),
          events: [
            ScoreEvent(
              id: 'ev_kata_hantei_$i',
              side: Side.red,
              isHantei: true,
              redFlags: 3,
              whiteFlags: 0,
              timestamp: DateTime(2026, 10, 15, 10, i),
            ),
          ],
          rule: kataRule,
        ),
      );

      final doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
          build: (context) => [
            PdfIndividualList.build('日本剣道形競技 公式記録表', kataMatches, ttf, ttfBold),
          ],
        ),
      );

      final bytes = await doc.save();
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(1000));
      expect(PdfPageFormat.a4.width, closeTo(595.28, 0.1));
      expect(PdfPageFormat.a4.height, closeTo(841.89, 0.1));
    });
  });
}
