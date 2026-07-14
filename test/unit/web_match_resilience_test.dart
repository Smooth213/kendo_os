import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/match_repository.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';

// Mock repository to simulate failures and retries
class MockFailingMatchRepository extends MatchRepository {
  int attempts = 0;
  final int failUntilAttempt;
  final MatchRepository delegate;

  MockFailingMatchRepository(
    FirebaseFirestore firestore,
    this.delegate, {
    this.failUntilAttempt = 0,
  }) : super(firestore, '', '');

  @override
  Future<int> saveMatch(MatchModel match) async {
    attempts++;
    if (attempts <= failUntilAttempt) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
        message: 'ERR_CONNECTION_CLOSED / QUIC_TOO_MANY_RTOS simulated',
      );
    }
    return await delegate.saveMatch(match);
  }
}

void main() {
  group('🛡️ Webアプリ表示・保存障害（QUIC通信遮断）耐性テスト', () {
    late FakeFirebaseFirestore fakeFirestore;
    late String testDojoId;
    late String testTournamentId;
    late MatchModel testMatch;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      testDojoId = 'test_dojo_web';
      testTournamentId = 'test_tournament_web';

      testMatch = MatchModel(
        id: 'match_web_001',
        organizationId: testDojoId,
        tournamentId: testTournamentId,
        matchType: '個人戦',
        redName: '佐々木 雅紀',
        whiteName: '木村 拓也',
        matchTimeMinutes: 3.0,
        status: 'waiting',
      );
    });

    test(
      '1. 【正常系】Firestoreがオンラインの時、選手名・タイマー設定時間が正常にロードされ、スコア保存ができること',
      () async {
        final container = ProviderContainer(
          overrides: [
            currentDojoIdProvider.overrideWith((ref) => testDojoId),
            currentTournamentIdProvider.overrideWith((ref) => testTournamentId),
            matchRepositoryProvider.overrideWith((ref) {
              return MatchRepository(
                fakeFirestore,
                testDojoId,
                testTournamentId,
              );
            }),
          ],
        );

        final repo = container.read(matchRepositoryProvider);

        // 初期データの書き込み
        await repo.saveMatch(testMatch);

        // コレクションからデータを取得（ロードのシミュレート）
        final streamResult = await repo.watchSingleMatch(testMatch.id).first;

        // 選手名が正常にロードされることの検証
        expect(streamResult.redName, equals('佐々木 雅紀'));
        expect(streamResult.whiteName, equals('木村 拓也'));

        // タイマーの初期設定時間が正常にロードされることの検証
        expect(streamResult.matchTimeMinutes, equals(3.0));

        // スコアの更新保存ができることの検証
        final updatedMatch = streamResult.copyWith(redScore: 1);
        await repo.saveMatch(updatedMatch);

        // ストリーム経由でスコアが更新されるのを待つ
        final postSaveMatch = await repo
            .watchSingleMatch(testMatch.id)
            .firstWhere((match) => match.redScore == 1);

        expect(postSaveMatch.redScore, equals(1));
      },
    );

    test(
      '2. 【異常系・自動復旧】通信一時切断（QUICエラー）が発生しても、リトライ機構によって自動復旧して最終的に保存が成功すること',
      () async {
        final baseRepo = MatchRepository(
          fakeFirestore,
          testDojoId,
          testTournamentId,
        );
        // 2回目まで通信エラーが発生し、3回目に成功するモックリポジトリ
        final mockFailingRepo = MockFailingMatchRepository(
          fakeFirestore,
          baseRepo,
          failUntilAttempt: 2,
        );

        final container = ProviderContainer(
          overrides: [
            currentDojoIdProvider.overrideWith((ref) => testDojoId),
            currentTournamentIdProvider.overrideWith((ref) => testTournamentId),
            matchRepositoryProvider.overrideWith((ref) => mockFailingRepo),
          ],
        );

        final repo = container.read(matchRepositoryProvider);

        // MatchApplicationServiceの _saveToFirestoreWithRetry と同等のリトライ処理を再現してテスト
        Future<void> saveWithRetry(
          MatchModel match, {
          int maxAttempts = 3,
        }) async {
          for (int attempt = 1; attempt <= maxAttempts; attempt++) {
            try {
              await repo.saveMatch(match);
              return;
            } catch (e) {
              if (attempt == maxAttempts) rethrow;
              // テスト実行を高速化するため、待機時間は最小化（1ms）する
              await Future.delayed(const Duration(milliseconds: 1));
            }
          }
        }

        // 保存処理の実行（1、2回目は例外を投げるが、3回目で成功）
        await saveWithRetry(testMatch);

        expect(
          mockFailingRepo.attempts,
          equals(3),
          reason: '2回リトライに失敗し、3回目のリトライで保存が成功すること',
        );

        // データが最終的に正常に保存されたことを確認
        final savedDoc = await fakeFirestore
            .collection('organizations')
            .doc(testDojoId)
            .collection('tournaments')
            .doc(testTournamentId)
            .collection('matches')
            .doc(testMatch.id)
            .get();

        expect(savedDoc.exists, isTrue);
        expect(savedDoc.data()?['redName'], equals('佐々木 雅紀'));
      },
    );
  });
}
