import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/kata_score_action_section.dart';
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
  group('[Golden] 形・基本技スコアボード＆操作パネル ピクセル・視覚整合性テスト', () {
    const kataRule = MatchRule(
      isKataMatch: true,
      matchTimeMinutes: 0,
      isRunningTime: false,
      hasHantei: true,
    );

    testWidgets('形試合スコアボード（特大旗スコア表示「3 - 0」）がライト＆ダークモードで崩れなく描画されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final match = MatchModel(
        id: 'golden_kata_scoreboard_01',
        tournamentId: 'tour_kata',
        category: '小学生の部',
        matchType: '決勝',
        status: 'finished',
        redName: '田中・山田',
        whiteName: '佐藤・高橋',
        rule: kataRule,
        redScore: 3,
        whiteScore: 0,
        events: [
          ScoreEvent(
            id: 'e1',
            side: Side.red,
            isHantei: true,
            redFlags: 3,
            whiteFlags: 0,
            timestamp: DateTime(2026, 10, 11, 10, 0),
          ),
        ],
      );

      for (final isDark in [false, true]) {
        final themeColors = AppThemeColors.ofMode(
          isDark: isDark,
          mode: 'normal',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              settingsProvider.overrideWith(() => _MockSettingsNotifier()),
              matchViewStateUserIdProvider.overrideWith((ref) => 'user_1'),
              matchListProvider.overrideWithValue([match]),
              scoreboardMatchIdProvider.overrideWithValue(
                'golden_kata_scoreboard_01',
              ),
              scoreboardMatchProvider.overrideWithValue(match),
              scoreboardNameTapProvider.overrideWithValue((side) {}),
            ],
            child: MaterialApp(
              theme: (isDark ? ThemeData.dark() : ThemeData.light()).copyWith(
                extensions: [themeColors],
              ),
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
        expect(find.text('田中・山田'), findsOneWidget);
        expect(find.text('佐藤・高橋'), findsOneWidget);
        // 特大旗判定スコアの描画確認
        expect(find.text('3'), findsOneWidget);
        expect(find.text('0'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets(
      'KataScoreActionSection（審判3名旗判定ボタン群 ＆ 不戦勝ボタン）がモバイル幅で崩れなく描画されること',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        for (final isDark in [false, true]) {
          final themeColors = AppThemeColors.ofMode(
            isDark: isDark,
            mode: 'normal',
          );

          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                theme: (isDark ? ThemeData.dark() : ThemeData.light()).copyWith(
                  extensions: [themeColors],
                ),
                home: Scaffold(
                  body: Center(
                    child: KataScoreActionSection(
                      matchId: 'match_golden_action_01',
                      isInputLocked: false,
                      isDark: isDark,
                      hasEvents: false,
                    ),
                  ),
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();

          expect(find.byType(KataScoreActionSection), findsOneWidget);
          expect(find.text('赤 3 - 0 白'), findsOneWidget);
          expect(find.text('赤 2 - 1 白'), findsOneWidget);
          expect(find.text('赤 1 - 2 白'), findsOneWidget);
          expect(find.text('赤 0 - 3 白'), findsOneWidget);
          expect(find.text('赤 不戦勝'), findsOneWidget);
          expect(find.text('白 不戦勝'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      },
    );
  });
}
