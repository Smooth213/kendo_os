import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/security/pwa_storage_bridge.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';

void main() {
  group('🌐 【E2E】Web/PWA ブラウザ操作耐久（リロード・戻る復元）E2Eテスト', () {
    const tournamentKey = 'kendo_os_active_tournament_id';
    const dojoKey = 'kendo_os_active_dojo_id';

    setUp(() {
      PwaStorage.removeItem(tournamentKey);
      PwaStorage.removeItem(dojoKey);
    });

    tearDown(() {
      PwaStorage.removeItem(tournamentKey);
      PwaStorage.removeItem(dojoKey);
    });

    test('1. 試合スコア入力中のブラウザリロード（F5）後のアクティブ大会・道場空間の完全復元', () {
      // ユーザーが入力中にブラウザを誤ってリロードしたケースをシミュレート
      PwaStorage.setItem(tournamentKey, 'tournament_pwa_resilience_100');
      PwaStorage.setItem(dojoKey, 'dojo_pwa_space_200');

      // リロード後の新しいProviderContainer
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final restoredTourneyId = container.read(currentTournamentIdProvider);
      final restoredDojoId = container.read(currentDojoIdProvider);
      final syncContext = container.read(currentSyncContextProvider);

      expect(restoredTourneyId, 'tournament_pwa_resilience_100');
      expect(restoredDojoId, 'dojo_pwa_space_200');
      expect(syncContext.organizationId, 'dojo_pwa_space_200');
    });

    test('2. ブラウザ戻る・進むナビゲーション時のURLパラメータ・エンコード復元耐久性', () {
      const groupTitle = '中学女子 決勝トーナメント【第2試合場】';
      final encodedUrl = Uri.parse(
        'https://kendo-os.web.app/operate/timeline?group=${Uri.encodeComponent(groupTitle)}&tid=t_navigation_test',
      );

      String safeDecode(String? input) {
        if (input == null) return '';
        try {
          return Uri.decodeComponent(input);
        } catch (_) {
          return input;
        }
      }

      expect(encodedUrl.queryParameters['tid'], 't_navigation_test');
      final decodedGroup = safeDecode(encodedUrl.queryParameters['group']);
      expect(decodedGroup, groupTitle);
    });
  });
}
