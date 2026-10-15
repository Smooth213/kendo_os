import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_match_group_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const match = MatchModel(
    id: 'golden_slidable_m1',
    tournamentId: 'tour_slidable',
    matchType: '先鋒',
    category: '一般団体の部',
    status: 'finished',
    groupName: '道上剣友会 vs 洗心道場',
    redName: '道上剣友会 : 皿田',
    whiteName: '洗心道場 : 相手選手',
    redScore: 2,
    whiteScore: 0,
  );

  Widget buildSlidableTestWidget({required bool isDark}) {
    final themeColors = AppThemeColors.ofMode(isDark: isDark, mode: 'operate');

    return ProviderScope(
      overrides: [
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
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 32.0,
            ),
            child: SlidableAutoCloseBehavior(
              child: ListView(
                children: [
                  TimelineMatchGroupCard(
                    groupId: 'grp_slidable_1',
                    groupList: const [match],
                    groupComments: const [],
                    categoryName: '一般団体の部',
                    teamName: '道上剣友会',
                    label: '第2試合場 第1試合目',
                    isReadOnlyUI: false,
                    canManageTournamentUI: true,
                    isDark: isDark,
                    tournamentId: 'tour_slidable',
                    ownTeams: const ['道上剣友会'],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('[Golden] タイムラインスワイプアクション露出状態 ピクセル整合性テスト', () {
    testWidgets('カードを右スワイプした際に次戦追加・編集・削除の3要素が白飛びせず明瞭に露出すること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildSlidableTestWidget(isDark: false));
      await tester.pumpAndSettle();

      final cardFinder = find.byType(TimelineMatchGroupCard);
      expect(cardFinder, findsOneWidget);

      await tester.drag(cardFinder, const Offset(-300, 0));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('ダークモードにおいてスワイプアクションのアイコンおよび背景がコントラスト高く描画されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildSlidableTestWidget(isDark: true));
      await tester.pumpAndSettle();

      final cardFinder = find.byType(TimelineMatchGroupCard);
      await tester.drag(cardFinder, const Offset(-300, 0));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
