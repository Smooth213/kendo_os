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
  group('🛡️ Bunaiksen Multi-Tenant Isolation & Date Discovery Tests', () {
    late MockLocalMatchRepository mockLocalRepo;

    setUp(() {
      mockLocalRepo = MockLocalMatchRepository();

      // Isar watch stub (not expected to trigger in this test, but registered for safety)
      when(
        () => mockLocalRepo.watchAllLocalMatches(),
      ).thenAnswer((_) => Stream.value(<MatchModel>[]));
    });

    test('1. 他道場（別テナント）データの完全隔離 ＆ 1週間以上の過去日付全期間自動点灯アサート', () async {
      final fakeFirestore = FakeFirebaseFirestore();

      // ① 自分の道場 (test202) の本日/直近の試合データ
      await fakeFirestore
          .collection('organizations')
          .doc('test202')
          .collection('tournaments')
          .doc('bunaiksen_20260622')
          .collection('matches')
          .doc('match_01')
          .set({
            'tournamentId': 'bunaiksen_20260622',
            'redName': '自分1',
            'whiteName': '自分2',
          });

      // ② 自分の道場 (test202) の1週間以上前の過去日付データ (例: 2026/06/10)
      await fakeFirestore
          .collection('organizations')
          .doc('test202')
          .collection('tournaments')
          .doc('bunaiksen_20260610')
          .collection('matches')
          .doc('match_past')
          .set({
            'tournamentId': 'bunaiksen_20260610',
            'redName': '過去1',
            'whiteName': '過去2',
          });

      // ③ 他道場 (test201) の試合データ (混入ドキュメント - 排除対象)
      await fakeFirestore
          .collection('organizations')
          .doc('test201')
          .collection('tournaments')
          .doc('bunaiksen_20260620')
          .collection('matches')
          .doc('match_02')
          .set({
            'tournamentId': 'bunaiksen_20260620',
            'redName': '他所1',
            'whiteName': '他所2',
          });

      // ProviderContainerを設定（道場IDは 自分の道場: test202）
      final container = ProviderContainer(
        overrides: [
          firestoreProvider.overrideWithValue(fakeFirestore),
          currentDojoIdProvider.overrideWith((ref) => 'test202'),
          localMatchRepositoryProvider.overrideWithValue(mockLocalRepo),
        ],
      );

      // bunaiksenAvailableDatesProvider の値を取得
      final Set<String> dates = await container.read(
        bunaiksenAvailableDatesProvider.future,
      );

      // 🔍 隔離アサーション: 自分の道場の日付のみが含まれており、他道場 (test201) の日付は排除されていること
      expect(dates.contains('20260622'), isTrue, reason: '自テナントの試合日は抽出されるべきです');
      expect(
        dates.contains('20260610'),
        isTrue,
        reason: '1週間以上前の自テナントの過去日付も自動で抽出されるべきです',
      );
      expect(
        dates.contains('20260620'),
        isFalse,
        reason: '他テナント(test201)の日付は厳格に排除されるべきです',
      );

      // Setのサイズが正しく2であること（他道場のデータが入っていないこと）
      expect(dates.length, 2, reason: '抽出された日付Setは自道場の2件のみであるべきです');
    });
  });
}
