import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/errors/safety_net_error_view.dart';

void main() {
  group('[Widget] 不壊セーフティネット画面および復旧導線テスト', () {
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
  });
}
