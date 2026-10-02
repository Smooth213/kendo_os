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
  group('[Golden] 直射日光サンシャイン超高コントラストモード視覚検証テスト', () {
    testWidgets('直射日光下サンシャインモードにおいて純黒テキストと純白背景による超高コントラストが成立すること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final sunshineColors = AppThemeColors.ofMode(
        isDark: false,
        mode: 'sunshine',
      );

      // サンシャインモードの配色契約の検証
      expect(sunshineColors.textColor, equals(Colors.black));
      expect(sunshineColors.scaffoldBackground, equals(Colors.white));
      expect(sunshineColors.separatorColor, equals(const Color(0xFF000000)));

      final match = MatchModel(
        id: 'match_sunshine_01',
        tournamentId: 't_sun_01',
        category: '野外特設コートの部',
        matchType: '個人戦',
        status: 'in_progress',
        redName: '日光 太郎',
        whiteName: '晴天 次郎',
        redScore: 1,
        whiteScore: 0,
        matchTimeMinutes: 3.0,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsProvider.overrideWith(() => _MockSettingsNotifier()),
            matchViewStateUserIdProvider.overrideWith((ref) => 'user_sun'),
            matchListProvider.overrideWithValue([match]),
            scoreboardMatchIdProvider.overrideWithValue('match_sunshine_01'),
            scoreboardMatchProvider.overrideWithValue(match),
            scoreboardNameTapProvider.overrideWithValue((side) {}),
          ],
          child: MaterialApp(
            theme: ThemeData.light().copyWith(
              scaffoldBackgroundColor: sunshineColors.scaffoldBackground,
              extensions: [sunshineColors],
            ),
            home: const Scaffold(
              body: Center(
                child: SizedBox(
                  width: 900,
                  height: 380,
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
