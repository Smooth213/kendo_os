import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/match_model.dart';
import '../models/score_event.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

class PdfService {
  // ★ 共通処理：PDFのデータ（中身）を作成する裏方メソッド
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

          // ★ 修正：勝ち抜き戦と団体戦でレイアウト（1列/2列）を賢く出し分ける
          for (int i = 0; i < groupDataList.length; i++) {
            final group = groupDataList[i];
            final matches = group['matches'] as List<MatchModel>;
            final isKachinuki = matches.isNotEmpty && matches.first.isKachinuki;

            if (isKachinuki) {
              // 勝ち抜き戦は横に長くなるため、1行をまるごと使って描画する
              contentWidgets.add(_buildPdfKachinukiBracket(group['groupName'], matches, ttf, ttfBold));
              contentWidgets.add(pw.SizedBox(height: 16));
            } else {
              // 通常の団体戦は今まで通り2列で並べる
              final table1 = _buildPdfScoreTable(group['groupName'], matches, ttf, ttfBold);
              pw.Widget table2 = pw.SizedBox();
              
              if (i + 1 < groupDataList.length) {
                final nextGroup = groupDataList[i + 1];
                final nextMatches = nextGroup['matches'] as List<MatchModel>;
                if (!(nextMatches.isNotEmpty && nextMatches.first.isKachinuki)) {
                  table2 = _buildPdfScoreTable(nextGroup['groupName'], nextMatches, ttf, ttfBold);
                  i++; // 次のグループも消費したためスキップ
                }
              }
              
              contentWidgets.add(
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(child: table1),
                    pw.SizedBox(width: 16),
                    pw.Expanded(child: table2),
                  ],
                ),
              );
              contentWidgets.add(pw.SizedBox(height: 16));
            }
          }

          if (contentWidgets.isEmpty) {
            contentWidgets.add(pw.Center(child: pw.Text('データがありません。')));
          }

          return contentWidgets;
        },
      ),
    );

    return pdf.save();
  }

  // ★ 1. PDFとして「印刷」するメイン関数
  static Future<void> printOfficialRecord(String categoryName, List<Map<String, dynamic>> groupDataList) async {
    final pdfBytes = await _generatePdfBytes(categoryName, groupDataList);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: '公式記録_$categoryName.pdf',
    );
  }

  // ★ 2. 画像（PNG）としてLINEなどに「シェア」する機能
  static Future<void> shareOfficialRecordAsImage(String categoryName, List<Map<String, dynamic>> groupDataList) async {
    final pdfBytes = await _generatePdfBytes(categoryName, groupDataList);
    final outputFiles = <XFile>[];

    int pageNum = 1;
    await for (final page in Printing.raster(pdfBytes, dpi: 300)) {
      final pngBytes = await page.toPng();
      outputFiles.add(XFile.fromData(
        pngBytes,
        mimeType: 'image/png',
        name: '公式記録_${categoryName}_$pageNum.png',
      ));
      pageNum++;
    }

    await SharePlus.instance.share(ShareParams(
      files: outputFiles,
      text: '【$categoryName】の公式記録です。',
    ));
  }

  // =========================================================================
  // ★ NEW: 勝ち抜き戦の美しい放射状スコアをPDF上に描画するエンジン
  // =========================================================================
  static pw.Widget _buildPdfKachinukiBracket(String groupName, List<MatchModel> matches, pw.Font ttf, pw.Font ttfBold) {
    if (matches.isEmpty) return pw.SizedBox();

    // ★ 謎の英数字ではなく、試合詳細（note）とチーム名を抽出してタイトルを作る
    final firstMatch = matches.first;
    final note = firstMatch.note;
    final String rTeam = firstMatch.redName.contains(':') ? firstMatch.redName.split(':').first.trim() : firstMatch.redName;
    final String wTeam = firstMatch.whiteName.contains(':') ? firstMatch.whiteName.split(':').first.trim() : firstMatch.whiteName;
    final String titleText = note.isNotEmpty ? '勝ち抜き戦：【$note】 $rTeam vs $wTeam' : '勝ち抜き戦：$rTeam vs $wTeam';

    // レイアウト定義（A4用紙に最適化）
    const double dx = 45.0;       // 1試合の列幅
    const double startX = 45.0;   // 左端のチーム名列幅
    const double height = 280.0;  // 描画エリアの高さ
    
    const double y0 = 0.0;
    const double y1 = 80.0;       // 赤チーム名前エリア
    const double y2 = 200.0;      // 試合エリア（縦線なし）
    const double y3 = 280.0;      // 白チーム名前エリア

    // 選手のスパン計算（誰が何試合目から何試合目まで戦ったか）
    List<_PdfPlayerSpan> redSpans = [];
    List<_PdfPlayerSpan> whiteSpans = [];
    String currentRed = "", currentWhite = "";

    for (int i = 0; i < matches.length; i++) {
      final rName = matches[i].redName.contains(':') ? matches[i].redName.split(':').last.replaceAll(')', '').trim() : matches[i].redName;
      final wName = matches[i].whiteName.contains(':') ? matches[i].whiteName.split(':').last.replaceAll(')', '').trim() : matches[i].whiteName;

      if (rName != currentRed) { 
        redSpans.add(_PdfPlayerSpan(rName, i, i)); 
        currentRed = rName; 
      } else { 
        redSpans.last.endIndex = i; 
      }

      if (wName != currentWhite) { 
        whiteSpans.add(_PdfPlayerSpan(wName, i, i)); 
        currentWhite = wName; 
      } else { 
        whiteSpans.last.endIndex = i; 
      }
    }

    // ★ 追加：PDF出力でも、試合に出ていない「出場待ち」の選手（残機）を右側に追加描画
    final latestMatch = matches.last;
    int currentRedIdx = matches.length;
    for (String name in latestMatch.redRemaining) {
      final cleanName = name.contains(':') ? name.split(':').last.replaceAll(')', '').trim() : name;
      redSpans.add(_PdfPlayerSpan(cleanName, currentRedIdx, currentRedIdx));
      currentRedIdx++;
    }

    int currentWhiteIdx = matches.length;
    for (String name in latestMatch.whiteRemaining) {
      final cleanName = name.contains(':') ? name.split(':').last.replaceAll(')', '').trim() : name;
      whiteSpans.add(_PdfPlayerSpan(cleanName, currentWhiteIdx, currentWhiteIdx));
      currentWhiteIdx++;
    }

    // 合計の列数を、赤と白の多い方に合わせてPDF上の外枠を描画
    int totalCols = currentRedIdx > currentWhiteIdx ? currentRedIdx : currentWhiteIdx;
    final double totalWidth = startX + (totalCols * dx);

    // Canvasへの直線描画関数（PDFの座標系である左下原点に変換して描く）
    void paintBracket(PdfGraphics canvas, PdfPoint size) {
      double invY(double y) => height - y; // PDF座標系（Y軸反転）へ

      void drawLine(double x1, double y1, double x2, double y2, {double w = 1.0}) {
        canvas.setStrokeColor(PdfColors.black);
        canvas.setLineWidth(w);
        canvas.drawLine(x1, invY(y1), x2, invY(y2));
        canvas.strokePath();
      }
      
      void drawRect(double x, double y, double w, double h, {double lw = 1.0}) {
        canvas.setStrokeColor(PdfColors.black);
        canvas.setLineWidth(lw);
        canvas.drawRect(x, invY(y + h), w, h);
        canvas.strokePath();
      }

      // 外枠と横線
      drawRect(0, 0, totalWidth, height, lw: 2.0);
      drawLine(0, y1, totalWidth, y1, w: 2.0);
      drawLine(0, y2, totalWidth, y2, w: 2.0);
      drawLine(startX, 0, startX, height, w: 2.0);

      // 赤チームの名前枠（縦仕切り）
      for (var span in redSpans) {
        double left = startX + (span.startIndex * dx);
        if (span.startIndex > 0) {
          drawLine(left, y0, left, y1);
        }
      }

      // 白チームの名前枠（縦仕切り）
      for (var span in whiteSpans) {
        double left = startX + (span.startIndex * dx);
        if (span.startIndex > 0) {
          drawLine(left, y2, left, y3);
        }
      }

      // 試合結果の放射線と✕
      for (int i = 0; i < matches.length; i++) {
        var match = matches[i];
        bool isDone = match.status == 'finished' || match.status == 'approved';
        if (!isDone) {
          continue;
        }

        var rSpan = redSpans.firstWhere((s) => i >= s.startIndex && i <= s.endIndex);
        var wSpan = whiteSpans.firstWhere((s) => i >= s.startIndex && i <= s.endIndex);
        
        // 放射線の起点（名前枠のど真ん中）
        double rx = startX + (rSpan.startIndex + rSpan.endIndex + 1) * dx / 2;
        double wx = startX + (wSpan.startIndex + wSpan.endIndex + 1) * dx / 2;

        var ptsMap = _calculatePointsRaw(match);
        int rPts = ptsMap['red']!.length;
        int wPts = ptsMap['white']!.length;

        drawLine(rx, y1, wx, y2, w: 1.0); // 放射状の斜め線

        if (rPts == wPts) {
          // 引き分け：線の真ん中に小さな✕
          double cx = (rx + wx) / 2;
          double cy = (y1 + y2) / 2;
          double s = 4.0;
          drawLine(cx - s, cy - s, cx + s, cy + s, w: 1.5);
          drawLine(cx + s, cy - s, cx - s, cy + s, w: 1.5);
        }
      }
    }

    // テキスト配置用のWidgetリスト
    List<pw.Widget> textWidgets = [];

    // 縦書きテキスト生成ヘルパー（文字化け回避の「｜」対応）
    pw.Widget vertText(String text, double x, double y, double w, double h, pw.Font font, {bool isBold = false, double fSize = 9}) {
      final chars = text.split('');
      return pw.Positioned(
        left: x, top: y,
        child: pw.Container(
          width: w, height: h,
          child: pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: chars.map((c) {
                if (c == 'ー' || c == '-') {
                  return pw.Container(width: 1, height: fSize * 0.8, color: PdfColors.black, margin: const pw.EdgeInsets.symmetric(vertical: 1));
                }
                if (c == '(' || c == ')' || c == '（' || c == '）') {
                   return pw.Text(c, style: pw.TextStyle(font: font, fontSize: fSize * 0.8, fontWeight: isBold ? pw.FontWeight.bold : null));
                }
                return pw.Text(c, style: pw.TextStyle(font: font, fontSize: fSize, fontWeight: isBold ? pw.FontWeight.bold : null));
              }).toList()
            )
          )
        )
      );
    }

    // チーム名
    textWidgets.add(vertText(rTeam, 0, y0, startX, y1 - y0, ttfBold, isBold: true, fSize: 11));
    textWidgets.add(vertText(wTeam, 0, y2, startX, y3 - y2, ttfBold, isBold: true, fSize: 11));

    // 選手名
    for (var span in redSpans) {
      double left = startX + (span.startIndex * dx);
      double w = ((span.endIndex - span.startIndex) + 1) * dx;
      textWidgets.add(vertText(span.name, left, y0, w, y1 - y0, ttf));
    }
    for (var span in whiteSpans) {
      double left = startX + (span.startIndex * dx);
      double w = ((span.endIndex - span.startIndex) + 1) * dx;
      textWidgets.add(vertText(span.name, left, y2, w, y3 - y2, ttf));
    }

    // スコアマーク（◯など）
    for (int i = 0; i < matches.length; i++) {
      var match = matches[i];
      bool isDone = match.status == 'finished' || match.status == 'approved';
      if (!isDone) {
        continue;
      }

      var ptsMap = _calculatePointsRaw(match);
      int rPts = ptsMap['red']!.length;
      int wPts = ptsMap['white']!.length;
      double leftX = startX + (i * dx);
      
      if (rPts > wPts) {
        textWidgets.add(pw.Positioned(left: leftX, top: y1 + 5, child: pw.Container(width: dx, child: pw.Center(child: _pdfScoreColumn(ptsMap['red']!, ttfBold)))));
      } else if (wPts > rPts) {
        // 白の勝利は下から上へ
        textWidgets.add(pw.Positioned(left: leftX, bottom: (height - y2) + 5, child: pw.Container(width: dx, child: pw.Center(child: _pdfScoreColumn(ptsMap['white']!, ttfBold, reverse: true)))));
      }
    }

    // 大枠のコンテナ（FittedBoxでA4サイズに自動縮小させる）
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // ★ groupName（英数字）の代わりに、上で作った titleText を描画する！
        pw.Text(titleText, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: ttfBold, fontSize: 12)),
        pw.SizedBox(height: 8),
        pw.FittedBox(
          fit: pw.BoxFit.scaleDown,
          alignment: pw.Alignment.centerLeft,
          child: pw.Container(
            width: totalWidth,
            height: height,
            child: pw.Stack(
              children: [
                pw.CustomPaint(size: PdfPoint(totalWidth, height), painter: paintBracket), // 描画
                ...textWidgets, // テキスト
              ]
            )
          )
        )
      ]
    );
  }

  // スコアの縦並び描画（公式ルールで最初の1本目のみ◯）
  static pw.Widget _pdfScoreColumn(List<_PdfPointData> pts, pw.Font ttfBold, {bool reverse = false}) {
    final widgets = pts.map((p) {
      final text = pw.Text(p.mark, style: pw.TextStyle(font: ttfBold, fontSize: 9));
      if (p.isFirstOverall && p.mark != '◯') {
        return pw.Container(
          margin: const pw.EdgeInsets.symmetric(vertical: 1),
          padding: const pw.EdgeInsets.all(2),
          decoration: pw.BoxDecoration(shape: pw.BoxShape.circle, border: pw.Border.all(color: PdfColors.black, width: 1)),
          child: text
        );
      }
      return pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 2), child: text);
    }).toList();

    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      children: reverse ? widgets.reversed.toList() : widgets,
    );
  }

  // =========================================================================
  // 通常の団体戦オーダー表描画
  // =========================================================================
  static pw.Widget _buildPdfScoreTable(String groupName, List<MatchModel> matches, pw.Font ttf, pw.Font ttfBold) {
    if (matches.isEmpty) return pw.SizedBox();

    final note = matches.first.note;
    final redTeam = matches.first.redName.split(':').first;
    final whiteTeam = matches.first.whiteName.split(':').first;

    // ★ 同姓判定用リスト
    Map<String, String> parse(String raw) {
      if (raw.contains('欠員')) return {'last': '', 'first': ''};
      String clean = raw.contains(':') ? raw.split(':').last.replaceAll(RegExp(r'[()（）]'), '').trim() : raw.trim();
      var parts = clean.split(RegExp(r'\s+'));
      return {'last': parts[0], 'first': parts.length > 1 ? parts[1] : ''};
    }
    List<String> rLasts = matches.map((m) => parse(m.redName)['last']!).where((s) => s.isNotEmpty).toList();
    List<String> wLasts = matches.map((m) => parse(m.whiteName)['last']!).where((s) => s.isNotEmpty).toList();

    // ★ 勝敗判定ロジック
    String teamWinner = 'draw';
    int rWins = 0, wWins = 0, rPts = 0, wPts = 0;
    MatchModel? daihyo;
    for (var m in matches) {
      final rs = (m.redScore as num).toInt(); 
      final ws = (m.whiteScore as num).toInt();
      rPts += rs; 
      wPts += ws;
      if (rs > ws) {
        rWins++;
      } else if (ws > rs) {
        wWins++;
      }
      if (m.matchType == '代表戦') {
        daihyo = m;
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

    final String titleText = note.isNotEmpty ? '【$note】 $redTeam vs $whiteTeam' : '$redTeam vs $whiteTeam';
    final Map<int, pw.TableColumnWidth> columnWidths = {
      0: const pw.FlexColumnWidth(1.4), 
      for (int i = 1; i <= matches.length; i++) i: const pw.FlexColumnWidth(1.0),
      matches.length + 1: const pw.FlexColumnWidth(1.0), 
    };

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(6), color: PdfColors.grey200, width: double.infinity,
          child: pw.Text(titleText, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: ttfBold, fontSize: 11)),
        ),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.black, width: 1),
          columnWidths: columnWidths,
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                pw.SizedBox(), // ★ 修正：「ポジション」のテキストセルを削除して完全に空欄に
                ...matches.map((m) => pw.Center(child: pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(m.matchType, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, font: ttfBold))))),
                pw.Center(child: pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('勝/本', style: const pw.TextStyle(fontSize: 9)))),
              ],
            ),
            pw.TableRow(children: [
              _pdfTeamCell(redTeam, PdfColors.red900, ttfBold),
              // ★ 修正：同姓判定リストを渡す
              ...matches.map((m) => _pdfNameCell(m.redName, rLasts, ttf)),
              _pdfSummaryCell(matches, true, ttfBold),
            ]),
            pw.TableRow(children: [
              pw.SizedBox(),
              ...matches.map((m) => _pdfScoreCell(m, ttfBold)),
              _pdfTeamResultCell(teamWinner, ttfBold),
            ]),
            pw.TableRow(children: [
              _pdfTeamCell(whiteTeam, PdfColors.black, ttfBold),
              // ★ 修正：同姓判定リストを渡す
              ...matches.map((m) => _pdfNameCell(m.whiteName, wLasts, ttf)),
              _pdfSummaryCell(matches, false, ttfBold),
            ]),
          ],
        ),
      ],
    );
  }

  static pw.Widget _pdfTeamResultCell(String winner, pw.Font fontBold) {
    return pw.Container(
      height: 60, // ★ PDF側のスコアセルと全く同じ高さに強制固定
      alignment: pw.Alignment.center,
      child: pw.Stack(
        alignment: pw.Alignment.center,
        children: [
          // ★ 引き分け以外の場合、隣のセルの横線とシームレスに繋ぐ
          if (winner != 'draw')
            pw.Divider(color: PdfColors.black, thickness: 1, height: 0),
          
          if (winner == 'draw')
            pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center, 
                children: '引き分け'.split('').map((c) => pw.Text(c, style: pw.TextStyle(font: fontBold, fontSize: 9))).toList()
              )
            )
          else
            pw.Column(
              children: [
                // 上半分のど真ん中に配置
                pw.Expanded(child: pw.Center(child: pw.Text(winner == 'red' ? '勝' : '負', style: pw.TextStyle(font: fontBold, fontSize: 11, color: winner == 'red' ? PdfColors.red : PdfColors.black)))),
                // 下半分のど真ん中に配置
                pw.Expanded(child: pw.Center(child: pw.Text(winner == 'white' ? '勝' : '負', style: pw.TextStyle(font: fontBold, fontSize: 11, color: winner == 'white' ? PdfColors.red : PdfColors.black)))),
              ],
            ),
        ],
      ),
    );
  }

  static pw.Widget _pdfTeamCell(String name, PdfColor color, pw.Font fontBold) => pw.Center(
    child: pw.Padding(
      padding: const pw.EdgeInsets.all(6), 
      child: pw.Text(name, style: pw.TextStyle(color: color, fontWeight: pw.FontWeight.bold, font: fontBold, fontSize: 10))
    )
  );

  // ★ 修正：PDFセル上の名前描画（欠員対応、同姓対応）
  static pw.Widget _pdfNameCell(String rawName, List<String> teamLastNames, pw.Font ttf) {
    if (rawName.contains('欠員')) return pw.SizedBox(); // 完全に空欄

    String clean = rawName.contains(':') ? rawName.split(':').last.replaceAll(RegExp(r'[()（）]'), '').trim() : rawName.trim();
    var parts = clean.split(RegExp(r'\s+'));
    final lastName = parts[0];
    final firstName = parts.length > 1 ? parts[1] : '';
    
    final showInitial = teamLastNames.where((n) => n == lastName).length > 1 && firstName.isNotEmpty;

    final lastNameVert = lastName.split('').join('\n');
    
    return pw.Center(
      child: pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2), 
        child: pw.Row(
          mainAxisSize: pw.MainAxisSize.min,
          crossAxisAlignment: pw.CrossAxisAlignment.end, // 下揃え
          children: [
            pw.Text(lastNameVert, style: pw.TextStyle(font: ttf, fontSize: 9), textAlign: pw.TextAlign.center),
            if (showInitial)
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 1, bottom: 0),
                child: pw.Text(firstName.substring(0, 1), style: pw.TextStyle(font: ttf, fontSize: 6, color: PdfColors.grey700))
              )
          ]
        )
      )
    );
  }

  static pw.Widget _pdfScoreCell(MatchModel m, pw.Font fontBold) {
    final isDone = m.status == 'finished' || m.status == 'approved';
    final isDraw = isDone && (m.redScore == m.whiteScore);
    final rScore = (m.redScore as num).toInt();
    final wScore = (m.whiteScore as num).toInt();

    // ポイント抽出ロジック（先取判定付き）
    List<_PdfPointData> redPts = [];
    List<_PdfPointData> whitePts = [];
    int rH = 0, wH = 0;
    bool isFirst = true;
    for (var e in m.events) {
      if (e.type == PointType.undo) {
        continue;
      }
      if (e.type == PointType.hansoku) {
        if (e.side == Side.red) {
          rH++;
          if (rH == 2 || rH == 4) {
            whitePts.add(_PdfPointData('反', isFirst));
            isFirst = false;
          }
        } else if (e.side == Side.white) {
          wH++;
          if (wH == 2 || wH == 4) {
            redPts.add(_PdfPointData('反', isFirst));
            isFirst = false;
          }
        }
      } else {
        if (e.side == Side.red) {
          redPts.add(_PdfPointData(_toMark(e.type), isFirst));
          isFirst = false;
        } else if (e.side == Side.white) {
          whitePts.add(_PdfPointData(_toMark(e.type), isFirst));
          isFirst = false;
        }
      }
    }

    return pw.Container(
      height: 60, // ★ PDFも視認性向上のため少し拡張
      alignment: pw.Alignment.center,
      child: pw.Stack(
        alignment: pw.Alignment.center,
        children: [
          pw.Divider(color: PdfColors.black, thickness: 1, height: 0),
          if (isDraw) pw.Center(child: pw.Text('×', style: pw.TextStyle(fontSize: 32, color: PdfColors.red300, font: fontBold))),
          pw.Column(
            children: [
              pw.Expanded(child: _pdfPointBox(redPts, rScore > wScore, true, fontBold)),
              pw.Expanded(child: _pdfPointBox(whitePts, wScore > rScore, false, fontBold)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _pdfPointBox(List<_PdfPointData> pts, bool isWinner, bool isRed, pw.Font fontBold) {
    if (pts.isEmpty && !isWinner) return pw.SizedBox();
    final color = isRed ? PdfColors.red : PdfColors.black;
    final bool isFusen = pts.length == 2 && pts.every((p) => p.mark == '◯');

    return pw.Container(
      width: 26, height: 26,
      child: pw.Stack(
        alignment: pw.Alignment.center,
        children: [
          if (isWinner)
            pw.Container(
              width: 26, height: 26,
              decoration: pw.BoxDecoration(shape: pw.BoxShape.circle, border: pw.Border.all(color: color, width: 0.8)),
            ),
          
          if (isFusen)
            // ★ 修正：不戦勝は中央に縦並び
            pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text('◯', style: pw.TextStyle(font: fontBold, fontSize: 10, color: color)),
                pw.Text('◯', style: pw.TextStyle(font: fontBold, fontSize: 10, color: color)),
              ]
            )
          else
            // ★ 修正：1本目左上、2本目右下に完全固定
            pw.Stack(
              children: [
                if (pts.isNotEmpty)
                  pw.Positioned(top: 4, left: 5, child: _pdfSingleMark(pts[0], color, fontBold)),
                if (pts.length > 1)
                  pw.Positioned(bottom: 4, right: 5, child: _pdfSingleMark(pts[1], color, fontBold)),
              ]
            ),
        ],
      ),
    );
  }

  static pw.Widget _pdfSingleMark(_PdfPointData p, PdfColor color, pw.Font fontBold) {
    if (p.isFirstOverall && p.mark != '◯') {
      // ★ 修正：縦横を同値（10x10）に固定し、Alignment.center で文字を中央に配置して「真円」を作る
      return pw.Container(
        width: 10, height: 10,
        alignment: pw.Alignment.center,
        decoration: pw.BoxDecoration(shape: pw.BoxShape.circle, border: pw.Border.all(color: color, width: 0.8)),
        child: pw.Text(p.mark, style: pw.TextStyle(font: fontBold, fontSize: 6, color: color)),
      );
    }
    return pw.Text(p.mark, style: pw.TextStyle(font: fontBold, fontSize: 8, color: color));
  }

  static pw.Widget _pdfSummaryCell(List<MatchModel> ms, bool isRed, pw.Font fontBold) {
    int wins = 0, pts = 0;
    for (var m in ms) {
      final r = (m.redScore as num).toInt();
      final w = (m.whiteScore as num).toInt();
      pts += isRed ? r : w;
      if (isRed && r > w) {
        wins++;
      }
      if (!isRed && w > r) {
        wins++;
      }
    }
    return pw.Center(child: pw.Text('$wins\nー\n$pts', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold, fontSize: 10), textAlign: pw.TextAlign.center));
  }

  static String _toMark(PointType t) {
    switch (t) {
      case PointType.men: return 'メ';
      case PointType.kote: return 'コ';
      case PointType.doIdo: return 'ド';
      case PointType.tsuki: return 'ツ';
      case PointType.hansoku: return '反';
      case PointType.fusen: return '◯';
      default: return '';
    }
  }

  // 共通のポイント計算メソッド
  static Map<String, List<_PdfPointData>> _calculatePointsRaw(MatchModel match) {
    List<_PdfPointData> redPts = [], whitePts = [];
    int rH = 0, wH = 0;
    bool isFirst = true; 
    for (var e in match.events) {
      if (e.type == PointType.undo) {
        continue;
      }
      String mark = '';
      Side side = e.side;
      if (e.type == PointType.hansoku) {
        if (e.side == Side.red) {
          rH++;
          if (rH == 2 || rH == 4) {
            mark = '反';
            side = Side.white;
          } else {
            continue;
          }
        } else if (e.side == Side.white) {
          wH++;
          if (wH == 2 || wH == 4) {
            mark = '反';
            side = Side.red;
          } else {
            continue;
          }
        }
      } else {
        mark = _toMark(e.type);
      }
      if (side == Side.red) {
        redPts.add(_PdfPointData(mark, isFirst));
        isFirst = false;
      } else if (side == Side.white) {
        whitePts.add(_PdfPointData(mark, isFirst));
        isFirst = false;
      }
    }
    return {'red': redPts, 'white': whitePts};
  }
}

// ヘルパークラス
class _PdfPlayerSpan {
  final String name;
  final int startIndex;
  int endIndex;
  _PdfPlayerSpan(this.name, this.startIndex, this.endIndex);
}

class _PdfPointData {
  final String mark;
  final bool isFirstOverall;
  _PdfPointData(this.mark, this.isFirstOverall);
}