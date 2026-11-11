import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/auth/presentation/widgets/initial_role_pin_prompt_dialog.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/settings/dojo_security_settings_tile.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_user_role_provider.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/room_join_pin_dialog.dart';
import '../../helpers/safe_pump_helper.dart';

void main() {
  group('[Widget] 道場PINダイアログ・初回Admin案内・設定セクションテスト', () {
    testWidgets('RoomJoinPinDialog が新規作成時の4〜20文字制限と6文字以上推奨案内を表示すること', (
      tester,
    ) async {
      String? submittedPin;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  RoomJoinPinDialog.show(
                    context: context,
                    dojoId: 'test_dojo',
                    mode: RoomJoinPinMode.createNew,
                    onSubmitPin: (pin) async {
                      submittedPin = pin;
                      return null;
                    },
                  );
                },
                child: const Text('OpenPin'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('OpenPin'));
      await tester.safePumpAndSettle();

      // 入力欄・送信ボタンがカプセル型（AppRadius.capsule / StadiumBorder）であることの回帰防止
      final textField = tester.widget<TextField>(find.byType(TextField));
      final enabledBorder =
          textField.decoration?.enabledBorder as OutlineInputBorder?;
      expect(enabledBorder?.borderRadius, AppRadius.capsule);
      final submitButton = tester.widget<ElevatedButton>(
        find.ancestor(
          of: find.text('PINを設定して作成'),
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(submitButton.style?.shape?.resolve({}), isA<StadiumBorder>());

      // 短すぎる入力はエラー
      await tester.enterText(find.byType(TextField), 'abc');
      await tester.tap(find.text('PINを設定して作成'));
      await tester.safePumpAndSettle();
      expect(find.textContaining('4文字以上で入力'), findsOneWidget);
      expect(submittedPin, isNull);

      // 4文字は登録可能だが推奨案内が出る
      await tester.enterText(find.byType(TextField), '1234');
      await tester.safePumpAndSettle();
      expect(find.textContaining('6文字以上の英数字を推奨'), findsWidgets);

      // 6文字以上は推奨メッセージが出て登録成功
      await tester.enterText(find.byType(TextField), 'dojo2026');
      await tester.safePumpAndSettle();
      expect(find.textContaining('推奨文字数（6文字以上）を満たしています'), findsOneWidget);

      await tester.tap(find.text('PINを設定して作成'));
      await tester.safePumpAndSettle();
      expect(submittedPin, 'dojo2026');
      expect(find.byType(RoomJoinPinDialog), findsNothing);
    });

    testWidgets('InitialRolePinPromptDialog で「今すぐ変更する」「初期PINのまま使う」を選択できること', (
      tester,
    ) async {
      InitialRolePinPromptAction? result;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await InitialRolePinPromptDialog.show(
                    context,
                    dojoId: 'kendo_dojo',
                  );
                },
                child: const Text('Prompt'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Prompt'));
      await tester.safePumpAndSettle();
      expect(find.text('権限PINの設定確認（初回のみ）'), findsOneWidget);

      await tester.tap(find.text('初期PINのまま使う'));
      await tester.safePumpAndSettle();
      expect(result, InitialRolePinPromptAction.keepDefault);
    });

    testWidgets(
      'DojoSecuritySettingsSection が Admin のみ表示され Operator では非表示であること',
      (tester) async {
        final themeColors = AppThemeColors.ofMode(
          isDark: false,
          mode: 'normal',
        );

        Widget buildForRole(UserRole role) {
          return ProviderScope(
            overrides: [
              currentUserRoleProvider.overrideWithValue(role),
              currentDojoIdProvider.overrideWith((ref) => 'dojo_sec_1'),
            ],
            child: MaterialApp(
              theme: ThemeData.light().copyWith(extensions: [themeColors]),
              home: Scaffold(
                body: DojoSecuritySettingsSection(
                  enableLiquidGlass: false,
                  themeColors: themeColors,
                ),
              ),
            ),
          );
        }

        await tester.pumpWidget(buildForRole(UserRole.operator));
        await tester.safePumpAndSettle();
        expect(find.text('道場入室PIN・ロールPINの変更'), findsNothing);

        await tester.pumpWidget(buildForRole(UserRole.admin));
        await tester.safePumpAndSettle();
        expect(find.text('道場入室PIN・ロールPINの変更'), findsOneWidget);
      },
    );
  });
}
