import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bulk_rule_edit_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_command_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('BulkRuleEditSheet Widget Tests', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    testWidgets(
      '1. Render options, checkboxes, filters, and update successfully',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        // 1. Prepare matches data
        final matches = [
          const MatchModel(
            id: 'match_1',
            matchType: '個人戦',
            redName: '山田 太郎',
            whiteName: '佐藤 次郎',
            category: '小学生低学年の部',
            status: 'waiting',
          ),
          const MatchModel(
            id: 'match_2',
            matchType: '団体戦',
            redName: '千代田A',
            whiteName: '中央B',
            category: '中学生の部',
            groupName: '千代田A vs 中央B',
            status: 'waiting',
          ),
          const MatchModel(
            id: 'match_3',
            matchType: '個人戦',
            redName: '鈴木 三郎',
            whiteName: '高橋 四郎',
            category: '小学生低学年の部',
            status: 'waiting',
          ),
        ];

        // 2. Set up Firestore mock documents so _getMatch finds them
        for (final m in matches) {
          await fakeFirestore
              .collection('organizations')
              .doc('test_dojo')
              .collection('tournaments')
              .doc('bunaiksen_20260724')
              .collection('matches')
              .doc(m.id)
              .set(m.toJson());
        }

        List<String> lastUpdatedIds = [];
        MatchRule? lastAppliedRule;

        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final themeColors = AppThemeColors.ofMode(
          isDark: false,
          mode: 'bunaiksen',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentDojoIdProvider.overrideWith((ref) => 'test_dojo'),
              firestoreProvider.overrideWithValue(fakeFirestore),
              sharedPreferencesProvider.overrideWithValue(prefs),
              matchCommandProvider.overrideWith((ref) {
                return _MockMatchCommandService(ref, (ids, rule) {
                  lastUpdatedIds = ids;
                  lastAppliedRule = rule;
                });
              }),
            ],
            child: MaterialApp(
              theme: ThemeData.light().copyWith(extensions: [themeColors]),
              home: Scaffold(
                body: Builder(
                  builder: (context) {
                    return Center(
                      child: ElevatedButton(
                        onPressed: () {
                          showBulkRuleEditSheet(
                            context,
                            'bunaiksen_20260724',
                            matches,
                            isBunaiksen: true,
                          );
                        },
                        child: const Text('Open Sheet'),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        // 3. Open BulkRuleEditSheet
        await tester.tap(find.text('Open Sheet'));
        await tester.pumpAndSettle();

        // 4. Verify title and dynamic select lists
        expect(find.text('⚡ ルール一括変更'), findsOneWidget);
        expect(find.text('現在 3 件を選択中 / 全 3 件中'), findsOneWidget);

        expect(find.text('[小学生低学年の部] 山田 太郎 vs 佐藤 次郎'), findsOneWidget);
        expect(find.text('[中学生の部] 千代田A vs 中央B'), findsOneWidget);
        expect(find.text('[小学生低学年の部] 鈴木 三郎 vs 高橋 四郎'), findsOneWidget);

        // 5. Select Category Filter: 小学生低学年の部
        await tester.tap(find.text('すべて').first);
        await tester.pumpAndSettle();

        await tester.tap(find.text('小学生低学年の部').last);
        await tester.pumpAndSettle();

        // Verify count decreases to 2
        expect(find.text('現在 2 件を選択中 / 全 2 件中'), findsOneWidget);
        expect(find.text('[小学生低学年の部] 山田 太郎 vs 佐藤 次郎'), findsOneWidget);
        expect(find.text('[小学生低学年の部] 鈴木 三郎 vs 高橋 四郎'), findsOneWidget);
        expect(find.text('[中学生の部] 千代田A vs 中央B'), findsNothing);

        // 6. Manual Override: Uncheck one match
        await tester.tap(find.text('[小学生低学年の部] 鈴木 三郎 vs 高橋 四郎'));
        await tester.pumpAndSettle();

        expect(find.text('現在 1 件を選択中 / 全 2 件中'), findsOneWidget);

        // 7. Adjust rules inside the sheet (Set Match Time to 2分 & Toggle Hantei ON)
        await tester.tap(find.text('2分').first);
        await tester.pumpAndSettle();

        await tester.tap(find.text('判定の適用'));
        await tester.pumpAndSettle();

        // 8. Apply Rules
        await tester.tap(find.text('選択した 1 件にルールを適用する'));
        await tester.pumpAndSettle();

        // Verify sheet closes and correct matches are updated with correct rules
        expect(lastUpdatedIds, ['match_1']);
        expect(lastAppliedRule, isNotNull);
        expect(lastAppliedRule!.matchTimeMinutes, 2.0);
        expect(lastAppliedRule!.hasHantei, true);
      },
    );
  });
}

class _MockMatchCommandService extends MatchCommandService {
  final void Function(List<String> ids, MatchRule rule) onBulkUpdate;

  _MockMatchCommandService(super.ref, this.onBulkUpdate);

  @override
  Future<void> bulkUpdateMatchRules({
    required List<String> targetMatchIds,
    required MatchRule newRule,
  }) async {
    onBulkUpdate(targetMatchIds, newRule);
  }
}
