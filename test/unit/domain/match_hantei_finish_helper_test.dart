import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/application/services/match_hantei_finish_helper.dart';
import 'package:kendo_os/features/match/application/services/match_persistence_helper.dart';
import 'package:kendo_os/features/match/application/usecases/match_usecases.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/presentation/providers/match_rule_provider.dart';
import 'package:kendo_os/shared/application/services/sound_service.dart';
import 'package:kendo_os/shared/domain/entities/role_permission.dart';
import 'package:kendo_os/shared/domain/entities/settings_model.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';

class _FakeSoundService implements SoundService {
  String? lastSpoken;
  bool fanfarePlayed = false;

  @override
  Future<void> speak(String text) async {
    lastSpoken = text;
  }

  @override
  Future<void> playFinishFanfare() async {
    fanfarePlayed = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePermissionService implements PermissionService {
  bool allowAppend = true;

  @override
  bool canAppend(User user, ScoreEvent event) => allowAppend;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSettingsNotifier extends SettingsNotifier {
  final String _audioMode;
  _FakeSettingsNotifier(this._audioMode);

  @override
  SettingsModel build() {
    return SettingsModel(
      showConfirmDialog: false,
      audioFeedbackMode: _audioMode,
    );
  }
}

class _FakeMatchRuleNotifier extends MatchRuleNotifier {
  @override
  MatchRule build() => const MatchRule();
}

class _FakeMatchPersistenceHelper extends MatchPersistenceHelper {
  final Map<String, MatchModel> store = {};
  MatchModel? lastSavedMatch;

  _FakeMatchPersistenceHelper(super.ref);

  @override
  Future<MatchModel?> getMatchSafely(String matchId) async {
    return store[matchId];
  }

  @override
  Future<void> saveAndSync(MatchModel match) async {
    store[match.id] = match;
    lastSavedMatch = match;
  }
}

class _FakeAddScoreUseCase implements AddScoreUseCase {
  @override
  MatchModel execute(
    User user,
    MatchModel currentMatch,
    ScoreEvent newEvent,
    MatchRule rule,
  ) {
    return currentMatch.copyWith(
      events: [...currentMatch.events, newEvent],
      redScore: newEvent.side == Side.red
          ? currentMatch.redScore + 1
          : currentMatch.redScore,
      whiteScore: newEvent.side == Side.white
          ? currentMatch.whiteScore + 1
          : currentMatch.whiteScore,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('[Unit] 試合判定決着および手動終了承認ヘルパーテスト', () {
    late ProviderContainer container;
    late _FakeMatchPersistenceHelper fakePersistence;
    late _FakeAddScoreUseCase fakeAddScore;
    late _FakeSoundService fakeSound;
    late _FakePermissionService fakePermission;
    late MatchHanteiFinishHelper helper;

    setUp(() {
      fakeSound = _FakeSoundService();
      fakePermission = _FakePermissionService();

      container = ProviderContainer(
        overrides: [
          soundServiceProvider.overrideWithValue(fakeSound),
          permissionServiceProvider.overrideWithValue(fakePermission),
          settingsProvider.overrideWith(() => _FakeSettingsNotifier('voice')),
          matchRuleProvider.overrideWith(() => _FakeMatchRuleNotifier()),
        ],
      );

      final ref = container.read(Provider((ref) => ref));
      fakePersistence = _FakeMatchPersistenceHelper(ref);
      fakeAddScore = _FakeAddScoreUseCase();

      helper = MatchHanteiFinishHelper(ref, fakePersistence, fakeAddScore);
    });

    tearDown(() {
      container.dispose();
    });

    test('試合承認において対象試合のステータスがapprovedへ正しく昇格すること', () async {
      final initialMatch = const MatchModel(
        id: 'match_hantei_1',
        tournamentId: 't1',
        matchType: 'individual',
        redName: '選手赤',
        whiteName: '選手白',
        status: 'finished',
      );
      fakePersistence.store['match_hantei_1'] = initialMatch;

      await helper.approveMatch('match_hantei_1', 'trace_001');

      final saved = fakePersistence.lastSavedMatch;
      expect(saved, isNotNull);
      expect(saved!.status, equals('approved'));
    });

    test('試合終了処理において未終了試合が安全にfinishedへ移行すること', () async {
      final runningMatch = MatchModel(
        id: 'match_hantei_2',
        tournamentId: 't1',
        matchType: 'individual',
        redName: '選手赤',
        whiteName: '選手白',
        status: 'in_progress',
        hasExtension: true,
        timerStartedAt: DateTime.now(),
      );
      fakePersistence.store['match_hantei_2'] = runningMatch;

      final result = await helper.finishMatch('match_hantei_2');

      expect(result, isNotNull);
      expect(result!.status, equals('finished'));
      expect(result.timerStartedAt, isNull);
      expect(result.hasExtension, isFalse);
    });

    test('権限なしユーザーによる判定決着要求時に例外を送出すること', () async {
      final match = const MatchModel(
        id: 'match_hantei_3',
        tournamentId: 't1',
        matchType: 'individual',
        redName: '選手赤',
        whiteName: '選手白',
        status: 'in_progress',
      );
      fakePersistence.store['match_hantei_3'] = match;

      fakePermission.allowAppend = false;
      const unauthorizedUser = User(
        id: 'viewer_user',
        role: Role.viewer,
        organizationId: 'dojo_1',
      );

      expect(
        () async => await helper.finishMatchManually(
          matchId: 'match_hantei_3',
          currentUser: unauthorizedUser,
          hanteiWinner: Side.red,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('正当な権限での判定決着時に判定イベントが追加され音声通知が発火すること', () async {
      final match = const MatchModel(
        id: 'match_hantei_4',
        tournamentId: 't1',
        matchType: 'individual',
        redName: '選手赤',
        whiteName: '選手白',
        status: 'in_progress',
        events: [],
      );
      fakePersistence.store['match_hantei_4'] = match;

      fakePermission.allowAppend = true;
      const referee = User(
        id: 'referee_1',
        role: Role.scorer,
        organizationId: 'dojo_1',
      );

      final result = await helper.finishMatchManually(
        matchId: 'match_hantei_4',
        currentUser: referee,
        hanteiWinner: Side.red,
      );

      expect(result, isNotNull);
      expect(result!.status, equals('finished'));
      expect(result.events.length, equals(1));
      expect(result.events.first.type, equals(PointType.hantei));
      expect(result.events.first.side, equals(Side.red));

      // 音声フィードバック確認 (voice mode)
      expect(fakeSound.lastSpoken, equals('試合終了です'));
    });
  });
}
