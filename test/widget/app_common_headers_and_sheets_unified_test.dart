import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_detail_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_representative_modal_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_share_options_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/settings/settings_ui_tiles.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_settings_bottom_sheet.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_search_header.dart';
import 'package:kendo_os/shared/widgets/app_switch.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('[Widget] アプリ共通 検索ヘッダー・ボトムシート・iOSスイッチ統合検証テスト', () {
    testWidgets('SettingsSwitchTile が AppSwitch を内包しタップでコールバックが発火すること', (
      tester,
    ) async {
      bool currentValue = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
          ),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SettingsSwitchTile(
                  title: '通知設定',
                  icon: Icons.notifications,
                  iconBgColor: AppKendoColors.indigo,
                  value: currentValue,
                  onChanged: (val) {
                    setState(() {
                      currentValue = val;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('通知設定'), findsOneWidget);
      expect(find.byType(AppSwitch), findsOneWidget);

      await tester.tap(find.byType(SettingsSwitchTile));
      await tester.pumpAndSettle();

      expect(currentValue, isTrue);
    });

    testWidgets('ViewerSettingsBottomSheet がクラッシュせず正常に描画されること', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            theme: ThemeData(
              extensions: [
                AppThemeColors.ofMode(isDark: false, mode: 'normal'),
              ],
            ),
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      showAppBottomSheet(
                        context: context,
                        builder: (_) => const ViewerSettingsBottomSheet(),
                      );
                    },
                    child: const Text('Open Viewer Settings'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Viewer Settings'));
      await tester.pumpAndSettle();

      expect(find.text('表示設定'), findsOneWidget);
      expect(find.text('省エネモード'), findsOneWidget);
      expect(find.text('背景アニメーション停止'), findsOneWidget);
      expect(find.byType(AppSwitch), findsOneWidget);
    });

    testWidgets('CategoryRuleDetailBottomSheet がクラッシュせず正常にレンダリングされること', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData(
              extensions: [
                AppThemeColors.ofMode(isDark: false, mode: 'normal'),
              ],
            ),
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      CategoryRuleDetailBottomSheet.show(
                        context,
                        categoryName: '小学生の部',
                        ruleSet: const CategoryRuleSet(
                          matchType: '団体戦',
                          normalRule: MatchRule(),
                        ),
                        isDark: false,
                      );
                    },
                    child: const Text('Open Sheet'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('小学生の部 のルール設定'), findsOneWidget);
      expect(find.text('閉じる'), findsOneWidget);
    });

    testWidgets('MatchRepresentativeModalBottomSheet がクラッシュせず正常に描画されること', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData(
              extensions: [
                AppThemeColors.ofMode(isDark: false, mode: 'normal'),
              ],
            ),
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      MatchRepresentativeModalBottomSheet.show(
                        context,
                        match: const MatchModel(
                          id: 'match_1',
                          tournamentId: 'tour_1',
                          matchType: '団体戦',
                          redName: '赤チーム',
                          whiteName: '白チーム',
                        ),
                        rTeam: '赤チーム',
                        wTeam: '白チーム',
                        redPlayers: ['先鋒 赤', '中堅 赤'],
                        whitePlayers: ['先鋒 白', '中堅 白'],
                      );
                    },
                    child: const Text('Open Modal'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.text('代表戦の準備'), findsOneWidget);
    });

    testWidgets('MatchShareOptionsBottomSheet がクラッシュせず正常に描画されること', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData(
              extensions: [
                AppThemeColors.ofMode(isDark: false, mode: 'normal'),
              ],
            ),
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      MatchShareOptionsBottomSheet.show(
                        context,
                        match: const MatchModel(
                          id: 'match_1',
                          tournamentId: 'tour_1',
                          matchType: '団体戦',
                          redName: '赤チーム',
                          whiteName: '白チーム',
                        ),
                      );
                    },
                    child: const Text('Open Share'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Share'));
      await tester.pumpAndSettle();

      expect(find.text('観戦の共有方法を選択'), findsOneWidget);
    });

    testWidgets('検索ヘッダーにおいて検索ヒントテキスト・アイコン・クリア・キャンセルが正しく動作すること', (
      WidgetTester tester,
    ) async {
      String currentQuery = '';
      bool isClosed = false;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              theme: ThemeData(
                extensions: [
                  AppThemeColors.ofMode(isDark: false, mode: 'normal'),
                ],
              ),
              home: Scaffold(
                body: AppSearchHeader(
                  searchQuery: currentQuery,
                  onSearchQueryChanged: (val) {
                    setState(() {
                      currentQuery = val;
                    });
                  },
                  onClose: () => isClosed = true,
                ),
              ),
            );
          },
        ),
      );

      expect(find.text('選手名・チーム名で検索...'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.text('キャンセル'), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsNothing);

      final textField = find.byType(AppTextField);
      await tester.enterText(textField, '山田');
      await tester.pumpAndSettle();

      expect(currentQuery, '山田');
      expect(find.byIcon(Icons.cancel), findsOneWidget);

      await tester.tap(find.byIcon(Icons.cancel));
      await tester.pumpAndSettle();

      expect(currentQuery, '');
      expect(find.byIcon(Icons.cancel), findsNothing);

      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();
      expect(isClosed, isTrue);
    });
  });
}
