import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../helpers/safe_pump_helper.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_view_state_provider.dart';
import 'package:kendo_os/shared/domain/entities/settings_model.dart';
import 'package:kendo_os/shared/errors/safety_net_error_view.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/scoreboard.dart';

class _MockSettingsNotifier extends SettingsNotifier {
  @override
  SettingsModel build() =>
      const SettingsModel(securityLevel: 1, enableLiquidGlass: false);
}

void main() {
  group('[Widget] セーフティネット画面 ＆ 小型画面オーバーフロー保護 統合テスト', () {
    testWidgets('例外発生時においてセーフティネットUIと復旧ボタン群が正常に描画されること', (tester) async {
      final details = FlutterErrorDetails(
        exception: Exception('テスト用エラーメッセージ'),
        stack: StackTrace.current,
      );

      await tester.pumpWidget(
        MaterialApp(home: SafetyNetErrorView(details: details)),
      );

      expect(find.text('🛡️ KendoOS 不壊セーフティネット作動'), findsOneWidget);
      expect(find.text('再読み込み'), findsOneWidget);
      expect(find.text('リセット復旧'), findsOneWidget);
      expect(find.byIcon(Icons.shield), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.byIcon(Icons.restart_alt), findsOneWidget);
    });

    testWidgets('再読み込みおよびリセット復旧ボタン押下時において例外をスローせず安全に処理されること', (tester) async {
      final details = FlutterErrorDetails(exception: Exception('テスト用エラー'));

      await tester.pumpWidget(
        MaterialApp(home: SafetyNetErrorView(details: details)),
      );

      await tester.tap(find.text('再読み込み'));
      await tester.pump();
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('リセット復旧'));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('320x568 極小画面でもスコアボードがオーバーフロー例外ゼロで完全描画されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final match = const MatchModel(
        id: 'compact_match_1',
        tournamentId: 't1',
        category: '一般の部',
        matchType: '個人戦',
        status: 'inProgress',
        redName: '神武館:佐藤 剣士',
        whiteName: '修道館:田中 武士',
        redScore: 1,
        whiteScore: 1,
      );

      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsProvider.overrideWith(() => _MockSettingsNotifier()),
            matchViewStateUserIdProvider.overrideWith((ref) => 'user_1'),
            matchListProvider.overrideWithValue([match]),
            scoreboardMatchIdProvider.overrideWithValue('compact_match_1'),
            scoreboardMatchProvider.overrideWithValue(match),
            scoreboardNameTapProvider.overrideWithValue((side) {}),
          ],
          child: MaterialApp(
            theme: ThemeData.light().copyWith(extensions: [themeColors]),
            home: const Scaffold(
              body: Center(
                child: SingleChildScrollView(
                  child: SizedBox(
                    width: 310,
                    height: 280,
                    child: MatchScoreboard(),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.safePumpAndSettle();

      expect(find.byType(MatchScoreboard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
