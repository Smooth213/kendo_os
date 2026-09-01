import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_status_badge.dart';
import 'package:kendo_os/features/viewer/components/viewer_bunaiksen_match_card.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import '../helpers/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testBunaiksenMatch = MatchModel(
    id: 'bunaiksen_1',
    tournamentId: 'tourney_1',
    matchType: '部内戦',
    status: 'in_progress',
    redName: '皿田 脩人',
    whiteName: '相手 太郎',
    redScore: 1,
    whiteScore: 0,
    note: '部内リーグ',
    order: 1.0,
  );

  group('🥋 部内戦試合カード MatchStatusBadge 統合テスト', () {
    testWidgets('観客席部内戦カードでMatchStatusBadge（LIVE）が描画されること', (tester) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        ProviderScope(
          child: createTestApp(
            Theme(
              data: ThemeData.light().copyWith(extensions: [themeColors]),
              child: const Scaffold(
                body: ViewerBunaiksenMatchCard(
                  match: testBunaiksenMatch,
                  index: 0,
                  tournamentId: 'tourney_1',
                  dojoId: 'dojo_1',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MatchStatusBadge), findsOneWidget);
      expect(find.text('試合中 (LIVE)'), findsOneWidget);
    });
  });
}
