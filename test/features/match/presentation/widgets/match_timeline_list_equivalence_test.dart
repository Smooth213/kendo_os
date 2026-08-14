import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_timeline_list.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/timeline_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart'
    show tournamentProvider;
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';

void main() {
  testWidgets(
    'MatchTimelineList ensures environment-agnostic accordion equivalence',
    (WidgetTester tester) async {
      // 1. 監査用の決定論的モックデータ作成
      // Web環境で Firestore ストリームから複数件の重複に見えるデータが流れてきたケースを再現
      final mockIndividualMatch1 = MatchModel(
        id: 'mock_indiv_1',
        tournamentId: 'test_tournament',
        category: '一般男子の部',
        groupName: '剣道太郎',
        redName: '自チーム : 剣道太郎',
        whiteName: '相手チーム : 相手選手',
        matchType: '選手', // 個人戦フラグ
        status: 'waiting',
        order: 1.0,
        note: '',
      );

      final mockIndividualMatch2 = MatchModel(
        id: 'mock_indiv_2',
        tournamentId: 'test_tournament',
        category: '一般男子の部',
        groupName: '剣道太郎',
        redName: '自チーム : 剣道太郎',
        whiteName: '相手チーム : 別の相手',
        matchType: 'individual', // 個人戦フラグ
        status: 'waiting',
        order: 2.0,
        note: '',
      );

      final mockMatches = [mockIndividualMatch1, mockIndividualMatch2];

      // 2. ウィジェットのビルドパイプライン起動
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // 🛡️ リストプロバイダーをモックデータで上書きし、Isar等の外部依存を完全遮断
            matchListProvider.overrideWith((ref) => mockMatches),
            matchListByTournamentProvider.overrideWith(
              (ref, id) => Stream.value(mockMatches),
            ),
            isarProvider.overrideWithValue(null),
            commentStreamProvider.overrideWith((ref, arg) => Stream.value([])),
            tournamentProvider.overrideWith((ref, id) => Stream.value(null)),
            customTeamNamesProvider.overrideWith(
              (ref) => Stream.value(const <String>[]),
            ),
            searchQueryProvider.overrideWith((ref) => ''),
            isSearchVisibleProvider.overrideWith((ref) => false),
            permissionProvider.overrideWith(
              (ref) => const AppPermissions(
                isReadOnly: false,
                canManageTournament: true,
                canCreateMatch: true,
                canChangeSettings: true,
                canDeleteData: true,
              ),
            ),
          ],
          child: MaterialApp(
            theme: ThemeData(
              brightness:
                  Brightness.dark, // ★ アサーションのカラー(0xFF1C1C1E)に合わせてダークモードを指定
              splashFactory: NoSplash.splashFactory,
            ),
            home: const Scaffold(
              body: MatchTimelineList(tournamentId: 'test_tournament'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 3. 監査フェーズ①: 複数件データがあっても団体戦アコーディオンに化けず、個人戦として正しく分類されているか
      // 個人戦アコーディオンの証である CircleAvatar の存在を確認
      expect(find.byType(CircleAvatar), findsWidgets);
      expect(find.byKey(const ValueKey('player_剣道太郎')), findsOneWidget);

      // 4. 監査フェーズ②: Web環境でのスタイル先祖返りを防ぐための ExpansionTileTheme がツリー上に存在するか
      expect(find.byType(ExpansionTileTheme), findsWidgets);
      final expansionTileThemeWidget = tester.widget<ExpansionTileTheme>(
        find.byType(ExpansionTileTheme).first,
      );
      expect(
        expansionTileThemeWidget.data.backgroundColor,
        const Color(0xFF1C1C1E),
      );
      expect(
        expansionTileThemeWidget.data.collapsedBackgroundColor,
        const Color(0xFF1C1C1E),
      );
    },
  );
}
