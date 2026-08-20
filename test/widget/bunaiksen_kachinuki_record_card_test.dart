import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen_official_record/bunaiksen_kachinuki_record_card.dart';

void main() {
  group('🛡️ BunaiksenKachinukiRecordCard Widget Tests', () {
    testWidgets('Renders kachinuki card with title and canvas', (tester) async {
      final match = MatchModel(
        id: 'match1',
        redName: '赤チーム: 先鋒',
        whiteName: '白チーム: 先鋒',
        matchType: '勝ち抜き戦',
        isKachinuki: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  return BunaiksenKachinukiRecordCard(
                    matches: [match],
                    isDark: false,
                    ref: ref,
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('勝ち抜き戦：赤チーム vs 白チーム'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('Renders empty widget when matches is empty', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  return BunaiksenKachinukiRecordCard(
                    matches: const [],
                    isDark: false,
                    ref: ref,
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('勝ち抜き戦：赤チーム vs 白チーム'), findsNothing);
    });
  });
}
