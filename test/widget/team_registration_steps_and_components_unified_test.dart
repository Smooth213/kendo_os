import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_app_bar.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_autocomplete_field.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_category_step.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_confirm_step.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_dynamic_header.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_player_select_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_selection_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_sticky_bottom_bar.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Widget] チーム登録 ステップ・コンポーネント統合検証テスト', () {
    testWidgets('TeamRegistrationAppBarにおいて 戻るボタンが動作すること', (tester) async {
      bool backPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TeamRegistrationAppBar(onBack: () => backPressed = true),
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      expect(backPressed, isTrue);
    });

    testWidgets('TeamRegistrationDynamicHeaderおよびAutocompleteFieldが描画されること', (
      tester,
    ) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');
      final controller = TextEditingController();
      final focusNode = FocusNode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TeamRegistrationDynamicHeader(
                  currentPage: 0,
                  themeColors: themeColors,
                ),
                TeamRegistrationAutocompleteField(
                  controller: controller,
                  focusNode: focusNode,
                  suggestions: const ['赤チーム', '白チーム'],
                  labelText: 'チーム名',
                  hintText: 'チーム名を入力',
                  fillColor: Colors.white,
                  borderColor: Colors.grey,
                  textColor: Colors.black,
                  subTextColor: Colors.grey,
                  isDark: false,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('チームとオーダー登録'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('チーム名'), findsOneWidget);
      expect(find.byIcon(Icons.shield), findsOneWidget);
    });

    testWidgets('TeamRegistrationCategoryStepにおいて 部門一覧が表示されること', (
      tester,
    ) async {
      String major = '小学生';
      String minor = '低学年';
      String matchType = '団体戦（5人制）';
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TeamRegistrationCategoryStep(
              selectedMajorCategory: major,
              selectedMinorCategory: minor,
              selectedCategory: '小学生低学年の部',
              matchType: matchType,
              showExtraMajorCategories: false,
              showExtraMatchTypes: false,
              themeColors: themeColors,
              onMajorCategoryChanged: (val) => major = val,
              onMinorCategoryChanged: (val) => minor = val,
              onMatchTypeChanged: (val) => matchType = val,
              onToggleExtraMajorCategories: () {},
              onToggleExtraMatchTypes: () {},
            ),
          ),
        ),
      );

      expect(find.text('小学生低学年の部'), findsOneWidget);
      expect(find.text('小学生'), findsOneWidget);
      expect(find.text('低学年 (1-4年)'), findsOneWidget);
      expect(find.text('団体戦（5人制）'), findsOneWidget);
    });

    testWidgets('TeamRegistrationConfirmStepにおいて チーム一覧が適切に描画されること', (
      tester,
    ) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');
      final teams = [
        TeamModel(
          id: 't1',
          tournamentId: 'tourney_1',
          category: '小学生高学年の部',
          teamName: '白龍会A',
          matchType: '団体戦（5人制）',
          playerNames: ['白1', '白2', '白3', '白4', '白5'],
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(extensions: [themeColors]),
          home: Scaffold(
            body: TeamRegistrationConfirmStep(
              registeredTeamsAsync: AsyncValue.data(teams),
              playerCount: 5,
              selectedCategory: '小学生高学年の部',
              teamName: '赤心館A',
              matchType: '団体戦（5人制）',
              tempSelectedPlayers: const {},
              themeColors: themeColors,
              onEditTeam: (_) {},
              onDeleteTeam: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('登録済みチーム (1)'), findsOneWidget);
      expect(find.text('白龍会A'), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('TeamRegistrationPlayerSelectBottomSheetにおいて 選手選択シートが開くこと', (
      tester,
    ) async {
      final p1 = PlayerModel(
        id: 'p1',
        lastName: '山田',
        firstName: '太郎',
        lastNameKana: 'ヤマダ',
        firstNameKana: 'タロウ',
        grade: 5,
        isBeginner: false,
      );
      final p2 = PlayerModel(
        id: 'p2',
        lastName: '佐藤',
        firstName: '花子',
        lastNameKana: 'サトウ',
        firstNameKana: 'ハナコ',
        grade: 4,
        isBeginner: false,
      );
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => TeamRegistrationPlayerSelectBottomSheet.show(
                    context: context,
                    index: 0,
                    players: [p1, p2],
                    posNames: ['先鋒', '中堅', '大将'],
                    tempSelectedPlayers: {},
                    selectedMajorCategory: '小学生',
                    selectedMinorCategory: '低学年',
                    themeColors: themeColors,
                  ),
                  child: const Text('Open Sheet'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('選手の選択 (先鋒)'), findsWidgets);
      expect(find.text('山田 太郎'), findsOneWidget);
      expect(find.text('佐藤 花子'), findsOneWidget);

      await tester.tap(find.text('山田 太郎'));
      await tester.pumpAndSettle();

      expect(find.text('山田 太郎'), findsNothing);
    });

    testWidgets('TeamRegistrationSelectionCardにおいて カード表示とタップが動作すること', (
      tester,
    ) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TeamRegistrationSelectionCard(
              name: '佐藤 太郎',
              subtitle: '三段 / 20歳',
              isUsed: false,
              usedPos: '',
              isDark: false,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('佐藤 太郎'), findsOneWidget);
      expect(find.text('三段 / 20歳'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);

      await tester.tap(find.text('佐藤 太郎'));
      expect(tapped, isTrue);
    });

    testWidgets('TeamRegistrationStickyBottomBarにおいて 各ページのボタンが正しく描画されること', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            theme: ThemeData.light().copyWith(extensions: [themeColors]),
            home: Scaffold(
              bottomNavigationBar: TeamRegistrationStickyBottomBar(
                currentPage: 0,
                editingTeamId: null,
                themeColors: themeColors,
                onPrevious: () {},
                onPrimaryAction: () {},
                onFinishToRules: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('次へ進む'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new), findsNothing);
    });
  });
}
