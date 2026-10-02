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
  group('[Golden] 団体戦 代表戦突入ダイアログ＆代表戦専用スコアボード ピクセル視覚完全性テスト', () {
    testWidgets('代表戦（無制限一本勝負）スコアボードのピクセル配置と視認性が検証されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final daihyoMatch = MatchModel(
        id: 'daihyo_match_01',
        tournamentId: 't_team_01',
        category: '高校団体の部',
        matchType: '代表戦',
        status: 'in_progress',
        redName: '剣道太郎 (代表)',
        whiteName: '武道次郎 (代表)',
        redScore: 0,
        whiteScore: 0,
        order: 99.0,
        matchTimeMinutes: 0.0,
      );

      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsProvider.overrideWith(() => _MockSettingsNotifier()),
            matchViewStateUserIdProvider.overrideWith((ref) => 'user_1'),
            matchListProvider.overrideWithValue([daihyoMatch]),
            scoreboardMatchIdProvider.overrideWithValue('daihyo_match_01'),
            scoreboardMatchProvider.overrideWithValue(daihyoMatch),
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
      expect(find.text('剣道太郎 (代表)'), findsOneWidget);
      expect(find.text('武道次郎 (代表)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
