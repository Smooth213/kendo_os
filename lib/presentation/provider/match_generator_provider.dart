import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/match_model.dart';
import 'match_list_provider.dart';
import 'match_command_provider.dart';

// ★ Phase 3: 試合の大量生成（リーグ・団体）専門のプロバイダ
final matchGeneratorProvider = Provider<MatchGenerator>((ref) {
  return MatchGenerator(ref);
});

class MatchGenerator {
  final Ref ref;
  MatchGenerator(this.ref);

  FirebaseFirestore get _firestore => ref.read(firestoreProvider);
  MatchCommand get _command => ref.read(matchCommandProvider);

  // リーグ戦生成
  Future<void> generateLeagueMatches(String category, List<String> participants, bool countForStandings, [String? note]) async {
    int order = 1;
    for (int i = 0; i < participants.length; i++) {
      for (int j = i + 1; j < participants.length; j++) {
        final docRef = _firestore.collection('matches').doc();
        final newMatch = MatchModel(
          id: docRef.id, matchType: 'リーグ戦', category: category,
          redName: participants[i], whiteName: participants[j],
          countForStandings: countForStandings, source: 'auto_league',
          order: (order++).toDouble(), note: note ?? '',
        );
        await _command.saveMatch(newMatch);
      }
    }
  }

  // 団体戦生成
  Future<void> generateTeamMatchBouts(
    String redTeamName, List<String> redMembers, 
    String whiteTeamName, List<String> whiteMembers, 
    bool countForStandings, {String? category, String? note}
  ) async {
    final groupName = '$redTeamName vs $whiteTeamName';
    int maxLength = redMembers.length > whiteMembers.length ? redMembers.length : whiteMembers.length;
    final positions = ['先鋒', '次鋒', '中堅', '副将', '大将']; 
    for (int i = 0; i < maxLength; i++) {
      final docRef = _firestore.collection('matches').doc();
      final newMatch = MatchModel(
        id: docRef.id,
        matchType: i < positions.length ? positions[i] : '${i + 1}将',
        groupName: groupName, category: category,
        redName: '$redTeamName:${i < redMembers.length ? redMembers[i] : '欠員'}',
        whiteName: '$whiteTeamName:${i < whiteMembers.length ? whiteMembers[i] : '欠員'}',
        countForStandings: countForStandings, source: 'auto_team',
        matchOrder: i + 1, order: (i + 1).toDouble(), note: note ?? '',
      );
      await _command.saveMatch(newMatch);
    }
  }

  // ★ Step 5-3: トーナメント形式のプレースホルダー試合を生成するヘルパー（例：準決勝）
  Future<void> generateLinkedMatch({
    required String tournamentId,
    required String category,
    required String redFromMatchId,
    required String whiteFromMatchId,
    required double order,
  }) async {
    final docRef = _firestore.collection('matches').doc();
    final newMatch = MatchModel(
      id: docRef.id,
      tournamentId: tournamentId,
      category: category,
      matchType: 'トーナメント',
      redName: '[[Winner:$redFromMatchId]]', // ★ 勝者を待つ予約名
      whiteName: '[[Winner:$whiteFromMatchId]]',
      source: 'auto_tournament',
      order: order,
    );
    await _command.saveMatch(newMatch);
  }
}