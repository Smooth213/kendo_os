import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/program_view_state_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🥋 ProgramViewStateService ユニットテスト', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      ProgramViewStateService.instance.resetForTesting();
    });

    test('初期状態では指定したデフォルトインデックスが返されること', () {
      final service = ProgramViewStateService.instance;
      expect(service.getLastProgramIndex('tournament_1', defaultIndex: 0), 0);
      expect(service.getLastProgramIndex('tournament_1', defaultIndex: 2), 2);
    });

    test('初期状態では指定したデフォルトページが返されること', () {
      final service = ProgramViewStateService.instance;
      expect(service.getLastPageNumber('prog_1', defaultPage: 1), 1);
      expect(service.getLastPageNumber('prog_1', defaultPage: 5), 5);
    });

    test('プログラムインデックスの保存と即時復元（メモリキャッシュ＆SharedPreferences）', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = ProgramViewStateService.instance;
      await service.init(prefs: prefs);

      service.setLastProgramIndex('tournament_1', 3);
      expect(service.getLastProgramIndex('tournament_1'), 3);
      expect(prefs.getInt('kendo_os_prog_last_idx_tournament_1'), 3);

      // 別の大会IDは影響を受けないこと
      expect(service.getLastProgramIndex('tournament_2', defaultIndex: 0), 0);
    });

    test('PDFページ番号の保存と即時復元（メモリキャッシュ＆SharedPreferences）', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = ProgramViewStateService.instance;
      await service.init(prefs: prefs);

      service.setLastPageNumber('prog_pdf_abc', 7);
      expect(service.getLastPageNumber('prog_pdf_abc'), 7);
      expect(prefs.getInt('kendo_os_prog_last_page_prog_pdf_abc'), 7);

      // 別のプログラムキーは影響を受けないこと
      expect(service.getLastPageNumber('prog_pdf_xyz', defaultPage: 1), 1);
    });

    test('SharedPreferences に事前保存されていた値が正しく読み出せること', () async {
      SharedPreferences.setMockInitialValues({
        'kendo_os_prog_last_idx_tournament_pre': 2,
        'kendo_os_prog_last_page_prog_pre': 4,
      });
      final prefs = await SharedPreferences.getInstance();
      final service = ProgramViewStateService.instance;
      await service.init(prefs: prefs);

      expect(service.getLastProgramIndex('tournament_pre'), 2);
      expect(service.getLastPageNumber('prog_pre'), 4);
    });

    test('空文字キーに対する安全なフォールバック', () {
      final service = ProgramViewStateService.instance;
      service.setLastProgramIndex('', 5);
      expect(service.getLastProgramIndex('', defaultIndex: 0), 0);

      service.setLastPageNumber('', 10);
      expect(service.getLastPageNumber('', defaultPage: 1), 1);
    });
  });
}
