import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_edit_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_timeline_list.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/presentation/providers/current_user_role_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late MatchModel testMatch;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();

    testMatch = MatchModel(
      id: 'match_test_101',
      tournamentId: 'tourney_test_001',
      category: '一般男子',
      matchType: '個人戦',
      order: 1.0,
      redName: '山田 太郎',
      whiteName: '佐藤 次郎',
      status: 'waiting',
      note: '1回戦',
    );
  });

  Widget createTestWidget({
    required UserRole role,
    required AppPermissions permissions,
    required MatchModel match,
  }) {
    final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'operate');

    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        currentUserRoleProvider.overrideWith((ref) => role),
        permissionProvider.overrideWith((ref) => permissions),
        matchListProvider.overrideWith((ref) => [match]),
        matchListByTournamentProvider(
          match.tournamentId!,
        ).overrideWith((ref) => Stream.value([match])),
        customTeamNamesProvider.overrideWith((ref) => Stream.value([])),
      ],
      child: MaterialApp(
        theme: ThemeData.light().copyWith(extensions: [themeColors]),
        home: Scaffold(
          body: SizedBox(
            width: 500,
            height: 800,
            child: ListView(
              children: [
                SlidableAutoCloseBehavior(
                  child: MatchListTileCard(
                    initialMatch: match,
                    isDeletable: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  group('🥋 MatchListTileCard スワイプ権限制御テスト', () {
    testWidgets('1. 【試合記録者 (Recorder)】 スワイプで「編集」が表示され、「削除」は非表示であること', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          role: UserRole.recorder,
          permissions: const AppPermissions(
            role: UserRole.recorder,
            isReadOnly: false,
            canManageTournament: false,
            canDeleteData: false,
            canCreateMatch: true,
          ),
          match: testMatch,
        ),
      );
      await tester.pumpAndSettle();

      // カードが表示されている
      expect(find.text('山田 太郎'), findsOneWidget);
      expect(find.text('佐藤 次郎'), findsOneWidget);

      // 左スワイプして Slidable アクションを展開
      await tester.drag(find.text('山田 太郎'), const Offset(-300, 0));
      await tester.pumpAndSettle();

      // ★ 「編集」アクションが表示されていること
      expect(find.text('編集'), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsOneWidget);

      // ★ 「削除」アクションは表示されないこと
      expect(find.text('削除'), findsNothing);
      expect(find.byIcon(Icons.delete), findsNothing);

      // 「編集」をタップすると MatchEditSheet が立ち上がること
      await tester.tap(find.text('編集'));
      await tester.pumpAndSettle();

      expect(find.byType(MatchEditSheet), findsOneWidget);
    });

    testWidgets('2. 【大会管理者 (Admin)】 スワイプで「編集」と「削除」の両方が表示されること', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          role: UserRole.admin,
          permissions: const AppPermissions(
            role: UserRole.admin,
            isReadOnly: false,
            canManageTournament: true,
            canDeleteData: true,
            canCreateMatch: true,
          ),
          match: testMatch,
        ),
      );
      await tester.pumpAndSettle();

      // 左スワイプ
      await tester.drag(find.text('山田 太郎'), const Offset(-300, 0));
      await tester.pumpAndSettle();

      // 「編集」と「削除」の両方が存在すること
      expect(find.text('編集'), findsOneWidget);
      expect(find.text('削除'), findsOneWidget);
    });

    testWidgets('3. 【閲覧者 (Viewer)】 スワイプが無効化され、アクションが一切露出しないこと', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          role: UserRole.viewer,
          permissions: const AppPermissions(
            role: UserRole.viewer,
            isReadOnly: true,
            canManageTournament: false,
            canDeleteData: false,
            canCreateMatch: false,
          ),
          match: testMatch,
        ),
      );
      await tester.pumpAndSettle();

      // 左スワイプを試みる
      await tester.drag(find.text('山田 太郎'), const Offset(-300, 0));
      await tester.pumpAndSettle();

      // SlidableActionは一切表示されないこと
      expect(find.text('編集'), findsNothing);
      expect(find.text('削除'), findsNothing);
    });
  });
}
