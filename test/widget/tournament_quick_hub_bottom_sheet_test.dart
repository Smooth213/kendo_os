import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/presentation/providers/unread_announcement_provider.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/tournament_quick_hub_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/program_list_provider.dart';
import 'package:kendo_os/shared/domain/entities/program_model.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final dummyPrograms = [
    ProgramModel(
      id: 'prog_1',
      tournamentId: 'tour_hub_test',
      title: '進行表',
      fileUrl: 'https://example.com/sheet.png',
      fileType: 'image',
      pageCount: 1,
      createdAt: DateTime(2026, 9, 1),
    ),
  ];

  Widget createTestWidget({
    bool isViewerMode = false,
    int unreadCount = 0,
    bool isDark = false,
  }) {
    final themeColors = AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
    return ProviderScope(
      overrides: [
        permissionProvider.overrideWithValue(
          PermissionState(
            role: isViewerMode ? UserRole.viewer : UserRole.operator,
          ),
        ),
        programListProvider(
          'tour_hub_test',
        ).overrideWith((ref) => Stream.value(dummyPrograms)),
        unreadAnnouncementCountProvider((
          tournamentId: 'tour_hub_test',
          isStaffRoom: !isViewerMode,
        )).overrideWith((ref) => Stream.value(unreadCount)),
        unreadAnnouncementCountProvider((
          tournamentId: 'tour_hub_test',
          isStaffRoom: isViewerMode,
        )).overrideWith((ref) => Stream.value(unreadCount)),
      ],
      child: MaterialApp(
        theme: (isDark ? ThemeData.dark() : ThemeData.light()).copyWith(
          extensions: [themeColors],
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Center(
                child: ElevatedButton(
                  onPressed: () {
                    TournamentQuickHubBottomSheet.show(
                      context,
                      tournamentId: 'tour_hub_test',
                      isViewerMode: isViewerMode,
                    );
                  },
                  child: const Text('Open Hub'),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  group('🥋 TournamentQuickHubBottomSheet ウィジェットテスト', () {
    testWidgets('シート展開時に全7つの主要機能項目が表示されること（スタッフモード）', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(isViewerMode: false));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Hub'));
      await tester.pumpAndSettle();

      // ヘッダー
      expect(find.text('大会クイック機能'), findsOneWidget);

      // 1. プログラム・進行表
      expect(find.text('大会プログラム・進行表'), findsOneWidget);
      expect(find.text('手書きペン対応'), findsOneWidget);

      // 2. チーム試合状況
      expect(find.text('チーム試合状況'), findsOneWidget);

      // 3. 公式記録・対戦表
      expect(find.text('公式記録・対戦表'), findsOneWidget);

      // 4. クイックメモ
      expect(find.text('クイックメモ'), findsOneWidget);

      // 5. お知らせ・連絡
      expect(find.text('お知らせ・連絡'), findsOneWidget);

      // 6. 大会設定（スタッフモードで表示）
      expect(find.text('大会設定'), findsOneWidget);

      // 7. ヘルプ・手引
      expect(find.text('ヘルプ・手引'), findsOneWidget);
    });

    testWidgets('観客モード（isViewerMode=true）では大会設定タイルが表示されないこと', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(isViewerMode: true));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Hub'));
      await tester.pumpAndSettle();

      expect(find.text('大会プログラム・進行表'), findsOneWidget);
      expect(find.text('チーム試合状況'), findsOneWidget);
      expect(find.text('公式記録・対戦表'), findsOneWidget);
      expect(find.text('クイックメモ'), findsOneWidget);
      expect(find.text('お知らせ・連絡'), findsOneWidget);
      expect(find.text('ヘルプ・手引'), findsOneWidget);

      // 観客モードでは大会設定は非表示
      expect(find.text('大会設定'), findsNothing);
    });

    testWidgets('未読アナウンスがある場合、お知らせタイルに数字バッジが表示されること', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestWidget(isViewerMode: false, unreadCount: 3),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Hub'));
      await tester.pumpAndSettle();

      // 未読件数 3 の表示
      expect(find.text('3'), findsOneWidget);
      expect(find.text('3 件の新着あり'), findsOneWidget);
    });

    testWidgets('閉じるボタンをタップするとシートが閉じること', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Hub'));
      await tester.pumpAndSettle();

      expect(find.byType(TournamentQuickHubBottomSheet), findsOneWidget);

      // 閉じるアイコンをタップ
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(TournamentQuickHubBottomSheet), findsNothing);
    });
  });
}
