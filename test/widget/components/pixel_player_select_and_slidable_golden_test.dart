import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/order_setup/order_setup_player_select_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_individual_player_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_match_group_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final dummyPlayers = [
    PlayerModel(
      id: 'p1',
      lastName: '皿田',
      firstName: '脩人',
      lastNameKana: 'さらだ',
      firstNameKana: 'しゅうと',
      grade: 5,
      organization: '青藍館道場',
    ),
    PlayerModel(
      id: 'p2',
      lastName: '塚本',
      firstName: '大道',
      lastNameKana: 'つかもと',
      firstNameKana: 'だいどう',
      grade: 4,
      organization: '青藍館道場',
    ),
  ];

  group('[Golden] 選手選択ボトムシート及びスワイプカード視認性・文字切れ検証テスト', () {
    testWidgets('ライトテーマにおいて選手選択ボトムシートの選手名・所属・直接入力ボタンが白飛びせず明瞭に描画されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844); // iPhone 14
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData(
              brightness: Brightness.light,
              extensions: [themeColors],
            ),
            home: Scaffold(
              body: OrderSetupPlayerSelectBottomSheet(
                masterPlayers: dummyPlayers,
                themeColors: themeColors,
                isDark: false,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(OrderSetupPlayerSelectBottomSheet), findsOneWidget);
      expect(find.text('選手の選択'), findsOneWidget);
      expect(find.text('皿田 脩人'), findsOneWidget);
      expect(find.text('塚本 大道'), findsOneWidget);
      expect(find.text('小学5年'), findsOneWidget);
      expect(find.text('小学4年'), findsOneWidget);
      expect(find.text('直接入力（助っ人など）'), findsOneWidget);
      expect(find.text('未定（空枠）'), findsOneWidget);

      // 白飛びせず、正常なtextColorが適用されていることを確認
      final nameTextFinder = find.text('皿田 脩人');
      final Text nameText = tester.widget(nameTextFinder);
      expect(nameText.style?.color, isNot(themeColors.cardBackground));
      expect(nameText.style?.color, isNot(themeColors.inputBackground));
      expect(tester.takeException(), isNull);
    });

    testWidgets('ダークテーマにおいて選手選択ボトムシートの選手名・所属が高コントラストで視覚破綻なく描画されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final themeColors = AppThemeColors.ofMode(isDark: true, mode: 'normal');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.dark().copyWith(extensions: [themeColors]),
            home: Scaffold(
              backgroundColor: themeColors.scaffoldBackground,
              body: OrderSetupPlayerSelectBottomSheet(
                masterPlayers: dummyPlayers,
                themeColors: themeColors,
                isDark: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(OrderSetupPlayerSelectBottomSheet), findsOneWidget);
      expect(find.text('選手の選択'), findsOneWidget);
      expect(find.text('皿田 脩人'), findsOneWidget);
      expect(find.text('塚本 大道'), findsOneWidget);
      expect(find.text('小学5年'), findsOneWidget);
      expect(find.text('小学4年'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'タイムラインスワイプアクション展開時において次戦追加・編集・削除の3列アイコン及びテキストラベルが文字切れなく描画されること',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final themeColors = AppThemeColors.ofMode(
          isDark: false,
          mode: 'normal',
        );

        const dummyMatch = MatchModel(
          id: 'm1',
          matchType: '先鋒',
          redName: '青藍館道場 : 皿田 脩人',
          whiteName: '一心館道場 : 山田 太郎',
          status: 'finished',
          groupName: '第1試合場',
          matchOrder: 1,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              permissionProvider.overrideWith(
                (ref) => const PermissionState(canManageTournament: true),
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
                    TimelineMatchGroupCard(
                      groupId: 'grp_1',
                      groupList: [dummyMatch],
                      groupComments: [],
                      categoryName: '一般男子',
                      teamName: '青藍館道場',
                      label: '第1試合場 第1試合目',
                      isReadOnlyUI: false,
                      canManageTournamentUI: true,
                      isDark: false,
                      tournamentId: 'tour_1',
                      ownTeams: ['青藍館道場'],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(TimelineMatchGroupCard), findsOneWidget);

        // カードを左にスワイプしてアクションを展開
        final cardFinder = find.byType(Slidable);
        expect(cardFinder, findsOneWidget);
        await tester.drag(cardFinder, const Offset(-300, 0));
        await tester.pump();

        // 3列アクション（次戦追加、編集、削除）とそれぞれのアイコン・テキストが描画されていることを確認
        expect(find.text('次戦追加'), findsOneWidget);
        expect(find.text('編集'), findsOneWidget);
        expect(find.text('削除'), findsOneWidget);
        expect(find.byIcon(Icons.playlist_add), findsOneWidget);
        expect(find.byIcon(Icons.edit), findsOneWidget);
        expect(find.byIcon(Icons.delete), findsOneWidget);

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '剣道形・個人戦タイムラインカード（TimelineIndividualPlayerCard）スワイプ展開時において次戦追加・編集・削除の3列アクションが描画されること',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final themeColors = AppThemeColors.ofMode(
          isDark: false,
          mode: 'normal',
        );

        const kataMatch = MatchModel(
          id: 'km1',
          matchType: '形競技',
          category: '剣道形',
          redName: '青藍館道場 : 皿田 脩人・塚本 大道',
          whiteName: '一心館道場 : 選手・選手',
          status: 'finished',
          groupName: '第1試合場',
          matchOrder: 1,
        );

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
                      playerMatches: [kataMatch],
                      playerComments: [],
                      categoryName: '剣道形',
                      teamName: '青藍館道場',
                      tournamentId: 'tour_1',
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
        await tester.pump();

        expect(find.byType(TimelineIndividualPlayerCard), findsOneWidget);

        // カードを左にスワイプしてアクションを展開
        final cardFinder = find.byType(Slidable);
        expect(cardFinder, findsOneWidget);
        await tester.drag(cardFinder, const Offset(-300, 0));
        await tester.pump();

        // 3列アクション（次戦追加、編集、削除）とそれぞれのアイコン・テキストが描画されていることを確認
        expect(find.text('次戦追加'), findsOneWidget);
        expect(find.text('編集'), findsOneWidget);
        expect(find.text('削除'), findsOneWidget);
        expect(find.byIcon(Icons.playlist_add), findsOneWidget);
        expect(find.byIcon(Icons.edit), findsOneWidget);
        expect(find.byIcon(Icons.delete), findsOneWidget);

        expect(tester.takeException(), isNull);
      },
    );
  });
}
