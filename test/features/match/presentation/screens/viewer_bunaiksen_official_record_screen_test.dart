import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/domain/match/match_model.dart';
import 'package:kendo_os/domain/entities/settings_model.dart';
import 'package:kendo_os/presentation/operate/providers/settings_provider.dart';
import 'package:kendo_os/presentation/viewer/screens/viewer_bunaiksen_official_record_screen.dart';
import 'package:kendo_os/presentation/operate/providers/match_view_model_provider.dart';
import 'package:kendo_os/presentation/shared/providers/dojo_room_sync_provider.dart';
import 'package:kendo_os/presentation/shared/providers/current_sync_context_provider.dart';
import 'package:kendo_os/presentation/shared/providers/current_user_role_provider.dart';
import 'package:kendo_os/domain/entities/user_role.dart';

// モック用のSettingsNotifier
class MockSettingsNotifier extends SettingsNotifier {
  @override
  SettingsModel build() =>
      const SettingsModel(securityLevel: 1, enableLiquidGlass: false);
}

// Mock MatchModel creator
MatchModel createMockMatch({
  String id = 'm1',
  String tournamentId = 'bunaiksen_20250101',
  String category = '一般',
  String groupName = '団体戦A',
  String redName = 'チームA:先鋒',
  String whiteName = 'チームB:先鋒',
  int redScore = 0,
  int whiteScore = 0,
  String matchType = '先鋒',
  String status = 'finished',
  String note = '',
  double order = 1.0,
}) {
  return MatchModel(
    id: id,
    tournamentId: tournamentId,
    category: category,
    groupName: groupName,
    redName: redName,
    whiteName: whiteName,
    redScore: redScore,
    whiteScore: whiteScore,
    matchType: matchType,
    status: status,
    order: order,
    note: note,
    events: const [],
  );
}

void main() {
  const testTournamentId = 'bunaiksen_20250101';

  testWidgets(
    'ViewerBunaiksenOfficialRecordScreen team score table should display "赤" and "白"',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final matches = [
        createMockMatch(redName: 'チームRed:選手1', whiteName: 'チームWhite:選手1'),
      ];

      final Map<String, Map<String, List<MatchModel>>> categoryGroups = {
        '一般': {'団体戦A': matches},
      };

      // テスト用のダミールーターを用意
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                const ViewerBunaiksenOfficialRecordScreen(
                  tournamentId: testTournamentId,
                ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bunaiksenRecordCategoryGroupsProvider(
              testTournamentId,
            ).overrideWith((ref) => categoryGroups),
            settingsProvider.overrideWith(() => MockSettingsNotifier()),
            dojoRoomSyncProvider.overrideWith((ref) {}),
            currentDojoIdProvider.overrideWith((ref) => 'test_dojo'),
            currentUserRoleProvider.overrideWith((ref) => UserRole.viewer),
          ],
          child: MaterialApp.router(
            theme: ThemeData(splashFactory: NoSplash.splashFactory),
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the score table
      expect(find.byType(Table), findsOneWidget);

      // Check for "赤" and "白" labels
      expect(find.text('赤'), findsOneWidget);
      expect(find.text('白'), findsOneWidget);

      // Ensure team names are NOT used as row labels
      expect(find.text('チームRed'), findsNothing);
      expect(find.text('チームWhite'), findsNothing);
    },
  );

  testWidgets(
    'ViewerBunaiksenOfficialRecordScreen should display empty cell for "欠員"',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final matches = [
        createMockMatch(
          redName: 'チームA:山田太郎',
          whiteName: 'チームB:(欠員)',
          matchType: '先鋒',
        ),
      ];

      final categoryGroups = {
        '一般': {'団体戦A': matches},
      };

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                const ViewerBunaiksenOfficialRecordScreen(
                  tournamentId: testTournamentId,
                ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bunaiksenRecordCategoryGroupsProvider(
              testTournamentId,
            ).overrideWith((ref) => categoryGroups),
            settingsProvider.overrideWith(() => MockSettingsNotifier()),
            dojoRoomSyncProvider.overrideWith((ref) {}),
            currentDojoIdProvider.overrideWith((ref) => 'test_dojo'),
            currentUserRoleProvider.overrideWith((ref) => UserRole.viewer),
          ],
          child: MaterialApp.router(
            theme: ThemeData(splashFactory: NoSplash.splashFactory),
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      final tableWidget = tester.widget<Table>(find.byType(Table).first);
      final whiteNameRow = tableWidget.children[3];
      final nameCellWidget = whiteNameRow.children[1] as Container;

      expect(nameCellWidget.child, isNull);
      expect(find.text('(欠員)'), findsNothing);
    },
  );

  testWidgets(
    'ViewerBunaiksenOfficialRecordScreen should display initial for same last names',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final matches = [
        createMockMatch(
          id: 'm1',
          order: 1,
          matchType: '先鋒',
          redName: 'チームA:山田 太郎',
          whiteName: 'チームB:佐藤 一',
        ),
        createMockMatch(
          id: 'm2',
          order: 2,
          matchType: '次鋒',
          redName: 'チームA:山田 花子',
          whiteName: 'チームB:鈴木 二',
        ),
      ];

      final categoryGroups = {
        '一般': {'団体戦A': matches},
      };

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                const ViewerBunaiksenOfficialRecordScreen(
                  tournamentId: testTournamentId,
                ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bunaiksenRecordCategoryGroupsProvider(
              testTournamentId,
            ).overrideWith((ref) => categoryGroups),
            settingsProvider.overrideWith(() => MockSettingsNotifier()),
            dojoRoomSyncProvider.overrideWith((ref) {}),
            currentDojoIdProvider.overrideWith((ref) => 'test_dojo'),
            currentUserRoleProvider.overrideWith((ref) => UserRole.viewer),
          ],
          child: MaterialApp.router(
            theme: ThemeData(splashFactory: NoSplash.splashFactory),
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      final initialTaroFinder = find.text('太');
      expect(initialTaroFinder, findsOneWidget);
      final rowTaroFinder = find.ancestor(
        of: initialTaroFinder,
        matching: find.byType(Row),
      );
      expect(
        find.descendant(of: rowTaroFinder, matching: find.text('山')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: rowTaroFinder, matching: find.text('田')),
        findsOneWidget,
      );

      final initialHanakoFinder = find.text('花');
      expect(initialHanakoFinder, findsOneWidget);
      final rowHanakoFinder = find.ancestor(
        of: initialHanakoFinder,
        matching: find.byType(Row),
      );
      expect(
        find.descendant(of: rowHanakoFinder, matching: find.text('山')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: rowHanakoFinder, matching: find.text('田')),
        findsOneWidget,
      );

      expect(find.text('一'), findsNothing);
      expect(find.text('二'), findsNothing);
    },
  );

  testWidgets(
    'ViewerBunaiksenOfficialRecordScreen should show and hide loading dialog on PDF export',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final matches = [
        createMockMatch(redName: 'チームRed:選手1', whiteName: 'チームWhite:選手1'),
      ];

      final Map<String, Map<String, List<MatchModel>>> categoryGroups = {
        '一般': {'団体戦A': matches},
      };

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                const ViewerBunaiksenOfficialRecordScreen(
                  tournamentId: testTournamentId,
                ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bunaiksenRecordCategoryGroupsProvider(
              testTournamentId,
            ).overrideWith((ref) => categoryGroups),
            settingsProvider.overrideWith(() => MockSettingsNotifier()),
            dojoRoomSyncProvider.overrideWith((ref) {}),
            currentDojoIdProvider.overrideWith((ref) => 'test_dojo'),
            currentUserRoleProvider.overrideWith((ref) => UserRole.viewer),
          ],
          child: MaterialApp.router(
            theme: ThemeData(splashFactory: NoSplash.splashFactory),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final pdfButton = find.text('PDF印刷').first;
      await tester.tap(pdfButton);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );
}
