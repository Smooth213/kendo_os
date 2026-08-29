import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/viewer/components/large_viewer_scoreboard.dart';
import 'package:kendo_os/shared/application/projections/match_projection.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🛡️ LargeViewerScoreboard Tests', () {
    testWidgets('1. LargeViewerScoreboard renders correctly', (tester) async {
      final proj = MatchProjection(
        id: 'm1',
        tournamentId: 't1',
        matchOrder: 1,
        matchType: '先鋒戦',
        status: 'in_progress',
        groupName: 'グループA',
        note: '',
        isKachinuki: false,
        redName: 'A道場 : 佐藤',
        whiteName: 'B道場 : 鈴木',
        redScore: 1,
        whiteScore: 0,
        remainingSeconds: 180,
        timerIsRunning: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
          ),
          home: Scaffold(
            body: LargeViewerScoreboard(
              projection: proj,
              activeMatch: null,
              isDark: false,
            ),
          ),
        ),
      );

      expect(find.text('佐藤'), findsOneWidget);
      expect(find.text('鈴木'), findsOneWidget);
      expect(find.text('1 - 0'), findsOneWidget);
      expect(find.text('03:00'), findsNothing);
    });
  });
}
