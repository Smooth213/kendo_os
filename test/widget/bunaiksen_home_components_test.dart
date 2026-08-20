import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bunaiksen/bunaiksen_leaderboard_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bunaiksen/bunaiksen_share_dialog.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bunaiksen/bunaiksen_single_player_select_sheet.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';

void main() {
  group('🛡️ BunaiksenHome Components Widget Tests', () {
    testWidgets('BunaiksenShareDialog renders QR code and share button', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BunaiksenShareDialog(
                tournamentId: 'bunaiksen_20260820',
                dateDisplay: '2026/08/20',
                dojoId: 'test_dojo',
              ),
            ),
          ),
        ),
      );

      expect(find.text('2026/08/20 観戦リンク'), findsOneWidget);
      expect(find.text('リンクをコピー・共有'), findsOneWidget);
    });

    testWidgets(
      'BunaiksenLeaderboardCard renders leaderboard title and structure',
      (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(body: BunaiksenLeaderboardCard()),
            ),
          ),
        );

        expect(find.text('無限勝ち抜き 連勝ランキング'), findsOneWidget);
        expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
      },
    );

    testWidgets(
      'BunaiksenSinglePlayerSelectSheet renders player choices and chips',
      (tester) async {
        final players = [
          PlayerModel(
            id: 'p1',
            lastName: '山田',
            firstName: '太郎',
            lastNameKana: 'ヤマダ',
            firstNameKana: 'タロウ',
            grade: 5,
            isBeginner: false,
          ),
        ];

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: BunaiksenSinglePlayerSelectSheet(
                  sideName: '赤',
                  accentColor: Colors.red,
                  masterPlayers: players,
                ),
              ),
            ),
          ),
        );

        expect(find.text('赤の選手を選択'), findsOneWidget);
        expect(find.text('山田 太郎'), findsOneWidget);
        expect(find.text('小学5年'), findsOneWidget);
      },
    );
  });
}
