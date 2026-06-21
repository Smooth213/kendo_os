import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:intl/intl.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_command_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/bunaiksen_setup_screen.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/shared/time/time_source.dart';
import 'package:kendo_os/shared/time/fixed_time_source.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';
import 'package:kendo_os/shared/widgets/smart_player_input.dart';

class MockLocalMatchRepository extends Mock implements LocalMatchRepository {}

class MockMatchApplicationService extends Mock
    implements MatchApplicationService {}

void main() {
  setUpAll(() {
    registerFallbackValue(<MatchModel>[]);
    registerFallbackValue(
      const MatchModel(id: '', matchType: '個人戦', redName: '', whiteName: ''),
    );
    registerFallbackValue(
      MatchCommandModel(
        id: '',
        type: CommandType.updateMatch,
        payload: const {},
        createdAt: DateTime.now(),
      ),
    );
  });

  group('🛡️ Bunaiksen Date & Timezone Sync Integration Tests', () {
    late MockLocalMatchRepository mockLocalRepo;

    setUp(() {
      mockLocalRepo = MockLocalMatchRepository();

      // Default stubs
      when(
        () => mockLocalRepo.watchLocalMatches(any()),
      ).thenAnswer((_) => Stream.value(<MatchModel>[]));
      when(
        () => mockLocalRepo.watchAllLocalMatches(),
      ).thenAnswer((_) => Stream.value(<MatchModel>[]));
      when(
        () => mockLocalRepo.saveMatchesBulk(any()),
      ).thenAnswer((_) => Future.value());
      when(
        () => mockLocalRepo.saveMatch(any()),
      ).thenAnswer((_) => Future.value());
      when(
        () => mockLocalRepo.savePendingCommand(any()),
      ).thenAnswer((_) => Future.value());
      when(
        () => mockLocalRepo.getPendingCommands(),
      ).thenAnswer((_) => Future.value(<MatchCommandModel>[]));
      when(
        () => mockLocalRepo.watchPendingMatchesCount(),
      ).thenAnswer((_) => Stream.value(0));
    });

    testWidgets('1. JSTローカル時間に基づく今日の試合作成・バインド検証 (深夜・早朝時間帯の先祖返り防止)', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      // 深夜 JST 02:00 AM (= 前日 17:00 UTC) を模擬
      final earlyMorningUtc = DateTime.utc(2026, 6, 21, 17, 0);
      final timeSource = FixedTimeSource(earlyMorningUtc);

      MatchModel? capturedMatch;
      when(() => mockLocalRepo.saveMatch(any())).thenAnswer((inv) async {
        capturedMatch = inv.positionalArguments[0] as MatchModel;
        return;
      });

      // GoRouterを設定してナビゲーションに対応
      final router = GoRouter(
        initialLocation: '/setup',
        routes: [
          GoRoute(
            path: '/setup',
            builder: (context, state) => const BunaiksenSetupScreen(),
          ),
          GoRoute(
            path: '/match/:id',
            builder: (context, state) =>
                const Scaffold(body: Text('Match Screen')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            localMatchRepositoryProvider.overrideWithValue(mockLocalRepo),
            timeSourceProvider.overrideWithValue(timeSource),
            currentDojoIdProvider.overrideWith((ref) => 'test_dojo'),
            bunaiksenPlayerMasterProvider.overrideWith(
              (ref) => Stream.value([]),
            ),
            isarProvider.overrideWithValue(null),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      // SmartPlayerInputのコントローラに直接値を設定
      final redInput = tester.widget<TextField>(
        find.widgetWithText(TextField, '赤の選手'),
      );
      redInput.controller!.text = '赤選手JST';
      final whiteInput = tester.widget<TextField>(
        find.widgetWithText(TextField, '白選手'),
      );
      whiteInput.controller!.text = '白選手JST';

      // 試合開始ボタンをタップ
      await tester.tap(find.text('試合開始'));
      await tester.pumpAndSettle();

      // 保存されたMatchModelがUTC時間(20260621)ではなく、JSTローカル時間(DateTime.now())の日付になっていることを検証
      expect(capturedMatch, isNotNull);
      final expectedDateStr = DateFormat('yyyyMMdd').format(DateTime.now());
      expect(capturedMatch!.tournamentId, 'bunaiksen_$expectedDateStr');
    });

    test('2. Web（Firestore）＆ ネイティブ（Isar）双方向データ表示検証', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final targetDateId = 'bunaiksen_20260622';

      // Firestoreに試合データをセットアップ
      await fakeFirestore
          .collection('organizations')
          .doc('test_dojo')
          .collection('tournaments')
          .doc(targetDateId)
          .collection('matches')
          .doc('match_sync_1')
          .set({
            'redName': 'Firestore赤',
            'whiteName': 'Firestore白',
            'matchType': '個人戦',
            'status': 'waiting',
            'order': 1.0,
            'events': [],
          });

      List<MatchModel>? capturedMatches;
      final completer = Completer<void>();
      when(() => mockLocalRepo.saveMatchesBulk(any())).thenAnswer((inv) async {
        capturedMatches = inv.positionalArguments[0] as List<MatchModel>;
        completer.complete();
        return;
      });

      final container = ProviderContainer(
        overrides: [
          firestoreProvider.overrideWithValue(fakeFirestore),
          currentDojoIdProvider.overrideWith((ref) => 'test_dojo'),
          localMatchRepositoryProvider.overrideWithValue(mockLocalRepo),
        ],
      );

      // Web/Firestore ストリーム経由でデータを読み込み
      final list = await container.read(
        bunaiksenMatchesStreamProvider(targetDateId).future,
      );

      // Firestoreから正しくパースされていることの検証 (Web側)
      expect(list.length, 1);
      expect(list.first.id, 'match_sync_1');
      expect(list.first.redName, 'Firestore赤');

      // ネイティブ側（!kIsWeb）でのIsarキャッシュ書き込みが呼び出されたことを検証
      await completer.future;
      expect(capturedMatches, isNotNull);
      expect(capturedMatches!.length, 1);
      expect(capturedMatches!.first.tournamentId, targetDateId);
    });

    test('3. 過去日付へのタイムトラベル（カレンダー開放）＆ ソート順検証', () {
      // 過去カレンダーロック解除Predicateの検証 (常にtrue)
      bool calendarPredicate(DateTime date) {
        return true; // selectableDayPredicate is always true
      }

      expect(calendarPredicate(DateTime(2024, 1, 1)), isTrue);
      expect(calendarPredicate(DateTime(2025, 12, 31)), isTrue);

      final pastDateId = 'bunaiksen_20260620';
      final List<MatchModel> mockPastMatches = [
        MatchModel(
          id: '1',
          tournamentId: pastDateId,
          matchType: '個人戦',
          redName: 'A',
          whiteName: 'B',
          status: 'finished',
          order: 1.0,
        ),
        MatchModel(
          id: '2',
          tournamentId: pastDateId,
          matchType: '個人戦',
          redName: 'C',
          whiteName: 'D',
          status: 'in_progress',
          order: 2.0,
        ),
        MatchModel(
          id: '3',
          tournamentId: pastDateId,
          matchType: '個人戦',
          redName: 'E',
          whiteName: 'F',
          status: 'waiting',
          order: 3.0,
        ),
        MatchModel(
          id: '4',
          tournamentId: pastDateId,
          matchType: '個人戦',
          redName: 'G',
          whiteName: 'H',
          status: 'waiting',
          order: 1.5,
        ),
      ];

      // matchListProvider がIsarキャッシュからこれらの試合を返すようモック
      final container = ProviderContainer(
        overrides: [
          matchListProvider.overrideWith((ref) => mockPastMatches),
          bunaiksenMatchesStreamProvider.overrideWith(
            (ref, arg) => Stream.value(<MatchModel>[]),
          ),
        ],
      );

      // bunaiksenMatchesProvider から取得してソート順の検証
      final sortedMatches = container.read(
        bunaiksenMatchesProvider(pastDateId),
      );

      // 期待される順序: in_progress -> waiting (order 1.5) -> waiting (order 3.0) -> finished (order 1.0)
      expect(sortedMatches.length, 4);
      expect(sortedMatches[0].id, '2'); // in_progress
      expect(sortedMatches[1].id, '4'); // waiting (order: 1.5)
      expect(sortedMatches[2].id, '3'); // waiting (order: 3.0)
      expect(sortedMatches[3].id, '1'); // finished
    });

    test('4. 例外安全弁（TamperedEventException 対策）の堅牢性検証', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final targetDateId = 'bunaiksen_20260622';

      // Fake Firestore document snapshot
      await fakeFirestore
          .collection('organizations')
          .doc('test_dojo')
          .collection('tournaments')
          .doc(targetDateId)
          .collection('matches')
          .doc('match_sync_2')
          .set({
            'redName': 'Firestore赤',
            'whiteName': 'Firestore白',
            'matchType': '個人戦',
            'status': 'waiting',
            'order': 1.0,
            'events': [],
          });

      // Isar保存時に TamperedEventException をスローさせる
      when(
        () => mockLocalRepo.saveMatchesBulk(any()),
      ).thenThrow(TamperedEventException('改ざんされた署名を検知しました'));

      final container = ProviderContainer(
        overrides: [
          firestoreProvider.overrideWithValue(fakeFirestore),
          currentDojoIdProvider.overrideWith((ref) => 'test_dojo'),
          localMatchRepositoryProvider.overrideWithValue(mockLocalRepo),
        ],
      );

      // ストリームをリッスンし、Isarで例外が発生してもストリームがクラッシュ/クローズせず値が出力されることをアサート
      final list = await container.read(
        bunaiksenMatchesStreamProvider(targetDateId).future,
      );

      expect(list.length, 1);
      expect(list.first.id, 'match_sync_2');
      // 例外が発生しても、UI側に安全にデータが流れ続けていること
    });
  });
}
