import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:kendo_os/features/pdf/widgets/pdf_team_table_cell_renderer.dart';

class PdfTeamTable {
  static pw.Widget build(
    String groupName,
    List<dynamic> matches,
    pw.Font ttf,
    pw.Font ttfBold,
  ) {
    if (matches.isEmpty) return pw.SizedBox();

    final note = matches.first.note;
    final isLeague = note.contains('リーグ戦');

    // ★ 修正: 団体戦でもデフォルトのリーグ戦文言を綺麗に消去する
    String cleanNote = note
        .replaceAll('[リーグ戦]', '')
        .replaceAll('[', '')
        .replaceAll(']', '')
        .trim();
    if (cleanNote == 'リーグ戦') {
      cleanNote = '';
    }

    final redTeam = matches.first.redName.split(':').first;
    final whiteTeam = matches.first.whiteName.split(':').first;

    // ★ 修正: 【リーグ団体戦】への切り替えと、パターンA（コメントがない時は括弧ごと消去）の適用
    final prefix = isLeague ? '【リーグ団体戦】' : '【団体戦】';
    final String titleText = cleanNote.isNotEmpty
        ? '$prefix対戦スコア詳細（$cleanNote）'
        : '$prefix対戦スコア詳細';
    Map<String, String> parse(String raw) {
      if (raw.contains('欠員')) return {'last': '', 'first': ''};
      String clean = raw.contains(':')
          ? raw.split(':').last.replaceAll(RegExp(r'[()（）]'), '').trim()
          : raw.trim();
      var parts = clean.split(RegExp(r'\s+'));
      return {'last': parts[0], 'first': parts.length > 1 ? parts[1] : ''};
    }

    List<String> rLasts = matches
        .map((m) => parse(m.redName)['last']!)
        .where((s) => s.isNotEmpty)
        .toList();
    List<String> wLasts = matches
        .map((m) => parse(m.whiteName)['last']!)
        .where((s) => s.isNotEmpty)
        .toList();

    final allFinished = matches.every(
      (m) =>
          m.status.toString().contains('finished') ||
          m.status.toString().contains('approved'),
    );
    String teamWinner = 'none';

    if (allFinished) {
      teamWinner = 'draw';
      int rWins = 0, wWins = 0, rPts = 0, wPts = 0;
      dynamic daihyo;
      for (var m in matches) {
        if (m.matchType == '代表戦') {
          daihyo = m;
          continue; // ★ 修正: 代表戦のスコアはチームの合計(勝数/本数)には含めない
        }
        final rs = (m.redScore as num).toInt();
        final ws = (m.whiteScore as num).toInt();
        rPts += rs;
        wPts += ws;
        if (rs > ws) {
          rWins++;
        } else if (ws > rs) {
          wWins++;
        }
      }
      if (rWins > wWins) {
        teamWinner = 'red';
      } else if (wWins > rWins) {
        teamWinner = 'white';
      } else if (rPts > wPts) {
        teamWinner = 'red';
      } else if (wPts > rPts) {
        teamWinner = 'white';
      } else if (daihyo != null) {
        final rs = (daihyo.redScore as num).toInt();
        final ws = (daihyo.whiteScore as num).toInt();
        if (rs > ws) {
          teamWinner = 'red';
        } else if (ws > rs) {
          teamWinner = 'white';
        }
      }
    }

    // ★ Phase 6-1: A4横幅最適化ガード
    // 7人制や9人制など、試合数（列数）が極端に多くなった場合でも、文字が重なってA4の印刷可能幅から
    // はみ出るのを物理的に防ぐため、列数に応じてフォントサイズとタイトルサイズを決定論的に自動縮小（スケール）させます。
    final double dynamicFontSize = matches.length > 5 ? 7.5 : 9.0;
    final double dynamicTitleSize = matches.length > 5 ? 9.5 : 11.0;

    final Map<int, pw.TableColumnWidth> columnWidths = {
      0: const pw.FlexColumnWidth(1.4),
      for (int i = 1; i <= matches.length; i++)
        i: const pw.FlexColumnWidth(1.0),
      matches.length + 1: const pw.FlexColumnWidth(1.0),
    };

    // ★ Phase 6-1: 改ページ崩れの完全封鎖（pw.Container）
    // 1つの対戦表がページの最下部で不自然に真っ二つに分断されるのを100%防止するため、
    // 表のひとかたまりを pw.Container で包み、ページ内に収まらない場合は自動で次のページへ安全に送出します。
    return pw.Container(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.all(AppSpacing.subValue),
            color: PdfColors.grey200,
            width: double.infinity,
            child: pw.Text(
              titleText,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                font: ttfBold,
                fontSize: dynamicTitleSize,
              ),
            ),
          ),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.black, width: 1),
            columnWidths: columnWidths,
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  pw.SizedBox(),
                  ...matches.map(
                    (m) => pw.Center(
                      child: pw.Padding(
                        padding: const pw.EdgeInsets.all(AppSpacing.xs),
                        child: pw.Text(
                          m.matchType,
                          style: pw.TextStyle(
                            fontSize: dynamicFontSize,
                            fontWeight: pw.FontWeight.bold,
                            font: ttfBold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  pw.Center(
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.all(AppSpacing.xs),
                      child: pw.Text(
                        '本/勝',
                        style: pw.TextStyle(
                          fontSize: dynamicFontSize,
                          font: ttfBold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  PdfTeamTableCellRenderer.buildTeamCell(
                    redTeam,
                    PdfColors.red900,
                    ttfBold,
                  ),
                  ...matches.map(
                    (m) => PdfTeamTableCellRenderer.buildNameCell(
                      m.redName,
                      rLasts,
                      ttf,
                    ),
                  ),
                  PdfTeamTableCellRenderer.buildSummaryCell(
                    matches,
                    true,
                    ttfBold,
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.SizedBox(),
                  ...matches.map(
                    (m) => PdfTeamTableCellRenderer.buildScoreCell(m, ttfBold),
                  ),
                  PdfTeamTableCellRenderer.buildTeamResultCell(
                    teamWinner,
                    ttfBold,
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  PdfTeamTableCellRenderer.buildTeamCell(
                    whiteTeam,
                    PdfColors.black,
                    ttfBold,
                  ),
                  ...matches.map(
                    (m) => PdfTeamTableCellRenderer.buildNameCell(
                      m.whiteName,
                      wLasts,
                      ttf,
                    ),
                  ),
                  PdfTeamTableCellRenderer.buildSummaryCell(
                    matches,
                    false,
                    ttfBold,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 後方互換性エイリアス
  static pw.Widget pdfPointBox(
    dynamic pts,
    bool isWinner,
    bool isRed,
    pw.Font fontBold,
  ) => PdfTeamTableCellRenderer.buildPointBox(
    pts as dynamic,
    isWinner,
    isRed,
    fontBold,
  );
}
