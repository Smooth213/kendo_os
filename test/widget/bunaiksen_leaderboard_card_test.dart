import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bunaiksen/bunaiksen_leaderboard_card.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

class _MockStreakNotifier extends BunaiksenInfiniteStreakNotifier {
  _MockStreakNotifier(Map<String, int> initial) {
    state = initial;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget createTestWidget({
    required Map<String, int> streaks,
    bool isDark = false,
  }) {
    return ProviderScope(
      overrides: [
        bunaiksenInfiniteStreakProvider.overrideWith(
          (ref) => _MockStreakNotifier(streaks),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(
          extensions: [AppThemeColors.ofMode(isDark: isDark, mode: 'normal')],
        ),
        home: const Scaffold(body: BunaiksenLeaderboardCard()),
      ),
    );
  }

  group('[Widget] BunaiksenLeaderboardCard ウィジェットテスト', () {
    testWidgets('連勝記録が空の場合は未記録メッセージが表示されること', (tester) async {
      await tester.pumpWidget(createTestWidget(streaks: {}));

      expect(find.text('無限勝ち抜き 連勝ランキング'), findsOneWidget);
      expect(find.text('まだ連勝記録はありません'), findsOneWidget);
      expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
    });

    testWidgets('連勝記録が存在する場合は上位選手と連勝数が描画されること', (tester) async {
      await tester.pumpWidget(
        createTestWidget(streaks: {'佐々木選手': 5, '宮本選手': 3, '坂本選手': 1}),
      );

      expect(find.text('佐々木選手'), findsOneWidget);
      expect(find.text('5 連勝'), findsOneWidget);
      expect(find.text('宮本選手'), findsOneWidget);
      expect(find.text('3 連勝'), findsOneWidget);
      expect(find.text('坂本選手'), findsOneWidget);
      expect(find.text('1 連勝'), findsOneWidget);
    });
  });
}
