import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/admin/presentation/components/master_player_gender_selector.dart';
import 'package:kendo_os/admin/presentation/helpers/auto_kana_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🛡️ MasterPlayer Components & Helpers Tests', () {
    testWidgets('1. MasterPlayerGenderSelector taps correctly', (tester) async {
      String selectedGender = '男子';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MasterPlayerGenderSelector(
              selectedGender: selectedGender,
              onGenderChanged: (val) => selectedGender = val,
            ),
          ),
        ),
      );

      expect(find.text('男子'), findsOneWidget);
      expect(find.text('女子'), findsOneWidget);

      await tester.tap(find.text('女子'));
      await tester.pump();

      expect(selectedGender, '女子');
    });

    testWidgets('2. AutoKanaHelper updates kana on name change', (
      tester,
    ) async {
      final nameCtrl = TextEditingController();
      final kanaCtrl = TextEditingController();

      AutoKanaHelper.setupAutoKana(nameCtrl, kanaCtrl);

      nameCtrl.text = 'さとう';
      await tester.pump();

      expect(kanaCtrl.text, 'さとう');

      nameCtrl.dispose();
      kanaCtrl.dispose();
    });
  });
}
