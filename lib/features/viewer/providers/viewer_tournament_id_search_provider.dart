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

    final dojoId = ref.read(currentDojoIdProvider);
    final firestore = FirebaseFirestore.instance;

    // 1. dojoId配下のtournamentsを優先して直接走査（O(1)〜小件数のため圧倒的に高速・インデックス不要）
    if (dojoId.isNotEmpty) {
      try {
        final tournamentsSnap = await firestore
            .collection('organizations')
            .doc(dojoId)
            .collection('tournaments')
            .limit(10)
            .get();

        for (final tDoc in tournamentsSnap.docs) {
          final mSnap = await tDoc.reference
              .collection('matches')
              .where('groupName', isEqualTo: groupName)
              .limit(1)
              .get();
          if (mSnap.docs.isNotEmpty) {
            return tDoc.id;
          }
        }
        // もし大会が1つしか存在しないなら、その大会IDを採用
        if (tournamentsSnap.docs.length == 1) {
          return tournamentsSnap.docs.first.id;
        }
      } catch (e) {
        debugPrint('🚨 [Organization Tournaments Scan Error] $e');
      }
    }

    // 2. フォールバック: collectionGroup('matches') での検索（組織跨ぎ・パラメータ完全欠落時のみ）
    try {
      final groupSnap = await firestore
          .collectionGroup('matches')
          .where('groupName', isEqualTo: groupName)
          .limit(1)
          .get();
      if (groupSnap.docs.isNotEmpty) {
        final tId = groupSnap.docs.first.data()['tournamentId'] as String?;
        if (tId != null && tId.isNotEmpty) return tId;
        final pathSegments = groupSnap.docs.first.reference.path.split('/');
        final tIndex = pathSegments.indexOf('tournaments');
        if (tIndex != -1 && tIndex + 1 < pathSegments.length) {
          return pathSegments[tIndex + 1];
        }
      }

      final idSnap = await firestore
          .collectionGroup('matches')
          .where('id', isEqualTo: groupName)
          .limit(1)
          .get();
      if (idSnap.docs.isNotEmpty) {
        final tId = idSnap.docs.first.data()['tournamentId'] as String?;
        if (tId != null && tId.isNotEmpty) return tId;
        final pathSegments = idSnap.docs.first.reference.path.split('/');
        final tIndex = pathSegments.indexOf('tournaments');
        if (tIndex != -1 && tIndex + 1 < pathSegments.length) {
          return pathSegments[tIndex + 1];
        }
      }
    } catch (e) {
      debugPrint('🚨 [collectionGroup matches Error] $e');
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
