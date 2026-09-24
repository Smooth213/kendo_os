import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kendo_os/features/auth/presentation/screens/role_select_screen.dart';
import 'package:kendo_os/features/auth/presentation/screens/pin_auth_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/start_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/tournament_list_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/bunaiksen_home_screen.dart';
import 'package:kendo_os/features/viewer/presentation/viewer_home_screen.dart';
import 'package:kendo_os/features/viewer/screens/viewer_bunaiksen_home_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/new_match_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/setup_match_format_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/category_rules_screen.dart';
import 'package:kendo_os/admin/presentation/screens/master_management_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/settings_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_edit_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_bottom_sheet_header.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_team_header_row.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_players_score_row.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/tournament_header_card.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/expedition_card_result_list.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/expedition_stats_models.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/calculator/match_calculator_format_selector.dart';
import 'package:kendo_os/features/tournament/presentation/providers/match_calculator_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/timeline_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/tournament_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/sync_engine.dart';
import 'package:kendo_os/shared/presentation/providers/dojo_room_sync_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_user_role_provider.dart';

class MockTournamentRepository extends Mock implements TournamentRepository {}

class MockPlayerRepository extends Mock implements PlayerRepository {}

class MockSyncEngine extends Mock implements SyncEngine {}

class MockLocalMatchRepository extends Mock implements LocalMatchRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(<MatchModel>[]);
    registerFallbackValue(
      const MatchModel(id: '', matchType: '', redName: '', whiteName: ''),
    );
  });

  group('🥋 KendoOS 全画面・全サイズ文字切れ＆省略（...）完全防止テスト', () {
    late MockTournamentRepository mockTournamentRepo;
    late MockPlayerRepository mockPlayerRepo;
    late MockSyncEngine mockSyncEngine;
    late MockLocalMatchRepository mockLocalRepo;
    late List<MatchModel> mockMatches;
    late TournamentModel mockTournament;
    late SharedPreferences prefs;

    setUp(() async {
      mockTournamentRepo = MockTournamentRepository();
      mockPlayerRepo = MockPlayerRepository();
      mockSyncEngine = MockSyncEngine();
      mockLocalRepo = MockLocalMatchRepository();

      mockMatches = [
        MatchModel(
          id: 'test_match_1',
          tournamentId: 'test_tourney_id',
          category: '中学生男子の部',
          groupName: '第1ブロック',
          redName: '岡山剣道連盟道上道場: 山田太郎',
          whiteName: '倉敷少年剣道クラブ旭東: 佐藤次郎',
          matchType: '団体戦',
          status: 'in_progress',
          order: 1.0,
          note: '第7試合場, 4試合目 (延長3回目)',
        ),
      ];

      mockTournament = TournamentModel(
        id: 'test_tourney_id',
        name: '第50回記念 西日本選抜少年剣道大会（春季選手権）',
        date: DateTime(2026, 9, 24),
        venue: '山陽ふれあい公園総合体育館 メインアリーナ',
        categories: const ['中学生男子の部', '小学生団体の部'],
        organizationId: 'dojo_123',
      );

      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();

      when(
        () => mockTournamentRepo.getTournamentStream(any()),
      ).thenAnswer((_) => Stream.value(mockTournament));
      when(
        () => mockTournamentRepo.watchTournaments(),
      ).thenAnswer((_) => Stream.value([mockTournament]));
      when(
        () => mockTournamentRepo.getArchivedTournaments(),
      ).thenAnswer((_) => Future.value([mockTournament]));
      when(
        () => mockPlayerRepo.watchCustomTeamNames(),
      ).thenAnswer((_) => Stream.value(<String>[]));
      when(
        () =>
            mockPlayerRepo.getPlayers(organization: any(named: 'organization')),
      ).thenAnswer((_) => Stream.value([]));
      when(
        () => mockLocalRepo.watchLocalMatches(any()),
      ).thenAnswer((_) => Stream.value(mockMatches));
      when(
        () => mockLocalRepo.watchAllLocalMatches(),
      ).thenAnswer((_) => Stream.value(mockMatches));
      when(
        () => mockLocalRepo.saveMatchesBulk(any()),
      ).thenAnswer((_) => Future.value());
      when(
        () => mockLocalRepo.getPendingCommands(),
      ).thenAnswer((_) => Future.value([]));
    });

    List<Override> createOverrides() {
      return [
        sharedPreferencesProvider.overrideWithValue(prefs),
        tournamentRepositoryProvider.overrideWithValue(mockTournamentRepo),
        playerRepositoryProvider.overrideWithValue(mockPlayerRepo),
        syncEngineProvider.overrideWithValue(mockSyncEngine),
        localMatchRepositoryProvider.overrideWithValue(mockLocalRepo),
        commentStreamProvider.overrideWith((ref, arg) => Stream.value([])),
        dojoRoomSyncProvider.overrideWithValue(null),
        permissionProvider.overrideWith(
          (ref) => const AppPermissions(
            isReadOnly: false,
            canManageTournament: true,
            canCreateMatch: true,
            canChangeSettings: true,
            canDeleteData: true,
          ),
        ),
        currentDojoIdProvider.overrideWith((ref) => 'dojo_123'),
        currentTournamentIdProvider.overrideWith((ref) => 'test_tourney_id'),
        currentUserRoleProvider.overrideWith((ref) => UserRole.operator),
        matchListByTournamentProvider.overrideWith(
          (ref, id) => Stream.value(mockMatches),
        ),
      ];
    }

    /// 指定されたウィジェットを各テキストスケールでポンプし、文字あふれ・省略を検証するヘルパー
    Future<void> testWidgetWithTextScalers({
      required WidgetTester tester,
      required Widget widget,
      required String screenName,
      bool pumpAndSettle = true,
    }) async {
      // スマートフォン標準幅 390x844 (iPhone 12/13/14/15/16)
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // 3つの文字拡大モード: 標準(1.0x), 大(1.2x), 特大(1.35x)
      final scales = [
        ('標準 (1.0x)', const TextScaler.linear(1.0)),
        ('大 (1.2x)', const TextScaler.linear(1.20)),
        ('特大 (1.35x)', const TextScaler.linear(1.35)),
      ];

      for (final (scaleLabel, textScaler) in scales) {
        await tester.pumpWidget(
          ProviderScope(
            overrides: createOverrides(),
            child: MaterialApp(
              theme: ThemeData.light(),
              home: MediaQuery(
                data: MediaQueryData(
                  size: const Size(390, 844),
                  textScaler: textScaler,
                ),
                child: Material(child: widget),
              ),
            ),
          ),
        );

        if (pumpAndSettle) {
          await tester.pump();
          // 短いタイマーや非同期更新を消化
          await tester.pump(const Duration(milliseconds: 100));
        } else {
          await tester.pump();
        }

        // 1. レイアウトエラー（RenderFlex overflow 等）がゼロであること
        final exception = tester.takeException();
        expect(
          exception,
          isNull,
          reason: '[$screenName - $scaleLabel] レイアウトオーバーフロー例外が発生してはならない',
        );

        // 2. RenderParagraph の didExceedMaxLines 検査
        // maxLines を超過して文字があふれ・切断されている箇所を検知
        final richTexts = tester.renderObjectList<RenderParagraph>(
          find.byType(RichText),
        );
        for (final rp in richTexts) {
          if (rp.didExceedMaxLines) {
            final textStr = rp.text.toPlainText();
            fail(
              '[$screenName - $scaleLabel] 文字列が領域を超えて文字切れ・省略されています: "$textStr"',
            );
          }
        }
      }
    }

    // =========================================================================
    // 1. 全主要画面（Pages）の文字拡大テスト
    // =========================================================================
    testWidgets('1-1. スタート画面 (StartScreen): 全文字サイズで文字切れ・例外ゼロ', (tester) async {
      await testWidgetWithTextScalers(
        tester: tester,
        widget: const StartScreen(),
        screenName: 'StartScreen',
      );
    });

    testWidgets('1-2. 権限選択画面 (RoleSelectScreen): 全文字サイズで文字切れ・例外ゼロ', (
      tester,
    ) async {
      await testWidgetWithTextScalers(
        tester: tester,
        widget: const RoleSelectScreen(),
        screenName: 'RoleSelectScreen',
      );
    });

    testWidgets('1-3. PIN認証画面 (PinAuthScreen): 全文字サイズで文字切れ・例外ゼロ', (
      tester,
    ) async {
      await testWidgetWithTextScalers(
        tester: tester,
        widget: const PinAuthScreen(role: UserRole.operator),
        screenName: 'PinAuthScreen',
      );
    });

    testWidgets('1-4. 設定画面 (SettingsScreen): 全文字サイズで文字切れ・例外ゼロ', (tester) async {
      await testWidgetWithTextScalers(
        tester: tester,
        widget: const SettingsScreen(),
        screenName: 'SettingsScreen',
      );
    });

    testWidgets('1-5. 大会一覧画面 (TournamentListScreen): 全文字サイズで文字切れ・例外ゼロ', (
      tester,
    ) async {
      await testWidgetWithTextScalers(
        tester: tester,
        widget: const TournamentListScreen(isArchive: false),
        screenName: 'TournamentListScreen',
      );
    });

    testWidgets('1-6. 大会ホーム画面 (HomeScreen): 全文字サイズで文字切れ・例外ゼロ', (tester) async {
      await testWidgetWithTextScalers(
        tester: tester,
        widget: const HomeScreen(tournamentId: 'test_tourney_id'),
        screenName: 'HomeScreen',
      );
    });

    testWidgets('1-7. 部内戦ホーム画面 (BunaiksenHomeScreen): 全文字サイズで文字切れ・例外ゼロ', (
      tester,
    ) async {
      await testWidgetWithTextScalers(
        tester: tester,
        widget: const BunaiksenHomeScreen(),
        screenName: 'BunaiksenHomeScreen',
      );
    });

    testWidgets('1-8. 観客ホーム画面 (ViewerHomeScreen): 全文字サイズで文字切れ・例外ゼロ', (
      tester,
    ) async {
      await testWidgetWithTextScalers(
        tester: tester,
        widget: const ViewerHomeScreen(tournamentId: 'test_tourney_id'),
        screenName: 'ViewerHomeScreen',
      );
    });

    testWidgets(
      '1-9. 観客用部内戦ホーム (ViewerBunaiksenHomeScreen): 全文字サイズで文字切れ・例外ゼロ',
      (tester) async {
        await testWidgetWithTextScalers(
          tester: tester,
          widget: const ViewerBunaiksenHomeScreen(
            tournamentId: 'test_tourney_id',
          ),
          screenName: 'ViewerBunaiksenHomeScreen',
        );
      },
    );

    testWidgets('1-10. 新規試合作成画面 (NewMatchScreen): 全文字サイズで文字切れ・例外ゼロ', (
      tester,
    ) async {
      await testWidgetWithTextScalers(
        tester: tester,
        widget: const NewMatchScreen(tournamentId: 'test_tourney_id'),
        screenName: 'NewMatchScreen',
      );
    });

    testWidgets('1-11. 試合形式設定画面 (SetupMatchFormatScreen): 全文字サイズで文字切れ・例外ゼロ', (
      tester,
    ) async {
      await testWidgetWithTextScalers(
        tester: tester,
        widget: const SetupMatchFormatScreen(tournamentId: 'test_tourney_id'),
        screenName: 'SetupMatchFormatScreen',
      );
    });

    testWidgets('1-12. 部門ルール画面 (CategoryRulesScreen): 全文字サイズで文字切れ・例外ゼロ', (
      tester,
    ) async {
      await testWidgetWithTextScalers(
        tester: tester,
        widget: const CategoryRulesScreen(tournamentId: 'test_tourney_id'),
        screenName: 'CategoryRulesScreen',
      );
    });

    testWidgets('1-13. マスター管理画面 (MasterManagementScreen): 全文字サイズで文字切れ・例外ゼロ', (
      tester,
    ) async {
      await testWidgetWithTextScalers(
        tester: tester,
        widget: const MasterManagementScreen(),
        screenName: 'MasterManagementScreen',
      );
    });

    // =========================================================================
    // 2. ボトムシート・ドック・重要コンポーネントの文字拡大テスト
    // =========================================================================
    testWidgets(
      '2-1. ドックボトムシートヘッダー (DockBottomSheetHeader): 特大時もボタン押し出し・文字切れゼロ',
      (tester) async {
        await testWidgetWithTextScalers(
          tester: tester,
          widget: const DockBottomSheetHeader(
            title: '大会プログラム・部内戦詳細成績カルテ',
            icon: Icons.menu_book_rounded,
          ),
          screenName: 'DockBottomSheetHeader',
        );
      },
    );

    testWidgets(
      '2-2. AppBar標準ヘッダー (AppHeader): 長文タイトルでもFittedBoxで綺麗に収まり文字切れゼロ',
      (tester) async {
        await testWidgetWithTextScalers(
          tester: tester,
          widget: const AppHeader(title: '2026/09/24 過去の大会 (西日本選抜少年剣道大会アーカイブ)'),
          screenName: 'AppHeader',
        );
      },
    );

    testWidgets('2-3. 試合チームヘッダー行 (MatchTeamHeaderRow): 左右長文チーム名でも重ならず全文表示', (
      tester,
    ) async {
      await testWidgetWithTextScalers(
        tester: tester,
        widget: const MatchTeamHeaderRow(
          redTeam: '岡山県代表 備前少年剣道道場連合会',
          whiteTeam: '広島県代表 広島南剣道親善クラブ',
          textColor: Colors.black,
        ),
        screenName: 'MatchTeamHeaderRow',
      );
    });

    testWidgets(
      '2-4. 試合選手・スコア行 (MatchPlayersScoreRow): 左右長文選手名でもスコアと干渉せず全文表示',
      (tester) async {
        await testWidgetWithTextScalers(
          tester: tester,
          widget: const MatchPlayersScoreRow(
            redName: '岡山備前: 長谷川健太郎',
            whiteName: '広島南: 佐々木小次郎',
            isRedOwn: true,
            isWhiteOwn: false,
            redPoints: [],
            whitePoints: [],
            isDraw: false,
            textColor: Colors.black,
            subTextColor: Colors.grey,
          ),
          screenName: 'MatchPlayersScoreRow',
        );
      },
    );

    testWidgets(
      '2-5. 大会情報ヘッダー (TournamentHeaderCard): 長文会場名でもFittedBoxで綺麗に全文収まる',
      (tester) async {
        await testWidgetWithTextScalers(
          tester: tester,
          widget: TournamentHeaderCard(tournament: mockTournament),
          screenName: 'TournamentHeaderCard',
        );
      },
    );

    testWidgets(
      '2-6. 対戦履歴カードリスト (ExpeditionCardResultList): 長文試合場・進行見出しでも全文表示',
      (tester) async {
        await testWidgetWithTextScalers(
          tester: tester,
          widget: ExpeditionCardResultList(
            cardResults: [
              ExpeditionCardResult(
                cardTitle: '第7試合場, 4回戦, 第23試合目 (予選トーナメント)',
                opponentTeamName: '倉敷少年剣道クラブ旭東中学校',
                myWins: 3,
                myPoints: 5,
                oppWins: 1,
                oppPoints: 2,
                isWin: true,
                isDraw: false,
                resultType: 'team',
                scene: '1回戦',
              ),
            ],
            isDark: false,
          ),
          screenName: 'ExpeditionCardResultList',
        );
      },
    );

    testWidgets('2-7. 試合編集シート (MatchEditSheet): タブ「コート・メモ」等全文字サイズで文字切れゼロ', (
      tester,
    ) async {
      await testWidgetWithTextScalers(
        tester: tester,
        widget: MatchEditSheet(
          matches: mockMatches,
          tournamentId: 'test_tourney_id',
          themeColors: AppThemeColors.ofMode(isDark: false, mode: 'normal'),
        ),
        screenName: 'MatchEditSheet',
      );
    });

    testWidgets(
      '2-8. コート計算機形式選択 (MatchCalculatorFormatSelector): 「複数リーグ総当たり」等ボタン文字切れゼロ',
      (tester) async {
        final notifier = MatchCalculatorNotifier();
        await testWidgetWithTextScalers(
          tester: tester,
          widget: MatchCalculatorFormatSelector(
            settings: notifier.state.settings,
            notifier: notifier,
          ),
          screenName: 'MatchCalculatorFormatSelector',
        );
      },
    );

    testWidgets('2-9. 観客用表示設定シート (ViewerSettingsBottomSheet): 全設定タイルで文字切れゼロ', (
      tester,
    ) async {
      await testWidgetWithTextScalers(
        tester: tester,
        widget: const ViewerSettingsBottomSheet(),
        screenName: 'ViewerSettingsBottomSheet',
      );
    });
  });
}
