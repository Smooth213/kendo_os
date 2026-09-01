import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/rules/sections/match_rule_daihyo_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/rules/sections/match_rule_dialog_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/rules/sections/match_rule_encho_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/rules/sections/match_rule_hantei_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/rules/sections/match_rule_special_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/rules/sections/match_rule_time_section.dart';
import 'package:kendo_os/shared/presentation/widgets/kendo_scene_badge.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestableApp({required Widget child, bool isDark = false}) {
    final themeData = ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      splashFactory: NoSplash.splashFactory,
      extensions: [AppThemeColors.ofMode(isDark: isDark, mode: 'normal')],
    );

    return MaterialApp(
      theme: themeData,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
  }

  String formatMinutes(double minutes) {
    if (minutes == 0.0) return '時間制限なし';
    final int m = minutes.toInt();
    final int s = ((minutes % 1) * 60).round();
    if (s == 0) return '$m分';
    if (m == 0) return '$s秒';
    return '$m分$s秒';
  }

  group('🥋 Refactored MatchRule Sections Widget Tests', () {
    testWidgets('1. MatchRuleTimeSection: 試合時間・進行形式・計測方式・勝負形式が操作可能であること', (
      WidgetTester tester,
    ) async {
      double matchTime = 3.0;
      bool isRunningTime = false;
      bool isIpponShobu = false;
      int ipponLimit = 2;
      int hansokuLimit = 2;
      String renseikaiType = '一試合制';

      await tester.pumpWidget(
        buildTestableApp(
          child: StatefulBuilder(
            builder: (context, setState) {
              return MatchRuleTimeSection(
                matchTime: matchTime,
                isRunningTime: isRunningTime,
                isIpponShobu: isIpponShobu,
                ipponLimit: ipponLimit,
                hansokuLimit: hansokuLimit,
                renseikaiType: renseikaiType,
                primaryAccent: KendoSceneHelper.getColor(
                  KendoMatchScene.honsen,
                ),
                isDark: false,
                formatMinutes: formatMinutes,
                onMatchTimeChanged: (v) => setState(() => matchTime = v),
                onRunningTimeChanged: (v) => setState(() => isRunningTime = v),
                onIpponShobuChanged: (v) => setState(() => isIpponShobu = v),
                onIpponLimitChanged: (v) => setState(() => ipponLimit = v),
                onHansokuLimitChanged: (v) => setState(() => hansokuLimit = v),
                onRenseikaiTypeChanged: (v) =>
                    setState(() => renseikaiType = v),
              );
            },
          ),
        ),
      );

      expect(find.text('⏱️ 試合時間 ＆ 基本形式'), findsOneWidget);
      expect(find.text('一試合制 (デフォルト)'), findsOneWidget);
      expect(find.text('時間制'), findsOneWidget);

      // 時間制に切り替え
      await tester.tap(find.text('時間制'));
      await tester.pumpAndSettle();
      expect(renseikaiType, '時間制');

      // 4分タップ
      await tester.tap(find.text('4分'));
      await tester.pumpAndSettle();
      expect(matchTime, 4.0);
    });

    testWidgets('2. MatchRuleEnchoSection: 延長戦トグル・延長時間チップ・無制限スイッチが動作すること', (
      WidgetTester tester,
    ) async {
      bool hasExtension = false;
      double enchoTime = 2.0;
      int enchoCount = 1;
      bool isEnchoUnlimited = false;

      await tester.pumpWidget(
        buildTestableApp(
          child: StatefulBuilder(
            builder: (context, setState) {
              return MatchRuleEnchoSection(
                hasExtension: hasExtension,
                enchoTime: enchoTime,
                enchoCount: enchoCount,
                isEnchoUnlimited: isEnchoUnlimited,
                primaryAccent: KendoSceneHelper.getColor(
                  KendoMatchScene.honsen,
                ),
                isDark: false,
                formatMinutes: formatMinutes,
                onExtensionChanged: (v) => setState(() => hasExtension = v),
                onEnchoTimeChanged: (v) => setState(() => enchoTime = v),
                onEnchoCountChanged: (v) => setState(() => enchoCount = v),
                onEnchoUnlimitedChanged: (v) =>
                    setState(() => isEnchoUnlimited = v),
              );
            },
          ),
        ),
      );

      expect(find.text('🔄 延長戦ルール'), findsOneWidget);
      expect(find.text('延長戦を行う'), findsOneWidget);

      // 延長戦をON
      await tester.tap(find.text('延長戦を行う'));
      await tester.pumpAndSettle();
      expect(hasExtension, true);

      // 3分を選択
      await tester.tap(find.text('3分'));
      await tester.pumpAndSettle();
      expect(enchoTime, 3.0);
    });

    testWidgets('3. MatchRuleHanteiSection: 判定トグルが動作すること', (
      WidgetTester tester,
    ) async {
      bool hasHantei = false;

      await tester.pumpWidget(
        buildTestableApp(
          child: StatefulBuilder(
            builder: (context, setState) {
              return MatchRuleHanteiSection(
                hasHantei: hasHantei,
                primaryAccent: KendoSceneHelper.getColor(
                  KendoMatchScene.honsen,
                ),
                isDark: false,
                onHanteiChanged: (v) => setState(() => hasHantei = v),
              );
            },
          ),
        ),
      );

      expect(find.text('⚖️ 判定（ハンテイ）ルール'), findsOneWidget);
      expect(find.text('判定の適用'), findsOneWidget);

      await tester.tap(find.text('判定の適用'));
      await tester.pumpAndSettle();
      expect(hasHantei, true);
    });

    testWidgets('4. MatchRuleDaihyoSection: 団体戦ON時に代表戦詳細設定が展開されること', (
      WidgetTester tester,
    ) async {
      bool hasRepresentativeMatch = true;
      bool isDaihyoIpponShobu = true;
      double daihyoMatchTime = 0.0;
      bool daihyoHasExtension = true;
      double daihyoEnchoTime = 3.0;
      int daihyoEnchoCount = -2;
      bool isDaihyoEnchoUnlimited = true;
      bool daihyoHasHantei = false;

      await tester.pumpWidget(
        buildTestableApp(
          child: StatefulBuilder(
            builder: (context, setState) {
              return MatchRuleDaihyoSection(
                isDantai: true,
                hasRepresentativeMatch: hasRepresentativeMatch,
                isDaihyoIpponShobu: isDaihyoIpponShobu,
                daihyoMatchTime: daihyoMatchTime,
                daihyoHasExtension: daihyoHasExtension,
                daihyoEnchoTime: daihyoEnchoTime,
                daihyoEnchoCount: daihyoEnchoCount,
                isDaihyoEnchoUnlimited: isDaihyoEnchoUnlimited,
                daihyoHasHantei: daihyoHasHantei,
                primaryAccent: KendoSceneHelper.getColor(
                  KendoMatchScene.honsen,
                ),
                isDark: false,
                formatMinutes: formatMinutes,
                onRepresentativeMatchChanged: (v) =>
                    setState(() => hasRepresentativeMatch = v),
                onDaihyoIpponShobuChanged: (v) =>
                    setState(() => isDaihyoIpponShobu = v),
                onDaihyoMatchTimeChanged: (v) =>
                    setState(() => daihyoMatchTime = v),
                onDaihyoExtensionChanged: (v) =>
                    setState(() => daihyoHasExtension = v),
                onDaihyoEnchoTimeChanged: (v) =>
                    setState(() => daihyoEnchoTime = v),
                onDaihyoEnchoCountChanged: (v) =>
                    setState(() => daihyoEnchoCount = v),
                onDaihyoEnchoUnlimitedChanged: (v) =>
                    setState(() => isDaihyoEnchoUnlimited = v),
                onDaihyoHanteiChanged: (v) =>
                    setState(() => daihyoHasHantei = v),
              );
            },
          ),
        ),
      );

      expect(find.text('🥋 団体戦・代表戦ルール'), findsOneWidget);
      expect(find.text('代表戦 詳細設定'), findsOneWidget);
      expect(find.text('代表戦は一本勝負'), findsOneWidget);
      expect(find.text('代表戦の延長戦を行う'), findsOneWidget);
    });

    testWidgets('5. MatchRuleSpecialSection: 勝ち抜き戦・リーグ勝ち点が設定可能であること', (
      WidgetTester tester,
    ) async {
      bool isKachinuki = true;
      String kachinukiUnlimitedType = '大将対大将';
      bool isLeague = true;
      double winPoint = 3.0;
      double lossPoint = 0.0;
      double drawPoint = 1.0;

      await tester.pumpWidget(
        buildTestableApp(
          child: StatefulBuilder(
            builder: (context, setState) {
              return MatchRuleSpecialSection(
                isKachinuki: isKachinuki,
                kachinukiUnlimitedType: kachinukiUnlimitedType,
                isLeague: isLeague,
                winPoint: winPoint,
                lossPoint: lossPoint,
                drawPoint: drawPoint,
                primaryAccent: KendoSceneHelper.getColor(
                  KendoMatchScene.honsen,
                ),
                isDark: false,
                onKachinukiChanged: (v) => setState(() => isKachinuki = v),
                onKachinukiUnlimitedTypeChanged: (v) =>
                    setState(() => kachinukiUnlimitedType = v),
                onLeagueChanged: (v) => setState(() => isLeague = v),
                onWinPointChanged: (v) => setState(() => winPoint = v),
                onLossPointChanged: (v) => setState(() => lossPoint = v),
                onDrawPointChanged: (v) => setState(() => drawPoint = v),
              );
            },
          ),
        ),
      );

      expect(find.text('⚔️ 特殊形式 ＆ リーグ順位決定ルール'), findsOneWidget);
      expect(find.text('勝ち抜き戦形式'), findsOneWidget);
      expect(find.text('リーグ戦（勝点集計ルール）'), findsOneWidget);
    });

    testWidgets('6. MatchRuleDialogHelper: カスタム時間ダイアログが正しく表示・入力・決定できること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      double selectedTime = 0.0;

      await tester.pumpWidget(
        buildTestableApp(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => MatchRuleDialogHelper.showCustomTimeDialog(
                context,
                title: 'カスタム時間テスト',
                currentTime: 2.5,
                onConfirmed: (v) => selectedTime = v,
              ),
              child: const Text('ダイアログを開く'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('ダイアログを開く'));
      await tester.pumpAndSettle();

      expect(find.text('カスタム時間テスト'), findsOneWidget);
      expect(find.text('決定'), findsOneWidget);

      await tester.tap(find.text('決定'));
      await tester.pumpAndSettle();

      expect(selectedTime, 2.5);
    });
  });
}
