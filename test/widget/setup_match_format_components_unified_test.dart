import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/safe_pump_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_category_preview_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_dynamic_header.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_section_header.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_team_selection_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/setup_match_format_screen.dart';
import 'package:kendo_os/shared/domain/entities/settings_model.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/team_repository.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

class _MockSettingsNotifier extends SettingsNotifier {
  @override
  SettingsModel build() =>
      const SettingsModel(securityLevel: 1, enableLiquidGlass: false);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Widget] 試合形式設定 各種セクション・カード・ヘッダー・リーグ描画統合検証テスト', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    testWidgets('MatchFormatDynamicHeaderにおいて ヘッダーテキストおよび進行状況が正しく描画されること', (
      tester,
    ) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchFormatDynamicHeader(
              currentPage: 0,
              themeColors: themeColors,
            ),
          ),
        ),
      );

      expect(find.text('試合ルールの設定'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('MatchFormatSectionHeaderにおいて タイトルおよびアクセントバーが正しく描画されること', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MatchFormatSectionHeader(
              title: '試合時間の設定',
              accentColor: Colors.blue,
            ),
          ),
        ),
      );

      expect(find.text('試合時間の設定'), findsOneWidget);
    });

    testWidgets('部門プレビューカードに部門テキストが正しく描画されること', (tester) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchFormatCategoryPreviewCard(
              category: '小学生 低学年 (1-4年)',
              themeColors: themeColors,
              textColor: Colors.black,
            ),
          ),
        ),
      );

      expect(find.text('設定されるカテゴリ名'), findsOneWidget);
      expect(find.text('小学生 低学年 (1-4年)'), findsOneWidget);
    });

    testWidgets('MatchFormatTeamSelectionCardにおいて チーム情報が描画されコールバックが正常に動作すること', (
      tester,
    ) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');
      const team = TeamModel(
        id: 'team1',
        tournamentId: 't1',
        teamName: '洗心道場 A',
        category: '小学生',
        matchType: '5人制',
        playerNames: ['先鋒', '次鋒', '中堅', '副将', '大将'],
      );

      bool tappedSelect = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchFormatTeamSelectionCard(
              team: team,
              isSelected: true,
              themeColors: themeColors,
              textColor: Colors.black,
              isDark: false,
              onSelect: () {
                tappedSelect = true;
              },
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      expect(find.text('洗心道場 A'), findsOneWidget);

      await tester.tap(find.text('洗心道場 A'));
      await tester.pump();
      expect(tappedSelect, isTrue);
    });

    testWidgets('リーグ戦モードで詳細な同点代表戦設定と勝ち点が正しく描画されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const testTeam = TeamModel(
        id: 'team_1',
        tournamentId: 'test_tournament',
        category: '小学生の部',
        teamName: '千代田チーム',
        matchType: 'リーグ団体戦',
        playerNames: ['山田', '佐藤', '鈴木'],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsProvider.overrideWith(() => _MockSettingsNotifier()),
            currentDojoIdProvider.overrideWith((ref) => 'test_dojo_id'),
            playerRepositoryProvider.overrideWith((ref) {
              final dojoId = ref.watch(currentDojoIdProvider);
              return PlayerRepository(dojoId: dojoId, firestore: fakeFirestore);
            }),
            teamRepositoryProvider.overrideWith((ref) {
              final dojoId = ref.watch(currentDojoIdProvider);
              return TeamRepository(dojoId: dojoId, firestore: fakeFirestore);
            }),
            registeredTeamsProvider('test_tournament').overrideWith((ref) {
              return Stream.value([testTeam]);
            }),
          ],
          child: const MaterialApp(
            home: SetupMatchFormatScreen(tournamentId: 'test_tournament'),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      await tester.safePumpAndSettle();

      expect(find.text('千代田チーム'), findsOneWidget);

      await tester.tap(find.text('千代田チーム'));
      await tester.safePumpAndSettle();

      expect(find.text('次へ進む'), findsOneWidget);
      await tester.tap(find.text('次へ進む'));
      await tester.safePumpAndSettle();

      expect(find.text('試合方式'), findsOneWidget);
      expect(find.text('リーグ団体戦'), findsAtLeast(1));

      expect(find.text('同点代表戦'), findsOneWidget);
      expect(find.text('勝ち点'), findsOneWidget);
    });

    testWidgets('その他カテゴリ選択時に登録済みその他カテゴリ一覧チップが表示され、チーム選択でカテゴリ名が自動連動すること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const otherTeam = TeamModel(
        id: 'team_other_1',
        tournamentId: 'test_tournament_other',
        category: '道場対抗の部',
        teamName: '道場対抗Aチーム',
        matchType: '5人戦（3本勝負）',
        playerNames: ['先鋒', '次鋒', '中堅', '副将', '大将'],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsProvider.overrideWith(() => _MockSettingsNotifier()),
            currentDojoIdProvider.overrideWith((ref) => 'test_dojo_id'),
            playerRepositoryProvider.overrideWith((ref) {
              final dojoId = ref.watch(currentDojoIdProvider);
              return PlayerRepository(dojoId: dojoId, firestore: fakeFirestore);
            }),
            teamRepositoryProvider.overrideWith((ref) {
              final dojoId = ref.watch(currentDojoIdProvider);
              return TeamRepository(dojoId: dojoId, firestore: fakeFirestore);
            }),
            registeredTeamsProvider('test_tournament_other').overrideWith((
              ref,
            ) {
              return Stream.value([otherTeam]);
            }),
          ],
          child: const MaterialApp(
            home: SetupMatchFormatScreen(tournamentId: 'test_tournament_other'),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      await tester.safePumpAndSettle();

      // 1. 大分類「その他」をタップ
      expect(find.text('その他'), findsWidgets);
      await tester.tap(find.text('その他').first);
      await tester.safePumpAndSettle();

      // 2. 登録済みその他カテゴリ一覧チップ「道場対抗の部 (1)」が表示されること
      expect(find.text('登録済みのカテゴリから選択：'), findsOneWidget);
      expect(find.text('道場対抗の部 (1)'), findsOneWidget);

      // 3. チーム一覧に「道場対抗Aチーム」が存在すること
      expect(find.text('道場対抗Aチーム', skipOffstage: false), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('道場対抗Aチーム'),
        100.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.safePumpAndSettle();
      expect(find.text('道場対抗Aチーム'), findsOneWidget);

      // 4. 登録済みチップをタップするとカテゴリプレビューに反映されること
      await tester.tap(find.text('道場対抗の部 (1)'));
      await tester.safePumpAndSettle();
      expect(find.text('道場対抗の部'), findsWidgets);
    });
  });
}
