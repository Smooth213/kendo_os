import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/mock_services.dart';
import '../helpers/safe_pump_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/quick_next_match/quick_next_match_wizard_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_screen_providers.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/safe_timeline_provider.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';

void main() {
  setUpAll(() {
    registerCommonFallbackValues();
  });

  group('[Widget] クイック次戦作成ウィザードの検証', () {
    late MockMatchApplicationService mockMatchService;

    setUp(() {
      mockMatchService = MockMatchApplicationService();
      when(() => mockMatchService.saveMatch(any())).thenAnswer((_) async {});
    });

    tearDown(() async {
      // リセット
    });

    Widget createTestWidget({
      required MatchModel baseMatch,
      List<MatchModel> teamMatches = const [],
      bool isSameTeamContinue = false,
    }) {
      return ProviderScope(
        overrides: [
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
              ),
              PlayerModel(
                id: 'p2',
                lastName: '佐藤',
                firstName: '健',
                lastNameKana: 'さとう',
                firstNameKana: 'たける',
                grade: 6,
              ),
            ]),
          ),
          customTeamNamesProvider.overrideWith(
            (ref) => Stream.value(['道上剣友会']),
          ),
          registeredTeamsProvider('t1').overrideWith((ref) => Stream.value([])),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: QuickNextMatchWizardSheet(
              baseMatch: baseMatch,
              teamMatches: teamMatches,
              isSameTeamContinue: isSameTeamContinue,
            ),
          ),
        ),
      );
    }

    testWidgets('クイック次戦作成: 紅白トグルで白を選択した際、自チームが白・相手が赤に反転して保存されること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const baseMatch = MatchModel(
        id: 'm1',
        tournamentId: 't1',
        category: '小学生団体',
        matchType: '先鋒',
        redName: '道上剣友会 : 皿田 脩人',
        whiteName: '相手道場 : 相手選手',
        note: '第1試合場, 1試合目',
        rule: MatchRule(teamName: '道上剣友会'),
      );

      await tester.pumpWidget(
        createTestWidget(baseMatch: baseMatch, teamMatches: [baseMatch]),
      );
      await tester.safePumpAndSettle();

      // Step 1: 「試合詳細の設定へ進む」をタップ
      final nextButton1 = find.widgetWithText(ElevatedButton, '試合詳細の設定へ進む');
      expect(nextButton1, findsOneWidget);
      await tester.tap(nextButton1);
      await tester.safePumpAndSettle();

      // Step 2: 「対戦相手・紅白へ進む」をタップ
      final nextButton2 = find.widgetWithText(ElevatedButton, '対戦相手・紅白へ進む');
      expect(nextButton2, findsOneWidget);
      await tester.tap(nextButton2);
      await tester.safePumpAndSettle();

      // Step 3: 「白 (右側)」をタップして自チームを白に変更
      final whiteToggle = find.text('白 (右側)');
      expect(whiteToggle, findsOneWidget);
      await tester.tap(whiteToggle);
      await tester.safePumpAndSettle();

      // 「このオーダーで確定して進む」をタップ
      final confirmButton = find.widgetWithText(
        ElevatedButton,
        'このオーダーで確定して進む',
      );
      expect(confirmButton, findsOneWidget);
      await tester.tap(confirmButton);
      await tester.safePumpAndSettle();

      // 検証: 保存された MatchModel の redName が相手、whiteName が自チームになっていること
      final captured = verify(
        () => mockMatchService.saveMatch(captureAny()),
      ).captured;
      expect(captured.isNotEmpty, isTrue);

      final createdMatch = captured.first as MatchModel;
      expect(createdMatch.whiteName, contains('道上剣友会 : 皿田 脩人'));
      // 相手チーム変更時は相手選手名が空欄になり、デフォルトで「選手」となること
      expect(createdMatch.redName, contains('選手'));
    });

    testWidgets('錬成会モード: オーダー確認画面で即開始ボタンを押した際、後続設定をスキップして即座に次戦が保存されること', (
      tester,
    ) async {
      const baseMatch = MatchModel(
        id: 'm_renseikai',
        tournamentId: 't1',
        category: '錬成会',
        matchType: '先鋒',
        redName: '道上剣友会 : 皿田 脩人',
        whiteName: 'ライバル道場 : 相手選手',
        note: '第2試合場',
        rule: MatchRule(teamName: '道上剣友会', isRenseikai: true),
      );

      await tester.pumpWidget(
        createTestWidget(
          baseMatch: baseMatch,
          teamMatches: [baseMatch],
          isSameTeamContinue: true,
        ),
      );
      await tester.safePumpAndSettle();

      // 錬成会即開始ボタンが存在すること
      final quickStartButton = find.widgetWithText(
        ElevatedButton,
        'このオーダーのまま即開始（Step2/3をスキップ）',
      );
      expect(quickStartButton, findsOneWidget);

      // タップして即時作成
      await tester.tap(quickStartButton);
      await tester.safePumpAndSettle();

      // 検証: Step 2/3 を経由せずに即 saveMatch が呼ばれたこと
      final captured = verify(
        () => mockMatchService.saveMatch(captureAny()),
      ).captured;
      expect(captured.isNotEmpty, isTrue);

      final createdMatch = captured.first as MatchModel;
      expect(createdMatch.redName, contains('道上剣友会 : 皿田 脩人'));
      expect(createdMatch.whiteName, contains('ライバル道場 : 相手選手'));
      expect(createdMatch.note, equals('第2試合場'));
    });

    testWidgets('回戦チップ選択: 試合詳細画面で回戦を選択した際、見出しnoteに正しく反映されること', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const baseMatch = MatchModel(
        id: 'm_tourney',
        tournamentId: 't1',
        category: 'トーナメント',
        matchType: '先鋒',
        redName: '道上剣友会 : 皿田 脩人',
        whiteName: '相手道場 : 選手',
        note: '第1試合場, 1回戦',
        rule: MatchRule(teamName: '道上剣友会'),
      );

      await tester.pumpWidget(
        createTestWidget(baseMatch: baseMatch, teamMatches: [baseMatch]),
      );
      await tester.safePumpAndSettle();

      // Step 1 ➔ Step 2 へ進む
      await tester.tap(find.widgetWithText(ElevatedButton, '試合詳細の設定へ進む'));
      await tester.safePumpAndSettle();

      // Step 2: 「2回戦」チップをタップ
      final round2Chip = find.text('2回戦');
      expect(round2Chip, findsOneWidget);
      await tester.tap(round2Chip);
      await tester.safePumpAndSettle();

      // Step 2 ➔ Step 3 へ進む
      await tester.tap(find.widgetWithText(ElevatedButton, '対戦相手・紅白へ進む'));
      await tester.safePumpAndSettle();

      // Step 3: 確定
      await tester.tap(find.widgetWithText(ElevatedButton, 'このオーダーで確定して進む'));
      await tester.safePumpAndSettle();

      // 検証: note に '2回戦' が反映されていること
      final captured = verify(
        () => mockMatchService.saveMatch(captureAny()),
      ).captured;
      expect(captured.isNotEmpty, isTrue);

      final createdMatch = captured.first as MatchModel;
      expect(createdMatch.note, contains('2回戦'));
    });

    testWidgets('オーダー編成画面準拠のスロットが表示され、「欠員」ボタンで相手が欠員として登録されること', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const baseMatch = MatchModel(
        id: 'm_slot_test',
        tournamentId: 't1',
        category: '小学生団体',
        matchType: '先鋒',
        groupName: '団体戦A',
        redName: '道上剣友会 : 皿田 脩人',
        whiteName: '相手道場 : 相手先鋒',
        note: '第1試合場',
        rule: MatchRule(
          teamName: '道上剣友会',
          positions: ['先鋒', '次鋒'],
          baseOrder: ['皿田 脩人', '佐藤 健'],
        ),
      );

      await tester.pumpWidget(
        createTestWidget(baseMatch: baseMatch, teamMatches: [baseMatch]),
      );
      await tester.safePumpAndSettle();

      // Step 1 ➔ Step 2
      await tester.tap(find.widgetWithText(ElevatedButton, '試合詳細の設定へ進む'));
      await tester.safePumpAndSettle();

      // Step 2 ➔ Step 3
      await tester.tap(find.widgetWithText(ElevatedButton, '対戦相手・紅白へ進む'));
      await tester.safePumpAndSettle();

      // Step 3: オーダー編成準拠の要素が表示されていること
      expect(find.text('自チームの紅白（タスキ）'), findsOneWidget);
      expect(find.text('道上剣友会 : 先鋒'), findsOneWidget);
      expect(find.text('皿田 脩人'), findsWidgets);

      // 先鋒の「欠員」ボタンをタップ
      final vacantButtons = find.widgetWithText(TextButton, '欠員');
      expect(vacantButtons, findsWidgets);
      await tester.tap(vacantButtons.first);
      await tester.safePumpAndSettle();

      // 確定ボタンをタップ
      await tester.tap(find.widgetWithText(ElevatedButton, 'このオーダーで確定して進む'));
      await tester.safePumpAndSettle();

      // 検証: 先鋒の相手選手名が「欠員」として保存されたこと
      final captured = verify(
        () => mockMatchService.saveMatch(captureAny()),
      ).captured;
      expect(captured.isNotEmpty, isTrue);

      final matches = captured.map((e) => e as MatchModel).toList();
      final senpoMatch = matches.firstWhere((m) => m.matchType == '先鋒');
      expect(senpoMatch.whiteName, contains('欠員'));
    });

    testWidgets('試合詳細画面で運営メモアコーディオンが初期状態で閉じていること、および展開して入力した内容が保存されること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const baseMatch = MatchModel(
        id: 'm_note_test',
        tournamentId: 't1',
        category: '小学生団体',
        matchType: '先鋒',
        groupName: '団体戦A',
        redName: '道上剣友会 : 皿田 脩人',
        whiteName: '相手道場 : 相手先鋒',
        note: '第1試合場',
        rule: MatchRule(
          teamName: '道上剣友会',
          positions: ['先鋒'],
          baseOrder: ['皿田 脩人'],
        ),
      );

      await tester.pumpWidget(
        createTestWidget(baseMatch: baseMatch, teamMatches: [baseMatch]),
      );
      await tester.safePumpAndSettle();

      // Step 1 ➔ Step 2
      await tester.tap(find.widgetWithText(ElevatedButton, '試合詳細の設定へ進む'));
      await tester.safePumpAndSettle();

      // Step 2: 運営メモアコーディオンが存在し、初期状態では閉じていること
      final accordionHeader = find.text('＋ 運営メモ・特記事項を追加（任意）');
      expect(accordionHeader, findsOneWidget);
      expect(
        find.text('※このメモは大会ホーム・チーム試合状況にのみ表示され、PDFや外部試合結果には出力されません'),
        findsNothing,
      );

      // タップしてアコーディオンを展開
      await tester.tap(accordionHeader);
      await tester.safePumpAndSettle();

      // 展開後、注記とテキストフィールドが表示されること
      expect(
        find.text('※このメモは大会ホーム・チーム試合状況にのみ表示され、PDFや外部試合結果には出力されません'),
        findsOneWidget,
      );

      // 運営メモを入力
      final noteTextField = find.widgetWithText(TextField, '');
      expect(noteTextField, findsWidgets);
      await tester.enterText(noteTextField.last, '相手先鋒上段注意');
      await tester.safePumpAndSettle();

      // Step 2 ➔ Step 3
      await tester.tap(find.widgetWithText(ElevatedButton, '対戦相手・紅白へ進む'));
      await tester.safePumpAndSettle();

      // Step 3 ➔ 確定
      await tester.tap(find.widgetWithText(ElevatedButton, 'このオーダーで確定して進む'));
      await tester.safePumpAndSettle();

      // 検証: 保存された MatchModel の note に見出しと運営メモが含まれていること
      final captured = verify(
        () => mockMatchService.saveMatch(captureAny()),
      ).captured;
      expect(captured.isNotEmpty, isTrue);

      final createdMatch = captured.first as MatchModel;
      expect(createdMatch.note, contains('第1試合場'));
      expect(createdMatch.note, contains('相手先鋒上段注意'));
    });

    testWidgets('剣道形ペア選手（皿田 脩人・塚本 大道）が分割表示され、1名ずつ個別に選手変更できること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const baseMatch = MatchModel(
        id: 'kata_match_1',
        tournamentId: 't1',
        matchType: '木刀による剣道基本技稽古法（5本）',
        redName: '道上剣友会 : 皿田 脩人・塚本 大道',
        whiteName: '相手剣友会 : 相手1・相手2',
        note: '第1試合場',
        rule: MatchRule(
          teamName: '道上剣友会',
          positions: ['木刀による剣道基本技稽古法（5本）'],
          baseOrder: ['皿田 脩人・塚本 大道'],
        ),
      );

      await tester.pumpWidget(
        createTestWidget(baseMatch: baseMatch, teamMatches: [baseMatch]),
      );
      await tester.safePumpAndSettle();

      // Step 1: オーダー編成画面準拠で2スロットに分かれて選手が表示されていることを確認
      expect(find.text('皿田 脩人'), findsOneWidget);
      expect(find.text('塚本 大道'), findsOneWidget);

      // 「変更」ボタンがスロットごとに存在すること（2つ）
      final changeButtons = find.text('変更');
      expect(changeButtons, findsNWidgets(2));

      // 1人目（皿田 脩人）の変更ボタンをタップ
      await tester.tap(changeButtons.first);
      await tester.safePumpAndSettle();

      // 選手選択ボトムシートで「佐藤 健（p2）」を選択
      final playerOption = find.text('佐藤 健');
      expect(playerOption, findsOneWidget);
      await tester.tap(playerOption);
      await tester.safePumpAndSettle();

      // 検証: 1人目だけが「佐藤 健」に変更され、2人目の「塚本 大道」が維持されていること！
      expect(find.text('佐藤 健'), findsOneWidget);
      expect(find.text('塚本 大道'), findsOneWidget);
      expect(find.text('皿田 脩人'), findsNothing);

      // Step 1 ➔ Step 2
      await tester.tap(find.widgetWithText(ElevatedButton, '試合詳細の設定へ進む'));
      await tester.safePumpAndSettle();

      // Step 2 ➔ Step 3
      await tester.tap(find.widgetWithText(ElevatedButton, '対戦相手・紅白へ進む'));
      await tester.safePumpAndSettle();

      // Step 3 ➔ 確定
      await tester.tap(find.widgetWithText(ElevatedButton, 'このオーダーで確定して進む'));
      await tester.safePumpAndSettle();

      // 保存された MatchModel の redName が「道上剣友会 : 佐藤 健・塚本 大道」になっていること
      final captured = verify(
        () => mockMatchService.saveMatch(captureAny()),
      ).captured;
      expect(captured.isNotEmpty, isTrue);

      final createdMatch = captured.first as MatchModel;
      expect(createdMatch.redName, '道上剣友会 : 佐藤 健・塚本 大道');
    });
  });
}
