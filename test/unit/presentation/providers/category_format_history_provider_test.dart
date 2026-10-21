import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/category_format_history_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('[Unit] CategoryFormatHistoryNotifier 単体テスト', () {
    test('初期状態ではデフォルトプリセットが優先して返却されること', () {
      final notifier = container.read(categoryFormatHistoryProvider.notifier);
      final topPresets = notifier.getTopPresets(limit: 4);

      expect(topPresets.length, 4);
      expect(topPresets[0].category, '小学生高学年の部');
      expect(topPresets[0].matchType, '団体戦（5人制）');
      expect(topPresets[1].category, '小学生低学年の部');
    });

    test('利用を記録するとカウントアップされ、上位に反映されること', () async {
      final notifier = container.read(categoryFormatHistoryProvider.notifier);

      // 高校生・女子 / 団体戦 を2回記録
      await notifier.recordUsage(
        majorCategory: '高校生',
        minorCategory: '女子',
        category: '高校生女子の部',
        matchType: '団体戦（5人制）',
      );
      await notifier.recordUsage(
        majorCategory: '高校生',
        minorCategory: '女子',
        category: '高校生女子の部',
        matchType: '団体戦（5人制）',
      );

      final topPresets = notifier.getTopPresets(limit: 4);

      expect(topPresets.first.category, '高校生女子の部');
      expect(topPresets.first.count, 2);
      expect(topPresets.first.displayLabel, '高校生女子 / 団体 5人制');
    });

    test('SharedPreferencesから既存データが正常に復元されること', () async {
      final notifier = container.read(categoryFormatHistoryProvider.notifier);
      await notifier.recordUsage(
        majorCategory: '一般',
        minorCategory: '男子',
        category: '一般男子の部',
        matchType: '個人戦',
      );

      // 新しいContainerで再読み込み
      final newContainer = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(newContainer.dispose);

      final restoredNotifier = newContainer.read(
        categoryFormatHistoryProvider.notifier,
      );
      final topPresets = restoredNotifier.getTopPresets(limit: 4);

      expect(topPresets.first.category, '一般男子の部');
      expect(topPresets.first.matchType, '個人戦');
      expect(topPresets.first.displayLabel, '一般男子 / 個人');
    });
  });
}
