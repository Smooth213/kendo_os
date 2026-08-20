import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/services/new_match_submission_service.dart';

void main() {
  group('🛡️ NewMatchSubmissionService Tests', () {
    const service = NewMatchSubmissionService();

    test('Service can be instantiated', () {
      expect(service, isNotNull);
    });
  });
}
