import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/admin/presentation/components/master_player_edit_bottom_sheet.dart';
import 'package:kendo_os/admin/presentation/components/master_player_gender_selector.dart';
import 'package:kendo_os/admin/presentation/components/master_player_grouping_helper.dart';
import 'package:kendo_os/admin/presentation/components/master_player_tile.dart';
import 'package:kendo_os/admin/presentation/helpers/auto_kana_helper.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Widget] マスター選手管理コンポーネント統合テスト', () {
    // ----------------------------------------------------------
    // 性別セレクター・自動カナ
    // ----------------------------------------------------------
    group('選手性別セレクター・自動カナテスト', () {
      testWidgets('MasterPlayerGenderSelector taps correctlyこと', (
        tester,
      ) async {
        String selectedGender = '男子';

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MasterPlayerGenderSelector(
                selectedGender: selectedGender,
                onGenderChanged: (val) => selectedGender = val,
              ),
            ),
          ),
        );

        expect(find.text('男子'), findsOneWidget);
        expect(find.text('女子'), findsOneWidget);

        await tester.tap(find.text('女子'));
        await tester.pump();

        expect(selectedGender, '女子');
      });

      testWidgets('氏名変更時にフリガナが自動更新されること', (tester) async {
        final nameCtrl = TextEditingController();
        final kanaCtrl = TextEditingController();

        AutoKanaHelper.setupAutoKana(nameCtrl, kanaCtrl);

        nameCtrl.text = 'さとう';
        await tester.pump();

        expect(kanaCtrl.text, 'さとう');

        nameCtrl.dispose();
        kanaCtrl.dispose();
      });
    });

    // ----------------------------------------------------------
    // 選手タイル
    // ----------------------------------------------------------
    group('MasterPlayerTile描画テスト', () {
      testWidgets('選手詳細が正しく描画されること', (tester) async {
        final player = PlayerModel(
          id: 'p1',
          lastName: '山田',
          firstName: '太郎',
          lastNameKana: 'ヤマダ',
          firstNameKana: 'タロウ',
          gender: '男子',
          grade: 7,
          isBeginner: true,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MasterPlayerTile(
                player: player,
                isReadOnly: false,
                canManageMaster: true,
                isSelectionMode: false,
                isSelected: false,
              ),
            ),
          ),
        );

        expect(find.text('山田 太郎'), findsOneWidget);
        expect(find.text('ヤマダ タロウ '), findsOneWidget);
        expect(find.text('中学1年 / 男子'), findsOneWidget);
        expect(find.text('初心者'), findsOneWidget);
      });

      testWidgets('選択モード時のタップ操作が正しく処理されること', (tester) async {
        final player = PlayerModel(
          id: 'p1',
          lastName: '佐藤',
          firstName: '花子',
          lastNameKana: 'サトウ',
          firstNameKana: 'ハナコ',
          gender: '女子',
          grade: 6,
        );

        bool tappedSelection = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MasterPlayerTile(
                player: player,
                isReadOnly: false,
                canManageMaster: true,
                isSelectionMode: true,
                isSelected: true,
                onTapSelection: () {
                  tappedSelection = true;
                },
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.check_circle), findsOneWidget);
        await tester.tap(find.text('佐藤 花子'));
        await tester.pump();
        expect(tappedSelection, isTrue);
      });
    });

    // ----------------------------------------------------------
    // グループ化ヘルパー
    // ----------------------------------------------------------
    group('MasterPlayerGroupingHelperグループ化テスト', () {
      test('getCategoryNameにおいて correct 部門 for each gradeが返却されること', () {
        expect(MasterPlayerGroupingHelper.getCategoryName(-1), '初心者の部');
        expect(MasterPlayerGroupingHelper.getCategoryName(0), '幼年の部');
        expect(MasterPlayerGroupingHelper.getCategoryName(3), '小学生低学年の部');
        expect(MasterPlayerGroupingHelper.getCategoryName(6), '小学生高学年の部');
        expect(MasterPlayerGroupingHelper.getCategoryName(8), '中学生の部');
        expect(MasterPlayerGroupingHelper.getCategoryName(11), '高校生の部');
        expect(MasterPlayerGroupingHelper.getCategoryName(13), '一般の部');
      });

      test('モードが0のときに学年名で選手が正しくグループ分けされること', () {
        final players = [
          PlayerModel(
            id: 'p1',
            lastName: '山田',
            firstName: '太郎',
            lastNameKana: 'やまだ',
            firstNameKana: 'たろう',
            grade: 3,
          ),
          PlayerModel(
            id: 'p2',
            lastName: '佐藤',
            firstName: '次郎',
            lastNameKana: 'さとう',
            firstNameKana: 'じろう',
            grade: 3,
          ),
          PlayerModel(
            id: 'p3',
            lastName: '鈴木',
            firstName: '三郎',
            lastNameKana: 'すずき',
            firstNameKana: 'さぶろう',
            grade: 5,
          ),
        ];

        final grouped = MasterPlayerGroupingHelper.groupPlayers(
          players: players,
          groupingMode: 0,
        );

        expect(grouped['小学3年']!.length, 2);
        expect(grouped['小学5年']!.length, 1);
      });

      test('モードが1のときに部門別で選手が正しくグループ分けされること', () {
        final players = [
          PlayerModel(
            id: 'p1',
            lastName: '山田',
            firstName: '太郎',
            lastNameKana: 'やまだ',
            firstNameKana: 'たろう',
            grade: 1,
          ),
          PlayerModel(
            id: 'p2',
            lastName: '佐藤',
            firstName: '次郎',
            lastNameKana: 'さとう',
            firstNameKana: 'じろう',
            grade: 3,
          ),
          PlayerModel(
            id: 'p3',
            lastName: '鈴木',
            firstName: '三郎',
            lastNameKana: 'すずき',
            firstNameKana: 'さぶろう',
            grade: 5,
          ),
        ];

        final grouped = MasterPlayerGroupingHelper.groupPlayers(
          players: players,
          groupingMode: 1,
        );

        expect(grouped['小学生低学年の部']!.length, 2);
        expect(grouped['小学生高学年の部']!.length, 1);
      });
    });

    // ----------------------------------------------------------
    // 選手編集ボトムシート
    // ----------------------------------------------------------
    group('MasterPlayerEditBottomSheet編集シートテスト', () {
      testWidgets('選手編集ボトムシートに選手登録フィールド群が正しく描画されること', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: MasterPlayerEditBottomSheet(cloudDojoName: 'テスト道場'),
              ),
            ),
          ),
        );

        expect(find.text('新しい選手を登録'), findsOneWidget);
        expect(find.text('名字'), findsOneWidget);
        expect(find.text('名前'), findsOneWidget);
        expect(find.text('男子'), findsOneWidget);
        expect(find.text('女子'), findsOneWidget);
        expect(find.text('保存して登録'), findsOneWidget);
      });

      testWidgets('MasterPlayerEditBottomSheetにおいて 既存選手の情報とともに編集モードが表示されること', (
        tester,
      ) async {
        final player = PlayerModel(
          id: 'p1',
          lastName: '佐藤',
          firstName: '次郎',
          lastNameKana: 'サトウ',
          firstNameKana: 'ジロウ',
          grade: 2,
          gender: '男子',
          organization: 'テスト道場',
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: MasterPlayerEditBottomSheet(
                  player: player,
                  cloudDojoName: 'テスト道場',
                ),
              ),
            ),
          ),
        );

        expect(find.text('選手情報を編集'), findsOneWidget);
        expect(find.text('佐藤'), findsOneWidget);
        expect(find.text('次郎'), findsOneWidget);
      });
    });
  });
}
