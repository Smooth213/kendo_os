import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/safe_pump_helper.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/order_setup/order_setup_base_order_actions_bar.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/order_setup/order_setup_league_participants_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/order_setup/order_setup_match_generator.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/order_setup/order_setup_matchup_config_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/order_setup/order_setup_player_select_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/order_setup/order_setup_position_slot.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/order_setup/order_setup_reorderable_slots_view.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/order_setup/order_setup_sticky_bottom_bar.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/order_setup/order_setup_team_autocomplete_field.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Widget] オーダー設定 コンポーネント・セクション統合検証テスト', () {
    testWidgets('OrderSetupBaseOrderActionsBarにおいて 保存および読込のコールバックが正常に動作すること', (
      tester,
    ) async {
      bool saved = false;
      bool loaded = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OrderSetupBaseOrderActionsBar(
              themeColors: AppThemeColors.ofMode(isDark: false, mode: 'normal'),
              isDark: false,
              canLoadBaseOrder: true,
              onSaveBaseOrder: () => saved = true,
              onLoadBaseOrder: () => loaded = true,
            ),
          ),
        ),
      );

      expect(find.text('基本オーダーに登録'), findsOneWidget);
      expect(find.text('基本オーダーを呼出'), findsOneWidget);

      await tester.tap(find.text('基本オーダーに登録'));
      expect(saved, isTrue);

      await tester.tap(find.text('基本オーダーを呼出'));
      expect(loaded, isTrue);
    });

    test('OrderSetupMatchGeneratorにより試合が正しく生成されること', () {
      const rule = MatchRule(
        teamName: '先鋒道場',
        category: '一般男子',
        positions: ['先鋒', '中堅', '大将'],
        baseOrder: ['山田', '佐藤', '鈴木'],
      );

      final matches = OrderSetupMatchGenerator.generateMatches(
        tournamentId: 't1',
        rule: rule,
        positions: const ['先鋒', '中堅', '大将'],
        selectedPlayers: {0: '山田', 1: '佐藤', 2: '鈴木'},
        opponentPlayers: {0: '田中', 1: '高橋', 2: '渡辺'},
        opponentTeamInput: '相手道場',
        isOwnTeamRed: true,
        leagueParticipants: const [],
        leagueTeamOrders: const {},
        matchType: 'team',
        isStartNow: false,
        baseOrder: 1000.0,
      );

      expect(matches.length, equals(3));
      expect(matches[0].redName, contains('先鋒道場'));
      expect(matches[0].whiteName, contains('相手道場'));
      expect(matches[0].matchType, equals('先鋒'));
    });

    testWidgets('OrderSetupStickyBottomBarおよびスロット一覧が正しく描画されること', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: OrderSetupStickyBottomBar(
              themeColors: AppThemeColors.ofMode(isDark: false, mode: 'normal'),
              isDark: false,
              enableLiquidGlass: false,
              onAddExtraPosition: () {},
              onConfirmAndProceed: () {},
            ),
            body: OrderSetupReorderableSlotsView(
              positions: const ['先鋒', '大将'],
              selectedPlayers: const {0: '山田', 1: '鈴木'},
              opponentPlayers: const {},
              teamName: '自チーム',
              isLeague: false,
              isDark: false,
              themeColors: AppThemeColors.ofMode(isDark: false, mode: 'normal'),
              masterPlayers: const [],
              onReorder: (_, _) {},
              onSelectPlayerTap: (_) {},
              onOpponentChanged: (_, _) {},
              onVacantPressed: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('イレギュラー枠を追加する（錬成会用）'), findsOneWidget);
      expect(find.text('このオーダーで確定して進む'), findsOneWidget);
      expect(find.textContaining('先鋒'), findsWidgets);
      expect(find.textContaining('大将'), findsWidgets);
      expect(find.text('山田'), findsOneWidget);
      expect(find.text('鈴木'), findsOneWidget);
    });

    testWidgets(
      'OrderSetupLeagueParticipantsSectionにおいて リーグ参加者リストが正しく描画されること',
      (tester) async {
        final participants = ['自チーム', '相手チームA'];
        final teamOrders = <String, List<String>>{
          '自チーム': ['選手1', '選手2'],
        };

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: OrderSetupLeagueParticipantsSection(
                    themeColors: AppThemeColors.ofMode(
                      isDark: false,
                      mode: 'normal',
                    ),
                    leagueParticipants: participants,
                    leagueTeamOrders: teamOrders,
                    positions: const ['先鋒', '中堅', '大将'],
                    ruleTeamName: '自チーム',
                    matchType: '団体戦',
                    opponentTeamSuggestions: const ['相手チームA', '相手チームB'],
                    onParticipantsChanged: () {},
                    isDark: false,
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.text('1. リーグ参加者リストの作成'), findsOneWidget);
        expect(find.text('自チーム'), findsOneWidget);
        expect(find.text('相手チームA'), findsOneWidget);
        expect(find.text('リストに追加'), findsOneWidget);
      },
    );

    testWidgets('OrderSetupMatchupConfigSectionにおいて タスキと相手チーム入力欄が表示されること', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: OrderSetupMatchupConfigSection(
                themeColors: AppThemeColors.ofMode(
                  isDark: false,
                  mode: 'normal',
                ),
                isOwnTeamRed: true,
                onIsOwnTeamRedChanged: (_) {},
                opponentTeamController: TextEditingController(text: '相手剣道クラブ'),
                opponentTeamFocusNode: FocusNode(),
                opponentTeamSuggestions: const ['相手剣道クラブ', 'ライバル高校'],
                isDark: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('自チームの紅白（タスキ）'), findsOneWidget);
      expect(find.text('赤 (左側)'), findsOneWidget);
      expect(find.text('白 (右側)'), findsOneWidget);
      expect(find.text('相手チームの情報を入力'), findsOneWidget);
      expect(find.text('相手剣道クラブ'), findsOneWidget);
    });

    testWidgets('OrderSetupPlayerSelectBottomSheetにおいて 選手一覧から選択できること', (
      tester,
    ) async {
      final testPlayers = [
        PlayerModel(
          id: 'p1',
          lastName: '山田',
          firstName: '太郎',
          lastNameKana: 'ヤマダ',
          firstNameKana: 'タロウ',
          grade: 5,
          isBeginner: false,
        ),
        PlayerModel(
          id: 'p2',
          lastName: '佐藤',
          firstName: '次郎',
          lastNameKana: 'サトウ',
          firstNameKana: 'ジロウ',
          grade: 8,
          isBeginner: false,
        ),
      ];

      String? selectedResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  selectedResult = await OrderSetupPlayerSelectBottomSheet.show(
                    context,
                    masterPlayers: testPlayers,
                    themeColors: AppThemeColors.ofMode(
                      isDark: false,
                      mode: 'normal',
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.safePumpAndSettle();

      expect(find.text('選手の選択'), findsOneWidget);
      expect(find.text('未定（空枠）'), findsOneWidget);
      expect(find.text('山田 太郎'), findsOneWidget);

      await tester.tap(find.text('山田 太郎'));
      await tester.safePumpAndSettle();

      expect(selectedResult, '山田 太郎');
    });

    testWidgets('OrderSetupPositionSlotにおいて 選手名・変更・欠員ボタンが正しく動作すること', (
      tester,
    ) async {
      bool tapped = false;
      bool vacantTapped = false;
      String opponent = '田中 次郎';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: OrderSetupPositionSlot(
                key: const ValueKey('slot_0'),
                index: 0,
                posName: '先鋒',
                playerName: '佐藤 太郎',
                teamName: '東京剣道クラブ',
                isSelected: true,
                onTap: () => tapped = true,
                isDark: false,
                showOpponentField: true,
                opponentPlayerName: opponent,
                onOpponentChanged: (val) => opponent = val,
                onVacantPressed: () => vacantTapped = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('東京剣道クラブ : 先鋒'), findsOneWidget);
      expect(find.text('佐藤 太郎'), findsOneWidget);
      expect(find.text('変更'), findsOneWidget);
      expect(find.text('欠員'), findsOneWidget);

      await tester.tap(find.text('変更'));
      expect(tapped, isTrue);

      await tester.tap(find.text('欠員'));
      expect(vacantTapped, isTrue);
    });

    testWidgets('OrderSetupTeamAutocompleteFieldにおいて 手動入力とサジェスト選択ができること', (
      tester,
    ) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: OrderSetupTeamAutocompleteField(
                controller: controller,
                focusNode: focusNode,
                suggestions: const ['修道館', '養正館', '練兵館'],
                labelText: '赤チーム名',
                hintText: 'チーム名を入力または選択',
                fillColor: Colors.grey.shade100,
                borderColor: Colors.grey,
                textColor: Colors.black,
                subTextColor: Colors.grey.shade600,
                primaryAccent: Colors.blue,
                isDark: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('赤チーム名'), findsOneWidget);
      expect(find.text('チーム名を入力または選択'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '玄武館');
      await tester.pump();

      expect(controller.text, '玄武館');
    });
  });
}
