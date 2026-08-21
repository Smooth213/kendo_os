import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_rule_step.dart';
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
                    required String hintText,
                    required String labelText,
                    Widget? prefixIcon,
                  }) => InputDecoration(
                    labelText: labelText,
                    hintText: hintText,
                    prefixIcon: prefixIcon,
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
}
