import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/login_screen.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';

void main() {
  group('🛡️ LoginScreen Dojo ID Display Tests', () {
    testWidgets(
      '1. Verify active Dojo ID is clearly displayed on LoginScreen',
      (WidgetTester tester) async {
        const testDojoId = 'tokyo_kendo_dojo_2026';

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentDojoIdProvider.overrideWith((ref) => testDojoId),
            ],
            child: const MaterialApp(home: LoginScreen()),
          ),
        );

        await tester.pumpAndSettle();

        // 接続中の道場ID のラベルと、設定されている ID 値が表示されることを検証
        expect(find.text('接続中の道場ID'), findsOneWidget);
        expect(find.text(testDojoId), findsOneWidget);
        expect(find.text('選択中'), findsOneWidget);
      },
    );
  });
}
