import 'package:flutter_test/flutter_test.dart';

void main() {
  group('[Widget] WidgetTest 単体検証', () {
    testWidgets('Dummy testこと', (WidgetTester tester) async {
      // UIテストは開発の終盤で行うため、一旦ダミーのテストにしておきます
      expect(true, isTrue);
    });
  });
}
