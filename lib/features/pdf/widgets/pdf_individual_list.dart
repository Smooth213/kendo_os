import 'package:kendo_os/features/tournament/presentation/operate/providers/team_progress_helper.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:kendo_os/features/pdf/models/pdf_view_model.dart';
import 'package:kendo_os/features/pdf/widgets/pdf_team_table_cell_renderer.dart';

class PdfIndividualList {
  static pw.Widget build(
    String groupName,
    List<dynamic> matches,
    pw.Font ttf,
    pw.Font ttfBold,
  ) {
    if (matches.isEmpty) return pw.SizedBox();

    final note = matches.first.note;
    final isLeague = note.contains('リーグ戦');

    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    String displayGroupName = groupName;
    if (uuidRegex.hasMatch(groupName) ||
        groupName.length > 20 ||
        groupName == '__default__' ||
        groupName.contains(' vs ')) {
      displayGroupName = '';
    }

    final scenePrefix = TeamProgressHelper.getScenePrefixFromDynamic(
      matches.first,
    );
    String headerTitle = '$scenePrefix${isLeague ? '【リーグ個人戦】' : '【個人戦】'}';
    if (displayGroupName.isNotEmpty) {
      headerTitle += ' $displayGroupName';
    }

    // ★note抽出ロジックは削除完了

    final rows = <pw.Widget>[];
    for (int i = 0; i < matches.length; i++) {
      final m = matches[i];
      final rName = m.redName.contains(':')
          ? m.redName.split(':').last.replaceAll(')', '').trim()
          : m.redName;
      final wName = m.whiteName.contains(':')
          ? m.whiteName.split(':').last.replaceAll(')', '').trim()
          : m.whiteName;
      final rTeam = m.redName.contains(':')
          ? m.redName.split(':').first.trim()
          : '';
      final wTeam = m.whiteName.contains(':')
          ? m.whiteName.split(':').first.trim()
          : '';

      final isDone =
          m.status.toString().contains('finished') ||
          m.status.toString().contains('approved');
      final rScore = (m.redScore as num).toInt();
      final wScore = (m.whiteScore as num).toInt();
      final isDraw = isDone && rScore == wScore;
      final rWin = isDone && rScore > wScore;
      final wWin = isDone && wScore > rScore;
      final noteStr = (m.note ?? '').toString();
      final typeStr = (m.matchType ?? '').toString();
      final isEncho =
          isDone &&
          (noteStr.contains('延長') ||
              typeStr.contains('代表') ||
              typeStr.contains('延長'));

      final ptsMap = PdfViewModel.calculatePointsRaw(m);

      // ★ Phase 6-1: 選手名テキストの Overflow 防壁化
      // 非常に長い道場名やフルネームが入り込んだ場合でも、テキストの自動折り返しによって行の高さが想定を超えて膨らみ、
      // ページの境界ボックスを突き破って pdf レンダラが無限ループ（Cannot fit some widgets）を起こすのを100%防止します。
      rows.add(
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(
            vertical: AppSpacing.xs,
            horizontal: AppSpacing.xs,
          ),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
            ),
          ),
          child: pw.Row(
            children: [
              pw.Container(
                width: 45,
                child: pw.Text(
                  m.note.isNotEmpty ? m.note : '第${i + 1}試合',
                  style: pw.TextStyle(
                    font: ttfBold,
                    fontSize: AppFontSize.micro,
                    color: PdfColors.grey600,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    if (rTeam.isNotEmpty)
                      pw.Text(
                        rTeam,
                        style: pw.TextStyle(
                          font: ttf,
                          fontSize: 7,
                          color: PdfColors.grey600,
                        ),
                        maxLines: 1,
                        overflow: pw.TextOverflow.clip,
                      ),
                    pw.Text(
                      rName,
                      style: pw.TextStyle(
                        font: ttfBold,
                        fontSize: AppFontSize.badge,
                        color: rWin ? PdfColors.red700 : PdfColors.black,
                      ),
                      maxLines: 1,
                      overflow: pw.TextOverflow.clip,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 8),
              PdfTeamTableCellRenderer.buildPointBox(
                ptsMap['red']!,
                rWin,
                true,
                ttfBold,
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: AppSpacing.subValue,
                ),
                child: pw.Text(
                  isDraw ? '×' : (isEncho ? '延長' : '-'),
                  style: pw.TextStyle(
                    font: ttfBold,
                    fontSize: isEncho ? 10 : 16,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
              PdfTeamTableCellRenderer.buildPointBox(
                ptsMap['white']!,
                wWin,
                false,
                ttfBold,
              ),
              pw.SizedBox(width: 8),

              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (wTeam.isNotEmpty)
                      pw.Text(
                        wTeam,
                        style: pw.TextStyle(
                          font: ttf,
                          fontSize: 7,
                          color: PdfColors.grey600,
                        ),
                        maxLines: 1,
                        overflow: pw.TextOverflow.clip,
                      ),
                    pw.Text(
                      wName,
                      style: pw.TextStyle(
                        font: ttfBold,
                        fontSize: AppFontSize.badge,
                        color: wWin ? PdfColors.red700 : PdfColors.black,
                      ),
                      maxLines: 1,
                      overflow: pw.TextOverflow.clip,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 個人戦の1ブロックを安全な外枠コンテナとしてラップして返却します
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: AppSpacing.xs),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey500, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.all(AppSpacing.subValue),
            color: PdfColors.grey200,
            width: double.infinity,
            child: pw.Text(
              headerTitle,
              style: pw.TextStyle(font: ttfBold, fontSize: AppFontSize.badge),
            ),
          ),
          ...rows,
        ],
      ),
    );
  }
}
