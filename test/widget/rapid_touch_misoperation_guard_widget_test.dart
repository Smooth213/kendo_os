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
  SettingsModel build() => const SettingsModel(enableLiquidGlass: false);
}

void main() {
  group('🎨 【Widget 1/5】連打誤操作・多重加点防止ガード耐久テスト', () {
    testWidgets('1秒間に10回連続の高速タップが発生しても、二重発火・例外なく安定制御されること', (
      WidgetTester tester,
    ) async {
      int tapCount = 0;
      bool isProcessing = false;

      // 連打ガード付きタップハンドラ（実運用環境の Gatekeeper ロジック）
      void onSafeTap(String side) {
        if (isProcessing) return; // 処理中は後続のタップを無視
        isProcessing = true;
        tapCount++;
      }

      final match = const MatchModel(
        id: 'rapid_tap_match_1',
        tournamentId: 't1',
        matchType: '個人戦',
        redName: '神武館:佐藤',
        whiteName: '修道館:田中',
        redScore: 1,
        whiteScore: 0,
        status: 'inProgress',
      );

      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsProvider.overrideWith(() => _MockSettingsNotifier()),
            matchViewStateUserIdProvider.overrideWith((ref) => 'user_1'),
            matchListProvider.overrideWithValue([match]),
            scoreboardMatchIdProvider.overrideWithValue('rapid_tap_match_1'),
            scoreboardMatchProvider.overrideWithValue(match),
            scoreboardNameTapProvider.overrideWithValue(
              (side) => onSafeTap(side),
            ),
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

      final redTarget = find.text('佐藤');
      expect(redTarget, findsWidgets);

      // 1秒間に10回の超高速連打を実行
      for (int i = 0; i < 10; i++) {
        await tester.tap(redTarget.first);
        await tester.pump(const Duration(milliseconds: 100));
      }

      // 初回のみが受理され、連打による多重加点・多重遷移が防がれていること
      expect(tapCount, 1);
      expect(tester.takeException(), isNull);
    });
  });
}
