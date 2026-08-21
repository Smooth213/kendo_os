import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/pdf/painters/pdf_kachinuki_painter.dart';
import 'package:kendo_os/features/pdf/widgets/pdf_individual_list.dart';
import 'package:kendo_os/features/pdf/widgets/pdf_league_table.dart';
import 'package:kendo_os/features/pdf/widgets/pdf_team_table.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

/// PDFのヘッダー・フッターおよびコンテンツレイアウト構築ヘルパー
class PdfPageLayoutHelper {
  /// PDFヘッダーウィジェット構築
  static pw.Widget buildHeader({
    required String categoryName,
    String? tournamentName,
    String? tournamentDate,
    String? tournamentVenue,
    required DateTime outputTime,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  '公式記録',
                  style: pw.TextStyle(
                    fontSize: AppFontSize.headline,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (tournamentName != null && tournamentName.isNotEmpty) ...[
                  pw.SizedBox(width: 12),
                  pw.Text(
                    tournamentName,
                    style: pw.TextStyle(
                      fontSize: AppFontSize.body,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
            pw.Text(
              DateFormat('yyyy/MM/dd HH:mm 出力').format(outputTime),
              style: const pw.TextStyle(
                fontSize: AppFontSize.badge,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ),
        if ((tournamentDate != null && tournamentDate.isNotEmpty) ||
            (tournamentVenue != null && tournamentVenue.isNotEmpty)) ...[
          pw.SizedBox(height: 6),
          pw.Row(
            children: [
              if (tournamentDate != null && tournamentDate.isNotEmpty)
                pw.Text(
                  '開催日: $tournamentDate',
                  style: const pw.TextStyle(
                    fontSize: AppFontSize.caption,
                    color: PdfColors.grey800,
                  ),
                ),
              if (tournamentDate != null &&
                  tournamentDate.isNotEmpty &&
                  tournamentVenue != null &&
                  tournamentVenue.isNotEmpty)
                pw.SizedBox(width: 16),
              if (tournamentVenue != null && tournamentVenue.isNotEmpty)
                pw.Text(
                  '場所: $tournamentVenue',
                  style: const pw.TextStyle(
                    fontSize: AppFontSize.caption,
                    color: PdfColors.grey800,
                  ),
                ),
            ],
          ),
        ],
        pw.SizedBox(height: 4),
        pw.Text(
          'カテゴリ: $categoryName',
          style: pw.TextStyle(
            fontSize: AppFontSize.body,
            color: PdfColors.indigo900,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Divider(thickness: 2),
        pw.SizedBox(height: 12),
      ],
    );
  }

  /// PDFフッターウィジェット構築
  static pw.Widget buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: AppSpacing.compact),
      child: pw.Text(
        '${context.pageNumber} / ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: AppFontSize.small),
      ),
    );
  }

  /// PDF本文コンテンツウィジェット群構築
  static List<pw.Widget> buildContentWidgets({
    required List<Map<String, dynamic>> groupDataList,
    required pw.Font ttf,
    required pw.Font ttfBold,
  }) {
    final List<pw.Widget> contentWidgets = [];

    for (int i = 0; i < groupDataList.length; i++) {
      final group = groupDataList[i];
      final matches =
          group['matches']
              as List<dynamic>; // MatchModel でも MatchProjection でも可
      if (matches.isEmpty) continue;

      final first = matches.first;

      bool isKachinuki = false;
      if (first is MatchModel) {
        isKachinuki = first.rule?.isKachinuki ?? false;
      } else {
        try {
          isKachinuki = first.isKachinuki;
        } catch (_) {
          isKachinuki = false;
        }
      }

      final bool isLeague = matches.any((m) => m.note.contains('[リーグ戦]'));

      if (isKachinuki) {
        contentWidgets.add(
          PdfKachinukiPainter.build(group['groupName'], matches, ttf, ttfBold),
        );
        contentWidgets.add(pw.SizedBox(height: 16));
      } else if (isLeague) {
        _buildLeagueContent(
          contentWidgets: contentWidgets,
          groupName: group['groupName'],
          matches: matches,
          ttf: ttf,
          ttfBold: ttfBold,
        );
      } else {
        i = _buildTournamentContent(
          contentWidgets: contentWidgets,
          groupDataList: groupDataList,
          currentIndex: i,
          matches: matches,
          groupName: group['groupName'],
          ttf: ttf,
          ttfBold: ttfBold,
        );
      }
    }

    if (contentWidgets.isEmpty) {
      contentWidgets.add(
        pw.Center(
          child: pw.Text('データがありません。', style: pw.TextStyle(font: ttf)),
        ),
      );
    }

    return contentWidgets;
  }

  static void _buildLeagueContent({
    required List<pw.Widget> contentWidgets,
    required String groupName,
    required List<dynamic> matches,
    required pw.Font ttf,
    required pw.Font ttfBold,
  }) {
    final normalMatches = matches
        .where((m) => !m.note.contains('[順位決定戦]'))
        .toList();
    final tieBreakMatches = matches
        .where((m) => m.note.contains('[順位決定戦]'))
        .toList();

    if (normalMatches.isNotEmpty) {
      final allFinished = normalMatches.every(
        (m) =>
            m.status.toString().contains('finished') ||
            m.status.toString().contains('approved'),
      );
      final statusText = allFinished ? '（最終結果）' : '（進行中）';

      contentWidgets.add(
        pw.Text(
          '【リーグ表】 $statusText',
          style: pw.TextStyle(font: ttfBold, fontSize: AppFontSize.body),
        ),
      );
      contentWidgets.add(pw.SizedBox(height: 10));
      contentWidgets.add(
        PdfLeagueTable.build(groupName, normalMatches, ttf, ttfBold),
      );
      contentWidgets.add(pw.SizedBox(height: 24));

      contentWidgets.add(
        pw.Text(
          '【対戦詳細スコア】',
          style: pw.TextStyle(font: ttfBold, fontSize: AppFontSize.small),
        ),
      );
      contentWidgets.add(pw.SizedBox(height: 10));

      final matchups = <String, List<dynamic>>{};
      for (var m in normalMatches) {
        final t1 = m.redName.split(':').first.trim();
        final t2 = m.whiteName.split(':').first.trim();
        final key = '$t1 vs $t2';
        if (!matchups.containsKey(key)) matchups[key] = [];
        matchups[key]!.add(m);
      }
      final matchupLists = matchups.values
          .where((ms) => !ms.any((m) => m.note.contains('[SUMMARY]')))
          .toList();
      final isIndivLeague = normalMatches.any(
        (m) =>
            m.matchType == 'individual' ||
            m.matchType == '選手' ||
            m.matchType.contains('個人戦') ||
            (!m.redName.contains(':') && !m.whiteName.contains(':')),
      );

      if (isIndivLeague) {
        final indivMatches = normalMatches
            .where((m) => !m.note.contains('[SUMMARY]'))
            .toList();
        if (indivMatches.isNotEmpty) {
          contentWidgets.add(
            PdfIndividualList.build('対戦スコア詳細', indivMatches, ttf, ttfBold),
          );
          contentWidgets.add(pw.SizedBox(height: 16));
        }
      } else {
        for (int j = 0; j < matchupLists.length; j += 2) {
          final pw.Widget table1 = PdfTeamTable.build(
            'matchup',
            matchupLists[j],
            ttf,
            ttfBold,
          );
          pw.Widget table2 = pw.SizedBox();
          if (j + 1 < matchupLists.length) {
            table2 = PdfTeamTable.build(
              'matchup',
              matchupLists[j + 1],
              ttf,
              ttfBold,
            );
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
    }

    if (tieBreakMatches.isNotEmpty) {
      contentWidgets.add(pw.SizedBox(height: 8));
      contentWidgets.add(
        pw.Text(
          '▼ 順位決定戦',
          style: pw.TextStyle(
            font: ttfBold,
            fontSize: AppFontSize.small,
            color: PdfColors.orange700,
          ),
        ),
      );
      contentWidgets.add(pw.SizedBox(height: 10));

      final isIndivTie = tieBreakMatches.any(
        (m) =>
            m.matchType == 'individual' ||
            m.matchType == '選手' ||
            m.matchType.contains('個人戦'),
      );

      if (isIndivTie) {
        contentWidgets.add(
          pw.SizedBox(
            width: PdfPageFormat.a4.availableWidth / 2 - 8,
            child: PdfIndividualList.build(
              '順位決定戦',
              tieBreakMatches,
              ttf,
              ttfBold,
            ),
          ),
        );
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
          contentWidgets.add(
            pw.SizedBox(
              width: PdfPageFormat.a4.availableWidth / 2 - 8,
              child: PdfTeamTable.build(entry.key, entry.value, ttf, ttfBold),
            ),
          );
          contentWidgets.add(pw.SizedBox(height: 16));
        }
      }
    }
    contentWidgets.add(pw.SizedBox(height: 16));
  }

  static int _buildTournamentContent({
    required List<pw.Widget> contentWidgets,
    required List<Map<String, dynamic>> groupDataList,
    required int currentIndex,
    required List<dynamic> matches,
    required String groupName,
    required pw.Font ttf,
    required pw.Font ttfBold,
  }) {
    int i = currentIndex;
    if (matches.any((m) => m.note.contains('[SUMMARY]'))) return i;

    final isIndiv = matches.any(
      (m) =>
          m.matchType == 'individual' ||
          m.matchType == '選手' ||
          m.matchType.contains('個人戦'),
    );
    final pw.Widget table1 = isIndiv
        ? PdfIndividualList.build(groupName, matches, ttf, ttfBold)
        : PdfTeamTable.build(groupName, matches, ttf, ttfBold);
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
          try {
            nextIsKachinuki = nextFirst.isKachinuki;
          } catch (_) {}
        }
        if (!(nextIsKachinuki || nextFirst.note.contains('[リーグ戦]'))) {
          final isNextIndiv = nextMatches.any(
            (m) =>
                m.matchType == 'individual' ||
                m.matchType == '選手' ||
                m.matchType.contains('個人戦'),
          );
          table2 = isNextIndiv
              ? PdfIndividualList.build(
                  nextGroup['groupName'],
                  nextMatches,
                  ttf,
                  ttfBold,
                )
              : PdfTeamTable.build(
                  nextGroup['groupName'],
                  nextMatches,
                  ttf,
                  ttfBold,
                );
          i++;
        }
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

    return i;
  }
}
