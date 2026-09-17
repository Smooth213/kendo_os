import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/calculator/bunaiksen_dock_calculator_sheet.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildCalculatorSheet() {
    final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'bunaiksen');
    return ProviderScope(
      child: MaterialApp(
        theme: ThemeData.light().copyWith(extensions: [themeColors]),
        home: const Scaffold(body: BunaiksenDockCalculatorSheet()),
      ),
    );
  }

  group('🧮 BunaiksenDockCalculatorSheet Widget Tests', () {
    testWidgets('初期表示で計算機シートの要素（タイトル・サマリー・形式・基本設定・アコーディオン）が描画されること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildCalculatorSheet());
      await tester.pumpAndSettle();

      // ヘッダータイトルの確認
      expect(find.text('試合数・コート配分計算'), findsOneWidget);

      // サマリーカードの各テキスト確認
      expect(find.text('進行シミュレーション概要'), findsOneWidget);
      expect(find.text('総試合数'), findsOneWidget);
      expect(find.text('想定所要時間'), findsOneWidget);
      expect(find.text('終了予定時刻'), findsOneWidget);

      // 形式選択チップの存在確認
      expect(find.text('1リーグ総当たり'), findsOneWidget);
      expect(find.text('複数リーグ総当たり'), findsOneWidget);
      expect(find.text('トーナメント'), findsOneWidget);
      expect(find.text('予選L＋決勝T'), findsOneWidget);

      // アコーディオンの存在確認
      expect(find.text('詳細設定・調整 (タップで展開)'), findsOneWidget);
      expect(find.text('開始予定時刻 ＆ 時間詳細'), findsOneWidget);
      expect(find.text('リーグ人数配分 ＆ 進出枠'), findsOneWidget);
      expect(find.text('コート割り振りパターン'), findsOneWidget);

      // コピーボタン（ヘッダーアイコン）の存在確認
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);

      // 下部コピーボタンまでスクロールして確認
      await tester.scrollUntilVisible(
        find.text('進行予定・コート配分表をコピー'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('進行予定・コート配分表をコピー'), findsOneWidget);
    });

    testWidgets('参加人数の増減ボタンで値が変化し、再計算されること', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildCalculatorSheet());
      await tester.pumpAndSettle();

      // 初期状態 (8名, 2リーグ: 各4名 => 6+6=12試合)
      expect(find.text('8 名'), findsOneWidget);
      expect(find.text('12'), findsWidgets);

      // ＋ボタンをタップ
      final addButtons = find.byIcon(Icons.add);
      expect(addButtons, findsWidgets);
      await tester.tap(addButtons.first);
      await tester.pumpAndSettle();

      // 9名に増加（1リーグ5名, 2リーグ4名 => 10+6=16試合）
      expect(find.text('9 名'), findsOneWidget);
      expect(find.text('16'), findsWidgets);
    });

    testWidgets('形式を「トーナメント」に切り替えると試合数がトーナメント計算になり、詳細設定も更新されること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildCalculatorSheet());
      await tester.pumpAndSettle();

      // トーナメントを選択
      final tournamentChip = find.text('トーナメント');
      expect(tournamentChip, findsOneWidget);
      await tester.tap(tournamentChip);
      await tester.pumpAndSettle();

      // 8名のトーナメント（3決あり） => 8試合
      expect(find.text('8'), findsWidgets);

      // トーナメント詳細設定アコーディオンを展開
      final tournamentAccordion = find.text('トーナメント詳細設定');
      expect(tournamentAccordion, findsOneWidget);
      await tester.tap(tournamentAccordion);
      await tester.pumpAndSettle();

      expect(find.text('3位決定戦を行う'), findsOneWidget);
    });

    testWidgets('配分パターンアコーディオンを展開してタップで切り替えられること', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildCalculatorSheet());
      await tester.pumpAndSettle();

      // 「コート割り振りパターン」アコーディオンを展開
      final patternAccordion = find.text('コート割り振りパターン');
      await tester.scrollUntilVisible(
        patternAccordion,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(patternAccordion);
      await tester.pumpAndSettle();

      // パターンB（コート均等負荷）までスクロールしてタップ
      final patternB = find.text('パターンB (コート均等負荷)');
      await tester.scrollUntilVisible(
        patternB,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      // 画面中央付近へさらにスクロール
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
      await tester.pumpAndSettle();

      expect(patternB, findsOneWidget);
      await tester.tap(patternB);
      await tester.pumpAndSettle();

      // サマリーバッジが「均等負荷」に変化
      // 上部サマリーカードまでスクロールして戻す
      await tester.scrollUntilVisible(
        find.text('均等負荷'),
        -300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('均等負荷'), findsWidgets);
    });

    testWidgets('試合時間のクイック選択カプセル（例: 3分）タップで時間設定が変更されること', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildCalculatorSheet());
      await tester.pumpAndSettle();

      // 試合時間3分のチップを探してスクロール＆タップ
      final chip3m = find.text('3分').first;
      await tester.scrollUntilVisible(
        chip3m,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(chip3m, findsOneWidget);
      await tester.tap(chip3m);
      await tester.pumpAndSettle();

      // 基本デフォルト時間が3分に更新されること
      expect(find.text('3分'), findsWidgets);
    });

    testWidgets('リーグ別詳細設定アコーディオンを展開してAリーグの人数を変更できること', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildCalculatorSheet());
      await tester.pumpAndSettle();

      // 「リーグ人数配分 ＆ 進出枠」アコーディオンを展開
      final leagueAccordion = find.text('リーグ人数配分 ＆ 進出枠');
      await tester.scrollUntilVisible(
        leagueAccordion,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(leagueAccordion);
      await tester.pumpAndSettle();

      // 初期状態: Aリーグ4名(6試合), Bリーグ4名(6試合) => 計12試合
      expect(find.text('Aリーグ'), findsWidgets);
      expect(find.text('Bリーグ'), findsWidgets);

      // Aリーグの人数「4名」の＋ボタンをタップ
      final addBtns = find.byIcon(Icons.add);
      // 基本設定カードの＋ボタンに続いて、アコーディオン内の＋ボタンが存在
      await tester.tap(addBtns.at(2));
      await tester.pumpAndSettle();

      // 再計算されること
      expect(find.byType(BunaiksenDockCalculatorSheet), findsOneWidget);
    });

    testWidgets('予選L＋決勝Tでアコーディオンを展開し、各リーグからの進出枠を切り替えて再計算できること', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildCalculatorSheet());
      await tester.pumpAndSettle();

      // 形式「予選L＋決勝T」をタップ
      final prelimChip = find.text('予選L＋決勝T');
      expect(prelimChip, findsOneWidget);
      await tester.tap(prelimChip);
      await tester.pumpAndSettle();

      // 初期状態: 8名(2L各4名=12試合), 上位2名進出(計4名決勝T=4試合) => 計16試合
      expect(find.text('16'), findsWidgets);

      // 「リーグ人数配分 ＆ 進出枠」アコーディオンを展開
      final leagueAccordion = find.text('リーグ人数配分 ＆ 進出枠');
      await tester.scrollUntilVisible(
        leagueAccordion,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(leagueAccordion);
      await tester.pumpAndSettle();

      // 「1位のみ」のチップを探してタップ
      final chip1st = find.text('1位のみ');
      expect(chip1st, findsOneWidget);
      await tester.tap(chip1st);
      await tester.pumpAndSettle();

      // 2名進出 => 決勝戦1試合のみ。予選12試合＋決勝1試合＝計13試合
      await tester.scrollUntilVisible(
        find.text('13'),
        -300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('13'), findsWidgets);
    });

    testWidgets('時間詳細アコーディオンで「一括設定」と「リーグ別に個別設定」を切り替えられること', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildCalculatorSheet());
      await tester.pumpAndSettle();

      // 「開始予定時刻 ＆ 時間詳細」アコーディオンを展開
      final timeAccordion = find.text('開始予定時刻 ＆ 時間詳細');
      await tester.scrollUntilVisible(
        timeAccordion,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(timeAccordion);
      await tester.pumpAndSettle();

      // 初期状態では「一括設定 (全リーグ共通)」が表示されている
      expect(find.text('一括設定 (全リーグ共通)'), findsOneWidget);
      expect(find.text('リーグ別に個別設定'), findsOneWidget);

      // 「リーグ別に個別設定」をタップ
      final individualTab = find.text('リーグ別に個別設定');
      await tester.tap(individualTab);
      await tester.pumpAndSettle();

      // 各リーグの試合時間設定が表示されること
      expect(find.text('リーグごとの試合時間 (個別設定)'), findsOneWidget);

      // 「一括設定 (全リーグ共通)」をタップして戻す
      final uniformTab = find.text('一括設定 (全リーグ共通)');
      await tester.tap(uniformTab);
      await tester.pumpAndSettle();

      expect(find.text('1試合の時間'), findsOneWidget);
    });

    testWidgets('開始予定時刻のハイブリッドUI（ダイヤル展開とクイック選択）が正常に動作すること', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildCalculatorSheet());
      await tester.pumpAndSettle();

      // 「開始予定時刻 ＆ 時間詳細」アコーディオンを展開
      final timeAccordion = find.text('開始予定時刻 ＆ 時間詳細');
      await tester.scrollUntilVisible(
        timeAccordion,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(timeAccordion);
      await tester.pumpAndSettle();

      // 開始予定時刻エリアまでスクロール
      final dialBtn = find.text('ダイヤル');
      await tester.scrollUntilVisible(
        dialBtn,
        300,
        scrollable: find.byType(Scrollable).first,
      );

      // 開始予定時刻エリアが表示されていること
      expect(find.text('開始予定時刻'), findsOneWidget);
      expect(dialBtn, findsOneWidget);

      // 「ダイヤル」ボタンをタップしてホイールピッカーを展開
      await tester.tap(dialBtn);
      await tester.pumpAndSettle();

      // ダイヤルモード（完了ボタン、CupertinoPickerが表示される）
      expect(find.text('完了'), findsOneWidget);
      expect(find.byType(CupertinoPicker), findsWidgets);

      // 「完了」ボタンをタップして通常モードに戻る
      await tester.tap(find.text('完了'));
      await tester.pumpAndSettle();
      expect(find.text('ダイヤル'), findsOneWidget);

      // クイック選択カプセルの「10:00」までスクロールしてタップ
      final time10 = find.text('10:00');
      await tester.scrollUntilVisible(
        time10,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(time10, findsOneWidget);
      await tester.tap(time10);
      await tester.pumpAndSettle();

      // 「10」時が表示されていること（デジタル数字ブロック）
      expect(find.text('10'), findsWidgets);

      // 数字ブロックの長押しでダイヤルモードが展開すること
      await tester.longPress(find.text('10').first);
      await tester.pumpAndSettle();
      expect(find.text('完了'), findsOneWidget);
      expect(find.byType(CupertinoPicker), findsWidgets);
    });
  });
}
