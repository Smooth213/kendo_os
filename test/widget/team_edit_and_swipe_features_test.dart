import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/domain/share_import/tournament_team_auto_register_service.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_team_selection_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_edit_basic_fields.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_edit_order_list.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_player_select_bottom_sheet.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

  group('🥋 チーム編集・スワイプ操作・UI改善のテスト', () {
    // 1. 【添付ファイル１＆４対応】スワイプ編集・削除とオーダー調整ボタン削除
    testWidgets(
      'MatchFormatTeamSelectionCard: スワイプで編集・削除ボタンが表示され、「オーダーを調整」ボタンは存在しない',
      (tester) async {
        final team = TeamModel(
          id: 'team1',
          tournamentId: 't1',
          teamName: '洗心道場 A',
          category: '小学生',
          matchType: '団体戦（5人制）',
          playerNames: ['先鋒', '次鋒', '中堅', '副将', '大将'],
        );

        bool editCalled = false;
        bool deleteCalled = false;
        bool selectCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MatchFormatTeamSelectionCard(
                team: team,
                isSelected: true,
                themeColors: themeColors,
                textColor: Colors.black,
                isDark: false,
                onSelect: () => selectCalled = true,
                onEdit: () => editCalled = true,
                onDelete: () => deleteCalled = true,
              ),
            ),
          ),
        );

        // 添付ファイル４: カード選択時でも「オーダーを調整」ボタンは削除されていること
        expect(find.text('オーダーを調整'), findsNothing);
        expect(find.text('洗心道場 A'), findsOneWidget);

        // カードタップで onSelect が呼ばれること
        await tester.tap(find.text('洗心道場 A'));
        await tester.pump();
        expect(selectCalled, isTrue);

        // 添付ファイル１: スワイプ操作で「編集」「削除」アクションが出現
        await tester.drag(find.text('洗心道場 A'), const Offset(-300, 0));
        await tester.pumpAndSettle();

        expect(find.text('編集'), findsOneWidget);
        expect(find.text('削除'), findsOneWidget);

        // 「編集」アクションの背景色が大会ホームと統一された blueAccent であること
        final editAction = tester.widget<SlidableAction>(
          find.widgetWithText(SlidableAction, '編集'),
        );
        expect(editAction.backgroundColor, equals(AppKendoColors.blueAccent));

        // 編集ボタンタップで onEdit が呼ばれること
        await tester.tap(find.text('編集'));
        await tester.pump();
        expect(editCalled, isTrue);

        // 削除ボタンタップで onDelete が呼ばれること
        await tester.tap(find.text('削除'));
        await tester.pump();
        expect(deleteCalled, isTrue);
      },
    );

    // 2. 【添付ファイル２対応】「の部」が除外されてコンパクトに表示されること
    testWidgets('TeamEditBasicFields: 所属部門チップから「の部」が無くコンパクトに表示される', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'テストチーム');
      String selectedCat = '小学生低学年';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TeamEditBasicFields(
              teamNameController: controller,
              selectedCategory: selectedCat,
              matchType: '団体戦（5人制）',
              candidateCategories: const [
                '小学生低学年の部',
                '小学生高学年の部',
                '中学生の部',
                '高校生の部',
                '一般の部',
              ],
              matchTypes: const ['団体戦（5人制）', '個人戦'],
              themeColors: themeColors,
              borderColor: Colors.grey,
              onCategoryChanged: (cat) => selectedCat = cat,
              onMatchTypeChanged: (_) {},
            ),
          ),
        ),
      );

      // 「の部」が付いたテキストは表示されず、「の部」なしでコンパクトに表示されていること
      expect(find.text('小学生低学年'), findsOneWidget);
      expect(find.text('小学生高学年'), findsOneWidget);
      expect(find.text('中学生'), findsOneWidget);
      expect(find.text('小学生低学年の部'), findsNothing);
      expect(find.text('中学生の部'), findsNothing);

      // チップタップで onCategoryChanged が呼ばれること
      await tester.tap(find.text('中学生'));
      await tester.pump();
      expect(selectedCat, equals('中学生の部'));
    });

    // 3. 【添付ファイル３対応】オーダーリストから「✕」と「＞」が削除され、ドラッグハンドルが表示されること
    testWidgets('TeamEditOrderList: 各行の✕ボタンや＞シェブロンが削除され、ドラッグハンドルが表示される', (
      tester,
    ) async {
      bool selectCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TeamEditOrderList(
              totalCount: 3,
              baseCount: 3,
              posNames: const ['先鋒', '中堅', '大将'],
              tempSelectedPlayers: const {0: '山田 太郎', 1: '佐藤 次郎'},
              slotKeys: const ['slot_1', 'slot_2', 'slot_3'],
              themeColors: themeColors,
              borderColor: Colors.grey,
              inputBgColor: Colors.white,
              onSelectPlayer: (idx) => selectCalled = true,
              onRemoveSubstitute: (_) {},
              onReorder: (oldIdx, newIdx) {},
            ),
          ),
        ),
      );

      // 選手が設定されていても、行右端の「✕（クリア）」ボタンは削除されていること
      expect(find.byIcon(Icons.clear), findsNothing);

      // レギュラー行の「＞（シェブロン）」アイコンも削除されていること
      expect(find.byIcon(Icons.chevron_right), findsNothing);

      // 各行にドラッグハンドルが表示されていること
      expect(find.byIcon(Icons.drag_handle), findsNWidgets(3));

      // 行タップで onSelectPlayer が呼ばれること
      await tester.tap(find.text('山田 太郎'));
      await tester.pump();
      expect(selectCalled, isTrue);
    });

    // 4. 選手選択ボトムシート: リアルタイム絞り込み・同カテゴリ優先・助っ人即時登録
    testWidgets(
      'TeamRegistrationPlayerSelectBottomSheet: リアルタイム絞り込みと同カテゴリ優先、助っ人即時登録',
      (tester) async {
        final pLow = PlayerModel(
          id: 'p1',
          lastName: '低学年',
          firstName: '選手',
          lastNameKana: 'テイガクネン',
          firstNameKana: 'センシュ',
          grade: 3, // 小学生低学年
          isBeginner: false,
        );
        final pHigh = PlayerModel(
          id: 'p2',
          lastName: '高学年',
          firstName: '選手',
          lastNameKana: 'コウガクネン',
          firstNameKana: 'センシュ',
          grade: 6, // 小学生高学年
          isBeginner: false,
        );

        String? selectedResult;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    selectedResult =
                        await TeamRegistrationPlayerSelectBottomSheet.show(
                          context: context,
                          index: 0,
                          players: [pLow, pHigh],
                          posNames: ['先鋒', '中堅', '大将'],
                          tempSelectedPlayers: {},
                          selectedMajorCategory: '小学生',
                          selectedMinorCategory: '低学年',
                          themeColors: themeColors,
                        );
                  },
                  child: const Text('選手選択を開く'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('選手選択を開く'));
        await tester.pumpAndSettle();

        // 1. 同カテゴリ（低学年）が「おすすめの選手」として表示されること
        expect(find.text('おすすめの選手（同カテゴリ）'), findsOneWidget);
        expect(find.text('低学年 選手'), findsOneWidget);
        expect(find.text('その他の所属選手'), findsOneWidget);
        expect(find.text('高学年 選手'), findsOneWidget);

        // 2. 助っ人名を入力すると「助っ人として登録」カードが最上部に現れること
        final searchField = find.byType(TextField);
        await tester.enterText(searchField, '助っ人 太郎');
        await tester.pump();

        expect(find.text('助っ人として「助っ人 太郎」を登録'), findsOneWidget);

        // 3. 助っ人カードをタップするとその名前が返却されてシートが閉じること
        await tester.tap(find.text('助っ人として「助っ人 太郎」を登録'));
        await tester.pumpAndSettle();

        expect(selectedResult, equals('助っ人 太郎'));
      },
    );

    // 5. TeamEditBasicFields: 勝ち抜き戦やリーグ戦を含む全試合形式が表示され選択可能であること
    testWidgets('TeamEditBasicFields: 勝ち抜き戦やリーグ戦を含む全試合形式が表示され選択可能であること', (
      tester,
    ) async {
      final controller = TextEditingController(text: '道上剣友会A');
      String selectedType = '団体戦（3人制）';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TeamEditBasicFields(
              teamNameController: controller,
              selectedCategory: '小学生',
              matchType: selectedType,
              candidateCategories: const ['小学生'],
              matchTypes: TournamentTeamAutoRegisterService.candidateMatchTypes,
              themeColors: themeColors,
              borderColor: Colors.grey,
              onCategoryChanged: (_) {},
              onMatchTypeChanged: (type) => selectedType = type,
            ),
          ),
        ),
      );

      // 試合形式チップの確認
      expect(find.text('勝ち抜き戦'), findsOneWidget);
      expect(find.text('リーグ団体戦'), findsOneWidget);
      expect(find.text('リーグ個人戦'), findsOneWidget);
      expect(find.text('団体戦（5人制）'), findsOneWidget);
      expect(find.text('団体戦（3人制）'), findsOneWidget);
      expect(find.text('団体戦（7人制）'), findsOneWidget);
      expect(find.text('個人戦'), findsOneWidget);
      expect(find.text('団体戦（それ以上）'), findsOneWidget);

      // 「勝ち抜き戦」をタップ
      await tester.tap(find.text('勝ち抜き戦'));
      await tester.pump();
      expect(selectedType, equals('勝ち抜き戦'));

      // 「リーグ団体戦」をタップ
      await tester.tap(find.text('リーグ団体戦'));
      await tester.pump();
      expect(selectedType, equals('リーグ団体戦'));
    });
  });
}
