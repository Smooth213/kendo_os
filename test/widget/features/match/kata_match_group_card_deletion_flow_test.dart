import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../helpers/safe_pump_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_individual_player_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_player_match_classifier.dart';
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
  group('[Widget] 剣道形対戦枠スワイプ削除フロー統合テスト', () {
    testWidgets('形試合が対戦枠として分類されスワイプ削除から確定ダイアログを経て削除されること', (tester) async {
      final mockLocalRepo = TrackingLocalMatchRepository();
      final mockRemoteRepo = TrackingMatchRepository();

      const tournamentId = 'test_tournament_kata';
      const groupId = 'group_kata_1';

      final sampleKataMatch = [
        const MatchModel(
          id: 'kata_match_001',
          tournamentId: tournamentId,
          groupName: groupId,
          matchType: '日本剣道形',
          redName: '道上剣友会:皿田 脩人(打太刀)・塚本 大道(仕太刀)',
          whiteName: '友道館:佐藤 健一(打太刀)・鈴木 次郎(仕太刀)',
          status: 'waiting',
          order: 1.0,
          rule: MatchRule(isKataMatch: true, hasHantei: true),
        ),
      ];

      // 1. 分類ロジックで sortedPlayers に入ることを確認
      final classified = TimelinePlayerMatchClassifier.classifyTeamMatches(
        teamMatchesList: sampleKataMatch,
        teamName: '道上剣友会',
        sanitizedQuery: '',
        matchedMatchIds: {},
        matchedGroupNames: {},
        ownTeams: const ['道上剣友会'],
      );
      expect(classified.sortedGroups.isEmpty, isTrue);
      expect(classified.sortedPlayers.length, 1);
      const pairName = '皿田 脩人(打太刀)・塚本 大道(仕太刀)';
      expect(classified.sortedPlayers.first.key, pairName);

      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localMatchRepositoryProvider.overrideWithValue(mockLocalRepo),
            matchRepositoryProvider.overrideWithValue(mockRemoteRepo),
            matchListProvider.overrideWithValue(sampleKataMatch),
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
                    playerName: pairName,
                    playerMatches: sampleKataMatch,
                    playerComments: [],
                    categoryName: '形の部',
                    teamName: '道上剣友会',
                    isReadOnlyUI: false,
                    isDark: false,
                    permissions: PermissionState(
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

      // 形ペア名が表示されていること
      expect(find.textContaining(pairName, findRichText: true), findsWidgets);

      // 左にドラッグして Slidable 削除を表示
      await tester.drag(
        find.byKey(const ValueKey('player_slidable_$pairName')),
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
      expect(find.textContaining('1件'), findsOneWidget);

      // 「全削除する」ボタンをタップ
      final confirmButtonFinder = find.widgetWithText(ElevatedButton, '全削除する');
      expect(confirmButtonFinder, findsOneWidget);
      await tester.tap(confirmButtonFinder);
      await tester.safePumpAndSettle();

      // 試合IDが削除されたこと
      expect(mockLocalRepo.bulkDeletedIds, contains('kata_match_001'));
      expect(mockLocalRepo.bulkDeletedIds.length, 1);
    });
  });
}
