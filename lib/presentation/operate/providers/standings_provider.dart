import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'match_list_provider.dart';

// ★ クラス定義は「関数の外」に置くのが鉄則！
class MatchPointsSettings {
  final double winPoints;
  final double drawPoints;
  final double lossPoints;
  const MatchPointsSettings({this.winPoints = 1.0, this.drawPoints = 0.5, this.lossPoints = 0.0});
}

class MatchPointsSettingsNotifier extends Notifier<MatchPointsSettings> {
  @override
  MatchPointsSettings build() => const MatchPointsSettings();
  void updateSettings(MatchPointsSettings newSettings) => state = newSettings;
}

final matchPointsSettingsProvider = NotifierProvider<MatchPointsSettingsNotifier, MatchPointsSettings>(() {
  return MatchPointsSettingsNotifier();
});

class StandingData {
  final String name;
  int matchesPlayed = 0;
  int wins = 0;
  int losses = 0;
  int draws = 0;
  int pointsScored = 0;
  int pointsLost = 0;
  double matchPoints = 0.0; 
  StandingData(this.name);
}

final standingsProvider = Provider<List<StandingData>>((ref) {
  final matches = ref.watch(matchListProvider);
  final settings = ref.watch(matchPointsSettingsProvider);
  final Map<String, StandingData> standingsMap = {};

  final validMatches = matches.where((m) => 
    (m.status == 'finished' || m.status == 'approved') && m.countForStandings
  );

  // ... (中略：ループ処理のところ)
  for (var match in validMatches) {
    standingsMap.putIfAbsent(match.redName, () => StandingData(match.redName));
    standingsMap.putIfAbsent(match.whiteName, () => StandingData(match.whiteName));

    final redData = standingsMap[match.redName]!;
    final whiteData = standingsMap[match.whiteName]!;

    redData.matchesPlayed++;
    whiteData.matchesPlayed++;

    // ★ .toInt() を追加！
    redData.pointsScored = redData.pointsScored + (match.redScore as num).toInt();
    redData.pointsLost = redData.pointsLost + (match.whiteScore as num).toInt();
    whiteData.pointsScored = whiteData.pointsScored + (match.whiteScore as num).toInt();
    whiteData.pointsLost = whiteData.pointsLost + (match.redScore as num).toInt();

    if (match.redScore.toInt() > match.whiteScore.toInt()) {
      redData.wins++;
      whiteData.losses++;
    } else if (match.redScore.toInt() < match.whiteScore.toInt()) {
      whiteData.wins++;
      redData.losses++;
    } else {
      redData.draws++;
      whiteData.draws++;
    }
  }


  final standingsList = standingsMap.values.toList();
  for (var data in standingsList) {
    data.matchPoints = (data.wins.toDouble() * settings.winPoints) + 
                       (data.draws.toDouble() * settings.drawPoints) + 
                       (data.losses.toDouble() * settings.lossPoints);
  }

  standingsList.sort((a, b) {
    if (b.matchPoints != a.matchPoints) return b.matchPoints.compareTo(a.matchPoints);
    if (b.wins != a.wins) return b.wins.compareTo(a.wins);
    return b.pointsScored.compareTo(a.pointsScored);
  });

  return standingsList;
});