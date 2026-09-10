import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_items_reorder_bottom_sheet.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget createTestWidget({
  required Widget child,
  required SharedPreferences prefs,
}) {
  return ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  group('🔄 DockItemsReorderBottomSheet Widget Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets('並び替えボトムシートが正常にレンダリングされReorderableListViewと項目が表示されること', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          child: const DockItemsReorderBottomSheet(),
          prefs: prefs,
        ),
      );
      await tester.pumpAndSettle();

      // ヘッダータイトルの存在確認
      expect(find.text('ドックの並び替え'), findsOneWidget);

      // ReorderableListView の存在確認
      expect(find.byType(ReorderableListView), findsOneWidget);

      // 初期化ボタンの存在確認
      expect(find.text('初期順に戻す'), findsOneWidget);

      // 新機能「観戦QR」と「タイマー」がリストに含まれていること
      expect(find.text('観戦QR'), findsOneWidget);
      expect(find.text('タイマー'), findsOneWidget);
      expect(find.text('プログラム'), findsOneWidget);
    });
  });
}
