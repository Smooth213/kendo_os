import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/application/projections/match_projection.dart';

class BunaiksenHelper {
  // 1. 名前分割ロジック
  static Map<String, String> parseName(String raw) {
    if (raw.contains('欠員')) {
      return {'last': '', 'first': ''};
    }
    String clean = raw.contains(':')
        ? raw.split(':').last.replaceAll(RegExp(r'[()（）]'), '').trim()
        : raw.trim();
    var parts = clean.split(RegExp(r'\s+'));
    return {'last': parts[0], 'first': parts.length > 1 ? parts[1] : ''};
  }

  // 2. 試合イベントから表示用の技マーク（メ、コ、㋱など）を抽出するロジック
  static List<String> extractMarks(List<dynamic>? events, bool isRed) {
    if (events == null) {
      return [];
    }
    List<String> res = [];
    bool isFirst = true;
    for (var e in events) {
      String s = e.toString().toLowerCase();
      if (s.contains('iscanceled: true') || s.contains('undo')) {
        continue;
      }
      bool eventIsRed = s.contains('red') || s.contains('赤');

      String mark = '';
      if (s.contains('men') || s.contains('メ')) {
        mark = 'メ';
      } else if (s.contains('kote') || s.contains('コ')) {
        mark = 'コ';
      } else if (s.contains('do') || s.contains('ド')) {
        mark = 'ド';
      } else if (s.contains('tsuki') || s.contains('ツ')) {
        mark = 'ツ';
      } else if (s.contains('hansoku') || s.contains('反')) {
        mark = '反';
      }

      if (mark.isNotEmpty) {
        if (isFirst) {
          if (mark == 'メ') {
            mark = '㋱';
          } else if (mark == 'コ') {
            mark = '㋙';
          } else if (mark == 'ド') {
            mark = '㋣';
          } else if (mark == 'ツ') {
            mark = '㋡';
          }
        }
        if (eventIsRed == isRed) {
          res.add(mark);
        }
        isFirst = false;
      }
    }
    return res;
  }

  // 3. ログから技（メ・コ・ド・ツ・反）を抽出するロジック（リーグ戦星取表用）
  static List<String> extractTechs(List<dynamic> logs, bool isRed, int count) {
    List<String> res = [];
    bool isFirst = true;
    for (var log in logs) {
      String s = log.toString().toLowerCase();
      if (s.contains('undo') || s.contains('iscanceled: true')) {
        continue;
      }
      bool isRedPoint = s.contains('red') || s.contains('赤');

      String mark = '';
      if (s.contains('men') || s.contains('メ')) {
        mark = 'メ';
      } else if (s.contains('kote') || s.contains('コ')) {
        mark = 'コ';
      } else if (s.contains('do') || s.contains('ド')) {
        mark = 'ド';
      } else if (s.contains('tsuki') || s.contains('ツ')) {
        mark = 'ツ';
      } else if (s.contains('hansoku') || s.contains('反')) {
        mark = '反';
      }

      if (mark.isNotEmpty) {
        if (isFirst) {
          if (mark == 'メ') {
            mark = '㋱';
          } else if (mark == 'コ') {
            mark = '㋙';
          } else if (mark == 'ド') {
            mark = '㋣';
          } else if (mark == 'ツ') {
            mark = '㋡';
          }
        }
        if (isRed == isRedPoint) {
          res.add(mark);
        }
        isFirst = false;
      }
    }
    while (res.length < count) {
      res.add('◯');
    }
    return res.take(count).toList();
  }

  // 4. リーグ戦用のタイトル生成ロジック
  static String generateDescriptiveLeagueTitle(
    List<MatchModel> matches,
    List<String> ownTeams,
  ) {
    final participantsSet = <String>{};
    for (var m in matches) {
      participantsSet.add(m.redName.split(':').first.trim());
      participantsSet.add(m.whiteName.split(':').first.trim());
    }
    final int n = participantsSet.length;
    final int mCount = n * (n - 1) ~/ 2;
    final bool isIndiv = matches.any(
      (m) =>
          m.matchType == 'individual' ||
          m.matchType == '選手' ||
          m.matchType.contains('個人戦'),
    );

    String selfInfo = "";
    if (isIndiv) {
      final myMatch = matches.firstWhere(
        (m) => ownTeams.any(
          (ot) => m.redName.contains(ot) || m.whiteName.contains(ot),
        ),
        orElse: () => matches.first,
      );
      final isRedOwn = ownTeams.any((ot) => myMatch.redName.contains(ot));
      final rawName = isRedOwn ? myMatch.redName : myMatch.whiteName;
      final team = rawName.split(':').first.trim();
      final name = rawName.contains(':')
          ? rawName.split(':').last.replaceAll(RegExp(r'[()（）]'), '').trim()
          : rawName;
      selfInfo = "$name（$team）";
    } else {
      selfInfo = participantsSet.firstWhere(
        (p) => ownTeams.contains(p),
        orElse: () => participantsSet.first,
      );
    }

    final suffix = isIndiv ? "$n人リーグ" : "$nチームリーグ";
    return "$selfInfo : $suffix（全$mCount試合）";
  }

  // 4-2. リーグ戦用のタイトル生成ロジック (Projection用)
  static String generateDescriptiveLeagueTitleFromProjections(
    List<MatchProjection> matches,
    List<String> ownTeams,
  ) {
    final participantsSet = <String>{};
    for (var m in matches) {
      participantsSet.add(m.redName.split(':').first.trim());
      participantsSet.add(m.whiteName.split(':').first.trim());
    }
    final int n = participantsSet.length;
    final int mCount = n * (n - 1) ~/ 2;
    final bool isIndiv = matches.any(
      (m) =>
          m.matchType == 'individual' ||
          m.matchType == '選手' ||
          m.matchType.contains('個人戦'),
    );

    String selfInfo = "";
    if (isIndiv) {
      final myMatch = matches.firstWhere(
        (m) => ownTeams.any(
          (ot) => m.redName.contains(ot) || m.whiteName.contains(ot),
        ),
        orElse: () => matches.first,
      );
      final isRedOwn = ownTeams.any((ot) => myMatch.redName.contains(ot));
      final rawName = isRedOwn ? myMatch.redName : myMatch.whiteName;
      final team = rawName.split(':').first.trim();
      final name = rawName.contains(':')
          ? rawName.split(':').last.replaceAll(RegExp(r'[()（）]'), '').trim()
          : rawName;
      selfInfo = "$name（$team）";
    } else {
      selfInfo = participantsSet.firstWhere(
        (p) => ownTeams.contains(p),
        orElse: () => participantsSet.first,
      );
    }

    final suffix = isIndiv ? "$n人リーグ" : "$nチームリーグ";
    return "$selfInfo : $suffix（全$mCount試合）";
  }

  // 5. リーグ戦の独自勝ち点計算ロジック（勝=3, 分=1, 負=0）
  static int calculateCustomLeaguePoints(
    String rowTeam,
    List<String> teamList,
    List<MatchModel> normalMatches,
  ) {
    int customTeamPoints = 0;
    for (var colTeam in teamList) {
      if (rowTeam == colTeam) {
        continue;
      }
      final bouts = normalMatches.where((m) {
        final r = m.redName.split(':').first.trim();
        final w = m.whiteName.split(':').first.trim();
        return (r == rowTeam && w == colTeam) || (r == colTeam && w == rowTeam);
      }).toList();

      if (bouts.isEmpty ||
          !bouts.every(
            (m) => m.status == 'approved' || m.status == 'finished',
          )) {
        continue;
      }

      int rWins = 0, cWins = 0;
      for (var m in bouts) {
        final isRowRed = m.redName.split(':').first.trim() == rowTeam;
        final rs = (m.redScore as num).toInt();
        final ws = (m.whiteScore as num).toInt();
        if (rs > ws) {
          if (isRowRed) {
            rWins++;
          } else {
            cWins++;
          }
        } else if (ws > rs) {
          if (isRowRed) {
            cWins++;
          } else {
            rWins++;
          }
        }
      }

      if (rWins > cWins) {
        customTeamPoints += 3;
      } else if (rWins == cWins) {
        customTeamPoints += 1;
      }
    }
    return customTeamPoints;
  }

  // 6. リーグ戦判定ロジック（単一試合・複数試合対応）
  static bool isLeagueMatch(dynamic m) {
    if (m == null) return false;

    // 1. 試合形式（matchType）が明確にリーグ戦である場合
    try {
      final String mt = m.matchType?.toString().trim() ?? '';
      if (mt == 'リーグ戦' ||
          mt == 'league' ||
          mt == 'リーグ団体戦' ||
          mt == 'リーグ個人戦' ||
          mt.startsWith('リーグ団体戦') ||
          mt.startsWith('リーグ個人戦')) {
        return true;
      }
    } catch (_) {}

    // 2. システムが付与する明示的な [リーグ戦] タグ、または [league] タグのみ許可
    // ※ メモやラウンド名中の単なる「Bリーグ」等の文字列は除外する
    try {
      final String note = m.note?.toString() ?? '';
      if (note.contains('[リーグ戦]') ||
          note.contains('【リーグ戦】') ||
          note.contains('[league]')) {
        return true;
      }
    } catch (_) {}

    // 3. 試合ルールで明示的にリーグ戦が有効化されている場合
    // ※ ただし、試合形式が通常の団体戦・個人戦・勝ち抜き戦・トーナメント・または団体戦の各ポジション（先鋒、次鋒等）である場合は
    // 「試合形式でリーグ戦を選んでいない」ため除外する
    try {
      if (m.rule != null) {
        if (m.rule.isLeague == true || m.rule.matchFormat == 'league') {
          final String mt = m.matchType?.toString().trim() ?? '';
          final bool isStandardMatch =
              mt.contains('団体戦') ||
              mt.contains('勝ち抜き') ||
              mt.contains('トーナメント') ||
              mt.contains('個人戦') ||
              mt == '先鋒' ||
              mt == '次鋒' ||
              mt == '中堅' ||
              mt == '副将' ||
              mt == '大将' ||
              mt == '代表戦' ||
              mt.endsWith('将');
          if (!isStandardMatch) {
            return true;
          }
        }
      }
    } catch (_) {}

    return false;
  }

  static bool isLeagueMatches(List<dynamic> matches) {
    if (matches.isEmpty) return false;

    // どの試合もリーグ戦判定を満たさない場合は false
    if (!matches.any(isLeagueMatch)) return false;

    // 団体戦であるかどうかの判定（ポジション名や「団体」を含む）
    final bool isTeamMatch = matches.any((m) {
      final mt = m.matchType?.toString().trim() ?? '';
      return mt.contains('団体') ||
          mt.contains('勝ち抜き') ||
          mt == '先鋒' ||
          mt == '次鋒' ||
          mt == '中堅' ||
          mt == '副将' ||
          mt == '大将' ||
          mt == '代表戦' ||
          mt.endsWith('将');
    });

    // 団体戦の場合、参加チームが2チーム以下で単一の対抗戦しかないときは、
    // 星取表ではなく通常の団体戦スコア詳細カード（オーダー表）として表示する
    // （明示的な [リーグ戦] タグや matchType == 'リーグ団体戦' の場合を除く）
    if (isTeamMatch) {
      final participants = <String>{};
      for (var m in matches) {
        final r = m.redName?.toString().split(':').first.trim() ?? '';
        final w = m.whiteName?.toString().split(':').first.trim() ?? '';
        if (r.isNotEmpty) participants.add(r);
        if (w.isNotEmpty) participants.add(w);
      }
      if (participants.length <= 2) {
        final hasExplicitLeague = matches.any((m) {
          final note = m.note?.toString() ?? '';
          final mt = m.matchType?.toString() ?? '';
          return note.contains('[リーグ戦]') ||
              note.contains('【リーグ戦】') ||
              note.contains('[league]') ||
              mt == 'リーグ団体戦';
        });
        if (!hasExplicitLeague) {
          return false;
        }
      }
    }

    return true;
  }
}
