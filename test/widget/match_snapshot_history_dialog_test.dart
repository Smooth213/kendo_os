import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_snapshot_history_dialog.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('🛡️ MatchSnapshotHistoryDialog Widget Tests', () {
    testWidgets('Renders empty message when validEvents is empty', (
      WidgetTester tester,
    ) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [themeColors]),
          home: Scaffold(
            body: MatchSnapshotHistoryDialog(
              validEvents: const [],
              isDark: false,
              onSelectRewind: (version, index) {},
              onClose: () {},
            ),
          ),
        ),
      );

      expect(find.text('操作履歴と取り消し'), findsOneWidget);
      expect(find.text('取り消し可能な操作履歴がありません'), findsOneWidget);
      expect(find.text('閉じる'), findsOneWidget);
    });

    testWidgets('Renders history list and triggers rewind callback', (
      WidgetTester tester,
    ) async {
      int? selectedVersion;
      int? selectedIndex;

      final now = DateTime(2026, 8, 15, 14, 30, 0);

      final event1 = ScoreEvent(
        id: 'e1',
        strikeType: StrikeType.men,
        isIppon: true,
        side: Side.red,
        timestamp: now,
      );

      final event2 = ScoreEvent(
        id: 'e2',
        strikeType: StrikeType.kote,
        isIppon: true,
        side: Side.white,
        timestamp: now.add(const Duration(minutes: 1)),
      );

      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [themeColors]),
          home: Scaffold(
            body: MatchSnapshotHistoryDialog(
              validEvents: [event1, event2],
              isDark: false,
              onSelectRewind: (version, index) {
                selectedVersion = version;
                selectedIndex = index;
              },
              onClose: () {},
            ),
          ),
        ),
      );

      expect(find.text('赤 メン'), findsOneWidget);
      expect(find.text('白 コテ'), findsOneWidget);
      expect(find.text('1本目まで戻る'), findsOneWidget);
      expect(find.text('2本目まで戻る'), findsOneWidget);

      // 1本目まで戻るをタップ
      await tester.tap(find.text('赤 メン'));
      await tester.pump();
      expect(selectedVersion, 1);
      expect(selectedIndex, 0);
    });
  });
}
