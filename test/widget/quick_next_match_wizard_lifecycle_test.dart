import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/application/mappers/match_projection_mapper.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/quick_next_match/quick_next_match_wizard_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_player_match_classifier.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_screen_providers.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/safe_timeline_provider.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:mocktail/mocktail.dart';

class MockMatchApplicationService extends Mock
    implements MatchApplicationService {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const MatchModel(
        id: 'fallback_id',
        matchType: '個人戦',
        redName: 'red',
        whiteName: 'white',
      ),
    );
  });

  group('[Widget] クイック次戦ウィザード起動〜試合生成〜スコア入力・確定〜タイムライン更新ライフサイクル統合テスト', () {
    late MockMatchApplicationService mockMatchService;
    final List<MatchModel> matchStore = [];

    final dummyPlayers = [
      PlayerModel(
        id: 'p1',
        lastName: '皿田',
        firstName: '脩人',
        lastNameKana: 'さらだ',
        firstNameKana: 'しゅうと',
        grade: 5,
        organization: '道上剣友会',
      ),
      PlayerModel(
        id: 'p2',
        lastName: '高橋',
        firstName: '武',
        lastNameKana: 'たかはし',
        firstNameKana: 'たけし',
        grade: 5,
        organization: '修道館',
      ),
    ];

    setUp(() {
      mockMatchService = MockMatchApplicationService();
      matchStore.clear();

      when(() => mockMatchService.saveMatch(any())).thenAnswer((
        invocation,
      ) async {
        final match = invocation.positionalArguments[0] as MatchModel;
        matchStore.removeWhere((m) => m.id == match.id);
        matchStore.add(match);
      });
    });

    Widget createTestApp({required Widget child}) {
      return ProviderScope(
        overrides: [
          matchApplicationServiceProvider.overrideWithValue(mockMatchService),
          playerListProvider.overrideWith((ref) => Stream.value(dummyPlayers)),
          customTeamNamesProvider.overrideWith(
            (ref) => Stream.value(['道上剣友会']),
          ),
          registeredTeamsProvider(
            'tourney_life_01',
          ).overrideWith((ref) => Stream.value([])),
        ],
        child: MaterialApp(home: Scaffold(body: child)),
      );
    }

    testWidgets('ウィザードからの試合生成から得点判定・完了確定、タイムラインへの即時反映まで全ライフサイクルが一貫して成立すること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final baseMatch = MatchModel(
        id: 'base_m1',
        tournamentId: 'tourney_life_01',
        matchType: '個人戦',
        category: '小学生の部',
        groupName: '第1コート',
        redName: '皿田 脩人',
        whiteName: '高橋 武',
        rule: const MatchRule(matchTimeMinutes: 3, ipponLimit: 2),
      );

      // ─────────────────────────────────────────────
      // 1. ウィザードシート起動と次戦の確定生成
      // ─────────────────────────────────────────────
      await tester.pumpWidget(
        createTestApp(
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (modalCtx) => QuickNextMatchWizardSheet(
                      baseMatch: baseMatch,
                      teamMatches: const [],
                    ),
                  );
                },
                child: const Text('ウィザードを開く'),
              );
            },
          ),
        ),
      );

      // ボタンを押してウィザードを開く
      await tester.tap(find.text('ウィザードを開く'));
      await tester.pumpAndSettle();

      // Step 0: オーダー確認画面
      expect(find.textContaining('オーダー確認'), findsOneWidget);
      await tester.tap(find.text('試合詳細の設定へ進む'));
      await tester.pumpAndSettle();

      // Step 1: コート・見出し確認
      expect(find.text('対戦相手・紅白へ進む'), findsOneWidget);
      await tester.tap(find.text('対戦相手・紅白へ進む'));
      await tester.pumpAndSettle();

      // Step 2: 対戦相手・紅白設定
      expect(find.text('このオーダーで確定して進む'), findsOneWidget);
      await tester.tap(find.text('このオーダーで確定して進む'));
      await tester.pumpAndSettle();

      // コールバックにより5ポジションの試合モデルが生成され、mockMatchService経由で保存されていること
      expect(matchStore.length, equals(5));
      final createdMatch = matchStore.first;
      expect(createdMatch.tournamentId, equals('tourney_life_01'));

      // ─────────────────────────────────────────────
      // 2. 試合エンジンによるスコアイベントの蓄積と判定
      // ─────────────────────────────────────────────
      final engine = KendoRuleEngine();
      final now = DateTime(2026, 10, 15, 14, 0, 0);

      // 赤（皿田）が面を先取
      final redMen = ScoreEvent(
        id: 'ev_01',
        side: Side.red,
        strikeType: StrikeType.men,
        isIppon: true,
        timestamp: now,
        sequence: 1,
        logicalClock: 1,
      );

      // 赤（皿田）が小手を決めて二本勝ち
      final redKote = ScoreEvent(
        id: 'ev_02',
        side: Side.red,
        strikeType: StrikeType.kote,
        isIppon: true,
        timestamp: now.add(const Duration(seconds: 45)),
        sequence: 2,
        logicalClock: 2,
      );

      final events = [redMen, redKote];
      final rule = createdMatch.rule;
      final analysis = engine.analyzeHistory(events, createdMatch, rule);

      // 二本取得により規定本数達成
      expect(analysis.context.redIppon, equals(2));
      expect(analysis.context.whiteIppon, equals(0));
      expect(analysis.displays[Side.red]?.length, equals(2));

      // ─────────────────────────────────────────────
      // 3. 試合結果の反映・完了化（finished）
      // ─────────────────────────────────────────────
      final finishedMatch = createdMatch.copyWith(
        events: events,
        redScore: analysis.context.redIppon,
        whiteScore: analysis.context.whiteIppon,
        status: 'finished',
        lastUpdatedAt: now.add(const Duration(seconds: 46)),
      );

      await mockMatchService.saveMatch(finishedMatch);
      final savedMatch = matchStore.firstWhere((m) => m.id == createdMatch.id);
      expect(savedMatch.status, equals('finished'));
      expect(savedMatch.redScore, equals(2));

      // Projectionへのマッピング検証
      final projection = MatchProjectionMapper.toMatchProjection(
        finishedMatch,
        analysis,
      );
      expect(projection.status, equals('finished'));
      expect(projection.redScore, equals(2));
      expect(projection.whiteScore, equals(0));

      // ─────────────────────────────────────────────
      // 4. タイムライン分類器による完了試合の反映検証
      // ─────────────────────────────────────────────
      final classified = TimelinePlayerMatchClassifier.classifyTeamMatches(
        teamMatchesList: matchStore,
        teamName: '道上剣友会',
        sanitizedQuery: '',
        matchedMatchIds: {},
        matchedGroupNames: {},
        ownTeams: ['道上剣友会'],
      );

      // 個人戦選手グループまたは団体グループに登録・分類されていること
      final totalMatches =
          classified.sortedGroups.fold<int>(
            0,
            (sum, e) => sum + e.value.length,
          ) +
          classified.sortedPlayers.fold<int>(
            0,
            (sum, e) => sum + e.value.length,
          );

      expect(totalMatches, equals(5));
    });
  });
}
