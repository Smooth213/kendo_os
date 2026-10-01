import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/application/services/thermal_monitor_service.dart';
import 'package:kendo_os/shared/application/services/thermal_power_governor.dart';
import 'package:kendo_os/shared/widgets/thermal_floating_toast.dart';

void main() {
  group('[Governance] サーマル適応警告トースト非ブロッキング表示およびメモリリーク排除規約', () {
    testWidgets(
      'ThermalToastListenerにおいてトースト表示中も子ウィジェットのタップ操作が阻害されず即座に応答すること',
      (tester) async {
        int tapCount = 0;
        final governor = ThermalPowerGovernor();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              thermalPowerGovernorProvider.overrideWith((ref) => governor),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: ThermalToastListener(
                  child: Center(
                    child: ElevatedButton(
                      onPressed: () {
                        tapCount++;
                      },
                      child: const Text('試合スコア記録ボタン'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // 初回タップ確認
        await tester.tap(find.text('試合スコア記録ボタン'));
        await tester.pump();
        expect(tapCount, equals(1));

        // トーストイベント発行をシミュレート（発熱検知）
        governor.updatePreference('auto');
        governor.updateThermalStatus(ThermalSensorStatus.serious);

        // マイクロタスクおよびトーストOverlayEntryの挿入・アニメーション
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        // トーストが表示されていることを確認
        expect(find.textContaining('端末の発熱を検知'), findsOneWidget);

        // トースト表示中でも背後・画面内のボタンをタップ可能であること（非ブロッキング）
        await tester.tap(find.text('試合スコア記録ボタン'));
        await tester.pump();
        expect(tapCount, equals(2));

        // 3秒経過で自動消去されること
        await tester.pump(const Duration(seconds: 4));
        expect(find.textContaining('端末の発熱を検知'), findsNothing);
      },
    );

    test(
      'ThermalToastListener実装において購読およびタイマーとOverlayEntryが明示的に完全破棄されていること',
      () {
        final file = File('lib/shared/widgets/thermal_floating_toast.dart');
        final content = file.readAsStringSync();

        // dispose メソッド内での明示的リソース解放の存在を静的監査
        expect(content.contains('void dispose()'), isTrue);
        expect(content.contains('_subscription?.cancel()'), isTrue);
        expect(content.contains('_dismissTimer?.cancel()'), isTrue);
        expect(content.contains('_overlayEntry?.remove()'), isTrue);
      },
    );
  });
}
