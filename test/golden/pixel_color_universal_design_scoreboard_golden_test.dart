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
  group('[Golden] カラーユニバーサルデザイン色覚多様性 スコア表示視覚整合性テスト', () {
    testWidgets('色覚多様性配慮下において赤白記号と打突表示が明瞭に描画されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final now = DateTime(2026, 10, 3, 14, 0);
      final match = MatchModel(
        id: 'golden_cud_pixel_01',
        tournamentId: 't_cud',
        category: '全国選抜選手権',
        matchType: '個人戦',
        status: 'in_progress',
        redName: '佐々木小次郎',
        whiteName: '宮本武蔵',
        redScore: 2,
        whiteScore: 1,
        events: [
          // 赤: 面・小手 (2本)
          ScoreEvent(
            id: 'e_cud_1',
            side: Side.red,
            strikeType: StrikeType.men,
            isIppon: true,
            timestamp: now,
          ),
          ScoreEvent(
            id: 'e_cud_2',
            side: Side.red,
            strikeType: StrikeType.kote,
            isIppon: true,
            timestamp: now.add(const Duration(seconds: 40)),
          ),
          // 白: 胴 (1本) + 反則1回
          ScoreEvent(
            id: 'e_cud_3',
            side: Side.white,
            strikeType: StrikeType.dou,
            isIppon: true,
            timestamp: now.add(const Duration(seconds: 80)),
          ),
          ScoreEvent(
            id: 'e_cud_4',
            side: Side.white,
            isHansoku: true,
            timestamp: now.add(const Duration(seconds: 100)),
          ),
        ],
      );

      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      // CUDシミュレーションを包含するレイアウトツリー
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsProvider.overrideWith(() => _MockSettingsNotifier()),
            matchViewStateUserIdProvider.overrideWith((ref) => 'user_cud'),
            matchListProvider.overrideWithValue([match]),
            scoreboardMatchIdProvider.overrideWithValue('golden_cud_pixel_01'),
            scoreboardMatchProvider.overrideWithValue(match),
            scoreboardNameTapProvider.overrideWithValue((side) {}),
          ],
          child: MaterialApp(
            theme: ThemeData.light().copyWith(extensions: [themeColors]),
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 900,
                  height: 380,
                  child: const MatchScoreboard(),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // スコアボードおよび選手名・打突記号（メ・コ・ド）・反則（▲）の整合描画を検証
      expect(find.byType(MatchScoreboard), findsOneWidget);
      expect(find.text('佐々木小次郎'), findsOneWidget);
      expect(find.text('宮本武蔵'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
