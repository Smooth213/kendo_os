import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/application/services/match_auto_progression_service.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/services/match_domain_service.dart';

void main() {
  group('[Unit] MatchAutoProgressionService 単体テスト', () {
    test('両選手が欠員の場合、autoProcessFusenIfNeededにより試合終了がトリガーされること', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = MatchAutoProgressionService(
        container.read(Provider((ref) => ref)),
        MatchDomainService(),
      );

      final match = MatchModel(
        id: 'm1',
        matchType: '先鋒',
        redName: '欠員',
        whiteName: '欠員',
        status: 'waiting',
      );

      bool finishCalled = false;

      await service.autoProcessFusenIfNeeded(
        match: match,
        onAddIppon: (id, side, type) async {},
        onFinish: (id) async {
          finishCalled = true;
        },
      );

      expect(finishCalled, isTrue);
    });
  });
}
