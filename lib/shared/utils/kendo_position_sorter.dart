import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/application/projections/match_projection.dart';

/// 剣道における団体戦ポジションの標準順序付け・ソートユーティリティ
class KendoPositionSorter {
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
    // 多人数制ポジション
    if (t.contains('十将')) return 21;
    if (t.contains('九将')) return 22;
    if (t.contains('八将')) return 23;
    if (t.contains('七将')) return 24;
    if (t.contains('六将')) return 25;
    if (t.contains('五将')) return 26;
    if (t.contains('四将')) return 27;

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
    // 三将 (35)
    if (t.contains('三将')) return 35;

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

    return 999;
  }

  /// 試合情報の各フィールドから総合優先度を算出
  static int resolveMatchPriority({
    required String matchType,
    String? note,
    String? redName,
    String? whiteName,
  }) {
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
    list.sort((a, b) {
      final pA = resolveMatchPriority(
        matchType: a.matchType,
        note: a.note,
        redName: a.redName,
        whiteName: a.whiteName,
      );
      final pB = resolveMatchPriority(
        matchType: b.matchType,
        note: b.note,
        redName: b.redName,
        whiteName: b.whiteName,
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
    list.sort((a, b) {
      final pA = resolveMatchPriority(
        matchType: a.matchType,
        note: a.note,
        redName: a.redName,
        whiteName: a.whiteName,
      );
      final pB = resolveMatchPriority(
        matchType: b.matchType,
        note: b.note,
        redName: b.redName,
        whiteName: b.whiteName,
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
    list.sort((a, b) {
      final pA = resolveMatchPriority(
        matchType: a.matchType,
        note: a.note,
        redName: a.redName,
        whiteName: a.whiteName,
      );
      final pB = resolveMatchPriority(
        matchType: b.matchType,
        note: b.note,
        redName: b.redName,
        whiteName: b.whiteName,
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
