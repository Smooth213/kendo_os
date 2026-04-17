import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/league_standing.dart';

// ★ 同上：団体戦の集計機能も一時的に空のリストを返してエラーを封じます。
final teamStandingsProvider = Provider<List<LeagueStanding>>((ref) {
  return [];
});