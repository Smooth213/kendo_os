import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/widgets/app_loading_indicator.dart';
import 'package:kendo_os/shared/widgets/room_join_qr_dialog_actions.dart';

void main() {
  group('[Widget] RoomJoinQrDialogActions ウィジェットテスト', () {
    testWidgets('not 読み込み中において Cancel and Join buttonsが正しく描画されること', (
      tester,
    ) async {
      bool canceled = false;
      bool joined = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoomJoinQrDialogActions(
              isLoading: false,
              isDark: false,
              onCancel: () => canceled = true,
              onJoin: () => joined = true,
            ),
          ),
        ),
      );

      expect(find.text('キャンセル'), findsOneWidget);
      expect(find.text('接続開始'), findsOneWidget);
      expect(find.byType(AppLoadingIndicator), findsNothing);

      await tester.tap(find.text('キャンセル'));
      await tester.pump();
      expect(canceled, isTrue);

      await tester.tap(find.text('接続開始'));
      await tester.pump();
      expect(joined, isTrue);
    });

    testWidgets(
      '読み込み中において AppLoadingIndicator and disables cancelが正しく描画されること',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RoomJoinQrDialogActions(
                isLoading: true,
                isDark: true,
                onCancel: () {},
                onJoin: () {},
              ),
            ),
          ),
        );

        expect(find.byType(AppLoadingIndicator), findsOneWidget);
        expect(find.text('接続開始'), findsNothing);

        // キャンセルボタンは disabled (onPressed: null)
        final outlinedButton = tester.widget<OutlinedButton>(
          find.byType(OutlinedButton),
        );
        expect(outlinedButton.onPressed, isNull);
      },
    );
  });
}
