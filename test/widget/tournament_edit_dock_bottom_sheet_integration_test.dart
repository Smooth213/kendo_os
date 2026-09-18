import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/tournament_header_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/tournament_edit_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/tournament_repository.dart';

class MockTournamentRepository extends Mock implements TournamentRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime.now());
  });

  group('🥋 大会情報編集UI ドックボトムシート統合 ＆ 動作保証テスト', () {
    late MockTournamentRepository mockTournamentRepo;
    late TournamentModel sampleTournament;

    setUp(() {
      mockTournamentRepo = MockTournamentRepository();
      sampleTournament = TournamentModel(
        id: 't_dock_01',
        organizationId: 'org_001',
        name: '第45回 全道剣道大会',
        venue: '北海道立総合体育センター',
        date: DateTime(2026, 9, 20),
        notes: '午前8:30開場、9:15審判会議',
      );
    });

    Widget buildTestApp({
      required Widget child,
      bool canManage = true,
      ThemeMode themeMode = ThemeMode.light,
    }) {
      return ProviderScope(
        overrides: [
          tournamentRepositoryProvider.overrideWithValue(mockTournamentRepo),
          permissionProvider.overrideWith(
            (ref) => PermissionState(
              canManageTournament: canManage,
              canDeleteData: false,
            ),
          ),
        ],
        child: MaterialApp(
          themeMode: themeMode,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          home: Scaffold(body: child),
        ),
      );
    }

    testWidgets('1. ヘッダーカードのメニューから大会編集ドックボトムシートが正常に起動すること', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildTestApp(child: TournamentHeaderCard(tournament: sampleTournament)),
      );

      // 大会名・会場・メモが表示されていること
      expect(find.text('第45回 全道剣道大会'), findsOneWidget);
      expect(find.text('北海道立総合体育センター'), findsOneWidget);

      // 三点リーダーメニューをタップ
      final menuButton = find.byIcon(Icons.more_horiz);
      expect(menuButton, findsOneWidget);
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      // メニュー内の「大会情報の編集」タップ
      final editTile = find.text('大会情報の編集');
      expect(editTile, findsOneWidget);
      await tester.tap(editTile);
      await tester.pumpAndSettle();

      // TournamentEditBottomSheet が開いていること
      expect(find.byType(TournamentEditBottomSheet), findsOneWidget);
      expect(find.byType(DraggableScrollableSheet), findsOneWidget);

      // 編集シート内の各初期値が反映されていること
      expect(find.widgetWithText(TextField, '第45回 全道剣道大会'), findsOneWidget);
      expect(find.widgetWithText(TextField, '北海道立総合体育センター'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(TournamentEditBottomSheet),
          matching: find.text('2026年09月20日'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('2. ドックボトムシート規格（可変サイズ0.58〜0.95・ドラッグハンドル・キーボード回避）に適合していること', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          child: TournamentEditBottomSheet(tournament: sampleTournament),
        ),
      );

      final sheetFinder = find.byType(DraggableScrollableSheet);
      expect(sheetFinder, findsOneWidget);

      final sheet = tester.widget<DraggableScrollableSheet>(sheetFinder);
      expect(sheet.initialChildSize, equals(0.58));
      expect(sheet.maxChildSize, equals(0.95));
      expect(sheet.minChildSize, equals(0.35));

      // ドラッグハンドルとヘッダーアイコンの存在
      expect(find.byIcon(Icons.edit_note_rounded), findsOneWidget);
      expect(find.text('保存'), findsOneWidget);
      expect(find.text('キャンセル'), findsOneWidget);
    });

    testWidgets('3. 大会情報を編集してヘッダー保存ボタンで正しくリポジトリ更新とシートクローズが行われること', (
      tester,
    ) async {
      when(
        () => mockTournamentRepo.updateTournamentDetails(
          any(),
          name: any(named: 'name'),
          venue: any(named: 'venue'),
          notes: any(named: 'notes'),
          date: any(named: 'date'),
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(
        buildTestApp(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                TournamentEditBottomSheet.show(
                  context: context,
                  tournament: sampleTournament,
                );
              },
              child: const Text('編集シートを開く'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('編集シートを開く'));
      await tester.pumpAndSettle();

      // フィールド編集
      final nameField = find.widgetWithText(TextField, '第45回 全道剣道大会');
      await tester.enterText(nameField, '第45回 全道少年少女剣道大会');

      final venueField = find.widgetWithText(TextField, '北海道立総合体育センター');
      await tester.enterText(venueField, '北ガスアリーナ札幌46');

      final notesField = find.widgetWithText(TextField, '午前8:30開場、9:15審判会議');
      await tester.enterText(notesField, '午前8:00開場に変更');
      await tester.pump();

      // ヘッダーの「保存」ボタン押下
      await tester.tap(find.text('保存'));
      await tester.pump();

      // リポジトリが更新されたか検証
      verify(
        () => mockTournamentRepo.updateTournamentDetails(
          't_dock_01',
          name: '第45回 全道少年少女剣道大会',
          venue: '北ガスアリーナ札幌46',
          notes: '午前8:00開場に変更',
          date: DateTime(2026, 9, 20),
        ),
      ).called(1);

      await tester.pumpAndSettle();
      // ボトムシートが閉じていること
      expect(find.byType(TournamentEditBottomSheet), findsNothing);
    });

    testWidgets('4. 下部固定アクションボタン「大会情報を保存する」でも統合更新が成功すること', (tester) async {
      when(
        () => mockTournamentRepo.updateTournamentDetails(
          any(),
          name: any(named: 'name'),
          venue: any(named: 'venue'),
          notes: any(named: 'notes'),
          date: any(named: 'date'),
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(
        buildTestApp(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                TournamentEditBottomSheet.show(
                  context: context,
                  tournament: sampleTournament,
                );
              },
              child: const Text('編集シートを開く'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('編集シートを開く'));
      await tester.pumpAndSettle();

      final bottomSaveBtn = find.text('大会情報を保存する');
      await tester.ensureVisible(bottomSaveBtn);
      await tester.pumpAndSettle();

      await tester.tap(bottomSaveBtn);
      await tester.pump();

      verify(
        () => mockTournamentRepo.updateTournamentDetails(
          't_dock_01',
          name: '第45回 全道剣道大会',
          venue: '北海道立総合体育センター',
          notes: '午前8:30開場、9:15審判会議',
          date: DateTime(2026, 9, 20),
        ),
      ).called(1);

      await tester.pumpAndSettle();
      expect(find.byType(TournamentEditBottomSheet), findsNothing);
    });

    testWidgets('5. 大会名が未入力の場合はエラーが表示されリポジトリ更新がブロックされること', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: TournamentEditBottomSheet(tournament: sampleTournament),
        ),
      );

      final nameField = find.widgetWithText(TextField, '第45回 全道剣道大会');
      await tester.enterText(nameField, '   ');
      await tester.pump();

      await tester.tap(find.text('保存'));
      await tester.pump();

      expect(find.text('大会名を入力してください'), findsOneWidget);
      verifyNever(
        () => mockTournamentRepo.updateTournamentDetails(
          any(),
          name: any(named: 'name'),
          venue: any(named: 'venue'),
          notes: any(named: 'notes'),
          date: any(named: 'date'),
        ),
      );
    });

    testWidgets('6. 「キャンセル」ボタンで保存されずにボトムシートが正常に破棄されること', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                TournamentEditBottomSheet.show(
                  context: context,
                  tournament: sampleTournament,
                );
              },
              child: const Text('開く'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('開く'));
      await tester.pumpAndSettle();

      expect(find.byType(TournamentEditBottomSheet), findsOneWidget);

      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      expect(find.byType(TournamentEditBottomSheet), findsNothing);
      verifyNever(
        () => mockTournamentRepo.updateTournamentDetails(
          any(),
          name: any(named: 'name'),
          venue: any(named: 'venue'),
          notes: any(named: 'notes'),
          date: any(named: 'date'),
        ),
      );
    });

    testWidgets('7. 管理権限（canManageTournament）がない場合、メニューボタンが非表示になり編集が開かないこと', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          canManage: false,
          child: TournamentHeaderCard(tournament: sampleTournament),
        ),
      );

      expect(find.byIcon(Icons.more_horiz), findsNothing);
      expect(find.text('大会情報の編集'), findsNothing);
    });

    testWidgets('8. ダークモードおよびカスタムカラーがドックボトムシートに美しく伝播すること', (tester) async {
      const customCard = Color(0xFF1E293B);
      const customText = Color(0xFFF8FAFC);
      const customSubText = Color(0xFF94A3B8);
      const customBorder = Color(0xFF334155);

      await tester.pumpWidget(
        buildTestApp(
          themeMode: ThemeMode.dark,
          child: TournamentEditBottomSheet(
            tournament: sampleTournament,
            cardColor: customCard,
            textColor: customText,
            subTextColor: customSubText,
            borderColor: customBorder,
          ),
        ),
      );

      expect(find.byType(TournamentEditBottomSheet), findsOneWidget);

      final containerFinder = find.byWidgetPredicate(
        (w) =>
            w is Container &&
            (w.decoration is BoxDecoration) &&
            ((w.decoration as BoxDecoration).color == customCard),
      );
      expect(containerFinder, findsWidgets);
    });
  });
}
