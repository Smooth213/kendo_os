import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/auth/presentation/widgets/dojo_pin_recovery_sheet.dart';
import 'package:kendo_os/security/dojo_owner_recovery_repository.dart';
import 'package:kendo_os/security/dojo_security_repository.dart';
import 'package:kendo_os/security/viewer_share_models.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import '../../helpers/safe_pump_helper.dart';

void main() {
  group('[Widget] DojoPinRecoverySheet Google本人確認・PIN初期化シートテスト', () {
    testWidgets('未登録Googleは拒否され、登録済み代表者Googleで入室PIN・ロールPINを初期化できること', (
      tester,
    ) async {
      final fakeFirestore = FakeFirebaseFirestore();
      final securityRepo = DojoSecurityRepository(fakeFirestore);
      final recoveryRepo = DojoOwnerRecoveryRepository(fakeFirestore);
      await securityRepo.createDojoWithPin(
        dojoId: 'recovery_dojo',
        joinPin: 'oldpass99',
        uid: 'u1',
      );
      await recoveryRepo.updateDojoOwners(
        dojoId: 'recovery_dojo',
        owners: const [DojoOwnerAccount(email: 'captain@example.com')],
        currentAdminPin: '9999',
        uid: 'u1',
      );

      String mockSignedInEmail = 'stranger@example.com';
      DojoPinRecoveryResult? result;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dojoSecurityFirestoreProvider.overrideWithValue(fakeFirestore),
          ],
          child: MaterialApp(
            theme: ThemeData.light().copyWith(
              extensions: [
                AppThemeColors.ofMode(isDark: false, mode: 'normal'),
              ],
            ),
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    result = await DojoPinRecoverySheet.show(
                      context: context,
                      dojoId: 'recovery_dojo',
                      mode: DojoRecoveryMode.joinPin,
                      signInWithGoogleOverride: () async => mockSignedInEmail,
                    );
                  },
                  child: const Text('Recover'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Recover'));
      await tester.safePumpAndSettle();

      // 未登録アカウントは拒否
      await tester.tap(find.text('Googleアカウントで本人確認する'));
      await tester.safePumpAndSettle();
      expect(find.textContaining('代表者として登録されていません'), findsOneWidget);

      // 登録済みアカウントに切替えると成功して再設定フォームが開く
      mockSignedInEmail = 'captain@example.com';
      await tester.tap(find.text('Googleアカウントで本人確認する'));
      await tester.safePumpAndSettle();
      expect(
        find.textContaining('代表者確認済み（captain@example.com）'),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextField), 'newdojo2027');
      await tester.tap(find.text('PINを初期化・再設定する'));
      await tester.safePumpAndSettle();

      expect(result?.recovered, isTrue);
      expect(result?.newJoinPinHash, isNotNull);
    });

    testWidgets('rolePinモードで初期化スイッチ制御とカスタムAdmin PIN指定による初期化が機能すること', (
      tester,
    ) async {
      final fakeFirestore = FakeFirebaseFirestore();
      final securityRepo = DojoSecurityRepository(fakeFirestore);
      final recoveryRepo = DojoOwnerRecoveryRepository(fakeFirestore);
      final joinHash = await securityRepo.createDojoWithPin(
        dojoId: 'role_recover_dojo',
        joinPin: 'kendo2026',
        uid: 'u1',
      );
      await recoveryRepo.updateDojoOwners(
        dojoId: 'role_recover_dojo',
        owners: const [DojoOwnerAccount(email: 'coach@example.com')],
        currentAdminPin: '9999',
        uid: 'u1',
      );

      DojoPinRecoveryResult? result;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dojoSecurityFirestoreProvider.overrideWithValue(fakeFirestore),
          ],
          child: MaterialApp(
            theme: ThemeData.light().copyWith(
              extensions: [
                AppThemeColors.ofMode(isDark: false, mode: 'normal'),
              ],
            ),
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    result = await DojoPinRecoverySheet.show(
                      context: context,
                      dojoId: 'role_recover_dojo',
                      mode: DojoRecoveryMode.rolePin,
                      elevateToAdmin: true,
                      signInWithGoogleOverride: () async => 'coach@example.com',
                    );
                  },
                  child: const Text('RecoverRole'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('RecoverRole'));
      await tester.safePumpAndSettle();

      await tester.tap(find.text('Googleアカウントで本人確認する'));
      await tester.safePumpAndSettle();
      expect(find.textContaining('代表者確認済み（coach@example.com）'), findsOneWidget);

      // スイッチOFFかつAdmin PIN空欄ではエラーになること
      await tester.tap(find.byType(Switch));
      await tester.safePumpAndSettle();
      await tester.tap(find.text('PINを初期化・再設定する'));
      await tester.safePumpAndSettle();
      expect(
        find.textContaining('初期値に戻すか、新しい4桁Admin PINを入力してください'),
        findsOneWidget,
      );

      // スイッチON＋カスタムAdmin PIN「5678」で再設定できること
      await tester.tap(find.byType(Switch));
      await tester.safePumpAndSettle();
      await tester.enterText(find.byType(TextField), '5678');
      await tester.tap(find.text('PINを初期化・再設定する'));
      await tester.safePumpAndSettle();

      expect(result?.recovered, isTrue);
      expect(result?.effectiveAdminPin, '5678');

      final unlockRes = await securityRepo.verifyAdminAndUnlockVault(
        dojoId: 'role_recover_dojo',
        currentAdminPin: '5678',
        joinPinHash: joinHash,
        uid: 'u2',
      );
      expect(unlockRes.status, AdminVaultUnlockStatus.unlocked);
      expect(unlockRes.payload?.adminPin, '5678');
      expect(unlockRes.payload?.operatorPin, '2468');
    });
  });
}
