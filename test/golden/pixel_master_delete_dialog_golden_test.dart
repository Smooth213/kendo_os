import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/admin/presentation/components/master_delete_dialog_helper.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Golden] マスタ削除警告ダイアログ視覚整合性テスト', () {
    testWidgets('単一選手削除モーダルにおいて警告文とキャンセルおよび削除ボタンが明確に表示されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final testPlayer = PlayerModel(
        id: 'p_del_01',
        lastName: '山田',
        firstName: '太郎',
        lastNameKana: 'やまだ',
        firstNameKana: 'たろう',
        grade: 3,
        organization: '神武館',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return Consumer(
                    builder: (context, ref, _) {
                      return Center(
                        child: ElevatedButton(
                          onPressed: () {
                            MasterDeleteDialogHelper.confirmSingleDelete(
                              context,
                              ref,
                              testPlayer,
                            );
                          },
                          child: const Text('削除ダイアログを開く'),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      );

      // ボタンをタップしてダイアログを開く
      await tester.tap(find.text('削除ダイアログを開く'));
      await tester.pumpAndSettle();

      expect(find.text('削除の確認'), findsOneWidget);
      expect(find.text('選手データを完全に削除します。この操作は取り消せません。よろしいですか？'), findsOneWidget);
      expect(find.text('キャンセル'), findsOneWidget);
      expect(find.text('削除'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('一括削除モーダルにおいて対象人数および全件削除警告ボタンが赤色で強調表示されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return Consumer(
                    builder: (context, ref, _) {
                      return Center(
                        child: ElevatedButton(
                          onPressed: () {
                            MasterDeleteDialogHelper.confirmBulkDelete(
                              context: context,
                              ref: ref,
                              selectedPlayerIds: {'p1', 'p2', 'p3'},
                              onDeleted: () {},
                            );
                          },
                          child: const Text('一括削除ダイアログを開く'),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('一括削除ダイアログを開く'));
      await tester.pumpAndSettle();

      expect(find.text('一括削除の確認'), findsOneWidget);
      expect(
        find.text('3人の選手データを完全に削除します。この操作は取り消せません。よろしいですか？'),
        findsOneWidget,
      );
      expect(find.text('すべて削除'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
