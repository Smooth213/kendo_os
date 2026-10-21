import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_timeline_list.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/sheets/order_reorder_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/sheets/order_reorder_player_tile.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/team_repository.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('[Widget] オーダー並べ替えシート・選手タイル統合テスト', () {
    group('OrderReorderBottomSheet描画テスト', () {
      testWidgets('OrderReorderBottomSheetにおいて 描画され、試合一覧 orderが表示されること', (
        WidgetTester tester,
      ) async {
        final matches = [
          const MatchModel(
            id: 'm1',
            tournamentId: 't1',
            matchType: '先鋒',
            redName: '道上 : 佐藤',
            whiteName: '相手 : 田中',
            status: 'pending',
          ),
          const MatchModel(
            id: 'm2',
            tournamentId: 't1',
            matchType: '次鋒',
            redName: '道上 : 鈴木',
            whiteName: '相手 : 高橋',
            status: 'pending',
          ),
        ];

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              customTeamNamesProvider.overrideWith(
                (ref) => Stream.value(['道上']),
              ),
              timelinePlayerListProvider.overrideWith(
                (ref) => Stream.value(<PlayerModel>[]),
              ),
              registeredTeamsProvider(
                't1',
              ).overrideWith((ref) => Stream.value(<TeamModel>[])),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: OrderReorderBottomSheet(sortedMatches: matches),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('オーダー編集 : 道上'), findsOneWidget);
        expect(find.text('先鋒'), findsOneWidget);
        expect(find.text('佐藤'), findsOneWidget);
        expect(find.text('次鋒'), findsOneWidget);
        expect(find.text('鈴木'), findsOneWidget);
        expect(find.text('オーダーを確定'), findsOneWidget);
      });
    });

    group('OrderReorderPlayerTile描画テスト', () {
      testWidgets('ポジション選手タイルが正しく描画されること', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              extensions: [
                AppThemeColors.ofMode(isDark: false, mode: 'normal'),
              ],
            ),
            home: const Scaffold(
              body: OrderReorderPlayerTile(
                label: '先鋒',
                playerName: '佐藤 健太',
                isPosition: true,
                isDark: false,
              ),
            ),
          ),
        );

        expect(find.text('先鋒'), findsOneWidget);
        expect(find.text('佐藤 健太'), findsOneWidget);
        expect(find.byIcon(Icons.drag_handle), findsOneWidget);
      });

      testWidgets('控え選手タイルがダークモードで正しく描画されること', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              brightness: Brightness.dark,
              extensions: [AppThemeColors.ofMode(isDark: true, mode: 'normal')],
            ),
            home: const Scaffold(
              body: OrderReorderPlayerTile(
                label: '控1',
                playerName: '田中 太郎',
                isPosition: false,
                isDark: true,
              ),
            ),
          ),
        );

        expect(find.text('控1'), findsOneWidget);
        expect(find.text('田中 太郎'), findsOneWidget);
      });
    });
  });
}
