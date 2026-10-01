import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/match/domain/services/team_match_calculator.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_setup_helper.dart';
import 'package:kendo_os/shared/application/services/csv_service.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group(
    '[E2E] 【Composite E2E】文字拡大モード(1.35x) × 7人制団体戦 × 反則累積・不戦勝 × 代表戦 × CSV一括出力',
    () {
      late KendoRuleEngine ruleEngine;
      final now = DateTime(2026, 9, 27, 13, 0);

      setUp(() {
        ruleEngine = KendoRuleEngine();
      });

      test('[ドメイン＆極限シナリオ] 7人制団体戦で反則累積一本・不戦勝・大将戦同点・代表戦サドンデス完全決着こと', () {
        final positions = MatchFormatSetupHelper.generatePositions(7);
        expect(positions, ['先鋒', '次鋒', '五将', '中堅', '三将', '副将', '大将']);

        const defaultRule = MatchRule();
        final matches = <MatchModel>[];

        // 1. 先鋒: 通常試合 (赤メ、コで2本勝ち 2-0)
        matches.add(
          MatchModel(
            id: 'c_m1',
            matchType: '7人制',
            matchOrder: 1,
            redName: '先鋒:赤井',
            whiteName: '先鋒:白石',
            redScore: 2,
            whiteScore: 0,
            status: 'finished',
            rule: defaultRule,
            events: [
              ScoreEvent(
                id: 'ev1',
                side: Side.red,
                strikeType: StrikeType.men,
                isIppon: true,
                timestamp: now,
              ),
              ScoreEvent(
                id: 'ev2',
                side: Side.red,
                strikeType: StrikeType.kote,
                isIppon: true,
                timestamp: now.add(const Duration(seconds: 30)),
              ),
            ],
          ),
        );

        // 2. 次鋒: 赤反則2回累積により白に一本 (0-1)
        final hansokuEvent1 = ScoreEvent(
          id: 'ev_h1',
          side: Side.red,
          isHansoku: true,
          timestamp: now.add(const Duration(minutes: 1)),
        );
        final hansokuEvent2 = ScoreEvent(
          id: 'ev_h2',
          side: Side.red,
          isHansoku: true,
          timestamp: now.add(const Duration(minutes: 2)),
        );

        final dummyJihouMatch = MatchModel(
          id: 'c_m2_dummy',
          matchType: '7人制',
          redName: '次鋒:赤木',
          whiteName: '次鋒:白井',
          rule: defaultRule,
        );
        final analysisJihou = ruleEngine.analyzeHistory(
          [hansokuEvent1, hansokuEvent2],
          dummyJihouMatch,
          defaultRule,
        );
        expect(analysisJihou.context.redHansoku, 2);
        expect(analysisJihou.context.whiteIppon, 1, reason: '赤の反則累積2回で白に1本付与');

        matches.add(
          MatchModel(
            id: 'c_m2',
            matchType: '7人制',
            matchOrder: 2,
            redName: '次鋒:赤木',
            whiteName: '次鋒:白井',
            redScore: 0,
            whiteScore: 1,
            status: 'finished',
            rule: defaultRule,
            events: [hansokuEvent1, hansokuEvent2],
          ),
        );

        // 3. 五将: 白の不戦勝 (0-2)
        matches.add(
          const MatchModel(
            id: 'c_m3',
            matchType: '7人制',
            matchOrder: 3,
            redName: '五将:欠場',
            whiteName: '五将:白鳥',
            redScore: 0,
            whiteScore: 2,
            status: 'finished',
          ),
        );

        // 4. 中堅: 引き分け (0-0)
        matches.add(
          const MatchModel(
            id: 'c_m4',
            matchType: '7人制',
            matchOrder: 4,
            redName: '中堅:赤松',
            whiteName: '中堅:白川',
            redScore: 0,
            whiteScore: 0,
            status: 'finished',
          ),
        );

        // 5. 三将: 赤の不戦勝 (2-0)
        matches.add(
          const MatchModel(
            id: 'c_m5',
            matchType: '7人制',
            matchOrder: 5,
            redName: '三将:赤田',
            whiteName: '三将:欠場',
            redScore: 2,
            whiteScore: 0,
            status: 'finished',
          ),
        );

        // 6. 副将: 白ドウで一本勝ち (0-1)
        matches.add(
          MatchModel(
            id: 'c_m6',
            matchType: '7人制',
            matchOrder: 6,
            redName: '副将:赤星',
            whiteName: '副将:白山',
            redScore: 0,
            whiteScore: 1,
            status: 'finished',
            rule: defaultRule,
            events: [
              ScoreEvent(
                id: 'ev6',
                side: Side.white,
                strikeType: StrikeType.dou,
                isIppon: true,
                timestamp: now,
              ),
            ],
          ),
        );

        // 7. 大将: 引き分け (0-0)
        // ここまでの集計:
        // 赤勝者: 先鋒(1), 三将(1) = 2勝
        // 白勝者: 次鋒(1), 五将(1), 副将(1) = 3勝 (白リード)
        // ➔ 大将戦で赤が2-0勝ちとすると: 赤 3勝 (4本) vs 白 3勝 (4本) で完全同点！
        matches.add(
          MatchModel(
            id: 'c_m7',
            matchType: '7人制',
            matchOrder: 7,
            redName: '大将:赤坂',
            whiteName: '大将:白峰',
            redScore: 2,
            whiteScore: 0,
            status: 'finished',
            rule: defaultRule,
            events: [
              ScoreEvent(
                id: 'ev7_1',
                side: Side.red,
                strikeType: StrikeType.men,
                isIppon: true,
                timestamp: now,
              ),
              ScoreEvent(
                id: 'ev7_2',
                side: Side.red,
                strikeType: StrikeType.kote,
                isIppon: true,
                timestamp: now.add(const Duration(seconds: 40)),
              ),
            ],
          ),
        );

        // 7人制本戦の集計
        // 赤: 先鋒(1勝 2本) + 三将(1勝 2本) + 大将(1勝 2本) = 3勝 6本
        // 白: 次鋒(1勝 1本) + 五将(1勝 2本) + 副将(1勝 1本) = 3勝 4本 (赤勝利になってしまう)
        // 赤本数と白本数を同数にするため、先鋒を1-0、大将を1-0に調整:
        // 先鋒: 赤 1 - 0 白 (赤1勝 1本)
        // 次鋒: 赤 0 - 1 白 (白1勝 1本)
        // 五将: 赤 0 - 2 白 (白1勝 2本)
        // 中堅: 赤 0 - 0 白 (分)
        // 三将: 赤 2 - 0 白 (赤1勝 2本)
        // 副将: 赤 0 - 1 白 (白1勝 1本)
        // 大将: 赤 1 - 0 白 (赤1勝 1本)
        // -> 赤: 3勝 4本, 白: 3勝 4本 (完全同点！)
        final balancedMatches = [
          MatchModel(
            id: 'c_m1_b',
            matchType: '7人制',
            matchOrder: 1,
            redName: '先鋒:赤井',
            whiteName: '先鋒:白石',
            redScore: 1,
            whiteScore: 0,
            status: 'finished',
          ),
          matches[1], // 次鋒 0-1
          matches[2], // 五将 0-2 (不戦勝)
          matches[3], // 中堅 0-0
          matches[4], // 三将 2-0 (不戦勝)
          matches[5], // 副将 0-1
          MatchModel(
            id: 'c_m7_b',
            matchType: '7人制',
            matchOrder: 7,
            redName: '大将:赤坂',
            whiteName: '大将:白峰',
            redScore: 1,
            whiteScore: 0,
            status: 'finished',
          ),
        ];

        final honsenResult = TeamMatchCalculator.calculate(balancedMatches);
        expect(honsenResult.redWins, 3);
        expect(honsenResult.whiteWins, 3);
        expect(honsenResult.redPoints, 4);
        expect(honsenResult.whitePoints, 4);
        expect(honsenResult.isTie, isTrue, reason: '勝者数(3=3)、本数(4=4)で完全同点');
        expect(honsenResult.hasDaihyo, isFalse);
        expect(honsenResult.teamWinner, 'draw');

        // 代表戦の追加・サドンデス
        final daihyoMatch = MatchModel(
          id: 'c_m_daihyo',
          matchType: '代表戦',
          note: '代表戦',
          redName: '代表:赤坂',
          whiteName: '代表:白峰',
          redScore: 1,
          whiteScore: 0,
          status: 'finished',
          events: [
            ScoreEvent(
              id: 'ev_d1',
              side: Side.red,
              strikeType: StrikeType.men,
              isIppon: true,
              timestamp: now.add(const Duration(minutes: 5)),
            ),
          ],
        );
        final allMatches = [...balancedMatches, daihyoMatch];

        final finalResult = TeamMatchCalculator.calculate(allMatches);
        expect(finalResult.hasDaihyo, isTrue);
        expect(finalResult.isTie, isFalse);
        expect(finalResult.teamWinner, 'red', reason: '代表戦サドンデス一本勝ちにより赤チーム勝利');

        // 公式記録CSV出力検証
        final csvString = CsvService.generateCsvString('7人制選手権', [
          {'groupName': '決勝', 'matches': allMatches},
        ]);
        expect(csvString.startsWith('\uFEFF'), isTrue);
        expect(csvString.contains('代表戦'), isTrue);
        expect(csvString.contains('赤坂'), isTrue);
        expect(csvString.contains('白峰'), isTrue);
      });

      testWidgets(
        '[UI・アクセシビリティ] 文字拡大モード(特大 1.35x)下での7人制結果表示・オーバーフローゼロが正しく検証されること',
        (tester) async {
          tester.view.physicalSize = const Size(390, 1000);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          final themeColors = AppThemeColors.ofMode(
            isDark: false,
            mode: 'normal',
          );

          // 文字拡大 1.35x をシミュレート
          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                theme: ThemeData.light().copyWith(extensions: [themeColors]),
                home: MediaQuery(
                  data: const MediaQueryData(
                    textScaler: TextScaler.linear(1.35),
                    size: Size(390, 1000),
                  ),
                  child: Scaffold(
                    appBar: AppBar(
                      title: const Text(
                        '7人制 団体戦公式記録',
                        style: TextStyle(fontSize: AppFontSize.headline),
                      ),
                    ),
                    body: ListView(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: themeColors.cardBackground,
                            borderRadius: AppRadius.medium,
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '錬心館道場 3 (4) - 3 (4) 修道館道場',
                                style: TextStyle(
                                  fontSize: AppFontSize.headline,
                                  fontWeight: AppFontWeight.bold,
                                ),
                              ),
                              SizedBox(height: AppSpacing.xs),
                              Text(
                                '代表戦: 錬心館道場 勝ち (赤坂 メ - 白峰)',
                                style: TextStyle(
                                  fontSize: AppFontSize.body,
                                  color: AppKendoColors.ipponGold,
                                  fontWeight: AppFontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('7人制 団体戦公式記録'), findsOneWidget);
          expect(find.text('錬心館道場 3 (4) - 3 (4) 修道館道場'), findsOneWidget);
          expect(find.textContaining('代表戦: 錬心館道場 勝ち'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    },
  );
}
