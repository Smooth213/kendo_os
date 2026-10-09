import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_match_group_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/match_repository.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

class TrackingLocalMatchRepository implements LocalMatchRepository {
  List<String> bulkDeletedIds = [];

  @override
  Future<void> deleteMatch(String matchId) async {
    bulkDeletedIds.add(matchId);
  }

  @override
  Future<void> deleteMatchesBulk(List<String> matchIds) async {
    bulkDeletedIds.addAll(matchIds);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TrackingMatchRepository implements MatchRepository {
  List<String> bulkDeletedIds = [];

  @override
  Future<void> deleteMatch(String matchId) async {
    bulkDeletedIds.add(matchId);
  }

  @override
  Future<void> deleteMatchesBulk(List<String> matchIds) async {
    bulkDeletedIds.addAll(matchIds);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('[Widget] 団体戦グループカード削除フロー統合テスト', () {
    testWidgets('スワイプ削除からダイアログ確定を経て全試合IDが一括削除されること', (tester) async {
      final mockLocalRepo = TrackingLocalMatchRepository();
      final mockRemoteRepo = TrackingMatchRepository();

      const tournamentId = 'test_tournament_1';
      const groupId = 'group_team_vs_team';

      final sampleGroupMatches = [
        const MatchModel(
          id: 'match_senpo',
          tournamentId: tournamentId,
          groupName: groupId,
          matchType: '先鋒',
          redName: '赤道場:選手1',
          whiteName: '白道場:選手1',
          status: 'waiting',
          order: 1.0,
        ),
        const MatchModel(
          id: 'match_jiho',
          tournamentId: tournamentId,
          groupName: groupId,
          matchType: '次鋒',
          redName: '赤道場:選手2',
          whiteName: '白道場:選手2',
          status: 'waiting',
          order: 2.0,
        ),
        const MatchModel(
          id: 'match_chuken',
          tournamentId: tournamentId,
          groupName: groupId,
          matchType: '中堅',
          redName: '赤道場:選手3',
          whiteName: '白道場:選手3',
          status: 'waiting',
          order: 3.0,
        ),
        const MatchModel(
          id: 'match_fukuso',
          tournamentId: tournamentId,
          groupName: groupId,
          matchType: '副将',
          redName: '赤道場:選手4',
          whiteName: '白道場:選手4',
          status: 'waiting',
          order: 4.0,
        ),
        const MatchModel(
          id: 'match_taisho',
          tournamentId: tournamentId,
          groupName: groupId,
          matchType: '大将',
          redName: '赤道場:選手5',
          whiteName: '白道場:選手5',
          status: 'waiting',
          order: 5.0,
        ),
      ];

      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localMatchRepositoryProvider.overrideWithValue(mockLocalRepo),
            matchRepositoryProvider.overrideWithValue(mockRemoteRepo),
            matchListProvider.overrideWithValue(sampleGroupMatches),
            permissionProvider.overrideWithValue(
              const PermissionState(
                role: UserRole.admin,
                isReadOnly: false,
                canManageTournament: true,
                canDeleteData: true,
              ),
            ),
          ],
          child: MaterialApp(
            theme: ThemeData.light().copyWith(
              extensions: [
                AppThemeColors.ofMode(isDark: false, mode: 'normal'),
              ],
            ),
            home: Scaffold(
              body: ListView(
                children: [
                  TimelineMatchGroupCard(
                    groupId: groupId,
                    groupList: sampleGroupMatches,
                    groupComments: const [],
                    categoryName: '一般の部',
                    teamName: '赤道場',
                    label: '団体戦',
                    isReadOnlyUI: false,
                    canManageTournamentUI: true,
                    isDark: false,
                    tournamentId: tournamentId,
                    ownTeams: const ['赤道場'],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 団体戦グループカードが表示されていること
      expect(find.text('赤道場 vs 白道場'), findsOneWidget);

      // カードを左にドラッグして Slidable の削除アクションを表示
      await tester.drag(find.text('赤道場 vs 白道場'), const Offset(-300, 0));
      await tester.pumpAndSettle();

      // 「削除」のアクションボタンを見つけてタップ
      final deleteActionFinder = find.widgetWithText(InkWell, '削除');
      expect(deleteActionFinder, findsWidgets);
      await tester.tap(deleteActionFinder.first);
      await tester.pumpAndSettle();

      // 確認ダイアログが表示されること
      expect(find.text('グループ全削除の確認'), findsOneWidget);
      expect(find.textContaining('5件'), findsOneWidget);

      // 「全削除する」ボタンをタップ
      final confirmButtonFinder = find.widgetWithText(ElevatedButton, '全削除する');
      expect(confirmButtonFinder, findsOneWidget);
      await tester.tap(confirmButtonFinder);
      await tester.pumpAndSettle();

      // 5件すべての試合IDが一度にアトミック一括削除されたこと
      final expectedIds = [
        'match_senpo',
        'match_jiho',
        'match_chuken',
        'match_fukuso',
        'match_taisho',
      ];
      expect(mockLocalRepo.bulkDeletedIds, containsAll(expectedIds));
      expect(mockLocalRepo.bulkDeletedIds.length, equals(5));
    });
  });
}
