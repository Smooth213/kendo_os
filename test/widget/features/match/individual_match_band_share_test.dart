import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../helpers/safe_pump_helper.dart';
import 'package:kendo_os/features/band/domain/entities/band_group_model.dart';
import 'package:kendo_os/features/band/presentation/components/band_share_button.dart';
import 'package:kendo_os/features/band/presentation/providers/band_provider.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_list_tile_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_timeline_list.dart'
    show customTeamNamesProvider;
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_individual_player_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import '../../../helpers/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final dummyGroups = [
    BandGroupModel(
      id: 'g_indiv_1',
      name: '中学生個人戦グループ',
      url: 'https://band.us/@kendo_indiv_jhs',
      order: 1,
      createdAt: DateTime(2026, 9, 1),
    ),
  ];

  String? mockClipboardText;

  setUp(() {
    BandLauncherHelper.urlLauncherOverride = null;
    mockClipboardText = null;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (
          MethodCall methodCall,
        ) async {
          if (methodCall.method == 'Clipboard.setData') {
            final args = methodCall.arguments as Map<dynamic, dynamic>?;
            mockClipboardText = args?['text'] as String?;
            return null;
          }
          if (methodCall.method == 'Clipboard.getData') {
            return <String, dynamic>{'text': mockClipboardText};
          }
          return null;
        });
  });

  tearDown(() {
    BandLauncherHelper.urlLauncherOverride = null;
    mockClipboardText = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  group('[Widget] 個人戦・リーグ個人戦 試合カードBAND連携・自動コピー 検証テスト', () {
    testWidgets('個人戦アコーディオン内の試合カードBANDボタン押下によるクリップボード格納およびBANDシート起動が検証されること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      Uri? launchedUri;
      BandLauncherHelper.urlLauncherOverride = (uri) async {
        launchedUri = uri;
        return true;
      };

      const testMatch = MatchModel(
        id: 'match_hashimoto_r25',
        tournamentId: 'tourney_autumn_2026',
        matchType: '個人戦',
        status: 'finished',
        redName: '道上剣友会:橋本 璃久',
        whiteName: '昇龍館一福道場:三宅 隆誠',
        redScore: 1,
        whiteScore: 0,
        note: '第8試合場, 25試合目',
        groupName: '',
        order: 25.0,
      );

      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'operate');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentDojoIdProvider.overrideWith((ref) => 'dojo_michigami'),
            currentTournamentIdProvider.overrideWith(
              (ref) => 'tourney_autumn_2026',
            ),
            bandGroupsStreamProvider.overrideWith(
              (ref) => Stream.value(dummyGroups),
            ),
            permissionProvider.overrideWithValue(
              const PermissionState(canManageTournament: true),
            ),
            matchListProvider.overrideWith((ref) => [testMatch]),
            customTeamNamesProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: createTestApp(
            Theme(
              data: ThemeData.light().copyWith(extensions: [themeColors]),
              child: Scaffold(
                body: SingleChildScrollView(
                  child: TimelineIndividualPlayerCard(
                    playerName: '橋本 璃久',
                    playerMatches: const [testMatch],
                    playerComments: const [],
                    categoryName: '中学生男子の部',
                    teamName: '道上剣友会',
                    tournamentId: 'tourney_autumn_2026',
                    isReadOnlyUI: false,
                    isDark: false,
                    permissions: const PermissionState(
                      canManageTournament: true,
                      isReadOnly: false,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.safePumpAndSettle();

      // 1. 初期状態：親アコーディオンヘッダーをタップして展開
      await tester.tap(find.byKey(const ValueKey('player_橋本 璃久')));
      await tester.safePumpAndSettle();

      // 2. 展開された各試合カード（第8試合場, 25試合目）内にBANDボタンが存在することを確認
      expect(find.byType(MatchListTileCard), findsOneWidget);
      expect(find.textContaining('第8試合場, 25試合目'), findsOneWidget);
      final bandBtnFinder = find.byType(BandShareButton);
      expect(bandBtnFinder, findsOneWidget);

      // 3. 試合カード内のBANDボタンをタップ
      await tester.tap(bandBtnFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // 4. クリップボードに正しい対戦情報と個人戦単一URLが格納されたことを検証
      expect(mockClipboardText, isNotNull);
      expect(mockClipboardText, contains('第8試合場, 25試合目'));
      expect(mockClipboardText, contains('赤: 道上剣友会:橋本 璃久 vs 白: 昇龍館一福道場:三宅 隆誠'));
      expect(
        mockClipboardText,
        contains(
          'https://kendo-os-beta.web.app/viewer/match_hashimoto_r25?tournamentId=tourney_autumn_2026&role=viewer&dojoId=dojo_michigami',
        ),
      );

      // 5. BANDグループ選択ボトムシートが表示されたことを検証
      expect(find.text('BANDでLIVE配信・共有'), findsOneWidget);
      expect(find.text('中学生個人戦グループ'), findsOneWidget);

      // 6. グループをタップしてBANDが起動すること
      await tester.tap(find.text('中学生個人戦グループ'));
      await tester.safePumpAndSettle();

      expect(launchedUri, isNotNull);
      expect(launchedUri.toString(), 'https://band.us/@kendo_indiv_jhs');
    });

    testWidgets('リーグ個人戦の試合カードBANDボタン押下による正しい個人戦単独URLでのBAND共有が検証されること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const leagueMatch = MatchModel(
        id: 'league_match_indiv_01',
        tournamentId: 'tourney_autumn_2026',
        matchType: 'individual',
        groupName: '個人リーグAブロック',
        status: 'in_progress',
        redName: '道上剣友会:橋本 璃久',
        whiteName: 'ライバル道場:選手B',
        redScore: 2,
        whiteScore: 0,
        note: '第3試合場 [リーグ戦] 第1試合',
        order: 1.0,
      );

      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'operate');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentDojoIdProvider.overrideWith((ref) => 'dojo_michigami'),
            currentTournamentIdProvider.overrideWith(
              (ref) => 'tourney_autumn_2026',
            ),
            bandGroupsStreamProvider.overrideWith(
              (ref) => Stream.value(dummyGroups),
            ),
            permissionProvider.overrideWithValue(
              const PermissionState(canManageTournament: true),
            ),
            matchListProvider.overrideWith((ref) => [leagueMatch]),
            customTeamNamesProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: createTestApp(
            Theme(
              data: ThemeData.light().copyWith(extensions: [themeColors]),
              child: const Scaffold(
                body: MatchListTileCard(initialMatch: leagueMatch),
              ),
            ),
          ),
        ),
      );
      await tester.safePumpAndSettle();

      // 1. リーグ個人戦の試合カードにBANDボタンが表示されること
      final bandBtnFinder = find.byType(BandShareButton);
      expect(bandBtnFinder, findsOneWidget);

      // 2. BANDボタンをタップ
      await tester.tap(bandBtnFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // 3. 団体戦URL (/viewer-team/) ではなく、個人戦単独URL (/viewer/{id}) がコピーされること
      expect(mockClipboardText, isNotNull);
      expect(mockClipboardText, contains('第3試合場 [リーグ戦] 第1試合'));
      expect(
        mockClipboardText,
        contains(
          'https://kendo-os-beta.web.app/viewer/league_match_indiv_01?tournamentId=tourney_autumn_2026&role=viewer&dojoId=dojo_michigami',
        ),
      );
      expect(mockClipboardText, isNot(contains('/viewer-team/')));
    });
  });
}
