import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/settings/dojo_security_pin_form_card.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import '../../helpers/safe_pump_helper.dart';

void main() {
  group('[Widget] DojoSecurityPinFormCard ＆ DojoAdminUnlockCard テスト', () {
    testWidgets('Admin本人確認カードとPIN編集カードがボタン操作を受け付けること', (tester) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');
      final adminAuthCtrl = TextEditingController(text: '9999');
      final joinCtrl = TextEditingController(text: 'dojo2026');
      final adminCtrl = TextEditingController(text: '9999');
      final opCtrl = TextEditingController(text: '2468');
      final recCtrl = TextEditingController(text: '1357');
      addTearDown(() {
        adminAuthCtrl.dispose();
        joinCtrl.dispose();
        adminCtrl.dispose();
        opCtrl.dispose();
        recCtrl.dispose();
      });

      bool unlockedTapped = false;
      bool recoveryTapped = false;
      bool saveTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(extensions: [themeColors]),
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  DojoAdminUnlockCard(
                    themeColors: themeColors,
                    controller: adminAuthCtrl,
                    obscurePin: true,
                    isBusy: false,
                    onToggleObscure: () {},
                    onUnlock: () => unlockedTapped = true,
                    onOpenRecovery: () => recoveryTapped = true,
                  ),
                  DojoSecurityPinFormCard(
                    themeColors: themeColors,
                    joinPinController: joinCtrl,
                    adminPinController: adminCtrl,
                    operatorPinController: opCtrl,
                    recorderPinController: recCtrl,
                    hidePins: false,
                    isBusy: false,
                    onToggleHidePins: () {},
                    onSave: () => saveTapped = true,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.safePumpAndSettle();

      await tester.tap(find.text('本人確認して現在のPINを表示'));
      await tester.tap(find.text('PINを忘れた場合（代表者Googleで初期化）'));
      await tester.ensureVisible(find.text('PIN変更を保存する'));
      await tester.tap(find.text('PIN変更を保存する'));
      await tester.safePumpAndSettle();

      expect(unlockedTapped, isTrue);
      expect(recoveryTapped, isTrue);
      expect(saveTapped, isTrue);
      expect(find.text('dojo2026'), findsOneWidget);
      expect(find.text('2468'), findsOneWidget);
    });
  });
}
