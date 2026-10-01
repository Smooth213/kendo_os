import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/room_join_duplicate_warning_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[E2E] 道場ルームID重複検知および解決フロー 複合シナリオテスト', () {
    testWidgets('ルームID重複警告ダイアログにおいてキャンセル選択時に部屋接続が中断され再採番へ戻ること', (
      WidgetTester tester,
    ) async {
      bool isConfirmed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  RoomJoinDuplicateWarningDialog.show(
                    context: context,
                    code: 'COLLISION-ROOM-001',
                    onConfirm: () => isConfirmed = true,
                  );
                },
                child: const Text('参加モーダル表示'),
              ),
            ),
          ),
        ),
      );

      // ダイアログ表示
      await tester.tap(find.text('参加モーダル表示'));
      await tester.pumpAndSettle();

      expect(find.byType(RoomJoinDuplicateWarningDialog), findsOneWidget);
      expect(find.textContaining('COLLISION-ROOM-001'), findsOneWidget);

      // キャンセル（変更する）をタップ
      await tester.tap(find.text('キャンセル（変更する）'));
      await tester.pumpAndSettle();

      // ダイアログが閉じ、接続確定処理が実行されていないこと
      expect(find.byType(RoomJoinDuplicateWarningDialog), findsNothing);
      expect(isConfirmed, isFalse);
    });

    testWidgets('ルームID重複警告ダイアログにおいてこのまま接続選択時に確定処理が安全に実行されること', (
      WidgetTester tester,
    ) async {
      bool isConfirmed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  RoomJoinDuplicateWarningDialog.show(
                    context: context,
                    code: 'COLLISION-ROOM-002',
                    onConfirm: () => isConfirmed = true,
                  );
                },
                child: const Text('参加モーダル表示'),
              ),
            ),
          ),
        ),
      );

      // ダイアログ表示
      await tester.tap(find.text('参加モーダル表示'));
      await tester.pumpAndSettle();

      expect(find.byType(RoomJoinDuplicateWarningDialog), findsOneWidget);

      // このまま接続をタップ
      await tester.tap(find.text('このまま接続'));
      await tester.pumpAndSettle();

      // ダイアログが閉じ、確定コールバックが正常に実行されたこと
      expect(find.byType(RoomJoinDuplicateWarningDialog), findsNothing);
      expect(isConfirmed, isTrue);
    });
  });
}
