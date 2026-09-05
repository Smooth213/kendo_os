import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/floating_dock_sheet_manager.dart';

void main() {
  group('📌 【ガバナンス監査 18/18】FloatingDock 常設ドック・オーバーレイ解放＆ライフサイクル規約テスト', () {
    testWidgets(
      '1. OverlayEntry ライフサイクル解放規約: show/close が安全に動作し isOpen が正しく遷移すること',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      FloatingDockSheetManager.show(
                        context: context,
                        builder: (sheetContext) => const SizedBox(
                          height: 200,
                          child: Text('Dock Sheet Content'),
                        ),
                      );
                    },
                    child: const Text('Open Dock'),
                  );
                },
              ),
            ),
          ),
        );

        // 初期状態は閉じている
        expect(FloatingDockSheetManager.isOpen, isFalse);

        // 開く
        await tester.tap(find.text('Open Dock'));
        await tester.pumpAndSettle();

        expect(FloatingDockSheetManager.isOpen, isTrue);
        expect(find.text('Dock Sheet Content'), findsOneWidget);

        // 即時閉じる
        await FloatingDockSheetManager.close(immediate: true);
        await tester.pumpAndSettle();

        expect(FloatingDockSheetManager.isOpen, isFalse);
        expect(find.text('Dock Sheet Content'), findsNothing);
      },
    );

    testWidgets('2. 二重 show 呼び出し時の既存オーバーレイ自動解放規約: 新規シート展開時に旧シートがリークしないこと', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        FloatingDockSheetManager.show(
                          context: context,
                          builder: (_) => const Text('Sheet 1'),
                        );
                      },
                      child: const Text('Open 1'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        FloatingDockSheetManager.show(
                          context: context,
                          builder: (_) => const Text('Sheet 2'),
                        );
                      },
                      child: const Text('Open 2'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      // Sheet 1 を開く
      await tester.tap(find.text('Open 1'));
      await tester.pumpAndSettle();
      expect(find.text('Sheet 1'), findsOneWidget);

      // Sheet 2 を開く（Sheet 1 が自動で閉じられる）
      await tester.tap(find.text('Open 2'));
      await tester.pumpAndSettle();
      expect(find.text('Sheet 1'), findsNothing);
      expect(find.text('Sheet 2'), findsOneWidget);

      // クリーンアップ
      await FloatingDockSheetManager.close(immediate: true);
      await tester.pumpAndSettle();
      expect(FloatingDockSheetManager.isOpen, isFalse);
    });

    test('3. 未オープン時の安全 close 規約: 未展開時の close 呼び出しが例外をスローしないこと', () async {
      expect(FloatingDockSheetManager.isOpen, isFalse);
      // 未オープン時に close を呼んでも安全にスルーされる
      await expectLater(
        FloatingDockSheetManager.close(immediate: true),
        completes,
      );
      expect(FloatingDockSheetManager.isOpen, isFalse);
    });

    test(
      '4. 静的コード規約: lib/features/viewer/ 配下に FloatingDock 関連コードが物理排除されていること',
      () {
        final viewerDir = Directory('lib/features/viewer');
        expect(viewerDir.existsSync(), isTrue);

        final dartFiles = viewerDir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'));

        for (final file in dartFiles) {
          final content = file.readAsStringSync();
          expect(
            content.contains('FloatingProgramDockButton'),
            isFalse,
            reason:
                '🚨 閲覧画面 (${file.path}) に FloatingProgramDockButton が混入しています！',
          );
          expect(
            content.contains('FloatingDockSheetManager'),
            isFalse,
            reason:
                '🚨 閲覧画面 (${file.path}) に FloatingDockSheetManager が混入しています！',
          );
        }
      },
    );
  });
}
