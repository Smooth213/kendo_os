import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/match_tables/league_grid_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget createTestWidget({
    required List<LeagueGridTeamInfo> teams,
    required Map<String, Map<String, LeagueGridCellData>> matrix,
    bool hasMatchPoints = false,
    bool isDark = false,
  }) {
    return MaterialApp(
      theme: ThemeData(
        extensions: [AppThemeColors.ofMode(isDark: isDark, mode: 'normal')],
      ),
      home: Scaffold(
        body: LeagueGridCard(
          teams: teams,
          matrix: matrix,
          hasMatchPoints: hasMatchPoints,
          isDark: isDark,
        ),
      ),
    );
  }

  group('[Widget] LeagueGridCard ウィジェットテスト', () {
    testWidgets('リーグ戦表のチーム名・ヘッダー・勝敗データが正常に描画されること', (tester) async {
      bool cellTapped = false;

      final teams = [
        const LeagueGridTeamInfo(
          teamName: '東京道場',
          matchWins: '2',
          individualWinners: '4',
          totalPoints: '8',
          rank: '1',
        ),
        const LeagueGridTeamInfo(
          teamName: '大阪道場',
          matchWins: '0',
          individualWinners: '1',
          totalPoints: '2',
          rank: '2',
        ),
      ];

      final matrix = {
        '東京道場': {
          '大阪道場': LeagueGridCellData(
            result: 'win',
            isIndiv: false,
            rPoints: 3,
            rWinners: 2,
            onTap: () {
              cellTapped = true;
            },
          ),
        },
        '大阪道場': {
          '東京道場': const LeagueGridCellData(
            result: 'loss',
            isIndiv: false,
            rPoints: 1,
            rWinners: 0,
          ),
        },
      };

      await tester.pumpWidget(
        createTestWidget(
          teams: teams,
          matrix: matrix,
          hasMatchPoints: true,
          isDark: false,
        ),
      );

      // チーム名
      expect(find.text('東京道場'), findsWidgets);
      expect(find.text('大阪道場'), findsWidgets);

      // 各ヘッダー
      expect(find.text('勝数'), findsOneWidget);
      expect(find.text('勝者'), findsOneWidget);
      expect(find.text('本数'), findsOneWidget);
      expect(find.text('勝点'), findsOneWidget);
      expect(find.text('順位'), findsOneWidget);

      // セルタップ
      await tester.tap(find.text('3'));
      await tester.pump();
      expect(cellTapped, isTrue);
    });

    testWidgets('チームリストが空の場合はSizedBoxが返ること', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          teams: const [],
          matrix: const {},
          hasMatchPoints: false,
          isDark: false,
        ),
      );

      expect(find.byType(Card), findsNothing);
    });
  });
}
