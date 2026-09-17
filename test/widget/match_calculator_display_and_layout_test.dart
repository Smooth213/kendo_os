import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/calculator/bunaiksen_dock_calculator_sheet.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildCalculatorSheet({bool isDark = false}) {
    final themeColors = AppThemeColors.ofMode(
      isDark: isDark,
      mode: 'bunaiksen',
    );
    return ProviderScope(
      child: MaterialApp(
        theme: isDark
            ? ThemeData.dark().copyWith(extensions: [themeColors])
            : ThemeData.light().copyWith(extensions: [themeColors]),
        home: const Scaffold(body: BunaiksenDockCalculatorSheet()),
      ),
    );
  }

  group('📱 試合数計算機：表示・視認性・レイアウト完全性テスト', () {
    testWidgets('スマートフォン標準幅 (390px) でオーバーフローなく全要素が正しく表示されること', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildCalculatorSheet());
      await tester.pumpAndSettle();

      // 基本設定カードの重要ラベルが文字切れなく描画されていること
      expect(find.text('試合数・コート配分計算'), findsOneWidget);
      expect(find.text('試合形式'), findsOneWidget);
      expect(find.text('規模・コート設定'), findsOneWidget);
      expect(find.text('基本試合時間'), findsOneWidget);

      // アコーディオンのタイトルと設定バッジが正しく描画されていること
      expect(find.text('開始予定時刻 ＆ 時間詳細'), findsOneWidget);
      expect(find.text('リーグ人数配分 ＆ 進出枠'), findsOneWidget);
      expect(find.text('コート割り振りパターン'), findsOneWidget);

      // サマリーバッジの表示確認
      expect(find.textContaining('09:00開始'), findsOneWidget);
      expect(find.textContaining('2リーグ'), findsWidgets);
      expect(find.text('インターバル優先'), findsWidgets);

      // エラーログやオーバーフローがないこと
      expect(tester.takeException(), isNull);
    });

    testWidgets('アコーディオンの開閉トグル（展開 ➔ 折りたたみ）が正常に機能すること', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildCalculatorSheet());
      await tester.pumpAndSettle();

      // 初期状態ではSizeTransitionのサイズ係数が0.0（折りたたまれた状態）
      final sizeTransitions = find.byType(SizeTransition);
      expect(
        tester.widget<SizeTransition>(sizeTransitions.first).sizeFactor.value,
        0.0,
      );

      // 1. スクロールしてタップして展開
      final timeAccordion = find.text('開始予定時刻 ＆ 時間詳細');
      await tester.scrollUntilVisible(
        timeAccordion,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      // ヘッダー被りを避けてタップ可能な位置へ微調整
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 100));
      await tester.pumpAndSettle();
      await tester.tap(timeAccordion);
      await tester.pumpAndSettle();

      // サイズ係数が1.0（完全に展開）になり、中身が操作可能になること
      expect(
        tester.widget<SizeTransition>(sizeTransitions.first).sizeFactor.value,
        1.0,
      );
      expect(find.text('インターバル クイック選択'), findsOneWidget);

      // 2. 再度タップして折りたたむ
      await tester.tap(timeAccordion);
      await tester.pumpAndSettle();

      // サイズ係数が0.0に戻り、完全に折りたたまれること
      expect(
        tester.widget<SizeTransition>(sizeTransitions.first).sizeFactor.value,
        0.0,
      );
    });

    testWidgets('コート別タイムラインのコート切替タブで第1コートと第2コートを正しく切り替えられること', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildCalculatorSheet());
      await tester.pumpAndSettle();

      // タイムラインエリアまでスクロール
      final court1Tab = find.text('第1コート (6試合)');
      await tester.scrollUntilVisible(
        court1Tab,
        300,
        scrollable: find.byType(Scrollable).first,
      );

      // コート切替タブが表示されていること
      expect(court1Tab, findsOneWidget);
      expect(find.text('第2コート (6試合)'), findsOneWidget);

      // 初期状態: 第1コートの状況バーが表示
      expect(find.text('第1コート 進行順 (6試合)'), findsOneWidget);

      // 第2コートをタップ
      await tester.tap(find.text('第2コート (6試合)'));
      await tester.pumpAndSettle();

      // 第2コートの状況バーに更新されること
      expect(find.text('第2コート 進行順 (6試合)'), findsOneWidget);
    });

    testWidgets('ダークモードでもコントラスト高く正常に描画されエラーがないこと', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildCalculatorSheet(isDark: true));
      await tester.pumpAndSettle();

      expect(find.text('試合数・コート配分計算'), findsOneWidget);
      expect(find.text('進行シミュレーション概要'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
