import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../helpers/safe_pump_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/new_match/new_match_heading_notes_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/new_match/new_match_mode_input_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/new_match/new_match_scene_rule_selector_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/new_match/new_match_smart_autocomplete.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/new_match/new_match_team_selector_card.dart';
import 'package:kendo_os/shared/domain/entities/organization.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('[Widget] 新規試合作成 各種セクション・カード・コンポーネント統合検証テスト', () {
    testWidgets('デフォルト3つのシーンルールカードが描画され選択が正常に処理されること', (tester) async {
      String selectedScene = 'honsen';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return NewMatchSceneRuleSelectorSection(
                  categoryRules: const {},
                  category: '',
                  selectedScene: selectedScene,
                  onSceneSelected: (scene) =>
                      setState(() => selectedScene = scene),
                  isDark: false,
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('⚔️ 錬成（練習試合）'), findsOneWidget);
      expect(find.text('🏆 本戦（通常戦）'), findsOneWidget);
      expect(find.text('🤝 申合せ（自由対戦）'), findsOneWidget);

      await tester.tap(find.text('⚔️ 錬成（練習試合）'));
      await tester.pump();

      expect(selectedScene, 'renseikai');
    });

    testWidgets('テキストフィールドに見出しとアイコンが正しく描画されること', (WidgetTester tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [themeColors]),
          home: Scaffold(
            body: NewMatchSmartAutocomplete(
              controller: controller,
              focusNode: focusNode,
              suggestions: const ['山田', '佐藤', '田中'],
              labelText: '赤の選手名',
              isDark: false,
            ),
          ),
        ),
      );

      expect(find.text('赤の選手名'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
    });

    testWidgets('タップ時にサジェストが表示され選択した項目が反映されること', (WidgetTester tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [themeColors]),
          home: Scaffold(
            body: NewMatchSmartAutocomplete(
              controller: controller,
              focusNode: focusNode,
              suggestions: const ['山田', '佐藤', '田中'],
              labelText: '赤の選手名',
              isDark: false,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextField));
      await tester.safePumpAndSettle();

      expect(find.text('山田'), findsOneWidget);
      expect(find.text('佐藤'), findsOneWidget);
      expect(find.text('田中'), findsOneWidget);

      await tester.tap(find.text('山田'));
      await tester.safePumpAndSettle();

      expect(controller.text, '山田');
    });

    testWidgets('見出しプリセットが表示されトグルおよびクリアが正しく動作すること', (
      WidgetTester tester,
    ) async {
      final courtController = TextEditingController();
      final noteController = TextEditingController();
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [themeColors]),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return NewMatchHeadingNotesCard(
                  courtController: courtController,
                  noteController: noteController,
                  isDark: false,
                  onClearCourt: () {
                    setState(() {
                      courtController.clear();
                    });
                  },
                  onHeadingPresetToggled: (preset) {
                    setState(() {
                      courtController.text = preset;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('試合場・進行見出しの設定'), findsOneWidget);
      expect(find.text('試合場'), findsOneWidget);
      expect(find.text('試合順'), findsOneWidget);
      expect(find.text('準決勝'), findsOneWidget);

      await tester.tap(find.text('準決勝'));
      await tester.safePumpAndSettle();

      expect(courtController.text, contains('準決勝'));
      expect(find.text('クリア'), findsOneWidget);

      await tester.tap(find.text('クリア'));
      await tester.safePumpAndSettle();

      expect(courtController.text, '');

      expect(find.textContaining('運営メモ・特記事項'), findsOneWidget);
      await tester.tap(find.textContaining('運営メモ・特記事項'));
      await tester.safePumpAndSettle();

      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('道場組織ドロップダウンが表示され選択が正しく動作すること', (WidgetTester tester) async {
      Organization? selectedOrg;
      TeamTemplate? selectedTeam;

      final org1 = Organization(id: 'org1', name: '東京剣道クラブ');
      final org2 = Organization(id: 'org2', name: '大阪剣友会');
      final team1 = TeamTemplate(
        id: 'team1',
        name: 'Aチーム',
        orderedMemberNames: ['選手1', '選手2'],
      );

      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [themeColors]),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return NewMatchTeamSelectorCard(
                  colorLabel: '赤',
                  orgs: [org1, org2],
                  isRed: true,
                  selectedOrg: selectedOrg,
                  selectedTeam: selectedTeam,
                  teamTemplates: [team1],
                  onOrgChanged: (val) {
                    setState(() {
                      selectedOrg = val;
                    });
                  },
                  onTeamChanged: (val) {
                    setState(() {
                      selectedTeam = val;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('赤チーム選択'), findsOneWidget);
      expect(find.text('組織（道場・学校）を選択'), findsOneWidget);
      expect(find.text('チームテンプレを選択'), findsNothing);

      await tester.tap(find.text('組織（道場・学校）を選択'), warnIfMissed: false);
      await tester.safePumpAndSettle();

      expect(find.text('東京剣道クラブ'), findsOneWidget);
      expect(find.text('大阪剣友会'), findsOneWidget);

      await tester.tap(find.text('東京剣道クラブ').last);
      await tester.safePumpAndSettle();

      expect(selectedOrg, org1);
      expect(find.text('チームテンプレを選択'), findsOneWidget);
    });

    testWidgets('単発試合モードにおいて単発試合用入力フォームが正しく描画されること', (tester) async {
      final redController = TextEditingController();
      final whiteController = TextEditingController();
      final leagueController = TextEditingController();
      final redFocus = FocusNode();
      final whiteFocus = FocusNode();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: NewMatchModeInputSection(
                creationMode: '単発試合',
                redNameController: redController,
                redFocusNode: redFocus,
                whiteNameController: whiteController,
                whiteFocusNode: whiteFocus,
                leagueParticipantsController: leagueController,
                suggestions: const ['選手A', '選手B'],
                redOrg: null,
                redTeam: null,
                whiteOrg: null,
                whiteTeam: null,
                onRedOrgChanged: (_) {},
                onRedTeamChanged: (_) {},
                onWhiteOrgChanged: (_) {},
                onWhiteTeamChanged: (_) {},
                isDark: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('赤の選手名（またはチーム名）'), findsOneWidget);
      expect(find.text('白の選手名（またはチーム名）'), findsOneWidget);
    });

    testWidgets('リーグ戦自動生成モードにおいて参加者テキストエリアが正しく描画されること', (tester) async {
      final redController = TextEditingController();
      final whiteController = TextEditingController();
      final leagueController = TextEditingController();
      final redFocus = FocusNode();
      final whiteFocus = FocusNode();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: NewMatchModeInputSection(
                creationMode: 'リーグ戦自動生成',
                redNameController: redController,
                redFocusNode: redFocus,
                whiteNameController: whiteController,
                whiteFocusNode: whiteFocus,
                leagueParticipantsController: leagueController,
                suggestions: const [],
                redOrg: null,
                redTeam: null,
                whiteOrg: null,
                whiteTeam: null,
                onRedOrgChanged: (_) {},
                onRedTeamChanged: (_) {},
                onWhiteOrgChanged: (_) {},
                onWhiteTeamChanged: (_) {},
                isDark: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('参加者リスト'), findsOneWidget);
      expect(
        find.text('参加チーム（選手）をカンマ( , )区切りで入力してください\n例: Aチーム, Bチーム, C道場, D剣友会'),
        findsOneWidget,
      );
    });
  });
}
