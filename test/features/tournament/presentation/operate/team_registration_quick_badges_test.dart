import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_quick_badges.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/category_format_history_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget buildTestWidget({
    required ValueChanged<CategoryFormatPresetItem> onPresetSelected,
  }) {
    final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');
    return ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        theme: ThemeData.light().copyWith(extensions: [themeColors]),
        home: Scaffold(
          body: TeamRegistrationQuickBadges(
            themeColors: themeColors,
            onPresetSelected: onPresetSelected,
          ),
        ),
      ),
    );
  }

  group('[Widget] チーム登録クイックバッジ アコーディオン表示検証', () {
    testWidgets('初期状態は折りたたまれており、開くが表示されていること', (tester) async {
      await tester.pumpWidget(buildTestWidget(onPresetSelected: (_) {}));
      await tester.pumpAndSettle();

      expect(find.text('よく使う組み合わせ（ワンタップ入力）'), findsOneWidget);
      expect(find.text('開く'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);

      // 初期状態ではプリセットのチップは非表示
      expect(find.text('小学生高学年 / 団体 5人制'), findsNothing);
    });

    testWidgets('タップするとアコーディオンが展開され、閉じる表示とプリセットが表示されること', (tester) async {
      CategoryFormatPresetItem? selectedPreset;
      await tester.pumpWidget(
        buildTestWidget(
          onPresetSelected: (preset) {
            selectedPreset = preset;
          },
        ),
      );
      await tester.pumpAndSettle();

      // 開く
      await tester.tap(find.text('よく使う組み合わせ（ワンタップ入力）'));
      await tester.pumpAndSettle();

      expect(find.text('閉じる'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);
      expect(find.text('小学生高学年 / 団体 5人制'), findsOneWidget);

      // プリセットをタップ
      await tester.tap(find.text('小学生高学年 / 団体 5人制'));
      await tester.pumpAndSettle();

      expect(selectedPreset, isNotNull);
      expect(selectedPreset!.category, equals('小学生高学年の部'));
      expect(selectedPreset!.matchType, equals('団体戦（5人制）'));

      // 再度ヘッダーをタップすると折りたたまれること
      await tester.tap(find.text('よく使う組み合わせ（ワンタップ入力）'));
      await tester.pumpAndSettle();

      expect(find.text('開く'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
      expect(find.text('小学生高学年 / 団体 5人制'), findsNothing);
    });
  });
}
