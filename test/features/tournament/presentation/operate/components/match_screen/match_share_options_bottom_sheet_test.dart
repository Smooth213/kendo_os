import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_share_options_bottom_sheet.dart';

void main() {
  testWidgets('MatchShareOptionsBottomSheet renders cloud and P2P options', (
    tester,
  ) async {
    const match = MatchModel(
      id: 'test-match-1',
      matchType: '先鋒',
      redName: '誠道館 : 山田',
      whiteName: 'ライバル : 田中',
    );

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: MatchShareOptionsBottomSheet(match: match)),
        ),
      ),
    );

    expect(find.text('観戦の共有方法を選択'), findsOneWidget);
    expect(find.textContaining('LINE / クラウドで共有'), findsOneWidget);
    expect(find.textContaining('体育館ローカルP2P配信'), findsOneWidget);
    expect(find.text('圏外OK'), findsOneWidget);
  });
}
