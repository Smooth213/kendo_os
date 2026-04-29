import '../models/match_model.dart';

class BunaiksenHelper {
  // 1. 名前分割ロジック
  static Map<String, String> parseName(String raw) {
    if (raw.contains('欠員')) {
      return {'last': '', 'first': ''};
    }
    String clean = raw.contains(':') ? raw.split(':').last.replaceAll(RegExp(r'[()（）]'), '').trim() : raw.trim();
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
  static String generateDescriptiveLeagueTitle(List<MatchModel> matches, List<String> ownTeams) {
    final participantsSet = <String>{};
    for (var m in matches) {
      participantsSet.add(m.redName.split(':').first.trim());
      participantsSet.add(m.whiteName.split(':').first.trim());
    }
    final int n = participantsSet.length;
    final int mCount = n * (n - 1) ~/ 2;
    final bool isIndiv = matches.any((m) => m.matchType == 'individual' || m.matchType == '選手' || m.matchType.contains('個人戦'));

    String selfInfo = "";
    if (isIndiv) {
      final myMatch = matches.firstWhere((m) => ownTeams.any((ot) => m.redName.contains(ot) || m.whiteName.contains(ot)), orElse: () => matches.first);
      final isRedOwn = ownTeams.any((ot) => myMatch.redName.contains(ot));
      final rawName = isRedOwn ? myMatch.redName : myMatch.whiteName;
      final team = rawName.split(':').first.trim();
      final name = rawName.contains(':') ? rawName.split(':').last.replaceAll(RegExp(r'[()（）]'), '').trim() : rawName;
      selfInfo = "$name（$team）";
    } else {
      selfInfo = participantsSet.firstWhere((p) => ownTeams.contains(p), orElse: () => participantsSet.first);
    }

    final suffix = isIndiv ? "$n人リーグ" : "$nチームリーグ";
    return "$selfInfo : $suffix（全$mCount試合）";
  }

  // 5. リーグ戦の独自勝ち点計算ロジック（勝=3, 分=1, 負=0）
  static int calculateCustomLeaguePoints(String rowTeam, List<String> teamList, List<MatchModel> normalMatches) {
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
      
      if (bouts.isEmpty || !bouts.every((m) => m.status == 'approved' || m.status == 'finished')) {
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
}