import 'package:flutter_test/flutter_test.dart';

/// 🛡️ STEP 1-2 要件：試合残り時間の決定論的進捗（Timer制御）
class FakeTimeMachine {
  void advanceSeconds(WidgetTester tester, int seconds) {
    tester.binding.pump(Duration(seconds: seconds));
  }
}