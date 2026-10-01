import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/viewer/components/viewer_bunaiksen_share_dialog.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Widget] ViewerBunaiksenShareDialog ウィジェットテスト', () {
    testWidgets('部内戦観客用共有ダイアログが正常に表示されること', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentDojoIdProvider.overrideWith((ref) => 'org_dojo_test'),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  return ElevatedButton(
                    onPressed: () {
                      ViewerBunaiksenShareDialog.show(
                        context,
                        ref,
                        tournamentId: 't-12345',
                        dateDisplay: '2026年10月2日',
                      );
                    },
                    child: const Text('共有ダイアログを開く'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('共有ダイアログを開く'), findsOneWidget);
      await tester.tap(find.text('共有ダイアログを開く'));
      await tester.pumpAndSettle();

      expect(find.text('2026年10月2日 観戦リンク'), findsOneWidget);
      expect(find.text('部内戦ID: t-12345'), findsOneWidget);
      expect(find.text('LINEやSNSでURLを送る'), findsOneWidget);
    });

    testWidgets('dojoIdが未設定の場合はdefault_orgがフォールバックされること', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [currentDojoIdProvider.overrideWith((ref) => '')],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  return ElevatedButton(
                    onPressed: () {
                      ViewerBunaiksenShareDialog.show(
                        context,
                        ref,
                        tournamentId: 't-default',
                        dateDisplay: '2026年10月3日',
                      );
                    },
                    child: const Text('フォールバック共有'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('フォールバック共有'));
      await tester.pumpAndSettle();

      expect(find.text('2026年10月3日 観戦リンク'), findsOneWidget);
      expect(find.text('部内戦ID: t-default'), findsOneWidget);
    });
  });
}
