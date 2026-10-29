import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/safe_pump_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_individual_player_card.dart';
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
  group('[Widget] 個人戦カードスワイプ削除フロー統合テスト', () {
    testWidgets('個人戦カード自体を左スワイプして確認ダイアログから全試合一括削除できること', (tester) async {
      final mockLocalRepo = TrackingLocalMatchRepository();
      final mockRemoteRepo = TrackingMatchRepository();

      const tournamentId = 'test_tournament_indiv';
      const playerName = '佐藤 太郎';

      final samplePlayerMatches = [
        const MatchModel(
          id: 'indiv_match_001',
          tournamentId: tournamentId,
          matchType: '個人戦',
          redName: '道上剣友会:佐藤 太郎',
          whiteName: '友道館:鈴木 次郎',
          status: 'waiting',
          order: 1.0,
        ),
        const MatchModel(
          id: 'indiv_match_002',
          tournamentId: tournamentId,
          matchType: '個人戦',
          redName: '道上剣友会:佐藤 太郎',
          whiteName: '青藍館:高橋 三郎',
          status: 'waiting',
          order: 2.0,
        ),
      ];

      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localMatchRepositoryProvider.overrideWithValue(mockLocalRepo),
            matchRepositoryProvider.overrideWithValue(mockRemoteRepo),
            matchListProvider.overrideWithValue(samplePlayerMatches),
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
                  TimelineIndividualPlayerCard(
                    playerName: playerName,
                    playerMatches: samplePlayerMatches,
                    playerComments: const [],
                    categoryName: '小学生の部',
                    teamName: '道上剣友会',
                    isReadOnlyUI: false,
                    isDark: false,
                    permissions: const PermissionState(
                      role: UserRole.admin,
                      isReadOnly: false,
                      canManageTournament: true,
                      canDeleteData: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.safePumpAndSettle();

      // 選手アコーディオンが表示されていること
      expect(find.byKey(const ValueKey('player_佐藤 太郎')), findsOneWidget);

      // 左にドラッグして Slidable 削除を表示
      await tester.drag(
        find.byKey(const ValueKey('player_佐藤 太郎')),
        const Offset(-300, 0),
      );
      await tester.safePumpAndSettle();

      // 「削除」アクションをタップ
      final deleteActionFinder = find.widgetWithText(InkWell, '削除');
      expect(deleteActionFinder, findsWidgets);
      await tester.tap(deleteActionFinder.first);
      await tester.safePumpAndSettle();

      // 確認ダイアログが表示されること
      expect(find.text('試合削除の確認'), findsOneWidget);
      expect(find.textContaining('2件'), findsOneWidget);

      // 「全削除する」ボタンをタップ
      final confirmButtonFinder = find.widgetWithText(ElevatedButton, '全削除する');
      expect(confirmButtonFinder, findsOneWidget);
      await tester.tap(confirmButtonFinder);
      await tester.safePumpAndSettle();

      // 2試合とも削除されたこと
      expect(
        mockLocalRepo.bulkDeletedIds,
        containsAll(['indiv_match_001', 'indiv_match_002']),
      );
      expect(mockLocalRepo.bulkDeletedIds.length, 2);
    });
  });
}
