import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bulk_rule_target_select_section.dart';

void main() {
  group('🛡️ BulkRuleTargetSelectSection Widget Tests', () {
    testWidgets('Renders filters, units and triggers callbacks', (
      tester,
    ) async {
      String selectedCategory = 'すべて';
      String selectedType = 'すべて';
      bool toggleAllCalled = false;
      final selectedIds = <String>['m1'];

      final units = [
        const MatchGroupUnit(
          id: 'u1',
          displayName: '1回戦: チームA vs チームB',
          matchIds: ['m1', 'm2'],
          category: '一般の部',
          resolvedType: '団体戦',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return BulkRuleTargetSelectSection(
                  categories: const ['すべて', '一般の部'],
                  matchTypes: const ['すべて', '団体戦'],
                  selectedCategoryFilter: selectedCategory,
                  selectedTypeFilter: selectedType,
                  filteredUnits: units,
                  selectedMatchIds: selectedIds,
                  primaryAccent: Colors.blue,
                  isDark: false,
                  textColor: Colors.black,
                  onCategoryChanged: (cat) {
                    setState(() => selectedCategory = cat ?? 'すべて');
                  },
                  onTypeChanged: (type) {
                    setState(() => selectedType = type ?? 'すべて');
                  },
                  onToggleUnit: (unit, checked) {
                    if (checked == true) {
                      selectedIds.addAll(unit.matchIds);
                    } else {
                      selectedIds.clear();
                    }
                  },
                  onToggleAll: () => toggleAllCalled = true,
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('STEP 1: 変更対象の試合を選択'), findsOneWidget);
      expect(find.text('カテゴリ'), findsOneWidget);
      expect(find.text('形式・種別'), findsOneWidget);
      expect(find.text('1回戦: チームA vs チームB'), findsOneWidget);
      expect(find.text('現在 0 件を選択中 / 全 1 件中'), findsOneWidget);

      await tester.tap(find.text('全選択'));
      await tester.pumpAndSettle();
      expect(toggleAllCalled, isTrue);
    });
  });
}
