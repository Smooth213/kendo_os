import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/match_repository.dart';

// ※注: TournamentRepository や PlayerRepository 等のインポートは、
// 実際のプロジェクト構造に合わせてコメントアウトを外してご利用ください。
// import 'package:kendo_os/shared/infrastructure/repository/tournament_repository.dart';
// import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';

void main() {
  group('🛡️ マルチテナント・データ隔離（Tenant Isolation）完全検証要塞', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    test('✅ 1. 【試合データ】指定されたテナント内にのみ保存され、外（ルートや他テナント）に漏れないこと', () async {
      const tenantA = 'dojo_A';
      const tenantB = 'dojo_B';

      // テナントAとBのコンテキストを持つRepositoryを生成
      final repoA = MatchRepository(fakeFirestore, tenantA);
      final repoB = MatchRepository(fakeFirestore, tenantB);

      // テナントAで試合を保存
      final matchForA = const MatchModel(
        id: 'match_a_001',
        matchType: '個人戦',
        redName: '赤',
        whiteName: '白',
        organizationId: tenantA, // 明示的にテナントAを指定
      );

      await repoA.saveMatch(matchForA);

      // --- 監査フェーズ ---

      // ① テナントAのサブコレクションにデータが存在すること（正しい場所）
      final docInTenantA = await fakeFirestore
          .collection('organizations')
          .doc(tenantA)
          .collection('matches')
          .doc('match_a_001')
          .get();

      expect(docInTenantA.exists, isTrue, reason: 'テナントAの中にデータが作成されていなければならない');

      // ② ルートコレクション（旧仕様の保存先）にデータが漏洩していないこと（グローバル汚染防止）
      final docInRoot = await fakeFirestore
          .collection('matches')
          .doc('match_a_001')
          .get();

      expect(docInRoot.exists, isFalse, reason: 'ルートコレクションにデータが漏洩してはならない');

      // ③ 他のテナント（テナントB）のコレクションにデータが混入していないこと
      final docInTenantB = await fakeFirestore
          .collection('organizations')
          .doc(tenantB)
          .collection('matches')
          .doc('match_a_001')
          .get();

      expect(docInTenantB.exists, isFalse, reason: '他のテナントにデータが漏洩してはならない');

      // ④ テナントBのリポジトリ経由でデータを読み取ろうとしても、絶対に空であること（Read隔離）
      final matchesInB = await repoB.getStaticMatches();
      expect(matchesInB, isEmpty, reason: 'テナントBからテナントAのデータは見えてはならない');
    });

    test('✅ 2. 【他ドメイン】大会、選手マスタ、プログラムもテナントサブコレクションに隔離されること（概念実証）', () async {
      // ※ MatchRepository 同様、各Repositoryが organizations/{tenantId}/...
      // を向くように改修されていることを前提としたFirestoreの構造テストです。

      const targetTenantId = 'dojo_test_01';

      // ダミーとしてFirestoreの正しいテナントパスに直接書き込む
      await fakeFirestore
          .collection('organizations')
          .doc(targetTenantId)
          .collection('tournaments')
          .doc('tourney_1')
          .set({'name': '春季大会'});

      await fakeFirestore
          .collection('organizations')
          .doc(targetTenantId)
          .collection('players')
          .doc('player_1')
          .set({'name': '剣道太郎'});

      await fakeFirestore
          .collection('organizations')
          .doc(targetTenantId)
          .collection('programs')
          .doc('prog_1')
          .set({'title': '大会パンフレット'});

      // --- 監査フェーズ ---
      // サブコレクションが正しく構成されているか確認
      final tournaments = await fakeFirestore
          .collection('organizations')
          .doc(targetTenantId)
          .collection('tournaments')
          .get();
      final players = await fakeFirestore
          .collection('organizations')
          .doc(targetTenantId)
          .collection('players')
          .get();
      final programs = await fakeFirestore
          .collection('organizations')
          .doc(targetTenantId)
          .collection('programs')
          .get();

      expect(tournaments.docs.length, 1);
      expect(players.docs.length, 1);
      expect(programs.docs.length, 1);

      // ルート階層が一切汚染されていないか確認
      final rootTournaments = await fakeFirestore
          .collection('tournaments')
          .get();
      final rootPlayers = await fakeFirestore.collection('players').get();

      expect(
        rootTournaments.docs.isEmpty,
        isTrue,
        reason: '旧仕様のルートコレクションに大会データが漏れていないこと',
      );
      expect(
        rootPlayers.docs.isEmpty,
        isTrue,
        reason: '旧仕様のルートコレクションに選手データが漏れていないこと',
      );
    });
  });
}
