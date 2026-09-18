import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/tournament_edit_bottom_sheet.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/tournament_repository.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';

class MockTournamentRepository extends Mock implements TournamentRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime.now());
  });

  group('TournamentEditBottomSheet 網羅テスト', () {
    late MockTournamentRepository mockTournamentRepo;
    late TournamentModel sampleTournament;

    setUp(() {
      mockTournamentRepo = MockTournamentRepository();
      sampleTournament = TournamentModel(
        id: 't_001',
        organizationId: 'org_001',
        name: '全国剣道大会2026',
        venue: '日本武道館',
        date: DateTime(2026, 10, 15),
        notes: '開会式は9:00開始',
      );
    });

    Widget buildTestWidget({required Widget child}) {
      return ProviderScope(
        overrides: [
          tournamentRepositoryProvider.overrideWithValue(mockTournamentRepo),
        ],
        child: MaterialApp(home: Scaffold(body: child)),
      );
    }

    testWidgets('1. 初期値（大会名、会場、メモ、日付）が正常に描画されること', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          child: TournamentEditBottomSheet(
            tournament: sampleTournament,
            cardColor: AppKendoColors.pureWhite,
            textColor: AppKendoColors.black,
            subTextColor: AppKendoColors.grey,
            borderColor: AppKendoColors.grey,
          ),
        ),
      );

      expect(find.text('大会情報の編集'), findsOneWidget);
      expect(find.text('全国剣道大会2026'), findsOneWidget);
      expect(find.text('日本武道館'), findsOneWidget);
      expect(find.text('開会式は9:00開始'), findsOneWidget);
      expect(find.text('2026年10月15日'), findsOneWidget);
      expect(find.text('保存'), findsOneWidget);
      expect(find.text('キャンセル'), findsOneWidget);
      expect(find.text('大会情報を保存する'), findsOneWidget);
    });

    testWidgets('2. 大会名が空の場合はバリデーションエラーが表示され保存されないこと', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          child: TournamentEditBottomSheet(tournament: sampleTournament),
        ),
      );

      // 大会名を空文字に入力変更
      final nameField = find.widgetWithText(TextField, '全国剣道大会2026');
      await tester.enterText(nameField, '   ');
      await tester.pump();

      // ヘッダーの保存ボタンをタップ
      await tester.tap(find.text('保存'));
      await tester.pump();

      // エラーのスナックバーが表示されること
      expect(find.text('大会名を入力してください'), findsOneWidget);

      // リポジトリの保存処理は呼び出されないこと
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

    testWidgets('3. 大会名・会場・メモを編集してヘッダー「保存」ボタンで正常に更新されること', (tester) async {
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
        buildTestWidget(
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  TournamentEditBottomSheet.show(
                    context: context,
                    tournament: sampleTournament,
                  );
                },
                child: const Text('開く'),
              );
            },
          ),
        ),
      );

      // ボトムシートを開く
      await tester.tap(find.text('開く'));
      await tester.pumpAndSettle();

      // 項目を編集
      final nameField = find.widgetWithText(TextField, '全国剣道大会2026');
      await tester.enterText(nameField, '第50回 全日本選手権');

      final venueField = find.widgetWithText(TextField, '日本武道館');
      await tester.enterText(venueField, '東京武道館 第一武道場');

      final notesField = find.widgetWithText(TextField, '開会式は9:00開始');
      await tester.enterText(notesField, '集合時間は8:30厳守、駐車場は第2Pを利用してください。');

      await tester.pump();

      // ヘッダーの「保存」ボタンをタップ
      await tester.tap(find.text('保存'));
      await tester.pump();

      // リポジトリが更新引数で正しく呼ばれたことを確認
      verify(
        () => mockTournamentRepo.updateTournamentDetails(
          't_001',
          name: '第50回 全日本選手権',
          venue: '東京武道館 第一武道場',
          notes: '集合時間は8:30厳守、駐車場は第2Pを利用してください。',
          date: DateTime(2026, 10, 15),
        ),
      ).called(1);

      await tester.pumpAndSettle();
      // ボトムシートが閉じていること
      expect(find.text('第50回 全日本選手権'), findsNothing);
    });

    testWidgets('4. 下部固定アクションボタン「大会情報を保存する」でも正常に保存されること', (tester) async {
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
        buildTestWidget(
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  TournamentEditBottomSheet.show(
                    context: context,
                    tournament: sampleTournament,
                  );
                },
                child: const Text('開く'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('開く'));
      await tester.pumpAndSettle();

      // 下部固定アクションボタンまでスクロールしてタップ
      final saveButton = find.text('大会情報を保存する');
      await tester.ensureVisible(saveButton);
      await tester.pumpAndSettle();

      await tester.tap(saveButton);
      await tester.pump();

      // リポジトリが呼ばれたことを確認
      verify(
        () => mockTournamentRepo.updateTournamentDetails(
          't_001',
          name: '全国剣道大会2026',
          venue: '日本武道館',
          notes: '開会式は9:00開始',
          date: DateTime(2026, 10, 15),
        ),
      ).called(1);

      await tester.pumpAndSettle();
    });

    testWidgets('5. 「キャンセル」ボタンを押した際、保存されずにボトムシートが閉じること', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  TournamentEditBottomSheet.show(
                    context: context,
                    tournament: sampleTournament,
                  );
                },
                child: const Text('開く'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('開く'));
      await tester.pumpAndSettle();

      expect(find.text('大会情報の編集'), findsOneWidget);

      // キャンセルボタンをタップ
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      // リポジトリは呼ばれず、シートが閉じていること
      verifyNever(
        () => mockTournamentRepo.updateTournamentDetails(
          any(),
          name: any(named: 'name'),
          venue: any(named: 'venue'),
          notes: any(named: 'notes'),
          date: any(named: 'date'),
        ),
      );

      expect(find.text('大会情報の編集'), findsNothing);
    });

    testWidgets('6. 開催年月日タップで日付選択ダイアログが起動すること', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          child: TournamentEditBottomSheet(tournament: sampleTournament),
        ),
      );

      // 開催年月日フィールドをタップ
      await tester.tap(find.text('2026年10月15日'));
      await tester.pumpAndSettle();

      // 日付選択ダイアログが表示されること（年やOKボタンの存在確認）
      expect(find.byType(DatePickerDialog), findsOneWidget);
    });
  });
}
