import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_infinite_handler_helper.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart';

class _FakeMatchAppService implements MatchApplicationService {
  MatchModel? savedMatch;

  @override
  Future<void> saveMatch(MatchModel match) async {
    savedMatch = match;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('[Unit] 部内戦無限勝ち抜き結果調停エンジン単体テスト', () {
    testWidgets('handleMatchFinishにおいて勝者が勝ち残り連勝数が加算され次試合準備が整うこと', (
      WidgetTester tester,
    ) async {
      final fakeAppService = _FakeMatchAppService();

      final currentMatch = MatchModel(
        id: 'infinite-m-1',
        tournamentId: 't-1',
        matchType: '無限稽古',
        redName: '元立ちA',
        whiteName: '挑戦者B',
        status: 'ongoing',
      );

      late BuildContext capturedContext;
      late WidgetRef capturedRef;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matchApplicationServiceProvider.overrideWithValue(fakeAppService),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  capturedContext = context;
                  capturedRef = ref;
                  return ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const Center(child: Text('処理中')),
                      );
                    },
                    child: const Text('開始'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      capturedRef.read(bunaiksenInfiniteQueueProvider.notifier).setPlayers([
        '挑戦者C',
        '挑戦者D',
      ]);

      await tester.tap(find.text('開始'));
      await tester.pump();
      expect(find.text('処理中'), findsOneWidget);

      await MatchInfiniteHandlerHelper.handleMatchFinish(
        context: capturedContext,
        ref: capturedRef,
        currentMatch: currentMatch,
        winnerColor: 'red',
      );

      await tester.pumpAndSettle();

      expect(fakeAppService.savedMatch, isNotNull);
      expect(fakeAppService.savedMatch!.status, 'finished');

      final streaks = capturedRef.read(bunaiksenInfiniteStreakProvider);
      expect(streaks['元立ちA'], 1);

      expect(find.textContaining('元立ちA'), findsWidgets);
      expect(find.textContaining('挑戦者C'), findsWidgets);
    });
  });
}
