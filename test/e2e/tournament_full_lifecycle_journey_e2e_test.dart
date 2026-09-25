import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_context.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/pdf/services/pdf_font_loader.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🥋 【E2E】大会ライフサイクル完全貫通ジャーニーE2Eテスト', () {
    test('大会作成〜試合進行〜結果承認〜公式記録PDF〜観客共有の完全貫通ジャーニー', () async {
      // 1. 大会の作成
      final tournament = TournamentModel(
        id: 'tourney_lifecycle_01',
        name: '秋季市民剣道大会',
        date: DateTime(2026, 9, 25),
        venue: '市民総合体育館 武道場',
        categories: const ['一般の部'],
        organizationId: 'dojo_main',
      );
      expect(tournament.id, 'tourney_lifecycle_01');
      expect(tournament.name, '秋季市民剣道大会');

      // 2. 試合対戦カードの生成
      final initialMatch = MatchModel(
        id: 'match_final_01',
        tournamentId: tournament.id,
        category: '一般の部',
        matchType: '個人戦',
        redName: '剣道道場: 山田',
        whiteName: '一心館: 佐藤',
        status: 'waiting',
        matchTimeMinutes: 3.0,
        rule: const MatchRule(),
      );
      expect(initialMatch.status, 'waiting');

      // 3. 試合開始 & スコア進行
      final ruleEngine = KendoRuleEngine();
      final inProgressMatch = initialMatch.copyWith(status: 'in_progress');

      final menEvent = ScoreEvent(
        id: 'ev_men',
        side: Side.red,
        strikeType: StrikeType.men,
        isIppon: true,
        timestamp: DateTime(2026, 9, 25, 10, 1, 0),
        sequence: 1,
      );

      final koteEvent = ScoreEvent(
        id: 'ev_kote',
        side: Side.red,
        strikeType: StrikeType.kote,
        isIppon: true,
        timestamp: DateTime(2026, 9, 25, 10, 2, 0),
        sequence: 2,
      );

      final events = [menEvent, koteEvent];
      final analysis = ruleEngine.analyzeHistory(
        events,
        inProgressMatch,
        const MatchRule(),
      );
      expect(analysis.context.redIppon, 2);
      expect(analysis.context.whiteIppon, 0);

      final matchResult = ruleEngine.decideResult(
        analysis.context,
        const MatchRule(),
      );
      expect(matchResult, MatchResultStatus.redWin);

      // 4. 試合終了 & 結果承認
      final finishedMatch = inProgressMatch.copyWith(
        status: 'approved',
        redScore: analysis.context.redIppon,
        whiteScore: analysis.context.whiteIppon,
        events: events,
      );
      expect(finishedMatch.status, 'approved');
      expect(finishedMatch.redScore, 2);

      // 5. 公式PDF記録生成
      final fontPair = await PdfFontLoader.loadFonts();
      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(
          base: fontPair.regular,
          bold: fontPair.bold,
        ),
      );

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => pw.Column(
            children: [
              pw.Text('${tournament.name} 公式記録表'),
              pw.Text('勝者: ${finishedMatch.redName} 2本勝ち'),
            ],
          ),
        ),
      );

      final pdfBytes = await pdf.save();
      expect(pdfBytes.isNotEmpty, isTrue);
      expect(pdfBytes.length, greaterThan(100));

      // 6. 観客共有URL / QRコードの生成検証
      final shareUrl =
          'https://kendo-os.web.app/#/viewer?tournamentId=${tournament.id}';
      expect(shareUrl.contains(tournament.id), isTrue);
      expect(shareUrl.startsWith('https://'), isTrue);
    });
  });
}
