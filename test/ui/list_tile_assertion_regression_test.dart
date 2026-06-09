import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/team_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/tournament_repository.dart';
import 'package:kendo_os/features/tournament/presentation/operate/settings_screen.dart';
import 'package:kendo_os/admin/presentation/screens/master_management_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/team_registration_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/setup_match_format_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/order_setup_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/bunaiksen_setup_screen.dart';
import 'package:kendo_os/shared/widgets/smart_player_input.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';

class MockPlayerRepository extends Mock implements PlayerRepository {}

class MockTeamRepository extends Mock implements TeamRepository {}

class MockTournamentRepository extends Mock implements TournamentRepository {}

void main() {
  late MockPlayerRepository mockPlayerRepo;
  late MockTeamRepository mockTeamRepo;

  setUp(() {
    mockPlayerRepo = MockPlayerRepository();
    when(() => mockPlayerRepo.getPlayers()).thenAnswer((_) => Stream.value([]));
    when(
      () => mockPlayerRepo.watchCustomTeamNames(),
    ).thenAnswer((_) => Stream.value([]));

    mockTeamRepo = MockTeamRepository();
    when(
      () => mockTeamRepo.watchTeamsByTournament(any()),
    ).thenAnswer((_) => Stream.value([]));
  });

  group('🛡️ UI Error Regression Tests: ListTile Material Assertion', () {
    testWidgets('❌ [Bad Pattern] 色付きDecoratedBoxが直接ListTileをラップすると例外が発生すること', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              decoration: const BoxDecoration(color: Colors.white),
              child: ListTile(
                title: const Text('Test'),
                onTap: () {}, // ← onTapがないと波紋エフェクトが計算されずアサーションがスローされません
              ),
            ),
          ),
        ),
      );

      // フレームワークからスローされた例外をキャッチ
      final exception = tester.takeException();
      expect(exception, isNotNull);
      expect(
        exception.toString(),
        contains('ListTile background color or ink splashes may be invisible'),
        reason: '色付きのDecoratedBoxの内側にListTileを直置きするとアサーションエラーになる必要があります。',
      );
    });

    testWidgets('✅ [Good Pattern] 中間に透明なMaterialを挟むことで例外を回避できること', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              decoration: const BoxDecoration(color: Colors.white),
              child: Material(
                color: Colors.transparent, // ← これがインクエフェクトの受け皿になる
                child: ListTile(title: const Text('Test'), onTap: () {}),
              ),
            ),
          ),
        ),
      );

      final exception = tester.takeException();
      expect(exception, isNull, reason: '正しい階層構造であれば例外は発生しません。');
    });

    testWidgets('✅ SettingsScreen が ListTile のアサーションエラーなしで正常にレンダリングされること', (
      WidgetTester tester,
    ) async {
      // 依存する SharedPreferences をモック化して UnimplementedError を回避
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            isarProvider.overrideWithValue(null),
          ],
          child: MaterialApp(home: SettingsScreen()),
        ),
      );

      await tester.pumpAndSettle();

      final exception = tester.takeException();
      expect(
        exception,
        isNull,
        reason: 'SettingsScreen内でUIエラー（ListTileのMaterialアサーション等）が発生してはなりません。',
      );

      // UIがクラッシュせずに描画を完了していることを確認
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('✅ MasterManagementScreen がアサーションエラーなしで正常にレンダリングされること', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            playerRepositoryProvider.overrideWithValue(mockPlayerRepo),
            isarProvider.overrideWithValue(null),
          ],
          child: const MaterialApp(home: MasterManagementScreen()),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(MasterManagementScreen), findsOneWidget);
    });

    testWidgets('✅ TeamRegistrationScreen がアサーションエラーなしで正常にレンダリングされること', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            playerRepositoryProvider.overrideWithValue(mockPlayerRepo),
            teamRepositoryProvider.overrideWithValue(mockTeamRepo),
            isarProvider.overrideWithValue(null),
          ],
          child: const MaterialApp(
            home: TeamRegistrationScreen(tournamentId: 'test_id'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(TeamRegistrationScreen), findsOneWidget);
    });

    testWidgets('✅ SetupMatchFormatScreen がアサーションエラーなしで正常にレンダリングされること', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            playerRepositoryProvider.overrideWithValue(mockPlayerRepo),
            teamRepositoryProvider.overrideWithValue(mockTeamRepo),
            isarProvider.overrideWithValue(null),
          ],
          child: const MaterialApp(
            home: SetupMatchFormatScreen(tournamentId: 'test_id'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(SetupMatchFormatScreen), findsOneWidget);
    });

    testWidgets('✅ OrderSetupScreen がアサーションエラーなしで正常にレンダリングされること', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            playerRepositoryProvider.overrideWithValue(mockPlayerRepo),
            isarProvider.overrideWithValue(null),
            opponentTeamHistoryProvider.overrideWithValue([]),
          ],
          child: const MaterialApp(
            home: OrderSetupScreen(tournamentId: 'test_id'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(OrderSetupScreen), findsOneWidget);
    });

    testWidgets('✅ BunaiksenSetupScreen がアサーションエラーなしで正常にレンダリングされること', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            playerRepositoryProvider.overrideWithValue(mockPlayerRepo),
            isarProvider.overrideWithValue(null),
            bunaiksenPlayerMasterProvider.overrideWith(
              (ref) => Stream.value([]),
            ),
          ],
          child: const MaterialApp(home: BunaiksenSetupScreen()),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(BunaiksenSetupScreen), findsOneWidget);
    });
  });
}
