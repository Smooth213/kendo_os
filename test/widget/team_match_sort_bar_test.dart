import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/court_status/team_match_sort_bar.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/team_progress_sort_helper.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget createTestWidget({
    required TeamSortType currentSort,
    required ValueChanged<TeamSortType> onSortChanged,
    bool isDark = false,
  }) {
    return MaterialApp(
      theme: ThemeData(
        extensions: [AppThemeColors.ofMode(isDark: isDark, mode: 'normal')],
      ),
      home: Scaffold(
        body: TeamMatchSortBar(
          currentSort: currentSort,
          onSortChanged: onSortChanged,
          isDark: isDark,
        ),
      ),
    );
  }

  group('[Widget] TeamMatchSortBar ウィジェットテスト', () {
    testWidgets('並び替えチップバーが正常に描画され選択変更できること', (tester) async {
      TeamSortType selectedType = TeamSortType.status;

      await tester.pumpWidget(
        createTestWidget(
          currentSort: selectedType,
          onSortChanged: (type) {
            selectedType = type;
          },
        ),
      );

      expect(find.text('並び替え:'), findsOneWidget);
      expect(find.text('⚡ 進行状況順'), findsOneWidget);
      expect(find.text('🏟️ 試合会場順'), findsOneWidget);
      expect(find.text('🔢 試合順'), findsOneWidget);

      // 会場順を選択
      await tester.tap(find.text('🏟️ 試合会場順'));
      await tester.pump();

      expect(selectedType, TeamSortType.court);

      // 試合順を選択
      await tester.tap(find.text('🔢 試合順'));
      await tester.pump();

      expect(selectedType, TeamSortType.matchOrder);
    });

    testWidgets('ダークモード時も正常に描画されること', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          currentSort: TeamSortType.court,
          onSortChanged: (_) {},
          isDark: true,
        ),
      );

      expect(find.text('並び替え:'), findsOneWidget);
      expect(find.byIcon(Icons.swap_vert_rounded), findsOneWidget);
    });
  });
}
