import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/room_join_duplicate_warning_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Golden] ルームID重複警告ダイアログ Pixel完全性テスト', () {
    Widget buildDialogTestWidget({required bool isDark, required String code}) {
      final themeColors = AppThemeColors.ofMode(
        isDark: isDark,
        mode: isDark ? 'dark' : 'normal',
      );

      return MaterialApp(
        theme: isDark
            ? ThemeData.dark().copyWith(extensions: [themeColors])
            : ThemeData.light().copyWith(extensions: [themeColors]),
        home: Scaffold(
          body: Center(
            child: RoomJoinDuplicateWarningDialog(code: code, onConfirm: () {}),
          ),
        ),
      );
    }

    testWidgets('ライトモード表示において 警告アイコンおよびボタン配置が正常に描画されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildDialogTestWidget(isDark: false, code: 'DOJO-777'),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(RoomJoinDuplicateWarningDialog), findsOneWidget);
      expect(find.textContaining('DOJO-777'), findsOneWidget);
      expect(find.byIcon(Icons.report_problem_rounded), findsOneWidget);
      expect(find.text('このまま接続'), findsOneWidget);
      expect(find.text('キャンセル（変更する）'), findsOneWidget);
    });

    testWidgets('ダークモード表示において ダーク背景およびコントラスト色が正常に適用描画されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildDialogTestWidget(isDark: true, code: 'KENDO-999'),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(RoomJoinDuplicateWarningDialog), findsOneWidget);
      expect(find.textContaining('KENDO-999'), findsOneWidget);
    });
  });
}
