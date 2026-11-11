import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/viewer/presentation/screens/viewer_share_expired_screen.dart';
import 'package:kendo_os/security/viewer_share_models.dart';
import 'package:kendo_os/security/viewer_share_repository.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/presentation/providers/current_user_role_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/qr_share_dialog.dart';
import 'package:kendo_os/shared/widgets/viewer_share_expiry_selector.dart';
import '../../helpers/safe_pump_helper.dart';

void main() {
  group('[Widget] 1大会限定QR共有 有効期限選択・失効画面テスト', () {
    testWidgets('ViewerShareExpirySelector で 24時間 / 7日間 / 無期限 / 停止 を選択できること', (
      tester,
    ) async {
      ViewerShareExpiryPreset? selected;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
          ),
          home: Scaffold(
            body: ViewerShareExpirySelector(
              selectedPreset: ViewerShareExpiryPreset.days7,
              expiresAt: DateTime(2026, 11, 18, 12, 0),
              onPresetSelected: (p) => selected = p,
            ),
          ),
        ),
      );
      await tester.safePumpAndSettle();

      expect(find.text('24時間'), findsOneWidget);
      expect(find.text('7日間'), findsOneWidget);
      expect(find.text('無期限'), findsOneWidget);
      expect(find.text('停止'), findsOneWidget);
      expect(find.textContaining('公開期限:'), findsOneWidget);

      await tester.tap(find.text('停止'));
      await tester.safePumpAndSettle();
      expect(selected, ViewerShareExpiryPreset.revoked);
    });

    testWidgets('QrShareDialog がスタッフ操作時に初期値7日間でトークンを発行し、停止へ切り替えられること', (
      tester,
    ) async {
      final fakeFirestore = FakeFirebaseFirestore();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            viewerShareFirestoreProvider.overrideWithValue(fakeFirestore),
            currentUserRoleProvider.overrideWithValue(UserRole.admin),
          ],
          child: MaterialApp(
            theme: ThemeData.light().copyWith(
              extensions: [
                AppThemeColors.ofMode(isDark: false, mode: 'normal'),
              ],
            ),
            home: const Scaffold(
              body: QrShareDialog(
                title: '大会観戦リンク',
                description: 'テスト共有',
                shareUrl:
                    'https://kendo-os-beta.web.app/viewer-home/t_1?role=viewer&dojoId=dojo_1',
                shareText:
                    'https://kendo-os-beta.web.app/viewer-home/t_1?role=viewer&dojoId=dojo_1',
                shareDojoId: 'dojo_1',
                shareTournamentId: 't_1',
              ),
            ),
          ),
        ),
      );
      await tester.safePumpAndSettle();

      // token= がURLに付与され、有効期限UIが表示されていること
      expect(find.textContaining('token='), findsOneWidget);
      expect(find.text('7日間'), findsOneWidget);

      await tester.runAsync(() async {
        await tester.tap(find.text('停止'));
        await Future<void>.delayed(Duration.zero);
      });
      await tester.safePumpAndSettle();

      expect(find.textContaining('現在この共有リンクは停止中です'), findsOneWidget);

      final metaSnap = await fakeFirestore
          .collection('organizations')
          .doc('dojo_1')
          .collection('share_meta')
          .doc('t_1')
          .get();
      expect(metaSnap.data()?['isRevoked'], isTrue);
      expect(metaSnap.data()?['preset'], 'revoked');
    });

    testWidgets('ViewerShareExpiredScreen が期限切れと公開停止で適切な案内と道場参加導線を表示すること', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
          ),
          home: const ViewerShareExpiredScreen(
            status: ViewerShareAccessStatus.expired,
          ),
        ),
      );
      await tester.safePumpAndSettle();

      expect(find.text('観戦リンクの公開期間が終了しました'), findsOneWidget);
      expect(find.text('道場ID・入室PINから参加する'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
          ),
          home: const ViewerShareExpiredScreen(
            status: ViewerShareAccessStatus.revoked,
          ),
        ),
      );
      await tester.safePumpAndSettle();
      expect(find.text('観戦リンクは公開停止中です'), findsOneWidget);
    });
  });
}
