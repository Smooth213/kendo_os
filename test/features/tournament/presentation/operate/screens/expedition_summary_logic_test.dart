import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/tournament/presentation/operate/official_record_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/team_repository.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';

void main() {
  group('🏆 遠征成績サマリー 全日本剣道連盟基準・技別計測＆詳細ボトムシート検証テスト', () {
    testWidgets(
      '1. 全剣連基準（勝数勝ち・本数差勝ち・代表戦勝ち）、個人戦分離、取得技計測、詳細ボトムシート展開が100%正常動作すること',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1366, 1024);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        final now = DateTime.now();

        // 試合1: 本戦 団体戦カードA (自チーム: 東京道場 vs 相手: 京都道場) ➔ 本数差勝ち (2勝3本 vs 2勝2本)
        final bout1 = MatchModel(
          id: 'cardA_senpo',
          tournamentId: 't1',
          matchType: '先鋒',
          category: '小学生高学年',
          groupName: '1回戦 (東京道場 vs 京都道場)',
          redName: '東京道場 : 山田',
          whiteName: '京都道場 : 田中',
          redScore: 2,
          whiteScore: 0,
          status: 'finished',
          events: [
            ScoreEvent(
              id: 'ev1',
              side: Side.red,
              strikeType: StrikeType.men,
              isIppon: true,
              timestamp: now,
            ),
            ScoreEvent(
              id: 'ev2',
              side: Side.red,
              strikeType: StrikeType.kote,
              isIppon: true,
              timestamp: now,
            ),
          ],
        );

        final bout2 = MatchModel(
          id: 'cardA_jiho',
          tournamentId: 't1',
          matchType: '次鋒',
          category: '小学生高学年',
          groupName: '1回戦 (東京道場 vs 京都道場)',
          redName: '東京道場 : 佐藤',
          whiteName: '京都道場 : 高橋',
          redScore: 0,
          whiteScore: 0,
          status: 'finished',
          events: [],
        );

        final bout3 = MatchModel(
          id: 'cardA_chuden',
          tournamentId: 't1',
          matchType: '中堅',
          category: '小学生高学年',
          groupName: '1回戦 (東京道場 vs 京都道場)',
          redName: '東京道場 : 鈴木',
          whiteName: '京都道場 : 伊藤',
          redScore: 1,
          whiteScore: 2,
          status: 'finished',
          events: [
            ScoreEvent(
              id: 'ev3',
              side: Side.red,
              strikeType: StrikeType.dou,
              isIppon: true,
              timestamp: now,
            ),
            ScoreEvent(
              id: 'ev4',
              side: Side.white,
              strikeType: StrikeType.men,
              isIppon: true,
              timestamp: now,
            ),
            ScoreEvent(
              id: 'ev5',
              side: Side.white,
              strikeType: StrikeType.men,
              isIppon: true,
              timestamp: now,
            ),
          ],
        );

        // 試合2: 個人戦 (自チーム: 東京道場 山田 vs 相手: 埼玉道場 渡辺) ➔ 個人成績にのみ反映される
        final indMatch = MatchModel(
          id: 'ind_1',
          tournamentId: 't1',
          matchType: '個人戦',
          category: '小学生高学年',
          groupName: '個人戦トーナメント',
          redName: '東京道場 : 山田',
          whiteName: '埼玉道場 : 渡辺',
          redScore: 1,
          whiteScore: 0,
          status: 'finished',
          events: [
            ScoreEvent(
              id: 'ev6',
              side: Side.red,
              strikeType: StrikeType.tsuki,
              isIppon: true,
              timestamp: now,
            ),
          ],
        );

        final router = GoRouter(
          initialLocation: '/official-record/t1',
          routes: [
            GoRoute(
              path: '/official-record/:id',
              builder: (context, state) => OfficialRecordScreen(
                tournamentId: state.pathParameters['id']!,
              ),
            ),
          ],
        );

        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            tournamentProvider('t1').overrideWith(
              (ref) => Stream.value(
                TournamentModel(
                  id: 't1',
                  organizationId: 'org_1',
                  name: 'テスト大会',
                  date: DateTime.now(),
                  categories: ['小学生高学年'],
                  venue: '日本武道館',
                ),
              ),
            ),
            matchListProvider.overrideWith(
              (ref) => [bout1, bout2, bout3, indMatch],
            ),
            registeredTeamsProvider('t1').overrideWith(
              (ref) => Stream.value([
                const TeamModel(
                  id: 't_tokyo',
                  tournamentId: 't1',
                  teamName: '東京道場',
                  category: '小学生高学年',
                  playerNames: ['山田', '佐藤', '鈴木'],
                ),
              ]),
            ),
            customTeamNamesProvider.overrideWith((ref) => Stream.value([])),
            permissionProvider.overrideWith(
              (ref) => const AppPermissions(
                isReadOnly: false,
                canManageTournament: true,
                canCreateMatch: true,
                canChangeSettings: true,
                canDeleteData: true,
              ),
            ),
            isarProvider.overrideWithValue(null),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              routerConfig: router,
              theme: ThemeData.light(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // サマリーカードが表示されていることを検証
        expect(find.text('成績サマリー'), findsOneWidget);

        // 団体戦1試合（本数差勝ち）と個人戦1試合がそれぞれ「1勝 0敗」として独立集計されていることを検証
        expect(find.text('1勝 0敗'), findsNWidgets(2));

        // 詳細分析ボタンが存在することを確認
        final detailBtn = find.text('詳細分析 ›');
        expect(detailBtn, findsOneWidget);

        // 「詳細分析 ›」をタップしてチーム遠征カルテボトムシートを展開
        await tester.tap(detailBtn);
        await tester.pumpAndSettle();

        // チーム詳細ボトムシートの内容（技別内訳・全剣連対戦カード履歴）を検証
        expect(find.text('成績 詳細分析 (全体)'), findsOneWidget);
        expect(find.text('有効打突・取得技内訳'), findsOneWidget);
        expect(find.text('面 (メ)'), findsOneWidget);
        expect(find.text('小手 (コ)'), findsOneWidget);
        expect(find.text('胴 (ド)'), findsOneWidget);
        expect(find.text('突き (ツ)'), findsOneWidget);
        expect(find.text('対戦カード履歴'), findsOneWidget);
        expect(find.text('本数差勝ち'), findsOneWidget);

        // ★ 案C: 試合名が時間＋シーン名（例: "本戦"）を含んでいることを検証
        expect(find.textContaining('本戦'), findsWidgets);

        // ボトムシートを閉じる
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        // 選手別成績アコーディオンを展開
        await tester.tap(find.textContaining('選手別成績'));
        await tester.pumpAndSettle();

        // 選手バッジ（山田）をタップして個人カルテボトムシートを展開
        final yamadaBadge = find.textContaining('山田:');
        expect(yamadaBadge, findsOneWidget);

        await tester.tap(yamadaBadge);
        await tester.pumpAndSettle();

        // 選手個人カルテの内容を検証
        expect(find.text('山田 選手の個人カルテ'), findsOneWidget);
        expect(find.text('勝率'), findsOneWidget);
        expect(find.text('取得技の内訳'), findsOneWidget);
      },
    );

    testWidgets(
      '2. スマートフォン画面幅（375px）でサマリーヘッダーおよび対戦カードがオーバーフローせず正常にレンダリングされること',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        final now = DateTime(2026, 8, 14, 10, 15);

        final boutA = MatchModel(
          id: 'cardA_1',
          tournamentId: 't1',
          matchType: '先鋒',
          category: '小学生高学年',
          groupName: 'edb185f4-131b-4380-b27b-e0619d79804e', // ★ UUID
          redName: '道上剣友会A : 山田',
          whiteName: '相手チーム : 田中',
          redScore: 2,
          whiteScore: 0,
          status: 'finished',
          lastUpdatedAt: now,
          matchScene: 'renseikai',
          events: [
            ScoreEvent(
              id: 'ev1',
              side: Side.red,
              strikeType: StrikeType.men,
              isIppon: true,
              timestamp: now,
            ),
          ],
        );

        final router = GoRouter(
          initialLocation: '/official-record/t1',
          routes: [
            GoRoute(
              path: '/official-record/:id',
              builder: (context, state) => OfficialRecordScreen(
                tournamentId: state.pathParameters['id']!,
              ),
            ),
          ],
        );

        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            tournamentProvider('t1').overrideWith(
              (ref) => Stream.value(
                TournamentModel(
                  id: 't1',
                  organizationId: 'org_1',
                  name: 'テスト大会',
                  date: DateTime.now(),
                  categories: ['小学生高学年'],
                  venue: '日本武道館',
                ),
              ),
            ),
            matchListProvider.overrideWith((ref) => [boutA]),
            registeredTeamsProvider('t1').overrideWith(
              (ref) => Stream.value([
                const TeamModel(
                  id: 't_michigamiA',
                  tournamentId: 't1',
                  teamName: '道上剣友会A',
                  category: '小学生高学年',
                  playerNames: ['山田'],
                ),
                const TeamModel(
                  id: 't_michigamiB',
                  tournamentId: 't1',
                  teamName: '道上剣友会B',
                  category: '小学生高学年',
                  playerNames: ['佐藤'],
                ),
              ]),
            ),
            customTeamNamesProvider.overrideWith((ref) => Stream.value([])),
            permissionProvider.overrideWith(
              (ref) => const AppPermissions(
                isReadOnly: false,
                canManageTournament: true,
                canCreateMatch: true,
                canChangeSettings: true,
                canDeleteData: true,
              ),
            ),
            isarProvider.overrideWithValue(null),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              routerConfig: router,
              theme: ThemeData.light(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 375px幅でサマリーヘッダーが正常に描画され、エラーがないことを検証
        expect(find.text('成績サマリー'), findsOneWidget);
        expect(find.text('詳細分析 ›'), findsOneWidget);

        // 詳細分析を開いてUUIDが排除され「10:15 錬成会」と表示されていることを検証
        await tester.tap(find.text('詳細分析 ›'));
        await tester.pumpAndSettle();

        expect(find.text('10:15 錬成会'), findsOneWidget);
        expect(find.textContaining('edb185f4'), findsNothing);
      },
    );
  });
}
