import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/viewer/services/viewer_bunaiksen_export_service.dart';

void main() {
  group('[Unit] ViewerBunaiksenExportService テスト', () {
    const service = ViewerBunaiksenExportService();

    test('サービスのインスタンスが正常に生成できること', () {
      expect(service, isNotNull);
    });
  });
}
