import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_status_badge.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import '../helpers/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildBadgeWithTheme({
    required bool isPlaying,
    required bool isFinished,
    required bool isDark,
  }) {
    final themeColors = AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
    return createTestApp(
      Theme(
        data: (isDark ? ThemeData.dark() : ThemeData.light()).copyWith(
          extensions: [themeColors],
        ),
        child: Scaffold(
          body: Center(
            child: MatchStatusBadge(
              isPlaying: isPlaying,
              isFinished: isFinished,
              isDark: isDark,
            ),
          ),
        ),
      ),
    );
  }

  group('🥋 MatchStatusBadge Visual Distinction Tests (試合中/待機中/終了 視認性テスト)', () {
    testWidgets('🔴 試合中(LIVE) 時は赤系ハイライト・試合中テキスト・赤アイコンが表示されること', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildBadgeWithTheme(isPlaying: true, isFinished: false, isDark: false),
      );
      await tester.pumpAndSettle();

      expect(find.text('試合中 (LIVE)'), findsOneWidget);
      expect(find.byIcon(Icons.fiber_manual_record), findsOneWidget);
      expect(find.text('⏳ 待機中'), findsNothing);
      expect(find.text('終了'), findsNothing);
    });

    testWidgets('⏳ 待機中 時は藍色アクセント・待機中テキストが表示されること', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildBadgeWithTheme(isPlaying: false, isFinished: false, isDark: false),
      );
      await tester.pumpAndSettle();

      expect(find.text('⏳ 待機中'), findsOneWidget);
      expect(find.text('試合中 (LIVE)'), findsNothing);
      expect(find.text('終了'), findsNothing);
    });

    testWidgets('🏁 終了 時はグレーアウト調・終了テキストが表示されること', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildBadgeWithTheme(isPlaying: false, isFinished: true, isDark: false),
      );
      await tester.pumpAndSettle();

      expect(find.text('終了'), findsOneWidget);
      expect(find.text('試合中 (LIVE)'), findsNothing);
      expect(find.text('⏳ 待機中'), findsNothing);
    });

    testWidgets('🌙 ダークモード下でも試合中・待機中・終了が正しく描画されること', (
      WidgetTester tester,
    ) async {
      // 試合中
      await tester.pumpWidget(
        buildBadgeWithTheme(isPlaying: true, isFinished: false, isDark: true),
      );
      await tester.pumpAndSettle();
      expect(find.text('試合中 (LIVE)'), findsOneWidget);

      // 待機中
      await tester.pumpWidget(
        buildBadgeWithTheme(isPlaying: false, isFinished: false, isDark: true),
      );
      await tester.pumpAndSettle();
      expect(find.text('⏳ 待機中'), findsOneWidget);

      // 終了
      await tester.pumpWidget(
        buildBadgeWithTheme(isPlaying: false, isFinished: true, isDark: true),
      );
      await tester.pumpAndSettle();
      expect(find.text('終了'), findsOneWidget);
    });
  });
}
