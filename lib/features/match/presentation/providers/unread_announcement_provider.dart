import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/presentation/components/announce_history_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';

/// 🥋 大会の未読アナウンス件数をリアルタイム監視するプロバイダー
final unreadAnnouncementCountProvider =
    StreamProvider.family<int, ({String tournamentId, bool isStaffRoom})>((
      ref,
      arg,
    ) {
      if (arg.tournamentId.isEmpty) return Stream.value(0);

      FirebaseFirestore? firestore;
      try {
        firestore = ref.watch(firestoreProvider);
      } catch (_) {
        try {
          firestore = FirebaseFirestore.instance;
        } catch (_) {
          firestore = null;
        }
      }

      if (firestore == null) return Stream.value(0);

      Query query = firestore
          .collection('announcements')
          .where('tournamentId', isEqualTo: arg.tournamentId);

      if (!arg.isStaffRoom) {
        query = query.where('target', isEqualTo: 'all');
      }

      final readIds = ref.watch(readAnnouncementsProvider);

      return query
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .where((doc) => !readIds.contains(doc.id))
                .length;
          })
          .handleError((_) => 0);
    });
