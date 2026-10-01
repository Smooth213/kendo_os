import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/viewer/components/official_record_action_button.dart';
import 'package:kendo_os/features/viewer/components/viewer_bunaiksen_category_content.dart';
import 'package:kendo_os/features/viewer/services/viewer_bunaiksen_export_service.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Golden] 部内戦観戦公式記録ビューア視覚整合性テスト', () {
    final sampleMatches = [
      MatchModel(
        id: 'bm1',
        tournamentId: 'bunaiksen_20261001',
        category: '小学生部内戦の部',
        groupName: 'Aブロック',
        order: 1.0,
        redName: '佐藤',
        whiteName: '高橋',
        redScore: 2,
        whiteScore: 0,
        matchType: '選手',
        status: 'finished',
        note: '[リーグ戦]',
      ),
      MatchModel(
        id: 'bm2',
        tournamentId: 'bunaiksen_20261001',
        category: '小学生部内戦の部',
        groupName: 'Aブロック',
        order: 2.0,
        redName: '高橋',
        whiteName: '鈴木',
        redScore: 1,
        whiteScore: 1,
        matchType: '選手',
        status: 'finished',
        note: '[リーグ戦]',
      ),
    ];

    Widget buildViewerWidget({required Size screenSize, required bool isDark}) {
      final dummyStateController = StateController<bool>(false);
      final themeColors = AppThemeColors.ofMode(
        isDark: isDark,
        mode: isDark ? 'dark' : 'bunaiksen_viewer',
      );

      return ProviderScope(
        child: MaterialApp(
          theme: isDark
              ? ThemeData.dark().copyWith(extensions: [themeColors])
              : ThemeData.light().copyWith(extensions: [themeColors]),
          home: MediaQuery(
            data: MediaQueryData(size: screenSize),
            child: Scaffold(
              body: ViewerBunaiksenCategoryContent(
                category: '小学生部内戦の部',
                groupsMap: {'Aブロック': sampleMatches},
                cardColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                themeColors: themeColors,
                isDark: isDark,
                isExporting: false,
                isExportingController: dummyStateController,
                tDate: '2026年10月01日',
                exportService: const ViewerBunaiksenExportService(),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('スマホ標準幅390px ライトモードにおいて星取表とエクスポートバーが整然と描画されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildViewerWidget(screenSize: const Size(390, 844), isDark: false),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(OfficialRecordActionButton), findsNWidgets(2));
      expect(find.text('PDF印刷'), findsOneWidget);
      expect(find.text('画像シェア'), findsOneWidget);
    });

    testWidgets('タブレット幅800px ダークモードにおいて高コントラストで崩れなく描画されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildViewerWidget(screenSize: const Size(800, 1000), isDark: true),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(OfficialRecordActionButton), findsNWidgets(2));
      expect(find.text('PDF印刷'), findsOneWidget);
      expect(find.text('画像シェア'), findsOneWidget);
    });
  });
}
