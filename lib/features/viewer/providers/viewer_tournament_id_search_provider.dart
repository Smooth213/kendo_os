import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';

/// Web環境やディープリンクでgroupNameからtournamentIdを検索・解決するプロバイダ
final webTournamentIdSearchProvider = FutureProvider.family<String?, String>((
  ref,
  groupName,
) async {
  try {
    final localMatches = ref.read(matchListProvider);
    final match = localMatches
        .where((m) => m.groupName == groupName || m.id == groupName)
        .firstOrNull;
    if (match != null) {
      return match.tournamentId;
    }

    final firestore = FirebaseFirestore.instance;
    try {
      var rootGroupSnap = await firestore
          .collection('matches')
          .where('groupName', isEqualTo: groupName)
          .limit(1)
          .get();
      if (rootGroupSnap.docs.isNotEmpty) {
        return rootGroupSnap.docs.first.data()['tournamentId'] as String?;
      }

      var rootIdSnap = await firestore
          .collection('matches')
          .doc(groupName)
          .get();
      if (rootIdSnap.exists) {
        return rootIdSnap.data()?['tournamentId'] as String?;
      }
    } catch (e) {
      debugPrint('🚨 [Root Matches Query Error] $e');
    }

    final dojoId = ref.read(currentDojoIdProvider);
    if (dojoId.isNotEmpty) {
      var snapshot = await firestore
          .collection('organizations')
          .doc(dojoId)
          .collection('matches')
          .where('groupName', isEqualTo: groupName)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        final docSnapshot = await firestore
            .collection('organizations')
            .doc(dojoId)
            .collection('matches')
            .doc(groupName)
            .get();
        if (docSnapshot.exists) {
          return docSnapshot.data()?['tournamentId'] as String?;
        }
      }

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data()['tournamentId'] as String?;
      }
    }

    final fallbackMatches = ref.read(matchListProvider);
    if (fallbackMatches.isNotEmpty) {
      return fallbackMatches.first.tournamentId;
    }

    return 'default_tournament';
  } catch (e) {
    debugPrint('🚨 [_webTournamentIdSearchProvider Error] $e');
    return 'default_tournament';
  }
});
