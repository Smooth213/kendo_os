import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🛡️ 【Plan 6 ガバナンス監査】極限最適化・低負荷・絶対安定性 完走永続保証規約', () {
    test(
      '1. [UI層・選手一括選択仮想化] multi_player_select_input.dart で全選手の一斉生成が禁止され、ListView.builder が使用されていること',
      () {
        final file = File('lib/shared/widgets/multi_player_select_input.dart');
        expect(file.existsSync(), isTrue);
        final content = file.readAsStringSync();

        expect(
          content.contains('ListView.builder('),
          isTrue,
          reason:
              'multi_player_select_input.dart では ListView.builder による仮想化が必須',
        );

        // children: [...] に一斉 map するパターンの残存がないこと
        final hasUnvirtualizedList = RegExp(
          r'child:\s*ListView\(\s*children:\s*\[',
        ).hasMatch(content);
        expect(
          hasUnvirtualizedList,
          isFalse,
          reason:
              'multi_player_select_input.dart 内で非仮想化 ListView(children: [...]) が使われていないこと',
        );
      },
    );

    test(
      '2. [レンダリング負荷隔離] viewer_category_section_list.dart で RepaintBoundary による描画隔離および ViewerTeamGroupingHelper が配備されていること',
      () {
        final file = File(
          'lib/features/viewer/presentation/components/viewer_category_section_list.dart',
        );
        expect(file.existsSync(), isTrue);
        final content = file.readAsStringSync();

        expect(
          content.contains('RepaintBoundary('),
          isTrue,
          reason:
              'viewer_category_section_list.dart では各カテゴリセクションに RepaintBoundary の配置が必須',
        );

        expect(
          content.contains('ViewerCategorySection'),
          isTrue,
          reason: 'カテゴリセクションが独立したWidgetとして分割されていること',
        );

        expect(
          content.contains('ViewerTeamGroupingHelper'),
          isTrue,
          reason: '集計・ソート計算が純粋関数ヘルパー ViewerTeamGroupingHelper に分離されていること',
        );
      },
    );

    test(
      '3. [ネットワーク・ライフサイクル管理] announce_popup_manager.dart に cancelGlobalAnnouncements が公開されていること',
      () {
        final file = File(
          'lib/features/match/presentation/components/announce_popup_manager.dart',
        );
        expect(file.existsSync(), isTrue);
        final content = file.readAsStringSync();

        expect(
          content.contains(
            'void cancelGlobalAnnouncements({String? tournamentId})',
          ),
          isTrue,
          reason:
              'announce_popup_manager.dart に明示的購読解除用API cancelGlobalAnnouncements が配備されていること',
        );
      },
    );

    test(
      '4. [メモリライフサイクル管理] timeline_rename_team_sheet.dart が StatefulWidget として controller を dispose していること',
      () {
        final file = File(
          'lib/features/tournament/presentation/operate/components/timeline/timeline_rename_team_sheet.dart',
        );
        expect(file.existsSync(), isTrue);
        final content = file.readAsStringSync();

        expect(
          content.contains(
            'class TimelineRenameTeamSheet extends StatefulWidget',
          ),
          isTrue,
          reason: 'TimelineRenameTeamSheet は StatefulWidget でなければならない',
        );

        expect(
          content.contains('_controller.dispose()'),
          isTrue,
          reason: 'dispose() メソッド内で _controller.dispose() が呼ばれていること',
        );

        // build() メソッド内での新規インスタンス生成が禁止されていること
        final hasControllerInBuild = RegExp(
          r'Widget\s+build\([^)]*\)\s*\{[^}]*TextEditingController\(',
        ).hasMatch(content);
        expect(
          hasControllerInBuild,
          isFalse,
          reason: 'build() メソッド内で TextEditingController を直接生成してはならない',
        );
      },
    );

    test('5. [メモリライフサイクル管理] 各種ダイアログ・シートで TextEditingController が確実に破棄されていること', () {
      // order_setup_league_participants_section.dart
      final orderSetupFile = File(
        'lib/features/tournament/presentation/operate/components/order_setup/order_setup_league_participants_section.dart',
      );
      expect(orderSetupFile.existsSync(), isTrue);
      final orderSetupContent = orderSetupFile.readAsStringSync();
      expect(
        orderSetupContent.contains('finally {') &&
            orderSetupContent.contains('nameController.dispose();'),
        isTrue,
        reason:
            'order_setup_league_participants_section.dart で nameController が finally で dispose されていること',
      );

      // timeline_edit_comment_dialog.dart
      final commentDialogFile = File(
        'lib/features/tournament/presentation/operate/components/timeline/timeline_edit_comment_dialog.dart',
      );
      expect(commentDialogFile.existsSync(), isTrue);
      final commentContent = commentDialogFile.readAsStringSync();
      expect(
        commentContent.contains('.then((_) => controller.dispose());'),
        isTrue,
        reason:
            'timeline_edit_comment_dialog.dart で controller が .then で dispose されていること',
      );

      // timeline_unified_announce_dialog.dart
      final announceDialogFile = File(
        'lib/features/tournament/presentation/operate/components/timeline/timeline_unified_announce_dialog.dart',
      );
      expect(announceDialogFile.existsSync(), isTrue);
      final announceContent = announceDialogFile.readAsStringSync();
      expect(
        announceContent.contains('titleController.dispose()') &&
            announceContent.contains('bodyController.dispose()'),
        isTrue,
        reason:
            'timeline_unified_announce_dialog.dart でコントローラーが dispose されていること',
      );

      // match_rule_dialog_helper.dart
      final ruleHelperFile = File(
        'lib/features/tournament/presentation/operate/components/rules/sections/match_rule_dialog_helper.dart',
      );
      expect(ruleHelperFile.existsSync(), isTrue);
      final ruleHelperContent = ruleHelperFile.readAsStringSync();
      expect(
        ruleHelperContent.contains('minCtrl.dispose()') &&
            ruleHelperContent.contains('secCtrl.dispose()') &&
            ruleHelperContent.contains('ctrl.dispose()'),
        isTrue,
        reason:
            'match_rule_dialog_helper.dart で全カスタムダイアログのコントローラーが dispose されていること',
      );
    });
  });
}
