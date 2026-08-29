import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kendo_os/features/tournament/presentation/operate/screens/tournament_list_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/shared/infrastructure/repository/tournament_repository.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/sync_provider.dart';

class MockTournamentRepository extends Mock implements TournamentRepository {}

class MockSyncEngine extends Mock implements SyncEngine {}

void main() {
  group('🛡️ 【過去の大会 (アーカイブ) 高速化＆無限ローディング防止 保証テスト】', () {
    late MockTournamentRepository mockTournamentRepo;
    late MockSyncEngine mockSyncEngine;

    setUp(() {
      mockTournamentRepo = MockTournamentRepository();
      mockSyncEngine = MockSyncEngine();
    });

    Widget createTestApp({
      required Widget child,
      required SharedPreferences prefs,
      List<Override> extraOverrides = const [],
    }) {
      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          tournamentRepositoryProvider.overrideWithValue(mockTournamentRepo),
          syncEngineProvider.overrideWithValue(mockSyncEngine),
          permissionProvider.overrideWith(
            (ref) => const AppPermissions(
              isReadOnly: false,
              canManageTournament: true,
              canCreateMatch: true,
              canChangeSettings: true,
              canDeleteData: true,
            ),
          ),
          ...extraOverrides,
        ],
        child: MaterialApp(home: child),
      );
    }

    testWidgets('1. 【即時表示保証】過去の大会が正常に取得され、ローディング待機なく一覧が表示されること', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final mockTournaments = [
        TournamentModel(
          id: 'archived_2025_01',
          name: '第20回 春季錬成大会',
          date: DateTime(2025, 3, 15),
          venue: '第一武道館',
          categories: const [],
          organizationId: 'org_1',
        ),
        TournamentModel(
          id: 'archived_2024_12',
          name: '第19回 冬季選手権大会',
          date: DateTime(2024, 12, 20),
          venue: '武道館メインアリーナ',
          categories: const [],
          organizationId: 'org_1',
        ),
      ];

      int callCount = 0;
      when(() => mockTournamentRepo.getArchivedTournaments()).thenAnswer((
        _,
      ) async {
        callCount++;
        return mockTournaments;
      });

      await tester.pumpWidget(
        createTestApp(
          prefs: prefs,
          child: const TournamentListScreen(isArchive: true),
        ),
      );

      // 初回 pump (非同期取得中)
      await tester.pump();
      await tester.pumpAndSettle();

      // 大会名が正しく描画されていること
      expect(find.text('第20回 春季錬成大会'), findsOneWidget);
      expect(find.text('第19回 冬季選手権大会'), findsOneWidget);
      expect(find.text('2025年03月'), findsOneWidget);
      expect(find.text('2024年12月'), findsOneWidget);

      // リポジトリの取得メソッドが1回だけ呼ばれたこと
      expect(callCount, 1);
    });

    testWidgets(
      '2. 【Rebuild耐性・通信ループ防止】画面が連続で再描画されても無駄な再フェッチが発生せずキャッシュが維持されること',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        final mockTournaments = [
          TournamentModel(
            id: 'archived_test_cache',
            name: 'キャッシュ検証大会',
            date: DateTime(2025, 1, 10),
            venue: '東京武道館',
            categories: const [],
            organizationId: 'org_1',
          ),
        ];

        int callCount = 0;
        when(() => mockTournamentRepo.getArchivedTournaments()).thenAnswer((
          _,
        ) async {
          callCount++;
          return mockTournaments;
        });

        await tester.pumpWidget(
          createTestApp(
            prefs: prefs,
            child: const TournamentListScreen(isArchive: true),
          ),
        );
        await tester.pumpAndSettle();

        expect(callCount, 1);
        expect(find.text('キャッシュ検証大会'), findsOneWidget);

        // 画面の連続リビルドを模倣（10回連続で pump 実行）
        for (int i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }

        // Rebuildされても通信回数は 1 のままであること（通信ループの完全根絶を検証）
        expect(callCount, 1);
        expect(find.text('キャッシュ検証大会'), findsOneWidget);
      },
    );

    testWidgets('3. 【Empty State検証】過去大会が0件の場合、透かしアイコンと適切な案内メッセージが表示されること', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      when(
        () => mockTournamentRepo.getArchivedTournaments(),
      ).thenAnswer((_) async => []);

      await tester.pumpWidget(
        createTestApp(
          prefs: prefs,
          child: const TournamentListScreen(isArchive: true),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('過去の大会記録はありません'), findsOneWidget);
      expect(find.text('終了した大会がここにアーカイブされます。'), findsOneWidget);
    });

    testWidgets('4. 【Pull to Refresh検証】引っ張って更新時にキャッシュが安全に無効化され最新データに更新されること', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      int fetchIteration = 0;
      when(() => mockTournamentRepo.getArchivedTournaments()).thenAnswer((
        _,
      ) async {
        fetchIteration++;
        if (fetchIteration == 1) {
          return [
            TournamentModel(
              id: 'initial_archived',
              name: '更新前大会',
              date: DateTime(2025, 2, 1),
              venue: '会場A',
              categories: const [],
              organizationId: 'org_1',
            ),
          ];
        } else {
          return [
            TournamentModel(
              id: 'initial_archived',
              name: '更新前大会',
              date: DateTime(2025, 2, 1),
              venue: '会場A',
              categories: const [],
              organizationId: 'org_1',
            ),
            TournamentModel(
              id: 'new_archived',
              name: '新規追加された過去大会',
              date: DateTime(2025, 2, 20),
              venue: '会場B',
              categories: const [],
              organizationId: 'org_1',
            ),
          ];
        }
      });

      await tester.pumpWidget(
        createTestApp(
          prefs: prefs,
          child: const TournamentListScreen(isArchive: true),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('更新前大会'), findsOneWidget);
      expect(find.text('新規追加された過去大会'), findsNothing);
      expect(fetchIteration, 1);

      // リストビューを下に引っ張って更新 (Pull to Refresh)
      await tester.fling(
        find.byType(ListView),
        const Offset(0.0, 300.0),
        1000.0,
      );
      await tester.pumpAndSettle();

      // 2回目の取得が実行され、新規追加された過去大会が表示されること
      expect(fetchIteration, 2);
      expect(find.text('新規追加された過去大会'), findsOneWidget);
    });

    testWidgets('5. 【エラーハンドリング】通信失敗時にエラーメッセージが崩れず表示されること', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      when(
        () => mockTournamentRepo.getArchivedTournaments(),
      ).thenThrow(Exception('ネットワークタイムアウト'));

      await tester.pumpWidget(
        createTestApp(
          prefs: prefs,
          child: const TournamentListScreen(isArchive: true),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('エラーが発生しました'), findsOneWidget);
    });
  });
}
