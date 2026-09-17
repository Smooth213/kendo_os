import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🛡️ 【Plan 5 ガバナンス監査】極限最適化・低負荷・絶対安定性 完走永続保証規約', () {
    test('1. [ブートストラップ層] main.dart において 5大最適化パイプラインが確実に結合されていること', () {
      final mainFile = File('lib/main.dart');
      expect(mainFile.existsSync(), isTrue);
      final content = mainFile.readAsStringSync();

      // 1. WebPlatformOptimizer
      expect(
        content.contains('WebPlatformOptimizer.applyOptimizations()'),
        isTrue,
        reason:
            'main.dart で WebPlatformOptimizer.applyOptimizations() が呼ばれていること',
      );

      // 2. configureImageCache
      expect(
        content.contains('AppStartup.configureImageCache()'),
        isTrue,
        reason: 'main.dart で AppStartup.configureImageCache() が呼ばれていること',
      );

      // 3. configureFontOptimization
      expect(
        content.contains('AppStartup.configureFontOptimization()'),
        isTrue,
        reason: 'main.dart で AppStartup.configureFontOptimization() が呼ばれていること',
      );

      // 4. soundService prewarm
      expect(
        content.contains('soundServiceProvider') &&
            content.contains('.prewarm()'),
        isTrue,
        reason: 'main.dart で soundServiceProvider の prewarm が呼ばれていること',
      );

      // 5. userDataCloudSyncManager initialize
      expect(
        content.contains('userDataCloudSyncManagerProvider') &&
            content.contains('.initialize()'),
        isTrue,
        reason:
            'main.dart で userDataCloudSyncManagerProvider の initialize が呼ばれていること',
      );

      // 6. prewarmAppAssets
      expect(
        content.contains('AppStartup.prewarmAppAssets()'),
        isTrue,
        reason: 'main.dart で AppStartup.prewarmAppAssets() が呼ばれていること',
      );
    });

    test(
      '2. [UI層・候補リスト仮想化] smart_player_input.dart で全選手の一斉生成が禁止され、ListView.builder が使用されていること',
      () {
        final file = File('lib/shared/widgets/smart_player_input.dart');
        expect(file.existsSync(), isTrue);
        final content = file.readAsStringSync();

        expect(
          content.contains('ListView.builder('),
          isTrue,
          reason: 'smart_player_input.dart では ListView.builder による仮想化が必須',
        );

        // children: [...] に一斉 map するパターンの残存がないこと
        final hasUnvirtualizedList = RegExp(
          r'child:\s*ListView\(\s*children:\s*\[',
        ).hasMatch(content);
        expect(
          hasUnvirtualizedList,
          isFalse,
          reason:
              'smart_player_input.dart 内で非仮想化 ListView(children: [...]) が使われていないこと',
        );
      },
    );

    test(
      '3. [UI層・チーム選手選択仮想化] team_registration_player_select_bottom_sheet.dart で CustomScrollView + SliverList.builder が使用されていること',
      () {
        final file = File(
          'lib/features/tournament/presentation/operate/components/team_registration/team_registration_player_select_bottom_sheet.dart',
        );
        expect(file.existsSync(), isTrue);
        final content = file.readAsStringSync();

        expect(
          content.contains('CustomScrollView('),
          isTrue,
          reason: 'CustomScrollView が使用されていること',
        );
        expect(
          content.contains('SliverList.builder('),
          isTrue,
          reason: 'SliverList.builder による仮想スクロールが使用されていること',
        );

        final hasUnvirtualizedList = RegExp(
          r'child:\s*ListView\(\s*children:\s*\[',
        ).hasMatch(content);
        expect(
          hasUnvirtualizedList,
          isFalse,
          reason: '非仮想化 ListView(children: [...]) が使われていないこと',
        );
      },
    );

    test(
      '4. [UI層・オーダー選手選択仮想化] order_setup_player_select_bottom_sheet.dart で ListView.builder が使用されていること',
      () {
        final file = File(
          'lib/features/tournament/presentation/operate/components/order_setup/order_setup_player_select_bottom_sheet.dart',
        );
        expect(file.existsSync(), isTrue);
        final content = file.readAsStringSync();

        expect(
          content.contains('ListView.builder('),
          isTrue,
          reason:
              'order_setup_player_select_bottom_sheet.dart では ListView.builder が必須',
        );

        final hasUnvirtualizedList = RegExp(
          r'child:\s*ListView\(\s*children:\s*\[',
        ).hasMatch(content);
        expect(
          hasUnvirtualizedList,
          isFalse,
          reason: '非仮想化 ListView(children: [...]) が使われていないこと',
        );
      },
    );

    test(
      '5. [フォントオフライン耐性] app_startup.dart に enforceOfflineFontFallback が配備されていること',
      () {
        final file = File('lib/bootstrap/app_startup.dart');
        expect(file.existsSync(), isTrue);
        final content = file.readAsStringSync();

        expect(
          content.contains('enforceOfflineFontFallback()'),
          isTrue,
          reason: 'app_startup.dart に enforceOfflineFontFallback() が定義されていること',
        );
        expect(
          content.contains('GoogleFonts.config.allowRuntimeFetching = false'),
          isTrue,
          reason: 'オフライン時にランタイムフォント取得を安全に無効化する仕組みがあること',
        );
      },
    );

    test(
      '6. [スコアボード局所購読規約] スコアボード画面で matchListProvider の無差別 ref.watch が禁止され、select シグネチャ購読されていること',
      () {
        final teamScoreboard = File(
          'lib/features/tournament/presentation/operate/team_scoreboard_screen.dart',
        );
        final viewerScoreboard = File(
          'lib/features/viewer/screens/viewer_team_scoreboard_screen.dart',
        );
        final kachinukiScoreboard = File(
          'lib/features/tournament/presentation/screens/kachinuki_scoreboard_screen.dart',
        );

        expect(teamScoreboard.existsSync(), isTrue);
        expect(viewerScoreboard.existsSync(), isTrue);
        expect(kachinukiScoreboard.existsSync(), isTrue);

        for (final file in [
          teamScoreboard,
          viewerScoreboard,
          kachinukiScoreboard,
        ]) {
          final content = file.readAsStringSync();

          // 無差別 watch: ref.watch(matchListProvider) は禁止
          final hasUnscopedWatch = RegExp(
            r'ref\.watch\(\s*matchListProvider\s*\)',
          ).hasMatch(content);
          expect(
            hasUnscopedWatch,
            isFalse,
            reason:
                '${file.path} で無差別な ref.watch(matchListProvider) を行ってはならない。他コートのタイマー更新による全画面リビルドを防ぐため select シグネチャを使用すること。',
          );

          // select による購読が行われていること
          expect(
            content.contains('matchListProvider.select('),
            isTrue,
            reason:
                '${file.path} で matchListProvider.select によるシグネチャ監視が行われていること',
          );
        }
      },
    );
  });
}
