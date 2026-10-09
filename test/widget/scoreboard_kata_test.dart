import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_view_state_provider.dart';
import 'package:kendo_os/shared/domain/entities/settings_model.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/widgets/scoreboard.dart';

class MockSettingsNotifier extends SettingsNotifier {
  @override
  SettingsModel build() =>
      const SettingsModel(securityLevel: 1, enableLiquidGlass: false);
}

void main() {
  group('[Widget] Scoreboard 形試合表示検証', () {
    testWidgets('形試合の場合にスコアボード中央に旗数判定が表示されること', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final testMatch = MatchModel(
        id: 'test_kata_match',
        tournamentId: 'tour_kata_1',
        category: '形・一般',
        redName: '山田・佐藤',
        whiteName: '鈴木・田中',
        matchType: '個人戦',
        status: 'finished',
        redScore: 2,
        whiteScore: 1,
        rule: const MatchRule(isKataMatch: true),
        events: [
          ScoreEvent(
            id: 'ev_kata_1',
            side: Side.red,
            timestamp: DateTime.now(),
            isHantei: true,
            redFlags: 2,
            whiteFlags: 1,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsProvider.overrideWith(() => MockSettingsNotifier()),
            matchViewStateUserIdProvider.overrideWith((ref) => 'test_user_id'),
            currentDojoIdProvider.overrideWith((ref) => 'test_dojo'),
            matchListProvider.overrideWithValue([testMatch]),
            scoreboardMatchIdProvider.overrideWithValue('test_kata_match'),
            scoreboardMatchProvider.overrideWithValue(testMatch),
            scoreboardNameTapProvider.overrideWithValue((side) {}),
          ],
          child: const MaterialApp(home: Scaffold(body: MatchScoreboard())),
        ),
      );

      await tester.pumpAndSettle();

      // ペア名が表示されていること
      expect(find.text('山田・佐藤'), findsOneWidget);
      expect(find.text('鈴木・田中'), findsOneWidget);

      // スコア（旗数）が表示されていること
      expect(find.text('2'), findsWidgets);
      expect(find.text('1'), findsWidgets);
    });
  });
}
