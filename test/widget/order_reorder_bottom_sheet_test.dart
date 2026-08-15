import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_timeline_list.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/sheets/order_reorder_bottom_sheet.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/team_repository.dart';

void main() {
  group('🛡️ OrderReorderBottomSheet Widget Tests', () {
    testWidgets('Renders OrderReorderBottomSheet and displays matches order', (
      WidgetTester tester,
    ) async {
      final matches = [
        const MatchModel(
          id: 'm1',
          tournamentId: 't1',
          matchType: '先鋒',
          redName: '道上 : 佐藤',
          whiteName: '相手 : 田中',
          status: 'pending',
        ),
        const MatchModel(
          id: 'm2',
          tournamentId: 't1',
          matchType: '次鋒',
          redName: '道上 : 鈴木',
          whiteName: '相手 : 高橋',
          status: 'pending',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            customTeamNamesProvider.overrideWith((ref) => Stream.value(['道上'])),
            timelinePlayerListProvider.overrideWith(
              (ref) => Stream.value(<PlayerModel>[]),
            ),
            registeredTeamsProvider(
              't1',
            ).overrideWith((ref) => Stream.value(<TeamModel>[])),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: OrderReorderBottomSheet(sortedMatches: matches),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('オーダー編集 : 道上'), findsOneWidget);
      expect(find.text('先鋒'), findsOneWidget);
      expect(find.text('佐藤'), findsOneWidget);
      expect(find.text('次鋒'), findsOneWidget);
      expect(find.text('鈴木'), findsOneWidget);
      expect(find.text('オーダーを確定'), findsOneWidget);
    });
  });
}
