import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mocktail/mocktail.dart';

import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';

class MockLocalMatchRepository extends Mock implements LocalMatchRepository {}

void main() {
  group('🛡️ Bunaiksen Web Stream Loop Prevention Tests', () {
    late MockLocalMatchRepository mockLocalRepo;

    setUp(() {
      mockLocalRepo = MockLocalMatchRepository();
      debugIsWebOverride = true; // Webモードをシミュレート
    });

    tearDown(() {
      debugIsWebOverride = false; // クリーンアップ
    });

    test(
      '1. matchListByTournamentProvider の Web環境下単方向直列ロード ＆ 無限ループ防止検証',
      () async {
        final fakeFirestore = FakeFirebaseFirestore();
        final targetDateId = 'bunaiksen_20260621';

        // Firestoreにテスト用試合データを書き込む
        await fakeFirestore
            .collection('organizations')
            .doc('test202')
            .collection('tournaments')
            .doc(targetDateId)
            .collection('matches')
            .doc('match_web_01')
            .set({
              'tournamentId': targetDateId,
              'redName': 'ウェブ赤',
              'whiteName': 'ウェブ白',
              'matchType': '個人戦',
              'status': 'waiting',
              'order': 1.0,
              'events': [],
            });

        final container = ProviderContainer(
          overrides: [
            firestoreProvider.overrideWithValue(fakeFirestore),
            currentDojoIdProvider.overrideWith((ref) => 'test202'),
            localMatchRepositoryProvider.overrideWithValue(mockLocalRepo),
          ],
        );

        // リッスンして購読状態を作る
        final subscription = container.listen(
          matchListByTournamentProvider(targetDateId),
          (previous, next) {},
        );

        // ロードを待機し、1回で正しく解決されることを確認 (タイムアウト付きで無限ループになっていないことを検証)
        final Future<List<MatchModel>> loadFuture = container.read(
          matchListByTournamentProvider(targetDateId).future,
        );

        final List<MatchModel> resultMatches = await loadFuture.timeout(
          const Duration(seconds: 3),
          onTimeout: () =>
              throw TimeoutException('Webストリームのロードが無限ループ等によりタイムアウトしました'),
        );

        expect(resultMatches.length, 1);
        expect(resultMatches.first.id, 'match_web_01');
        expect(resultMatches.first.redName, 'ウェブ赤');

        // 🔍 キャッシュの単方向更新アサーション: webCurrentTournamentMatchesProvider が更新されていること
        final cachedMatches = container.read(
          webCurrentTournamentMatchesProvider,
        );
        expect(cachedMatches.length, 1);
        expect(cachedMatches.first.id, 'match_web_01');

        // 🔍 キャッシュの単方向更新アサーション: webCurrentTournamentIdProvider が更新されていること
        final cachedId = container.read(webCurrentTournamentIdProvider);
        expect(cachedId, targetDateId);

        subscription.close();
      },
    );
  });
}
