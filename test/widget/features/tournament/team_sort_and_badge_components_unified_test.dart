import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../helpers/safe_pump_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/court_status/team_match_sort_bar.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_quick_badges.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/category_format_history_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/team_progress_sort_helper.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget createSortBarTestWidget({
    required TeamSortType currentSort,
    required ValueChanged<TeamSortType> onSortChanged,
    bool isDark = false,
  }) {
    return MaterialApp(
      theme: ThemeData(
        extensions: [AppThemeColors.ofMode(isDark: isDark, mode: 'normal')],
      ),
      home: Scaffold(
        body: TeamMatchSortBar(
          currentSort: currentSort,
          onSortChanged: onSortChanged,
          isDark: isDark,
        ),
      ),
    );
  }

  Widget buildQuickBadgesTestWidget({
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

  group('[Widget] TeamSortAndBadgeComponents 統合テスト', () {
    testWidgets('並び替えチップバーが正常に描画され選択変更できること', (tester) async {
      TeamSortType selectedType = TeamSortType.status;

      await tester.pumpWidget(
        createSortBarTestWidget(
          currentSort: selectedType,
          onSortChanged: (type) {
            selectedType = type;
          },
        ),
      );

      expect(find.text('並び替え:'), findsOneWidget);
      expect(find.text('⚡ 進行状況順'), findsOneWidget);
      expect(find.text('🏟️ 試合会場順'), findsOneWidget);
      expect(find.text('🔢 試合順'), findsOneWidget);

      // 会場順を選択
      await tester.tap(find.text('🏟️ 試合会場順'));
      await tester.pump();

      expect(selectedType, TeamSortType.court);

      // 試合順を選択
      await tester.tap(find.text('🔢 試合順'));
      await tester.pump();

      expect(selectedType, TeamSortType.matchOrder);
    });

    testWidgets('ダークモード時も正常に描画されること', (tester) async {
      await tester.pumpWidget(
        createSortBarTestWidget(
          currentSort: TeamSortType.court,
          onSortChanged: (_) {},
          isDark: true,
        ),
      );

      expect(find.text('並び替え:'), findsOneWidget);
      expect(find.byIcon(Icons.swap_vert_rounded), findsOneWidget);
    });

    testWidgets('初期状態は折りたたまれており、開くが表示されていること', (tester) async {
      await tester.pumpWidget(
        buildQuickBadgesTestWidget(onPresetSelected: (_) {}),
      );
      await tester.safePumpAndSettle();

      expect(find.text('よく使う組み合わせ（ワンタップ入力）'), findsOneWidget);
      expect(find.text('開く'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);

      // 初期状態ではプリセットのチップは非表示
      expect(find.text('小学生高学年 / 団体 5人制'), findsNothing);
    });

    testWidgets('タップするとアコーディオンが展開され、閉じる表示とプリセットが表示されること', (tester) async {
      CategoryFormatPresetItem? selectedPreset;
      await tester.pumpWidget(
        buildQuickBadgesTestWidget(
          onPresetSelected: (preset) {
            selectedPreset = preset;
          },
        ),
      );
      await tester.safePumpAndSettle();

      // 開く
      await tester.tap(find.text('よく使う組み合わせ（ワンタップ入力）'));
      await tester.safePumpAndSettle();

      expect(find.text('閉じる'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);
      expect(find.text('小学生高学年 / 団体 5人制'), findsOneWidget);

      // プリセットをタップ
      await tester.tap(find.text('小学生高学年 / 団体 5人制'));
      await tester.safePumpAndSettle();

      expect(selectedPreset, isNotNull);
      expect(selectedPreset!.category, equals('小学生高学年の部'));
      expect(selectedPreset!.matchType, equals('団体戦（5人制）'));

      // 再度ヘッダーをタップすると折りたたまれること
      await tester.tap(find.text('よく使う組み合わせ（ワンタップ入力）'));
      await tester.safePumpAndSettle();

      expect(find.text('開く'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
      expect(find.text('小学生高学年 / 団体 5人制'), findsNothing);
    });
  });
}
