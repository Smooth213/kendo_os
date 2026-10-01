import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_setup_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_order_step.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Golden] 団体戦オーダー編成（3〜11人制）ピクセル完全性テスト', () {
    Widget buildOrderStepWrapper({
      required int basePlayerCount,
      required int substituteCount,
      required bool isDark,
      required Map<int, String> selectedPlayers,
      String matchType = '7人制',
    }) {
      final basePosNames = MatchFormatSetupHelper.generatePositions(
        basePlayerCount,
      );
      final bool isMoreThan7 = matchType.contains('それ以上');
      final posNames = isMoreThan7
          ? basePosNames
          : [...basePosNames, ...List.filled(substituteCount, '補欠')];
      final totalPlayerCount = isMoreThan7
          ? basePlayerCount
          : (basePlayerCount + substituteCount);

      final themeColors = AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
      final dummyPlayers = [
        PlayerModel(
          id: 'p1',
          lastName: '佐藤',
          firstName: '健太',
          lastNameKana: 'サトウ',
          firstNameKana: 'ケンタ',
          grade: 6,
        ),
        PlayerModel(
          id: 'p2',
          lastName: '鈴木',
          firstName: '一郎',
          lastNameKana: 'スズキ',
          firstNameKana: 'イチロウ',
          grade: 5,
        ),
        PlayerModel(
          id: 'p3',
          lastName: '田中',
          firstName: '太郎',
          lastNameKana: 'タナカ',
          firstNameKana: 'タロウ',
          grade: 6,
        ),
        PlayerModel(
          id: 'p4',
          lastName: '高橋',
          firstName: '次郎',
          lastNameKana: 'タカハシ',
          firstNameKana: 'ジロウ',
          grade: 4,
        ),
        PlayerModel(
          id: 'p5',
          lastName: '伊藤',
          firstName: '三郎',
          lastNameKana: 'イトウ',
          firstNameKana: 'サブロウ',
          grade: 5,
        ),
        PlayerModel(
          id: 'p6',
          lastName: '渡辺',
          firstName: '四郎',
          lastNameKana: 'ワタナベ',
          firstNameKana: 'シロウ',
          grade: 6,
        ),
        PlayerModel(
          id: 'p7',
          lastName: '山本',
          firstName: '五郎',
          lastNameKana: 'ヤマモト',
          firstNameKana: 'ゴロウ',
          grade: 4,
        ),
      ];

      return ProviderScope(
        child: AppThemeModeWrapper(
          mode: isDark ? 'dark' : 'normal',
          child: MaterialApp(
            theme: isDark
                ? ThemeData.dark().copyWith(extensions: [themeColors])
                : ThemeData.light().copyWith(extensions: [themeColors]),
            home: Scaffold(
              body: TeamRegistrationOrderStep(
                playerCount: totalPlayerCount,
                posNames: posNames,
                players: dummyPlayers,
                teamNameController: TextEditingController(text: '錬心館道場 Aチーム'),
                teamNameFocusNode: FocusNode(),
                teamNameSuggestions: const ['錬心館道場 Aチーム', '錬心館道場 Bチーム'],
                tempSelectedPlayers: selectedPlayers,
                substituteCount: substituteCount,
                matchType: matchType,
                themeColors: themeColors,
                onSelectPlayer: (_) {},
                onRemoveSubstitute: (_) {},
                onAddSubstitute: () {},
                onAddPlayerSlot: () {},
                onRemovePlayerSlot: (_) {},
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('7人制オーダー設定: スマホ幅(390px) ライトモード レンダリングが正しく検証されること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final selectedPlayers = <int, String>{
        0: '佐藤 健太',
        1: '鈴木 一郎',
        2: '田中 太郎',
        3: '高橋 次郎',
        4: '伊藤 三郎',
        5: '渡辺 四郎',
        6: '山本 五郎',
        7: '補欠1 選手',
      };

      await tester.pumpWidget(
        buildOrderStepWrapper(
          basePlayerCount: 7,
          substituteCount: 1,
          isDark: false,
          selectedPlayers: selectedPlayers,
          matchType: '7人制',
        ),
      );
      await tester.pumpAndSettle();

      // 先鋒〜大将、補欠の全スロットがオーバーフローなく描画されていること
      expect(find.text('先鋒'), findsOneWidget);
      expect(find.text('次鋒'), findsOneWidget);
      expect(find.text('五将'), findsOneWidget);
      expect(find.text('中堅'), findsOneWidget);
      expect(find.text('三将'), findsOneWidget);
      expect(find.text('副将'), findsOneWidget);
      expect(find.text('大将'), findsOneWidget);
      expect(find.text('補欠'), findsOneWidget);
      expect(find.text('佐藤 健太'), findsOneWidget);
      expect(find.text('山本 五郎'), findsOneWidget);
      expect(find.text('補欠1 選手'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('11人制オーダー設定: タブレット幅(800px) ダークモード レンダリングが正しく検証されること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final selectedPlayers = <int, String>{0: '佐藤 健太', 10: '山本 五郎'};

      await tester.pumpWidget(
        buildOrderStepWrapper(
          basePlayerCount: 11,
          substituteCount: 0,
          isDark: true,
          selectedPlayers: selectedPlayers,
          matchType: 'それ以上（11人）',
        ),
      );
      await tester.pumpAndSettle();

      // 11人制のポジションスロット一覧
      expect(find.text('先鋒'), findsOneWidget);
      expect(find.text('大将'), findsOneWidget);
      expect(find.text('佐藤 健太'), findsOneWidget);
      expect(find.text('山本 五郎'), findsOneWidget);
      expect(find.textContaining('選手枠を追加'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('3人制オーダー設定: 補欠なし・最小構成のピクセル完全性こと', (tester) async {
      tester.view.physicalSize = const Size(390, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildOrderStepWrapper(
          basePlayerCount: 3,
          substituteCount: 0,
          isDark: false,
          selectedPlayers: {},
          matchType: '3人制',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('先鋒'), findsOneWidget);
      expect(find.text('中堅'), findsOneWidget);
      expect(find.text('大将'), findsOneWidget);
      expect(find.text('未選択'), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    });
  });
}
