import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bunaiksen/bunaiksen_home_action_helper.dart';

void main() {
  group('BunaiksenHomeActionHelper Tests', () {
    testWidgets('confirmDeleteMatch shows confirmation dialog', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Consumer(
                  builder: (context, ref, _) => ElevatedButton(
                    onPressed: () {
                      BunaiksenHomeActionHelper.confirmDeleteMatch(
                        context: context,
                        ref: ref,
                        matchId: 'm1',
                      );
                    },
                    child: const Text('Delete'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('試合の削除'), findsOneWidget);
      expect(find.text('キャンセル'), findsOneWidget);
    });
  });
}
