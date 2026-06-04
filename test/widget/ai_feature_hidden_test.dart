import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/config/beta_feature_flags.dart';
import 'package:kendo_os/application/services/ai_help_service.dart';

void main() {
  group('🛡️ [Phase 4] AI Runtime 完全封鎖検証テスト', () {
    test('【ガバナンス監査】BetaFeatureFlags.showAiFeatures が厳格に false に固定されていること', () {
      expect(BetaFeatureFlags.showAiFeatures, false);
    });

    test(
      '【ガバナンス監査】AI機能フラグOFFの際、AiHelpService 内の全処理がパニックを起こさず決定論的に空データまたはアクセス制限文言を返すこと',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final aiService = container.read(aiHelpServiceProvider);

        // 1. 検索処理の呼び出しが空を返すことを担保
        final manuals = await aiService.searchRelevantManuals('延長戦のルール');
        expect(manuals, isEmpty);

        // 2. 回答生成処理が、クラッシュせず安全なアクセス制限文言にフォールバックすることを確認
        final response = await aiService.askAgent('ヘルプエージェント起動');
        expect(response, contains('アクセス制限'));
        expect(response, contains('完全に封鎖されています'));
      },
    );
  });
}
