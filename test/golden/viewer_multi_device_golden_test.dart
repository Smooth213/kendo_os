import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/viewer/screens/viewer_team_scoreboard_screen.dart';
import 'package:kendo_os/features/viewer/presentation/viewer_match_screen.dart';
import 'package:kendo_os/shared/widgets/scoreboard.dart';
import 'package:kendo_os/shared/domain/entities/settings_model.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import '../helpers/test_app.dart';

class _MockLocalMatchRepository extends Mock implements LocalMatchRepository {}

class _MockSettingsNotifier extends SettingsNotifier {
  @override
  SettingsModel build() =>
      const SettingsModel(securityLevel: 1, enableLiquidGlass: false);
}

void main() {
  group('📸 【Golden 2/5】観客席ビュー（Viewer）マルチデバイス 視覚的境界整合性テスト', () {
    final devices = {
      'Mobile_Portrait (iPhone)': const Size(375, 812),
      'Tablet_Landscape (iPad 4-Court)': const Size(1024, 768),
      'Large_Display (Court-Side 1080p)': const Size(1920, 1080),
    };

    for (var entry in devices.entries) {
      final deviceName = entry.key;
      final size = entry.value;

      testWidgets('【マルチデバイス整合】$deviceName での観客席チームスコアボード描画整合性', (
        WidgetTester tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final mockLocalMatchRepository = _MockLocalMatchRepository();
        when(
          () => mockLocalMatchRepository.watchAllLocalMatches(),
        ).thenAnswer((_) => Stream.value(<MatchModel>[]));
        when(
          () => mockLocalMatchRepository.watchLocalMatches(any()),
        ).thenAnswer((_) => Stream.value(<MatchModel>[]));

        await tester.pumpWidget(
          createTestApp(
            const ViewerTeamScoreboardScreen(groupName: '高校男子の部_決勝リーグ'),
            overrides: [
              settingsProvider.overrideWith(() => _MockSettingsNotifier()),
              localMatchRepositoryProvider.overrideWithValue(
                mockLocalMatchRepository,
              ),
              matchListProvider.overrideWithValue([]),
              matchListByTournamentProvider.overrideWith(
                (ref, id) => Stream.value([]),
              ),
            ],
          ),
        );

        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.byType(ViewerTeamScoreboardScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets(
        '【マルチデバイス整合】$deviceName での観客席試合速報画面（ViewerMatchScreen）描画整合性',
        (WidgetTester tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() => tester.view.resetPhysicalSize());

          final match = MatchModel(
            id: 'viewer_match_golden',
            tournamentId: 't1',
            category: '一般の部',
            groupName: 'Aリーグ',
            redName: '神武館:佐藤',
            whiteName: '修道館:田中',
            matchType: '個人戦',
            status: 'inProgress',
            redScore: 1,
            whiteScore: 0,
          );

          await tester.pumpWidget(
            createTestApp(
              const ViewerMatchScreen(matchId: 'viewer_match_golden'),
              overrides: [
                settingsProvider.overrideWith(() => _MockSettingsNotifier()),
                matchListProvider.overrideWithValue([match]),
                scoreboardMatchIdProvider.overrideWithValue(
                  'viewer_match_golden',
                ),
                scoreboardMatchProvider.overrideWithValue(match),
                scoreboardNameTapProvider.overrideWithValue((side) {}),
              ],
            ),
          );

          await tester.pump();
          await tester.pumpAndSettle();

          expect(find.byType(ViewerMatchScreen), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
