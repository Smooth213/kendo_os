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

  testWidgets('☀️ ライトモード: 補欠アバターの背景と文字が同化せず、高コントラストで視認できること', (tester) async {
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
            playerCount: 6, // 5人レギュラー + 1人補欠
            posNames: const ['先鋒', '次鋒', '中堅', '副将', '大将', '補欠1'],
            players: const [],
            teamNameController: controller,
            teamNameFocusNode: focusNode,
            teamNameSuggestions: const [],
            tempSelectedPlayers: const {},
            substituteCount: 1,
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

    // 「補」の文字が描画されていること
    final subTextFinder = find.text('補');
    expect(subTextFinder, findsOneWidget);

    final Text subText = tester.widget(subTextFinder);
    final TextStyle subTextStyle = subText.style!;

    // 親の CircleAvatar を取得
    final circleAvatarFinder = find.ancestor(
      of: subTextFinder,
      matching: find.byType(CircleAvatar),
    );
    expect(circleAvatarFinder, findsOneWidget);
    final CircleAvatar circleAvatar = tester.widget(circleAvatarFinder);

    // 背景色と文字色が同色（視認性不良）になっていないこと
    expect(
      circleAvatar.backgroundColor,
      isNot(equals(subTextStyle.color)),
      reason: '背景色と文字色が同じだと文字が消えてしまいます',
    );

    // ライトモードの規定色（淡いオレンジ背景 + 濃いオレンジ文字）であること
    expect(circleAvatar.backgroundColor, equals(const Color(0xFFFFF3E0)));
    expect(subTextStyle.color, equals(const Color(0xFFE65100)));
  });

  testWidgets('🌙 ダークモード: 補欠アバターの背景と文字が同化せず、高コントラストで視認できること', (tester) async {
    final themeColors = AppThemeColors.ofMode(isDark: true, mode: 'normal');
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
        theme: ThemeData.dark().copyWith(extensions: [themeColors]),
        home: Scaffold(
          body: TeamRegistrationOrderStep(
            playerCount: 6,
            posNames: const ['先鋒', '次鋒', '中堅', '副将', '大将', '補欠1'],
            players: const [],
            teamNameController: controller,
            teamNameFocusNode: focusNode,
            teamNameSuggestions: const [],
            tempSelectedPlayers: const {},
            substituteCount: 1,
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

    final subTextFinder = find.text('補');
    expect(subTextFinder, findsOneWidget);

    final Text subText = tester.widget(subTextFinder);
    final TextStyle subTextStyle = subText.style!;

    final circleAvatarFinder = find.ancestor(
      of: subTextFinder,
      matching: find.byType(CircleAvatar),
    );
    expect(circleAvatarFinder, findsOneWidget);
    final CircleAvatar circleAvatar = tester.widget(circleAvatarFinder);

    expect(
      circleAvatar.backgroundColor,
      isNot(equals(subTextStyle.color)),
      reason: 'ダークモードでも背景色と文字色が同じだと文字が消えてしまいます',
    );

    expect(
      circleAvatar.backgroundColor,
      equals(const Color(0xFFFF9800).withValues(alpha: 0.2)),
    );
    expect(subTextStyle.color, equals(const Color(0xFFFFB74D)));
  });
}
