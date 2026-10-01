import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_team_action_helper.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/team_repository.dart';

class FakeTeamRepository implements TeamRepository {
  String? deletedId;

  @override
  String get dojoId => 'test_dojo';

  @override
  Future<String> saveTeam(TeamModel team) async => team.id;

  @override
  Future<void> deleteTeam(String id) async {
    deletedId = id;
  }

  @override
  Stream<List<TeamModel>> watchTeamsByTournament(String tournamentId) =>
      const Stream.empty();
}

void main() {
  group('[Unit] MatchFormatTeamActionHelper 単体テスト', () {
    testWidgets('handleDeleteTeamにおいてキャンセル選択時に削除が行われないこと', (tester) async {
      late BuildContext capturedContext;
      late WidgetRef capturedRef;
      final fakeRepo = FakeTeamRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [teamRepositoryProvider.overrideWithValue(fakeRepo)],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                capturedContext = context;
                capturedRef = ref;
                return const Scaffold(body: Text('ホーム'));
              },
            ),
          ),
        ),
      );

      const team = TeamModel(
        id: 'team-1',
        tournamentId: 'tour-1',
        category: '一般',
        teamName: '洗心道場A',
      );

      bool deletedCallbackCalled = false;

      // ダイアログ展開
      MatchFormatTeamActionHelper.handleDeleteTeam(
        context: capturedContext,
        ref: capturedRef,
        team: team,
        onDeleted: () {
          deletedCallbackCalled = true;
        },
      );

      await tester.pumpAndSettle();

      // キャンセルボタンをタップ
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      expect(fakeRepo.deletedId, isNull);
      expect(deletedCallbackCalled, isFalse);
    });

    testWidgets('handleDeleteTeamにおいて削除選択時にリポジトリ呼出とコールバックが実行されること', (
      tester,
    ) async {
      late BuildContext capturedContext;
      late WidgetRef capturedRef;
      final fakeRepo = FakeTeamRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [teamRepositoryProvider.overrideWithValue(fakeRepo)],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                capturedContext = context;
                capturedRef = ref;
                return const Scaffold(body: Text('ホーム'));
              },
            ),
          ),
        ),
      );

      const team = TeamModel(
        id: 'team-to-delete',
        tournamentId: 'tour-1',
        category: '一般',
        teamName: '明徳館B',
      );

      bool deletedCallbackCalled = false;

      MatchFormatTeamActionHelper.handleDeleteTeam(
        context: capturedContext,
        ref: capturedRef,
        team: team,
        onDeleted: () {
          deletedCallbackCalled = true;
        },
      );

      await tester.pumpAndSettle();

      // 削除ボタンをタップ
      await tester.tap(find.text('削除'));
      await tester.pumpAndSettle();

      expect(fakeRepo.deletedId, 'team-to-delete');
      expect(deletedCallbackCalled, isTrue);
    });
  });
}
