import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_daihyo_overlay.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_view_only_notice_banner.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('[Widget] MatchScreen Sub Components テスト', () {
    testWidgets('MatchViewOnlyNoticeBannerにおいて 警告バナーおよび切替ボタンが描画されること', (
      tester,
    ) async {
      bool claimed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchViewOnlyNoticeBanner(
              isSomeoneElseOperating: true,
              isApproved: false,
              isReadOnly: false,
              onClaimScorer: () {
                claimed = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('他の記録員が入力中です'), findsOneWidget);
      expect(find.text('自分に切り替える'), findsOneWidget);

      await tester.tap(find.text('自分に切り替える'));
      expect(claimed, isTrue);
    });

    testWidgets('MatchDaihyoOverlayにおいて ボタンが描画されコールバックが呼び出されること', (
      tester,
    ) async {
      final prefs = await SharedPreferences.getInstance();
      bool selected = false;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: MatchDaihyoOverlay(
                  match: const MatchModel(
                    id: 'representative-match',
                    matchType: '代表戦',
                    redName: '赤チーム : 代表選手',
                    whiteName: '白チーム : 代表選手',
                    status: 'waiting',
                  ),
                  onSelectDaihyo: () {
                    selected = true;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('代表戦の選手が未設定です'), findsOneWidget);
      expect(find.text('代表者を選択する'), findsOneWidget);

      await tester.tap(find.text('代表者を選択する'));
      expect(selected, isTrue);
    });
  });
}
