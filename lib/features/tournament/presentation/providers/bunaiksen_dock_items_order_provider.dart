import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';

/// 🥋 部内戦ドックに配置可能な全6機能の識別Enum
enum BunaiksenDockItemType {
  matches, // 対戦ホーム一覧（次試合・全カード確認）
  standings, // 部内戦成績一覧（星取表・連勝リーダーボード）
  calendar, // カレンダー（稽古日切替・過去アーカイブ）
  quickMemo, // クイックメモ（手書き・テキスト）
  timer, // ドックタイマー
  settings, // 設定
}

/// 🥋 部内戦ドックアイテムのメタデータ定義
extension BunaiksenDockItemTypeExtension on BunaiksenDockItemType {
  String get id => name;

  String get label {
    switch (this) {
      case BunaiksenDockItemType.matches:
        return '対戦一覧';
      case BunaiksenDockItemType.standings:
        return '成績・星取表';
      case BunaiksenDockItemType.calendar:
        return 'カレンダー';
      case BunaiksenDockItemType.quickMemo:
        return 'クイックメモ';
      case BunaiksenDockItemType.timer:
        return 'タイマー';
      case BunaiksenDockItemType.settings:
        return '設定';
    }
  }

  IconData get icon {
    switch (this) {
      case BunaiksenDockItemType.matches:
        return Icons.format_list_bulleted_rounded;
      case BunaiksenDockItemType.standings:
        return Icons.leaderboard_rounded;
      case BunaiksenDockItemType.calendar:
        return Icons.calendar_month_rounded;
      case BunaiksenDockItemType.quickMemo:
        return Icons.brush_rounded;
      case BunaiksenDockItemType.timer:
        return Icons.timer_outlined;
      case BunaiksenDockItemType.settings:
        return Icons.settings_rounded;
    }
  }

  Color get defaultColor {
    switch (this) {
      case BunaiksenDockItemType.matches:
        return AppKendoColors.indigo;
      case BunaiksenDockItemType.standings:
        return AppKendoColors.ipponGold;
      case BunaiksenDockItemType.calendar:
        return AppKendoColors.teal;
      case BunaiksenDockItemType.quickMemo:
        return AppKendoColors.pink;
      case BunaiksenDockItemType.timer:
        return AppKendoColors.orangeAccent;
      case BunaiksenDockItemType.settings:
        return AppKendoColors.grey;
    }
  }

  Color colorForMode(bool isDark) {
    if (!isDark) return defaultColor;
    switch (this) {
      case BunaiksenDockItemType.matches:
        return const Color(0xFF818CF8); // Indigo 400 (高コントラスト)
      case BunaiksenDockItemType.standings:
        return AppKendoColors.ipponGold;
      case BunaiksenDockItemType.calendar:
        return const Color(0xFF2DD4BF); // Teal 400
      case BunaiksenDockItemType.quickMemo:
        return const Color(0xFFF472B6); // Pink 400
      case BunaiksenDockItemType.timer:
        return const Color(0xFFFB923C); // Orange 400
      case BunaiksenDockItemType.settings:
        return const Color(0xFFCBD5E1); // Slate 200 (高視認性シルバーホワイト)
    }
  }

  static BunaiksenDockItemType fromId(String id) {
    return BunaiksenDockItemType.values.firstWhere(
      (e) => e.name == id,
      orElse: () => BunaiksenDockItemType.matches,
    );
  }
}

/// 🥋 部内戦ドックのアイテム順序を管理するNotifier（ローカル＋Googleアカウント自動同期）
class BunaiksenDockItemsOrderNotifier
    extends StateNotifier<List<BunaiksenDockItemType>> {
  final Ref _ref;
  static const _key = 'kendo_os_bunaiksen_dock_items_order';

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

  static const List<BunaiksenDockItemType> defaultOrder = [
    BunaiksenDockItemType.matches,
    BunaiksenDockItemType.standings,
    BunaiksenDockItemType.calendar,
    BunaiksenDockItemType.quickMemo,
    BunaiksenDockItemType.timer,
    BunaiksenDockItemType.settings,
  ];

  BunaiksenDockItemsOrderNotifier(this._ref) : super(defaultOrder) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = _ref.read(sharedPreferencesProvider);
      final list = prefs.getStringList(_key);
      if (list != null && list.isNotEmpty) {
        final loaded = <BunaiksenDockItemType>[];
        for (final id in list) {
          try {
            loaded.add(BunaiksenDockItemTypeExtension.fromId(id));
          } catch (_) {}
        }
        for (final item in defaultOrder) {
          if (!loaded.contains(item)) loaded.add(item);
        }
        state = loaded;
      }
    } catch (_) {}

    _syncFromCloud();
  }

  Future<void> _syncFromCloud() async {
    final uid = _linkedUid;
    if (uid == null) return;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('bunaiksen_dock_items_order')
          .get();

      if (doc.exists && doc.data() != null) {
        final cloudList = List<String>.from(
          doc.data()!['order'] as List? ?? [],
        );
        if (cloudList.isNotEmpty) {
          final loaded = <BunaiksenDockItemType>[];
          for (final id in cloudList) {
            try {
              loaded.add(BunaiksenDockItemTypeExtension.fromId(id));
            } catch (_) {}
          }
          for (final item in defaultOrder) {
            if (!loaded.contains(item)) loaded.add(item);
          }
          state = loaded;
          final prefs = _ref.read(sharedPreferencesProvider);
          await prefs.setStringList(_key, state.map((e) => e.name).toList());
        }
      }
    } catch (_) {}
  }

  /// ドラッグ＆ドロップによる並び替え
  Future<void> reorder(int oldIndex, int newIndex) async {
    if (oldIndex < 0 ||
        oldIndex >= state.length ||
        newIndex < 0 ||
        newIndex >= state.length ||
        oldIndex == newIndex) {
      return;
    }

    final list = List<BunaiksenDockItemType>.from(state);
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = list;

    try {
      final prefs = _ref.read(sharedPreferencesProvider);
      await prefs.setStringList(_key, list.map((e) => e.name).toList());
    } catch (_) {}

    _pushToCloud(list);
  }

  /// 並び順を一括更新して保存
  Future<void> updateOrder(List<BunaiksenDockItemType> newOrder) async {
    state = List.from(newOrder);
    try {
      final prefs = _ref.read(sharedPreferencesProvider);
      await prefs.setStringList(_key, newOrder.map((e) => e.name).toList());
    } catch (_) {}
    _pushToCloud(newOrder);
  }

  /// デフォルト順への復元
  Future<void> resetToDefault() async {
    state = defaultOrder;
    try {
      final prefs = _ref.read(sharedPreferencesProvider);
      await prefs.setStringList(_key, defaultOrder.map((e) => e.name).toList());
    } catch (_) {}

    _pushToCloud(defaultOrder);
  }

  void _pushToCloud(List<BunaiksenDockItemType> list) {
    final uid = _linkedUid;
    if (uid == null) return;

    _firestore
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('bunaiksen_dock_items_order')
        .set({
          'order': list.map((e) => e.name).toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true))
        .catchError((_) {});
  }
}

final bunaiksenDockItemsOrderProvider =
    StateNotifierProvider<
      BunaiksenDockItemsOrderNotifier,
      List<BunaiksenDockItemType>
    >((ref) {
      return BunaiksenDockItemsOrderNotifier(ref);
    });
