import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_command_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/match_repository.dart';
import 'package:kendo_os/shared/presentation/utils/match_calculator_helper.dart';

class MockLocalMatchRepository extends Mock implements LocalMatchRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(
      const MatchModel(
        id: 'dummy',
        matchType: 'dummy',
        redName: 'red',
        whiteName: 'white',
      ),
    );
    registerFallbackValue(
      MatchCommandModel(
        id: 'dummy',
        type: CommandType.updateMatch,
        payload: const {},
        createdAt: DateTime.now(),
        status: CommandStatus.pending,
      ),
    );
  });

  group('[Unit] 試合ルール適用・伝播 ＆ 判定ドメインロジック整合性テスト', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockLocalMatchRepository mockLocalRepo;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockLocalRepo = MockLocalMatchRepository();

      when(() => mockLocalRepo.saveMatchesBulk(any())).thenAnswer((_) async {});
      when(() => mockLocalRepo.saveMatch(any())).thenAnswer((_) async {});
      when(
        () => mockLocalRepo.savePendingCommand(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockLocalRepo.savePendingCommandsBulk(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockLocalRepo.getPendingCommands(),
      ).thenAnswer((_) async => <MatchCommandModel>[]);
      when(
        () => mockLocalRepo.getPendingMatches(),
      ).thenAnswer((_) async => <MatchModel>[]);
      when(
        () => mockLocalRepo.watchAllLocalMatches(),
      ).thenAnswer((_) => Stream.value(<MatchModel>[]));
    });

    test('Firestore内で特定試合のルールが一括更新されること', () async {
      final oldRule = const MatchRule(matchTimeMinutes: 1.5, hasHantei: false);
      final m1 = MatchModel(
        id: 'bulk_match_1',
        tournamentId: 'test_tournament_rules',
        category: '小学生の部',
        matchType: '個人戦',
        redName: '赤1',
        whiteName: '白1',
        status: 'waiting',
        matchTimeMinutes: 1.5,
        rule: oldRule,
        organizationId: 'test_dojo_id',
      );
      final m2 = MatchModel(
        id: 'bulk_match_2',
        tournamentId: 'test_tournament_rules',
        category: '小学生の部',
        matchType: '個人戦',
        redName: '赤2',
        whiteName: '白2',
        status: 'waiting',
        matchTimeMinutes: 1.5,
        rule: oldRule,
        organizationId: 'test_dojo_id',
      );

      await fakeFirestore
          .collection('organizations')
          .doc('test_dojo_id')
          .collection('tournaments')
          .doc('test_tournament_rules')
          .collection('matches')
          .doc(m1.id)
          .set(m1.toJson());

      await fakeFirestore
          .collection('organizations')
          .doc('test_dojo_id')
          .collection('tournaments')
          .doc('test_tournament_rules')
          .collection('matches')
          .doc(m2.id)
          .set(m2.toJson());

      final container = ProviderContainer(
        overrides: [
          currentDojoIdProvider.overrideWith((ref) => 'test_dojo_id'),
          currentTournamentIdProvider.overrideWith(
            (ref) => 'test_tournament_rules',
          ),
          firestoreProvider.overrideWithValue(fakeFirestore),
          matchListByTournamentProvider('test_tournament_rules').overrideWith((
            ref,
          ) {
            return Stream.value([m1, m2]);
          }),
          matchListProvider.overrideWith((ref) => [m1, m2]),
          matchStreamProvider.overrideWith((ref) => Stream.value([m1, m2])),
          localMatchRepositoryProvider.overrideWithValue(mockLocalRepo),
        ],
      );

      container.read(matchListByTournamentProvider('test_tournament_rules'));

      final newRule = const MatchRule(
        matchTimeMinutes: 3.5,
        enchoTimeMinutes: 2.0,
        hasHantei: true,
      );

      await container
          .read(matchCommandProvider)
          .bulkUpdateMatchRules(
            targetMatchIds: ['bulk_match_1'],
            newRule: newRule,
          );

      final captured = verify(
        () => mockLocalRepo.saveMatchesBulk(captureAny()),
      ).captured;
      final savedMatches = captured.last as List<MatchModel>;

      final match1 = savedMatches.firstWhere((m) => m.id == 'bulk_match_1');
      expect(match1.matchTimeMinutes, 3.5);
      expect(match1.extensionTimeMinutes, 2.0);
      expect(match1.rule?.matchTimeMinutes, 3.5);

      final match2 = savedMatches.where((m) => m.id == 'bulk_match_2');
      expect(match2, isEmpty);
    });

    test('deleteMatchにおいて Web環境でFirestoreから直接削除され楽観的UI更新が行われること', () async {
      debugIsWebOverride = true;
      addTearDown(() {
        debugIsWebOverride = false;
      });

      final matchToDelete = const MatchModel(
        id: 'web_delete_match',
        tournamentId: 'test_tournament_rules',
        category: '小学生の部',
        matchType: '個人戦',
        redName: '赤',
        whiteName: '白',
        status: 'waiting',
        organizationId: 'test_dojo_id',
      );

      await fakeFirestore
          .collection('organizations')
          .doc('test_dojo_id')
          .collection('tournaments')
          .doc('test_tournament_rules')
          .collection('matches')
          .doc(matchToDelete.id)
          .set(matchToDelete.toJson());

      final container = ProviderContainer(
        overrides: [
          currentDojoIdProvider.overrideWith((ref) => 'test_dojo_id'),
          currentTournamentIdProvider.overrideWith(
            (ref) => 'test_tournament_rules',
          ),
          firestoreProvider.overrideWithValue(fakeFirestore),
          matchRepositoryProvider.overrideWith((ref) {
            return MatchRepository(
              fakeFirestore,
              'test_dojo_id',
              'test_tournament_rules',
            );
          }),
        ],
      );

      container.read(webCurrentTournamentMatchesProvider.notifier).state = [
        matchToDelete,
      ];

      await container
          .read(matchCommandProvider)
          .deleteMatch('web_delete_match');

      final currentWebMatches = container.read(
        webCurrentTournamentMatchesProvider,
      );
      expect(currentWebMatches, isEmpty);

      final snap = await fakeFirestore
          .collection('organizations')
          .doc('test_dojo_id')
          .collection('tournaments')
          .doc('test_tournament_rules')
          .collection('matches')
          .doc(matchToDelete.id)
          .get();
      expect(snap.exists, isFalse);
    });

    test('deleteMatchにおいて Web環境でプロバイダ情報が不足時にMatchModelから動的補完されること', () async {
      debugIsWebOverride = true;
      addTearDown(() {
        debugIsWebOverride = false;
      });

      final matchToDelete = const MatchModel(
        id: 'web_dynamic_delete_match',
        tournamentId: 'correct_tournament_id',
        category: '小学生の部',
        matchType: '個人戦',
        redName: '赤',
        whiteName: '白',
        status: 'waiting',
        organizationId: 'correct_dojo_id',
      );

      await fakeFirestore
          .collection('organizations')
          .doc('correct_dojo_id')
          .collection('tournaments')
          .doc('correct_tournament_id')
          .collection('matches')
          .doc(matchToDelete.id)
          .set(matchToDelete.toJson());

      final container = ProviderContainer(
        overrides: [
          currentDojoIdProvider.overrideWith((ref) => 'initial_wrong_dojo'),
          currentTournamentIdProvider.overrideWith(
            (ref) => 'initial_wrong_tournament',
          ),
          firestoreProvider.overrideWithValue(fakeFirestore),
          matchRepositoryProvider.overrideWith((ref) {
            final dojoId = ref.watch(currentDojoIdProvider);
            final tournamentId = ref.watch(currentTournamentIdProvider);
            return MatchRepository(fakeFirestore, dojoId, tournamentId);
          }),
        ],
      );

      container.read(webCurrentTournamentMatchesProvider.notifier).state = [
        matchToDelete,
      ];

      await container
          .read(matchCommandProvider)
          .deleteMatch('web_dynamic_delete_match');

      expect(container.read(currentDojoIdProvider), 'correct_dojo_id');
      expect(
        container.read(currentTournamentIdProvider),
        'correct_tournament_id',
      );

      final snap = await fakeFirestore
          .collection('organizations')
          .doc('correct_dojo_id')
          .collection('tournaments')
          .doc('correct_tournament_id')
          .collection('matches')
          .doc(matchToDelete.id)
          .get();
      expect(snap.exists, isFalse);
    });

    test('Web環境での試合削除時にアクティブな道場IDが上書きされないこと', () async {
      debugIsWebOverride = true;
      addTearDown(() {
        debugIsWebOverride = false;
      });

      const matchWithDefaultOrg = MatchModel(
        id: 'delete_default_org_match',
        tournamentId: 'my_active_tournament',
        matchType: '個人戦',
        status: 'waiting',
        redName: '赤',
        whiteName: '白',
        organizationId: 'default_org',
      );

      await fakeFirestore
          .collection('organizations')
          .doc('my_active_dojo')
          .collection('tournaments')
          .doc('my_active_tournament')
          .collection('matches')
          .doc(matchWithDefaultOrg.id)
          .set(matchWithDefaultOrg.toJson());

      final container = ProviderContainer(
        overrides: [
          currentDojoIdProvider.overrideWith((ref) => 'my_active_dojo'),
          currentTournamentIdProvider.overrideWith(
            (ref) => 'my_active_tournament',
          ),
          firestoreProvider.overrideWithValue(fakeFirestore),
          matchRepositoryProvider.overrideWith((ref) {
            final dojoId = ref.watch(currentDojoIdProvider);
            final tournamentId = ref.watch(currentTournamentIdProvider);
            return MatchRepository(fakeFirestore, dojoId, tournamentId);
          }),
        ],
      );

      container.read(webCurrentTournamentMatchesProvider.notifier).state = [
        matchWithDefaultOrg,
      ];

      await container
          .read(matchCommandProvider)
          .deleteMatch('delete_default_org_match');

      expect(container.read(currentDojoIdProvider), 'my_active_dojo');
      expect(
        container.read(currentTournamentIdProvider),
        'my_active_tournament',
      );

      final snap = await fakeFirestore
          .collection('organizations')
          .doc('my_active_dojo')
          .collection('tournaments')
          .doc('my_active_tournament')
          .collection('matches')
          .doc('delete_default_org_match')
          .get();
      expect(snap.exists, isFalse);
    });

    test('チーム試合作成において補欠選手に対して余剰な試合スロットが生成されないこと', () {
      final teamPlayerNames = ['先鋒太郎', '次鋒次郎', '中堅三郎', '副将四郎', '大将五郎', '補欠六郎'];

      int teamSize = 5;
      final positions = ['先鋒', '次鋒', '中堅', '副将', '大将'];

      expect(positions.length, equals(teamSize));
      expect(positions.contains('4将'), isFalse);
      expect(positions.contains('3将'), isFalse);

      final selectedPlayers = <int, String>{};
      for (int i = 0; i < teamPlayerNames.length && i < positions.length; i++) {
        selectedPlayers[i] = teamPlayerNames[i];
      }

      expect(selectedPlayers.length, equals(5));
      expect(selectedPlayers[0], equals('先鋒太郎'));
      expect(selectedPlayers[4], equals('大将五郎'));
      expect(selectedPlayers.containsKey(5), isFalse);
    });

    test('選手登録において 試合枠外の登録控え選手がベンチ待機補欠（teamSubstitutes）として識別されること', () {
      final teamPlayerNames = [
        '先鋒太郎',
        '次鋒次郎',
        '中堅三郎',
        '副将四郎',
        '大将五郎',
        '補欠六郎',
        '補欠七郎',
      ];

      final activePlayerNames = {'先鋒太郎', '次鋒次郎', '中堅三郎', '副将四郎', '大将五郎'};

      final teamSubstitutes = teamPlayerNames
          .where((name) => name.isNotEmpty && !activePlayerNames.contains(name))
          .toList();

      expect(activePlayerNames.length, equals(5));
      expect(teamSubstitutes, equals(['補欠六郎', '補欠七郎']));
      expect(teamSubstitutes.contains('大将五郎'), isFalse);
    });

    test('同名チームが複数部門に存在する場合でも部門別に候補選手チップが正しく絞り込まれること', () {
      final registeredTeams = [
        const TeamModel(
          id: 't_elem',
          tournamentId: 'tour1',
          category: '小学生の部',
          teamName: '道上剣友会',
          playerNames: ['小学生先鋒', '小学生次鋒', '小学生中堅', '小学生副将', '小学生大将', '小学生補欠'],
        ),
        const TeamModel(
          id: 't_jhs',
          tournamentId: 'tour1',
          category: '中学生の部',
          teamName: '道上剣友会',
          playerNames: ['中学生先鋒', '中学生次鋒', '中学生中堅', '中学生副将', '中学生大将', '中学生補欠'],
        ),
      ];

      const matchCat = '小学生の部';
      const targetTeamName = '道上剣友会';

      final elemTeamData = registeredTeams.firstWhere(
        (t) {
          final nameMatch =
              t.teamName.trim() == targetTeamName ||
              targetTeamName.contains(t.teamName.trim()) ||
              t.teamName.trim().contains(targetTeamName);
          if (!nameMatch) return false;
          if (matchCat.isNotEmpty && t.category.isNotEmpty) {
            return t.category.trim() == matchCat ||
                matchCat.contains(t.category.trim()) ||
                t.category.trim().contains(matchCat);
          }
          return true;
        },
        orElse: () => const TeamModel(
          id: '',
          tournamentId: '',
          category: '',
          teamName: '',
          matchType: '',
          playerNames: [],
        ),
      );

      final candidates = elemTeamData.playerNames
          .where((n) => n.isNotEmpty)
          .toList();

      expect(candidates.length, equals(6));
      expect(candidates.contains('小学生先鋒'), isTrue);
      expect(candidates.contains('小学生補欠'), isTrue);
      expect(candidates.contains('中学生先鋒'), isFalse);
      expect(candidates.contains('中学生補欠'), isFalse);
    });

    test('延長判定において スコアカードおよび公式記録用で正しくisEnchoフラグが設定されること', () {
      final regularFinishedMatch = const MatchModel(
        id: 'm1',
        matchType: '通常',
        redName: '選手A',
        whiteName: '選手B',
        redScore: 2,
        whiteScore: 1,
        status: 'approved',
        note: '',
      );
      expect(
        MatchCalculatorHelper.isEnchoFromModel(regularFinishedMatch),
        isFalse,
      );

      final daihyoMatch = const MatchModel(
        id: 'm2',
        matchType: '代表戦',
        redName: '代表A',
        whiteName: '代表B',
        redScore: 1,
        whiteScore: 0,
        status: 'approved',
        note: '',
      );
      expect(MatchCalculatorHelper.isEnchoFromModel(daihyoMatch), isFalse);

      final daihyoEnchoMatch = const MatchModel(
        id: 'm2_ext',
        matchType: '代表戦',
        redName: '代表A',
        whiteName: '代表B',
        redScore: 1,
        whiteScore: 0,
        status: 'approved',
        note: '代表戦 延長1回目',
      );
      expect(MatchCalculatorHelper.isEnchoFromModel(daihyoEnchoMatch), isTrue);

      final enchoNoteMatch = const MatchModel(
        id: 'm3',
        matchType: '通常',
        redName: '選手C',
        whiteName: '選手D',
        redScore: 1,
        whiteScore: 0,
        status: 'approved',
        note: '延長戦にて決着',
      );
      expect(MatchCalculatorHelper.isEnchoFromModel(enchoNoteMatch), isTrue);

      final taishoEnchoMatch = const MatchModel(
        id: 'm4',
        matchType: '大将延長戦',
        redName: '大将A',
        whiteName: '大将B',
        redScore: 1,
        whiteScore: 0,
        status: 'approved',
        note: '',
      );
      expect(MatchCalculatorHelper.isEnchoFromModel(taishoEnchoMatch), isTrue);

      final hasExtWinnerMatch = const MatchModel(
        id: 'm5',
        matchType: '通常',
        redName: '選手E',
        whiteName: '選手F',
        redScore: 1,
        whiteScore: 0,
        status: 'approved',
        hasExtension: true,
        extensionCount: 0,
        note: '',
      );
      expect(
        MatchCalculatorHelper.isEnchoFromModel(hasExtWinnerMatch),
        isFalse,
      );

      final actualExtMatch = const MatchModel(
        id: 'm5_ext',
        matchType: '通常',
        redName: '選手E',
        whiteName: '選手F',
        redScore: 1,
        whiteScore: 0,
        status: 'approved',
        hasExtension: true,
        extensionCount: 1,
        note: '延長1回目',
      );
      expect(MatchCalculatorHelper.isEnchoFromModel(actualExtMatch), isTrue);

      final unfinishedEnchoMatch = const MatchModel(
        id: 'm6',
        matchType: '代表戦',
        redName: '代表A',
        whiteName: '代表B',
        redScore: 0,
        whiteScore: 0,
        status: 'running',
        note: '延長戦',
      );
      expect(
        MatchCalculatorHelper.isEnchoFromModel(unfinishedEnchoMatch),
        isFalse,
      );
    });

    test('試合の備考欄においてコート表示と進行ヘッダーメモが正しく保持されること', () {
      const courtText = '第1試合場';
      const userNote = '準決勝';
      const combinedNote = '$courtText\n$userNote';

      final matchWithNote = const MatchModel(
        id: 'm10',
        matchType: '先鋒',
        redName: 'Aチーム : 先鋒A',
        whiteName: 'Bチーム : 先鋒B',
        groupName: 'group_uuid_123',
        note: combinedNote,
      );

      expect(matchWithNote.note, equals('第1試合場\n準決勝'));
      expect(matchWithNote.note.contains('第1試合場'), isTrue);
    });

    test('MatchEditSheetにおいて チップ選択用の試合ルール・シーンプリセットキーが正しく検知されること', () {
      String detectPresetKey(MatchModel match) {
        final r = match.rule ?? const MatchRule();
        if (r.isRenseikai ||
            r.matchScene == 'renseikai' ||
            match.matchScene == 'renseikai') {
          return 'renseikai';
        } else if (r.matchScene == 'moushiawase' ||
            match.matchScene == 'moushiawase') {
          return 'moushiawase';
        } else if (r.matchScene == 'honsen' || match.matchScene == 'honsen') {
          return 'honsen';
        } else {
          return 'honsen';
        }
      }

      const honsenMatch = MatchModel(
        id: 'm11_1',
        matchType: '先鋒',
        redName: 'Aチーム : 先鋒A',
        whiteName: 'Bチーム : 先鋒B',
        matchScene: 'honsen',
        rule: MatchRule(matchScene: 'honsen'),
      );
      expect(detectPresetKey(honsenMatch), equals('honsen'));

      const renseikaiMatch = MatchModel(
        id: 'm11_2',
        matchType: '先鋒',
        redName: 'Aチーム : 先鋒A',
        whiteName: 'Bチーム : 先鋒B',
        matchScene: 'renseikai',
        rule: MatchRule(matchScene: 'renseikai', isRenseikai: true),
      );
      expect(detectPresetKey(renseikaiMatch), equals('renseikai'));

      const moushiawaseMatch = MatchModel(
        id: 'm11_3',
        matchType: '先鋒',
        redName: 'Aチーム : 先鋒A',
        whiteName: 'Bチーム : 先鋒B',
        matchScene: 'moushiawase',
        rule: MatchRule(matchScene: 'moushiawase', isRenseikai: false),
      );
      expect(detectPresetKey(moushiawaseMatch), equals('moushiawase'));
    });

    test('錬成会候補選手チップにおいて自カテゴリのチーム選手と補欠選手のみが抽出されること', () {
      final registeredTeams = [
        const TeamModel(
          id: 't_elem',
          tournamentId: 'tour1',
          category: '小学生の部',
          teamName: '道上剣友会',
          playerNames: ['小学生先鋒', '小学生次鋒', '小学生中堅', '小学生副将', '小学生大将', '小学生補欠'],
        ),
        const TeamModel(
          id: 't_jhs',
          tournamentId: 'tour1',
          category: '中学生の部',
          teamName: '道上剣友会',
          playerNames: ['中学生先鋒', '中学生次鋒', '中学生中堅', '中学生副将', '中学生大将', '中学生補欠'],
        ),
      ];

      bool isCategoryMatch(String teamCat, String matchCat) {
        final tCat = teamCat.trim();
        final mCat = matchCat.trim();
        if (mCat.isEmpty || tCat.isEmpty) return true;
        if (tCat == mCat || mCat.contains(tCat) || tCat.contains(mCat)) {
          return true;
        }
        final keywords = ['低学年', '高学年', '小学生', '中学生', '高校生', '一般'];
        for (final kw in keywords) {
          if (mCat.contains(kw) && tCat.contains(kw)) return true;
          if (mCat.contains(kw) && !tCat.contains(kw)) return false;
        }
        return true;
      }

      const matchCat = '小学生の部';
      const targetTeamName = '道上剣友会';

      final matchingTeams = registeredTeams.where((t) {
        final nameMatch =
            t.teamName.trim() == targetTeamName ||
            targetTeamName.contains(t.teamName.trim()) ||
            t.teamName.trim().contains(targetTeamName);
        return nameMatch;
      }).toList();

      final teamData = matchingTeams.firstWhere(
        (t) => isCategoryMatch(t.category, matchCat),
        orElse: () => matchingTeams.first,
      );

      final List<String> masterPlayers = teamData.playerNames
          .map((n) => n.trim())
          .where((n) => n.isNotEmpty && !n.contains('未定') && !n.contains('欠員'))
          .toList();

      final baseHistoryPlayers = ['小学生先鋒', '小学生次鋒', '小学生中堅', '小学生副将', '小学生大将'];

      final List<String> candidates = masterPlayers.isNotEmpty
          ? {...masterPlayers, ...baseHistoryPlayers}.toList()
          : [];

      expect(candidates.length, equals(6));
      expect(candidates.contains('小学生先鋒'), isTrue);
      expect(candidates.contains('小学生補欠'), isTrue);
      expect(candidates.contains('中学生先鋒'), isFalse);
      expect(candidates.contains('大人会員'), isFalse);
    });

    test('試合ルールシーンと判定フラグの状態が正確に保持され環境横断で反映されること', () {
      const initialMatch = MatchModel(
        id: 'm13_1',
        matchType: '先鋒',
        redName: 'Aチーム : 先鋒A',
        whiteName: 'Bチーム : 先鋒B',
        matchScene: 'honsen',
        rule: MatchRule(matchScene: 'honsen', hasHantei: false),
      );

      const renseikaiSceneKey = 'renseikai';
      final updatedRenseikaiRule = initialMatch.rule!.copyWith(
        matchScene: renseikaiSceneKey,
        isRenseikai: true,
        hasHantei: false,
        enchoTimeMinutes: 0.0,
        isEnchoUnlimited: false,
      );
      final updatedRenseikaiMatch = initialMatch.copyWith(
        matchScene: renseikaiSceneKey,
        rule: updatedRenseikaiRule,
      );

      expect(updatedRenseikaiMatch.matchScene, equals('renseikai'));
      expect(updatedRenseikaiMatch.rule?.matchScene, equals('renseikai'));
      expect(updatedRenseikaiMatch.rule?.isRenseikai, isTrue);
      expect(updatedRenseikaiMatch.rule?.hasHantei, isFalse);

      const moushiawaseSceneKey = 'moushiawase';
      final updatedMoushiawaseRule = initialMatch.rule!.copyWith(
        matchScene: moushiawaseSceneKey,
        isRenseikai: false,
        hasHantei: false,
        enchoTimeMinutes: 0.0,
        isEnchoUnlimited: false,
      );
      final updatedMoushiawaseMatch = initialMatch.copyWith(
        matchScene: moushiawaseSceneKey,
        rule: updatedMoushiawaseRule,
      );

      expect(updatedMoushiawaseMatch.matchScene, equals('moushiawase'));
      expect(updatedMoushiawaseMatch.rule?.matchScene, equals('moushiawase'));
      expect(updatedMoushiawaseMatch.rule?.isRenseikai, isFalse);
      expect(updatedMoushiawaseMatch.rule?.hasHantei, isFalse);

      String detectSavedScene(MatchModel m) {
        final r = m.rule ?? const MatchRule();
        if (r.isRenseikai ||
            r.matchScene == 'renseikai' ||
            m.matchScene == 'renseikai') {
          return 'renseikai';
        } else if (r.matchScene == 'moushiawase' ||
            m.matchScene == 'moushiawase') {
          return 'moushiawase';
        } else {
          return 'honsen';
        }
      }

      expect(detectSavedScene(updatedRenseikaiMatch), equals('renseikai'));
      expect(detectSavedScene(updatedMoushiawaseMatch), equals('moushiawase'));
    });
  });
}
