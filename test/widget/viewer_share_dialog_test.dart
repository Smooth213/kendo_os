import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_share_dialog.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  group('🛡️ ViewerShareDialog Widget Tests', () {
    testWidgets('Renders QR code and share button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ViewerShareDialog(tournamentId: 't1', dojoId: 'd1'),
          ),
        ),
      );

      expect(find.text('大会観戦リンク'), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text('LINEやSNSでURLを送る'), findsOneWidget);
      expect(find.text('閉じる'), findsOneWidget);
    });
  });
}
