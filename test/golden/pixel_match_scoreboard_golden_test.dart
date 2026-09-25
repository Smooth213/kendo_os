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
  group('📸 【Golden】公式スコアボード（打突記号・旗色・タイマー）ピクセル・視覚整合性テスト', () {
    testWidgets('1. 公式打突記号（メ・コ・反・先取◯）とタイマーのレイアウト検証', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final now = DateTime(2026, 9, 25, 14, 0);
      final match = MatchModel(
        id: 'golden_scoreboard_pixel_01',
        tournamentId: 't1',
        category: '一般男子の部',
        matchType: '個人戦',
        status: 'finished',
        redName: '剣道太郎',
        whiteName: '武道次郎',
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
            timestamp: now.add(const Duration(seconds: 45)),
          ),
          ScoreEvent(
            id: 'e3',
            side: Side.red,
            strikeType: StrikeType.dou,
            isIppon: true,
            timestamp: now.add(const Duration(seconds: 90)),
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
            scoreboardMatchIdProvider.overrideWithValue(
              'golden_scoreboard_pixel_01',
            ),
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
      expect(find.text('剣道太郎'), findsOneWidget);
      expect(find.text('武道次郎'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
