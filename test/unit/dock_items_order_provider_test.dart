import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/providers/dock_items_order_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('🔄 DockItemsOrderNotifier Unit Tests', () {
    late SharedPreferences prefs;
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('初期状態ではデフォルトの9項目が登録されていること', () {
      final order = container.read(dockItemsOrderProvider);
      expect(order.length, 9);
      expect(order, DockItemsOrderNotifier.defaultOrder);
      expect(order.contains(DockItemType.viewerQr), isTrue);
      expect(order.contains(DockItemType.timer), isTrue);
    });

    test('reorder 操作により先頭の要素が指定位置へ移動しSharedPreferencesに保存されること', () async {
      final notifier = container.read(dockItemsOrderProvider.notifier);
      final firstItem = container.read(dockItemsOrderProvider).first;

      // 0番目を2番目へ移動
      await notifier.reorder(0, 2);

      final updated = container.read(dockItemsOrderProvider);
      expect(updated[2], firstItem);

      // SharedPreferencesの保存確認
      final savedList = prefs.getStringList('kendo_os_dock_items_order');
      expect(savedList, isNotNull);
      expect(savedList![2], firstItem.name);
    });

    test('resetToDefault でデフォルト順へ初期化復帰すること', () async {
      final notifier = container.read(dockItemsOrderProvider.notifier);
      await notifier.reorder(0, 5);
      expect(
        container.read(dockItemsOrderProvider),
        isNot(DockItemsOrderNotifier.defaultOrder),
      );

      await notifier.resetToDefault();
      expect(
        container.read(dockItemsOrderProvider),
        DockItemsOrderNotifier.defaultOrder,
      );
    });
  });
}
