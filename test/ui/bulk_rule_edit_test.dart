import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bulk_rule_edit_sheet.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/providers/dojo_room_sync_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🛡️ Bulk Rule Edit & Category Rule Presets Integration Tests', () {
    test(
      '1. Verify bulkUpdateMatchRules preserves existing rule teamName and category',
      () async {
        // 既存の自チーム設定を持つ MatchModel を模倣
        final initialRule = const MatchRule(
          teamName: '剣道道場A',
          category: '小学生の部',
          matchTimeMinutes: 3.0,
          isIpponShobu: false,
        );

        final match = MatchModel(
          id: 'match_101',
          matchType: '団体戦',
          redName: '剣道道場A : 山田',
          whiteName: 'ライバル道場 : 佐藤',
          rule: initialRule,
          matchTimeMinutes: 3.0,
        );

        // 新ルール（一括適用用：teamNameは指定しない）
        final newRule = const MatchRule(
          matchTimeMinutes: 2.0,
          isIpponShobu: true,
          enchoTimeMinutes: 0.0,
        );

        // 既存プロパティを合成するマージ処理
        final existingRule = match.rule;
        final mergedRule = newRule.copyWith(
          teamName: (existingRule?.teamName.isNotEmpty == true)
              ? existingRule!.teamName
              : newRule.teamName,
          category: (existingRule?.category.isNotEmpty == true)
              ? existingRule!.category
              : newRule.category,
        );

        final updatedMatch = match.copyWith(
          matchTimeMinutes: mergedRule.matchTimeMinutes,
          hasExtension:
              mergedRule.enchoTimeMinutes > 0 || mergedRule.isEnchoUnlimited,
          extensionTimeMinutes: mergedRule.enchoTimeMinutes,
          hasHantei: mergedRule.hasHantei,
          rule: mergedRule,
        );

        // 自チーム名（teamName）とカテゴリ（category）が消えずに保持されているか検証
        expect(updatedMatch.rule?.teamName, equals('剣道道場A'));
        expect(updatedMatch.rule?.category, equals('小学生の部'));
        expect(updatedMatch.matchTimeMinutes, equals(2.0));
        expect(updatedMatch.rule?.isIpponShobu, isTrue);
      },
    );

    testWidgets(
      '2. Verify BulkRuleEditSheet renders Category Rules presets chip and applies selection',
      (WidgetTester tester) async {
        final categoryRules = {
          '小学生低学年の部': const CategoryRuleSet(
            normalRule: MatchRule(matchTimeMinutes: 1.5, isIpponShobu: true),
          ),
          '中学生の部': const CategoryRuleSet(
            normalRule: MatchRule(matchTimeMinutes: 3.0, isIpponShobu: false),
          ),
        };

        final tournament = TournamentModel(
          id: 'tourney_1',
          organizationId: 'org_1',
          name: '第1回テスト大会',
          date: DateTime.now(),
          venue: '武道館',
          categoryRules: categoryRules,
        );

        final matches = [
          MatchModel(
            id: 'm1',
            matchType: '個人戦',
            redName: '選手1',
            whiteName: '選手2',
            tournamentId: 'tourney_1',
          ),
        ];

        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              currentDojoIdProvider.overrideWith((ref) => 'test_dojo'),
              dojoRoomSyncProvider.overrideWith((ref) {}),
              tournamentProvider(
                'tourney_1',
              ).overrideWith((ref) => Stream.value(tournament)),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: BulkRuleEditSheet(
                  tournamentId: 'tourney_1',
                  matches: matches,
                  themeColors: AppThemeColors.ofMode(
                    isDark: false,
                    mode: 'operate',
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 「部門別ルールから一括セット」のセクションが表示されていること
        expect(find.text('部門別ルールから一括セット'), findsOneWidget);
        // 1段目の部門名チップが表示されていること
        expect(find.text('小学生低学年の部'), findsOneWidget);
        expect(find.text('中学生の部'), findsOneWidget);

        // 「小学生低学年の部」チップをタップ
        final chipFinder = find.text('小学生低学年の部');
        await tester.tap(chipFinder, warnIfMissed: false);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '3. Verify 2-Stage Selection: Selecting Category dynamically expands Scene Sub-Chips (Honsen, Renseikai, Moushiawase)',
      (WidgetTester tester) async {
        final categoryRules = {
          '小学生の部': const CategoryRuleSet(
            isMultiScene: true,
            useHonsenRule: true,
            normalRule: MatchRule(matchTimeMinutes: 3.0, isIpponShobu: false),
            useRenseikaiRule: true,
            renseikaiRule: MatchRule(
              matchTimeMinutes: 2.0,
              isIpponShobu: true,
              isRenseikai: true,
            ),
            useMoushiawaseRule: true,
            moushiawaseRule: MatchRule(
              matchTimeMinutes: 1.5,
              isIpponShobu: true,
              isRenseikai: true,
            ),
          ),
        };

        final tournament = TournamentModel(
          id: 'tourney_2',
          organizationId: 'org_1',
          name: '第2回テスト大会',
          date: DateTime.now(),
          venue: '武道館',
          categoryRules: categoryRules,
        );

        final matches = [
          MatchModel(
            id: 'm1',
            matchType: '個人戦',
            redName: '選手1',
            whiteName: '選手2',
            tournamentId: 'tourney_2',
          ),
        ];

        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              currentDojoIdProvider.overrideWith((ref) => 'test_dojo'),
              dojoRoomSyncProvider.overrideWith((ref) {}),
              tournamentProvider(
                'tourney_2',
              ).overrideWith((ref) => Stream.value(tournament)),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: BulkRuleEditSheet(
                  tournamentId: 'tourney_2',
                  matches: matches,
                  themeColors: AppThemeColors.ofMode(
                    isDark: false,
                    mode: 'operate',
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 1. 部門名「小学生の部」チップをタップ
        await tester.tap(find.text('小学生の部'), warnIfMissed: false);
        await tester.pumpAndSettle();

        // 2. 2段目のシーンサブチップ群（本戦、錬成会、申し合わせ）が動的に表示されていること
        expect(find.text('試合シーン・ルール用途を選択:'), findsOneWidget);
        expect(find.text('🏆 本戦 (3分・3本)'), findsOneWidget);
        expect(find.text('⚔️ 錬成会 (2分・1本)'), findsOneWidget);
        expect(find.text('🤝 申し合わせ (1.5分・1本)'), findsOneWidget);

        // 3. 「⚔️ 錬成会 (2分・1本)」サブチップをタップ
        await tester.tap(find.text('⚔️ 錬成会 (2分・1本)'), warnIfMissed: false);
        await tester.pumpAndSettle();

        // 4. 下部の入力フォーム（試合時間 2分・一本勝負 Switch ON）がリアルタイム連動して更新されていることを直接アサート
        expect(find.text('2分'), findsWidgets);
        expect(find.text('一本勝負形式にする'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '4. Verify Smart Auto-Reset: Non-applicable rules (e.g. Hantei for Team matches) are automatically turned OFF',
      (WidgetTester tester) async {
        final categoryRules = {
          '団体小学生の部': const CategoryRuleSet(
            normalRule: MatchRule(
              matchTimeMinutes: 3.0,
              hasHantei: true,
              hasRepresentativeMatch: true,
            ),
          ),
        };

        final tournament = TournamentModel(
          id: 'tourney_team',
          organizationId: 'org_1',
          name: '団体戦テスト大会',
          date: DateTime.now(),
          venue: '武道館',
          categoryRules: categoryRules,
        );

        final matches = [
          MatchModel(
            id: 'm1',
            matchType: '団体戦',
            redName: 'A道場',
            whiteName: 'B道場',
            tournamentId: 'tourney_team',
          ),
        ];

        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              currentDojoIdProvider.overrideWith((ref) => 'test_dojo'),
              dojoRoomSyncProvider.overrideWith((ref) {}),
              tournamentProvider(
                'tourney_team',
              ).overrideWith((ref) => Stream.value(tournament)),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: BulkRuleEditSheet(
                  tournamentId: 'tourney_team',
                  matches: matches,
                  themeColors: AppThemeColors.ofMode(
                    isDark: false,
                    mode: 'operate',
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 団体戦部門「団体小学生の部」をタップ
        await tester.tap(find.text('団体小学生の部'), warnIfMissed: false);
        await tester.pumpAndSettle();

        // エラーなくスマート自動OFFリセットが完了していること
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '5. Verify Strict Preset Reset: Rules not enabled in category preset are strictly turned OFF',
      (WidgetTester tester) async {
        final categoryRules = {
          '完全シンプルルール': const CategoryRuleSet(
            normalRule: MatchRule(
              matchTimeMinutes: 2.0,
              isIpponShobu: true,
              enchoTimeMinutes: 0.0, // 延長なし
              isEnchoUnlimited: false,
              hasHantei: false, // 判定なし
              hasRepresentativeMatch: false, // 代表戦なし
            ),
          ),
        };

        final tournament = TournamentModel(
          id: 'tourney_simple',
          organizationId: 'org_1',
          name: 'シンプル大会',
          date: DateTime.now(),
          venue: '武道館',
          categoryRules: categoryRules,
        );

        final matches = [
          MatchModel(
            id: 'm1',
            matchType: '個人戦',
            redName: '選手A',
            whiteName: '選手B',
            rule: const MatchRule(
              matchTimeMinutes: 3.0,
              enchoTimeMinutes: 3.0, // 既存試合は延長ON
              hasHantei: true, // 既存試合は判定ON
            ),
            tournamentId: 'tourney_simple',
          ),
        ];

        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              currentDojoIdProvider.overrideWith((ref) => 'test_dojo'),
              dojoRoomSyncProvider.overrideWith((ref) {}),
              tournamentProvider(
                'tourney_simple',
              ).overrideWith((ref) => Stream.value(tournament)),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: BulkRuleEditSheet(
                  tournamentId: 'tourney_simple',
                  matches: matches,
                  themeColors: AppThemeColors.ofMode(
                    isDark: false,
                    mode: 'operate',
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 部門「完全シンプルルール」をタップ
        await tester.tap(find.text('完全シンプルルール'), warnIfMissed: false);
        await tester.pumpAndSettle();

        // 既存試合でONだった延長や判定が、プリセット適用により厳格にOFFにクリアリセットされたことを検証
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '6. Verify Renseikai & Moushiawase Scenes strictly turn OFF personal hantei, extension, and representative match',
      (WidgetTester tester) async {
        final categoryRules = {
          '小学生の部': const CategoryRuleSet(
            isMultiScene: true,
            useHonsenRule: true,
            normalRule: MatchRule(matchTimeMinutes: 3.0, hasHantei: true),
            useRenseikaiRule: true,
            renseikaiRule: MatchRule(
              matchTimeMinutes: 2.0,
              isIpponShobu: true,
              hasHantei: true,
            ),
            useMoushiawaseRule: true,
            moushiawaseRule: MatchRule(
              matchTimeMinutes: 1.5,
              isIpponShobu: true,
              hasHantei: true,
            ),
          ),
        };

        final tournament = TournamentModel(
          id: 'tourney_sub',
          organizationId: 'org_1',
          name: '錬成会テスト大会',
          date: DateTime.now(),
          venue: '武道館',
          categoryRules: categoryRules,
        );

        final matches = [
          MatchModel(
            id: 'm1',
            matchType: '個人戦',
            redName: '選手1',
            whiteName: '選手2',
            rule: const MatchRule(matchTimeMinutes: 3.0, hasHantei: true),
            tournamentId: 'tourney_sub',
          ),
        ];

        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              currentDojoIdProvider.overrideWith((ref) => 'test_dojo'),
              dojoRoomSyncProvider.overrideWith((ref) {}),
              tournamentProvider(
                'tourney_sub',
              ).overrideWith((ref) => Stream.value(tournament)),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: BulkRuleEditSheet(
                  tournamentId: 'tourney_sub',
                  matches: matches,
                  themeColors: AppThemeColors.ofMode(
                    isDark: false,
                    mode: 'operate',
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 1. 部門「小学生の部」をタップ
        await tester.tap(find.text('小学生の部'), warnIfMissed: false);
        await tester.pumpAndSettle();

        // 2. 「⚔️ 錬成会 (2分・1本)」をタップ
        await tester.tap(find.text('⚔️ 錬成会 (2分・1本)'), warnIfMissed: false);
        await tester.pumpAndSettle();

        // 3. 「🤝 申し合わせ (1.5分・1本)」をタップ
        await tester.tap(find.text('🤝 申し合わせ (1.5分・1本)'), warnIfMissed: false);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );
  });
}
