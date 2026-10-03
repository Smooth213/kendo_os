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
  group('[Golden] 極小画面320pxおよびSafeArea境界 視覚整合性テスト', () {
    testWidgets('極小幅320ピクセルおよびノッチ環境下でスコアボードがはみ出しなく描画されること', (
      WidgetTester tester,
    ) async {
      // iPhone SE (第1世代相当: 320x568)
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final now = DateTime(2026, 10, 3, 10, 0);
      final match = MatchModel(
        id: 'golden_compact_320_01',
        tournamentId: 't_compact',
        category: '少年の部',
        matchType: '個人戦',
        status: 'in_progress',
        redName: '赤選手名長めテスト',
        whiteName: '白選手名長めテスト',
        redScore: 1,
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
        ],
      );

      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsProvider.overrideWith(() => _MockSettingsNotifier()),
            matchViewStateUserIdProvider.overrideWith((ref) => 'user_test'),
            matchListProvider.overrideWithValue([match]),
            scoreboardMatchIdProvider.overrideWithValue(
              'golden_compact_320_01',
            ),
            scoreboardMatchProvider.overrideWithValue(match),
            scoreboardNameTapProvider.overrideWithValue((side) {}),
          ],
          child: MaterialApp(
            theme: ThemeData.light().copyWith(extensions: [themeColors]),
            home: Scaffold(
              body: SafeArea(
                // Dynamic Island やノッチを想定したインセット
                minimum: const EdgeInsets.only(
                  top: 44,
                  bottom: 34,
                  left: 8,
                  right: 8,
                ),
                child: Center(
                  child: SizedBox(
                    width: 304,
                    height: 280,
                    child: const MatchScoreboard(),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // ウィジェットが正常にマウントされ、例外やRenderFlexオーバーフローが発生していないこと
      expect(find.byType(MatchScoreboard), findsOneWidget);
      expect(find.text('赤選手名長めテスト'), findsOneWidget);
      expect(find.text('白選手名長めテスト'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
