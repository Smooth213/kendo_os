import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_league_points_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_individual_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_renseikai_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_team_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_multi_scene_tabs_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_simple_scene_rule_form.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_time_stepper_tile.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('[Widget] カテゴリ設定 シーン・セクションコンポーネント統合検証テスト', () {
    testWidgets('CategoryLeaguePointsSectionにおいて 勝ち点設定項目が正しく描画され入力処理されること', (
      WidgetTester tester,
    ) async {
      double win = 3.0;
      double loss = 0.0;
      double draw = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return CategoryLeaguePointsSection(
                  keyPrefix: 'test_category',
                  winPoint: win,
                  lossPoint: loss,
                  drawPoint: draw,
                  onWinChanged: (val) => setState(() => win = val),
                  onLossChanged: (val) => setState(() => loss = val),
                  onDrawChanged: (val) => setState(() => draw = val),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('勝ち点（リーグ戦の順位決定用）'), findsOneWidget);
      expect(find.text('勝ち（点）'), findsOneWidget);
      expect(find.text('負け（点）'), findsOneWidget);
      expect(find.text('引き分け（点）'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('win_pt_test_category')),
        '5.0',
      );
      await tester.pumpAndSettle();

      expect(win, 5.0);
    });

    testWidgets('CategoryRuleIndividualSectionにおいて 個人戦ルール設定が正しく描画されること', (
      WidgetTester tester,
    ) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CategoryRuleIndividualSection(
                isLeague: true,
                isNormal: true,
                categoryKey: '一般',
                themeColors: themeColors,
                hasExtension: true,
                isEnchoUnlimited: false,
                enchoCount: 1,
                enchoTime: 2.0,
                hasHantei: true,
                winPoint: 3.0,
                lossPoint: 0.0,
                drawPoint: 1.0,
                onHasExtensionChanged: (_) {},
                onIsEnchoUnlimitedChanged: (_) {},
                onEnchoCountChanged: (_) {},
                onEnchoTimeChanged: (_) {},
                onHasHanteiChanged: (_) {},
                onWinPointChanged: (_) {},
                onLossPointChanged: (_) {},
                onDrawPointChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('延長戦を有効にする'), findsOneWidget);
      expect(find.text('時間・回数無制限'), findsOneWidget);
      expect(find.text('最大延長回数'), findsOneWidget);
      expect(find.text('延長戦の時間'), findsOneWidget);
    });

    testWidgets('CategoryRuleRenseikaiSectionにおいて 練習会および勝ち抜き設定が正しく描画されること', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CategoryRuleRenseikaiSection(
                isRenseikai: true,
                isKachinuki: false,
                isNormal: true,
                categoryKey: '一般',
                isRunningTime: true,
                renseikaiType: '一試合制',
                overallTime: 30,
                kachinukiUnlimitedType: '大将対大将',
                onIsRunningTimeChanged: (_) {},
                onRenseikaiTypeChanged: (_) {},
                onOverallTimeChanged: (_) {},
                onKachinukiUnlimitedTypeChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('ランニングタイム計測'), findsOneWidget);
      expect(find.text('進行形式'), findsOneWidget);
      expect(find.text('一試合制'), findsOneWidget);
    });

    testWidgets('CategoryRuleTeamSectionにおいて 団体戦ルール項目が描画されること', (
      WidgetTester tester,
    ) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CategoryRuleTeamSection(
                isLeague: true,
                isNormal: true,
                categoryKey: '一般',
                themeColors: themeColors,
                hasLeagueDaihyo: true,
                isDaihyoIpponShobu: true,
                daihyoMatchTime: 3.0,
                daihyoHasExtension: true,
                daihyoEnchoTime: 3.0,
                daihyoEnchoCount: -2,
                daihyoHasHantei: true,
                winPoint: 3.0,
                lossPoint: 0.0,
                drawPoint: 1.0,
                onHasLeagueDaihyoChanged: (_) {},
                onIsDaihyoIpponShobuChanged: (_) {},
                onDaihyoMatchTimeChanged: (_) {},
                onDaihyoHasExtensionChanged: (_) {},
                onDaihyoEnchoTimeChanged: (_) {},
                onDaihyoEnchoCountChanged: (_) {},
                onDaihyoHasHanteiChanged: (_) {},
                onWinPointChanged: (_) {},
                onLossPointChanged: (_) {},
                onDrawPointChanged: (_) {},
                formatMinutes: (m) => '$m分',
              ),
            ),
          ),
        ),
      );

      expect(find.text('代表戦あり（団体戦用）'), findsOneWidget);
      expect(find.text('１本勝負 (デフォルト)'), findsOneWidget);
      expect(find.text('代表戦の延長を有効にする'), findsOneWidget);
      expect(find.text('代表戦の判定を有効にする'), findsOneWidget);
    });

    testWidgets('CategoryRuleMultiSceneTabsCardにおいて チェックボックスおよびタブビューが描画されること', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CategoryRuleMultiSceneTabsCard(
                useRenseikaiRule: true,
                useHonsenRule: true,
                useMoushiawaseRule: true,
                renseikaiTime: 2.0,
                renseikaiIsRunningTime: true,
                renseikaiHasHantei: true,
                renseikaiType: '一試合制',
                renseikaiOverallTime: 30,
                moushiawaseTime: 2.0,
                moushiawaseIsRunningTime: true,
                moushiawaseHasHantei: true,
                moushiawaseType: '一試合制',
                moushiawaseOverallTime: 30,
                honsenRuleSection: const Text('本戦セクション'),
                onUseRenseikaiRuleChanged: (_) {},
                onUseHonsenRuleChanged: (_) {},
                onUseMoushiawaseRuleChanged: (_) {},
                onRenseikaiTimeChanged: (_) {},
                onRenseikaiRunningChanged: (_) {},
                onRenseikaiHanteiChanged: (_) {},
                onRenseikaiTypeChanged: (_) {},
                onRenseikaiOverallTimeChanged: (_) {},
                onMoushiawaseTimeChanged: (_) {},
                onMoushiawaseRunningChanged: (_) {},
                onMoushiawaseHanteiChanged: (_) {},
                onMoushiawaseTypeChanged: (_) {},
                onMoushiawaseOverallTimeChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('実施するルールシーンの選択'), findsOneWidget);
      expect(find.text('⚔️ 錬成ルール'), findsWidgets);
      expect(find.text('🏆 本戦ルール'), findsWidgets);
      expect(find.text('🤝 申合せルール'), findsWidgets);
    });

    testWidgets('シンプルシーンルールフォームが描画され形式トグルが正常に操作できること', (
      WidgetTester tester,
    ) async {
      double time = 2.0;
      bool isRunning = true;
      bool hasHantei = false;
      String type = '一試合制';
      int overallTime = 30;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return CategorySimpleSceneRuleForm(
                  title: '⚔️ 錬成会ルール',
                  time: time,
                  isRunning: isRunning,
                  hasHantei: hasHantei,
                  renseikaiType: type,
                  overallTime: overallTime,
                  onTimeChanged: (val) => setState(() => time = val),
                  onRunningChanged: (val) => setState(() => isRunning = val),
                  onHanteiChanged: (val) => setState(() => hasHantei = val),
                  onTypeChanged: (val) => setState(() => type = val),
                  onOverallTimeChanged: (val) =>
                      setState(() => overallTime = val),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('⚔️ 錬成会ルール'), findsOneWidget);
      expect(find.text('錬成形式（試合方式）'), findsOneWidget);
      expect(find.text('一試合制'), findsOneWidget);
      expect(find.text('時間制'), findsOneWidget);
      expect(find.text('1試合の時間'), findsOneWidget);
      expect(find.text('流し（タイマーを止めない）'), findsOneWidget);

      await tester.tap(find.text('時間制'));
      await tester.pumpAndSettle();

      expect(type, '時間制');
      expect(find.text('全体の制限時間（分）'), findsOneWidget);
    });

    testWidgets(
      'time stepper tile with タイトル and formatted minutesが正しく描画されること',
      (WidgetTester tester) async {
        double currentTime = 3.0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return CategoryTimeStepperTile(
                    title: '試合時間',
                    subtitle: '1試合の標準時間',
                    value: currentTime,
                    minValue: 1.0,
                    maxValue: 10.0,
                    step: 0.5,
                    onChanged: (val) {
                      setState(() {
                        currentTime = val;
                      });
                    },
                  );
                },
              ),
            ),
          ),
        );

        expect(find.text('試合時間'), findsOneWidget);
        expect(find.text('1試合の標準時間'), findsOneWidget);
        expect(find.text('3分'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        expect(currentTime, 3.5);
        expect(find.text('3分30秒'), findsOneWidget);
      },
    );
  });
}
