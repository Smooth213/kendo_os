import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/expedition_player_stats_section.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/expedition_stats_models.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';

void main() {
  group('ExpeditionPlayerStatsSection 視認性テスト', () {
    final Map<String, DetailedPlayerStats> sampleStats = {
      '恵木 春陽': DetailedPlayerStats()
        ..win = 1
        ..loss = 1
        ..draw = 3
        ..totalPoints = 4
        ..teamWin = 0
        ..teamLoss = 0
        ..teamDraw = 2
        ..teamPoints = 1
        ..individualWin = 1
        ..individualLoss = 1
        ..individualDraw = 1
        ..individualPoints = 3
        ..men = 2
        ..kote = 1
        ..dou = 1
        ..tsuki = 0
        ..hansoku = 0,
      '皿田 唯人': DetailedPlayerStats()
        ..win = 6
        ..loss = 1
        ..draw = 1
        ..totalPoints = 9
        ..teamWin = 2
        ..teamLoss = 0
        ..teamDraw = 0
        ..teamPoints = 3
        ..individualWin = 4
        ..individualLoss = 1
        ..individualDraw = 1
        ..individualPoints = 6
        ..men = 5
        ..kote = 3
        ..dou = 1
        ..tsuki = 0
        ..hansoku = 0,
    };

    testWidgets('ダークモードでの選択タブと取得本数の視認性テスト', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: ExpeditionPlayerStatsSection(
              playerStatsMap: sampleStats,
              isDark: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. 選択された「通算 (総合)」チップの検証
      final selectedChipFinder = find.byWidgetPredicate((widget) {
        if (widget is AppChoiceChip && widget.selected) {
          return true;
        }
        return false;
      });
      expect(selectedChipFinder, findsOneWidget);

      final selectedChip = tester.widget<AppChoiceChip>(selectedChipFinder);
      // 選択時の文字色は純白で視認性が確保されていること
      expect(selectedChip.customTextColor, equals(AppKendoColors.pureWhite));

      // 2. 取得本数「(4本)」「(9本)」のテキスト色検証（ダークモード時に暗いインディゴではなく明るい高コントラスト色であること）
      final points4Finder = find.text('(4本)');
      expect(points4Finder, findsOneWidget);
      final points4Text = tester.widget<Text>(points4Finder);
      expect(points4Text.style?.color, equals(const Color(0xFF60A5FA)));

      final points9Finder = find.text('(9本)');
      expect(points9Finder, findsOneWidget);
      final points9Text = tester.widget<Text>(points9Finder);
      expect(points9Text.style?.color, equals(const Color(0xFF60A5FA)));
    });

    testWidgets('ライトモードでの取得本数の視認性テスト', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: ExpeditionPlayerStatsSection(
              playerStatsMap: sampleStats,
              isDark: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final points4Finder = find.text('(4本)');
      expect(points4Finder, findsOneWidget);
      final points4Text = tester.widget<Text>(points4Finder);
      expect(points4Text.style?.color, equals(const Color(0xFF1D4ED8)));
    });
  });
}
