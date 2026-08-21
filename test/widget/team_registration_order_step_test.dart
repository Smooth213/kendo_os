import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_order_step.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  testWidgets('TeamRegistrationOrderStep renders properly', (tester) async {
    final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');
    final controller = TextEditingController(text: '赤心館A');
    final focusNode = FocusNode();

    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light().copyWith(extensions: [themeColors]),
        home: Scaffold(
          body: TeamRegistrationOrderStep(
            playerCount: 5,
            posNames: const ['先鋒', '次鋒', '中堅', '副将', '大将'],
            players: const [],
            teamNameController: controller,
            teamNameFocusNode: focusNode,
            teamNameSuggestions: const ['赤心館A', '白龍会B'],
            tempSelectedPlayers: const {0: '選手1'},
            substituteCount: 0,
            matchType: '団体戦（5人制）',
            themeColors: themeColors,
            onSelectPlayer: (_) {},
            onRemoveSubstitute: (_) {},
            onAddSubstitute: () {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('チーム名とオーダーを\n入力してください'), findsOneWidget);
    expect(find.text('選手1'), findsOneWidget);
    expect(find.text('先鋒'), findsOneWidget);
    expect(find.text('補欠を追加 (0/4)'), findsOneWidget);
  });
}
