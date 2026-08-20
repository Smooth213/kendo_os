import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/viewer/services/viewer_bunaiksen_export_service.dart';

void main() {
  group('🛡️ ViewerBunaiksenExportService Tests', () {
    const service = ViewerBunaiksenExportService();

    test('Service can be instantiated', () {
      expect(service, isNotNull);
    });
  });
}
