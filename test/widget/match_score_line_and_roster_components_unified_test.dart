import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_score_line.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_operate_action_buttons_grid.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_player_roster_list_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_player_selection_card.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/match_tables/point_mark_badge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Widget] MatchScoreLineAndRosterComponents 統合テスト', () {
    testWidgets('得点なしおよび引き分けでない場合に空白で正しく描画されること', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MatchScoreLine(
              redPoints: [],
              whitePoints: [],
              isDraw: false,
              redColor: Colors.red,
              whiteTextColor: Colors.white,
              dividerTextColor: Colors.grey,
            ),
          ),
        ),
      );

      expect(find.text('ー'), findsNothing);
      expect(find.text('×'), findsNothing);
    });

    testWidgets('スコアマークとダッシュ区切り線が正しく描画されること', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MatchScoreLine(
              redPoints: [PointMark(mark: 'メ', isFirst: true)],
              whitePoints: [PointMark(mark: 'コ', isFirst: false)],
              isDraw: false,
              redColor: Colors.red,
              whiteTextColor: Colors.white,
              dividerTextColor: Colors.grey,
            ),
          ),
        ),
      );

      expect(find.text('メ'), findsOneWidget);
      expect(find.text('コ'), findsOneWidget);
      expect(find.text('ー'), findsOneWidget);
      expect(find.text('×'), findsNothing);
    });

    testWidgets('スコア0-0の終了済みにおいて引き分けマーク（×）が正しく描画されること', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MatchScoreLine(
              redPoints: [],
              whitePoints: [],
              isDraw: true,
              redColor: Colors.red,
              whiteTextColor: Colors.white,
              dividerTextColor: Colors.grey,
            ),
          ),
        ),
      );

      expect(find.text('×'), findsOneWidget);
      expect(find.text('ー'), findsNothing);
    });

    testWidgets('選手選択カードに補員選手が正しく描画されること', (tester) async {
      final player = PlayerModel(
        id: 'p1',
        lastName: '高橋',
        firstName: '健太',
        lastNameKana: 'たかはし',
        firstNameKana: 'けんた',
        grade: 5,
        organization: 'A道場',
      );

      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchPlayerSelectionCard(
              player: player,
              isSub: true,
              isCurrentPosition: false,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('高橋 健太'), findsOneWidget);
      await tester.tap(find.text('高橋 健太'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('MatchPlayerRosterListSectionにおいて 出場選手および補欠選手が正しく表示されること', (
      tester,
    ) async {
      final p1 = PlayerModel(
        id: 'p1',
        lastName: '田中',
        firstName: '太郎',
        lastNameKana: '',
        firstNameKana: '',
        grade: 5,
      );
      final p2 = PlayerModel(
        id: 'p2',
        lastName: '佐藤',
        firstName: '次郎',
        lastNameKana: '',
        firstNameKana: '',
        grade: 5,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchPlayerRosterListSection(
              sameCatActive: [p1],
              dojoListSubstitutes: [p2],
              otherCategoryPlayers: const [],
              activePlayerNames: {'田中 太郎'},
              playerPositions: {'田中 太郎': '先鋒'},
              currentPlayerName: '田中 太郎',
              onPlayerSelected: (player, isSub) {},
            ),
          ),
        ),
      );

      expect(find.text('田中 太郎'), findsOneWidget);
      expect(find.text('佐藤 次郎'), findsOneWidget);
      expect(find.text('出場中の選手 (交代・スワップ)'), findsOneWidget);
      expect(find.text('同カテゴリの控え選手'), findsOneWidget);
    });

    testWidgets('全4ボタン一覧が表示されコールバックが正常に実行されること', (WidgetTester tester) async {
      bool shareClicked = false;
      bool restoreClicked = false;
      bool checkScoreClicked = false;
      bool checkRuleClicked = false;

      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [themeColors]),
          home: Scaffold(
            body: MatchOperateActionButtonsGrid(
              isViewOnly: false,
              isKachinuki: false,
              onShareUrl: () {
                shareClicked = true;
              },
              onRestoreHistory: () {
                restoreClicked = true;
              },
              onCheckScore: () {
                checkScoreClicked = true;
              },
              onCheckRule: () {
                checkRuleClicked = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('観戦URLを共有'), findsOneWidget);
      expect(find.text('履歴から復元'), findsOneWidget);
      expect(find.text('スコアを確認'), findsOneWidget);
      expect(find.text('ルールを確認'), findsOneWidget);

      await tester.tap(find.text('観戦URLを共有'));
      await tester.pump();
      expect(shareClicked, isTrue);

      await tester.tap(find.text('履歴から復元'));
      await tester.pump();
      expect(restoreClicked, isTrue);

      await tester.tap(find.text('スコアを確認'));
      await tester.pump();
      expect(checkScoreClicked, isTrue);

      await tester.tap(find.text('ルールを確認'));
      await tester.pump();
      expect(checkRuleClicked, isTrue);
    });

    testWidgets('閲覧専用モード時は復元ボタンが無効化されること', (WidgetTester tester) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [themeColors]),
          home: Scaffold(
            body: MatchOperateActionButtonsGrid(
              isViewOnly: true,
              isKachinuki: true,
              onShareUrl: () {},
              onRestoreHistory: null,
              onCheckScore: () {},
              onCheckRule: () {},
            ),
          ),
        ),
      );

      final button = tester.widget<OutlinedButton>(
        find.ancestor(
          of: find.text('履歴から復元'),
          matching: find.byType(OutlinedButton),
        ),
      );
      expect(button.onPressed, isNull);
    });
  });
}
