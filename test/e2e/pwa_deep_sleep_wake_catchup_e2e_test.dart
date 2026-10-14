import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/application/projections/tournament_projection_mapper.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/time/server_clock_offset_service.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';

void main() {
  group('[E2E] 観客PWA ディープスリープ復帰・30試合一括差分キャッチアップE2Eテスト', () {
    test('画面ロックで長時間放置後に30試合分の差分イベントを一括受信してもプロジェクションが破綻せず最新状態に同期すること', () async {
      final clockService = ServerClockOffsetService.instance;
      clockService.resetOffset();

      // 1. スリープ前の初期状態（1試合のみ）
      final initialMatches = [
        const MatchModel(
          id: 'sleep_m_0',
          tournamentId: 't_deep_sleep',
          matchType: '個人戦',
          status: 'in_progress',
          redName: '選手0_赤',
          whiteName: '選手0_白',
          redScore: 0,
          whiteScore: 0,
        ),
      ];

      final streamController = StreamController<List<MatchModel>>.broadcast();
      List<MatchModel> pwaState = [...initialMatches];

      final subscription = streamController.stream.listen((updatedList) {
        pwaState = List<MatchModel>.from(updatedList);
      });

      // 2. ディープスリープシミュレーション（時計が2時間進む）
      clockService.setOffset(const Duration(hours: 2));

      // 3. バックグラウンドで30試合が進行完了
      final caughtUpMatches = List.generate(30, (i) {
        return MatchModel(
          id: 'sleep_m_$i',
          tournamentId: 't_deep_sleep',
          matchType: '個人戦',
          status: 'finished',
          redName: '選手${i}_赤',
          whiteName: '選手${i}_白',
          redScore: (i % 2 == 0) ? 2 : 1,
          whiteScore: (i % 2 == 0) ? 0 : 2,
          order: i.toDouble(),
        );
      });

      // 4. 端末ウェイクアップ（一括受信）
      streamController.add(caughtUpMatches);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(pwaState.length, 30);
      expect(pwaState.every((m) => m.status == 'finished'), isTrue);

      // プロジェクションマッピング検証
      final tournament = TournamentModel(
        id: 't_deep_sleep',
        organizationId: 'org_1',
        name: 'ディープスリープ検証大会',
        venue: '日本武道館',
        date: DateTime(2026, 10, 2),
      );
      final projections = TournamentProjectionMapper.fromModels(
        tournament,
        pwaState,
      );

      expect(projections.allMatches.length, 30);
      expect(
        projections.allMatches.where((m) => m.status == 'finished').length,
        30,
      );

      await subscription.cancel();
      await streamController.close();
      clockService.resetOffset();
    });

    testWidgets('ディープスリープ復帰によるブラウザ自動再ロード後に大会ホームから大会一覧へ戻るボタンで正常復帰できること', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/home/t_deep_sleep',
        routes: [
          GoRoute(
            path: '/home/:tournamentId',
            builder: (context, state) => const Scaffold(
              appBar: AppHeader(
                title: '大会ホーム',
                fallbackRoute: '/tournament-list',
              ),
              body: Center(child: Text('大会ホームコンテンツ')),
            ),
          ),
          GoRoute(
            path: '/tournament-list',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('最近の大会 (一覧画面)'))),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          theme: ThemeData(
            extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
          ),
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('大会ホーム'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pumpAndSettle();

      expect(find.text('最近の大会 (一覧画面)'), findsOneWidget);
    });

    testWidgets('ディープスリープ復帰によるブラウザ自動再ロード後に部内戦ホームからトップ画面へ戻るボタンで正常復帰できること', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/bunaiksen-home',
        routes: [
          GoRoute(
            path: '/bunaiksen-home',
            builder: (context, state) => const Scaffold(
              appBar: AppHeader(title: '部内戦ホーム', fallbackRoute: '/'),
              body: Center(child: Text('部内戦ホームコンテンツ')),
            ),
          ),
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('トップ画面 (StartScreen)')),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          theme: ThemeData(
            extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
          ),
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('部内戦ホーム'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pumpAndSettle();

      expect(find.text('トップ画面 (StartScreen)'), findsOneWidget);
    });
  });
}
