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

class _E2ESoundService implements SoundService {
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

class _E2EPermissionService implements PermissionService {
  @override
  bool canAppend(User user, ScoreEvent event) {
    return user.role == Role.scorer || user.role == Role.admin;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _E2ESettingsNotifier extends SettingsNotifier {
  final String _audioMode;
  _E2ESettingsNotifier(this._audioMode);

  @override
  SettingsModel build() {
    return SettingsModel(
      showConfirmDialog: false,
      audioFeedbackMode: _audioMode,
    );
  }
}

class _E2EMatchRuleNotifier extends MatchRuleNotifier {
  @override
  MatchRule build() => const MatchRule(hasHantei: true);
}

class _E2EMatchPersistenceHelper extends MatchPersistenceHelper {
  final Map<String, MatchModel> localDb = {};

  _E2EMatchPersistenceHelper(super.ref);

  @override
  Future<MatchModel?> getMatchSafely(String matchId) async {
    return localDb[matchId];
  }

  @override
  Future<void> saveAndSync(MatchModel match) async {
    localDb[match.id] = match;
  }
}

class _E2EAddScoreUseCase implements AddScoreUseCase {
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
  group('[E2E] 複合引き分け延長判定決着および音声承認フローテスト', () {
    test('延長戦判定決着から音声案内および大会本部承認まで一貫して整合性が維持されること', () async {
      final fakeSound = _E2ESoundService();
      final fakePermission = _E2EPermissionService();

      final container = ProviderContainer(
        overrides: [
          soundServiceProvider.overrideWithValue(fakeSound),
          permissionServiceProvider.overrideWithValue(fakePermission),
          settingsProvider.overrideWith(() => _E2ESettingsNotifier('voice')),
          matchRuleProvider.overrideWith(() => _E2EMatchRuleNotifier()),
        ],
      );
      addTearDown(container.dispose);

      final ref = container.read(Provider((ref) => ref));
      final fakePersistence = _E2EMatchPersistenceHelper(ref);
      final fakeAddScore = _E2EAddScoreUseCase();
      final helper = MatchHanteiFinishHelper(
        ref,
        fakePersistence,
        fakeAddScore,
      );

      // 1. 本戦引き分け後の延長戦試合状態
      final enchoMatch = MatchModel(
        id: 'match_encho_hantei_1',
        tournamentId: 't_official_championship',
        matchType: '個人戦',
        category: '一般選手権',
        redName: '神武館: 山本',
        whiteName: '正気塾: 木村',
        redScore: 0,
        whiteScore: 0,
        hasExtension: true,
        status: 'in_progress',
        events: [],
      );
      fakePersistence.localDb[enchoMatch.id] = enchoMatch;

      // 2. 審判旗判定入力（コート主任・記録係による赤旗3本判定）
      const scorerUser = User(
        id: 'court_scorer_lead',
        role: Role.scorer,
        organizationId: 'org_championship',
      );

      final finishedMatch = await helper.finishMatchManually(
        matchId: enchoMatch.id,
        currentUser: scorerUser,
        hanteiWinner: Side.red,
      );

      // 試合結果検証
      expect(finishedMatch, isNotNull);
      expect(finishedMatch!.status, equals('finished'));
      expect(finishedMatch.hasExtension, isFalse);
      expect(finishedMatch.events.length, equals(1));
      expect(finishedMatch.events.first.type, equals(PointType.hantei));
      expect(finishedMatch.events.first.side, equals(Side.red));

      // 音声フィードバック発火検証
      expect(fakeSound.lastSpoken, equals('試合終了です'));

      // 3. 大会本部・総務管理者による公式記録確定承認
      await helper.approveMatch(enchoMatch.id, 'trace_approval_official');

      final finalApprovedMatch = fakePersistence.localDb[enchoMatch.id];
      expect(finalApprovedMatch, isNotNull);
      expect(finalApprovedMatch!.status, equals('approved'));
      expect(finalApprovedMatch.events.first.type, equals(PointType.hantei));
    });
  });
}
