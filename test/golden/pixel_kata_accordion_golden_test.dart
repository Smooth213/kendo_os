import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_list_tile_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_match_group_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/safe_timeline_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const kataRule = MatchRule(
    isKataMatch: true,
    matchTimeMinutes: 0.0,
    hasHantei: true,
  );

  final kataMatch = MatchModel(
    id: 'golden_kata_accordion_01',
    tournamentId: 't_kata',
    matchType: '日本剣道形',
    category: '形の部',
    status: 'finished',
    groupName: '道上剣友会 vs 修道館',
    redName: '道上剣友会 : 皿田 脩人・塚本 大道',
    whiteName: '修道館 : 佐藤 健・鈴木 一郎',
    redScore: 3,
    whiteScore: 0,
    rule: kataRule,
    events: [
      ScoreEvent(
        id: 'ev_kata_hantei_1',
        side: Side.red,
        isHantei: true,
        redFlags: 3,
        whiteFlags: 0,
        timestamp: DateTime(2026, 10, 15, 10, 0),
      ),
    ],
  );

  Widget buildKataAccordionTestWidget({required bool isDark}) {
    final themeColors = AppThemeColors.ofMode(isDark: isDark, mode: 'operate');

    return ProviderScope(
      overrides: [
        matchListProvider.overrideWith((ref) => [kataMatch]),
        customTeamNamesProvider.overrideWith((ref) => Stream.value(['道上剣友会'])),
        permissionProvider.overrideWith(
          (ref) => const PermissionState(canManageTournament: true),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(
          brightness: isDark ? Brightness.dark : Brightness.light,
          extensions: [themeColors],
        ),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                TimelineMatchGroupCard(
                  groupId: 'grp_kata_1',
                  groupList: [kataMatch],
                  groupComments: const [],
                  categoryName: '形の部',
                  teamName: '道上剣友会',
                  label: '第1試合場 第1試合目',
                  isReadOnlyUI: false,
                  canManageTournamentUI: true,
                  isDark: isDark,
                  tournamentId: 't_kata',
                  ownTeams: const ['道上剣友会'],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  group('[Golden] 剣道形アコーディオン展開および折り畳み ピクセル整合性テスト', () {
    testWidgets('折り畳み状態において剣道形の対戦枠がコンパクトかつ美しく描画されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildKataAccordionTestWidget(isDark: false));
      await tester.pumpAndSettle();

      expect(find.byType(TimelineMatchGroupCard), findsOneWidget);
      expect(find.text('道上剣友会'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ダークモードにおいて展開状態の打太刀仕太刀連名およびスコアが明瞭に描画されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildKataAccordionTestWidget(isDark: true));
      await tester.pumpAndSettle();

      // カードをタップしてアコーディオンを展開
      await tester.tap(find.byType(TimelineMatchGroupCard));
      await tester.pumpAndSettle();

      expect(find.byType(MatchListTileCard), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
