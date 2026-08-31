import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/shared/domain/entities/settings_model.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/timer_widget.dart';
import '../helpers/test_app.dart';

class MockSettingsNotifier extends SettingsNotifier {
  @override
  SettingsModel build() =>
      const SettingsModel(securityLevel: 1, enableLiquidGlass: false);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testMatchRunning = MatchModel(
    id: 'test_match_running',
    matchType: '個人戦',
    tournamentId: 't1',
    category: '小学生',
    redName: '赤選手',
    whiteName: '白選手',
    status: 'in_progress',
    timerStartedAt: DateTime.now(),
  );

  final testMatchStopped = MatchModel(
    id: 'test_match_stopped',
    matchType: '個人戦',
    tournamentId: 't1',
    category: '小学生',
    redName: '赤選手',
    whiteName: '白選手',
    status: 'in_progress',
  );

  group('⏱️ TimerWidget ライト＆ダークモード視認性コントラスト完全保証テスト', () {
    testWidgets('【ライトモード・動作中】赤背景において、テキストおよびアイコンが純白(pureWhite)で描画されること', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          Theme(
            data: ThemeData.light().copyWith(
              extensions: [
                AppThemeColors.ofMode(isDark: false, mode: 'normal'),
              ],
            ),
            child: const Scaffold(
              body: Center(
                child: TimerWidget(
                  matchId: 'test_match_running',
                  isInputLocked: false,
                ),
              ),
            ),
          ),
          overrides: [
            matchListProvider.overrideWith((ref) => [testMatchRunning]),
            settingsProvider.overrideWith(() => MockSettingsNotifier()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final textWidget = tester.widget<Text>(find.byType(Text).first);
      expect(textWidget.style?.color, AppKendoColors.pureWhite);

      final iconWidget = tester.widget<Icon>(find.byType(Icon).first);
      expect(iconWidget.color, AppKendoColors.pureWhite);
    });

    testWidgets('【ダークモード・動作中】暗赤背景において、テキストおよびアイコンが純白(pureWhite)で描画されること', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          Theme(
            data: ThemeData.dark().copyWith(
              extensions: [AppThemeColors.ofMode(isDark: true, mode: 'normal')],
            ),
            child: const Scaffold(
              body: Center(
                child: TimerWidget(
                  matchId: 'test_match_running',
                  isInputLocked: false,
                ),
              ),
            ),
          ),
          overrides: [
            matchListProvider.overrideWith((ref) => [testMatchRunning]),
            settingsProvider.overrideWith(() => MockSettingsNotifier()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final textWidget = tester.widget<Text>(find.byType(Text).first);
      expect(textWidget.style?.color, AppKendoColors.pureWhite);

      final iconWidget = tester.widget<Icon>(find.byType(Icon).first);
      expect(iconWidget.color, AppKendoColors.pureWhite);
    });

    testWidgets('【ライトモード・停止中】白背景において、テキストがtextColor(黒)、アイコンがインディゴブルーで描画されること', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          Theme(
            data: ThemeData.light().copyWith(
              extensions: [
                AppThemeColors.ofMode(isDark: false, mode: 'normal'),
              ],
            ),
            child: const Scaffold(
              body: Center(
                child: TimerWidget(
                  matchId: 'test_match_stopped',
                  isInputLocked: false,
                ),
              ),
            ),
          ),
          overrides: [
            matchListProvider.overrideWith((ref) => [testMatchStopped]),
            settingsProvider.overrideWith(() => MockSettingsNotifier()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final textWidget = tester.widget<Text>(find.byType(Text).first);
      expect(textWidget.style?.color, const Color(0xFF000000));

      final iconWidget = tester.widget<Icon>(find.byType(Icon).first);
      expect(iconWidget.color, const Color(0xFF3F51B5));
    });

    testWidgets(
      '【ダークモード・停止中】暗色背景において、テキストがtextColor(白)、アイコンが高視認性インディゴで描画されること',
      (tester) async {
        await tester.pumpWidget(
          createTestApp(
            Theme(
              data: ThemeData.dark().copyWith(
                extensions: [
                  AppThemeColors.ofMode(isDark: true, mode: 'normal'),
                ],
              ),
              child: const Scaffold(
                body: Center(
                  child: TimerWidget(
                    matchId: 'test_match_stopped',
                    isInputLocked: false,
                  ),
                ),
              ),
            ),
            overrides: [
              matchListProvider.overrideWith((ref) => [testMatchStopped]),
              settingsProvider.overrideWith(() => MockSettingsNotifier()),
            ],
          ),
        );
        await tester.pumpAndSettle();

        final textWidget = tester.widget<Text>(find.byType(Text).first);
        expect(textWidget.style?.color, const Color(0xFFFFFFFF));

        final iconWidget = tester.widget<Icon>(find.byType(Icon).first);
        expect(iconWidget.color, const Color(0xFF5C6BC0));
      },
    );
  });
}
