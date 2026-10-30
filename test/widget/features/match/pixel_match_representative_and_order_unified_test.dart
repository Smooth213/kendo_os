import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_setup_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_order_step.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_view_state_provider.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/domain/entities/settings_model.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/scoreboard.dart';

class _MockSettingsNotifier extends SettingsNotifier {
  @override
  SettingsModel build() =>
      const SettingsModel(securityLevel: 1, enableLiquidGlass: false);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Golden] 代表戦突入スコアボードと団体戦オーダー編成統合テスト', () {
    // =========================================================================
    // 1. 代表戦（無制限一本勝負）スコアボード配置と解像度適応
    // =========================================================================
    testWidgets('代表戦（無制限一本勝負）スコアボードが複数解像度（1024x768, 1280x800）で破綻なく描画されること', (
      WidgetTester tester,
    ) async {
      final resolutions = [const Size(1024, 768), const Size(1280, 800)];

      for (final res in resolutions) {
        tester.view.physicalSize = res;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final daihyoMatch = MatchModel(
          id: 'match_rep_golden_${res.width.toInt()}',
          tournamentId: 't_rep_01',
          category: '高校団体の部',
          matchType: '代表戦',
          status: 'in_progress',
          redName: '剣道太郎 (代表)',
          whiteName: '武道次郎 (代表)',
          redScore: 0,
          whiteScore: 0,
          order: 99.0,
          matchTimeMinutes: 0.0,
        );

        final themeColors = AppThemeColors.ofMode(
          isDark: false,
          mode: 'normal',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              settingsProvider.overrideWith(() => _MockSettingsNotifier()),
              matchViewStateUserIdProvider.overrideWith((ref) => 'user_golden'),
              matchListProvider.overrideWithValue([daihyoMatch]),
              scoreboardMatchIdProvider.overrideWithValue(daihyoMatch.id),
              scoreboardMatchProvider.overrideWithValue(daihyoMatch),
              scoreboardNameTapProvider.overrideWithValue((side) {}),
            ],
            child: MaterialApp(
              theme: ThemeData.light().copyWith(extensions: [themeColors]),
              home: const Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 1000,
                    height: 400,
                    child: MatchScoreboard(),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pump();

        expect(find.byType(MatchScoreboard), findsOneWidget);
        expect(find.text('剣道太郎 (代表)'), findsOneWidget);
        expect(find.text('武道次郎 (代表)'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    // =========================================================================
    // 2. 団体戦オーダー編成（3〜11人制）ピクセル完全性
    // =========================================================================
    Widget buildOrderStepWrapper({
      required int basePlayerCount,
      required int substituteCount,
      required bool isDark,
      required Map<int, String> selectedPlayers,
      String matchType = '7人制',
    }) {
      final basePosNames = MatchFormatSetupHelper.generatePositions(
        basePlayerCount,
      );
      final bool isMoreThan7 = matchType.contains('それ以上');
      final posNames = isMoreThan7
          ? basePosNames
          : [...basePosNames, ...List.filled(substituteCount, '補欠')];
      final totalPlayerCount = isMoreThan7
          ? basePlayerCount
          : (basePlayerCount + substituteCount);

      final themeColors = AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
      final dummyPlayers = [
        PlayerModel(
          id: 'p1',
          lastName: '佐藤',
          firstName: '健太',
          lastNameKana: 'サトウ',
          firstNameKana: 'ケンタ',
          grade: 6,
        ),
        PlayerModel(
          id: 'p2',
          lastName: '鈴木',
          firstName: '一郎',
          lastNameKana: 'スズキ',
          firstNameKana: 'イチロウ',
          grade: 5,
        ),
        PlayerModel(
          id: 'p3',
          lastName: '高橋',
          firstName: '大介',
          lastNameKana: 'タカハシ',
          firstNameKana: 'ダイスケ',
          grade: 6,
        ),
      ];

      return ProviderScope(
        child: MaterialApp(
          theme: isDark
              ? ThemeData.dark().copyWith(extensions: [themeColors])
              : ThemeData.light().copyWith(extensions: [themeColors]),
          home: Scaffold(
            body: TeamRegistrationOrderStep(
              playerCount: totalPlayerCount,
              posNames: posNames,
              players: dummyPlayers,
              teamNameController: TextEditingController(text: '錬心館道場 Aチーム'),
              teamNameFocusNode: FocusNode(),
              teamNameSuggestions: const ['錬心館道場 Aチーム', '錬心館道場 Bチーム'],
              tempSelectedPlayers: selectedPlayers,
              substituteCount: substituteCount,
              matchType: matchType,
              themeColors: themeColors,
              onSelectPlayer: (_) {},
              onRemoveSubstitute: (_) {},
              onAddSubstitute: () {},
              onAddPlayerSlot: () {},
              onRemovePlayerSlot: (_) {},
            ),
          ),
        ),
      );
    }

    testWidgets('7人制オーダー（補欠2名含む計9枠）がスマホ縦(390x844)で破綻なく描画されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildOrderStepWrapper(
          basePlayerCount: 7,
          substituteCount: 2,
          isDark: true,
          selectedPlayers: {0: 'p1', 1: 'p2'},
          matchType: '7人制',
        ),
      );
      await tester.pump();

      expect(find.text('先鋒'), findsOneWidget);
      expect(find.text('中堅'), findsOneWidget);
      expect(find.text('大将'), findsOneWidget);
      expect(find.text('補欠'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('11人制（7人より多いカスタム）オーダーがタブレット横(1024x768)で破綻なく描画されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildOrderStepWrapper(
          basePlayerCount: 11,
          substituteCount: 0,
          isDark: false,
          selectedPlayers: {0: 'p1'},
          matchType: '7人制より多い(カスタム)',
        ),
      );
      await tester.pump();

      expect(find.text('先鋒'), findsOneWidget);
      expect(find.text('中堅'), findsOneWidget);
      expect(find.text('大将'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
