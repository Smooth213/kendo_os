import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_generator_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockMatchApplicationService extends Mock
    implements MatchApplicationService {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const MatchModel(
        id: 'dummy',
        matchType: '個人戦',
        redName: '赤選手',
        whiteName: '白選手',
      ),
    );
  });

  group('[Unit] MatchGenerator 試合大量一括生成と欠員補完の検証', () {
    late FakeFirebaseFirestore fakeFirestore;
    late _MockMatchApplicationService mockAppService;
    late ProviderContainer container;
    late MatchGenerator generator;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockAppService = _MockMatchApplicationService();

      when(
        () => mockAppService.saveMatchesBulk(any()),
      ).thenAnswer((_) async {});
      when(() => mockAppService.saveMatch(any())).thenAnswer((_) async {});

      container = ProviderContainer(
        overrides: [
          firestoreProvider.overrideWithValue(fakeFirestore),
          matchApplicationServiceProvider.overrideWithValue(mockAppService),
        ],
      );
      generator = container.read(matchGeneratorProvider);
    });

    tearDown(() {
      container.dispose();
    });

    test('リーグ戦参加者リストから総当たり対戦組み合わせが一括生成されること', () async {
      final participants = ['選手A', '選手B', '選手C'];

      await generator.generateLeagueMatches(
        '一般の部',
        participants,
        true,
        '第1グループ',
        'tour_001',
      );

      final captured = verify(
        () => mockAppService.saveMatchesBulk(captureAny()),
      ).captured;
      expect(captured.isNotEmpty, isTrue);

      final generatedMatches = captured.first as List<MatchModel>;
      // 3人の総当たり = 3 * 2 / 2 = 3試合
      expect(generatedMatches.length, equals(3));

      expect(generatedMatches[0].redName, equals('選手A'));
      expect(generatedMatches[0].whiteName, equals('選手B'));
      expect(generatedMatches[0].matchType, equals('リーグ戦'));
      expect(generatedMatches[0].source, equals('auto_league'));
      expect(generatedMatches[0].tournamentId, equals('tour_001'));

      expect(generatedMatches[1].redName, equals('選手A'));
      expect(generatedMatches[1].whiteName, equals('選手C'));

      expect(generatedMatches[2].redName, equals('選手B'));
      expect(generatedMatches[2].whiteName, equals('選手C'));
    });

    test('団体戦において選手数が不均衡な場合に欠員として安全に補完生成されること', () async {
      final redMembers = ['赤先鋒', '赤中堅', '赤大将'];
      final whiteMembers = ['白先鋒', '白中堅']; // 1名不足

      await generator.generateTeamMatchBouts(
        '紅葉館',
        redMembers,
        '白水館',
        whiteMembers,
        true,
        category: '団体戦の部',
        tournamentId: 'tour_team_01',
      );

      final captured = verify(
        () => mockAppService.saveMatchesBulk(captureAny()),
      ).captured;
      expect(captured.isNotEmpty, isTrue);

      final bouts = captured.first as List<MatchModel>;
      expect(bouts.length, equals(3));

      // 1試合目（先鋒）
      expect(bouts[0].redName, equals('紅葉館:赤先鋒'));
      expect(bouts[0].whiteName, equals('白水館:白先鋒'));
      expect(bouts[0].matchType, equals('先鋒'));

      // 2試合目（中堅）
      expect(bouts[1].redName, equals('紅葉館:赤中堅'));
      expect(bouts[1].whiteName, equals('白水館:白中堅'));
      expect(bouts[1].matchType, equals('中堅'));

      // 3試合目（大将：白水館が欠員補完されること）
      expect(bouts[2].redName, equals('紅葉館:赤大将'));
      expect(bouts[2].whiteName, equals('白水館:欠員'));
      expect(bouts[2].matchType, equals('大将'));
      expect(bouts[2].source, equals('auto_team'));
    });

    test('トーナメント用の勝者リンクプレースホルダー試合が正しい順序で生成されること', () async {
      await generator.generateLinkedMatch(
        tournamentId: 'tour_main',
        category: '三段以下の部',
        redFromMatchId: 'semi_final_1',
        whiteFromMatchId: 'semi_final_2',
        order: 105.0,
      );

      final captured = verify(
        () => mockAppService.saveMatch(captureAny()),
      ).captured;
      expect(captured.isNotEmpty, isTrue);

      final match = captured.first as MatchModel;
      expect(match.tournamentId, equals('tour_main'));
      expect(match.category, equals('三段以下の部'));
      expect(match.matchType, equals('トーナメント'));
      expect(match.redName, equals('[[Winner:semi_final_1]]'));
      expect(match.whiteName, equals('[[Winner:semi_final_2]]'));
      expect(match.source, equals('auto_tournament'));
      expect(match.order, equals(105.0));
    });
  });
}
