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

  group('[Unit] ProgramViewStateService 破損データ自己修復と境界値クランプテスト', () {
    test('負のページ番号やゼロが保存されている場合に1ページ目へ自己修復すること', () async {
      await mockPrefs.setInt('kendo_os_prog_last_page_prog_corrupt_zero', 0);
      await mockPrefs.setInt(
        'kendo_os_prog_last_page_prog_corrupt_negative',
        -5,
      );

      ProgramViewStateService.instance.resetForTesting();
      await ProgramViewStateService.instance.init(prefs: mockPrefs);

      final zeroPage = ProgramViewStateService.instance.getLastPageNumber(
        'prog_corrupt_zero',
      );
      final negativePage = ProgramViewStateService.instance.getLastPageNumber(
        'prog_corrupt_negative',
      );

      expect(zeroPage, 1);
      expect(negativePage, 1);
    });

    test('負のプログラムインデックスが保存されている場合にデフォルト値へ自己修復すること', () async {
      await mockPrefs.setInt('kendo_os_prog_last_idx_tour_corrupt', -3);

      ProgramViewStateService.instance.resetForTesting();
      await ProgramViewStateService.instance.init(prefs: mockPrefs);

      final idx = ProgramViewStateService.instance.getLastProgramIndex(
        'tour_corrupt',
      );

      expect(idx, 0);
    });

    test('保存時に不正な値が指定された場合に正常範囲へクランプして永続化すること', () async {
      final service = ProgramViewStateService.instance;

      service.setLastPageNumber('prog_invalid_set', -10);
      service.setLastProgramIndex('tour_invalid_set', -2);

      expect(service.getLastPageNumber('prog_invalid_set'), 1);
      expect(service.getLastProgramIndex('tour_invalid_set'), 0);

      expect(mockPrefs.getInt('kendo_os_prog_last_page_prog_invalid_set'), 1);
      expect(mockPrefs.getInt('kendo_os_prog_last_idx_tour_invalid_set'), 0);
    });

    test('型不一致やストレージ例外が発生した場合にもクラッシュせずデフォルト値を返却すること', () async {
      // SharedPreferences に String型で不正に書き込まれた状態をシミュレート
      await mockPrefs.setString(
        'kendo_os_prog_last_page_prog_string',
        'invalid_string',
      );
      await mockPrefs.setString(
        'kendo_os_prog_last_idx_tour_string',
        'invalid_string',
      );

      ProgramViewStateService.instance.resetForTesting();
      await ProgramViewStateService.instance.init(prefs: mockPrefs);

      final page = ProgramViewStateService.instance.getLastPageNumber(
        'prog_string',
        defaultPage: 1,
      );
      final idx = ProgramViewStateService.instance.getLastProgramIndex(
        'tour_string',
        defaultIndex: 0,
      );

      expect(page, 1);
      expect(idx, 0);
    });
  });
}
