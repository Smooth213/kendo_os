import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🧹 【第14条 ガバナンス監査】メモリ保護・LRU上限 ＆ リソース明示解放（リーク根絶）規約', () {
    test(
      'Rule 1: [LRUキャッシュ上限＆解放] program_viewer_pdf_page_cache.dart における LRU 上限 ＆ clearUrl 規約',
      () {
        final file = File(
          'lib/features/tournament/presentation/components/program_viewer/program_viewer_pdf_page_cache.dart',
        );
        expect(file.existsSync(), isTrue);
        final content = file.readAsStringSync();

        expect(
          content.contains('maxCachedPagesPerDoc'),
          isTrue,
          reason: '無制限なPDFバイト蓄積を防ぐため、maxCachedPagesPerDoc 定数によるLRU上限が必要です。',
        );

        expect(
          content.contains('void clearUrl(String url)'),
          isTrue,
          reason: 'ビューワー画面を閉じた際に単一ページPDFバイトを即座に解放するための clearUrl メソッドが必須です。',
        );
      },
    );

    test(
      'Rule 2: [ビューア画面・PDFサービスメモリ解放] program_viewer_screen.dart & pdf_service.dart のキャッシュ解放規約',
      () {
        final viewerFile = File(
          'lib/features/tournament/presentation/operate/screens/program_viewer_screen.dart',
        );
        expect(viewerFile.existsSync(), isTrue);
        final viewerContent = viewerFile.readAsStringSync();
        expect(
          viewerContent.contains('ProgramViewerPdfPageCache.shared.clear()'),
          isTrue,
        );
        expect(
          viewerContent.contains('PaintingBinding.instance.imageCache.clear()'),
          isTrue,
        );

        final pdfFile = File('lib/features/pdf/pdf_service.dart');
        expect(pdfFile.existsSync(), isTrue);
        final pdfContent = pdfFile.readAsStringSync();
        expect(
          pdfContent.contains('PaintingBinding.instance.imageCache.clear()'),
          isTrue,
        );
      },
    );

    test('Rule 3: [コントローラー明示解放] 各種画面・シート・ガードにおける TextEditingController 解放規約', () {
      // 1. timeline_rename_team_sheet.dart
      final renameFile = File(
        'lib/features/tournament/presentation/operate/components/timeline/timeline_rename_team_sheet.dart',
      );
      expect(renameFile.existsSync(), isTrue);
      final renameContent = renameFile.readAsStringSync();
      expect(
        renameContent.contains(
          'class TimelineRenameTeamSheet extends StatefulWidget',
        ),
        isTrue,
      );
      expect(renameContent.contains('_controller.dispose()'), isTrue);

      // 2. critical_action_guard.dart
      final guardFile = File('lib/shared/widgets/critical_action_guard.dart');
      expect(guardFile.existsSync(), isTrue);
      final guardContent = guardFile.readAsStringSync();
      expect(guardContent.contains('pinController.dispose()'), isTrue);

      // 3. app_search_header.dart & multi_player_select_input.dart
      final searchHeaderFile = File(
        'lib/shared/widgets/app_search_header.dart',
      );
      final multiPlayerFile = File(
        'lib/shared/widgets/multi_player_select_input.dart',
      );
      expect(searchHeaderFile.existsSync(), isTrue);
      expect(multiPlayerFile.existsSync(), isTrue);
      expect(
        searchHeaderFile.readAsStringSync().contains('_controller.dispose()'),
        isTrue,
      );
      expect(
        multiPlayerFile.readAsStringSync().contains(
          '_displayController.dispose()',
        ),
        isTrue,
      );

      // 4. ダイアログコントローラー群
      final orderSetupFile = File(
        'lib/features/tournament/presentation/operate/components/order_setup/order_setup_league_participants_section.dart',
      );
      final commentDialogFile = File(
        'lib/features/tournament/presentation/operate/components/timeline/timeline_edit_comment_dialog.dart',
      );
      final announceDialogFile = File(
        'lib/features/tournament/presentation/operate/components/timeline/timeline_unified_announce_dialog.dart',
      );
      final ruleHelperFile = File(
        'lib/features/tournament/presentation/operate/components/rules/sections/match_rule_dialog_helper.dart',
      );
      expect(
        orderSetupFile.readAsStringSync().contains('nameController.dispose();'),
        isTrue,
      );
      expect(
        commentDialogFile.readAsStringSync().contains(
          '.then((_) => controller.dispose());',
        ),
        isTrue,
      );
      expect(
        announceDialogFile.readAsStringSync().contains(
          'titleController.dispose()',
        ),
        isTrue,
      );
      expect(
        ruleHelperFile.readAsStringSync().contains('minCtrl.dispose()'),
        isTrue,
      );
    });

    test(
      'Rule 4: [グローバルアナウンス購読解除＆既読トリム] cancelGlobalAnnouncements ＆ 既読ID上限トリム規約',
      () {
        final announceFile = File(
          'lib/features/match/presentation/components/announce_popup_manager.dart',
        );
        expect(announceFile.existsSync(), isTrue);
        expect(
          announceFile.readAsStringSync().contains(
            'void cancelGlobalAnnouncements({String? tournamentId})',
          ),
          isTrue,
        );

        final readAnnounceFile = File(
          'lib/features/match/presentation/providers/read_announcements_provider.dart',
        );
        expect(readAnnounceFile.existsSync(), isTrue);
        final readContent = readAnnounceFile.readAsStringSync();
        expect(
          readContent.contains('maxReadCount') && readContent.contains('200'),
          isTrue,
        );
        expect(readContent.contains('_trimIds'), isTrue);
      },
    );

    test(
      'Rule 5: [プロバイダ autoDispose & keepAlive 適正管理] matchList / viewer / sound プロバイダのライフサイクル規約',
      () {
        final matchFile = File(
          'lib/features/tournament/presentation/operate/providers/match_list_provider.dart',
        );
        expect(matchFile.existsSync(), isTrue);
        final matchContent = matchFile.readAsStringSync();
        final hasAutoDispose =
            matchContent.contains(
              'StreamProvider.family.autoDispose<List<MatchModel>, String>',
            ) ||
            RegExp(
              r'StreamProvider\.family\s*\.autoDispose<List<MatchModel>,\s*String>',
            ).hasMatch(matchContent);
        expect(hasAutoDispose, isTrue);
        expect(matchContent.contains('ref.keepAlive()'), isTrue);

        final viewerFile = File(
          'lib/features/viewer/providers/viewer_view_state_provider.dart',
        );
        expect(viewerFile.existsSync(), isTrue);
        final viewerContent = viewerFile.readAsStringSync();
        expect(
          viewerContent.contains(
                'viewerMatchProjectionProvider = StreamProvider.family\n    .autoDispose<MatchProjection?, String>(',
              ) ||
              viewerContent.contains(
                'viewerMatchProjectionProvider = StreamProvider.family.autoDispose<MatchProjection?, String>(',
              ),
          isTrue,
        );
        expect(viewerContent.contains('ref.keepAlive()'), isTrue);

        final soundFile = File(
          'lib/shared/application/services/sound_service.dart',
        );
        expect(soundFile.existsSync(), isTrue);
        expect(
          soundFile.readAsStringSync().contains(
            'ref.onDispose(() => service.dispose())',
          ),
          isTrue,
        );
      },
    );
  });
}
