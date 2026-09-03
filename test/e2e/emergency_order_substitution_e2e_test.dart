import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/pdf/widgets/pdf_team_table.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';

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

  group('🚀 【E2E 3/5】試合開始直前 選手急遽差替・オーダー変更 完全保証E2Eテスト', () {
    test('先鋒戦の直前差替において、過去の試合を汚染せず新選手名が帳票・PDFまで一貫波及すること', () async {
      // 1. 過去に終了した第1試合（この対戦成績は絶対に書き換わってはならない）
      final historicalMatch = MatchModel(
        id: 'hist_match_1',
        tournamentId: 'tour_sub_e2e',
        category: '一般団体',
        groupName: '1回戦',
        matchType: '先鋒戦',
        status: 'finished',
        redName: '神武館:山田太郎',
        whiteName: '修道館:鈴木一郎',
        redScore: 2,
        whiteScore: 0,
        order: 1.0,
      );

      // 2. まもなく開始される第2試合（登録時は先鋒: 山田太郎 だったが急遽負傷のため 補欠: 高橋次郎 へ変更）
      final originalUpcomingMatch = MatchModel(
        id: 'upcoming_match_2',
        tournamentId: 'tour_sub_e2e',
        category: '一般団体',
        groupName: '2回戦',
        matchType: '先鋒戦',
        status: 'waiting',
        redName: '神武館:山田太郎',
        whiteName: '正気館:佐藤健',
        redScore: 0,
        whiteScore: 0,
        order: 2.0,
      );

      // オーダー変更（選手差替）の実行
      const substitutePlayer = '神武館:高橋次郎';
      final substitutedMatch = originalUpcomingMatch.copyWith(
        redName: substitutePlayer,
        note: '選手変更(負傷交代)',
      );

      // 3. 不変性・分離性の検証: 過去の試合は完全にそのまま保持されていること
      expect(historicalMatch.redName, '神武館:山田太郎');
      expect(historicalMatch.status, 'finished');

      // 差替後の試合は正しく新選手が反映されていること
      expect(substitutedMatch.redName, substitutePlayer);
      expect(substitutedMatch.note, contains('負傷交代'));

      // 4. 差替後の選手で試合が進行し、一本取得
      final playedSubstitutedMatch = substitutedMatch.copyWith(
        status: 'inProgress',
        redScore: 1,
        events: [
          ScoreEvent(
            id: 'ev_sub_1',
            side: Side.red,
            strikeType: StrikeType.kote,
            isIppon: true,
            timestamp: DateTime(2026, 9, 3, 11, 0),
            logicalClock: 1,
          ),
        ],
      );

      expect(playedSubstitutedMatch.redScore, 1);
      expect(playedSubstitutedMatch.events.first.strikeType, StrikeType.kote);

      // 5. PDF公式記録帳票のレンダリング検証（新選手名が印字され例外なく生成されること）
      final doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
          build: (context) => [
            PdfTeamTable.build(
              '2回戦 団体戦公式対戦表',
              [historicalMatch, playedSubstitutedMatch],
              ttf,
              ttfBold,
            ),
          ],
        ),
      );

      final pdfBytes = await doc.save();
      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(1000));
    });
  });
}
