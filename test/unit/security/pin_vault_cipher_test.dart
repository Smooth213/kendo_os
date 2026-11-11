import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/security/pin_vault_cipher.dart';

void main() {
  group('[Unit] PinVaultCipher 暗号化・復号・改ざん検証テスト', () {
    test('正しい道場IDとAdmin PINで暗号化・復号が一致すること', () {
      const payload = DojoPinVaultPayload(
        joinPin: 'dojo2026_kendo',
        adminPin: '4321',
        operatorPin: '1122',
        recorderPin: '3344',
      );

      final encrypted = PinVaultCipher.encrypt(
        dojoId: 'Test_Dojo',
        adminPin: '4321',
        payload: payload,
      );

      expect(encrypted.startsWith('v1:'), isTrue);
      expect(encrypted.contains('dojo2026_kendo'), isFalse);

      // 道場IDの大文字小文字・前後空白は正規化されて復号できること
      final decrypted = PinVaultCipher.decrypt(
        dojoId: '  test_dojo ',
        adminPin: '4321',
        encryptedToken: encrypted,
      );

      expect(decrypted, isNotNull);
      expect(decrypted!.joinPin, 'dojo2026_kendo');
      expect(decrypted.adminPin, '4321');
      expect(decrypted.operatorPin, '1122');
      expect(decrypted.recorderPin, '3344');
    });

    test('誤ったAdmin PINや別の道場IDでは復号がnullで拒否されること', () {
      final encrypted = PinVaultCipher.encrypt(
        dojoId: 'dojo_a',
        adminPin: '9999',
        payload: DojoPinVaultPayload.defaults(joinPin: 'pass1234'),
      );

      expect(
        PinVaultCipher.decrypt(
          dojoId: 'dojo_a',
          adminPin: '9998',
          encryptedToken: encrypted,
        ),
        isNull,
      );
      expect(
        PinVaultCipher.decrypt(
          dojoId: 'dojo_b',
          adminPin: '9999',
          encryptedToken: encrypted,
        ),
        isNull,
      );
    });

    test('暗号文やMACが1文字でも改ざんされた場合に復号を拒否すること', () {
      final encrypted = PinVaultCipher.encrypt(
        dojoId: 'dojo_mac',
        adminPin: '9999',
        payload: DojoPinVaultPayload.defaults(joinPin: 'kendo99'),
        random: Random(42),
      );

      final parts = encrypted.split(':');
      final tamperedCipher =
          '${parts[2].substring(0, parts[2].length - 1)}${parts[2].endsWith('A') ? 'B' : 'A'}';
      final tamperedToken = [
        parts[0],
        parts[1],
        tamperedCipher,
        parts[3],
      ].join(':');

      expect(
        PinVaultCipher.decrypt(
          dojoId: 'dojo_mac',
          adminPin: '9999',
          encryptedToken: tamperedToken,
        ),
        isNull,
      );
      expect(
        PinVaultCipher.decrypt(
          dojoId: 'dojo_mac',
          adminPin: '9999',
          encryptedToken: 'invalid_format',
        ),
        isNull,
      );
    });
  });
}
