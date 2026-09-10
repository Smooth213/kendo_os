import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/viewer_qr_bottom_sheet.dart';
import 'package:qr_flutter/qr_flutter.dart';

Widget createTestWidget({required Widget child}) {
  return ProviderScope(
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  group('📲 ViewerQrBottomSheet Widget Tests', () {
    testWidgets('観戦用QRコードボトムシートが正常にレンダリングされQRとボタンが表示されること', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(
          child: const ViewerQrBottomSheet(tournamentId: 'test_tournament_123'),
        ),
      );
      await tester.pumpAndSettle();

      // ヘッダータイトルの存在確認
      expect(find.text('観戦用QRコード ＆ 速報共有'), findsOneWidget);

      // QrImageView の描画確認
      expect(find.byType(QrImageView), findsOneWidget);

      // 大会IDの表示確認
      expect(find.text('大会ID: test_tournament_123'), findsOneWidget);

      // 共有ボタンとURLコピーボタンの存在確認
      expect(find.text('LINEやSNSで観戦URLを送る'), findsOneWidget);
      expect(find.text('観戦URLをコピー'), findsOneWidget);
    });
  });
}
