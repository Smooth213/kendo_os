import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/components/kachinuki/kachinuki_battle_card_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bunaiksen_setup/bunaiksen_infinite_tab.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/infinite_streak_leaderboard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Golden] 部内戦（無限勝ち抜き戦）待機キュー＆連勝バッジ（Streak ）視覚整合性テスト', () {
    testWidgets('連勝リーダーボード（Top3）＆ Streak バッジのレンダリングが正しく検証されること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bunaiksenInfiniteStreakProvider.overrideWith((ref) {
              final notifier = BunaiksenInfiniteStreakNotifier();
              notifier.state = {'佐藤健太': 5, '田中慎一': 3, '高橋一郎': 2, '鈴木次郎': 0};
              return notifier;
            }),
          ],
          child: MaterialApp(
            theme: ThemeData.light().copyWith(extensions: [themeColors]),
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🏆 連勝リーダーボード',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: InfiniteStreakLeaderboard(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '🔥 連勝バッジ（Streak Badges）',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        // 2人抜き中バッジ
                        KachinukiBattleCardHelper.buildStreakBadge(
                          isWin: false,
                          isStreaking: true,
                          streak: 2,
                          isDark: false,
                        )!,
                        const SizedBox(width: 12),
                        // 5人抜き達成バッジ
                        KachinukiBattleCardHelper.buildStreakBadge(
                          isWin: true,
                          isStreaking: true,
                          streak: 5,
                          isDark: false,
                        )!,
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(InfiniteStreakLeaderboard), findsOneWidget);
      expect(find.text('佐藤健太'), findsOneWidget);
      expect(find.text('5 連勝'), findsOneWidget);
      expect(find.text('田中慎一'), findsOneWidget);
      expect(find.text('3 連勝'), findsOneWidget);
      expect(find.text('高橋一郎'), findsOneWidget);
      expect(find.text('2 連勝'), findsOneWidget);
      expect(find.text('🔥 5人抜き'), findsOneWidget);
      expect(find.text('🔥 2人抜き中'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('部内戦待機列キュー (BunaiksenInfiniteTab) レンダリングが正しく検証されること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final themeColors = AppThemeColors.ofMode(isDark: true, mode: 'normal');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bunaiksenInfiniteQueueProvider.overrideWith((ref) {
              final notifier = BunaiksenInfiniteQueueNotifier();
              notifier.setPlayers(['佐藤', '田中', '鈴木', '高橋', '渡辺']);
              return notifier;
            }),
          ],
          child: MaterialApp(
            theme: ThemeData.dark().copyWith(extensions: [themeColors]),
            home: Scaffold(
              body: BunaiksenInfiniteTab(themeColors: themeColors),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('待機列 (5人)'), findsOneWidget);
      expect(find.text('シャッフル'), findsOneWidget);
      expect(find.text('佐藤'), findsOneWidget);
      expect(find.text('渡辺'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
