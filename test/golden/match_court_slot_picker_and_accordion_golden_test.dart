import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/common/match_court_slot_picker.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/common/match_private_note_accordion.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Golden] 試合会場・試合順Picker及び運営メモアコーディオン視覚整合性テスト', () {
    testWidgets('ライトテーマにおいてMatchCourtSlotPickerの数値スロットおよびステップボタンが崩れず描画されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(414, 896); // iPhone 11/XR サイズ
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      int? court = 1;
      int? order = 3;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
          ),
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: MatchCourtSlotPicker(
                courtNumber: court,
                matchOrder: order,
                onCourtNumberChanged: (val) => court = val,
                onMatchOrderChanged: (val) => order = val,
                isDark: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MatchCourtSlotPicker), findsOneWidget);
      expect(find.text('試合場'), findsOneWidget);
      expect(find.text('第1試合場'), findsOneWidget);
      expect(find.text('試合順'), findsOneWidget);
      expect(find.text('第3試合目'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsNWidgets(2));
      expect(find.byIcon(Icons.remove), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'ダークテーマにおいてMatchCourtSlotPickerが高コントラストかつレイアウト破綻なく視覚的整合性を維持すること',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(414, 896);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark().copyWith(
              extensions: [AppThemeColors.ofMode(isDark: true, mode: 'normal')],
            ),
            home: Scaffold(
              backgroundColor: const Color(0xFF121212),
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: MatchCourtSlotPicker(
                  courtNumber: null,
                  matchOrder: null,
                  onCourtNumberChanged: (_) {},
                  onMatchOrderChanged: (_) {},
                  isDark: true,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(MatchCourtSlotPicker), findsOneWidget);
        expect(find.text('未設定'), findsNWidgets(2));
        expect(find.text('-'), findsNWidgets(2));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('MatchPrivateNoteAccordionの折りたたみ状態において省スペースに描画されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(414, 896);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final noteController = TextEditingController();
      addTearDown(noteController.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
          ),
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: MatchPrivateNoteAccordion(
                noteController: noteController,
                isDark: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MatchPrivateNoteAccordion), findsOneWidget);
      expect(find.text('＋ 運営メモ・特記事項を追加（任意）'), findsOneWidget);
      // 折りたたみ時は入力欄が非表示
      expect(find.byType(TextField), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'MatchPrivateNoteAccordionの展開状態において特記事項入力欄と注意書きが視覚的整合性を保ち描画されること',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(414, 896);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final noteController = TextEditingController(text: '相手先鋒上段、主審交代注意');
        addTearDown(noteController.dispose);

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              extensions: [
                AppThemeColors.ofMode(isDark: false, mode: 'normal'),
              ],
            ),
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: MatchPrivateNoteAccordion(
                  noteController: noteController,
                  isDark: false,
                  trailingAction: const Text('カンマ（,）'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(MatchPrivateNoteAccordion), findsOneWidget);
        expect(find.text('📝 運営メモ・特記事項（入力あり）'), findsOneWidget);
        expect(
          find.text('※このメモは大会ホーム・チーム試合状況にのみ表示され、PDFや外部試合結果には出力されません'),
          findsOneWidget,
        );
        expect(find.text('カンマ（,）'), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('相手先鋒上段、主審交代注意'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
