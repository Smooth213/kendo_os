import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart'
    hide customTeamNamesProvider, searchQueryProvider, isSearchVisibleProvider;
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_timeline_list.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/operator_action_buttons.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/timeline_provider.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';

void main() {
  // 1. 決定論的テスト用の共通モック試合データ（個人戦データ）
  final mockMatches = [
    MatchModel(
      id: 'equivalence_test_match_1',
      tournamentId: 'target_tournament_123',
      category: '小学生の部',
      groupName: '助っ人101',
      redName: '助っ人101 : 剣道太郎',
      whiteName: '相手101 : 相手選手',
      matchType: '個人戦', // ピュア個人戦フラグ
      status: 'waiting',
      order: 1.0,
      note: '',
    ),
  ];

  // 2. 監査対象となる4大権限マトリクスの定義
  final roleMatrices = {
    '最高管理者': const AppPermissions(
      isReadOnly: false,
      canManageTournament: true,
      canCreateMatch: true,
      canChangeSettings: true,
      canDeleteData: true,
    ),
    '大会運営者': const AppPermissions(
      isReadOnly: false,
      canManageTournament: true,
      canCreateMatch: true,
      canChangeSettings: false,
      canDeleteData: false,
    ),
    '試合記録者': const AppPermissions(
      isReadOnly: false,
      canManageTournament: false,
      canCreateMatch: false,
      canChangeSettings: false,
      canDeleteData: false,
    ),
    '一般観客席': const AppPermissions(
      isReadOnly: true,
      canManageTournament: false,
      canCreateMatch: false,
      canChangeSettings: false,
      canDeleteData: false,
    ),
  };

  roleMatrices.forEach((roleName, mockedPermission) {
    testWidgets('[$roleName 権限] ネイティブアプリ基準のデザイン・階層・コンポーネント配置の完全等価性検証', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      // 3. 権限プロバイダおよびデータプロバイダの強制オーバーライド
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            matchListByTournamentProvider.overrideWith(
              (ref, id) => Stream.value(mockMatches),
            ),
            matchListProvider.overrideWith((ref) => mockMatches),
            permissionProvider.overrideWith((ref) => mockedPermission),
            isarProvider.overrideWithValue(null),
            commentStreamProvider.overrideWith((ref, arg) => Stream.value([])),
            tournamentProvider.overrideWith((ref, id) => Stream.value(null)),
            customTeamNamesProvider.overrideWith(
              (ref) => Stream.value(const <String>[]),
            ),
            searchQueryProvider.overrideWith((ref) => ''),
            isSearchVisibleProvider.overrideWith((ref) => false),
          ],
          child: MaterialApp(
            theme: ThemeData(
              brightness: Brightness.dark,
              splashFactory: NoSplash.splashFactory,
            ),
            home: const HomeScreen(tournamentId: 'target_tournament_123'),
          ),
        ),
      );

      // 初期ビルドと非同期ストリームの解決を待機
      await tester.pump();
      await tester.pumpAndSettle();

      // -----------------------------------------------------------------------
      // 📌 監査項目①: 遷移先・包含ファイルの完全同一性検証
      // -----------------------------------------------------------------------
      // 全ての権限において、共通のホームコンポーネントがツリーの正しい位置にマウントされているかを検証
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(MatchTimelineList), findsOneWidget);

      // -----------------------------------------------------------------------
      // 📌 監査項目②: 権限に応じたボタン配置・操作パネルのネイティブ等価性検証
      // -----------------------------------------------------------------------
      if (mockedPermission.isReadOnly) {
        // 「一般観客席」はネイティブの要件通り、操作メニューが絶対に配置されないこと
        expect(find.byType(OperatorActionButtons), findsNothing);
      } else {
        // 「最高管理者」「大会運営者」「試合記録者」は操作メニューがネイティブ基準通りに100%配置されていること
        expect(find.byType(OperatorActionButtons), findsOneWidget);
      }

      // -----------------------------------------------------------------------
      // 📌 監査項目③: アコーディオンの階層デザインおよびマテリアルカラー等価性検証
      // -----------------------------------------------------------------------
      // Web特有のテーマ剥がれによる先祖返りを防ぐため、固定テーマコンポーネントが全権限で機能しているか
      expect(find.byType(ExpansionTileTheme), findsWidgets);

      final tileThemeWidget = tester.widget<ExpansionTileTheme>(
        find.byType(ExpansionTileTheme).first,
      );
      // iOS / ネイティブアプリのTrue Blackに準拠したテーマ定義が静的にバインドされているかを厳格監査
      expect(tileThemeWidget.data.backgroundColor, const Color(0xFF1C1C1E));
      expect(
        tileThemeWidget.data.collapsedBackgroundColor,
        const Color(0xFF1C1C1E),
      );

      // -----------------------------------------------------------------------
      // 📌 監査項目④: リストカードコンポーネントの配置同一性検証
      // -----------------------------------------------------------------------
      // アコーディオンが閉じている場合を考慮して展開を試みる
      if (find.byType(MatchListTileCard).evaluate().isEmpty) {
        final tileFinder = find.byType(ExpansionTile);
        if (tileFinder.evaluate().isNotEmpty) {
          final tile = tileFinder.first;
          await tester.ensureVisible(tile);
          await tester.pumpAndSettle();
          final listTileFinder = find.descendant(
            of: tile,
            matching: find.byType(ListTile),
          );
          if (listTileFinder.evaluate().isNotEmpty) {
            await tester.tap(listTileFinder.first);
          } else {
            await tester.tap(tile);
          }
          await tester.pumpAndSettle();
        }
      }

      // 反映漏れや消失を防ぐため、独立型 Widget である MatchListTileCard が正しくマウントされているか
      expect(find.byType(MatchListTileCard), findsWidgets);

      // 個人戦アコーディオンの証である CircleAvatar が描画されているか
      expect(find.byType(CircleAvatar), findsOneWidget);

      // -----------------------------------------------------------------------
      // 📌 監査項目⑤: スワイプ操作（編集・削除ボタン）の露出制御ガード検証
      // -----------------------------------------------------------------------
      if (!mockedPermission.canManageTournament) {
        // 「試合記録者」「一般観客席」は、ネイティブアプリのガバナンス通り Slidable（削除アクション）が有効化されない、または配置されないこと
        final slidableFinder = find.byType(Slidable);
        if (slidableFinder.evaluate().isNotEmpty) {
          final slidableWidget = tester.widget<Slidable>(slidableFinder.first);
          expect(slidableWidget.enabled, isFalse);
        }
      } else {
        // 「最高管理者」「大会運営者」はネイティブアプリ同様に大会全体の編集・削除権限（Slidable）が完全に露出していること
        expect(find.byType(Slidable), findsWidgets);
      }
    });
  });
}
