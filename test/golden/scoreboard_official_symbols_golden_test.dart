import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/widgets/scoreboard.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_view_state_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/domain/entities/settings_model.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

class _MockSettingsNotifier extends SettingsNotifier {
  @override
  SettingsModel build() =>
      const SettingsModel(securityLevel: 1, enableLiquidGlass: false);
}

void main() {
  group('📸 【Golden 1/5】公式スコアボード 打突記号・勝敗バッジ 視覚的境界整合性テスト', () {
    testWidgets('1. 公式打突記号（メ・コ・先取丸・勝者丸）が厳密なサイズと位置で描画されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final now = DateTime(2026, 9, 3, 12, 0);
      final match = MatchModel(
        id: 'golden_match_1',
        tournamentId: 't1',
        category: '一般の部',
        matchType: '個人戦',
        status: 'finished',
        redName: '神武館:佐藤 剣士',
        whiteName: '修道館:田中 武士',
        redScore: 2,
        whiteScore: 1,
        events: [
          ScoreEvent(
            id: 'e1',
            side: Side.red,
            strikeType: StrikeType.men,
            isIppon: true,
            timestamp: now,
          ),
          ScoreEvent(
            id: 'e2',
            side: Side.white,
            strikeType: StrikeType.kote,
            isIppon: true,
            timestamp: now.add(const Duration(seconds: 30)),
          ),
          ScoreEvent(
            id: 'e3',
            side: Side.red,
            strikeType: StrikeType.dou,
            isIppon: true,
            timestamp: now.add(const Duration(seconds: 60)),
          ),
        ],
      );

      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsProvider.overrideWith(() => _MockSettingsNotifier()),
            matchViewStateUserIdProvider.overrideWith((ref) => 'user_1'),
            matchListProvider.overrideWithValue([match]),
            scoreboardMatchIdProvider.overrideWithValue('golden_match_1'),
            scoreboardMatchProvider.overrideWithValue(match),
            scoreboardNameTapProvider.overrideWithValue((side) {}),
          ],
          child: MaterialApp(
            theme: ThemeData.light().copyWith(extensions: [themeColors]),
            home: const Scaffold(
              body: Center(
                child: SizedBox(
                  width: 900,
                  height: 350,
                  child: MatchScoreboard(),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(MatchScoreboard), findsOneWidget);
      expect(find.text('佐藤 剣士'), findsOneWidget);
      expect(find.text('田中 武士'), findsOneWidget);
    });

    testWidgets('2. 反則打突・ツキを含むスコアボードの境界整合性', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final now = DateTime(2026, 9, 3, 12, 0);
      final match = MatchModel(
        id: 'golden_match_special',
        tournamentId: 't1',
        category: '一般の部',
        matchType: '個人戦',
        status: 'finished',
        redName: '勇武館:高橋',
        whiteName: '正気館:伊藤',
        redScore: 1,
        whiteScore: 0,
        events: [
          ScoreEvent(
            id: 'e_tsuki',
            side: Side.red,
            strikeType: StrikeType.tsuki,
            isIppon: true,
            timestamp: now,
          ),
          ScoreEvent(
            id: 'e_hansoku',
            side: Side.white,
            strikeType: StrikeType.none,
            isHansoku: true,
            isIppon: false,
            timestamp: now.add(const Duration(seconds: 40)),
          ),
        ],
      );

      final themeColors = AppThemeColors.ofMode(isDark: true, mode: 'normal');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsProvider.overrideWith(() => _MockSettingsNotifier()),
            matchViewStateUserIdProvider.overrideWith((ref) => 'user_1'),
            matchListProvider.overrideWithValue([match]),
            scoreboardMatchIdProvider.overrideWithValue('golden_match_special'),
            scoreboardMatchProvider.overrideWithValue(match),
            scoreboardNameTapProvider.overrideWithValue((side) {}),
          ],
          child: MaterialApp(
            theme: ThemeData.dark().copyWith(extensions: [themeColors]),
            home: const Scaffold(
              body: Center(
                child: SizedBox(
                  width: 900,
                  height: 350,
                  child: MatchScoreboard(),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(MatchScoreboard), findsOneWidget);
      expect(find.text('高橋'), findsOneWidget);
      expect(find.text('伊藤'), findsOneWidget);
    });
  });
}
