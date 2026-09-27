import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_setup_helper.dart';
import 'package:kendo_os/shared/application/projections/match_projection.dart';

/// 剣道における団体戦ポジションの標準順序付け・ソートユーティリティ
class KendoPositionSorter {
  /// 漢数字（一〜九十九）またはアラビア数字の文字列を整数に変換
  static int? parseKanjiOrArabicNumber(String text) {
    final direct = int.tryParse(text);
    if (direct != null) return direct;

    const kanjiDigits = {
      '〇': 0,
      '一': 1,
      '二': 2,
      '三': 3,
      '四': 4,
      '五': 5,
      '六': 6,
      '七': 7,
      '八': 8,
      '九': 9,
    };

    if (text == '十') return 10;
    if (text.startsWith('十')) {
      final unit = text.substring(1);
      final digit = kanjiDigits[unit];
      if (digit != null) return 10 + digit;
    }
    if (text.contains('十')) {
      final parts = text.split('十');
      final tens = kanjiDigits[parts[0]] ?? 1;
      final ones = parts[1].isEmpty ? 0 : (kanjiDigits[parts[1]] ?? 0);
      return tens * 10 + ones;
    }
    return kanjiDigits[text];
  }

  /// ポジション名から優先度を取得（小さいほど前）
  static int getPositionPriority(String? text) {
    if (text == null || text.trim().isEmpty) return 999;
    final t = text.trim();

    // 先鋒 (10)
    if (t.contains('先鋒') || t.contains('センポウ') || t.contains('先')) {
      // 「先生」などに誤マッチしないようチェック
      if (t == '先' ||
          t.contains('先鋒') ||
          t.contains('センポウ') ||
          t.contains('【先】') ||
          t.contains('(先)') ||
          t.contains('（先）')) {
        return 10;
      }
    }
    // 次鋒 (20)
    if (t.contains('次鋒') || t.contains('ジホウ') || t.contains('次')) {
      if (t == '次' ||
          t.contains('次鋒') ||
          t.contains('ジホウ') ||
          t.contains('【次】') ||
          t.contains('(次)') ||
          t.contains('（次）')) {
        return 20;
      }
    }

    // 中堅 (30)
    if (t.contains('中堅') || t.contains('チュウケン') || t.contains('中')) {
      if (t == '中' ||
          t.contains('中堅') ||
          t.contains('チュウケン') ||
          t.contains('【中】') ||
          t.contains('(中)') ||
          t.contains('（中）')) {
        return 30;
      }
    }

    // 副将 (40)
    if (t.contains('副将') || t.contains('フクショウ') || t.contains('副')) {
      if (t == '副' ||
          t.contains('副将') ||
          t.contains('フクショウ') ||
          t.contains('【副】') ||
          t.contains('(副)') ||
          t.contains('（副）')) {
        return 40;
      }
    }

    // 大将 (50)
    if (t.contains('大将') || t.contains('タイショウ') || t.contains('大')) {
      if (t == '大' ||
          t.contains('大将') ||
          t.contains('タイショウ') ||
          t.contains('【大】') ||
          t.contains('(大)') ||
          t.contains('（大）')) {
        return 50;
      }
    }

    // 代表戦 / 代表 (100)
    if (t.contains('代表戦') ||
        t.contains('代表') ||
        t.contains('代決定') ||
        t == '代' ||
        t.contains('【代】')) {
      return 100;
    }

    // 順位決定戦 (110)
    if (t.contains('順位決定戦') || t.contains('順位戦') || t.contains('順位')) {
      return 110;
    }

    // 追加試合 (120)
    if (t.contains('追加') || t.contains('おかわり') || t.contains('お代わり')) {
      return 120;
    }

    // 多人数制ポジション（漢数字・アラビア数字に対応）
    final shoMatch = RegExp(r'([一二三四五六七八九十\d]+)将').firstMatch(t);
    if (shoMatch != null) {
      final k = parseKanjiOrArabicNumber(shoMatch.group(1)!);
      if (k != null) {
        if (k == 3) return 35;
        if (k == 4) return 27;
        if (k == 5) return 26;
        if (k == 6) return 25;
        if (k == 7) return 24;
        if (k == 8) return 23;
        if (k == 9) return 22;
        if (k == 10) return 21;
        if (k > 10) return 21 - (k - 10);
      }
    }

    return 999;
  }

  /// テキストから剣道ポジション名を抽出
  static String? extractPositionName(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    final t = text.trim();
    if (t.contains('先鋒') || t == '先') return '先鋒';
    if (t.contains('次鋒') || t == '次') return '次鋒';
    if (t.contains('中堅') || t == '中') return '中堅';
    if (t.contains('副将') || t == '副') return '副将';
    if (t.contains('大将') || t == '大') return '大将';
    if (t.contains('代表戦') || t.contains('代表')) return '代表戦';

    final shoMatch = RegExp(r'([一二三四五六七八九十\d]+)将').firstMatch(t);
    if (shoMatch != null) {
      final k = parseKanjiOrArabicNumber(shoMatch.group(1)!);
      if (k != null) {
        return '${MatchFormatSetupHelper.toKanjiNumber(k)}将';
      }
    }
    return null;
  }

  /// リスト内に出現するポジション群からチームサイズを推定し、ポジション優先度マップを構築
  static Map<String, int>? _buildDynamicPositionOrder(
    Iterable<String> rawTexts,
  ) {
    int maxSho = 0;
    for (final text in rawTexts) {
      final shoMatch = RegExp(r'([一二三四五六七八九十\d]+)将').firstMatch(text);
      if (shoMatch != null) {
        final k = parseKanjiOrArabicNumber(shoMatch.group(1)!);
        if (k != null && k > maxSho) {
          maxSho = k;
        }
      }
    }

    // 4将以上が出現する多人数戦の場合、動的ポジションリストを生成
    if (maxSho >= 4) {
      final teamSize = maxSho + 2;
      final standardPositions = MatchFormatSetupHelper.generatePositions(
        teamSize,
      );
      final map = <String, int>{};
      for (int i = 0; i < standardPositions.length; i++) {
        map[standardPositions[i]] = 10 + i;
      }
      return map;
    }
    return null;
  }

  /// 試合情報の各フィールドから総合優先度を算出
  static int resolveMatchPriority({
    required String matchType,
    String? note,
    String? redName,
    String? whiteName,
    Map<String, int>? dynamicMap,
  }) {
    if (dynamicMap != null) {
      for (final text in [matchType, note, redName, whiteName]) {
        final pos = extractPositionName(text);
        if (pos != null && dynamicMap.containsKey(pos)) {
          return dynamicMap[pos]!;
        }
      }
    }

    int p = getPositionPriority(matchType);
    if (p != 999) return p;

    if (note != null && note.isNotEmpty) {
      p = getPositionPriority(note);
      if (p != 999) return p;
    }

    if (redName != null && redName.isNotEmpty) {
      p = getPositionPriority(redName);
      if (p != 999) return p;
    }

    if (whiteName != null && whiteName.isNotEmpty) {
      p = getPositionPriority(whiteName);
      if (p != 999) return p;
    }

    return 999;
  }

  /// MatchModel のリストを剣道の標準順序でソート
  static List<MatchModel> sortMatches(List<MatchModel> matches) {
    final list = List<MatchModel>.from(matches);
    final dynamicMap = _buildDynamicPositionOrder(
      matches.expand((m) => [m.matchType, m.note, m.redName, m.whiteName]),
    );

    list.sort((a, b) {
      final pA = resolveMatchPriority(
        matchType: a.matchType,
        note: a.note,
        redName: a.redName,
        whiteName: a.whiteName,
        dynamicMap: dynamicMap,
      );
      final pB = resolveMatchPriority(
        matchType: b.matchType,
        note: b.note,
        redName: b.redName,
        whiteName: b.whiteName,
        dynamicMap: dynamicMap,
      );

      // 1. ポジション優先度が明確に異なる場合
      if (pA != pB && (pA != 999 || pB != 999)) {
        return pA.compareTo(pB);
      }

      // 2. order (double) の比較
      final orderComp = a.order.compareTo(b.order);
      if (orderComp != 0) return orderComp;

      // 3. matchOrder (int) の比較
      final moA = a.matchOrder ?? 0;
      final moB = b.matchOrder ?? 0;
      final moComp = moA.compareTo(moB);
      if (moComp != 0) return moComp;

      // 4. id で安定化
      return a.id.compareTo(b.id);
    });
    return list;
  }

  /// MatchListProjection のリストを剣道の標準順序でソート
  static List<MatchListProjection> sortProjections(
    List<MatchListProjection> projections,
  ) {
    final list = List<MatchListProjection>.from(projections);
    final dynamicMap = _buildDynamicPositionOrder(
      projections.expand((p) => [p.matchType, p.note, p.redName, p.whiteName]),
    );

    list.sort((a, b) {
      final pA = resolveMatchPriority(
        matchType: a.matchType,
        note: a.note,
        redName: a.redName,
        whiteName: a.whiteName,
        dynamicMap: dynamicMap,
      );
      final pB = resolveMatchPriority(
        matchType: b.matchType,
        note: b.note,
        redName: b.redName,
        whiteName: b.whiteName,
        dynamicMap: dynamicMap,
      );

      // 1. ポジション優先度
      if (pA != pB && (pA != 999 || pB != 999)) {
        return pA.compareTo(pB);
      }

      // 2. matchOrder (int) の比較
      final moComp = a.matchOrder.compareTo(b.matchOrder);
      if (moComp != 0) return moComp;

      // 3. id で安定化
      return a.id.compareTo(b.id);
    });
    return list;
  }

  /// MatchProjection（詳細版）のリストを剣道の標準順序でソート
  static List<MatchProjection> sortDetailedProjections(
    List<MatchProjection> projections,
  ) {
    final list = List<MatchProjection>.from(projections);
    final dynamicMap = _buildDynamicPositionOrder(
      projections.expand((p) => [p.matchType, p.note, p.redName, p.whiteName]),
    );

    list.sort((a, b) {
      final pA = resolveMatchPriority(
        matchType: a.matchType,
        note: a.note,
        redName: a.redName,
        whiteName: a.whiteName,
        dynamicMap: dynamicMap,
      );
      final pB = resolveMatchPriority(
        matchType: b.matchType,
        note: b.note,
        redName: b.redName,
        whiteName: b.whiteName,
        dynamicMap: dynamicMap,
      );

      // 1. ポジション優先度
      if (pA != pB && (pA != 999 || pB != 999)) {
        return pA.compareTo(pB);
      }

      // 2. matchOrder (int) の比較
      final moComp = a.matchOrder.compareTo(b.matchOrder);
      if (moComp != 0) return moComp;

      // 3. id で安定化
      return a.id.compareTo(b.id);
    });
    return list;
  }
}
