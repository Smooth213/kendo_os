import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_timer_bottom_sheet.dart';

Widget createTestWidget({required Widget child}) {
  return ProviderScope(
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  group('⏱️ DockTimerBottomSheet Widget Tests', () {
    testWidgets('初期表示で3分のデジタル表示と定型プリセットが表示されること', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(child: const DockTimerBottomSheet()),
      );
      await tester.pumpAndSettle();

      // タイトルの存在確認
      expect(find.text('独立型タイマー'), findsOneWidget);

      // 初期デジタル時間の表示確認 (分・コロン・秒)
      expect(find.text('03'), findsOneWidget);
      expect(find.text(' : '), findsOneWidget);
      expect(find.text('00'), findsOneWidget);
      expect(find.text('タップで手入力 ｜ 長押しでダイヤル'), findsOneWidget);

      // プリセットボタンの確認（カッコ・テキスト削除、1分・2分追加の全6種類）
      expect(find.text('1分'), findsOneWidget);
      expect(find.text('2分'), findsOneWidget);
      expect(find.text('3分'), findsOneWidget);
      expect(find.text('5分'), findsOneWidget);
      expect(find.text('10分'), findsOneWidget);
      expect(find.text('15分'), findsOneWidget);

      // 操作ボタンの確認
      expect(find.text('スタート'), findsOneWidget);
      expect(find.text('リセット'), findsOneWidget);
    });

    testWidgets('プリセットタップでタイマー設定が切り替わること', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(child: const DockTimerBottomSheet()),
      );
      await tester.pumpAndSettle();

      // 5分プリセットをタップ
      await tester.tap(find.text('5分'));
      await tester.pumpAndSettle();

      // デジタル時間が05:00に切り替わること
      expect(find.text('05'), findsOneWidget);
      expect(find.text('00'), findsOneWidget);

      // +1分をタップ
      await tester.tap(find.text('+1分'));
      await tester.pumpAndSettle();
      expect(find.text('06'), findsOneWidget);
    });

    testWidgets('分（03）タップで直接手入力モードになり時間を設定できること', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(child: const DockTimerBottomSheet()),
      );
      await tester.pumpAndSettle();

      // 「03」をタップして分編集モードに入る
      await tester.tap(find.text('03'));
      await tester.pumpAndSettle();

      // ガイドテキストが切り替わり、確定ボタンが出現
      expect(find.text('分を入力して確定（または秒をタップ）'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      // 分を7分に入力
      await tester.enterText(find.byType(TextField), '07');
      await tester.pumpAndSettle();

      // 確定ボタンをタップ
      await tester.tap(find.byIcon(Icons.check_circle));
      await tester.pumpAndSettle();

      // 7分に設定されたこと
      expect(find.text('07'), findsOneWidget);
      expect(find.text('00'), findsOneWidget);
      expect(find.text('タップで手入力 ｜ 長押しでダイヤル'), findsOneWidget);
    });

    testWidgets('長押しでその場にドラムロールが出現し完了で確定できること', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(child: const DockTimerBottomSheet()),
      );
      await tester.pumpAndSettle();

      // 初期状態ではドラムロールは非表示
      expect(find.text('ダイヤル調整'), findsNothing);

      // 特大デジタル時計カードを長押し
      await tester.longPress(find.text('03'));
      await tester.pumpAndSettle();

      // その場ドラムロール（CupertinoPicker）が出現
      expect(find.text('ダイヤル調整'), findsOneWidget);
      expect(find.text('完了'), findsOneWidget);
      expect(find.text('分'), findsOneWidget);
      expect(find.text('秒'), findsOneWidget);

      // 完了ボタンをタップ
      await tester.tap(find.text('完了'));
      await tester.pumpAndSettle();

      // ドラムロールが閉じ、通常表示に復帰
      expect(find.text('ダイヤル調整'), findsNothing);
      expect(find.text('タップで手入力 ｜ 長押しでダイヤル'), findsOneWidget);
    });

    testWidgets('手入力後、確定ボタンを押さずに「スタート」を押しても手入力値でタイマーが開始されること', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(child: const DockTimerBottomSheet()),
      );
      await tester.pumpAndSettle();

      // 「03」をタップ
      await tester.tap(find.text('03'));
      await tester.pumpAndSettle();

      // 分を「05」に入力
      await tester.enterText(find.byType(TextField), '05');
      await tester.pumpAndSettle();

      // 確定ボタンを押さずに、直接「スタート」ボタンをタップ
      await tester.ensureVisible(find.text('スタート'));
      await tester.tap(find.text('スタート'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // タイマーが開始され（一時停止ボタン表示）、05:00であること
      expect(find.text('一時停止'), findsOneWidget);
      expect(find.text('05'), findsOneWidget);
    });

    testWidgets('分を入力後に秒をタップしても、分で入力した値が保持されて合算されること', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(child: const DockTimerBottomSheet()),
      );
      await tester.pumpAndSettle();

      // 「03」をタップ
      await tester.tap(find.text('03'));
      await tester.pumpAndSettle();

      // 分に「7」（1桁）を入力
      await tester.enterText(find.byType(TextField), '7');
      await tester.pumpAndSettle();

      // 秒（「00」）をタップして手動遷移
      await tester.tap(find.text('00'));
      await tester.pumpAndSettle();

      // 秒フィールドに「30」を入力
      await tester.enterText(find.byType(TextField), '30');
      await tester.pumpAndSettle();

      // 確定ボタンをタップ
      await tester.tap(find.byIcon(Icons.check_circle));
      await tester.pumpAndSettle();

      // 07:30 として確定されていること
      expect(find.text('07'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
    });

    testWidgets('分を入力中に背景（タイトル等）をタップすると自動コミットされること', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(child: const DockTimerBottomSheet()),
      );
      await tester.pumpAndSettle();

      // 「03」をタップ
      await tester.tap(find.text('03'));
      await tester.pumpAndSettle();

      // 分に「04」を入力
      await tester.enterText(find.byType(TextField), '04');
      await tester.pumpAndSettle();

      // 確定ボタンを押さずに背景（タイトル「独立型タイマー」）をタップしてアンフォーカス
      await tester.tap(find.text('独立型タイマー'));
      await tester.pumpAndSettle();

      // 04:00 として確定し通常表示に戻ること
      expect(find.text('04'), findsOneWidget);
      expect(find.text('00'), findsOneWidget);
      expect(find.text('タップで手入力 ｜ 長押しでダイヤル'), findsOneWidget);
    });

    testWidgets('分の入力で2桁入力完了時に自動的に秒フィールドへフォーカス遷移すること', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(child: const DockTimerBottomSheet()),
      );
      await tester.pumpAndSettle();

      // 「03」をタップ
      await tester.tap(find.text('03'));
      await tester.pumpAndSettle();

      // 分編集モードであることを確認
      expect(find.text('分を入力して確定（または秒をタップ）'), findsOneWidget);

      // 分に「08」と2桁入力
      await tester.enterText(find.byType(TextField), '08');
      await tester.pumpAndSettle();

      // 自動的に秒編集モード（ガイドテキスト: 秒を入力して確定...）へ切り替わっていること
      expect(find.text('秒を入力して確定（または分をタップ）'), findsOneWidget);
    });

    testWidgets('タップ時に青いフォーカス枠線が存在せず、元の数字がhintTextとして表示され即入力可能な状態になること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(child: const DockTimerBottomSheet()),
      );
      await tester.pumpAndSettle();

      // 「03」をタップ
      await tester.tap(find.text('03'));
      await tester.pumpAndSettle();

      // TextFieldのプロパティ検証
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty); // バックスペース不要で空から入力可能
      expect(textField.decoration?.hintText, '03'); // 元の数字がプレースホルダーとして表示
      expect(
        textField.decoration?.border,
        InputBorder.none,
      ); // 青枠などの不要な枠線が完全にnone
      expect(textField.decoration?.focusedBorder, InputBorder.none);
    });

    testWidgets('タップ後に何も入力せずアンフォーカスした場合、元の時間が安全に維持されること', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(child: const DockTimerBottomSheet()),
      );
      await tester.pumpAndSettle();

      // 「03」をタップ（入力フィールドが開くが文字は打たない）
      await tester.tap(find.text('03'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);

      // 背景をタップしてアンフォーカス
      await tester.tap(find.text('独立型タイマー'));
      await tester.pumpAndSettle();

      // 入力フィールドが閉じ、元の「03:00」が崩れずに復帰すること
      expect(find.byType(TextField), findsNothing);
      expect(find.text('03'), findsOneWidget);
      expect(find.text('00'), findsOneWidget);
    });
  });
}
