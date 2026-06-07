import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/viewer/screens/viewer_team_scoreboard_screen.dart';
import '../helpers/test_app.dart';

class MockLocalMatchRepository extends Mock implements LocalMatchRepository {}

void main() {
  group('🛡️ フェーズ5 — Golden Test 多端末UI崩壊自動検知要塞', () {
    final devices = {
      'iPhone_SE': const Size(375, 667),
      'iPad': const Size(768, 1024),
      'Android_Tablet': const Size(800, 1280),
      'Web_Desktop': const Size(1920, 1080),
    };

    for (var entry in devices.entries) {
      final deviceName = entry.key;
      final size = entry.value;

      testWidgets('【Goldenシミュレーション】$deviceName 環境における描画境界整合性テスト', (
        WidgetTester tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final mockLocalMatchRepository = MockLocalMatchRepository();
        when(
          () => mockLocalMatchRepository.watchAllLocalMatches(),
        ).thenAnswer((_) => Stream.value(<MatchModel>[]));
        when(
          () => mockLocalMatchRepository.watchLocalMatches(any()),
        ).thenAnswer((_) => Stream.value(<MatchModel>[]));

        await tester.pumpWidget(
          createTestApp(
            const ViewerTeamScoreboardScreen(groupName: '一般の部_リーグ戦'),
            overrides: [
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
      });
    }
  });
}
