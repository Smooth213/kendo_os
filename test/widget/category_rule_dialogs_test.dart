import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_dialogs.dart';

void main() {
  testWidgets('CategoryRuleDialogs bulk apply dialog renders correctly', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              CategoryRuleDialogs.showBulkApplyConfirmDialog(
                context: context,
                category: '一般',
                matchCount: 5,
              );
            },
            child: const Text('Open Dialog'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('作成済みの試合に一括適用しますか？'), findsOneWidget);
    expect(find.text('一括適用する'), findsOneWidget);
    expect(find.text('適用しない（新規試合のみ）'), findsOneWidget);
  });

  testWidgets('CategoryRuleDialogs delete category dialog renders correctly', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              CategoryRuleDialogs.showDeleteCategoryDialog(
                context: context,
                category: '一般',
              );
            },
            child: const Text('Open Delete Dialog'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Delete Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('部門を削除しますか？'), findsOneWidget);
    expect(find.text('削除'), findsOneWidget);
  });
}
