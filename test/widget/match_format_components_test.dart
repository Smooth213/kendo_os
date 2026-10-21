import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_category_step.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_heading_and_note_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_option_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_rule_summary_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_sticky_bottom_action.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_team_detail_dialog.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/glass_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  group('[Widget] 試合形式・ルール設定UIコンポーネント 総合テスト', () {
    // 1. MatchFormatOptionCard & SetupReadOnlyRuleRow
    testWidgets('MatchFormatOptionCardおよび読取専用行が正しく描画されること', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                MatchFormatOptionCard(
                  title: '試合形式設定',
                  icon: Icons.sports_kabaddi,
                  color: Colors.blue,
                  child: Text('5人制団体戦'),
                ),
                SetupReadOnlyRuleRow(label: '試合時間', value: '3分'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('試合形式設定'), findsOneWidget);
      expect(find.byIcon(Icons.sports_kabaddi), findsOneWidget);
      expect(find.text('5人制団体戦'), findsOneWidget);
      expect(find.text('試合時間'), findsOneWidget);
      expect(find.text('3分'), findsOneWidget);
    });

    // 2. MatchFormatHeadingAndNoteSection
    testWidgets('進行見出しセクションにおいて プリセット選択とテキスト反映が正常動作すること', (tester) async {
      final courtCtrl = TextEditingController(text: '第1試合場');
      final noteCtrl = TextEditingController(text: '特記事項なし');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchFormatHeadingAndNoteSection(
              themeColors: dummyThemeColors,
              courtController: courtCtrl,
              noteController: noteCtrl,
              onToggleHeadingPreset: (_) {},
              isDark: false,
              buildTextFieldDecoration:
                  ({
                    required String labelText,
                    required String hintText,
                    Widget? prefixIcon,
                  }) {
                    return InputDecoration(
                      labelText: labelText,
                      hintText: hintText,
                      prefixIcon: prefixIcon,
                    );
                  },
            ),
          ),
        ),
      );

      expect(find.text('試合場・進行見出しの一括設定'), findsOneWidget);
      expect(find.text('1回戦'), findsOneWidget);

      await tester.tap(find.text('1回戦'));
      await tester.pump();
      expect(courtCtrl.text, '第1試合場, 1回戦');

      expect(find.text('カンマ（,）'), findsOneWidget);
      await tester.tap(find.text('カンマ（,）'));
      await tester.pump();
      expect(noteCtrl.text, '特記事項なし, ');
    });

    // 3. MatchFormatRuleSummaryCard
    testWidgets('ルール概要カードにおいて 各種設定情報が正しく描画されること', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MatchFormatRuleSummaryCard(
                displayRuleName: '🏆 本戦ルール',
                isAdvanced: false,
                themeColors: dummyThemeColors,
                isRenseikai: false,
                renseikaiType: '試合数制',
                matchTime: 3.0,
                overallTimeMinutes: '30',
                matchType: '団体戦',
                isRunningTime: false,
                isIpponShobu: false,
                ipponLimit: 2,
                hansokuLimit: 2,
                extensionText: 'あり (2分 / 1回)',
                hasHantei: true,
                kachinukiUnlimitedType: 'なし',
                hasLeagueDaihyo: true,
                isDaihyoIpponShobu: true,
                daihyoMatchTime: 2.0,
                daihyoHasExtension: true,
                daihyoEnchoTime: 2.0,
                daihyoEnchoCount: 1,
                daihyoHasHantei: false,
                winPoint: 3,
                lossPoint: 0,
                drawPoint: 1,
                formatMinutesText: (m) => '${m.toInt()}分',
                buildSectionHeader: (title, color) => Text(title),
              ),
            ),
          ),
        ),
      );

      expect(find.text('現在適用中のルール: 🏆 本戦ルール'), findsOneWidget);
      expect(find.text('試合方式'), findsOneWidget);
      expect(find.text('団体戦'), findsOneWidget);
      expect(find.text('勝負方式'), findsOneWidget);
      expect(find.text('三本勝負 (2本先取)'), findsOneWidget);
      expect(find.text('代表戦'), findsOneWidget);
      expect(find.text('あり (一本勝負)'), findsOneWidget);
    });

    // 4. MatchFormatStickyBottomAction
    testWidgets('スティッキーボトムアクションにおいて ページ遷移ボタンが正常動作すること', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      // 初回ページ
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            theme: ThemeData(extensions: const [dummyThemeColors]),
            home: Scaffold(
              body: MatchFormatStickyBottomAction(
                currentPage: 0,
                isLastPage: false,
                themeColors: dummyThemeColors,
                onPrevious: () {},
                onNextOrComplete: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GlassButton), findsOneWidget);
      expect(find.text('次へ進む'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new), findsNothing);

      // 最終ページ
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            theme: ThemeData(extensions: const [dummyThemeColors]),
            home: Scaffold(
              body: MatchFormatStickyBottomAction(
                currentPage: 1,
                isLastPage: true,
                themeColors: dummyThemeColors,
                onPrevious: () {},
                onNextOrComplete: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('このルールで枠を作成'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
    });

    // 5. MatchFormatCategoryStep
    testWidgets('部門選択ステップにおいて 各部門要素が正しく描画されること', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MatchFormatCategoryStep(
                tournamentId: 'tourney1',
                category: '小学生の部',
                selectedMajorCategory: '小学生の部',
                selectedMinorCategory: '低学年の部',
                selectedTeamId: 'team1',
                majorCategories: const ['小学生の部', '中学生の部'],
                getMinorCategories: (major) => ['低学年の部', '高学年の部'],
                onCategoryChanged: (major, minor) {},
                onTeamSelected: (team) {},
                onAdjustOrder: (team) {},
                onEditTeam: (team) {},
                onDeleteTeam: (team) {},
                onNavigateToTeamRegistration: () {},
                themeColors: dummyThemeColors,
                isDark: false,
                buildSectionTitle: (title) => Text(title),
              ),
            ),
          ),
        ),
      );

      expect(find.text('小学生の部'), findsWidgets);
    });

    // 6. MatchFormatTeamDetailDialog
    testWidgets('チーム詳細ダイアログにおいて オーダー情報が正しく描画されること', (tester) async {
      const mockTeam = TeamModel(
        id: 'team1',
        tournamentId: 'tourney1',
        category: '小学生の部',
        teamName: '東京A',
        playerNames: ['選手1'],
      );

      final mockPlayers = [
        PlayerModel(
          id: 'p1',
          lastName: '山田',
          firstName: '太郎',
          lastNameKana: 'ヤマダ',
          firstNameKana: 'タロウ',
          grade: 5,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => MatchFormatTeamDetailDialog(
                        team: mockTeam,
                        posNames: const ['先鋒', '次鋒', '中堅', '副将', '大将'],
                        themeColors: dummyThemeColors,
                        players: mockPlayers,
                        onTeamUpdated: (updated) {},
                      ),
                    );
                  },
                  child: const Text('Open Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('東京A'), findsOneWidget);
      expect(find.text('オーダー（タップして入れ替え）'), findsOneWidget);
    });
  });
}
