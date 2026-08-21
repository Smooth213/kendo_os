import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_unified_announce_dialog.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('TimelineUnifiedAnnounceDialog renders properly', (tester) async {
    final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');
    final prefs = await SharedPreferences.getInstance();

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
                    TimelineUnifiedAnnounceDialog.show(
                      context,
                      ref,
                      'tourney_1',
                      '一般の部',
                      'Aリーグ',
                      1.0,
                    );
                  },
                  child: const Text('アナウンスダイアログを開く'),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('アナウンスダイアログを開く'));
    await tester.pumpAndSettle();

    expect(find.text('公式アナウンス・コメントの一斉発信'), findsOneWidget);
    expect(find.text('📢 全員に通知'), findsOneWidget);
    expect(find.text('🔒 スタッフ限定'), findsOneWidget);
    expect(find.text('一斉発信して保存'), findsOneWidget);
  });
}
