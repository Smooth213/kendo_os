import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/team_name_history_provider.dart';
import 'package:kendo_os/features/tournament/presentation/providers/dock_timer_provider.dart';
import 'package:kendo_os/shared/domain/entities/settings_model.dart';
import 'package:kendo_os/shared/presentation/providers/dojo_room_history_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';

/// 🥋 Googleアカウント データ自動同期統括マネージャー
class UserDataCloudSyncManager {
  final Ref _ref;
  final FirebaseFirestore? _injectedFirestore;
  final FirebaseAuth? _injectedAuth;
  final String? _overrideUid;
  StreamSubscription<User?>? _authSubscription;
  bool _isSyncing = false;

  UserDataCloudSyncManager(
    this._ref, {
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    String? overrideUid,
  }) : _injectedFirestore = firestore,
       _injectedAuth = auth,
       _overrideUid = overrideUid;

  FirebaseFirestore get _firestore {
    final injected = _injectedFirestore;
    if (injected != null) return injected;
    return FirebaseFirestore.instance;
  }

  FirebaseAuth? get _auth {
    if (_injectedAuth != null) return _injectedAuth;
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  /// Google連携済みユーザーのUID（未連携または未ログインならnull）
  String? get linkedUid {
    if (_overrideUid != null) return _overrideUid;
    try {
      final user = _auth?.currentUser;
      if (user == null) return null;
      final isGoogle = user.providerData.any(
        (p) => p.providerId == 'google.com',
      );
      return isGoogle ? user.uid : null;
    } catch (_) {
      return null;
    }
  }

  /// 認証状態の監視を開始し、Googleアカウント連携時に自動同期を発火
  void initialize() {
    _authSubscription?.cancel();
    final auth = _auth;
    if (auth == null) return;

    _authSubscription = auth.userChanges().listen((user) {
      if (user != null &&
          user.providerData.any((p) => p.providerId == 'google.com')) {
        debugPrint('☁️ [CloudSyncManager] Googleアカウント検知 ➔ 全データ同期を実行');
        syncAll();
      }
    });

    // 起動時すでに連携済みであれば同期
    if (linkedUid != null) {
      syncAll();
    }
  }

  void dispose() {
    _authSubscription?.cancel();
  }

  /// 4大データ（個人設定、道場履歴、入力履歴、タイマー設定）の一括同期
  Future<void> syncAll() async {
    final uid = linkedUid;
    if (uid == null || _isSyncing) return;

    _isSyncing = true;
    try {
      await Future.wait([
        syncPreferencesFromCloud(uid),
        syncDojoHistoryFromCloud(uid),
        syncInputHistoryFromCloud(uid),
        syncTimerPreferencesFromCloud(uid),
      ]);
      debugPrint('✅ [CloudSyncManager] 全4大データのクラウド同期が完了しました');
    } catch (e) {
      debugPrint('⚠️ [CloudSyncManager] syncAll エラー (ローカル優先で継続): $e');
    } finally {
      _isSyncing = false;
    }
  }

  // ===========================================================================
  // 1. 個人環境設定 (SettingsModel)
  // ===========================================================================
  DocumentReference<Map<String, dynamic>> _prefDoc(String uid) => _firestore
      .collection('users')
      .doc(uid)
      .collection('settings')
      .doc('preferences');

  Future<void> syncPreferencesFromCloud(String uid) async {
    try {
      final doc = await _prefDoc(uid).get();
      if (!doc.exists || doc.data() == null) {
        // クラウドに未保存の場合は現在のローカル設定をアップロード
        final current = _ref.read(settingsProvider);
        await pushPreferencesToCloud(current);
        return;
      }

      final cloudData = doc.data()!;
      final cloudSettings = SettingsModel.fromJson(cloudData);
      // ローカルへ反映
      await _ref
          .read(settingsProvider.notifier)
          .applyCloudSettings(cloudSettings);
    } catch (e) {
      debugPrint('⚠️ [CloudSyncManager] syncPreferences エラー: $e');
    }
  }

  Future<void> pushPreferencesToCloud(SettingsModel settings) async {
    final uid = linkedUid;
    if (uid == null || _isSyncing) return;

    try {
      final data = settings.toJson();
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _prefDoc(uid).set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('⚠️ [CloudSyncManager] pushPreferences エラー: $e');
    }
  }

  // ===========================================================================
  // 2. 道場・大会ルーム参加履歴 (DojoRoomHistory)
  // ===========================================================================
  DocumentReference<Map<String, dynamic>> _dojoDoc(String uid) => _firestore
      .collection('users')
      .doc(uid)
      .collection('settings')
      .doc('dojo_history');

  Future<void> syncDojoHistoryFromCloud(String uid) async {
    try {
      final doc = await _dojoDoc(uid).get();
      final cloudList = List<String>.from(
        doc.data()?['history'] as List? ?? [],
      );
      if (cloudList.isEmpty) {
        final current = _ref.read(dojoRoomHistoryProvider);
        if (current.isNotEmpty) {
          await pushDojoHistoryToCloud(current);
        }
        return;
      }

      // ローカルとクラウドをスマートマージ（重複排除）
      await _ref
          .read(dojoRoomHistoryProvider.notifier)
          .mergeCloudHistory(cloudList);
      final merged = _ref.read(dojoRoomHistoryProvider);
      await pushDojoHistoryToCloud(merged);
    } catch (e) {
      debugPrint('⚠️ [CloudSyncManager] syncDojoHistory エラー: $e');
    }
  }

  Future<void> pushDojoHistoryToCloud(List<String> history) async {
    final uid = linkedUid;
    if (uid == null || _isSyncing) return;

    try {
      await _dojoDoc(uid).set({
        'history': history,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('⚠️ [CloudSyncManager] pushDojoHistory エラー: $e');
    }
  }

  // ===========================================================================
  // 3. チーム名・選手名 入力履歴 (TeamNameHistory)
  // ===========================================================================
  DocumentReference<Map<String, dynamic>> _inputDoc(String uid) => _firestore
      .collection('users')
      .doc(uid)
      .collection('settings')
      .doc('input_history');

  Future<void> syncInputHistoryFromCloud(String uid) async {
    try {
      final doc = await _inputDoc(uid).get();
      final cloudList = List<String>.from(
        doc.data()?['teamNames'] as List? ?? [],
      );
      if (cloudList.isEmpty) {
        final current = _ref.read(teamNameHistoryProvider);
        if (current.isNotEmpty) {
          await pushInputHistoryToCloud(current);
        }
        return;
      }

      await _ref
          .read(teamNameHistoryProvider.notifier)
          .mergeCloudTeamNames(cloudList);
      final merged = _ref.read(teamNameHistoryProvider);
      await pushInputHistoryToCloud(merged);
    } catch (e) {
      debugPrint('⚠️ [CloudSyncManager] syncInputHistory エラー: $e');
    }
  }

  Future<void> pushInputHistoryToCloud(List<String> names) async {
    final uid = linkedUid;
    if (uid == null || _isSyncing) return;

    try {
      await _inputDoc(uid).set({
        'teamNames': names,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('⚠️ [CloudSyncManager] pushInputHistory エラー: $e');
    }
  }

  // ===========================================================================
  // 4. 独立型タイマー設定 (DockTimerPreferences)
  // ===========================================================================
  DocumentReference<Map<String, dynamic>> _timerDoc(String uid) => _firestore
      .collection('users')
      .doc(uid)
      .collection('settings')
      .doc('timer_preferences');

  Future<void> syncTimerPreferencesFromCloud(String uid) async {
    try {
      final doc = await _timerDoc(uid).get();
      final seconds = doc.data()?['initialSeconds'] as int?;
      if (seconds != null && seconds > 0) {
        _ref.read(dockTimerProvider.notifier).restoreInitialSeconds(seconds);
      }
    } catch (e) {
      debugPrint('⚠️ [CloudSyncManager] syncTimerPreferences エラー: $e');
    }
  }

  Future<void> pushTimerPreferencesToCloud(int initialSeconds) async {
    final uid = linkedUid;
    if (uid == null || _isSyncing) return;

    try {
      await _timerDoc(uid).set({
        'initialSeconds': initialSeconds,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('⚠️ [CloudSyncManager] pushTimerPreferences エラー: $e');
    }
  }
}

/// 🥋 UserDataCloudSyncManager Provider
final userDataCloudSyncManagerProvider = Provider<UserDataCloudSyncManager>((
  ref,
) {
  final manager = UserDataCloudSyncManager(ref);
  ref.onDispose(manager.dispose);
  return manager;
});
