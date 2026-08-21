import 'package:kendo_os/shared/application/projections/match_projection.dart';

class PlayerSpan {
  final String rawName;
  final String lastName;
  final String initial;
  final int startIndex;
  int endIndex;

  PlayerSpan(
    this.rawName,
    this.lastName,
    this.initial,
    this.startIndex,
    this.endIndex,
  );
}

/// 勝ち抜き戦の選手スパン・名前解析ビルダー
class KachinukiSpanBuilder {
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

  static ({
    List<PlayerSpan> redSpans,
    List<PlayerSpan> whiteSpans,
    int totalCols,
  })
  buildSpans(List<MatchProjection> matches) {
    List<String> rAllRaw = matches.map((m) => m.redName).toList()
      ..addAll(matches.last.redRemaining);
    List<String> wAllRaw = matches.map((m) => m.whiteName).toList()
      ..addAll(matches.last.whiteRemaining);

    List<String> rLasts = rAllRaw
        .map((n) => parseName(n)['last']!)
        .where((s) => s.isNotEmpty)
        .toList();
    List<String> wLasts = wAllRaw
        .map((n) => parseName(n)['last']!)
        .where((s) => s.isNotEmpty)
        .toList();

    List<PlayerSpan> redSpans = [];
    List<PlayerSpan> whiteSpans = [];
    String currentRed = "", currentWhite = "";

    for (int i = 0; i < matches.length; i++) {
      final rRaw = matches[i].redName;
      final wRaw = matches[i].whiteName;
      final rP = parseName(rRaw);
      final rShow =
          rLasts.where((n) => n == rP['last']).length > 1 &&
          rP['first']!.isNotEmpty;
      if (rRaw != currentRed) {
        redSpans.add(
          PlayerSpan(
            rRaw,
            rP['last']!,
            rShow ? rP['first']!.substring(0, 1) : '',
            i,
            i,
          ),
        );
        currentRed = rRaw;
      } else {
        redSpans.last.endIndex = i;
      }

      final wP = parseName(wRaw);
      final wShow =
          wLasts.where((n) => n == wP['last']).length > 1 &&
          wP['first']!.isNotEmpty;
      if (wRaw != currentWhite) {
        whiteSpans.add(
          PlayerSpan(
            wRaw,
            wP['last']!,
            wShow ? wP['first']!.substring(0, 1) : '',
            i,
            i,
          ),
        );
        currentWhite = wRaw;
      } else {
        whiteSpans.last.endIndex = i;
      }
    }

    int currentRedIdx = matches.length;
    for (String name in matches.last.redRemaining) {
      final p = parseName(name);
      final show =
          rLasts.where((n) => n == p['last']).length > 1 &&
          p['first']!.isNotEmpty;
      redSpans.add(
        PlayerSpan(
          name,
          p['last']!,
          show ? p['first']!.substring(0, 1) : '',
          currentRedIdx,
          currentRedIdx,
        ),
      );
      currentRedIdx++;
    }

    int currentWhiteIdx = matches.length;
    for (String name in matches.last.whiteRemaining) {
      final p = parseName(name);
      final show =
          wLasts.where((n) => n == p['last']).length > 1 &&
          p['first']!.isNotEmpty;
      whiteSpans.add(
        PlayerSpan(
          name,
          p['last']!,
          show ? p['first']!.substring(0, 1) : '',
          currentWhiteIdx,
          currentWhiteIdx,
        ),
      );
      currentWhiteIdx++;
    }

    int totalCols = currentRedIdx > currentWhiteIdx
        ? currentRedIdx
        : currentWhiteIdx;

    return (redSpans: redSpans, whiteSpans: whiteSpans, totalCols: totalCols);
  }
}
