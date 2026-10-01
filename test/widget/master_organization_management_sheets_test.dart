import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/admin/presentation/components/master_menu_bottom_sheet.dart';
import 'package:kendo_os/admin/presentation/components/master_register_organization_bottom_sheet.dart';

void main() {
  group('[Widget] マスター組織管理およびメニューボトムシート ウィジェットテスト', () {
    testWidgets('MasterRegisterOrganizationBottomSheetが正常に表示されること', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  return ElevatedButton(
                    onPressed: () => MasterRegisterOrganizationBottomSheet.show(
                      context,
                      ref,
                    ),
                    child: const Text('組織登録開く'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('組織登録開く'));
      await tester.pumpAndSettle();

      expect(find.text('道場名・学校名の登録'), findsOneWidget);
      expect(find.text('選手を追加する前に、道場名または学校名を入力してください。'), findsOneWidget);
      expect(find.text('登録'), findsOneWidget);
      expect(find.text('キャンセル'), findsOneWidget);

      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();
      expect(find.text('道場名・学校名の登録'), findsNothing);
    });

    testWidgets('MasterRegisterOrganizationBottomSheetの未登録警告ダイアログが表示されること', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  return ElevatedButton(
                    onPressed: () =>
                        MasterRegisterOrganizationBottomSheet.showMustRegisterDialog(
                          context,
                          ref,
                        ),
                    child: const Text('警告開く'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('警告開く'));
      await tester.pumpAndSettle();

      expect(find.text('道場名の登録が必要です'), findsOneWidget);
      expect(find.text('道場名を入力'), findsOneWidget);

      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();
      expect(find.text('道場名の登録が必要です'), findsNothing);
    });

    testWidgets('MasterMenuBottomSheetが正常に展開されメニュー項目が描画されること', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  return ElevatedButton(
                    onPressed: () => MasterMenuBottomSheet.show(context, ref),
                    child: const Text('メニュー開く'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('メニュー開く'));
      await tester.pumpAndSettle();

      expect(find.text('データとストレージ管理'), findsOneWidget);
      expect(find.text('新年度の一括進級'), findsOneWidget);
    });
  });
}
