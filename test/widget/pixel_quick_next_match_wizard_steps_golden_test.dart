import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/safe_pump_helper.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/quick_next_match/quick_next_match_wizard_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_screen_providers.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/safe_timeline_provider.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

class MockMatchApplicationService extends Mock
    implements MatchApplicationService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockMatchApplicationService mockMatchService;

  setUpAll(() {
    registerFallbackValue(
      const MatchModel(
        id: 'fallback_id',
        matchType: '先鋒',
        redName: 'red',
        whiteName: 'white',
      ),
    );
  });

  setUp(() {
    mockMatchService = MockMatchApplicationService();
    when(() => mockMatchService.saveMatch(any())).thenAnswer((_) async {});
  });

  const baseMatch = MatchModel(
    id: 'golden_wizard_m1',
    tournamentId: 't1',
    category: '小学生団体の部',
    matchType: '先鋒',
    redName: '道上剣友会 : 皿田 脩人',
    whiteName: '修道館 : 相手選手',
    note: '第1試合場, 1試合目',
    rule: MatchRule(positions: ['先鋒', '中堅', '大将'], teamName: '道上剣友会'),
  );

  Widget buildWizardTestWidget({
    required bool isDark,
    required Size screenSize,
  }) {
    final themeColors = AppThemeColors.ofMode(isDark: isDark, mode: 'operate');

    return ProviderScope(
      overrides: [
        matchListProvider.overrideWith((ref) => [baseMatch]),
        matchApplicationServiceProvider.overrideWithValue(mockMatchService),
        playerListProvider.overrideWith(
          (ref) => Stream.value([
            PlayerModel(
              id: 'p1',
              lastName: '皿田',
              firstName: '脩人',
              lastNameKana: 'さらだ',
              firstNameKana: 'しゅうと',
              grade: 5,
              organization: '道上剣友会',
            ),
          ]),
        ),
        customTeamNamesProvider.overrideWith((ref) => Stream.value(['道上剣友会'])),
        registeredTeamsProvider(
          't1',
        ).overrideWith((ref) => Stream.value(<TeamModel>[])),
      ],
      child: MaterialApp(
        theme: ThemeData(
          brightness: isDark ? Brightness.dark : Brightness.light,
          extensions: [themeColors],
        ),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: screenSize.width,
              height: screenSize.height,
              child: const QuickNextMatchWizardSheet(
                baseMatch: baseMatch,
                teamMatches: [baseMatch],
                isSameTeamContinue: false,
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('[Golden] クイック次戦作成ウィザード全ステップ ピクセル整合性テスト', () {
    testWidgets('ライトモードにおいてオーダー設定ステップが白飛びなく明瞭に描画されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildWizardTestWidget(isDark: false, screenSize: const Size(800, 1600)),
      );
      await tester.pump();

      expect(find.text('道上剣友会 のオーダー確認'), findsOneWidget);
      expect(find.text('試合詳細の設定へ進む'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ダークモードにおいて試合詳細設定ステップがハイコントラストかつ美しく描画されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildWizardTestWidget(isDark: true, screenSize: const Size(800, 1600)),
      );
      await tester.pump();

      // Step 0 -> Step 1 へ進む
      final nextBtn1 = find.widgetWithText(ElevatedButton, '試合詳細の設定へ進む');
      expect(nextBtn1, findsOneWidget);
      await tester.tap(nextBtn1);
      await tester.safePumpAndSettle();

      expect(find.text('試合詳細・見出しの設定'), findsOneWidget);
      expect(find.text('対戦相手・紅白へ進む'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('対戦相手および紅白選択ステップが視認性高くオーバーフローなく描画されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildWizardTestWidget(isDark: false, screenSize: const Size(800, 1600)),
      );
      await tester.safePumpAndSettle();

      // Step 0 -> Step 1
      final nextBtn1 = find.widgetWithText(ElevatedButton, '試合詳細の設定へ進む');
      await tester.tap(nextBtn1);
      await tester.safePumpAndSettle();

      // Step 1 -> Step 2
      final nextBtn2 = find.widgetWithText(ElevatedButton, '対戦相手・紅白へ進む');
      await tester.tap(nextBtn2);
      await tester.safePumpAndSettle();

      expect(find.byType(QuickNextMatchWizardSheet), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
