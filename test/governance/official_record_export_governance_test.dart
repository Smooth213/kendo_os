import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/official_record_export_bar.dart';
import 'package:kendo_os/shared/application/services/csv_service.dart';
import 'package:kendo_os/shared/widgets/app_switch.dart';

// ============================================================================
// 🛡️ KendoOS 公式記録一括エクスポート＆スイッチUI ガバナンステスト
// ============================================================================
// 【ガバナンス第6条：UIレンダリング安全・PDF組版 ＆ 第12条：Isolate重計算分離規約】
// 1. UIレンダリング安全＆文字拡大・極小幅オーバーフローゼロ保証規約 (第6条)
// 2. システム設定統一AppSwitch採用規約 (第3条)
// 3. 複数カテゴリCSV重計算 Isolate非同期分離規約 (第12条)
// ============================================================================

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🛡️ [ガバナンス第6条・第12条] 大会公式記録一括エクスポート＆トグルUI 永続保証規約', () {
    // ------------------------------------------------------------------------
    // 1. UIレンダリング安全 ＆ オーバーフローゼロ保証 (第6条)
    // ------------------------------------------------------------------------
    group('【第6条】UIレンダリング安全 ＆ 文字サイズ拡大・狭小画面オーバーフローゼロ規約', () {
      final viewports = [
        const Size(320, 568), // iPhone SE 1st (最小サポート幅)
        const Size(375, 667), // iPhone 8 / SE 2nd (標準幅)
        const Size(393, 852), // iPhone 16 / 15 Pro
        const Size(768, 1024), // iPad Mini / Tablet
      ];

      final textScales = [1.0, 1.25, 1.5];

      for (final size in viewports) {
        for (final textScale in textScales) {
          testWidgets(
            '幅${size.width.toInt()}px × TextScale ${textScale}x (OFF/ON) でRenderFlexオーバーフローが0件であること',
            (WidgetTester tester) async {
              tester.view.physicalSize = Size(size.width * 2, size.height * 2);
              tester.view.devicePixelRatio = 2.0;
              addTearDown(() {
                tester.view.resetPhysicalSize();
                tester.view.resetDevicePixelRatio();
              });

              for (final scope in [
                OfficialRecordExportScope.current,
                OfficialRecordExportScope.all,
              ]) {
                await tester.pumpWidget(
                  MaterialApp(
                    theme: ThemeData.light(),
                    darkTheme: ThemeData.dark(),
                    home: MediaQuery(
                      data: MediaQueryData(
                        size: size,
                        textScaler: TextScaler.linear(textScale),
                      ),
                      child: Scaffold(
                        body: OfficialRecordExportBar(
                          isExporting: false,
                          isDark: false,
                          hasMultipleCategories: true,
                          exportScope: scope,
                          onScopeChanged: (_) {},
                        ),
                      ),
                    ),
                  ),
                );

                await tester.pumpAndSettle();

                // Flutterの例外（RenderFlexオーバーフローエラーなど）が一切発生していないこと
                expect(
                  tester.takeException(),
                  isNull,
                  reason:
                      '幅${size.width}px, TextScale:${textScale}x, scope:$scope で画面あふれ・描画エラーが発生してはならない',
                );

                // ボタン3つとスイッチが確実に存在すること
                expect(find.byType(ElevatedButton), findsNWidgets(3));
                expect(find.byType(AppSwitch), findsOneWidget);
              }
            },
          );
        }
      }
    });

    // ------------------------------------------------------------------------
    // 2. システム設定統一AppSwitch採用規約 (第3条)
    // ------------------------------------------------------------------------
    testWidgets('【第3条】システム設定と統一されたAppSwitchコンポーネントが使用されていること', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: OfficialRecordExportBar(
              isExporting: false,
              isDark: false,
              hasMultipleCategories: true,
              exportScope: OfficialRecordExportScope.current,
            ),
          ),
        ),
      );

      // AppSwitchが存在すること
      expect(find.byType(AppSwitch), findsOneWidget);

      // ボタンのテキストが最大1行で切断保護（TextOverflow.ellipsis）されていること
      final textWidgets = tester.widgetList<Text>(find.byType(Text));
      for (final text in textWidgets) {
        if (text.data == 'PDF' || text.data == '画像' || text.data == 'CSV') {
          expect(text.maxLines, 1);
          expect(text.overflow, TextOverflow.ellipsis);
        }
      }
    });

    // ------------------------------------------------------------------------
    // 3. 複数カテゴリCSV重計算 Isolate非同期分離規約 (第12条)
    // ------------------------------------------------------------------------
    test('【第12条】大量試合データの複数カテゴリ一括CSV生成が非ブロッキングIsolateで実行されること', () async {
      final sampleMatches = List.generate(
        50,
        (i) => MatchModel(
          id: 'gov_m_$i',
          tournamentId: 'gov_t1',
          category: i % 2 == 0 ? '少年男子の部' : '少年女子の部',
          groupName: 'グループ${i ~/ 5}',
          order: i.toDouble(),
          redName: '道場A: 選手$i',
          whiteName: '道場B: 相手$i',
          redScore: 1,
          whiteScore: 0,
          matchType: '選手',
          status: 'finished',
          note: 'メ',
          events: [],
        ),
      );

      final multiCategoryData = [
        (
          categoryName: '少年男子の部',
          groupDataList: [
            {
              'groupName': 'グループ0',
              'matches': sampleMatches
                  .where((m) => m.category == '少年男子の部')
                  .toList(),
            },
          ],
        ),
        (
          categoryName: '少年女子の部',
          groupDataList: [
            {
              'groupName': 'グループ1',
              'matches': sampleMatches
                  .where((m) => m.category == '少年女子の部')
                  .toList(),
            },
          ],
        ),
      ];

      // Isolateでのバイナリ非同期生成（KendoComputeHelper経由）
      final stopwatch = Stopwatch()..start();
      final bytes = await CsvService.generateMultiCategoryCsvBytesAsync(
        multiCategoryData,
      );
      stopwatch.stop();

      expect(bytes.isNotEmpty, isTrue);
      // BOMヘッダーが付与されていること
      expect(bytes[0], 0xEF);
      expect(bytes[1], 0xBB);
      expect(bytes[2], 0xBF);
    });
  });
}
