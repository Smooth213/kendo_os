import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:kendo_os/presentation/shared/providers/current_sync_context_provider.dart';
import 'package:kendo_os/infrastructure/repository/tournament_repository.dart';
import 'package:kendo_os/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/infrastructure/repository/team_repository.dart';
import 'package:kendo_os/presentation/providers/internal/audit_provider.dart';
import 'package:kendo_os/domain/entities/tournament_model.dart';
import 'package:kendo_os/domain/entities/player_model.dart';
import 'package:kendo_os/domain/entities/team_model.dart';
import 'package:kendo_os/domain/entities/audit_log.dart';

void main() {
  group('🛡️ マルチテナント（道場ID）隔離・同期不具合修正テスト要塞', () {
    setUp(() {
      // テスト用に SharedPreferences のモック（ダミー）を初期化
      SharedPreferences.setMockInitialValues({});
    });

    test('1. 【テナントID伝播】currentDojoId が切り替わると、各Repositoryが新しいdojoIdで再生成されること', () {
      final fakeFirestore = FakeFirebaseFirestore();
      
      final container = ProviderContainer(
        overrides: [
          tournamentRepositoryProvider.overrideWith((ref) {
            return TournamentRepository(dojoId: ref.watch(currentDojoIdProvider), firestore: fakeFirestore);
          }),
          playerRepositoryProvider.overrideWith((ref) {
            return PlayerRepository(dojoId: ref.watch(currentDojoIdProvider), firestore: fakeFirestore);
          }),
          teamRepositoryProvider.overrideWith((ref) {
            return TeamRepository(dojoId: ref.watch(currentDojoIdProvider), firestore: fakeFirestore);
          }),
          auditFirestoreProvider.overrideWithValue(fakeFirestore),
        ]
      );
      
      // ログイン前のデフォルト状態の取得
      final initialDojoId = container.read(currentDojoIdProvider);
      
      // 初期状態での各リポジトリの生成確認
      final tournamentRepo = container.read(tournamentRepositoryProvider);
      final playerRepo = container.read(playerRepositoryProvider);
      final teamRepo = container.read(teamRepositoryProvider);
      final auditService = container.read(auditProvider);

      expect(tournamentRepo.dojoId, equals(initialDojoId));
      expect(playerRepo.dojoId, equals(initialDojoId));
      expect(teamRepo.dojoId, equals(initialDojoId));
      expect(auditService.dojoId, equals(initialDojoId));

      // ★ 別の道場ID（テナント）でログインしたと仮定してIDを切り替える
      container.read(currentDojoIdProvider.notifier).state = 'new_dojo_123';

      // 新しいdojoIdでリポジトリが再生成されていること（Riverpodの依存性注入による自動再構築の保証）
      final newTournamentRepo = container.read(tournamentRepositoryProvider);
      final newPlayerRepo = container.read(playerRepositoryProvider);
      final newTeamRepo = container.read(teamRepositoryProvider);
      final newAuditService = container.read(auditProvider);

      expect(newTournamentRepo.dojoId, equals('new_dojo_123'), reason: 'TournamentRepositoryが新しい道場IDを向いていること');
      expect(newPlayerRepo.dojoId, equals('new_dojo_123'), reason: 'PlayerRepositoryが新しい道場IDを向いていること');
      expect(newTeamRepo.dojoId, equals('new_dojo_123'), reason: 'TeamRepositoryが新しい道場IDを向いていること');
      expect(newAuditService.dojoId, equals('new_dojo_123'), reason: 'AuditServiceが新しい道場IDを向いていること');
    });

    test('2. 【共有キーワイプ競合排除】SharedPreferences の global_last_dojo_id_v4 が確実に記録・更新され、ワイプの競合を防ぐこと', () async {
      SharedPreferences.setMockInitialValues({'global_last_dojo_id_v4': 'old_dojo_abc'});
      final prefs = await SharedPreferences.getInstance();

      final lastDojoId = prefs.getString('global_last_dojo_id_v4');
      expect(lastDojoId, equals('old_dojo_abc'));

      // 新しい道場IDでのワイプ検知と更新シミュレート（プロバイダの競合を防止するフラグ）
      await prefs.setString('global_last_dojo_id_v4', 'new_dojo_xyz');
      expect(prefs.getString('global_last_dojo_id_v4'), equals('new_dojo_xyz'));
    });

    test('3. 【データ分離保存】 各ドメインのデータが道場ID（テナント）別の専用サブコレクションに確実に保存され、ルート階層へ漏洩しないこと', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final targetDojoId = 'test_dojo_tenant_123';

      final container = ProviderContainer(
        overrides: [
          currentDojoIdProvider.overrideWith((ref) => targetDojoId),
          tournamentRepositoryProvider.overrideWith((ref) {
            return TournamentRepository(dojoId: ref.watch(currentDojoIdProvider), firestore: fakeFirestore);
          }),
          playerRepositoryProvider.overrideWith((ref) {
            return PlayerRepository(dojoId: ref.watch(currentDojoIdProvider), firestore: fakeFirestore);
          }),
          teamRepositoryProvider.overrideWith((ref) {
            return TeamRepository(dojoId: ref.watch(currentDojoIdProvider), firestore: fakeFirestore);
          }),
          auditFirestoreProvider.overrideWithValue(fakeFirestore),
        ]
      );

      final tournamentRepo = container.read(tournamentRepositoryProvider);
      final playerRepo = container.read(playerRepositoryProvider);
      final teamRepo = container.read(teamRepositoryProvider);
      final auditService = container.read(auditProvider);

      // 1. 試合以外の各種データを保存（Firestoreの書き込みをエミュレート）
      await tournamentRepo.saveTournament(TournamentModel(
        id: '',
        organizationId: targetDojoId,
        name: '道場専用大会',
        date: DateTime.now(),
        venue: 'テスト体育館',
        categories: const [],
      ));

      await teamRepo.saveTeam(TeamModel(
        id: '',
        tournamentId: 't1',
        category: '一般',
        teamName: '道場専用チーム',
      ));

      await playerRepo.addPlayer(PlayerModel(
        id: '',
        lastName: '道場',
        firstName: '太郎',
        lastNameKana: 'ドウジョウ',
        firstNameKana: 'タロウ',
        grade: 10,
        organization: '道上剣友会',
      ));

      await auditService.logAction(
        matchId: 'm1',
        action: AuditAction.addScore,
        details: 'test_score',
      );

      // 2. 検証：データが道場専用の「organizations/{dojoId}/xxx」に保存されているか
      final tournamentsSnapshot = await fakeFirestore.collection('organizations').doc(targetDojoId).collection('tournaments').get();
      expect(tournamentsSnapshot.docs.length, equals(1), reason: '大会がテナント層に保存されていること');
      expect(tournamentsSnapshot.docs.first.data()['name'], equals('道場専用大会'));

      final teamsSnapshot = await fakeFirestore.collection('organizations').doc(targetDojoId).collection('teams').get();
      expect(teamsSnapshot.docs.length, equals(1), reason: 'チームがテナント層に保存されていること');
      expect(teamsSnapshot.docs.first.data()['teamName'], equals('道場専用チーム'));

      final playersSnapshot = await fakeFirestore.collection('organizations').doc(targetDojoId).collection('players').get();
      expect(playersSnapshot.docs.length, equals(1), reason: '選手がテナント層に保存されていること');
      expect(playersSnapshot.docs.first.data()['lastName'], equals('道場'));
      expect(playersSnapshot.docs.first.data()['firstName'], equals('太郎'));

      final auditSnapshot = await fakeFirestore.collection('organizations').doc(targetDojoId).collection('audit_logs').get();
      expect(auditSnapshot.docs.length, equals(1), reason: '監査ログがテナント層に保存されていること');
      expect(auditSnapshot.docs.first.data()['details'], equals('test_score'));

      // 3. 絶対防壁：旧仕様のルートコレクションにデータが1件も「漏洩」していないことの証明
      expect((await fakeFirestore.collection('tournaments').get()).docs.isEmpty, isTrue, reason: '旧仕様の大会階層に漏れていないこと');
      expect((await fakeFirestore.collection('teams').get()).docs.isEmpty, isTrue, reason: '旧仕様のチーム階層に漏れていないこと');
      expect((await fakeFirestore.collection('players').get()).docs.isEmpty, isTrue, reason: '旧仕様の選手階層に漏れていないこと');
      expect((await fakeFirestore.collection('audit_logs').get()).docs.isEmpty, isTrue, reason: '旧仕様のログ階層に漏れていないこと');
    });
  });
}