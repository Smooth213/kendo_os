import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🌟 既読にしたアナウンスIDのローカル＆クラウド状態を管理・永続化するプロバイダー
final readAnnouncementsProvider =
    StateNotifierProvider<ReadAnnouncementsNotifier, List<String>>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return ReadAnnouncementsNotifier(prefs);
    });

class ReadAnnouncementsNotifier extends StateNotifier<List<String>> {
  final SharedPreferences _prefs;
  static const _key = 'kendo_os_read_announcements';
  static const int maxReadCount = 200;

  List<String> _trimIds(List<String> ids) {
    if (ids.length > maxReadCount) {
      return ids.sublist(ids.length - maxReadCount);
    }
    return ids;
  }

  ReadAnnouncementsNotifier(this._prefs)
    : super(_prefs.getStringList(_key) ?? []) {
    syncFromCloud();
  }

  @visibleForTesting
  static FirebaseFirestore? testFirestore;
  @visibleForTesting
  static String? testOverrideUid;

  FirebaseFirestore get _firestore =>
      testFirestore ?? FirebaseFirestore.instance;

  String? get _linkedUid {
    if (testOverrideUid != null) return testOverrideUid;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      final isGoogle = user.providerData.any(
        (p) => p.providerId == 'google.com',
      );
      return isGoogle ? user.uid : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> syncFromCloud() async {
    final uid = _linkedUid;
    if (uid == null) return;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('read_announcements')
          .get();

      if (doc.exists && doc.data() != null) {
        final cloudIds = List<String>.from(
          doc.data()!['readIds'] as List? ?? [],
        );
        if (cloudIds.isNotEmpty) {
          final merged = Set<String>.from(state)..addAll(cloudIds);
          final trimmed = _trimIds(merged.toList());
          state = trimmed;
          await _prefs.setStringList(_key, trimmed);
        }
      }
    } catch (e) {
      debugPrint('⚠️ [ReadAnnouncementsNotifier] cloud sync error: $e');
    }
  }

  Future<void> markAsRead(String id) async {
    if (!state.contains(id)) {
      final updated = _trimIds([...state, id]);
      state = updated;
      await _prefs.setStringList(_key, updated);
      _syncToCloud([id]);
    }
  }

  Future<void> markAllAsRead(List<String> ids) async {
    final List<String> updated = List.from(state);
    final List<String> newlyAdded = [];
    for (final id in ids) {
      if (!updated.contains(id)) {
        updated.add(id);
        newlyAdded.add(id);
      }
    }
    if (newlyAdded.isNotEmpty) {
      final trimmed = _trimIds(updated);
      state = trimmed;
      await _prefs.setStringList(_key, trimmed);
      _syncToCloud(newlyAdded);
    }
  }

  void _syncToCloud(List<String> newIds) {
    final uid = _linkedUid;
    if (uid == null || newIds.isEmpty) return;

    _firestore
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('read_announcements')
        .set({
          'readIds': FieldValue.arrayUnion(newIds),
          'updatedAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true))
        .catchError((e) {
          debugPrint('⚠️ [ReadAnnouncementsNotifier] sync to cloud error: $e');
        });
  }
}
