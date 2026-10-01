import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/errors/emergency_crash_preserver.dart';
import 'package:kendo_os/shared/errors/global_error_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('crash_e2e_test_');
    EmergencyCrashPreserver.customDirectory = tempDir;
    EmergencyCrashPreserver.isWebOverride = false;
  });

  tearDown(() async {
    EmergencyCrashPreserver.unregisterActiveMatch('match_crash_e2e_1');
    await EmergencyCrashPreserver.clearCrashDump();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('[E2E] グローバル例外トラップ＆緊急退避復旧E2Eテスト', () {
    test('Native環境で例外トラップ時にクラッシュダンプが保存され再起動後に完全復元されること', () async {
      const match = MatchModel(
        id: 'match_crash_e2e_1',
        matchType: '個人戦',
        redName: '選手赤',
        whiteName: '選手白',
        redScore: 1,
        whiteScore: 0,
        status: 'in_progress',
      );

      // 試合中の追跡登録
      EmergencyCrashPreserver.registerActiveMatch(
        match,
        extraContext: {'court': '第1コート', 'round': '決勝'},
      );

      // GlobalErrorHandlerのZone内で未捕捉例外を発生させる
      GlobalErrorHandler.runWithZone(() async {
        throw StateError('予期せぬクリティカルクラッシュ発生');
      });

      // 非同期保存の完了を待機
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // クラッシュ復旧の検証（アプリ再起動シミュレーション）
      final dump = await EmergencyCrashPreserver.loadRecoverableCrashDump();
      expect(dump, isNotNull);
      expect(dump!['error'], contains('予期せぬクリティカルクラッシュ発生'));
      expect(dump['context']['court'], '第1コート');

      final recoveredMatch = MatchModel.fromJson(
        dump['match'] as Map<String, dynamic>,
      );
      expect(recoveredMatch.id, 'match_crash_e2e_1');
      expect(recoveredMatch.redScore, 1);
      expect(recoveredMatch.whiteScore, 0);

      // 復旧後のクリア
      await EmergencyCrashPreserver.clearCrashDump();
      final postClear =
          await EmergencyCrashPreserver.loadRecoverableCrashDump();
      expect(postClear, isNull);
    });

    test('Web環境で未捕捉エラー発生時にSharedPreferencesに退避され復旧できること', () async {
      EmergencyCrashPreserver.isWebOverride = true;

      const match = MatchModel(
        id: 'match_crash_web_e2e',
        matchType: '団体戦',
        redName: '赤軍',
        whiteName: '白軍',
        redScore: 2,
        whiteScore: 1,
        status: 'in_progress',
      );

      EmergencyCrashPreserver.registerActiveMatch(
        match,
        extraContext: {'isWebSession': true},
      );

      await EmergencyCrashPreserver.preserveOnCrash(
        error: Exception('Webブラウザ内レンダリング例外'),
        stackTrace: StackTrace.current,
      );

      final dump = await EmergencyCrashPreserver.loadRecoverableCrashDump();
      expect(dump, isNotNull);
      expect(dump!['error'], contains('Webブラウザ内レンダリング例外'));

      final recoveredMatch = MatchModel.fromJson(
        dump['match'] as Map<String, dynamic>,
      );
      expect(recoveredMatch.id, 'match_crash_web_e2e');
      expect(recoveredMatch.redScore, 2);

      await EmergencyCrashPreserver.clearCrashDump();
      final emptyDump =
          await EmergencyCrashPreserver.loadRecoverableCrashDump();
      expect(emptyDump, isNull);
    });
  });
}
