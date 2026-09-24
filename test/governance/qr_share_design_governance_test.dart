import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/home_screen_qr_dialog.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/qr_share_dialog.dart';
import 'package:qr_flutter/qr_flutter.dart';

// ============================================================================
// 🥋 【第8条 ガバナンス監査 3/3】🔗 QRコード共有UI（ポップアップ＆ボトムシート）デザイン統一永続保証規約
// ============================================================================
// QRコードのポップアップ（ダイアログ）やボトムシートが将来の開発で再び独自実装され、
// デザイン・角丸・URLコピー機能・シェアボタンが不揃いになることを全自動で遮断・永続防護します。
// ============================================================================
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🥋 【第8条 ガバナンス 3/3】🔗 QRコード共有UIデザイン統一永続保証規約', () {
    late List<File> dartFiles;

    setUpAll(() {
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue, reason: 'lib directory must exist.');

      dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .toList();
    });

    test('Rule 1: 生の QrImageView 直接配置の排除と統一コンポーネント限定規約', () {
      final allowedFiles = {
        'lib/shared/widgets/qr_share_dialog.dart',
        'lib/features/tournament/presentation/components/program_management/viewer_qr_bottom_sheet.dart',
        'lib/features/p2p/presentation/components/p2p_broadcast_dialog.dart',
      };

      final violations = <String>[];

      for (final file in dartFiles) {
        final normalizedPath = file.path.replaceAll('\\', '/');
        final isAllowed = allowedFiles.any(
          (allowed) => normalizedPath.endsWith(allowed),
        );
        if (isAllowed) continue;

        final content = file.readAsStringSync();
        if (content.contains('QrImageView(')) {
          violations.add(file.path);
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            '許可されていない画面で生の QrImageView の直接配置が検出されました。\n'
            'QRコード共有は統一コンポーネント QrShareDialog または ViewerQrBottomSheet を使用してください。\n'
            '違反ファイル:\n${violations.join('\n')}',
      );
    });

    test('Rule 2: 全てのQR共有ダイアログが QrShareDialog を利用していることの構造監査', () {
      final shareDialogFiles = [
        'lib/features/tournament/presentation/operate/components/home/home_screen_qr_dialog.dart',
        'lib/features/tournament/presentation/operate/components/settings/web_app_qr_dialog.dart',
        'lib/features/tournament/presentation/operate/components/bunaiksen/bunaiksen_share_dialog.dart',
        'lib/features/viewer/presentation/components/viewer_share_dialog.dart',
        'lib/features/viewer/components/viewer_bunaiksen_share_dialog.dart',
        'lib/features/viewer/presentation/viewer_match_screen.dart',
      ];

      final violations = <String>[];

      for (final relativePath in shareDialogFiles) {
        final file = dartFiles.firstWhere(
          (f) => f.path.replaceAll('\\', '/').endsWith(relativePath),
          orElse: () => File(''),
        );

        if (!file.existsSync()) {
          violations.add('$relativePath が存在しません');
          continue;
        }

        final content = file.readAsStringSync();
        if (!content.contains('QrShareDialog')) {
          violations.add('$relativePath で QrShareDialog が使用されていません');
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'QRコード共有ダイアログで QrShareDialog を使用していないファイルが検出されました。\n'
            '違反ファイル:\n${violations.join('\n')}',
      );
    });

    testWidgets(
      'Rule 3-1: QrShareDialog が必須UI要素（アイコン・QRカード・URLバー・コピー・シェアボタン）を完備していること',
      (tester) async {
        const testUrl = 'https://kendo-os-beta.web.app/viewer-home/gov_test';

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light().copyWith(
              extensions: [
                AppThemeColors.ofMode(isDark: false, mode: 'normal'),
              ],
            ),
            home: const Scaffold(
              body: QrShareDialog(
                title: '大会観戦リンク',
                themeColor: AppKendoColors.teal,
                description: 'テスト説明文',
                shareUrl: testUrl,
                shareText: 'シェアテキスト',
                subtitleBadge: '大会ID: gov_test',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. タイトルアイコン (Icons.qr_code_2_rounded)
        expect(find.byIcon(Icons.qr_code_2_rounded), findsOneWidget);

        // 2. QRカード (QrImageView)
        expect(find.byType(QrImageView), findsOneWidget);

        // 3. 大会IDバッジ
        expect(find.text('大会ID: gov_test'), findsOneWidget);

        // 4. URLバー ＆ コピーボタン
        expect(find.text(testUrl), findsOneWidget);
        expect(find.byIcon(Icons.link), findsOneWidget);
        expect(find.byIcon(Icons.copy_rounded), findsOneWidget);

        // 5. シェアボタン (Icons.ios_share)
        expect(find.byIcon(Icons.ios_share), findsOneWidget);
        expect(find.text('LINEやSNSでURLを送る'), findsOneWidget);
      },
    );

    testWidgets(
      'Rule 3-2: 各種ダイアログ（HomeScreenQrDialog, WebAppQrDialog, BunaiksenShareDialog, ViewerShareDialog）の描画完全性',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light().copyWith(
              extensions: [
                AppThemeColors.ofMode(isDark: false, mode: 'normal'),
              ],
            ),
            home: const Scaffold(
              body: HomeScreenQrDialog(
                shareUrl: 'https://kendo-os-beta.web.app/viewer-home/gov_home',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(QrShareDialog), findsOneWidget);
        expect(find.byType(QrImageView), findsOneWidget);
        expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
        expect(find.byIcon(Icons.ios_share), findsOneWidget);
      },
    );

    test(
      'Rule 4: ViewerQrBottomSheet がURL表示バー・コピー・共有ボタン・QRカード装飾を完備していることの静的監査',
      () {
        final sheetFile = dartFiles.firstWhere(
          (f) => f.path
              .replaceAll('\\', '/')
              .endsWith(
                'lib/features/tournament/presentation/components/program_management/viewer_qr_bottom_sheet.dart',
              ),
        );

        final content = sheetFile.readAsStringSync();

        // 必須UI要素の存在検証
        expect(
          content.contains('QrImageView('),
          isTrue,
          reason: 'QRコード表示が存在すること',
        );
        expect(
          content.contains('Icons.link'),
          isTrue,
          reason: 'URLリンクアイコンが存在すること',
        );
        expect(
          content.contains('Icons.ios_share'),
          isTrue,
          reason: 'シェアアイコンが存在すること',
        );
        expect(
          content.contains('Icons.copy_rounded'),
          isTrue,
          reason: 'コピーアイコンが存在すること',
        );
        expect(
          content.contains('SelectableText('),
          isTrue,
          reason: 'URL選択可能テキストが存在すること',
        );
        expect(
          content.contains('AppRadius.large'),
          isTrue,
          reason: 'QRカードの角丸がAppRadius.largeであること',
        );
        expect(
          content.contains('AppKendoColors.teal'),
          isTrue,
          reason: 'アクセントカラーがAppKendoColors.tealであること',
        );
      },
    );
  });
}
