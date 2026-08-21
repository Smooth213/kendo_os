import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_content_layout_builder.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_header_widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🛡️ MatchScreen Extracted Components Tests', () {
    testWidgets('1. MatchHeaderTitle renders matchType and names', (
      tester,
    ) async {
      final match = MatchModel(
        id: 'm1',
        matchOrder: 1,
        redName: '佐藤',
        whiteName: '鈴木',
        redScore: 1,
        whiteScore: 0,
        status: 'in_progress',
        matchType: '個人戦',
        category: '一般の部',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MatchHeaderTitle(match: match)),
        ),
      );

      expect(find.text('一般の部 - 個人戦'), findsOneWidget);
      expect(find.text('佐藤 vs 鈴木'), findsOneWidget);
    });

    testWidgets('2. MatchContentLayoutBuilder renders portrait layout', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchContentLayoutBuilder(
              constraints: const BoxConstraints(maxWidth: 400, maxHeight: 800),
              isDark: false,
              corruptedBanner: const Text('CORRUPTED'),
              viewOnlyBanner: const Text('VIEW_ONLY'),
              timerPart: const Text('TIMER'),
              groupButtonPart: const Text('GROUP_BUTTONS'),
              scoreboardPart: const Text('SCOREBOARD'),
              actionPanelPart: const Text('ACTION_PANEL'),
              undoArea: const Text('UNDO_AREA'),
              bottomButtonPart: const Text('BOTTOM_BUTTONS'),
            ),
          ),
        ),
      );

      expect(find.text('TIMER'), findsOneWidget);
      expect(find.text('GROUP_BUTTONS'), findsOneWidget);
      expect(find.text('SCOREBOARD'), findsOneWidget);
      expect(find.text('ACTION_PANEL'), findsOneWidget);
    });
  });
}
