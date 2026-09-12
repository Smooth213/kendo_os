import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/viewer/screens/viewer_team_scoreboard_screen.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/tournament_repository.dart';
import 'package:mocktail/mocktail.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';

class MockTournamentRepository extends Mock implements TournamentRepository {}

void main() {
  group('ViewerTeamScoreboardScreen Order Tests', () {
    late MockTournamentRepository mockTournamentRepo;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();

      mockTournamentRepo = MockTournamentRepository();
      when(() => mockTournamentRepo.getTournamentStream(any())).thenAnswer(
        (_) => Stream.value(
          TournamentModel(
            id: 'tour_test_1',
            organizationId: 'org_1',
            name: 'テスト大会',
            date: DateTime.now(),
            venue: '武道館',
            categories: const ['一般の部'],
          ),
        ),
      );
    });

    testWidgets(
      'Displays matches in correct kendo position order (先鋒 -> 中堅 -> 大将) even if input is scrambled',
      (tester) async {
        // 意図的に「中堅 ➔ 大将 ➔ 先鋒」の乱れた順序でリストを作成
        final chuken = MatchModel(
          id: 'm_chuken',
          tournamentId: 'tour_test_1',
          order: 2.0,
          matchType: '中堅',
          redName: '道上剣友会: 皿田 史朗',
          whiteName: '相手0012: 相手 選手2',
          groupName: 'group_order_test',
          status: 'finished',
          redScore: 1,
          whiteScore: 0,
        );

        final taisho = MatchModel(
          id: 'm_taisho',
          tournamentId: 'tour_test_1',
          order: 3.0,
          matchType: '大将',
          redName: '道上剣友会: 久安 達也',
          whiteName: '相手0012: 相手 選手3',
          groupName: 'group_order_test',
          status: 'finished',
          redScore: 0,
          whiteScore: 2,
        );

        final sempo = MatchModel(
          id: 'm_sempo',
          tournamentId: 'tour_test_1',
          order: 1.0,
          matchType: '先鋒',
          redName: '道上剣友会: 塚本 達也',
          whiteName: '相手0012: 相手 選手1',
          groupName: 'group_order_test',
          status: 'finished',
          redScore: 2,
          whiteScore: 0,
        );

        // バラバラなリスト
        final scrambledMatches = [chuken, taisho, sempo];

        final router = GoRouter(
          initialLocation:
              '/viewer-team/group_order_test?tournamentId=tour_test_1',
          routes: [
            GoRoute(
              path: '/viewer-team/:groupName',
              builder: (context, state) => ViewerTeamScoreboardScreen(
                groupName: state.pathParameters['groupName']!,
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              matchListProvider.overrideWith((ref) => scrambledMatches),
              tournamentRepositoryProvider.overrideWithValue(
                mockTournamentRepo,
              ),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );

        await tester.pumpAndSettle();

        // ポジションテキストの存在確認
        expect(find.text('先鋒'), findsOneWidget);
        expect(find.text('中堅'), findsOneWidget);
        expect(find.text('大将'), findsOneWidget);

        // 描画位置（縦座標 Y）を取得し、上から「先鋒 ➔ 中堅 ➔ 大将」になっているか検証
        final sempoOffset = tester.getTopLeft(find.text('先鋒'));
        final chukenOffset = tester.getTopLeft(find.text('中堅'));
        final taishoOffset = tester.getTopLeft(find.text('大将'));

        expect(
          sempoOffset.dy < chukenOffset.dy,
          isTrue,
          reason: '先鋒 should be above 中堅',
        );
        expect(
          chukenOffset.dy < taishoOffset.dy,
          isTrue,
          reason: '中堅 should be above 大将',
        );

        // 選手名（RichText）の出現も確認
        final tsukamotoFinder = find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('塚本'),
        );
        final saradaFinder = find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('皿田'),
        );
        final hisayasuFinder = find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('久安'),
        );

        expect(tsukamotoFinder, findsWidgets);
        expect(saradaFinder, findsWidgets);
        expect(hisayasuFinder, findsWidgets);

        final tsukamotoOffset = tester.getTopLeft(tsukamotoFinder.first);
        final saradaOffset = tester.getTopLeft(saradaFinder.first);
        final hisayasuOffset = tester.getTopLeft(hisayasuFinder.first);

        expect(
          tsukamotoOffset.dy < saradaOffset.dy,
          isTrue,
          reason: '塚本 (先鋒) should be above 皿田 (中堅)',
        );
        expect(
          saradaOffset.dy < hisayasuOffset.dy,
          isTrue,
          reason: '皿田 (中堅) should be above 久安 (大将)',
        );
      },
    );
  });
}
