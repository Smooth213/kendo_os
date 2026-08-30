import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/application/services/kendo_haptics.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('KendoHaptics Unit Tests', () {
    test('全てのハプティクスAPIが例外をスローせず安全に完了すること', () async {
      await expectLater(KendoHaptics.timerToggle(isStarting: true), completes);
      await expectLater(KendoHaptics.timerToggle(isStarting: false), completes);
      await expectLater(KendoHaptics.scorePoint(), completes);
      await expectLater(KendoHaptics.foulHansoku(), completes);
      await expectLater(KendoHaptics.undoEvent(), completes);
      await expectLater(KendoHaptics.viewFlip(), completes);
    });
  });
}
