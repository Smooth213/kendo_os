import 'tournament_date_parser.dart';
import 'tournament_share_data.dart';

/// 外部テキスト（TimeTree, LINE, メモ等）から大会・オーダー情報を抽出するパーサー
class TournamentTextParser {
  /// ポジションの判定用キーワード
  static const List<String> _positionKeywords = [
    '先鋒',
    '次鋒',
    '五将',
    '中堅',
    '三将',
    '副将',
    '大将',
    '補欠',
    '補',
    '選手',
    '個人',
    '個人戦',
  ];

  /// 大会識別のキーワード
  static const List<String> _tournamentKeywords = [
    '剣道',
    '大会',
    '選手権',
    '錬成会',
    '杯',
    '個人戦',
    '個人',
  ];

  /// 会場識別のキーワード
  static const List<String> _venueKeywords = [
    '会場',
    '場所',
    '体育館',
    '武道場',
    '武道館',
    'アリーナ',
  ];

  /// 3重の安全フィルター: テキストが大会・オーダー情報の解析候補かを判定
  static bool isCandidate(String text) {
    final trimmed = text.trim();
    if (trimmed.length < 40) return false;
    final lines = trimmed
        .split(RegExp(r'\r?\n'))
        .where((l) => l.trim().isNotEmpty)
        .toList();
    if (lines.length < 3) return false;

    if (_positionKeywords.any((pos) => trimmed.contains(pos))) return true;

    final hasTournament = _tournamentKeywords.any((kw) => trimmed.contains(kw));
    final hasDate = TournamentDateParser.dateKeywords.any(
      (kw) => trimmed.contains(kw),
    );
    final hasVenue = _venueKeywords.any((kw) => trimmed.contains(kw));

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
            _detectInitialMatchType(
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

      if (_isIgnoredFooter(line)) continue;

      // 0. 試合形式セクション大見出し（個人戦、団体戦等）の検出
      final sectionType = _detectSectionMatchType(line);
      if (sectionType != null) {
        saveCurrentTeam();
        currentSectionMatchType = sectionType;
        currentTeamName = _cleanTeamHeader(line);
        continue;
      }

      // 1. 日時の検出
      final parsedDate = TournamentDateParser.extractDate(line);
      if (parsedDate != null && date == null) {
        date = parsedDate;
        continue;
      }

      // 2. 会場・場所の検出
      if (_isVenueLine(line)) {
        final extractedVenue = _cleanVenue(line);
        venue = venue.isEmpty ? extractedVenue : '$venue $extractedVenue';
        continue;
      }

      // 3. 住所の検出
      if (_isAddressLine(line)) {
        final extractedAddress = _cleanAddress(line);
        if (address.isEmpty) address = extractedAddress;
        continue;
      }

      // 4. ポジション & 選手名の検出
      final member = _extractMember(line);
      if (member != null) {
        currentTeamName ??= _findPreviousTeamName(lines, i) ?? 'チーム';
        currentTeamMembers.add(member);
        continue;
      }

      // 5. チーム名・部門見出しの検出判定
      if (_isPossibleTeamHeader(line, lines, i)) {
        saveCurrentTeam();
        currentTeamName = _cleanTeamHeader(line);
        continue;
      }

      // 5-b. 個人戦ヘッダー配下の選手名（ポジション接頭辞なし）の検出
      if (currentTeamName != null &&
          (currentSectionMatchType == '個人戦' ||
              currentSectionMatchType == 'リーグ個人戦' ||
              currentTeamName.contains('個人') ||
              currentTeamName.contains('選手'))) {
        final individualMember = _extractIndividualMember(line);
        if (individualMember != null) {
          currentTeamMembers.add(individualMember);
          continue;
        }
      }

      // 6. 大会名の候補抽出（ヘッダー部にある大会キーワード行）
      if (date == null &&
          venue.isEmpty &&
          teams.isEmpty &&
          _isTournamentNameCandidate(line)) {
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
            !_isIgnoredFooter(trimmed) &&
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

  /// TimeTreeやLINEのフッター、URLを無視対象とする
  static bool _isIgnoredFooter(String line) {
    if (line.contains('timetreeapp.com') ||
        line.contains('TimeTree') ||
        line.contains('共有されました') ||
        line.startsWith('http://') ||
        line.startsWith('https://')) {
      return true;
    }
    return false;
  }

  /// 大会名候補か判定
  static bool _isTournamentNameCandidate(String line) {
    if (line.length > 60) return false;
    return _tournamentKeywords.any((kw) => line.contains(kw));
  }

  /// 会場・場所行か判定
  static bool _isVenueLine(String line) {
    final lower = line.replaceAll(RegExp(r'[ 　]'), '');
    return RegExp(r'^(?:場所|会場|試合会場)[：:]|^【(?:大会会場|会場|試合会場)】').hasMatch(lower);
  }

  /// 会場文字列のクレンジング
  static String _cleanVenue(String line) {
    return line
        .replaceFirst(RegExp(r'^(?:場所|会場|試合会場|開催場所)[　\s:：]+'), '')
        .replaceFirst(RegExp(r'^【(?:大会会場|会場|試合会場)】[　\s]*'), '')
        .trim();
  }

  /// 住所行か判定
  static bool _isAddressLine(String line) {
    final lower = line.replaceAll(RegExp(r'[ 　]'), '');
    return RegExp(
      r'^(?:住所|所在地)[：:]|^〒|^(?:東京都|北海道|(?:京都|大阪)府|.{2,3}県)',
    ).hasMatch(lower);
  }

  /// 住所文字列のクレンジング
  static String _cleanAddress(String line) {
    return line.replaceFirst(RegExp(r'^(?:住所|所在地)[　\s:：]+'), '').trim();
  }

  /// ポジション & 選手名の抽出
  static ParsedTeamMember? _extractMember(String line) {
    final pattern = RegExp(
      r'^(先鋒|次鋒|五将|中堅|三将|副将|大将|補欠|補|選手|個人|個人戦|氏名)[　\s:：]+(.+)$',
    );
    final match = pattern.firstMatch(line.trim());
    if (match != null) {
      final rawPos = match.group(1)!;
      final position = (rawPos == '氏名' || rawPos == '個人' || rawPos == '個人戦')
          ? '選手'
          : rawPos;
      final rawName = match.group(2)!;
      final cleanName = _cleanPlayerName(rawName);
      if (cleanName.isNotEmpty) {
        return ParsedTeamMember(position: position, name: cleanName);
      }
    }
    return null;
  }

  /// 個人戦ヘッダー配下の選手名（ポジション接頭辞なし、番号/箇条書き付き等）を抽出
  static ParsedTeamMember? _extractIndividualMember(String line) {
    var trimmed = line.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('【') ||
        trimmed.startsWith('[') ||
        trimmed.startsWith('［') ||
        trimmed.endsWith('】') ||
        trimmed.endsWith(']') ||
        trimmed.endsWith('］')) {
      return null;
    }
    if (_isIgnoredFooter(trimmed) ||
        _isVenueLine(trimmed) ||
        _isAddressLine(trimmed)) {
      return null;
    }
    if (TournamentDateParser.extractDate(trimmed) != null) return null;
    if (trimmed.startsWith('開館') ||
        trimmed.startsWith('開会') ||
        trimmed.startsWith('集合') ||
        trimmed.startsWith('責任者') ||
        trimmed.startsWith('連絡') ||
        trimmed.startsWith('注意') ||
        trimmed.startsWith('※')) {
      return null;
    }
    trimmed = trimmed.replaceFirst(
      RegExp(
        r'^(?:[0-9]{1,2}[\.\)）:：\s]|[\(（][0-9]{1,2}[\)）]|[①-⑳・\-\*])[　\s]*',
      ),
      '',
    );
    final cleanName = _cleanPlayerName(trimmed);
    if (cleanName.length >= 2 &&
        cleanName.length <= 12 &&
        !cleanName.contains(':') &&
        !cleanName.contains('：')) {
      return ParsedTeamMember(position: '選手', name: cleanName);
    }
    return null;
  }

  /// 選手名から星印や絵文字、不要な記号をクレンジング
  static String _cleanPlayerName(String raw) {
    var name = raw;
    name = name.replaceAll(RegExp(r'[⭐️⭐★☆🌟✨👑🔥🎌]'), '');
    name = name.trim();
    return name;
  }

  /// チーム名見出し候補か判定
  static bool _isPossibleTeamHeader(
    String line,
    List<String> lines,
    int index,
  ) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return false;
    if (_extractMember(trimmed) != null) return false;
    if (_isVenueLine(trimmed) || _isAddressLine(trimmed)) return false;
    if (TournamentDateParser.extractDate(trimmed) != null) return false;

    // 次の行にポジション行または個人戦選手行が続くかチェック
    for (
      int next = index + 1;
      next < lines.length && next <= index + 3;
      next++
    ) {
      final nextLine = lines[next].trim();
      if (nextLine.isEmpty) continue;
      if (_extractMember(nextLine) != null) return true;
      if (trimmed.contains('個人') &&
          _extractIndividualMember(nextLine) != null) {
        return true;
      }
      break;
    }

    const teamKeywords = [
      '低学年',
      '高学年',
      '小学生',
      '中学生',
      '高校生',
      '一般',
      '男子',
      '女子',
      'チーム',
      '部',
      '勝ち抜き',
      'リーグ',
      '個人戦',
      '個人',
    ];
    return teamKeywords.any((kw) => trimmed.contains(kw)) &&
        trimmed.length <= 20;
  }

  /// 単独のセクション見出しから試合形式を検出
  static String? _detectSectionMatchType(String line) {
    final c = _cleanTeamHeader(line);
    if (c == '個人戦' || c == '個人' || c == '個人戦の部' || c == '個人の部') {
      return '個人戦';
    }
    if (c == '勝ち抜き戦' || c == '勝ち抜き' || c == '勝ち抜き戦の部') {
      return '勝ち抜き戦';
    }
    if (c == 'リーグ個人戦') {
      return 'リーグ個人戦';
    }
    if (c == 'リーグ戦' || c == 'リーグ' || c == 'リーグ団体戦' || c == 'リーグの部') {
      return 'リーグ団体戦';
    }
    if (c == '団体戦' || c == '団体戦の部' || c == '団体の部') {
      return '団体戦（5人制）';
    }
    return null;
  }

  /// チーム名や全体テキストから初期の試合形式を検出
  static String _detectInitialMatchType({
    required String teamName,
    required String rawText,
    required int memberCount,
  }) {
    if (teamName.contains('勝ち抜き')) return '勝ち抜き戦';
    if (teamName.contains('リーグ')) {
      return (memberCount == 1 || teamName.contains('個人'))
          ? 'リーグ個人戦'
          : 'リーグ団体戦';
    }
    if (teamName.contains('個人戦') || teamName.contains('個人')) {
      return '個人戦';
    }
    if (rawText.contains('勝ち抜き戦') || rawText.contains('勝ち抜き')) {
      return '勝ち抜き戦';
    }
    if (rawText.contains('リーグ戦') || rawText.contains('リーグ')) {
      return (memberCount == 1 || rawText.contains('個人')) ? 'リーグ個人戦' : 'リーグ団体戦';
    }
    if (rawText.contains('個人戦') || rawText.contains('個人選手権')) {
      return '個人戦';
    }
    if (memberCount == 1) {
      return '個人戦';
    }
    return '';
  }

  /// チームヘッダーのクレンジング
  static String _cleanTeamHeader(String line) {
    return line
        .replaceAll(RegExp(r'^[【\[［◆■●]\s*'), '')
        .replaceAll(RegExp(r'\s*[】\]］]$'), '')
        .trim();
  }

  /// チーム名が見つからない場合のフォールバック探索
  static String? _findPreviousTeamName(List<String> lines, int memberIndex) {
    for (int i = memberIndex - 1; i >= 0; i--) {
      final l = lines[i].trim();
      if (l.isEmpty) continue;
      if (_extractMember(l) == null && !_isVenueLine(l) && !_isAddressLine(l)) {
        return _cleanTeamHeader(l);
      }
    }
    return null;
  }
}
