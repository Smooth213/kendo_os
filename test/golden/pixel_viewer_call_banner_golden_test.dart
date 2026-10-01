import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_call_banner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Golden] 観客席選手呼び出しバナー視覚整合性テスト', () {
    testWidgets('進行中試合および次試合が存在する場合に視認性の高い配色で呼び出しバナーが表示されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final inProgress = [
        const MatchModel(
          id: 'm_progress_1',
          tournamentId: 't1',
          matchType: '個人戦',
          redName: '佐藤',
          whiteName: '田中',
          redScore: 1,
          whiteScore: 0,
          status: 'in_progress',
          note: '第1コート 第3試合',
        ),
      ];

      final waiting = [
        const MatchModel(
          id: 'm_waiting_1',
          tournamentId: 't1',
          matchType: '個人戦',
          redName: '高橋',
          whiteName: '渡辺',
          redScore: 0,
          whiteScore: 0,
          status: 'ready',
          note: '第1コート 第4試合',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: const Color(0xFF1E1E1E),
            body: Center(
              child: ViewerCallBanner(
                inProgressMatches: inProgress,
                waitingMatches: waiting,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ViewerCallBanner), findsOneWidget);
      expect(find.text('進行中'), findsOneWidget);
      expect(find.text('次試合'), findsOneWidget);
      expect(find.text('第1コート 第3試合'), findsOneWidget);
      expect(find.text('第1コート 第4試合'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('団体戦において所属チーム名と選手名が明瞭に分離されて描画されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final inProgress = [
        const MatchModel(
          id: 'm_team_call',
          tournamentId: 't1',
          matchType: '団体戦',
          groupName: '高校男子決勝',
          redName: '神武館道場 : 山田',
          whiteName: '修道館 : 佐々木',
          redScore: 0,
          whiteScore: 0,
          status: 'in_progress',
          note: '先鋒戦',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ViewerCallBanner(
                inProgressMatches: inProgress,
                waitingMatches: const [],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ViewerCallBanner), findsOneWidget);
      expect(find.text('神武館道場 vs 修道館'), findsOneWidget);
      expect(find.text('先鋒戦'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('試合リストが空の場合にバナーが表示されず空ウィジェットが返却されること', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ViewerCallBanner(inProgressMatches: [], waitingMatches: []),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ViewerCallBanner), findsOneWidget);
      expect(find.byType(Container), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
