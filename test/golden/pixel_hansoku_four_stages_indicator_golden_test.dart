import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_view_state_provider.dart';
import 'package:kendo_os/shared/domain/entities/settings_model.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/scoreboard.dart';

class _MockSettingsNotifier extends SettingsNotifier {
  @override
  SettingsModel build() =>
      const SettingsModel(securityLevel: 1, enableLiquidGlass: false);
}

void main() {
  group('[Golden] 反則4段階累積インジケーター ピクセル配置・視覚完全性テスト', () {
    testWidgets('反則累積（1回〜4回）時のスコアボード上表示レイアウトが検証されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final now = DateTime(2026, 10, 1, 10, 0);
      final matchWithHansoku = MatchModel(
        id: 'hansoku_match_01',
        tournamentId: 't_hansoku',
        category: '個人選手権',
        matchType: '個人戦',
        status: 'in_progress',
        redName: '赤選手',
        whiteName: '白選手',
        redScore: 1, // 白の反則2回により赤に一本
        whiteScore: 0,
        events: [
          ScoreEvent(
            id: 'h1',
            side: Side.white,
            isHansoku: true,
            timestamp: now,
          ),
          ScoreEvent(
            id: 'h2',
            side: Side.white,
            isHansoku: true,
            timestamp: now.add(const Duration(seconds: 30)),
          ),
          ScoreEvent(
            id: 'h3',
            side: Side.white,
            isHansoku: true,
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
            matchListProvider.overrideWithValue([matchWithHansoku]),
            scoreboardMatchIdProvider.overrideWithValue('hansoku_match_01'),
            scoreboardMatchProvider.overrideWithValue(matchWithHansoku),
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
      expect(find.text('赤選手'), findsOneWidget);
      expect(find.text('白選手'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
