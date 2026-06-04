import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/domain/match/match_model.dart';
import 'package:kendo_os/infrastructure/repository/match_repository.dart';
import 'package:kendo_os/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/presentation/operate/providers/match_rule_provider.dart';
import 'package:mockito/mockito.dart';

// 手動でMockクラスを定義（実装漏れによるコンパイルエラーを回避）
class MockMatchRepository extends Mock implements MatchRepository {
  @override
  Future<List<MatchModel>> getStaticMatches() => super.noSuchMethod(
    Invocation.method(#getStaticMatches, []),
    returnValue: Future<List<MatchModel>>.value(<MatchModel>[]),
  );

  @override
  Stream<List<MatchModel>> watchActiveMatches() => super.noSuchMethod(
    Invocation.method(#watchActiveMatches, []),
    returnValue: Stream<List<MatchModel>>.empty(), // ★ 型指定によりエラーを解消
  );
}

class MockLocalMatchRepository extends Mock implements LocalMatchRepository {
  @override
  Stream<List<MatchModel>> watchMatches() => super.noSuchMethod(
    Invocation.method(#watchMatches, []),
    returnValue: Stream<List<MatchModel>>.empty(), // ★ 型指定によりエラーを解消
  );

  @override
  Future<void> saveMatchesBulk(List<MatchModel> matches) => super.noSuchMethod(
    Invocation.method(#saveMatchesBulk, [matches]),
    returnValue: Future.value(),
  );

  @override
  Stream<List<MatchModel>> watchAllLocalMatches() => super.noSuchMethod(
    Invocation.method(#watchAllLocalMatches, []),
    returnValue: Stream<List<MatchModel>>.empty(),
  );
}

void main() {
  late MockMatchRepository mockRemote;
  late MockLocalMatchRepository mockLocal;

  setUp(() {
    mockRemote = MockMatchRepository();
    mockLocal = MockLocalMatchRepository();
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        matchRepositoryProvider.overrideWithValue(mockRemote),
        localMatchRepositoryProvider.overrideWithValue(mockLocal),
        // matchRuleProviderがNotifierProviderの場合、コンストラクタを直接参照
        matchRuleProvider.overrideWith(() => MatchRuleNotifier()),
      ],
    );
  }

  group('MatchListProvider Tests', () {
    test(
      'matchStreamProvider should return matches from local repository',
      () async {
        final container = createContainer();

        final mockMatches = [
          const MatchModel(
            id: '1',
            tournamentId: 't1',
            redName: '赤',
            whiteName: '白',
            matchType: '団体戦',
            status: 'ready',
            order: 1.0,
          ),
        ];

        // ストリーム型を明示的に指定
        when(
          mockRemote.watchActiveMatches(),
        ).thenAnswer((_) => Stream<List<MatchModel>>.empty());
        when(
          mockRemote.getStaticMatches(),
        ).thenAnswer((_) async => <MatchModel>[]);
        when(
          mockLocal.watchMatches(),
        ).thenAnswer((_) => Stream.value(mockMatches));
        when(
          mockLocal.watchAllLocalMatches(),
        ).thenAnswer((_) => Stream.value(mockMatches));

        // matchStreamProviderはStreamProviderなので .future で値を取得可能
        final result = await container.read(matchStreamProvider.future);

        expect(result.length, 1);
        expect(result.first.id, '1');
      },
    );
  });
}
