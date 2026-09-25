import 'tournament_date_parser.dart';
import 'tournament_share_data.dart';

/// 大会・オーダー情報テキスト解析の行分類・クレンジング・抽出ヘルパー
class TournamentTextParserHelper {
  /// ポジションの判定用キーワード
  static const List<String> positionKeywords = [
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
  static const List<String> tournamentKeywords = [
    '剣道',
    '大会',
    '選手権',
    '錬成会',
    '杯',
    '個人戦',
    '個人',
  ];

  /// 会場識別のキーワード
  static const List<String> venueKeywords = [
    '会場',
    '場所',
    '体育館',
    '武道場',
    '武道館',
    'アリーナ',
  ];

  /// TimeTreeやLINEのフッター、URLを無視対象とする
  static bool isIgnoredFooter(String line) {
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
  static bool isTournamentNameCandidate(String line) {
    if (line.length > 60) return false;
    return tournamentKeywords.any((kw) => line.contains(kw));
  }

  /// 会場・場所行か判定
  static bool isVenueLine(String line) {
    final lower = line.replaceAll(RegExp(r'[ 　]'), '');
    return RegExp(r'^(?:場所|会場|試合会場)[：:]|^【(?:大会会場|会場|試合会場)】').hasMatch(lower);
  }

  /// 会場文字列のクレンジング
  static String cleanVenue(String line) {
    return line
        .replaceFirst(RegExp(r'^(?:場所|会場|試合会場|開催場所)[　\s:：]+'), '')
        .replaceFirst(RegExp(r'^【(?:大会会場|会場|試合会場)】[　\s]*'), '')
        .trim();
  }

  /// 住所行か判定
  static bool isAddressLine(String line) {
    final lower = line.replaceAll(RegExp(r'[ 　]'), '');
    return RegExp(
      r'^(?:住所|所在地)[：:]|^〒|^(?:東京都|北海道|(?:京都|大阪)府|.{2,3}県)',
    ).hasMatch(lower);
  }

  /// 住所文字列のクレンジング
  static String cleanAddress(String line) {
    return line.replaceFirst(RegExp(r'^(?:住所|所在地)[　\s:：]+'), '').trim();
  }

  /// ポジション & 選手名の抽出
  static ParsedTeamMember? extractMember(String line) {
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
      final cleanName = cleanPlayerName(rawName);
      if (cleanName.isNotEmpty) {
        return ParsedTeamMember(position: position, name: cleanName);
      }
    }
    return null;
  }

  /// 個人戦ヘッダー配下の選手名（ポジション接頭辞なし、番号/箇条書き付き等）を抽出
  static ParsedTeamMember? extractIndividualMember(String line) {
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
    if (isIgnoredFooter(trimmed) ||
        isVenueLine(trimmed) ||
        isAddressLine(trimmed)) {
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
    final cleanName = cleanPlayerName(trimmed);
    if (cleanName.length >= 2 &&
        cleanName.length <= 12 &&
        !cleanName.contains(':') &&
        !cleanName.contains('：')) {
      return ParsedTeamMember(position: '選手', name: cleanName);
    }
    return null;
  }

  /// 選手名から星印や絵文字、不要な記号をクレンジング
  static String cleanPlayerName(String raw) {
    var name = raw;
    name = name.replaceAll(RegExp(r'[⭐️⭐★☆🌟✨👑🔥🎌]'), '');
    name = name.trim();
    return name;
  }

  /// チーム名見出し候補か判定
  static bool isPossibleTeamHeader(String line, List<String> lines, int index) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return false;
    if (extractMember(trimmed) != null) return false;
    if (isVenueLine(trimmed) || isAddressLine(trimmed)) return false;
    if (TournamentDateParser.extractDate(trimmed) != null) return false;

    // 次の行にポジション行または個人戦選手行が続くかチェック
    for (
      int next = index + 1;
      next < lines.length && next <= index + 3;
      next++
    ) {
      final nextLine = lines[next].trim();
      if (nextLine.isEmpty) continue;
      if (extractMember(nextLine) != null) return true;
      if (trimmed.contains('個人') && extractIndividualMember(nextLine) != null) {
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
  static String? detectSectionMatchType(String line) {
    final c = cleanTeamHeader(line);
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
  static String detectInitialMatchType({
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
  static String cleanTeamHeader(String line) {
    return line
        .replaceAll(RegExp(r'^[【\[［◆■●]\s*'), '')
        .replaceAll(RegExp(r'\s*[】\]］]$'), '')
        .trim();
  }

  /// チーム名が見つからない場合のフォールバック探索
  static String? findPreviousTeamName(List<String> lines, int memberIndex) {
    for (int i = memberIndex - 1; i >= 0; i--) {
      final l = lines[i].trim();
      if (l.isEmpty) continue;
      if (extractMember(l) == null && !isVenueLine(l) && !isAddressLine(l)) {
        return cleanTeamHeader(l);
      }
    }
    return null;
  }
}
