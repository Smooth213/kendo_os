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
  group('🎨 【Widget 3/5】高コントラスト＆アクセシビリティ（文字200%拡大）耐久テスト', () {
    testWidgets('システム文字サイズ200%拡大（TextScaler 2.0）下でも赤白スコアが視認可能でエラーなく描画されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final match = const MatchModel(
        id: 'acc_match_1',
        tournamentId: 't1',
        category: '一般の部',
        matchType: '個人戦',
        status: 'inProgress',
        redName: '神武館:佐藤 剣士',
        whiteName: '修道館:田中 武士',
        redScore: 2,
        whiteScore: 1,
      );

      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsProvider.overrideWith(() => _MockSettingsNotifier()),
            matchViewStateUserIdProvider.overrideWith((ref) => 'user_1'),
            matchListProvider.overrideWithValue([match]),
            scoreboardMatchIdProvider.overrideWithValue('acc_match_1'),
            scoreboardMatchProvider.overrideWithValue(match),
            scoreboardNameTapProvider.overrideWithValue((side) {}),
          ],
          child: MaterialApp(
            theme: ThemeData.light().copyWith(extensions: [themeColors]),
            home: MediaQuery(
              data: const MediaQueryData(
                textScaler: TextScaler.linear(2.0), // システムフォント200%拡大
              ),
              child: const Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 950,
                    height: 500,
                    child: MatchScoreboard(),
                  ),
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
      expect(tester.takeException(), isNull);
    });
  });
}
