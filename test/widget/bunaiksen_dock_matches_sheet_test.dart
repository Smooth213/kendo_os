import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/bunaiksen_dock_matches_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/bunaiksen_score_marks.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_matches_provider.dart';

void main() {
  group('🥋 BunaiksenDockMatchesSheet Widget Tests', () {
    testWidgets('1. ホーム画面と同じ順番（第1試合、第2試合…）で表示され、BunaiksenScoreMarksが描画されること', (
      tester,
    ) async {
      final mockMatch1 = MatchModel(
        id: 'match_1',
        tournamentId: 'bunaiksen_20260911',
        matchType: '個人戦',
        matchOrder: 1,
        order: 1,
        redName: '皿田 脩人',
        whiteName: '塚本 大道',
        redScore: 0,
        whiteScore: 0,
        status: 'pending',
      );

      final mockMatch2 = MatchModel(
        id: 'match_2',
        tournamentId: 'bunaiksen_20260911',
        matchType: '個人戦',
        matchOrder: 2,
        order: 2,
        redName: '皿田 梓人',
        whiteName: '久安 智也',
        redScore: 0,
        whiteScore: 0,
        status: 'pending',
      );

      // コテを取得した第6試合（確定）
      final mockMatch6 = MatchModel(
        id: 'match_6',
        tournamentId: 'bunaiksen_20260911',
        matchType: '個人戦',
        matchOrder: 6,
        order: 6,
        redName: '皿田 脩人',
        whiteName: '塚本 大道',
        redScore: 1,
        whiteScore: 0,
        status: 'approved',
        events: [
          ScoreEvent(
            id: 'ev_1',
            side: Side.red,
            strikeType: StrikeType.kote,
            isIppon: true,
            timestamp: DateTime.now(),
          ),
        ],
      );

      final List<MatchModel> mockMatches = [mockMatch1, mockMatch2, mockMatch6];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bunaiksenMatchesProvider(
              'bunaiksen_20260911',
            ).overrideWithValue(mockMatches),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: BunaiksenDockMatchesSheet(
                tournamentId: 'bunaiksen_20260911',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // ヘッダータイトルの存在確認
      expect(find.text('本日の対戦一覧・進行状況'), findsOneWidget);

      // 第1試合、第2試合、第3試合（リスト順のインデックス基準）が表示されていること
      expect(find.text('第1試合'), findsOneWidget);
      expect(find.text('第2試合'), findsOneWidget);
      expect(find.text('第3試合'), findsOneWidget);

      // 選手名が表示されていること
      expect(find.text('皿田 脩人'), findsNWidgets(2));
      expect(find.text('塚本 大道'), findsNWidgets(2));
      expect(find.text('皿田 梓人'), findsOneWidget);
      expect(find.text('久安 智也'), findsOneWidget);

      // スコアマーク（BunaiksenScoreMarks）が3試合分すべて正しく描画されていること
      expect(find.byType(BunaiksenScoreMarks), findsNWidgets(3));

      // コテの丸囲み文字 '㋙' が描画されていること
      expect(find.text('㋙'), findsOneWidget);

      // ステータスバッジの文言確認
      expect(find.text('待機中'), findsNWidgets(2));
      expect(find.text('確定'), findsOneWidget);
    });
  });
}
