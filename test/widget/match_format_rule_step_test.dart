import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_rule_step.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  const dummyThemeColors = AppThemeColors(
    primaryAccent: Colors.indigo,
    softAccent: Colors.indigoAccent,
    cardBackground: Colors.white,
    scaffoldBackground: Colors.white,
    textColor: Colors.black,
    subTextColor: Colors.grey,
    separatorColor: Colors.grey,
    inputBackground: Colors.white,
    hintColor: Colors.grey,
    rosePink: Colors.pink,
    successColor: Colors.green,
    warningColor: Colors.orange,
    errorColor: Colors.red,
    infoColor: Colors.blue,
  );

  testWidgets('MatchFormatRuleStep renders correctly', (tester) async {
    final courtCtrl = TextEditingController(text: '第1コート');
    final noteCtrl = TextEditingController();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: MatchFormatRuleStep(
              tournamentId: 't1',
              category: '小学生の部',
              selectedRuleScene: 'honsen',
              isCurrentMatchAdvanced: false,
              hasExtension: true,
              extTime: 2.0,
              extCount: 1,
              matchTime: 3.0,
              isRunningTime: false,
              isRenseikai: false,
              renseikaiType: 'normal',
              matchType: '個人戦',
              isIpponShobu: false,
              ipponLimit: 2,
              hansokuLimit: 2,
              hasHantei: true,
              kachinukiUnlimitedType: 'none',
              hasLeagueDaihyo: false,
              isDaihyoIpponShobu: false,
              daihyoMatchTime: 3.0,
              daihyoHasExtension: false,
              daihyoEnchoCount: 0,
              daihyoEnchoTime: 0.0,
              daihyoHasHantei: false,
              winPoint: 3,
              lossPoint: 0,
              drawPoint: 1,
              overallTimeMinutes: 30,
              courtController: courtCtrl,
              noteController: noteCtrl,
              themeColors: dummyThemeColors,
              onRuleSceneSelected: (scene, ruleSet) {},
              onSetManualRoundType: (type) {},
              onHeadingPresetToggled: (heading) {},
              onClearCourt: () {},
              buildTextFieldDecoration:
                  ({
                    required String labelText,
                    String? hintText,
                    Widget? prefixIcon,
                    String? suffixText,
                  }) => InputDecoration(
                    labelText: labelText,
                    hintText: hintText,
                    prefixIcon: prefixIcon,
                    suffixText: suffixText,
                  ),
              buildSectionHeader: (title, accentColor) => Text(title),
              formatMinutesText: (m) => '${m.toInt()}分',
            ),
          ),
        ),
      ),
    );

    expect(find.text('適用ルールの確認と\n詳細情報の入力'), findsOneWidget);
    expect(find.text('第1コート'), findsOneWidget);
  });

  testWidgets('同一部門に複数ルールが存在する場合に複数のチップが表示され、選択切り替えできること', (tester) async {
    final courtCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    final testTournament = TournamentModel(
      id: 't_multi',
      organizationId: 'org1',
      name: 'テスト大会',
      date: DateTime.now(),
      venue: '道場',
      categories: ['小学生低学年の部', '小学生低学年の部 (2)'],
      categoryRules: {
        '小学生低学年の部': const CategoryRuleSet(
          subtitle: '予選リーグ',
          matchType: '団体戦',
          useHonsenRule: true,
          normalRule: MatchRule(matchTimeMinutes: 2.0),
        ),
        '小学生低学年の部 (2)': const CategoryRuleSet(
          subtitle: '決勝トーナメント',
          matchType: '団体戦',
          useHonsenRule: true,
          useAdvancedRule: true,
          normalRule: MatchRule(matchTimeMinutes: 3.0),
          advancedRule: MatchRule(matchTimeMinutes: 4.0),
        ),
      },
    );

    String? selectedKey;
    String? selectedScene;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tournamentProvider(
            't_multi',
          ).overrideWith((ref) => Stream.value(testTournament)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: MatchFormatRuleStep(
              tournamentId: 't_multi',
              category: '小学生低学年の部',
              selectedRuleScene: 'honsen',
              selectedRuleKey: '小学生低学年の部',
              isCurrentMatchAdvanced: false,
              hasExtension: false,
              extTime: 0.0,
              extCount: 0,
              matchTime: 2.0,
              isRunningTime: false,
              isRenseikai: false,
              renseikaiType: 'normal',
              matchType: '団体戦',
              isIpponShobu: false,
              ipponLimit: 2,
              hansokuLimit: 2,
              hasHantei: true,
              kachinukiUnlimitedType: 'none',
              hasLeagueDaihyo: false,
              isDaihyoIpponShobu: false,
              daihyoMatchTime: 3.0,
              daihyoHasExtension: false,
              daihyoEnchoCount: 0,
              daihyoEnchoTime: 0.0,
              daihyoHasHantei: false,
              winPoint: 3,
              lossPoint: 0,
              drawPoint: 1,
              overallTimeMinutes: 30,
              courtController: courtCtrl,
              noteController: noteCtrl,
              themeColors: dummyThemeColors,
              onRuleSelected: (ruleKey, scene, ruleSet) {
                selectedKey = ruleKey;
                selectedScene = scene;
              },
              onSetManualRoundType: (type) {},
              onHeadingPresetToggled: (heading) {},
              onClearCourt: () {},
              buildTextFieldDecoration:
                  ({
                    required String labelText,
                    String? hintText,
                    Widget? prefixIcon,
                    String? suffixText,
                  }) => InputDecoration(
                    labelText: labelText,
                    hintText: hintText,
                    prefixIcon: prefixIcon,
                    suffixText: suffixText,
                  ),
              buildSectionHeader: (title, accentColor) => Text(title),
              formatMinutesText: (m) => '${m.toInt()}分',
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 複数ルール選択の案内文が表示されていること
    expect(find.text('この部門（小学生低学年の部）に登録されているルールを選択:'), findsOneWidget);

    // 「🏆 予選リーグ」と「🏆 決勝トーナメント」と「⭐ 決勝トーナメント（上位戦）」のチップが表示されていること
    expect(find.text('🏆 予選リーグ'), findsOneWidget);
    expect(find.text('🏆 決勝トーナメント'), findsOneWidget);
    expect(find.text('⭐ 決勝トーナメント（上位戦）'), findsOneWidget);

    // 「🏆 決勝トーナメント」をタップした時、正しいキーとシーンでコールバックが呼ばれること
    await tester.tap(find.text('🏆 決勝トーナメント'));
    await tester.pumpAndSettle();

    expect(selectedKey, '小学生低学年の部 (2)');
    expect(selectedScene, 'honsen');

    // 「⭐ 決勝トーナメント（上位戦）」をタップした時
    await tester.tap(find.text('⭐ 決勝トーナメント（上位戦）'));
    await tester.pumpAndSettle();

    expect(selectedKey, '小学生低学年の部 (2)');
    expect(selectedScene, 'advanced');
  });
}
