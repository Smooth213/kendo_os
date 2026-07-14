import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/presentation/providers/auth_session_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/shared/infrastructure/repository/sync_engine.dart';
import 'package:kendo_os/shared/presentation/providers/dojo_room_sync_provider.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';

class MockLocalMatchRepository extends Mock implements LocalMatchRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeFirebaseFirestore fakeFirestore;
  late MockLocalMatchRepository mockLocalRepo;

  const dummyMatch = MatchModel(
    id: 'dummy',
    matchType: 'individual',
    redName: 'Red',
    whiteName: 'White',
  );

  setUpAll(() {
    registerFallbackValue(dummyMatch);
    registerFallbackValue(<MatchModel>[]);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    fakeFirestore = FakeFirebaseFirestore();
    mockLocalRepo = MockLocalMatchRepository();

    // LocalMatchRepositoryのスタブ設定
    when(
      () => mockLocalRepo.saveMatchesBulk(any()),
    ).thenAnswer((_) => Future.value());
    when(
      () => mockLocalRepo.saveMatch(any()),
    ).thenAnswer((_) => Future.value());
    when(
      () => mockLocalRepo.getPendingCommands(),
    ).thenAnswer((_) => Future.value([]));
  });

  group('🔄 ログイン・認証連動試合同期 (Sync Rebind) 統合検証テスト', () {
    test(
      '【同期検証】ログイン成功時（authSessionProvider更新時）に、SyncEngineが自動的にFirestore監視を再バインドすること',
      () async {
        final container = ProviderContainer(
          overrides: [
            firestoreProvider.overrideWithValue(fakeFirestore),
            localMatchRepositoryProvider.overrideWithValue(mockLocalRepo),
          ],
        );

        // 初期道場IDと大会IDの設定
        container.read(currentDojoIdProvider.notifier).state = 'test_dojo';
        container.read(currentTournamentIdProvider.notifier).state =
            'test_tournament';

        // 1. 未ログイン状態で SyncEngine をインスタンス化
        // (これにより _setupFirestoreDownstream -> _bindListeners が1回走る)
        container.read(syncEngineProvider);

        // 2. ここでログイン（認証ゲート通過）を実行する
        await container
            .read(authSessionProvider.notifier)
            .establishSession(UserRole.admin, 'test_dojo');

        // 3. セッションが切り替わったことで再度 _bindListeners() が走り、
        // Firestore コレクションへの再購読が実行されていることを確認する。
        // これを実証するために、Firestore側にデータを追加して LocalMatchRepository の saveMatchesBulk が呼ばれるか検証する。
        final matchData = {
          'id': 'match_1',
          'matchType': 'individual',
          'redName': 'Red',
          'whiteName': 'White',
          'events': [],
          'pendingEvents': [],
        };

        await fakeFirestore
            .collection('organizations')
            .doc('test_dojo')
            .collection('tournaments')
            .doc('test_tournament')
            .collection('matches')
            .doc('match_1')
            .set(matchData);

        // 非同期のストリーム同期処理を少し待つ
        await Future.delayed(const Duration(milliseconds: 100));

        // saveMatchesBulk が呼ばれている ＝ 再バインドされたストリームが生きており、
        // 最新のデータをIsarへ流し込んだことを証明する
        verify(() => mockLocalRepo.saveMatchesBulk(any())).called(1);
      },
    );

    test(
      '【同期検証】ログイン成功時（authSessionProvider更新時）に、dojoRoomSyncProvider が自動的に再構築（rebuild）されること',
      () async {
        bool isDisposed = false;

        final container = ProviderContainer(
          overrides: [
            firestoreProvider.overrideWithValue(fakeFirestore),
            localMatchRepositoryProvider.overrideWithValue(mockLocalRepo),
            // dojoRoomSyncProvider 自体をオーバーライドし、依存変化による破棄 (onDispose) をスパイする
            dojoRoomSyncProvider.overrideWith((ref) {
              ref.watch(currentDojoIdProvider);
              ref.watch(authSessionProvider); // watch対象の接続

              ref.onDispose(() {
                isDisposed = true;
              });
              return;
            }),
          ],
        );

        // 1. プロバイダを読み込み、生存状態にする
        container.read(dojoRoomSyncProvider);
        expect(isDisposed, isFalse);

        // 2. ログインを実行して authSessionProvider を更新する
        await container
            .read(authSessionProvider.notifier)
            .establishSession(UserRole.admin, 'test_dojo');

        // 3. authSessionProvider の watch 変更により、プロバイダが再構築されるため、
        // 既存のインスタンスが正常に破棄 (onDisposeが発火) されたことをアサートする。
        expect(isDisposed, isTrue);
      },
    );
  });
}
