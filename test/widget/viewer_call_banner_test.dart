import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_call_banner.dart';

void main() {
  testWidgets('ViewerCallBanner renders in-progress and waiting matches', (
    tester,
  ) async {
    final match1 = MatchModel(
      id: 'm1',
      tournamentId: 't1',
      matchType: 'team',
      order: 1,
      redName: '先鋒: 田中',
      whiteName: '先鋒: 佐藤',
      status: 'in_progress',
      note: '1回戦',
    );
    final match2 = MatchModel(
      id: 'm2',
      tournamentId: 't1',
      matchType: 'team',
      order: 2,
      redName: '次鋒: 鈴木',
      whiteName: '次鋒: 高橋',
      status: 'waiting',
      note: '1回戦',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ViewerCallBanner(
            inProgressMatches: [match1],
            waitingMatches: [match2],
          ),
        ),
      ),
    );

    expect(find.text('進行中'), findsOneWidget);
    expect(find.text('次試合'), findsOneWidget);
  });
}
