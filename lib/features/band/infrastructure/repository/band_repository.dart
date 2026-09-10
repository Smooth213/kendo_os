import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kendo_os/features/band/domain/entities/band_group_model.dart';

/// 🥋 BANDグループ設定のFirestore永続化＆リアルタイム同期リポジトリ
class BandRepository {
  final FirebaseFirestore _firestore;
  final String _dojoId;
  static const String _localPrefKey = 'kendo_os_band_groups_cache';

  BandRepository(this._firestore, this._dojoId);

  DocumentReference<Map<String, dynamic>> get _configDoc {
    final dojo = _dojoId.isNotEmpty ? _dojoId : 'default_org';
    return _firestore
        .collection('organizations')
        .doc(dojo)
        .collection('settings')
        .doc('band_config');
  }

  /// 登録済みBANDグループをリアルタイム監視するストリーム
  Stream<List<BandGroupModel>> watchBandGroups() {
    return _configDoc
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists || snapshot.data() == null) {
            return <BandGroupModel>[];
          }
          final data = snapshot.data()!;
          final rawList = data['groups'] as List<dynamic>? ?? [];
          final groups =
              rawList
                  .map(
                    (item) => BandGroupModel.fromJson(
                      Map<String, dynamic>.from(item as Map),
                    ),
                  )
                  .toList()
                ..sort((a, b) => a.order.compareTo(b.order));

          // ローカルキャッシュにも非同期で保存
          _saveToLocalCache(groups);

          return groups;
        })
        .handleError((error) {
          debugPrint('⚠️ [BandRepository] watchBandGroups エラー: $error');
          return <BandGroupModel>[];
        });
  }

  /// 現在のBANDグループ一覧を1回取得（キャッシュ優先フォールバック付き）
  Future<List<BandGroupModel>> getBandGroups() async {
    try {
      final snapshot = await _configDoc.get();
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        final rawList = data['groups'] as List<dynamic>? ?? [];
        final groups =
            rawList
                .map(
                  (item) => BandGroupModel.fromJson(
                    Map<String, dynamic>.from(item as Map),
                  ),
                )
                .toList()
              ..sort((a, b) => a.order.compareTo(b.order));
        await _saveToLocalCache(groups);
        return groups;
      }
    } catch (e) {
      debugPrint(
        '⚠️ [BandRepository] getBandGroups Firestore取得失敗、キャッシュを確認: $e',
      );
    }
    return _loadFromLocalCache();
  }

  /// グループの追加または更新
  Future<void> saveBandGroup(BandGroupModel group) async {
    try {
      final currentGroups = await getBandGroups();
      final index = currentGroups.indexWhere((g) => g.id == group.id);

      final updatedList = List<BandGroupModel>.from(currentGroups);
      if (index >= 0) {
        updatedList[index] = group;
      } else {
        // 新規追加：IDが無ければ生成
        final targetGroup = group.id.isEmpty
            ? group.copyWith(
                id: 'band_${DateTime.now().millisecondsSinceEpoch}',
                order: currentGroups.length,
                createdAt: DateTime.now(),
              )
            : group;
        updatedList.add(targetGroup);
      }

      await _configDoc.set({
        'groups': updatedList.map((g) => g.toJson()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _saveToLocalCache(updatedList);
    } catch (e) {
      debugPrint('❌ [BandRepository] saveBandGroup 保存失敗: $e');
      rethrow;
    }
  }

  /// グループの削除
  Future<void> deleteBandGroup(String groupId) async {
    try {
      final currentGroups = await getBandGroups();
      final updatedList = currentGroups.where((g) => g.id != groupId).toList();

      await _configDoc.set({
        'groups': updatedList.map((g) => g.toJson()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _saveToLocalCache(updatedList);
    } catch (e) {
      debugPrint('❌ [BandRepository] deleteBandGroup 削除失敗: $e');
      rethrow;
    }
  }

  /// 一括保存（並び替え等）
  Future<void> saveAllGroups(List<BandGroupModel> groups) async {
    try {
      await _configDoc.set({
        'groups': groups.map((g) => g.toJson()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await _saveToLocalCache(groups);
    } catch (e) {
      debugPrint('❌ [BandRepository] saveAllGroups 保存失敗: $e');
      rethrow;
    }
  }

  // --- ローカルキャッシュヘルパー ---

  Future<void> _saveToLocalCache(List<BandGroupModel> groups) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = groups.map((g) => g.toJson()).toList();
      await prefs.setString(_localPrefKey, jsonEncode(jsonList));
    } catch (_) {}
  }

  Future<List<BandGroupModel>> _loadFromLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_localPrefKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final decoded = jsonDecode(jsonString) as List<dynamic>;
        return decoded
            .map(
              (item) => BandGroupModel.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList();
      }
    } catch (_) {}
    return <BandGroupModel>[];
  }
}
