import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/auth/application/google_auth_service.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/settings/settings_google_auth_tile.dart';

void main() {
  group('🥋 SettingsGoogleAuthTile UI Tests', () {
    testWidgets('未連携時: 「Googleアカウント連携」および「連携する」ボタンが表示されること', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isGoogleLinkedProvider.overrideWithValue(false),
            linkedGoogleEmailProvider.overrideWithValue(null),
          ],
          child: const MaterialApp(
            home: Scaffold(body: SettingsGoogleAuthTile()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Googleアカウント連携'), findsOneWidget);
      expect(find.text('PCとiPadでクイックメモや通知既読を自動同期します'), findsOneWidget);
      expect(find.text('連携する'), findsOneWidget);
      expect(find.byIcon(Icons.sync_rounded), findsOneWidget);
    });

    testWidgets('連携済み時: 「Google連携中」とメールアドレス、同期有効ステータスが表示されること', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isGoogleLinkedProvider.overrideWithValue(true),
            linkedGoogleEmailProvider.overrideWithValue(
              'kendo.sensei@gmail.com',
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: SettingsGoogleAuthTile()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Google連携中'), findsOneWidget);
      expect(find.text('kendo.sensei@gmail.com'), findsOneWidget);
      expect(find.text('クラウド同期有効（メモ・既読共有中）'), findsOneWidget);
      expect(find.text('解除'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_done_rounded), findsOneWidget);
    });
  });
}
