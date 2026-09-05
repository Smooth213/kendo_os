import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/features/match/presentation/components/announce_history_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/floating_program_dock_button.dart';
import 'package:kendo_os/shared/widgets/thermal_status_badge.dart';
import 'package:kendo_os/features/viewer/presentation/viewer_home_screen.dart';
import 'package:kendo_os/features/viewer/presentation/viewer_match_screen.dart';
import 'package:kendo_os/features/viewer/screens/viewer_bunaiksen_home_screen.dart';
import 'package:kendo_os/features/viewer/screens/viewer_bunaiksen_official_record_screen.dart';
import 'package:kendo_os/features/viewer/screens/viewer_kachinuki_scoreboard_screen.dart';
import 'package:kendo_os/features/viewer/screens/viewer_official_record_screen.dart';
import 'package:kendo_os/features/viewer/screens/viewer_team_scoreboard_screen.dart';
import 'helpers/rendering_safety_test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await RenderingSafetyTestHelper.initialize();
  });

  const String testTournamentId = RenderingSafetyTestHelper.testTournamentId;
  final edgeMatches = RenderingSafetyTestHelper.createEdgeCaseMatches();
  final edgeComments = RenderingSafetyTestHelper.createTestComments();

  group('🛡️ 【セキュリティ＆ロール露出規制】閲覧専用ビュアー フローティングドック完全排除保証テスト', () {
    testWidgets(
      '1. 静的コード規約: lib/features/viewer/ 配下に FloatingProgramDockButton が一切存在しないこと',
      (tester) async {
        final viewerDir = Directory('lib/features/viewer');
        expect(viewerDir.existsSync(), isTrue);

        final dartFiles = viewerDir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'));

        for (final file in dartFiles) {
          final content = file.readAsStringSync();
          expect(
            content.contains('FloatingProgramDockButton'),
            isFalse,
            reason:
                '🚨 閲覧専用ビュアー (${file.path}) に FloatingProgramDockButton が検出されました！'
                '閲覧者にはドックを表示してはなりません。',
          );
        }
      },
    );

    testWidgets(
      '2. 閲覧専用全7画面で FloatingProgramDockButton が画面上に物理排除されていること（findsNothing）',
      (tester) async {
        final viewerScreens = <Widget>[
          const ViewerHomeScreen(tournamentId: testTournamentId),
          const ViewerMatchScreen(matchId: 'm_edge_1'),
          const ViewerOfficialRecordScreen(tournamentId: testTournamentId),
          const ViewerTeamScoreboardScreen(groupName: '道上剣友会A'),
          const ViewerKachinukiScoreboardScreen(groupName: '道上剣友会A'),
          const ViewerBunaiksenHomeScreen(tournamentId: testTournamentId),
          const ViewerBunaiksenOfficialRecordScreen(
            tournamentId: testTournamentId,
          ),
        ];

        for (final screen in viewerScreens) {
          await tester.pumpWidget(
            RenderingSafetyTestHelper.buildTestWidget(
              child: screen,
              matches: edgeMatches,
              comments: edgeComments,
              role: UserRole.viewer,
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          // ドックが一切レンダリングされていないことを厳格にアサート
          expect(
            find.byType(FloatingProgramDockButton),
            findsNothing,
            reason:
                '🚨 ${screen.runtimeType} に FloatingProgramDockButton が描画されています！',
          );
        }
      },
    );

    testWidgets('3. ViewerHomeScreen のヘッダー部にお知らせベルアイコンおよびメニューが復元されていること', (
      tester,
    ) async {
      await tester.pumpWidget(
        RenderingSafetyTestHelper.buildTestWidget(
          child: const ViewerHomeScreen(tournamentId: testTournamentId),
          matches: edgeMatches,
          comments: edgeComments,
          role: UserRole.viewer,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // お知らせベルアイコンが存在すること
      expect(find.byType(NotificationBellButton), findsOneWidget);
      // メニューアイコン（PopupMenuButton）が存在すること
      expect(find.byType(PopupMenuButton<String>), findsOneWidget);
    });

    testWidgets(
      '4. ViewerSettingsBottomSheet に「省エネモード」「サーマル冷却」「サンシャイン」が正しく描画されること',
      (tester) async {
        await tester.pumpWidget(
          RenderingSafetyTestHelper.buildTestWidget(
            child: const ViewerSettingsBottomSheet(),
            role: UserRole.viewer,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // タイトル
        expect(find.text('表示設定'), findsOneWidget);
        // テーマの切り替えタイル
        expect(find.text('テーマの切り替え'), findsOneWidget);
        // 省エネモード（背景アニメーション停止）
        expect(find.text('省エネモード（背景アニメーション停止）'), findsOneWidget);
        expect(find.byIcon(Icons.eco), findsOneWidget);
        // サーマル冷却・省電力制御
        expect(find.text('サーマル冷却・省電力制御'), findsOneWidget);
        expect(find.byIcon(Icons.shield_rounded), findsOneWidget);
        expect(find.byType(ThermalStatusBadge), findsOneWidget);
        // ドロップダウンを展開してサンシャインモードが存在すること
        await tester.tap(find.text('📱 端末連動'));
        await tester.pumpAndSettle();
        expect(find.text('☀️ サンシャイン'), findsWidgets);
      },
    );
  });
}
