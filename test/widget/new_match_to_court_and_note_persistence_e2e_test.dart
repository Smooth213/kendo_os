import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/safe_pump_helper.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_list_tile_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/common/match_court_slot_picker.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/common/match_heading_format_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_timeline_list.dart'
    show customTeamNamesProvider;
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart'
    show tournamentProvider;
import 'package:kendo_os/features/tournament/presentation/operate/screens/new_match_screen.dart'
    show NewMatchScreen, newMatchHistoryProvider, newMatchPlayerMasterProvider;
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:mocktail/mocktail.dart';
import 'helpers/rendering_safety_test_helper.dart';

class MockMatchApplicationService extends Mock
    implements MatchApplicationService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await RenderingSafetyTestHelper.initialize();
    registerFallbackValue(
      const MatchModel(
        id: 'fallback_id',
        tournamentId: 'fallback_tour',
        matchType: '個人戦',
        redName: 'red',
        whiteName: 'white',
      ),
    );
  });

  group('[Widget] 新規試合作成〜会場・試合順・運営メモ永続化＆カード表示統合テスト', () {
    testWidgets(
      'NewMatchScreenでスロットPickerと運営メモを設定して単発試合を作成し、永続化された見出しと運営メモがカードに正しく分離表示されること',
      (tester) async {
        tester.view.physicalSize = const Size(414, 896);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final mockAppService = MockMatchApplicationService();
        final List<MatchModel> savedMatches = [];

        when(() => mockAppService.saveMatch(any())).thenAnswer((
          invocation,
        ) async {
          final match = invocation.positionalArguments[0] as MatchModel;
          savedMatches.add(match);
        });

        final testTournament = TournamentModel(
          id: 'tour_e2e_test',
          organizationId: 'org_e2e_test',
          name: 'E2E検証大会',
          date: DateTime.now(),
          venue: '武道館',
          categories: const ['小学生の部'],
        );

        // ── 1. NewMatchScreen を表示 ──
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              matchApplicationServiceProvider.overrideWithValue(mockAppService),
              tournamentProvider(
                'tour_e2e_test',
              ).overrideWith((ref) => Stream.value(testTournament)),
              permissionProvider.overrideWithValue(
                const PermissionState(canManageTournament: true),
              ),
              customTeamNamesProvider.overrideWith((ref) => Stream.value([])),
              newMatchPlayerMasterProvider.overrideWith(
                (ref) => Stream.value([]),
              ),
              newMatchHistoryProvider.overrideWithValue([]),
            ],
            child: MaterialApp(
              theme: ThemeData(
                extensions: [
                  AppThemeColors.ofMode(isDark: false, mode: 'normal'),
                ],
              ),
              home: const Scaffold(
                body: NewMatchScreen(tournamentId: 'tour_e2e_test'),
              ),
            ),
          ),
        );
        await tester.safePumpAndSettle();

        // ── 2. 赤・白の選手／チーム名を入力 ──
        final redField = find.widgetWithText(TextField, '赤の選手名（またはチーム名）');
        final whiteField = find.widgetWithText(TextField, '白の選手名（またはチーム名）');

        expect(redField, findsOneWidget);
        expect(whiteField, findsOneWidget);

        await tester.enterText(redField, '道上剣友会A');
        await tester.enterText(whiteField, '修道館B');
        await tester.safePumpAndSettle();

        // ── 3. 試合場・試合順スロットPickerで「14」と「4」を入力 ──
        expect(find.byType(MatchCourtSlotPicker), findsOneWidget);
        await tester.ensureVisible(find.byType(MatchCourtSlotPicker));

        // 試合場の中央数字（初期値 '-'）をタップしてテンキーダイアログ起動
        await tester.tap(find.text('-').first);
        await tester.safePumpAndSettle();
        expect(find.text('試合場番号を入力'), findsOneWidget);
        await tester.enterText(find.byType(TextField).last, '14');
        await tester.safePumpAndSettle();
        await tester.tap(find.text('決定'));
        await tester.safePumpAndSettle();

        // 試合順の中央数字（初期値 '-'）をタップしてテンキーダイアログ起動
        await tester.ensureVisible(find.byType(MatchCourtSlotPicker));
        await tester.tap(find.text('-').first);
        await tester.safePumpAndSettle();
        expect(find.text('試合順を入力'), findsOneWidget);
        await tester.enterText(find.byType(TextField).last, '4');
        await tester.safePumpAndSettle();
        await tester.tap(find.text('決定'));
        await tester.safePumpAndSettle();

        // カプセル中央に 14, 4 が反映されていること
        expect(find.text('14'), findsOneWidget);
        expect(find.text('4'), findsOneWidget);
        expect(find.text('第14試合場'), findsOneWidget);
        expect(find.text('第4試合目'), findsOneWidget);

        // ── 4. 運営メモアコーディオンを展開して内部メモを入力 ──
        await tester.ensureVisible(find.text('＋ 運営メモ・特記事項を追加（任意）'));
        await tester.tap(find.text('＋ 運営メモ・特記事項を追加（任意）'));
        await tester.safePumpAndSettle();

        // 展開されたメモ入力欄に特記事項を入力
        final noteField = find.widgetWithText(TextField, '運営メモ・特記事項');
        await tester.enterText(noteField, '本部席アナウンス注意');
        await tester.safePumpAndSettle();

        // ── 5. 「単発試合 を実行」ボタンをタップして保存 ──
        final submitButton = find.text('単発試合 を実行');
        await tester.ensureVisible(submitButton);
        await tester.tap(submitButton);
        await tester.safePumpAndSettle();

        // ── 6. DB永続化アサーション ──
        expect(savedMatches.length, 1);
        final createdMatch = savedMatches.first;
        expect(createdMatch.redName, '道上剣友会A');
        expect(createdMatch.whiteName, '修道館B');

        // 見出しと運営メモが MatchHeadingFormatHelper で正しく抽出できること
        final publicHeading = MatchHeadingFormatHelper.extractPublicHeading(
          createdMatch.note,
        );
        final privateNote = MatchHeadingFormatHelper.extractPrivateNote(
          createdMatch.note,
        );
        expect(publicHeading, '第14試合場, 4試合目');
        expect(privateNote, '本部席アナウンス注意');
      },
    );

    testWidgets('永続化された見出しと運営メモがMatchListTileCardに正しく分離表示されること', (
      tester,
    ) async {
      final sampleMatch = MatchModel(
        id: 'test_card_match_1',
        tournamentId: 'tour_e2e_test',
        matchType: '個人戦',
        redName: '道上剣友会A',
        whiteName: '修道館B',
        status: 'upcoming',
        note: '第14試合場, 4試合目\n本部席アナウンス注意',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            permissionProvider.overrideWithValue(
              const PermissionState(canManageTournament: true),
            ),
            matchListProvider.overrideWith((ref) => [sampleMatch]),
            customTeamNamesProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: MaterialApp(
            theme: ThemeData(
              extensions: [
                AppThemeColors.ofMode(isDark: false, mode: 'normal'),
              ],
            ),
            home: Scaffold(body: MatchListTileCard(initialMatch: sampleMatch)),
          ),
        ),
      );
      await tester.safePumpAndSettle();

      // 公開見出し（第14試合場, 4試合目）がチップ行に表示されていること
      expect(find.textContaining('第14試合場, 4試合目'), findsOneWidget);
      // 運営メモ行（内部特記事項）が管理カードに表示されていること
      expect(find.textContaining('本部席アナウンス注意'), findsOneWidget);
    });
  });
}
