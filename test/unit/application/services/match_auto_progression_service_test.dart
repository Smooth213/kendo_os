import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/application/services/match_auto_progression_service.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/services/match_domain_service.dart';

void main() {
  group('🛡️ MatchAutoProgressionService Unit Tests', () {
    test(
      'autoProcessFusenIfNeeded triggers finish when both players are 欠員',
      () async {
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
      },
    );
  });
}
