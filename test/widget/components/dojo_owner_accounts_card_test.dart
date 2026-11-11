import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/settings/dojo_owner_accounts_card.dart';
import 'package:kendo_os/security/viewer_share_models.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import '../../helpers/safe_pump_helper.dart';

void main() {
  group('[Widget] DojoOwnerAccountsCard 代表者管理カードテスト', () {
    testWidgets('最大5名の上限表示・最後の1名削除確認・手入力追加が機能すること', (tester) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');
      String? addedEmail;
      String? removedEmail;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(extensions: [themeColors]),
          home: Scaffold(
            body: SingleChildScrollView(
              child: DojoOwnerAccountsCard(
                themeColors: themeColors,
                owners: const [
                  DojoOwnerAccount(
                    email: 'captain@example.com',
                    displayName: '主将',
                  ),
                ],
                currentGoogleEmail: 'next_captain@example.com',
                isUpdating: false,
                onLinkCurrentGoogle: () async {},
                onAddManualEmail: (email) async => addedEmail = email,
                onRemoveEmail: (email) async => removedEmail = email,
              ),
            ),
          ),
        ),
      );
      await tester.safePumpAndSettle();

      expect(find.text('1 / 5 名'), findsOneWidget);
      expect(find.text('captain@example.com'), findsOneWidget);
      expect(find.textContaining('next_captain@example.com'), findsOneWidget);

      // メール手入力で追加
      await tester.enterText(find.byType(TextField), 'coach@example.com');
      await tester.tap(find.text('追加'));
      await tester.safePumpAndSettle();
      expect(addedEmail, 'coach@example.com');

      // 最後の1名削除時は確認ダイアログが出る
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.safePumpAndSettle();
      expect(find.text('最後の代表者を削除しますか？'), findsOneWidget);

      await tester.tap(find.text('削除する'));
      await tester.safePumpAndSettle();
      expect(removedEmail, 'captain@example.com');
    });
  });
}
