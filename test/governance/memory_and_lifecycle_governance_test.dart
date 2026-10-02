import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Governance] 第14条 ガバナンス監査において メモリ保護・LRU上限 ＆ リソース明示解放（リーク根絶）規約', () {
    test(
      'LRUキャッシュ上限＆解放に関して、 program_viewer_pdf_page_cache.dart における LRU 上限 ＆ clearUrl 規約こと',
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
          content.contains('void clearUrl(String url'),
          isTrue,
          reason: 'ビューワー画面を閉じた際に単一ページPDFバイトを即座に解放するための clearUrl メソッドが必須です。',
        );
      },
    );

    test(
      'ビューア画面・PDFサービスメモリ解放に関して、 program_viewer_screen.dart & pdf_service.dart のキャッシュ解放規約こと',
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

    test('コントローラー明示解放に関して、 各種画面・シート・ガードにおける TextEditingController 解放規約こと', () {
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

      // 5. 今回最適化したシート・カード群
      expect(
        orderSetupFile.readAsStringSync().contains('c.dispose();'),
        isTrue,
        reason:
            'order_setup_league_participants_section.dart で controllers が一括破棄されていること',
      );

      final masterOrgFile = File(
        'lib/admin/presentation/components/master_register_organization_bottom_sheet.dart',
      );
      expect(masterOrgFile.existsSync(), isTrue);
      expect(
        masterOrgFile.readAsStringSync().contains('controller.dispose();'),
        isTrue,
        reason:
            'master_register_organization_bottom_sheet.dart で controller が破棄されていること',
      );

      final shareImportFile = File(
        'lib/features/tournament/presentation/components/share_import/share_import_edit_sheets.dart',
      );
      expect(shareImportFile.existsSync(), isTrue);
      expect(
        shareImportFile.readAsStringSync().contains('controller.dispose();'),
        isTrue,
        reason: 'share_import_edit_sheets.dart で controller が破棄されていること',
      );

      final createTournamentFile = File(
        'lib/features/tournament/presentation/operate/components/create_tournament/create_tournament_import_teams_card.dart',
      );
      expect(createTournamentFile.existsSync(), isTrue);
      expect(
        createTournamentFile.readAsStringSync().contains(
          'controller.dispose();',
        ),
        isTrue,
        reason:
            'create_tournament_import_teams_card.dart で controller が破棄されていること',
      );
    });

    test('グローバルアナウンス購読解除＆既読トリムに関して、 cancelGlobalAnnouncements ＆ 既読ID上限トリム規約こと', () {
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
    });

    test(
      'プロバイダ autoDispose & keepAlive 適正管理に関して、 matchList / viewer / sound プロバイダのライフサイクル規約こと',
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

    test(
      '非同期リスナー・タイマー完全解放に関して、 StreamSubscription / Timer / AnimationController の dispose 明示解放規約こと',
      () {
        // 1. thermal_floating_toast.dart
        final toastFile = File(
          'lib/shared/widgets/thermal_floating_toast.dart',
        );
        expect(toastFile.existsSync(), isTrue);
        final toastContent = toastFile.readAsStringSync();
        expect(
          toastContent.contains('_subscription?.cancel();'),
          isTrue,
          reason: 'ThermalToastListener で _subscription が cancel されていること',
        );
        expect(
          toastContent.contains('_dismissTimer?.cancel();'),
          isTrue,
          reason: 'ThermalToastListener で _dismissTimer が cancel されていること',
        );
        expect(
          toastContent.contains('_animController.dispose();'),
          isTrue,
          reason:
              '_ThermalFloatingToastView で _animController が dispose されていること',
        );

        // 2. quick_memo_screen.dart & quick_memo_bottom_sheet.dart
        final memoScreenFile = File(
          'lib/features/tournament/presentation/components/program_management/quick_memo_screen.dart',
        );
        expect(memoScreenFile.existsSync(), isTrue);
        final memoScreenContent = memoScreenFile.readAsStringSync();
        expect(
          memoScreenContent.contains('_memoSubscription?.cancel();'),
          isTrue,
          reason: 'QuickMemoScreen で _memoSubscription が cancel されていること',
        );
        expect(
          memoScreenContent.contains('_textController.dispose();'),
          isTrue,
          reason: 'QuickMemoScreen で _textController が dispose されていること',
        );

        final memoSheetFile = File(
          'lib/features/tournament/presentation/components/program_management/quick_memo_bottom_sheet.dart',
        );
        expect(memoSheetFile.existsSync(), isTrue);
        final memoSheetContent = memoSheetFile.readAsStringSync();
        expect(
          memoSheetContent.contains('_memoSubscription?.cancel();'),
          isTrue,
          reason: 'QuickMemoBottomSheet で _memoSubscription が cancel されていること',
        );
        expect(
          memoSheetContent.contains('_textController.dispose();'),
          isTrue,
          reason: 'QuickMemoBottomSheet で _textController が dispose されていること',
        );

        // 3. user_data_cloud_sync_manager.dart
        final userSyncFile = File(
          'lib/features/auth/application/user_data_cloud_sync_manager.dart',
        );
        expect(userSyncFile.existsSync(), isTrue);
        final userSyncContent = userSyncFile.readAsStringSync();
        expect(
          userSyncContent.contains('_authSubscription?.cancel();') ||
              userSyncContent.contains('dispose()'),
          isTrue,
          reason: 'UserDataCloudSyncManager で Subscription が解放されていること',
        );
      },
    );

    test('UI層プロバイダライフサイクル ＆ 外部リソース（Timer/Audio/FocusNode）明示破棄規約こと', () {
      final bunaiksenFile = File(
        'lib/features/tournament/presentation/providers/bunaiksen_provider.dart',
      );
      if (bunaiksenFile.existsSync()) {
        final content = bunaiksenFile.readAsStringSync();
        expect(
          content.contains('_sub?.cancel()') && content.contains('dispose()'),
          isTrue,
          reason: 'UI層プロバイダは購読破棄と dispose メソッドを保持する必要があります。',
        );
      }

      final soundFile = File(
        'lib/shared/application/services/sound_service.dart',
      );
      expect(soundFile.existsSync(), isTrue);
      expect(soundFile.readAsStringSync().contains('dispose()'), isTrue);
    });
  });
}
