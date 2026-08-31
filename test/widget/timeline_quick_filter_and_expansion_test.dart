import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/timeline_category_filter_chips_bar.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import '../helpers/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final m1 = MatchModel(
    id: 'm1',
    category: '小学生低学年',
    matchType: '団体戦',
    redName: '道場A',
    whiteName: '道場B',
    groupName: 'group_A',
  );

  final m2 = MatchModel(
    id: 'm2',
    category: '小学生高学年',
    matchType: '団体戦',
    redName: '道場A',
    whiteName: '道場C',
    groupName: 'group_B',
  );

  final entries = [
    MapEntry('小学生低学年', [m1]),
    MapEntry('小学生高学年', [m2]),
  ];

  group('🥋 Timeline Category Filter Chips & Expansion Widget Tests', () {
    testWidgets('TimelineCategoryFilterChipsBar でチップが表示され、タップでフィルターが切り替わること', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          Theme(
            data: ThemeData.light().copyWith(
              extensions: [
                AppThemeColors.ofMode(isDark: false, mode: 'normal'),
              ],
            ),
            child: Scaffold(
              body: TimelineCategoryFilterChipsBar(
                categoryEntries: entries,
                isDark: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 「すべて」「小学生低学年」「小学生高学年」が表示されていること
      expect(find.text('すべて'), findsOneWidget);
      expect(find.text('小学生低学年'), findsOneWidget);
      expect(find.text('小学生高学年'), findsOneWidget);

      // 「小学生低学年」をタップ
      await tester.tap(find.text('小学生低学年'));
      await tester.pumpAndSettle();
    });
  });
}
