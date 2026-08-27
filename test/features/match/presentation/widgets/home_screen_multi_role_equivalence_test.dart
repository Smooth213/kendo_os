import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_timeline_list.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/timeline_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart'
    show tournamentProvider;
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';

void main() {
  // 決定論的テスト用の共通モックデータ作成（個人戦データがFirestore等の都合で重複して流れてきたWeb環境を想定）
  final mockMatches = [
    MatchModel(
      id: 'test_match_1',
      tournamentId: 'target_tournament',
      category: '一般の部',
      groupName: '剣道太郎',
      redName: '自チーム : 剣道太郎',
      whiteName: '相手チーム : 相手選手',
      matchType: '選手', // 個人戦フラグ
      status: 'waiting',
      order: 1.0,
      note: '',
    ),
  ];

  // アプリの実装に合わせた4つの全権限マトリクスを定義
  final rolesToTest = {
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

  rolesToTest.forEach((roleName, permission) {
    testWidgets('[$roleName 権限] ネイティブ基準の画面デザイン・コンポーネント構造との完全な等価性を検証', (
      WidgetTester tester,
    ) async {
      // 1. 各権限プロバイダーを上書きしてモック環境を起動
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matchListProvider.overrideWith((ref) => mockMatches),
            matchListByTournamentProvider.overrideWith(
              (ref, id) => Stream.value(mockMatches),
            ),
            permissionProvider.overrideWith((ref) => permission),
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
            home: const Scaffold(
              body: MatchTimelineList(tournamentId: 'target_tournament'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // ----------------------------------------------------
      // 監査①: 遷移ファイル・コンポーネント配置の同一性検証
      // ----------------------------------------------------
      // home画面を構成する主軸ファイル 'match_timeline_list.dart' のコンポーネントが全権限でマウントされているか
      expect(find.byType(MatchTimelineList), findsOneWidget);

      // ----------------------------------------------------
      // 監査②: アコーディオン階層デザインの等価性検証 (Web/Native共通)
      // ----------------------------------------------------
      // データ件数に関わらず「選手」「個人戦」の性質を持つものは、全権限で必ず個人戦アコーディオン（CircleAvatar）になること
      expect(find.byType(CircleAvatar), findsWidgets);
      expect(find.byKey(const ValueKey('player_剣道太郎')), findsOneWidget);

      // Web版でのリビルド時にスタイルが先祖返り（デフォルト剥ぎ取り）しないよう、強制テーマが挟まれているか
      expect(find.byType(ExpansionTileTheme), findsWidgets);
      final tileTheme = tester.widget<ExpansionTileTheme>(
        find.byType(ExpansionTileTheme).first,
      );
      expect(tileTheme.data.backgroundColor, const Color(0xFF1C1C1E));
      expect(tileTheme.data.collapsedBackgroundColor, const Color(0xFF1C1C1E));

      // ★ 修正: アコーディオンを展開して内部の MatchListTileCard (Slidable) をレンダリングさせる
      final expansionTile = find.byKey(const ValueKey('player_剣道太郎'));
      await tester.ensureVisible(expansionTile);
      await tester.tap(expansionTile);
      await tester.pumpAndSettle();

      // ----------------------------------------------------
      // 監査③: ボタン・操作配置のネイティブ整合性検証
      // ----------------------------------------------------
      if (permission.isReadOnly) {
        // 「応援・保護者・選手（Viewer）」はネイティブ基準通り、編集・削除スライド（Slidable）がツリーに配置されないこと
        expect(find.byType(Slidable), findsNothing);
      } else {
        // 「代表・管理者」「監督・引率責任者」「スコア・記録係」はネイティブ基準通り、スライド（Slidable）が正しく配置されていること
        expect(find.byType(Slidable), findsWidgets);
      }
    });
  });
}
