import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/settings/dojo_security_settings_sheet.dart';
import 'package:kendo_os/security/dojo_security_repository.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import '../../helpers/safe_pump_helper.dart';

void main() {
  group('[Widget] DojoSecuritySettingsSheet 2段階アンロック・余白・キーボード対応テスト', () {
    testWidgets(
      'DojoSecuritySettingsSheet が上端余白・左右パディングを保ちAdmin本人確認後に全PINを初期表示すること',
      (tester) async {
        tester.view.physicalSize = const Size(375, 667);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          tester.view.resetViewInsets();
        });

        final fakeFirestore = FakeFirebaseFirestore();
        final repo = DojoSecurityRepository(fakeFirestore);
        await repo.createDojoWithPin(
          dojoId: 'test204',
          joinPin: 'dojo2026',
          uid: 'u1',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentDojoIdProvider.overrideWith((ref) => 'test204'),
              dojoSecurityFirestoreProvider.overrideWithValue(fakeFirestore),
            ],
            child: MaterialApp(
              theme: ThemeData.light().copyWith(
                extensions: [
                  AppThemeColors.ofMode(isDark: false, mode: 'normal'),
                ],
              ),
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () => DojoSecuritySettingsSheet.show(context),
                    child: const Text('OpenSettings'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('OpenSettings'));
        await tester.safePumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('道場セキュリティ・PIN設定'), findsOneWidget);
        expect(find.text('対象道場: test204'), findsOneWidget);
        expect(find.text('1. 本人確認（必須）'), findsOneWidget);
        expect(find.text('2. 現在のPIN確認・変更'), findsNothing);

        // 上端余白・左右パディング検証
        final sheetTop = tester
            .getTopLeft(find.byType(DojoSecuritySettingsSheet))
            .dy;
        expect(sheetTop, greaterThanOrEqualTo(667 * 0.10));

        final firstFieldRect = tester.getRect(find.byType(TextField).first);
        expect(firstFieldRect.left, greaterThanOrEqualTo(AppSpacing.xl));
        expect(firstFieldRect.right, lessThanOrEqualTo(375 - AppSpacing.xl));

        // 誤ったPINは拒否
        await tester.enterText(find.byType(TextField).first, '0000');
        await tester.tap(find.text('本人確認して現在のPINを表示'));
        await tester.safePumpAndSettle();
        expect(find.textContaining('一致しません'), findsOneWidget);

        // 正しいAdmin PINで本人確認すると現在の全PINが初期表示されること
        await tester.enterText(find.byType(TextField).first, '9999');
        await tester.tap(find.text('本人確認して現在のPINを表示'));
        await tester.safePumpAndSettle();

        expect(find.text('2. 現在のPIN確認・変更'), findsOneWidget);
        expect(find.text('3. 代表者Googleアカウント（PIN復旧・引き継ぎ用）'), findsOneWidget);
        expect(find.text('dojo2026'), findsOneWidget);
        expect(find.text('9999'), findsOneWidget);
        expect(find.text('2468'), findsOneWidget);
        expect(find.text('1357'), findsOneWidget);

        // キーボード出現時にもオーバーフローしないこと
        tester.view.viewInsets = const FakeViewPadding(bottom: 280);
        await tester.safePumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'DojoSecuritySettingsSheet でPIN編集保存と代表者追加・削除を行い再オープン時に反映されていること',
      (tester) async {
        final fakeFirestore = FakeFirebaseFirestore();
        final repo = DojoSecurityRepository(fakeFirestore);
        await repo.createDojoWithPin(
          dojoId: 'edit_dojo',
          joinPin: 'dojo2026',
          uid: 'u1',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentDojoIdProvider.overrideWith((ref) => 'edit_dojo'),
              dojoSecurityFirestoreProvider.overrideWithValue(fakeFirestore),
            ],
            child: MaterialApp(
              theme: ThemeData.light().copyWith(
                extensions: [
                  AppThemeColors.ofMode(isDark: false, mode: 'normal'),
                ],
              ),
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () => DojoSecuritySettingsSheet.show(context),
                    child: const Text('OpenEdit'),
                  ),
                ),
              ),
            ),
          ),
        );

        // 1回目オープン＆アンロック
        await tester.tap(find.text('OpenEdit'));
        await tester.safePumpAndSettle();
        await tester.enterText(find.byType(TextField).first, '9999');
        await tester.tap(find.text('本人確認して現在のPINを表示'));
        await tester.safePumpAndSettle();

        // 代表者メールを追加して削除できること
        final ownerField = find.byType(TextField).last;
        await tester.ensureVisible(ownerField);
        await tester.enterText(ownerField, 'captain2027@example.com');
        await tester.tap(find.text('追加'));
        await tester.safePumpAndSettle();
        expect(find.text('captain2027@example.com'), findsOneWidget);
        expect(find.text('1 / 5 名'), findsOneWidget);

        // Operator PIN（index 3）を変更して保存
        final operatorField = find.byType(TextField).at(3);
        await tester.ensureVisible(operatorField);
        await tester.enterText(operatorField, '4455');
        await tester.ensureVisible(find.text('PIN変更を保存する'));
        await tester.tap(find.text('PIN変更を保存する'));
        await tester.safePumpAndSettle();

        // シートが閉じたあと再度開くと変更後のPINと代表者が保持されていること
        expect(find.byType(DojoSecuritySettingsSheet), findsNothing);
        await tester.tap(find.text('OpenEdit'));
        await tester.safePumpAndSettle();
        await tester.enterText(find.byType(TextField).first, '9999');
        await tester.tap(find.text('本人確認して現在のPINを表示'));
        await tester.safePumpAndSettle();

        expect(find.text('4455'), findsOneWidget);
        expect(find.text('captain2027@example.com'), findsOneWidget);
      },
    );

    testWidgets('admin_vault 未移行の既存道場でカスタムPINアンロック時に案内と本人PINのみ表示されること', (
      tester,
    ) async {
      final fakeFirestore = FakeFirebaseFirestore();
      final repo = DojoSecurityRepository(fakeFirestore);
      await repo.createDojoWithPin(
        dojoId: 'legacy_custom',
        joinPin: 'legacy123',
        uid: 'u1',
      );
      await repo.updateDojoSecurityPins(
        dojoId: 'legacy_custom',
        currentAdminPin: '9999',
        newRolePins: {UserRole.admin: '8888'},
        uid: 'u1',
      );
      await fakeFirestore
          .collection('organizations')
          .doc('legacy_custom')
          .collection('private')
          .doc('admin_vault')
          .delete();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentDojoIdProvider.overrideWith((ref) => 'legacy_custom'),
            dojoSecurityFirestoreProvider.overrideWithValue(fakeFirestore),
          ],
          child: MaterialApp(
            theme: ThemeData.light().copyWith(
              extensions: [
                AppThemeColors.ofMode(isDark: false, mode: 'normal'),
              ],
            ),
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => DojoSecuritySettingsSheet.show(context),
                  child: const Text('OpenLegacy'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('OpenLegacy'));
      await tester.safePumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '8888');
      await tester.tap(find.text('本人確認して現在のPINを表示'));
      await tester.safePumpAndSettle();

      expect(find.textContaining('未移行の既存PINは空欄で表示されます'), findsOneWidget);
      expect(find.text('8888'), findsOneWidget);
      expect(find.text('legacy123'), findsNothing);
    });
  });
}
