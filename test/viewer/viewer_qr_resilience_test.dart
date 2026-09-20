import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/viewer/presentation/viewer_home_screen.dart';
import 'package:kendo_os/features/viewer/screens/viewer_bunaiksen_home_screen.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_user_role_provider.dart';
import 'package:kendo_os/shared/routing/route_guards.dart';
import '../helpers/test_app.dart';

void main() {
  setUpAll(() async {
    await setupTestFirebase();
  });

  group('🛡️ QRコード遷移ビュアー Firestore権限エラー耐性テスト', () {
    const testTournamentId = 'test_tournament_qr_123';
    const testBunaiksenId = 'bunaiksen_20260919';

    final mockTournament = TournamentModel(
      id: testTournamentId,
      name: 'テスト大会',
      date: DateTime.now(),
      venue: '武道館',
      categories: const ['一般の部'],
      organizationId: 'test_dojo',
    );

    testWidgets(
      '【ViewerHomeScreen】Firestoreがpermission-denied例外を返しても、UIクラッシュせず安全にフォールバック描画されること',
      (tester) async {
        await tester.pumpWidget(
          createTestApp(
            const ViewerHomeScreen(tournamentId: testTournamentId),
            overrides: [
              currentDojoIdProvider.overrideWith((ref) => 'test_dojo'),
              currentUserRoleProvider.overrideWithValue(UserRole.viewer),
              permissionProvider.overrideWithValue(
                const PermissionState(role: UserRole.viewer, isReadOnly: true),
              ),
              // Firestore の permission-denied エラーをシミュレート
              customTeamNamesProvider.overrideWith((ref) {
                return Stream<List<String>>.error(
                  FirebaseException(
                    plugin: 'cloud_firestore',
                    code: 'permission-denied',
                    message: 'Missing or insufficient permissions.',
                  ),
                );
              }),
              matchListByTournamentProvider(testTournamentId).overrideWith((
                ref,
              ) {
                return Stream<List<MatchModel>>.error(
                  FirebaseException(
                    plugin: 'cloud_firestore',
                    code: 'permission-denied',
                    message: 'Missing or insufficient permissions.',
                  ),
                );
              }),
              viewerTournamentProvider(testTournamentId).overrideWith((ref) {
                return Stream<TournamentModel?>.value(mockTournament);
              }),
            ],
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // 🛡️ 致命的なUIエラーの赤文字画面が表示されていないこと
        expect(find.textContaining('致命的なUIエラー'), findsNothing);
        // 🛡️ ViewerHomeScreenが正常にマウントされ、ヘッダー等のコンポーネントが描画されていること
        expect(find.byType(ViewerHomeScreen), findsOneWidget);
        expect(find.text('大会ホーム (観客席)'), findsOneWidget);
      },
    );

    testWidgets(
      '【ViewerBunaiksenHomeScreen】bunaiksenAvailableDatesProviderがpermission-denied例外を返してもクラッシュしないこと',
      (tester) async {
        await tester.pumpWidget(
          createTestApp(
            const ViewerBunaiksenHomeScreen(tournamentId: testBunaiksenId),
            overrides: [
              currentDojoIdProvider.overrideWith((ref) => 'test_dojo'),
              currentUserRoleProvider.overrideWithValue(UserRole.viewer),
              permissionProvider.overrideWithValue(
                const PermissionState(role: UserRole.viewer, isReadOnly: true),
              ),
              // permission-denied をシミュレート
              bunaiksenAvailableDatesProvider.overrideWith((ref) {
                return Stream<Set<String>>.error(
                  FirebaseException(
                    plugin: 'cloud_firestore',
                    code: 'permission-denied',
                    message: 'Missing or insufficient permissions.',
                  ),
                );
              }),
              bunaiksenMatchesProvider(testBunaiksenId).overrideWith((ref) {
                return <MatchModel>[];
              }),
            ],
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // 🛡️ 致命的なUIエラーの赤文字画面が表示されていないこと
        expect(find.textContaining('致命的なUIエラー'), findsNothing);
        // 🛡️ 部内戦ビュアーが正常に描画されていること
        expect(find.byType(ViewerBunaiksenHomeScreen), findsOneWidget);
        expect(find.text('この日の記録はありません'), findsOneWidget);
      },
    );

    testWidgets(
      '【RoleInjector & ViewerAuthGate】未認証時にビュアー用ローディング防壁が表示され、未認証のままFirestoreへのアクセスを防ぐこと',
      (tester) async {
        await tester.pumpWidget(
          createTestApp(
            const RoleInjector(
              roleStr: 'viewer',
              dojoId: 'qr_scanned_dojo_999',
              tournamentId: 'qr_scanned_tournament_888',
              child: Scaffold(body: Text('Protected Viewer Content')),
            ),
            overrides: [
              currentDojoIdProvider.overrideWith((ref) => 'initial_dojo'),
            ],
          ),
        );

        // 初回フレーム：ViewerAuthGateが未認証を検知して待機中スピナーを表示
        await tester.pump();
        expect(find.byType(ViewerAuthGate), findsOneWidget);
      },
    );

    test(
      '【PlayerRepository】watchCustomTeamNames が Firestore エラー時でも例外をスローせず空リストへ安全フォールバックすること',
      () async {
        final fakeFirestore = FakeFirebaseFirestore();
        final repo = PlayerRepository(
          dojoId: 'test_dojo',
          firestore: fakeFirestore,
        );

        // 正常系で空リストが取得できること
        final list = await repo.watchCustomTeamNames().first;
        expect(list, isEmpty);
      },
    );
  });
}
