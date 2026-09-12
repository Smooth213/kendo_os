import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/band/presentation/components/band_share_button.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_status_badge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🛡️ 【カプセルUIガバナンス】ステータスバッジ＆BAND共有ボタン 統一高さ検証テスト', () {
    testWidgets('BandShareButton と MatchStatusBadge の高さが完全に一致（22px）すること', (
      tester,
    ) async {
      const dummyMatch = MatchModel(
        id: 'm1',
        tournamentId: 't1',
        status: 'pending',
        matchType: '団体戦',
        redName: '自道場',
        whiteName: '相手道場',
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  MatchStatusBadge(
                    isPlaying: true,
                    isFinished: false,
                    isDark: false,
                  ),
                  BandShareButton(matches: [dummyMatch]),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final badgeSize = tester.getSize(find.byType(MatchStatusBadge));
      final bandButtonSize = tester.getSize(find.byType(BandShareButton));

      // ステータスバッジ（22px）とBAND共有ボタン（22px）の高さが美しく揃っていること
      expect(badgeSize.height, equals(22.0));
      expect(bandButtonSize.height, equals(22.0));
    });
  });
}
