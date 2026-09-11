import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/band/domain/entities/band_group_model.dart';
import 'package:kendo_os/features/band/presentation/components/band_share_button.dart';
import 'package:kendo_os/features/band/presentation/providers/band_provider.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/domain/team_progress_model.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/floating_dock_sheet_manager.dart';
import 'package:kendo_os/features/tournament/presentation/operate/settings_screen.dart';
import 'package:kendo_os/shared/domain/entities/settings_model.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';

class MockSettingsNotifier extends SettingsNotifier {
  @override
  SettingsModel build() =>
      const SettingsModel(securityLevel: 1, enableLiquidGlass: false);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (
          MethodCall methodCall,
        ) async {
          if (methodCall.method == 'Clipboard.setData') {
            return null;
          }
          if (methodCall.method == 'Clipboard.getData') {
            return <String, dynamic>{'text': ''};
          }
          return null;
        });
  });

  group('🥋 ドック内BANDボタン＆子シート検証テスト', () {
    testWidgets('ドックのシステム設定からBAND連携タイルをタップしてグループ管理シートと追加ダイアログが開くこと', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsProvider.overrideWith(() => MockSettingsNotifier()),
            bandGroupsStreamProvider.overrideWith(
              (ref) => Stream.value([
                const BandGroupModel(
                  id: 'band_1',
                  name: '低学年チーム',
                  url: 'https://band.us/band/12345',
                  order: 0,
                ),
              ]),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: Center(child: Text('ホーム画面'))),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.text('ホーム画面'));
      FloatingDockSheetManager.show(
        context: context,
        builder: (_) => const SettingsScreen(isBottomSheet: true),
      );
      await tester.pumpAndSettle();

      // スクロールしてBAND連携タイルを表示させる
      await tester.drag(find.byType(ListView).first, const Offset(0, -800));
      await tester.pumpAndSettle();

      final bandTile = find.text('BAND連携・LIVE配信設定');
      expect(bandTile, findsOneWidget);

      // スクロールして可視化してからタップ
      await tester.ensureVisible(bandTile);
      await tester.pumpAndSettle();
      await tester.tap(bandTile);
      await tester.pumpAndSettle();

      // BandSettingsManagementSheet のタイトル「BANDグループ管理」が表示されること
      expect(find.text('BANDグループ管理'), findsOneWidget);

      // 編集アイコンをタップしてダイアログが開くこと
      await tester.tap(find.byIcon(Icons.edit_outlined).first);
      await tester.pumpAndSettle();
      expect(find.text('BANDグループの編集'), findsOneWidget);

      // ダイアログを閉じる
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();
      expect(find.text('BANDグループの編集'), findsNothing);
    });

    testWidgets(
      'FloatingDockSheetManager内でBandShareButtonをタップするとBandGroupSelectSheetが開くこと',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final mockStatus = TeamProgressStatus(
          teamName: '東京道場A',
          categoryName: '高学年の部',
          tournamentId: 'tourney_1',
          completedCount: 0,
          totalCount: 1,
          hasLiveMatch: true,
          matches: const [
            MatchModel(
              id: 'm1',
              tournamentId: 'tourney_1',
              matchType: 'team',
              redName: '東京道場A',
              whiteName: '京都道場B',
              status: 'inProgress',
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentDojoIdProvider.overrideWith((ref) => 'test_dojo'),
              bandGroupsStreamProvider.overrideWith(
                (ref) => Stream.value([
                  const BandGroupModel(
                    id: 'band_1',
                    name: '高学年チーム',
                    url: 'https://band.us/band/99999',
                    order: 0,
                  ),
                ]),
              ),
            ],
            child: const MaterialApp(
              home: Scaffold(body: Center(child: Text('ホーム画面'))),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final context = tester.element(find.text('ホーム画面'));
        FloatingDockSheetManager.show(
          context: context,
          builder: (_) => Scaffold(
            body: Center(child: BandShareButton(teamStatus: mockStatus)),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(BandShareButton), findsOneWidget);
        expect(find.byType(OutlinedButton), findsOneWidget);

        // BANDボタンをタップ
        await tester.tap(find.byType(OutlinedButton));
        await tester.pump();
        await tester.pumpAndSettle();

        // BandGroupSelectSheet が前面に開くこと
        expect(find.text('BANDでLIVE配信・共有'), findsOneWidget);
        expect(find.text('高学年チーム'), findsOneWidget);
      },
    );
  });
}
