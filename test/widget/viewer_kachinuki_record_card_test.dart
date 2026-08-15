import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/viewer/components/viewer_kachinuki_record_card.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('🛡️ ViewerKachinukiRecordCard Widget Tests', () {
    testWidgets('Renders team title and CustomPaint canvas', (
      WidgetTester tester,
    ) async {
      final match = MatchModel(
        id: 'k1',
        redName: '赤チーム: 山田',
        whiteName: '白チーム: 佐藤',
        redScore: 1,
        whiteScore: 0,
        status: 'finished',
        matchType: '勝ち抜き戦',
        isKachinuki: true,
      );

      final themeColors = AppThemeColors.ofMode(
        isDark: false,
        mode: 'bunaiksen_viewer',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData(extensions: [themeColors]),
            home: Scaffold(
              body: ViewerKachinukiRecordCard(matches: [match], isDark: false),
            ),
          ),
        ),
      );

      expect(find.text('勝ち抜き戦：赤チーム vs 白チーム'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}
