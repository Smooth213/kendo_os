import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/domain/entities/match_comment_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/comment_repository.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';

void main() {
  group('🛡️ コメント管理およびWeb用通信設定（QUIC対策）の検証テスト', () {
    test('1. FirestoreのWeb用自動ロングポーリング設定が正しく定義可能であること', () {
      const settings = Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        webExperimentalAutoDetectLongPolling: true,
      );

      expect(settings.persistenceEnabled, isTrue);
      expect(settings.cacheSizeBytes, equals(Settings.CACHE_SIZE_UNLIMITED));
      expect(
        settings.webExperimentalAutoDetectLongPolling,
        isTrue,
        reason: 'WebアプリでのQUIC切断/タイムアウトエラー対策としての自動ロングポーリング検知が有効化されていること',
      );
    });

    test(
      '2. コメントリポジトリがテナント別（/organizations/{dojoId}/tournaments/{tournamentId}/comments）に保存され、ルート階層へ漏洩しないこと',
      () async {
        final fakeFirestore = FakeFirebaseFirestore();
        final testDojoId = 'dojo_test_999';
        final testTournamentId = 'tournament_test_888';

        final container = ProviderContainer(
          overrides: [
            currentDojoIdProvider.overrideWith((ref) => testDojoId),
            commentRepositoryProvider.overrideWith((ref) {
              final dojoId = ref.watch(currentDojoIdProvider);
              return CommentRepository(fakeFirestore, dojoId);
            }),
          ],
        );

        final repo = container.read(commentRepositoryProvider);
        final comment = MatchCommentModel(
          id: 'comment_123',
          tournamentId: testTournamentId,
          category: '一般の部',
          groupName: '東京Aチーム',
          text: '第一試合場 開始',
          order: 100.0,
        );

        // 1. コメントを保存
        await repo.saveComment(comment);

        // 2. ルートレベルの「/comments」コレクションには何も入っていないことを検証
        final rootDocs = await fakeFirestore.collection('comments').get();
        expect(rootDocs.docs, isEmpty, reason: '旧仕様のルートコレクションには保存されてはならない');

        // 3. テナント別の正しい階層に保存されていることを検証
        final nestedDocRef = fakeFirestore
            .collection('organizations')
            .doc(testDojoId)
            .collection('tournaments')
            .doc(testTournamentId)
            .collection('comments')
            .doc('comment_123');

        final nestedSnapshot = await nestedDocRef.get();
        expect(
          nestedSnapshot.exists,
          isTrue,
          reason: '正しいテナント別サブコレクションに保存されていること',
        );
        expect(nestedSnapshot.data()?['text'], equals('第一試合場 開始'));

        // 4. ストリーム経由で取得できることの検証
        final streamResult = await repo.watchComments(testTournamentId).first;
        expect(streamResult.length, equals(1));
        expect(streamResult.first.id, equals('comment_123'));
        expect(streamResult.first.text, equals('第一試合場 開始'));

        // 5. コメントの削除検証
        await repo.deleteComment(testTournamentId, 'comment_123');
        final afterDeleteSnapshot = await nestedDocRef.get();
        expect(
          afterDeleteSnapshot.exists,
          isFalse,
          reason: '削除されたらドキュメントが存在しなくなること',
        );
      },
    );
  });
}
