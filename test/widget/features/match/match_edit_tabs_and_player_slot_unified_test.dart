import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../helpers/safe_pump_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_edit_court_and_group_tab.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_edit_data_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_edit_player_slot_tile.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_edit_team_and_players_tab.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('[Widget] MatchEditTabsAndPlayerSlot 統合テスト', () {
    late TextEditingController courtController;
    late TextEditingController noteController;
    late AppThemeColors themeColors;

    setUp(() {
      courtController = TextEditingController(text: '第1試合場, 1回戦');
      noteController = TextEditingController(text: '注意事項テスト');
      themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');
    });

    tearDown(() {
      courtController.dispose();
      noteController.dispose();
    });

    testWidgets('コートおよび回戦プリセットチップが表示され選択が正しく動作すること', (tester) async {
      String toggledPreset = '';
      bool cleared = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchEditCourtAndGroupTab(
              themeColors: themeColors,
              courtController: courtController,
              noteController: noteController,
              isDark: false,
              textColor: Colors.black87,
              onToggleHeadingPreset: (preset) {
                toggledPreset = preset;
              },
              onClearCourt: () {
                cleared = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('試合場・進行見出しの一括設定'), findsOneWidget);
      expect(find.text('第1試合場'), findsOneWidget);
      expect(find.text('1回戦'), findsOneWidget);
      expect(find.text('決勝戦'), findsOneWidget);

      await tester.tap(find.text('決勝戦'));
      await tester.pump();
      expect(toggledPreset, '決勝戦');

      await tester.tap(find.text('クリア'));
      await tester.pump();
      expect(cleared, isTrue);
    });

    testWidgets('カンマチップおよびカンマボタンをタップしてカンマが正しく挿入されること', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchEditCourtAndGroupTab(
              themeColors: themeColors,
              courtController: courtController,
              noteController: noteController,
              isDark: false,
              textColor: Colors.black87,
              onToggleHeadingPreset: (_) {},
              onClearCourt: () {},
            ),
          ),
        ),
      );

      expect(find.text('， (カンマ)'), findsOneWidget);
      expect(find.text('カンマ（,）'), findsOneWidget);

      await tester.tap(find.text('， (カンマ)'));
      await tester.pump();
      expect(courtController.text, '第1試合場, 1回戦, ');

      await tester.tap(find.text('カンマ（,）'));
      await tester.pump();
      expect(noteController.text, '注意事項テスト, ');
    });

    testWidgets('ダークモード時にヒントテキストがhintColorで適切に描画されること', (tester) async {
      final darkColors = AppThemeColors.ofMode(isDark: true, mode: 'normal');
      final emptyCourtCtrl = TextEditingController();
      final emptyNoteCtrl = TextEditingController();

      addTearDown(() {
        emptyCourtCtrl.dispose();
        emptyNoteCtrl.dispose();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchEditCourtAndGroupTab(
              themeColors: darkColors,
              courtController: emptyCourtCtrl,
              noteController: emptyNoteCtrl,
              isDark: true,
              textColor: darkColors.textColor,
              onToggleHeadingPreset: (_) {},
              onClearCourt: () {},
            ),
          ),
        ),
      );

      final textFields = tester.widgetList<TextField>(find.byType(TextField));
      expect(textFields, isNotEmpty);
      for (final textField in textFields) {
        expect(
          textField.decoration?.hintStyle?.color,
          equals(darkColors.hintColor),
        );
        expect(
          textField.decoration?.hintStyle?.color,
          isNot(equals(const Color(0xFFFFFFFF))),
        );
      }
    });

    testWidgets('ポジション名および紅白選手名欄が正しく描画されること', (tester) async {
      final redController = TextEditingController(text: '山田 太郎');
      final whiteController = TextEditingController(text: '佐藤 次郎');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [themeColors]),
          home: Scaffold(
            body: MatchEditPlayerSlotTile(
              posLabel: '先鋒',
              redController: redController,
              whiteController: whiteController,
              primaryAccent: Colors.blue,
              isDark: false,
              textColor: Colors.black,
            ),
          ),
        ),
      );

      expect(find.text('先鋒'), findsOneWidget);
      expect(find.text('山田 太郎'), findsOneWidget);
      expect(find.text('佐藤 次郎'), findsOneWidget);
      expect(find.text('vs'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, '山田 三郎');
      expect(redController.text, '山田 三郎');
    });

    testWidgets('ダークモード時において背景色が適切に適用され正しく描画されること', (tester) async {
      final redController = TextEditingController();
      final whiteController = TextEditingController();
      final darkColors = AppThemeColors.ofMode(isDark: true, mode: 'normal');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: Brightness.dark,
            extensions: [darkColors],
          ),
          home: Scaffold(
            body: MatchEditPlayerSlotTile(
              posLabel: '中堅',
              redController: redController,
              whiteController: whiteController,
              primaryAccent: Colors.purple,
              isDark: true,
              textColor: Colors.white,
            ),
          ),
        ),
      );

      expect(find.text('中堅'), findsOneWidget);
      expect(find.text('赤 選手名'), findsOneWidget);
      expect(find.text('白 選手名'), findsOneWidget);
    });

    test('MatchEditDataHelperにおいて 選手名および整形された備考が正しく抽出されること', () {
      expect(
        MatchEditDataHelper.extractTeamName('青龍道場: 山田', 'fallback', true),
        '青龍道場',
      );
      expect(MatchEditDataHelper.extractPlayerName('青龍道場: 山田'), '山田');
      expect(MatchEditDataHelper.cleanNoteText('第1コート\n個人戦メモ'), '個人戦メモ');
      expect(MatchEditDataHelper.getPositionLabel(0, 5), '先鋒');
      expect(MatchEditDataHelper.getPositionLabel(4, 5), '大将');
    });

    testWidgets('MatchEditTeamAndPlayersTabにおいて 入力欄が描画され紅白入替が正常に行えること', (
      tester,
    ) async {
      final redTeamCtrl = TextEditingController(text: '赤チーム');
      final whiteTeamCtrl = TextEditingController(text: '白チーム');
      final redPlayerCtrls = [TextEditingController(text: '赤選手1')];
      final whitePlayerCtrls = [TextEditingController(text: '白選手1')];
      bool swapCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(extensions: [themeColors]),
          home: Scaffold(
            body: MatchEditTeamAndPlayersTab(
              isDantai: true,
              redTeamController: redTeamCtrl,
              whiteTeamController: whiteTeamCtrl,
              redPlayerControllers: redPlayerCtrls,
              whitePlayerControllers: whitePlayerCtrls,
              primaryAccent: AppKendoColors.indigo,
              isDark: false,
              textColor: AppKendoColors.pureBlack,
              onSwapTeamsAndPlayers: () {
                swapCalled = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('🏫 団体戦 対戦チーム'), findsOneWidget);
      expect(find.text('赤チーム'), findsOneWidget);
      expect(find.text('白チーム'), findsOneWidget);
      expect(find.text('赤選手1'), findsOneWidget);
      expect(find.text('白選手1'), findsOneWidget);

      await tester.tap(find.text('チーム丸ごと赤と白を入れ替える ⇄'));
      await tester.safePumpAndSettle();

      expect(swapCalled, isTrue);
    });
  });
}
