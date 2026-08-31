import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/timeline_ui_state_provider.dart';

void main() {
  group('🥋 Timeline UI State Provider Tests', () {
    test(
      'selectedCategoryFilterProvider の初期値は null であり、カテゴリー変更・リセットが動作すること',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        expect(container.read(selectedCategoryFilterProvider), isNull);

        container.read(selectedCategoryFilterProvider.notifier).state =
            '小学生低学年';
        expect(container.read(selectedCategoryFilterProvider), '小学生低学年');

        container.read(selectedCategoryFilterProvider.notifier).state = null;
        expect(container.read(selectedCategoryFilterProvider), isNull);
      },
    );

    test('timelineGroupExpansionMapProvider の一括設定・個別切り替えが正常に動作すること', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final groupIds = ['group_1', 'group_2', 'group_3'];

      // 全開
      container
          .read(timelineGroupExpansionMapProvider.notifier)
          .setAll(groupIds, true);
      var state = container.read(timelineGroupExpansionMapProvider);
      expect(state['group_1'], isTrue);
      expect(state['group_2'], isTrue);
      expect(state['group_3'], isTrue);

      // 個別トグル (group_2 を閉じる)
      container
          .read(timelineGroupExpansionMapProvider.notifier)
          .toggleGroup('group_2', true);
      state = container.read(timelineGroupExpansionMapProvider);
      expect(state['group_1'], isTrue);
      expect(state['group_2'], isFalse);
      expect(state['group_3'], isTrue);

      // 全閉
      container
          .read(timelineGroupExpansionMapProvider.notifier)
          .setAll(groupIds, false);
      state = container.read(timelineGroupExpansionMapProvider);
      expect(state['group_1'], isFalse);
      expect(state['group_2'], isFalse);
      expect(state['group_3'], isFalse);
    });
  });
}
