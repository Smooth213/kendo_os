import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/official_record_export_bar.dart';
import 'package:kendo_os/shared/application/services/csv_service.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('🥋 【E2E】公式記録 複数カテゴリ混在大会 全カテゴリ一括出力フロー完全検証', () {
    final categories = ['小学生低学年の部', '小学生高学年の部', '中学生の部', '一般の部'];

    List<({String categoryName, List<Map<String, dynamic>> groupDataList})>
    generate4CategoryData() {
      return categories.map((cat) {
        final matches = <MatchModel>[
          MatchModel(
            id: 'm_${cat}_1',
            tournamentId: 'tour_4cat',
            category: cat,
            matchType: '個人戦',
            order: 1.0,
            redName: '紅組: 選手A',
            whiteName: '白組: 選手B',
            redScore: 2,
            whiteScore: 1,
            status: 'finished',
          ),
          MatchModel(
            id: 'm_${cat}_2',
            tournamentId: 'tour_4cat',
            category: cat,
            matchType: '個人戦',
            order: 2.0,
            redName: '青組: 選手C',
            whiteName: '緑組: 選手D',
            redScore: 0,
            whiteScore: 2,
            status: 'finished',
          ),
        ];

        return (
          categoryName: cat,
          groupDataList: [
            {'groupName': '決勝トーナメント', 'matches': matches},
          ],
        );
      }).toList();
    }

    test('1. 4カテゴリ混在データから全カテゴリ一括CSV文字列およびバイト配列が欠損なく生成されること', () async {
      final allCategoryData = generate4CategoryData();
      expect(allCategoryData.length, 4);

      // CSV生成検証
      final csvString = CsvService.generateMultiCategoryCsvString(
        allCategoryData,
      );
      expect(
        csvString.startsWith('\uFEFF'),
        isTrue,
        reason: 'Excel対策のBOMが付与されていること',
      );

      for (final cat in categories) {
        expect(csvString.contains(cat), isTrue, reason: '$cat がCSVに含まれていること');
      }
      expect(csvString.contains('決勝トーナメント'), isTrue);
      expect(csvString.contains('選手A'), isTrue);
      expect(csvString.contains('選手D'), isTrue);

      // 非同期バイト生成 (Isolate/バックグラウンド) 検証
      final bytes = await CsvService.generateCsvBytesAsync('全カテゴリ', [
        {'groupName': '統合', 'matches': <MatchModel>[]},
      ]);
      expect(bytes.isNotEmpty, isTrue);
    });

    testWidgets('2. UI上での全カテゴリエクスポートトグル切替・プログレス表示・完了通知のライフサイクル検証', (
      tester,
    ) async {
      OfficialRecordExportScope currentScope =
          OfficialRecordExportScope.current;
      bool isExporting = false;
      String? exportingType;

      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.light().copyWith(extensions: [themeColors]),
            home: StatefulBuilder(
              builder: (ctx, setState) {
                return Scaffold(
                  body: Column(
                    children: [
                      OfficialRecordExportBar(
                        isExporting: isExporting,
                        exportingType: exportingType,
                        isDark: false,
                        hasMultipleCategories: true,
                        exportScope: currentScope,
                        onScopeChanged: (newScope) {
                          setState(() => currentScope = newScope);
                        },
                        onPdfPressed: () async {
                          setState(() {
                            isExporting = true;
                            exportingType = 'pdf';
                          });
                          await Future.delayed(
                            const Duration(milliseconds: 50),
                          );
                          setState(() {
                            isExporting = false;
                            exportingType = null;
                          });
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text(
                                  currentScope == OfficialRecordExportScope.all
                                      ? '全4カテゴリの一括PDF出力を完了しました'
                                      : 'PDF出力を完了しました',
                                ),
                              ),
                            );
                          }
                        },
                        onImagePressed: () {},
                        onCsvPressed: () {},
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 初期状態: 個別カテゴリ出力モード
      expect(find.text('PDF'), findsOneWidget);
      expect(find.text('全カテゴリを一括出力'), findsOneWidget);

      // スイッチをタップして「全カテゴリ一括出力」へ切り替え
      await tester.tap(find.text('全カテゴリを一括出力'));
      await tester.pumpAndSettle();

      // ボタンの表記が「PDF（全）」に変わっていること
      expect(find.text('PDF（全）'), findsOneWidget);

      // PDF（全）ボタンをタップして出力開始
      await tester.tap(find.text('PDF（全）'));
      await tester.pump(); // プログレス開始

      // インジケーター表示中
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 100)); // 出力完了
      await tester.pumpAndSettle();

      // 完了スナックバーの表示確認
      expect(find.text('全4カテゴリの一括PDF出力を完了しました'), findsOneWidget);
    });
  });
}
