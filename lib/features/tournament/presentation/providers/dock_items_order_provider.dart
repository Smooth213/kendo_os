import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🥋 ドックに配置可能な全9機能の識別Enum
enum DockItemType {
  program,
  matchStatus,
  officialRecord,
  quickMemo,
  timer,
  viewerQr,
  announcements,
  manual,
  settings,
}

/// 🥋 各ドックアイテムのメタデータ定義
extension DockItemTypeExtension on DockItemType {
  String get id => name;

  String get label {
    switch (this) {
      case DockItemType.program:
        return 'プログラム';
      case DockItemType.matchStatus:
        return '試合状況';
      case DockItemType.officialRecord:
        return '対戦表';
      case DockItemType.quickMemo:
        return 'クイックメモ';
      case DockItemType.timer:
        return 'タイマー';
      case DockItemType.viewerQr:
        return '観戦QR';
      case DockItemType.announcements:
        return 'お知らせ';
      case DockItemType.manual:
        return 'ヘルプ';
      case DockItemType.settings:
        return '設定';
    }
  }

  IconData get icon {
    switch (this) {
      case DockItemType.program:
        return Icons.menu_book_rounded;
      case DockItemType.matchStatus:
        return Icons.groups_rounded;
      case DockItemType.officialRecord:
        return Icons.scoreboard_rounded;
      case DockItemType.quickMemo:
        return Icons.brush_rounded;
      case DockItemType.timer:
        return Icons.timer_rounded;
      case DockItemType.viewerQr:
        return Icons.qr_code_2_rounded;
      case DockItemType.announcements:
        return Icons.notifications_rounded;
      case DockItemType.manual:
        return Icons.help_outline_rounded;
      case DockItemType.settings:
        return Icons.settings_rounded;
    }
  }

  Color get defaultColor {
    switch (this) {
      case DockItemType.program:
        return AppKendoColors.indigo;
      case DockItemType.matchStatus:
        return AppKendoColors.indigo;
      case DockItemType.officialRecord:
        return AppKendoColors.ipponGold;
      case DockItemType.quickMemo:
        return AppKendoColors.pink;
      case DockItemType.timer:
        return AppKendoColors.orangeAccent;
      case DockItemType.viewerQr:
        return AppKendoColors.teal;
      case DockItemType.announcements:
        return AppKendoColors.deepOrange;
      case DockItemType.manual:
        return AppKendoColors.teal;
      case DockItemType.settings:
        return AppKendoColors.grey;
    }
  }

  static DockItemType fromId(String id) {
    return DockItemType.values.firstWhere(
      (e) => e.name == id,
      orElse: () => DockItemType.program,
    );
  }
}

/// 🥋 ドックアイテムの並び順とGoogleクラウド同期を統括するNotifier
class DockItemsOrderNotifier extends StateNotifier<List<DockItemType>> {
  final SharedPreferences? _prefs;
  static const _key = 'kendo_os_dock_items_order';

  static const List<DockItemType> defaultOrder = [
    DockItemType.program,
    DockItemType.matchStatus,
    DockItemType.officialRecord,
    DockItemType.quickMemo,
    DockItemType.timer,
    DockItemType.viewerQr,
    DockItemType.announcements,
    DockItemType.manual,
    DockItemType.settings,
  ];

  DockItemsOrderNotifier(this._prefs) : super(_loadInitialOrder(_prefs)) {
    _syncFromCloud();
  }

  static List<DockItemType> _loadInitialOrder(SharedPreferences? prefs) {
    if (prefs == null) {
      return List.from(defaultOrder);
    }
    final saved = prefs.getStringList(_key);
    if (saved == null || saved.isEmpty) {
      return List.from(defaultOrder);
    }
    // 保存済みリストから復元（新機能が追加された場合のフォールバック含む）
    final restored = <DockItemType>[];
    for (final id in saved) {
      try {
        final item = DockItemType.values.firstWhere((e) => e.name == id);
        if (!restored.contains(item)) {
          restored.add(item);
        }
      } catch (_) {}
    }
    // 漏れているデフォルト項目を末尾に追加
    for (final def in defaultOrder) {
      if (!restored.contains(def)) {
        restored.add(def);
      }
    }
    return restored;
  }

  String? get _linkedUid {
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

  /// クラウドから並び順を取得して同期
  Future<void> _syncFromCloud() async {
    final uid = _linkedUid;
    if (uid == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('dock_items_order')
          .get();

      if (doc.exists && doc.data() != null) {
        final cloudList = List<String>.from(
          doc.data()!['order'] as List? ?? [],
        );
        if (cloudList.isNotEmpty) {
          final cloudOrder = <DockItemType>[];
          for (final id in cloudList) {
            try {
              final item = DockItemType.values.firstWhere((e) => e.name == id);
              if (!cloudOrder.contains(item)) {
                cloudOrder.add(item);
              }
            } catch (_) {}
          }
          for (final def in defaultOrder) {
            if (!cloudOrder.contains(def)) {
              cloudOrder.add(def);
            }
          }
          state = cloudOrder;
          await _prefs?.setStringList(
            _key,
            cloudOrder.map((e) => e.name).toList(),
          );
        }
      }
    } catch (e) {
      debugPrint('ℹ️ [DockOrder] Cloud sync skipped: $e');
    }
  }

  /// ドラッグ＆ドロップによる並び替え（onReorderItem 準拠）
  Future<void> reorder(int oldIndex, int newIndex) async {
    final updated = List<DockItemType>.from(state);
    if (oldIndex < 0 || oldIndex >= updated.length) return;
    if (newIndex < 0 || newIndex >= updated.length) return;

    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);

    state = updated;
    await _save(updated);
  }

  /// 並び順を一括更新して保存
  Future<void> updateOrder(List<DockItemType> newOrder) async {
    state = List.from(newOrder);
    await _save(newOrder);
  }

  /// 初期並び順へリセット
  Future<void> resetToDefault() async {
    state = List.from(defaultOrder);
    await _save(defaultOrder);
  }

  Future<void> _save(List<DockItemType> order) async {
    final idList = order.map((e) => e.name).toList();
    await _prefs?.setStringList(_key, idList);

    // Google連携中ならクラウドへ非同期反映
    final uid = _linkedUid;
    if (uid != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('dock_items_order')
          .set({
            'order': idList,
            'updatedAt': DateTime.now().toIso8601String(),
          }, SetOptions(merge: true))
          .catchError((e) {
            debugPrint('⚠️ [DockOrder] Cloud sync error: $e');
          });
    }
  }
}

/// 🥋 ドックアイテム並び順のプロバイダー
final dockItemsOrderProvider =
    StateNotifierProvider<DockItemsOrderNotifier, List<DockItemType>>((ref) {
      SharedPreferences? prefs;
      try {
        prefs = ref.watch(sharedPreferencesProvider);
      } catch (_) {
        prefs = null;
      }
      return DockItemsOrderNotifier(prefs);
    });
