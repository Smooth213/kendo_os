import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/services/new_match_submission_service.dart';

void main() {
  group('[Unit] NewMatchSubmissionService テスト', () {
    const service = NewMatchSubmissionService();

    test('Service can be instantiatedであること', () {
      expect(service, isNotNull);
    });
  });
}
