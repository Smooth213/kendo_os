import 'tournament_date_parser.dart';
import 'tournament_share_data.dart';
import 'tournament_text_parser_helper.dart';

/// 外部テキスト（TimeTree, LINE, メモ等）から大会・オーダー情報を抽出するパーサー
class TournamentTextParser {
  /// 3重の安全フィルター: テキストが大会・オーダー情報の解析候補かを判定
  static bool isCandidate(String text) {
    final trimmed = text.trim();
    if (trimmed.length < 40) return false;
    final lines = trimmed
        .split(RegExp(r'\r?\n'))
        .where((l) => l.trim().isNotEmpty)
        .toList();
    if (lines.length < 3) return false;

    if (TournamentTextParserHelper.positionKeywords.any(
      (pos) => trimmed.contains(pos),
    )) {
      return true;
    }

    final hasTournament = TournamentTextParserHelper.tournamentKeywords.any(
      (kw) => trimmed.contains(kw),
    );
    final hasDate = TournamentDateParser.dateKeywords.any(
      (kw) => trimmed.contains(kw),
    );
    final hasVenue = TournamentTextParserHelper.venueKeywords.any(
      (kw) => trimmed.contains(kw),
    );

    return hasTournament && hasDate && hasVenue;
  }

  /// テキストを解析して TournamentShareData を生成
  static TournamentShareData parse(String rawText) {
    final lines = rawText.split(RegExp(r'\r?\n'));

    String tournamentName = '';
    DateTime? date;
    String venue = '';
    String address = '';
    final List<ParsedTeamOrder> teams = [];
    final List<String> noteLines = [];

    // 一時変数
    String? currentSectionMatchType;
    String? currentTeamName;
    List<ParsedTeamMember> currentTeamMembers = [];
    final List<String> candidateNames = [];

    void saveCurrentTeam() {
      final teamName = currentTeamName;
      if (teamName != null && currentTeamMembers.isNotEmpty) {
        final initialMatchType =
            currentSectionMatchType ??
            TournamentTextParserHelper.detectInitialMatchType(
              teamName: teamName,
              rawText: rawText,
              memberCount: currentTeamMembers.length,
            );
        if (initialMatchType == '個人戦' || initialMatchType == 'リーグ個人戦') {
          for (final m in currentTeamMembers) {
            final isCategoryOnly =
                teamName.contains('個人') ||
                teamName == '中学生' ||
                teamName == '小学生' ||
                teamName == '低学年' ||
                teamName == '高学年' ||
                teamName == '高校生' ||
                teamName == '一般';
            final entryName = isCategoryOnly ? m.name : '$teamName ${m.name}';
            teams.add(
              ParsedTeamOrder(
                teamName: entryName,
                category: teamName,
                matchType: initialMatchType,
                members: [m],
              ),
            );
          }
        } else {
          teams.add(
            ParsedTeamOrder(
              teamName: teamName,
              matchType: initialMatchType,
              members: List.from(currentTeamMembers),
            ),
          );
        }
        currentTeamMembers.clear();
      }
    }

    // 行ごとに走査
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      if (TournamentTextParserHelper.isIgnoredFooter(line)) continue;

      // 0. 試合形式セクション大見出し（個人戦、団体戦等）の検出
      final sectionType = TournamentTextParserHelper.detectSectionMatchType(
        line,
      );
      if (sectionType != null) {
        saveCurrentTeam();
        currentSectionMatchType = sectionType;
        currentTeamName = TournamentTextParserHelper.cleanTeamHeader(line);
        continue;
      }

      // 1. 日時の検出
      final parsedDate = TournamentDateParser.extractDate(line);
      if (parsedDate != null && date == null) {
        date = parsedDate;
        continue;
      }

      // 2. 会場・場所の検出
      if (TournamentTextParserHelper.isVenueLine(line)) {
        final extractedVenue = TournamentTextParserHelper.cleanVenue(line);
        venue = venue.isEmpty ? extractedVenue : '$venue $extractedVenue';
        continue;
      }

      // 3. 住所の検出
      if (TournamentTextParserHelper.isAddressLine(line)) {
        final extractedAddress = TournamentTextParserHelper.cleanAddress(line);
        if (address.isEmpty) address = extractedAddress;
        continue;
      }

      // 4. ポジション & 選手名の検出
      final member = TournamentTextParserHelper.extractMember(line);
      if (member != null) {
        currentTeamName ??=
            TournamentTextParserHelper.findPreviousTeamName(lines, i) ?? 'チーム';
        currentTeamMembers.add(member);
        continue;
      }

      // 5. チーム名・部門見出しの検出判定
      if (TournamentTextParserHelper.isPossibleTeamHeader(line, lines, i)) {
        saveCurrentTeam();
        currentTeamName = TournamentTextParserHelper.cleanTeamHeader(line);
        continue;
      }

      // 5-b. 個人戦ヘッダー配下の選手名（ポジション接頭辞なし）の検出
      if (currentTeamName != null &&
          (currentSectionMatchType == '個人戦' ||
              currentSectionMatchType == 'リーグ個人戦' ||
              currentTeamName.contains('個人') ||
              currentTeamName.contains('選手'))) {
        final individualMember =
            TournamentTextParserHelper.extractIndividualMember(line);
        if (individualMember != null) {
          currentTeamMembers.add(individualMember);
          continue;
        }
      }

      // 6. 大会名の候補抽出（ヘッダー部にある大会キーワード行）
      if (date == null &&
          venue.isEmpty &&
          teams.isEmpty &&
          TournamentTextParserHelper.isTournamentNameCandidate(line)) {
        candidateNames.add(line);
        continue;
      }

      // それ以外はメモ候補（チームブロック外の行）
      if (currentTeamMembers.isEmpty) {
        noteLines.add(line);
      }
    }

    // 最後のチームを保存
    saveCurrentTeam();

    // 大会名の決定
    if (candidateNames.isNotEmpty) {
      candidateNames.sort((a, b) => b.length.compareTo(a.length));
      tournamentName = candidateNames.first;
    } else if (teams.isNotEmpty && (date != null || venue.isNotEmpty)) {
      for (final l in lines) {
        final trimmed = l.trim();
        if (trimmed.isNotEmpty &&
            !TournamentTextParserHelper.isIgnoredFooter(trimmed) &&
            !trimmed.startsWith('日時') &&
            !trimmed.startsWith('場所') &&
            !trimmed.startsWith('会場')) {
          tournamentName = trimmed;
          break;
        }
      }
    }

    final notes = noteLines.join('\n').trim();

    return TournamentShareData(
      tournamentName: tournamentName,
      date: date,
      venue: venue,
      address: address,
      notes: notes,
      teams: teams,
      rawText: rawText,
    );
  }
}
