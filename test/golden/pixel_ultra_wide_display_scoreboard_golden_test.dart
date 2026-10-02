import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
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
  group('[Golden] 21:9ウルトラワイド解像度スコアボードアスペクト比維持テスト', () {
    testWidgets('2560x1080ウルトラワイド画面においてスコアボードが中央最適化され破綻なく描画されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(2560, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final match = MatchModel(
        id: 'match_ultrawide_01',
        tournamentId: 't_uw_01',
        category: '一般団体の部',
        matchType: '団体戦',
        status: 'in_progress',
        redName: '東京代表 剣道',
        whiteName: '大阪代表 武道',
        redScore: 1,
        whiteScore: 0,
        matchTimeMinutes: 4.0,
      );

      final themeColors = AppThemeColors.ofMode(isDark: true, mode: 'dark');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsProvider.overrideWith(() => _MockSettingsNotifier()),
            matchViewStateUserIdProvider.overrideWith((ref) => 'user_uw'),
            matchListProvider.overrideWithValue([match]),
            scoreboardMatchIdProvider.overrideWithValue('match_ultrawide_01'),
            scoreboardMatchProvider.overrideWithValue(match),
            scoreboardNameTapProvider.overrideWithValue((side) {}),
          ],
          child: MaterialApp(
            theme: ThemeData.dark().copyWith(extensions: [themeColors]),
            home: const Scaffold(
              body: Center(
                child: SizedBox(
                  width: 1400,
                  height: 480,
                  child: MatchScoreboard(),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(MatchScoreboard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
