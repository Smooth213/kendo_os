import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/viewer/components/viewer_bunaiksen_header_actions.dart';
import 'package:kendo_os/features/viewer/components/viewer_home_header_actions.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🛡️ ViewerHeaderActions Widget Tests', () {
    testWidgets(
      '1. ViewerHomeHeaderActions renders MoreButton and opens menu correctly',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: ThemeData(
                extensions: [
                  AppThemeColors.ofMode(isDark: false, mode: 'normal'),
                ],
              ),
              home: Scaffold(
                appBar: AppBar(
                  actions: const [
                    ViewerHomeHeaderActions(
                      tournamentId: 't1',
                      isDark: false,
                      iconColor: Colors.black,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 「…」ボタンが存在すること
        final moreBtn = find.byIcon(Icons.more_horiz_rounded);
        expect(moreBtn, findsOneWidget);

        // タップしてメニューが展開されること
        await tester.tap(moreBtn);
        await tester.pumpAndSettle();

        expect(find.text('大会を共有する'), findsOneWidget);
        expect(find.text('表示設定'), findsOneWidget);
        expect(find.text('観戦ヘルプ・FAQ'), findsOneWidget);
      },
    );

    testWidgets(
      '2. ViewerBunaiksenHeaderActions renders calendar button when not QR access and opens More menu',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: ThemeData(
                extensions: [
                  AppThemeColors.ofMode(
                    isDark: false,
                    mode: 'bunaiksen_viewer',
                  ),
                ],
              ),
              home: Scaffold(
                appBar: AppBar(
                  actions: const [
                    ViewerBunaiksenHeaderActions(
                      tournamentId: 'bunaiksen_20260829',
                      dateDisplay: '2026年8月29日',
                      dojoId: 'd1',
                      isDark: false,
                      isQrAccess: false,
                      availableDates: {'20260829'},
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // カレンダーボタンが存在すること
        expect(find.byIcon(Icons.calendar_month), findsOneWidget);

        // 「…」ボタンが存在すること
        final moreBtn = find.byIcon(Icons.more_horiz_rounded);
        expect(moreBtn, findsOneWidget);

        // タップしてメニューが展開されること
        await tester.tap(moreBtn);
        await tester.pumpAndSettle();

        expect(find.text('部内戦 成績一覧'), findsOneWidget);
        expect(find.text('観戦リンクを共有する'), findsOneWidget);
        expect(find.text('表示設定'), findsOneWidget);
      },
    );
  });
}
