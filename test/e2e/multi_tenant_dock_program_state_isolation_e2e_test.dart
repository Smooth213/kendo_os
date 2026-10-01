import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/program_view_state_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences mockPrefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockPrefs = await SharedPreferences.getInstance();
    ProgramViewStateService.instance.resetForTesting();
    await ProgramViewStateService.instance.init(prefs: mockPrefs);
  });

  group('[E2E] マルチテナント 道場ルーム切り替えにおけるドック状態完全隔離復元テスト', () {
    test('複数道場ルーム間の切り替えにおいて閲覧プログラムおよびページ位置が完全に隔離されること', () async {
      final service = ProgramViewStateService.instance;

      const dojoAlphaTourId = 'tour_dojo_alpha_2026';
      const dojoBetaTourId = 'tour_dojo_beta_2026';

      const dojoAlphaProgramKey = 'prog_alpha_handbook';
      const dojoBetaProgramKey = 'prog_beta_guideline';

      // 1. 道場Alphaでの操作
      service.setLastProgramIndex(dojoAlphaTourId, 1);
      service.setLastPageNumber(dojoAlphaProgramKey, 7);

      expect(service.getLastProgramIndex(dojoAlphaTourId), 1);
      expect(service.getLastPageNumber(dojoAlphaProgramKey), 7);

      // 2. 道場Betaへのルーム切り替え（初期状態）
      expect(service.getLastProgramIndex(dojoBetaTourId), 0);
      expect(service.getLastPageNumber(dojoBetaProgramKey), 1);

      // 3. 道場Betaでの操作
      service.setLastProgramIndex(dojoBetaTourId, 3);
      service.setLastPageNumber(dojoBetaProgramKey, 15);

      expect(service.getLastProgramIndex(dojoBetaTourId), 3);
      expect(service.getLastPageNumber(dojoBetaProgramKey), 15);

      // 4. 再び道場Alphaへ切り替えた際、Alphaの状態が全く汚染されずに復元されること
      expect(service.getLastProgramIndex(dojoAlphaTourId), 1);
      expect(service.getLastPageNumber(dojoAlphaProgramKey), 7);

      // 5. 端末再起動・メモリクリア後の永続化データの完全復元検証
      ProgramViewStateService.instance.resetForTesting();
      await ProgramViewStateService.instance.init(prefs: mockPrefs);

      expect(
        ProgramViewStateService.instance.getLastProgramIndex(dojoAlphaTourId),
        1,
      );
      expect(
        ProgramViewStateService.instance.getLastPageNumber(dojoAlphaProgramKey),
        7,
      );
      expect(
        ProgramViewStateService.instance.getLastProgramIndex(dojoBetaTourId),
        3,
      );
      expect(
        ProgramViewStateService.instance.getLastPageNumber(dojoBetaProgramKey),
        15,
      );
    });

    test('道場IDやプログラムキーが同一のプレフィックスを持つ場合にも部分一致で混信しないこと', () async {
      final service = ProgramViewStateService.instance;

      service.setLastProgramIndex('dojo_kendo', 2);
      service.setLastProgramIndex('dojo_kendo_os', 4);

      service.setLastPageNumber('pdf_item_1', 3);
      service.setLastPageNumber('pdf_item_10', 8);

      expect(service.getLastProgramIndex('dojo_kendo'), 2);
      expect(service.getLastProgramIndex('dojo_kendo_os'), 4);

      expect(service.getLastPageNumber('pdf_item_1'), 3);
      expect(service.getLastPageNumber('pdf_item_10'), 8);
    });
  });
}
