import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_summary_input_dialog.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('TimelineSummaryInputDialog renders properly', (tester) async {
    final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');
    final prefs = await SharedPreferences.getInstance();

    final matches = [
      MatchModel(
        id: 'm1',
        tournamentId: 't1',
        matchType: '先鋒戦',
        order: 1,
        redName: '赤心館 : 選手1',
        whiteName: '白龍会 : 選手2',
        status: 'pending',
        note: '',
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: ThemeData.light().copyWith(extensions: [themeColors]),
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, child) {
                return ElevatedButton(
                  onPressed: () {
                    TimelineSummaryInputDialog.show(context, ref, matches);
                  },
                  child: const Text('簡易入力ダイアログを開く'),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('簡易入力ダイアログを開く'));
    await tester.pumpAndSettle();

    expect(find.text('他コートの簡易入力'), findsOneWidget);
    expect(find.text('赤心館'), findsOneWidget);
    expect(find.text('白龍会'), findsOneWidget);
    expect(find.text('記録を確定する'), findsOneWidget);
  });
}
