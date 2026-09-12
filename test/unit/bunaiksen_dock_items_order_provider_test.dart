import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_dock_items_order_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🔄 BunaiksenDockItemsOrderNotifier Unit Tests', () {
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

    test('初期状態では部内戦専用の全6項目が登録されていること', () {
      final order = container.read(bunaiksenDockItemsOrderProvider);
      expect(order.length, 6);
      expect(order, BunaiksenDockItemsOrderNotifier.defaultOrder);
      expect(order.contains(BunaiksenDockItemType.matches), isTrue);
      expect(order.contains(BunaiksenDockItemType.standings), isTrue);
      expect(order.contains(BunaiksenDockItemType.calendar), isTrue);
      expect(order.contains(BunaiksenDockItemType.quickMemo), isTrue);
      expect(order.contains(BunaiksenDockItemType.timer), isTrue);
      expect(order.contains(BunaiksenDockItemType.settings), isTrue);
    });

    test('reorder 操作により項目が移動しSharedPreferencesに保存されること', () async {
      final notifier = container.read(bunaiksenDockItemsOrderProvider.notifier);
      final firstItem = container.read(bunaiksenDockItemsOrderProvider).first;

      // 0番目を2番目へ移動
      await notifier.reorder(0, 2);

      final updated = container.read(bunaiksenDockItemsOrderProvider);
      expect(updated[2], firstItem);

      // SharedPreferencesの保存確認
      final savedList = prefs.getStringList(
        'kendo_os_bunaiksen_dock_items_order',
      );
      expect(savedList, isNotNull);
      expect(savedList![2], firstItem.name);
    });

    test('resetToDefault でデフォルト順へ初期化復帰すること', () async {
      final notifier = container.read(bunaiksenDockItemsOrderProvider.notifier);
      await notifier.reorder(0, 4);
      expect(
        container.read(bunaiksenDockItemsOrderProvider),
        isNot(BunaiksenDockItemsOrderNotifier.defaultOrder),
      );

      await notifier.resetToDefault();
      expect(
        container.read(bunaiksenDockItemsOrderProvider),
        BunaiksenDockItemsOrderNotifier.defaultOrder,
      );
    });
  });
}
