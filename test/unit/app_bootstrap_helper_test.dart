import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/bootstrap/app_bootstrap_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Unit] AppBootstrapHelper および KendoOsConfig 単体テスト', () {
    test('KendoOsConfigのデフォルト設定値が正しく初期化されていること', () {
      const config = KendoOsConfig.current;
      expect(config.env, KendoOsEnv.beta);
      expect(config.enableTournamentMode, isTrue);
    });

    test('KendoOsConfigの各環境フラグに応じたインスタンス化が正常に行われること', () {
      const prodConfig = KendoOsConfig(
        env: KendoOsEnv.prod,
        enableTournamentMode: false,
      );
      expect(prodConfig.env, KendoOsEnv.prod);
      expect(prodConfig.enableTournamentMode, isFalse);

      const devConfig = KendoOsConfig(
        env: KendoOsEnv.dev,
        enableTournamentMode: true,
      );
      expect(devConfig.env, KendoOsEnv.dev);
      expect(devConfig.enableTournamentMode, isTrue);
    });

    test('テスト実行環境においてisOnlineStreamProviderが即時trueを配信すること', () async {
      final container = ProviderContainer();
      final sub = container.listen(isOnlineStreamProvider, (previous, next) {});
      addTearDown(() {
        sub.close();
        container.dispose();
      });

      final isOnline = await container.read(isOnlineStreamProvider.future);
      expect(isOnline, isTrue);
    });

    test('isOfflineStreamProviderがオンライン状態に応じてfalseを配信すること', () async {
      final container = ProviderContainer();
      final subOnline = container.listen(
        isOnlineStreamProvider,
        (previous, next) {},
      );
      final subOffline = container.listen(
        isOfflineStreamProvider,
        (previous, next) {},
      );
      addTearDown(() {
        subOnline.close();
        subOffline.close();
        container.dispose();
      });

      // isOnlineStreamProvider が初期化されるのを待機
      await container.read(isOnlineStreamProvider.future);
      final isOffline = await container.read(isOfflineStreamProvider.future);
      expect(isOffline, isFalse);
    });
  });
}
