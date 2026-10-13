import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/application/mappers/score_event_legacy_adapter.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/pdf/widgets/pdf_individual_list.dart';
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

  group('[Unit] 剣道形 PDF組版耐久およびクラッシュ防止テスト', () {
    const extremeLongDojo = '全日本学生剣道連盟付属武道研修育成国際強化選抜選手育成会東京中央本部道場支部連合会総本部道場';
    const extremeLongKataPairRed = '打太刀 宇都宮（健太郎）・仕太刀 勅使河原（大和守）';
    const extremeLongKataPairWhite =
        '打太刀 アレクサンダー（クリストファー）・仕太刀 フェルディナンド（マクシミリアン）';

    test('極長ペア名や同姓同名ペアが含まれても形競技PDFが例外なく生成されること', () async {
      final matches = [
        // 同姓同名ペア（苗字同一により添え字が発生するケース）
        MatchModel(
          id: 'kata-pdf-same-surname',
          tournamentId: 't1',
          category: '日本剣道形',
          groupName: '1回戦',
          redName: '道上剣友会:皿田 脩人・皿田 健太',
          whiteName: '友道館:佐藤 健一・佐藤 宏樹',
          redScore: 2,
          whiteScore: 1,
          matchType: '日本剣道形',
          status: 'finished',
          order: 1.0,
          events: [
            ScoreEventLegacyAdapter.fromLegacy(
              id: 'e1',
              type: PointType.hantei,
              side: Side.red,
              timestamp: SystemTimeSource().now(),
            ),
            ScoreEventLegacyAdapter.fromLegacy(
              id: 'e2',
              type: PointType.hantei,
              side: Side.red,
              timestamp: SystemTimeSource().now(),
            ),
            ScoreEventLegacyAdapter.fromLegacy(
              id: 'e3',
              type: PointType.hantei,
              side: Side.white,
              timestamp: SystemTimeSource().now(),
            ),
          ],
          rule: const MatchRule(isKataMatch: true, hasHantei: true),
        ),
        // 極長道場名・極長ペア名（文字あふれ・縮小描画のストレステスト）
        MatchModel(
          id: 'kata-pdf-extreme-long',
          tournamentId: 't1',
          category: '木刀による剣道基本技稽古法',
          groupName: '準決勝',
          redName: '$extremeLongDojo:$extremeLongKataPairRed',
          whiteName: '$extremeLongDojo:$extremeLongKataPairWhite',
          redScore: 3,
          whiteScore: 0,
          matchType: '木刀による剣道基本技稽古法',
          status: 'finished',
          order: 2.0,
          events: [
            ScoreEventLegacyAdapter.fromLegacy(
              id: 'e4',
              type: PointType.hantei,
              side: Side.red,
              timestamp: SystemTimeSource().now(),
            ),
            ScoreEventLegacyAdapter.fromLegacy(
              id: 'e5',
              type: PointType.hantei,
              side: Side.red,
              timestamp: SystemTimeSource().now(),
            ),
            ScoreEventLegacyAdapter.fromLegacy(
              id: 'e6',
              type: PointType.hantei,
              side: Side.red,
              timestamp: SystemTimeSource().now(),
            ),
          ],
          rule: const MatchRule(isKataMatch: true, hasHantei: true),
        ),
      ];

      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
          build: (context) => [
            PdfIndividualList.build('形・基本判定', matches, ttf, ttfBold),
          ],
        ),
      );

      final Uint8List bytes = await pdf.save();
      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.sublist(0, 4)), '%PDF');
    });

    test('多数の形競技試合が存在しても自動改ページが正常に動作しPDFが生成されること', () async {
      final matches = List.generate(40, (i) {
        final isRedWin = i % 2 == 0;
        return MatchModel(
          id: 'kata-pdf-mass-$i',
          tournamentId: 't1',
          category: '日本剣道形',
          groupName: '${(i ~/ 4) + 1}回戦',
          redName: '剣道クラブA:皿田 脩人・皿田 健太',
          whiteName: '剣道クラブB:鈴木 一郎・佐藤 次郎',
          redScore: isRedWin ? 3 : 0,
          whiteScore: isRedWin ? 0 : 3,
          matchType: '日本剣道形',
          status: 'finished',
          order: (i + 1).toDouble(),
          events: [
            ScoreEventLegacyAdapter.fromLegacy(
              id: 'me_${i}_1',
              type: PointType.hantei,
              side: isRedWin ? Side.red : Side.white,
              timestamp: SystemTimeSource().now(),
            ),
            ScoreEventLegacyAdapter.fromLegacy(
              id: 'me_${i}_2',
              type: PointType.hantei,
              side: isRedWin ? Side.red : Side.white,
              timestamp: SystemTimeSource().now(),
            ),
            ScoreEventLegacyAdapter.fromLegacy(
              id: 'me_${i}_3',
              type: PointType.hantei,
              side: isRedWin ? Side.red : Side.white,
              timestamp: SystemTimeSource().now(),
            ),
          ],
          rule: const MatchRule(isKataMatch: true, hasHantei: true),
        );
      });

      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
          build: (context) => [
            PdfIndividualList.build('日本剣道形 本戦', matches, ttf, ttfBold),
          ],
        ),
      );

      final Uint8List bytes = await pdf.save();
      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.sublist(0, 4)), '%PDF');
    });
  });
}
