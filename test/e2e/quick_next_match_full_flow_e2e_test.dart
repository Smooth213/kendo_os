import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_edit_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/quick_next_match/quick_next_match_wizard_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_individual_player_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_match_group_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_screen_providers.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/safe_timeline_provider.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

class MockMatchApplicationService extends Mock
    implements MatchApplicationService {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const MatchModel(
        id: 'fallback_id',
        matchType: '先鋒',
        redName: 'red',
        whiteName: 'white',
      ),
    );
  });

  group('[E2E] スワイプ次戦追加からウィザード（形ペア個別変更・特記事項入力）確定までの完全統合フローテスト', () {
    late MockMatchApplicationService mockMatchService;
    final List<MatchModel> savedMatches = [];

    final dummyPlayers = [
      PlayerModel(
        id: 'p1',
        lastName: '皿田',
        firstName: '脩人',
        lastNameKana: 'さらだ',
        firstNameKana: 'しゅうと',
        grade: 5,
        organization: '道上剣友会',
      ),
      PlayerModel(
        id: 'p2',
        lastName: '塚本',
        firstName: '大道',
        lastNameKana: 'つかもと',
        firstNameKana: 'だいどう',
        grade: 4,
        organization: '道上剣友会',
      ),
      PlayerModel(
        id: 'p3',
        lastName: '佐藤',
        firstName: '健',
        lastNameKana: 'さとう',
        firstNameKana: 'たける',
        grade: 6,
        organization: '道上剣友会',
      ),
    ];

    setUp(() {
      savedMatches.clear();
      mockMatchService = MockMatchApplicationService();
      when(() => mockMatchService.saveMatch(any())).thenAnswer((inv) async {
        savedMatches.add(inv.positionalArguments[0] as MatchModel);
      });
    });

    Widget createIntegrationTestWidget({
      required MatchModel baseMatch,
      List<MatchModel> teamMatches = const [],
    }) {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      return ProviderScope(
        overrides: [
          matchApplicationServiceProvider.overrideWithValue(mockMatchService),
          permissionProvider.overrideWith(
            (ref) => const PermissionState(canManageTournament: true),
          ),
          playerListProvider.overrideWith((ref) => Stream.value(dummyPlayers)),
          customTeamNamesProvider.overrideWith(
            (ref) => Stream.value(['道上剣友会']),
          ),
          registeredTeamsProvider('t1').overrideWith((ref) => Stream.value([])),
        ],
        child: MaterialApp(
          theme: ThemeData(
            brightness: Brightness.light,
            extensions: [themeColors],
          ),
          home: Scaffold(
            body: ListView(
              children: [
                TimelineMatchGroupCard(
                  groupId: 'grp_1',
                  groupList: teamMatches.isNotEmpty ? teamMatches : [baseMatch],
                  groupComments: const [],
                  categoryName: '錬成会',
                  teamName: '道上剣友会',
                  label: '第1試合場 第1試合目',
                  isReadOnlyUI: false,
                  canManageTournamentUI: true,
                  isDark: false,
                  tournamentId: 't1',
                  ownTeams: const ['道上剣友会'],
                ),
              ],
            ),
          ),
        ),
      );
    }

    testWidgets('スワイプから次戦追加ウィザードを起動し、会場・試合順・特記事項・対戦相手を設定して新試合が保存されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const baseMatch = MatchModel(
        id: 'm1',
        tournamentId: 't1',
        category: '小学生団体',
        matchType: '先鋒',
        redName: '道上剣友会 : 皿田 脩人',
        whiteName: '一心館 : 相手選手',
        groupName: '第1試合場',
        matchOrder: 1,
        rule: MatchRule(isRenseikai: true, teamName: '道上剣友会'),
      );

      await tester.pumpWidget(
        createIntegrationTestWidget(
          baseMatch: baseMatch,
          teamMatches: [baseMatch],
        ),
      );
      await tester.pumpAndSettle();

      // 1. スワイプして「次戦追加」を展開・タップ
      final cardFinder = find.byType(Slidable);
      expect(cardFinder, findsOneWidget);
      await tester.drag(cardFinder, const Offset(-300, 0));
      await tester.pumpAndSettle();

      final addNextButton = find.text('次戦追加');
      expect(addNextButton, findsOneWidget);
      await tester.tap(addNextButton);
      await tester.pumpAndSettle();

      // 2. ウィザードが表示される
      expect(find.byType(QuickNextMatchWizardSheet), findsOneWidget);

      // Step 0（オーダー確認）: 「試合詳細の設定へ進む」をタップ
      final toStep1Button = find.text('試合詳細の設定へ進む');
      expect(toStep1Button, findsOneWidget);
      await tester.tap(toStep1Button);
      await tester.pumpAndSettle();

      // Step 1（試合詳細）: 特記事項アコーディオンを展開
      final accordionTile = find.text('＋ 運営メモ・特記事項を追加（任意）');
      expect(accordionTile, findsOneWidget);
      await tester.tap(accordionTile);
      await tester.pumpAndSettle();

      // 特記事項を入力
      final noteField = find.byType(TextField).last;
      await tester.enterText(noteField, '1本勝負・延長あり');
      await tester.pumpAndSettle();

      // 「対戦相手・紅白へ進む」をタップして Step 2 へ進む
      final toStep2Button = find.text('対戦相手・紅白へ進む');
      expect(toStep2Button, findsOneWidget);
      await tester.tap(toStep2Button);
      await tester.pumpAndSettle();

      // Step 2（対戦相手・紅白・確定）
      final confirmButton = find.text('このオーダーで確定して進む');
      expect(confirmButton, findsOneWidget);
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      // 3. 保存が実行されたことを検証
      verify(() => mockMatchService.saveMatch(any())).called(1);
      expect(savedMatches.length, 1);
      expect(savedMatches.first.note, contains('1本勝負・延長あり'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('剣道形モードにおいてペア選手（打太刀・仕太刀）を個別に変更してウィザード確定すると結合文字列として正しく保存されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const kataRule = MatchRule(
        isKataMatch: true,
        isRenseikai: true,
        teamName: '道上剣友会',
      );

      const baseMatch = MatchModel(
        id: 'm_kata_1',
        tournamentId: 't1',
        category: '剣道形',
        matchType: '形競技',
        redName: '道上剣友会 : 皿田 脩人・塚本 大道',
        whiteName: '相手道場 : 打太刀相手・仕太刀相手',
        groupName: '第1試合場',
        matchOrder: 1,
        rule: kataRule,
      );

      await tester.pumpWidget(
        createIntegrationTestWidget(
          baseMatch: baseMatch,
          teamMatches: [baseMatch],
        ),
      );
      await tester.pumpAndSettle();

      // スワイプして「次戦追加」タップ
      final cardFinder = find.byType(Slidable);
      await tester.drag(cardFinder, const Offset(-300, 0));
      await tester.pumpAndSettle();

      await tester.tap(find.text('次戦追加'));
      await tester.pumpAndSettle();

      // Step 0: 形ペアスロットの確認（オーダー編成画面準拠の2スロット）
      expect(find.text('皿田 脩人'), findsOneWidget);
      expect(find.text('塚本 大道'), findsOneWidget);

      // 2人目（仕太刀側スロット）の「変更」ボタンをタップして選手選択ボトムシートを開く
      final changeButtons = find.text('変更');
      expect(changeButtons, findsNWidgets(2));
      await tester.tap(changeButtons.at(1)); // 2人目スロット
      await tester.pumpAndSettle();

      // 選手選択ボトムシートで「佐藤 健」を選択
      expect(find.text('選手の選択'), findsOneWidget);
      final playerTile = find.text('佐藤 健');
      expect(playerTile, findsOneWidget);
      await tester.tap(playerTile);
      await tester.pumpAndSettle();

      // 仕太刀が「佐藤 健」に変更されたことを確認
      expect(find.text('佐藤 健'), findsOneWidget);

      // Step 0 ➔ Step 1
      await tester.tap(find.text('試合詳細の設定へ進む'));
      await tester.pumpAndSettle();

      // Step 1 ➔ Step 2
      await tester.tap(find.text('対戦相手・紅白へ進む'));
      await tester.pumpAndSettle();

      // Step 2 ➔ 確定
      final confirmButton = find.text('このオーダーで確定して進む');
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      // 保存された試合の選手名が「皿田 脩人・佐藤 健」と結合されていることを検証
      verify(() => mockMatchService.saveMatch(any())).called(1);
      expect(savedMatches.length, 1);
      expect(savedMatches.first.redName, contains('皿田 脩人・佐藤 健'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('剣道形アコーディオンカードをスワイプして編集をタップした際、MatchEditSheetが開き試合編集ができること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const kataRule = MatchRule(
        isKataMatch: true,
        isRenseikai: true,
        teamName: '道上剣友会',
      );

      const baseMatch = MatchModel(
        id: 'm_edit_1',
        tournamentId: 't1',
        category: '剣道形',
        matchType: '形競技',
        redName: '道上剣友会 : 皿田 脩人・塚本 大道',
        whiteName: '相手道場 : 打太刀相手・仕太刀相手',
        groupName: '第1試合場',
        matchOrder: 1,
        rule: kataRule,
      );

      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'operate');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            permissionProvider.overrideWith(
              (ref) => const PermissionState(
                canManageTournament: true,
                canDeleteData: true,
              ),
            ),
          ],
          child: MaterialApp(
            theme: ThemeData(
              brightness: Brightness.light,
              extensions: [themeColors],
            ),
            home: Scaffold(
              body: ListView(
                children: const [
                  TimelineIndividualPlayerCard(
                    playerName: '皿田 脩人・塚本 大道',
                    playerMatches: [baseMatch],
                    playerComments: [],
                    categoryName: '剣道形',
                    teamName: '道上剣友会',
                    tournamentId: 't1',
                    isReadOnlyUI: false,
                    isDark: false,
                    permissions: PermissionState(
                      canManageTournament: true,
                      canDeleteData: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // カードを左にスワイプ
      final cardFinder = find.byType(Slidable);
      expect(cardFinder, findsOneWidget);
      await tester.drag(cardFinder, const Offset(-300, 0));
      await tester.pumpAndSettle();

      // 「編集」アクションが表示されていることを確認
      final editButton = find.text('編集');
      expect(editButton, findsOneWidget);

      // 「編集」をタップ
      await tester.tap(editButton);
      await tester.pumpAndSettle();

      // MatchEditSheet がモーダルとして開いていることを検証
      expect(find.byType(MatchEditSheet), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
