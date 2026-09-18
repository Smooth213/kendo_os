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
  ];

  /// 大会識別のキーワード
  static const List<String> _tournamentKeywords = [
    '剣道',
    '大会',
    '選手権',
    '錬成会',
    '杯',
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

  /// 日時識別のキーワード
  static const List<String> _dateKeywords = ['日時', '令和', '202', '平成'];

  /// 3重の安全フィルター: テキストが大会・オーダー情報の解析候補かを判定
  static bool isCandidate(String text) {
    final trimmed = text.trim();
    // フィルター②: 文字数制約（40文字以上）& 行数制約（3行以上）
    if (trimmed.length < 40) return false;
    final lines = trimmed
        .split(RegExp(r'\r?\n'))
        .where((l) => l.trim().isNotEmpty)
        .toList();
    if (lines.length < 3) return false;

    // フィルター① 条件A（即判定）: 剣道特有のポジションが含まれている
    final hasPosition = _positionKeywords.any((pos) => trimmed.contains(pos));
    if (hasPosition) return true;

    // フィルター① 条件B（大会イベント判定）: 3要素がすべて揃っていること
    final hasTournament = _tournamentKeywords.any(
      (keyword) => trimmed.contains(keyword),
    );
    final hasDate = _dateKeywords.any((keyword) => trimmed.contains(keyword));
    final hasVenue = _venueKeywords.any((keyword) => trimmed.contains(keyword));

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
    String? currentTeamName;
    List<ParsedTeamMember> currentTeamMembers = [];
    final List<String> candidateNames = [];

    // 行ごとに走査
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      // TimeTree等のフッターURLや共有メッセージを除外
      if (_isIgnoredFooter(line)) {
        continue;
      }

      // 1. 日時の検出
      final parsedDate = _extractDate(line);
      if (parsedDate != null && date == null) {
        date = parsedDate;
        continue;
      }

      // 2. 会場・場所の検出
      if (_isVenueLine(line)) {
        final extractedVenue = _cleanVenue(line);
        if (venue.isEmpty) {
          venue = extractedVenue;
        } else {
          venue = '$venue $extractedVenue';
        }
        continue;
      }

      // 3. 住所の検出
      if (_isAddressLine(line)) {
        final extractedAddress = _cleanAddress(line);
        if (address.isEmpty) {
          address = extractedAddress;
        }
        continue;
      }

      // 4. ポジション & 選手名の検出
      final member = _extractMember(line);
      if (member != null) {
        currentTeamName ??= _findPreviousTeamName(lines, i) ?? 'チーム';
        currentTeamMembers.add(member);
        continue;
      }

      // 5. チーム名見出しの検出判定
      if (_isPossibleTeamHeader(line, lines, i)) {
        // 前のチームがあれば保存
        if (currentTeamName != null && currentTeamMembers.isNotEmpty) {
          teams.add(
            ParsedTeamOrder(
              teamName: currentTeamName,
              members: List.from(currentTeamMembers),
            ),
          );
          currentTeamMembers.clear();
        }
        currentTeamName = _cleanTeamHeader(line);
        continue;
      }

      // 6. 大会名の候補抽出（ヘッダー部にある大会キーワード行）
      if (date == null &&
          venue.isEmpty &&
          teams.isEmpty &&
          _isTournamentNameCandidate(line)) {
        candidateNames.add(line);
        continue;
      }

      // それ以外はメモ候補
      // ただしチームブロック内の行でない場合
      if (currentTeamMembers.isEmpty) {
        noteLines.add(line);
      }
    }

    // 最後のチームを保存
    if (currentTeamName != null && currentTeamMembers.isNotEmpty) {
      teams.add(
        ParsedTeamOrder(
          teamName: currentTeamName,
          members: List.from(currentTeamMembers),
        ),
      );
    }

    // 大会名の決定: 最も具体的（長さが長く、第○回や選抜などの修飾があるもの優先）
    if (candidateNames.isNotEmpty) {
      candidateNames.sort((a, b) => b.length.compareTo(a.length));
      tournamentName = candidateNames.first;
    } else if (teams.isNotEmpty && (date != null || venue.isNotEmpty)) {
      // チームと日程/会場が存在し確実に大会テキストである場合のみ、先頭の有効行を大会名候補として推測
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

    // メモの整形
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

  /// 日時行のパース
  static DateTime? _extractDate(String line) {
    final normalized = _normalizeNumbers(line);

    // 和暦: 令和X年 / 平成X年
    final reiwaMatch = RegExp(
      r'令和\s*([0-9]+|元)\s*年\s*([0-9]{1,2})\s*月\s*([0-9]{1,2})\s*日',
    ).firstMatch(normalized);
    if (reiwaMatch != null) {
      final yearStr = reiwaMatch.group(1)!;
      final int year = yearStr == '元' ? 2019 : 2018 + int.parse(yearStr);
      final month = int.parse(reiwaMatch.group(2)!);
      final day = int.parse(reiwaMatch.group(3)!);
      return DateTime(year, month, day);
    }

    final heiseiMatch = RegExp(
      r'平成\s*([0-9]+|元)\s*年\s*([0-9]{1,2})\s*月\s*([0-9]{1,2})\s*日',
    ).firstMatch(normalized);
    if (heiseiMatch != null) {
      final yearStr = heiseiMatch.group(1)!;
      final int year = yearStr == '元' ? 1989 : 1988 + int.parse(yearStr);
      final month = int.parse(heiseiMatch.group(2)!);
      final day = int.parse(heiseiMatch.group(3)!);
      return DateTime(year, month, day);
    }

    // 西暦: 202X年X月X日
    final seirekiMatch = RegExp(
      r'(20[2-3][0-9])\s*年\s*([0-9]{1,2})\s*月\s*([0-9]{1,2})\s*日',
    ).firstMatch(normalized);
    if (seirekiMatch != null) {
      final year = int.parse(seirekiMatch.group(1)!);
      final month = int.parse(seirekiMatch.group(2)!);
      final day = int.parse(seirekiMatch.group(3)!);
      return DateTime(year, month, day);
    }

    // スラッシュ/ハイフン形式: 2026/09/20, 2026-9-20
    final slashMatch = RegExp(
      r'(20[2-3][0-9])[\/\-\.]([0-9]{1,2})[\/\-\.]([0-9]{1,2})',
    ).firstMatch(normalized);
    if (slashMatch != null) {
      final year = int.parse(slashMatch.group(1)!);
      final month = int.parse(slashMatch.group(2)!);
      final day = int.parse(slashMatch.group(3)!);
      return DateTime(year, month, day);
    }

    return null;
  }

  /// 会場・場所行か判定
  static bool _isVenueLine(String line) {
    final lower = line.replaceAll(' ', '').replaceAll('　', '');
    return lower.startsWith('場所:') ||
        lower.startsWith('場所：') ||
        lower.startsWith('会場:') ||
        lower.startsWith('会場：') ||
        lower.startsWith('試合会場:') ||
        lower.startsWith('試合会場：') ||
        lower.startsWith('【大会会場】') ||
        lower.startsWith('【会場】');
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
    final lower = line.replaceAll(' ', '').replaceAll('　', '');
    return lower.startsWith('住所:') ||
        lower.startsWith('住所：') ||
        lower.startsWith('所在地:') ||
        lower.startsWith('所在地：') ||
        line.startsWith('〒') ||
        RegExp(r'^(東京都|北海道|(?:京都|大阪)府|.{2,3}県)').hasMatch(line);
  }

  /// 住所文字列のクレンジング
  static String _cleanAddress(String line) {
    return line.replaceFirst(RegExp(r'^(?:住所|所在地)[　\s:：]+'), '').trim();
  }

  /// ポジション & 選手名の抽出
  static ParsedTeamMember? _extractMember(String line) {
    // 例: "先鋒　皿田 脩人", "中堅 : 塚本 大道", "大将　久安 智也⭐️"
    final pattern = RegExp(r'^(先鋒|次鋒|五将|中堅|三将|副将|大将|補欠|補)[　\s:：]+(.+)$');
    final match = pattern.firstMatch(line.trim());
    if (match != null) {
      final position = match.group(1)!;
      final rawName = match.group(2)!;
      final cleanName = _cleanPlayerName(rawName);
      if (cleanName.isNotEmpty) {
        return ParsedTeamMember(position: position, name: cleanName);
      }
    }
    return null;
  }

  /// 選手名から星印や絵文字、不要な記号をクレンジング
  static String _cleanPlayerName(String raw) {
    var name = raw;
    // 絵文字や記号を削除（⭐️, ⭐, ★, ☆, 🌟, ✨, 👑, etc.）
    name = name.replaceAll(RegExp(r'[⭐️⭐★☆🌟✨👑🔥🎌]'), '');
    // 全角英数記号の正規化
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
    // ポジション行、日時、会場、住所はチーム名ではない
    if (_extractMember(trimmed) != null) return false;
    if (_isVenueLine(trimmed) || _isAddressLine(trimmed)) return false;
    if (_extractDate(trimmed) != null) return false;

    // 次の行（あるいは2行以内）にポジション行が続くかチェック
    for (
      int next = index + 1;
      next < lines.length && next <= index + 3;
      next++
    ) {
      final nextLine = lines[next].trim();
      if (nextLine.isEmpty) continue;
      if (_extractMember(nextLine) != null) {
        // 次にポジション行が来るなら、この行はチーム名ヘッダーの可能性が極めて高い
        return true;
      }
      break;
    }

    // 代表的なチーム・カテゴリ名パターン
    final teamKeywords = [
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
    ];
    if (teamKeywords.any((kw) => trimmed.contains(kw)) &&
        trimmed.length <= 15) {
      return true;
    }

    return false;
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

  /// 全角数字を半角数字に正規化
  static String _normalizeNumbers(String input) {
    const fullWidth = '０１２３４５６７８９';
    const halfWidth = '0123456789';
    var result = input;
    for (int i = 0; i < fullWidth.length; i++) {
      result = result.replaceAll(fullWidth[i], halfWidth[i]);
    }
    return result;
  }
}
