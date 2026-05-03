import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/match_model.dart';
import '../service/pdf/painters/pdf_kachinuki_painter.dart';
import '../service/pdf/widgets/pdf_league_table.dart';
import '../service/pdf/widgets/pdf_individual_list.dart';
import '../service/pdf/widgets/pdf_team_table.dart';

class PdfService {
  static Future<Uint8List> _generatePdfBytes(String categoryName, List<Map<String, dynamic>> groupDataList) async {
    final fontData = await rootBundle.load('assets/fonts/NotoSansJP-Regular.ttf');
    final ttf = pw.Font.ttf(fontData);
    final fontDataBold = await rootBundle.load('assets/fonts/NotoSansJP-Bold.ttf');
    final ttfBold = pw.Font.ttf(fontDataBold);

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
        
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('公式記録', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Text(DateFormat('yyyy/MM/dd HH:mm 出力').format(DateTime.now()), style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Text('カテゴリ: $categoryName', style: pw.TextStyle(fontSize: 14, color: PdfColors.indigo900, fontWeight: pw.FontWeight.bold)),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 12),
            ],
          );
        },
        
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Text('${context.pageNumber} / ${context.pagesCount}', style: const pw.TextStyle(fontSize: 12)),
          );
        },
        
        build: (pw.Context context) {
          final List<pw.Widget> contentWidgets = [];

          for (int i = 0; i < groupDataList.length; i++) {
            final group = groupDataList[i];
            final matches = group['matches'] as List<dynamic>; // MatchModel でも MatchProjection でも可
            if (matches.isEmpty) continue;

            final first = matches.first;
            
            // ★重要: MatchModel (rule.isKachinuki) と MatchProjection (isKachinuki) の両方に対応
            bool isKachinuki = false;
            if (first is MatchModel) {
              isKachinuki = first.rule?.isKachinuki ?? false;
            } else {
              // Projection の場合はプロパティを直接参照（リフレクション的な dynamic アクセス）
              try {
                isKachinuki = first.isKachinuki;
              } catch (_) {
                isKachinuki = false;
              }
            }

            final bool isLeague = matches.any((m) => m.note.contains('[リーグ戦]'));

            if (isKachinuki) {
              contentWidgets.add(PdfKachinukiPainter.build(group['groupName'], matches, ttf, ttfBold));
              contentWidgets.add(pw.SizedBox(height: 16));
            } else if (isLeague) {
              final normalMatches = matches.where((m) => !m.note.contains('[順位決定戦]')).toList();
              final tieBreakMatches = matches.where((m) => m.note.contains('[順位決定戦]')).toList();
              
              if (normalMatches.isNotEmpty) {
                final allFinished = normalMatches.every((m) => m.status.toString().contains('finished') || m.status.toString().contains('approved'));
                final statusText = allFinished ? '（最終結果）' : '（進行中）';
                
                contentWidgets.add(pw.Text('【リーグ表】 $statusText', style: pw.TextStyle(font: ttfBold, fontSize: 14)));
                contentWidgets.add(pw.SizedBox(height: 10));
                contentWidgets.add(PdfLeagueTable.build(group['groupName'], normalMatches, ttf, ttfBold));
                contentWidgets.add(pw.SizedBox(height: 24));

                contentWidgets.add(pw.Text('【対戦詳細スコア】', style: pw.TextStyle(font: ttfBold, fontSize: 12)));
                contentWidgets.add(pw.SizedBox(height: 10));
                
                final matchups = <String, List<dynamic>>{};
                for (var m in normalMatches) {
                  final t1 = m.redName.split(':').first.trim();
                  final t2 = m.whiteName.split(':').first.trim();
                  final key = '$t1 vs $t2';
                  if (!matchups.containsKey(key)) matchups[key] = [];
                  matchups[key]!.add(m);
                }
                final matchupLists = matchups.values.where((ms) => !ms.any((m) => m.note.contains('[SUMMARY]'))).toList();
                final isIndivLeague = normalMatches.any((m) => 
                  m.matchType == 'individual' || m.matchType == '選手' || m.matchType.contains('個人戦') ||
                  (!m.redName.contains(':') && !m.whiteName.contains(':'))
                );
                
                if (isIndivLeague) {
                  final indivMatches = normalMatches.where((m) => !m.note.contains('[SUMMARY]')).toList();
                  if (indivMatches.isNotEmpty) {
                    contentWidgets.add(PdfIndividualList.build('対戦スコア詳細', indivMatches, ttf, ttfBold));
                    contentWidgets.add(pw.SizedBox(height: 16));
                  }
                } else {
                  for (int j = 0; j < matchupLists.length; j += 2) {
                    final pw.Widget table1 = PdfTeamTable.build('matchup', matchupLists[j], ttf, ttfBold);
                    pw.Widget table2 = pw.SizedBox();
                    if (j + 1 < matchupLists.length) table2 = PdfTeamTable.build('matchup', matchupLists[j + 1], ttf, ttfBold);
                    contentWidgets.add(pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.Expanded(child: table1), pw.SizedBox(width: 16), pw.Expanded(child: table2)]));
                    contentWidgets.add(pw.SizedBox(height: 16));
                  }
                }
              }

              if (tieBreakMatches.isNotEmpty) {
                contentWidgets.add(pw.SizedBox(height: 8));
                contentWidgets.add(pw.Text('▼ 順位決定戦', style: pw.TextStyle(font: ttfBold, fontSize: 12, color: PdfColors.orange700)));
                contentWidgets.add(pw.SizedBox(height: 10));
                
                final isIndivTie = tieBreakMatches.any((m) => m.matchType == 'individual' || m.matchType == '選手' || m.matchType.contains('個人戦'));
                
                if (isIndivTie) {
                  contentWidgets.add(pw.SizedBox(width: PdfPageFormat.a4.availableWidth / 2 - 8, child: PdfIndividualList.build('順位決定戦', tieBreakMatches, ttf, ttfBold)));
                  contentWidgets.add(pw.SizedBox(height: 16));
                } else {
                  final tieMatchups = <String, List<dynamic>>{};
                  for (var m in tieBreakMatches) {
                    final t1 = m.redName.split(':').first.trim();
                    final t2 = m.whiteName.split(':').first.trim();
                    final key = '$t1 vs $t2';
                    if (!tieMatchups.containsKey(key)) tieMatchups[key] = [];
                    tieMatchups[key]!.add(m);
                  }
                  for (var entry in tieMatchups.entries) {
                    contentWidgets.add(pw.SizedBox(width: PdfPageFormat.a4.availableWidth / 2 - 8, child: PdfTeamTable.build(entry.key, entry.value, ttf, ttfBold)));
                    contentWidgets.add(pw.SizedBox(height: 16));
                  }
                }
              }
              contentWidgets.add(pw.SizedBox(height: 16));

            } else {
              if (matches.any((m) => m.note.contains('[SUMMARY]'))) continue;
              final isIndiv = matches.any((m) => m.matchType == 'individual' || m.matchType == '選手' || m.matchType.contains('個人戦'));
              final pw.Widget table1 = isIndiv ? PdfIndividualList.build(group['groupName'], matches, ttf, ttfBold) : PdfTeamTable.build(group['groupName'], matches, ttf, ttfBold);
              pw.Widget table2 = pw.SizedBox();
              if (i + 1 < groupDataList.length) {
                final nextGroup = groupDataList[i + 1];
                final nextMatches = nextGroup['matches'] as List<dynamic>;
                if (nextMatches.isNotEmpty) {
                  bool nextIsKachinuki = false;
                  final nextFirst = nextMatches.first;
                  if (nextFirst is MatchModel) {
                    nextIsKachinuki = nextFirst.rule?.isKachinuki ?? false;
                  } else {
                    try { nextIsKachinuki = nextFirst.isKachinuki; } catch (_) {}
                  }
                  if (!(nextIsKachinuki || nextFirst.note.contains('[リーグ戦]'))) {
                    final isNextIndiv = nextMatches.any((m) => m.matchType == 'individual' || m.matchType == '選手' || m.matchType.contains('個人戦'));
                    table2 = isNextIndiv ? PdfIndividualList.build(nextGroup['groupName'], nextMatches, ttf, ttfBold) : PdfTeamTable.build(nextGroup['groupName'], nextMatches, ttf, ttfBold);
                    i++; 
                  }
                }
              }
              contentWidgets.add(pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.Expanded(child: table1), pw.SizedBox(width: 16), pw.Expanded(child: table2)]));
              contentWidgets.add(pw.SizedBox(height: 16));
            }
          }
          if (contentWidgets.isEmpty) contentWidgets.add(pw.Center(child: pw.Text('データがありません。', style: pw.TextStyle(font: ttf))));
          return contentWidgets;
        },
      ),
    );
    return pdf.save();
  }

  static Future<void> printOfficialRecord(String categoryName, List<Map<String, dynamic>> groupDataList) async {
    final pdfBytes = await _generatePdfBytes(categoryName, groupDataList);
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdfBytes, name: '公式記録_$categoryName.pdf');
  }

  static Future<void> shareOfficialRecordAsImage(String categoryName, List<Map<String, dynamic>> groupDataList) async {
    final pdfBytes = await _generatePdfBytes(categoryName, groupDataList);
    final outputFiles = <XFile>[];
    int pageNum = 1;
    await for (final page in Printing.raster(pdfBytes, dpi: 300)) {
      final pngBytes = await page.toPng();
      outputFiles.add(XFile.fromData(pngBytes, mimeType: 'image/png', name: '公式記録_${categoryName}_$pageNum.png'));
      pageNum++;
    }
    await SharePlus.instance.share(ShareParams(files: outputFiles, text: '【$categoryName】の公式記録です。'));
  }
}