import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/band/domain/entities/band_group_model.dart';
import 'package:kendo_os/features/band/presentation/components/band_settings_section.dart';
import 'package:kendo_os/features/band/presentation/components/band_share_button.dart';
import 'package:kendo_os/features/band/presentation/providers/band_provider.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/domain/team_progress_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/court_status/team_status_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_group_header.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final dummyGroups = [
    BandGroupModel(
      id: 'g1',
      name: '低学年チーム',
      url: 'https://band.us/@dojo_low',
      order: 1,
      createdAt: DateTime(2026, 9, 1),
    ),
    BandGroupModel(
      id: 'g2',
      name: '高学年チーム',
      url: 'https://band.us/@dojo_high',
      order: 2,
      createdAt: DateTime(2026, 9, 2),
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

  Future<void> pumpAnimation(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('🥋 【E2E】BAND LIVE配信連携・対戦カード自動コピー機能 完全保証テスト', () {
    testWidgets(
      '【シナリオ1: チーム試合状況カード】BANDボタンタップ ➔ クリップボードコピー ➔ シート展開 ➔ グループ選択起動の完全連携',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        Uri? launchedUri;
        BandLauncherHelper.urlLauncherOverride = (uri) async {
          launchedUri = uri;
          return true;
        };

        final liveMatch = MatchModel(
          id: 'match_team_live',
          matchType: '団体戦 (中堅)',
          redName: '勇武館:田中',
          whiteName: '翔武会:佐藤',
          status: 'in_progress',
          note: '第1試合場 2回戦',
        );

        final status = TeamProgressStatus(
          teamName: '勇武館',
          categoryName: '小学生団体の部',
          currentCourtName: '第1試合場',
          matchupTitle: '団体戦：勇武館 vs 翔武会',
          targetGroupId: 'team_group_live_999',
          tournamentId: 'tourney_e2e_1',
          matches: [liveMatch],
          inProgressMatch: liveMatch,
          completedCount: 2,
          totalCount: 5,
          hasLiveMatch: true,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentDojoIdProvider.overrideWith((ref) => 'dojo_test_e2e'),
              bandGroupsStreamProvider.overrideWith(
                (ref) => Stream.value(dummyGroups),
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: TeamStatusCard(status: status, isDark: false),
                ),
              ),
            ),
          ),
        );
        await pumpAnimation(tester);

        // 1. カード右上のBANDボタンが表示されていること
        final bandBtn = find.byType(BandShareButton);
        expect(bandBtn, findsOneWidget);

        // 2. BANDボタンをタップ
        await tester.tap(bandBtn);
        await pumpAnimation(tester);

        // 3. クリップボードへの自動書き込みを検証
        expect(mockClipboardText, isNotNull);
        expect(mockClipboardText, contains('[小学生団体の部 第1試合場]'));
        expect(mockClipboardText, contains('団体戦：勇武館 vs 翔武会'));
        expect(mockClipboardText, contains('【試合中】[中堅] 田中 vs 佐藤'));
        expect(
          mockClipboardText,
          contains(
            'https://kendo-os-beta.web.app/viewer-team/team_group_live_999?tournamentId=tourney_e2e_1&role=viewer&dojoId=dojo_test_e2e',
          ),
        );

        // 4. グループ選択ボトムシートが表示されること
        expect(find.text('BANDでLIVE配信・共有'), findsOneWidget);
        expect(find.text('低学年チーム'), findsOneWidget);
        expect(find.text('高学年チーム'), findsOneWidget);

        // 5. グループ（低学年チーム）をタップ ➔ URL起動コール＆シート閉鎖
        await tester.tap(find.text('低学年チーム'));
        await pumpAnimation(tester);

        expect(launchedUri, isNotNull);
        expect(
          launchedUri.toString(),
          'https://band.us/@dojo_low',
          reason: 'LIVE配信や通常投稿が可能なグループ画面へ直行するため登録グループURLが起動されること',
        );
        expect(find.text('BANDでLIVE配信・共有'), findsNothing);
      },
    );

    testWidgets('【シナリオ2: タイムライン個人戦】BANDボタンタップ ➔ 個人戦コピー ➔ コピーのみで閉じるフロー', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final individualMatch = MatchModel(
        id: 'match_indiv_01',
        matchType: '個人戦',
        redName: '小林 健太 (勇武館)',
        whiteName: '渡辺 翔太 (清風道場)',
        status: 'finished',
        redScore: 2,
        whiteScore: 1,
        note: '第2試合場 3回戦',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentDojoIdProvider.overrideWith((ref) => 'dojo_test_e2e'),
            bandGroupsStreamProvider.overrideWith(
              (ref) => Stream.value(dummyGroups),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: TimelineGroupHeader(
                groupList: [individualMatch],
                label: '個人戦 第2コート',
                allFinished: true,
                hasInProgress: false,
                isReadOnlyUI: false,
                canManageTournamentUI: true,
                isDark: false,
                ownTeams: const ['勇武館'],
                titleColor: Colors.black,
              ),
            ),
          ),
        ),
      );
      await pumpAnimation(tester);

      // BANDボタンをタップ
      final bandBtn = find.byType(BandShareButton);
      expect(bandBtn, findsOneWidget);
      await tester.tap(bandBtn);
      await pumpAnimation(tester);

      // クリップボード確認
      expect(mockClipboardText, isNotNull);
      expect(mockClipboardText, contains('第2試合場 3回戦'));
      expect(mockClipboardText, contains('赤: 小林 健太 (勇武館) vs 白: 渡辺 翔太 (清風道場)'));

      // シート内の「コピーのみで閉じる」をタップして閉じる
      final closeBtn = find.text('コピーのみで閉じる');
      expect(closeBtn, findsOneWidget);
      await tester.tap(closeBtn);
      await pumpAnimation(tester);

      expect(find.text('BANDでLIVE配信・共有'), findsNothing);
    });

    testWidgets('【シナリオ3: 未登録状態】空メッセージ表示 ➔ その場で即時グループ追加ダイアログ展開', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final match = MatchModel(
        id: 'match_empty_test',
        matchType: '個人戦',
        redName: '選手A',
        whiteName: '選手B',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentDojoIdProvider.overrideWith((ref) => 'dojo_test_e2e'),
            bandGroupsStreamProvider.overrideWith(
              (ref) => Stream.value(<BandGroupModel>[]), // 空状態
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: BandShareButton(matches: [match], tournamentName: 'テスト大会'),
            ),
          ),
        ),
      );
      await pumpAnimation(tester);

      // BANDボタンタップ
      await tester.tap(find.byType(BandShareButton));
      await pumpAnimation(tester);

      // 空状態の表示確認
      expect(find.text('登録済みのBANDグループがありません'), findsOneWidget);

      // 「グループを登録」ボタンをタップ
      final registerBtn = find.text('グループを登録');
      expect(registerBtn, findsOneWidget);
      await tester.tap(registerBtn);
      await pumpAnimation(tester);

      // 追加ダイアログが開くこと
      expect(find.text('新しいBANDグループを追加'), findsOneWidget);
      expect(find.text('グループ名（例: 低学年チーム）'), findsOneWidget);
    });

    testWidgets('【シナリオ4: システム設定画面】BAND設定タイル ➔ 一括管理シート ➔ ダイアログ起動のライフサイクル検証', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentDojoIdProvider.overrideWith((ref) => 'dojo_test_e2e'),
            bandGroupsStreamProvider.overrideWith(
              (ref) => Stream.value(dummyGroups),
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: BandSettingsTile())),
        ),
      );
      await pumpAnimation(tester);

      // 1. 設定タイルにグループ件数が反映されていること
      expect(find.text('BAND連携・LIVE配信設定'), findsOneWidget);
      expect(find.text('2件のグループが登録されています（※要BANDアプリ）'), findsOneWidget);

      // 2. タイルをタップ ➔ 管理シート展開
      await tester.tap(find.byType(BandSettingsTile));
      await pumpAnimation(tester);

      expect(find.text('BANDグループ管理'), findsOneWidget);
      expect(find.text('低学年チーム'), findsOneWidget);
      expect(find.text('高学年チーム'), findsOneWidget);

      // 3. 追加アイコンボタンをタップ ➔ 新規追加ダイアログが開くこと
      final addIconBtn = find.byTooltip('新しいBandを追加');
      expect(addIconBtn, findsOneWidget);
      await tester.tap(addIconBtn);
      await pumpAnimation(tester);

      expect(find.text('新しいBANDグループを追加'), findsOneWidget);
    });
  });
}
