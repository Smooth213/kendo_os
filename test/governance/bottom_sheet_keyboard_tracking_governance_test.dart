import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_draggable_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_text_view.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

// ============================================================================
// 🥋 【第5条 第5項 ガバナンス監査】
// 全ボトムシート キーボード追従・自動全開・入力視認性保証ガバナンス監査
// ============================================================================
// ソフトウェアキーボード表示時に、ボトムシート内の入力欄やツールバーが背面に
// 隠れてしまう操作破綻を根絶するため、以下の3大規約を静的コード解析および
// ウィジェット検証により厳格に検証・担保します：
//
// 1. 【基盤ボトムシート規約】
//    AppBottomSheetContent が MediaQuery.viewInsets.bottom を下部パディングとして
//    必ず内包し、showAppBottomSheet のデフォルトが isScrollControlled: true であること。
// 2. 【ドック式ボトムシート規約】
//    DockDraggableSheet がキーボード出現時に自動的に全開（maxChildSize: 0.95）へ
//    アニメーション展開すること。
// 3. 【全ボトムシートページ網羅規約】
//    アプリ内に存在するすべてのボトムシート（ドック型・モーダル型・マスタ編集型）が
//    キーボード追従構造を持ち、isScrollControlled: true または DockDraggableSheet を
//    採用していること。
// ============================================================================

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Governance] 第5条 第5項において 全ボトムシート・キーボード追従・自動全開・入力視認性保証ガバナンス監査', () {
    // -------------------------------------------------------------------------
    // 1. 基盤ボトムシート規約の検証
    // -------------------------------------------------------------------------
    test(
      '基盤 showAppBottomSheet に関して、デフォルトで isScrollControlled: true が設定されキーボード展開空間が保証されていること',
      () {
        final file = File('lib/shared/widgets/app_bottom_sheet.dart');
        expect(file.existsSync(), isTrue);
        final content = file.readAsStringSync();

        expect(
          content.contains('bool isScrollControlled = true'),
          isTrue,
          reason:
              'showAppBottomSheet の isScrollControlled はキーボード追従のため true でなければなりません',
        );

        expect(
          content.contains('MediaQuery.of(context).viewInsets.bottom'),
          isTrue,
          reason:
              'AppBottomSheetContent は viewInsets.bottom を自動パディングとして適用していなければなりません',
        );
      },
    );

    // -------------------------------------------------------------------------
    // 2. ドック式ボトムシート（DockDraggableSheet）自動全開機構の検証
    // -------------------------------------------------------------------------
    test(
      '基盤 DockDraggableSheet に関して、didChangeDependencies でキーボード出現を検知し自動全開（maxChildSize）されること',
      () {
        final file = File(
          'lib/features/tournament/presentation/components/program_management/dock_draggable_sheet.dart',
        );
        expect(file.existsSync(), isTrue);
        final content = file.readAsStringSync();

        expect(
          content.contains('MediaQuery.of(context).viewInsets.bottom > 0'),
          isTrue,
          reason: 'DockDraggableSheet は viewInsets.bottom > 0 を検知していなければなりません',
        );
        expect(
          content.contains('_expand()'),
          isTrue,
          reason: 'キーボード出現時に _expand() が呼び出されなければなりません',
        );
      },
    );

    // -------------------------------------------------------------------------
    // 3. アプリ内全ボトムシートページの静的スキャン網羅検証
    // -------------------------------------------------------------------------
    test(
      'アプリ内全ボトムシートに関して、モーダル型は showAppBottomSheet かつ isScrollControlled: true、ドック型は DockDraggableSheet を採用していること',
      () {
        // アプリ内の全ボトムシート一覧（ドック型、マスタ型、大会運営型、タイムライン型、共有型）
        final allBottomSheetFiles = [
          // ドック型シート
          'lib/features/tournament/presentation/components/program_management/quick_memo_bottom_sheet.dart',
          'lib/features/tournament/presentation/components/program_management/program_bottom_sheet.dart',
          'lib/features/tournament/presentation/components/program_management/manual_bottom_sheet.dart',
          'lib/features/tournament/presentation/components/program_management/dock_timer_bottom_sheet.dart',
          'lib/features/tournament/presentation/components/program_management/dock_items_reorder_bottom_sheet.dart',
          'lib/features/tournament/presentation/components/program_management/viewer_qr_bottom_sheet.dart',
          'lib/features/tournament/presentation/components/bunaiksen/bunaiksen_dock_standings_sheet.dart',
          'lib/features/tournament/presentation/components/bunaiksen/bunaiksen_dock_calendar_sheet.dart',
          'lib/features/tournament/presentation/components/bunaiksen/bunaiksen_dock_matches_sheet.dart',
          'lib/features/tournament/presentation/components/bunaiksen/calculator/bunaiksen_dock_calculator_sheet.dart',
          'lib/features/match/presentation/components/announce_history_bottom_sheet.dart',

          // マスタ編集・登録系シート
          'lib/admin/presentation/components/master_menu_bottom_sheet.dart',
          'lib/admin/presentation/components/master_player_edit_bottom_sheet.dart',
          'lib/admin/presentation/components/master_register_organization_bottom_sheet.dart',
          'lib/admin/presentation/components/master_edit_organization_bottom_sheet.dart',
          'lib/admin/presentation/components/master_team_name_management_sheet.dart',

          // タイムライン・アナウンス・コメント系シート
          'lib/features/tournament/presentation/operate/components/timeline/timeline_unified_announce_dialog.dart',
          'lib/features/tournament/presentation/operate/components/timeline/timeline_edit_comment_dialog.dart',
          'lib/features/tournament/presentation/operate/components/timeline/timeline_rename_team_sheet.dart',

          // チーム登録・選手編集・試合設定系シート
          'lib/features/tournament/presentation/operate/components/team_registration/team_edit_bottom_sheet.dart',
          'lib/features/tournament/presentation/operate/components/team_registration/team_registration_player_select_bottom_sheet.dart',
          'lib/features/tournament/presentation/operate/components/match_screen/match_player_name_edit_bottom_sheet.dart',
          'lib/features/tournament/presentation/operate/components/match_screen/match_share_options_bottom_sheet.dart',
          'lib/features/tournament/presentation/operate/components/match_screen/renseikai_add_next_match_bottom_sheet.dart',
          'lib/features/tournament/presentation/operate/components/bulk_rule_edit_sheet.dart',
          'lib/features/tournament/presentation/operate/components/home/tournament_edit_bottom_sheet.dart',

          // 共有・インポート・設定系シート
          'lib/features/tournament/presentation/components/share_import/tournament_share_import_sheet.dart',
          'lib/features/tournament/presentation/components/share_import/share_import_edit_sheets.dart',
          'lib/features/viewer/presentation/components/viewer_settings_bottom_sheet.dart',
          'lib/shared/widgets/room_join_qr_dialog.dart',
        ];

        for (final path in allBottomSheetFiles) {
          final file = File(path);
          expect(file.existsSync(), isTrue, reason: 'ボトムシートファイル $path が存在すること');

          final content = file.readAsStringSync();

          // 規約1: showModalBottomSheet の直接呼び出しは禁止（showAppBottomSheet を利用すること）
          expect(
            content.contains('showModalBottomSheet('),
            isFalse,
            reason:
                '$path で showModalBottomSheet が直接使われています。showAppBottomSheet を利用してください',
          );

          // 規約2: ドック型シートは DockDraggableSheet を内包、それ以外は showAppBottomSheet または AppBottomSheetContent を使用していること
          final isDockSheet = content.contains('DockDraggableSheet(');
          final usesAppBottomSheet =
              content.contains('showAppBottomSheet(') ||
              content.contains('AppBottomSheetContent(');

          expect(
            isDockSheet || usesAppBottomSheet,
            isTrue,
            reason:
                '$path は DockDraggableSheet または showAppBottomSheet / AppBottomSheetContent のいずれかを採用していなければなりません',
          );
        }
      },
    );

    // -------------------------------------------------------------------------
    // 4. ウィジェット統合動的検証
    // -------------------------------------------------------------------------
    testWidgets('DockDraggableSheet ウィジェットにおいて、キーボード出現時に自動全開アニメーションが動作すること', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(400, 800),
              viewInsets: EdgeInsets.zero,
            ),
            child: Material(
              child: DockDraggableSheet(
                initialChildSize: 0.58,
                maxChildSize: 0.95,
                builder: (context, scrollController) =>
                    const SizedBox(height: 200, child: Text('Sheet Content')),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // キーボード出現
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(400, 800),
              viewInsets: EdgeInsets.only(bottom: 280),
            ),
            child: Material(
              child: DockDraggableSheet(
                initialChildSize: 0.58,
                maxChildSize: 0.95,
                builder: (context, scrollController) =>
                    const SizedBox(height: 200, child: Text('Sheet Content')),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      final scope = tester.widget<DockSheetScope>(find.byType(DockSheetScope));
      expect(scope.isExpanded, isTrue);
    });

    testWidgets('QuickMemoTextView ウィジェットにおいて、キーボード出現時にツールバーとテキスト余白が完全追従すること', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'ガバナンステストメモ');
      final focusNode = FocusNode();
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(400, 800),
              viewInsets: EdgeInsets.only(bottom: 300),
              padding: EdgeInsets.only(bottom: 20),
            ),
            child: Material(
              child: QuickMemoTextView(
                controller: controller,
                focusNode: focusNode,
                themeColors: themeColors,
                isDark: false,
                onChanged: () {},
                onInsertTimestamp: () {},
                onCopy: () {},
                onClear: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final toolbarPositioned = tester.widget<Positioned>(
        find
            .descendant(
              of: find.byType(QuickMemoTextView),
              matching: find.byType(Positioned),
            )
            .last,
      );

      // ツールバーの bottom が 300px 以上（キーボードの上）にあること
      expect(toolbarPositioned.bottom! >= 300, isTrue);

      controller.dispose();
      focusNode.dispose();
    });
  });
}
