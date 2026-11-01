import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/settings/settings_ui_tiles.dart';
import 'package:kendo_os/shared/constants/legal_texts.dart';
import 'package:kendo_os/shared/presentation/screens/embedded_manual_screen.dart';
import 'package:kendo_os/shared/presentation/widgets/legal_document_dialog.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:url_launcher/url_launcher.dart';

/// 設定画面の「サポート・規約・情報」セクション
class SettingsSupportSection extends StatelessWidget {
  final bool enableLiquidGlass;
  final AppThemeColors themeColors;

  const SettingsSupportSection({
    super.key,
    required this.enableLiquidGlass,
    required this.themeColors,
  });

  Future<void> _launchContactForm(BuildContext context) async {
    final uri = Uri.parse(AppLegalTexts.contactFormUrl);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        AppSnackBar.showError(context, 'お問い合わせページを開けませんでした。');
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.showError(context, 'お問い合わせページを開けませんでした。');
      }
    }
  }

  void _openManual(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const EmbeddedManualScreen(initialTab: 0),
        fullscreenDialog: true,
      ),
    );
  }

  void _showTermsOfService(BuildContext context) {
    LegalDocumentDialog.show(
      context: context,
      title: AppLegalTexts.termsOfServiceTitle,
      content: AppLegalTexts.termsOfServiceContent,
      icon: Icons.description_outlined,
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    LegalDocumentDialog.show(
      context: context,
      title: AppLegalTexts.privacyPolicyTitle,
      content: AppLegalTexts.privacyPolicyContent,
      icon: Icons.privacy_tip_outlined,
    );
  }

  void _showAboutApp(BuildContext context) {
    LegalDocumentDialog.show(
      context: context,
      title: AppLegalTexts.aboutAppTitle,
      content: AppLegalTexts.aboutAppContent,
      icon: Icons.info_outline_rounded,
    );
  }

  void _showLicenses(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: 'KendoSync',
      applicationVersion: AppLegalTexts.appVersion,
      applicationLegalese: '© 2026 ${AppLegalTexts.developerTeamName}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(title: 'サポート・規約・情報'),
        SettingsBlock(
          enableLiquidGlass: enableLiquidGlass,
          themeColors: themeColors,
          children: [
            SettingsListTile(
              title: 'お問い合わせ・ご意見',
              subtitle: 'Googleフォームが開きます',
              icon: Icons.mail_outline_rounded,
              iconBgColor: AppKendoColors.blueAccent,
              trailing: const Icon(
                Icons.open_in_new_rounded,
                size: 20,
                color: AppKendoColors.blueAccent,
              ),
              onTap: () => _launchContactForm(context),
            ),
            SettingsListTile(
              title: '操作マニュアル',
              subtitle: 'クイックガイド・機能解説',
              icon: Icons.menu_book_rounded,
              iconBgColor: AppKendoColors.ipponGold,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openManual(context),
            ),
            SettingsListTile(
              title: '利用規約',
              icon: Icons.description_outlined,
              iconBgColor: AppKendoColors.indigo,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showTermsOfService(context),
            ),
            SettingsListTile(
              title: 'プライバシーポリシー',
              icon: Icons.privacy_tip_outlined,
              iconBgColor: AppKendoColors.indigo,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showPrivacyPolicy(context),
            ),
            SettingsListTile(
              title: 'KendoSync について',
              icon: Icons.info_outline_rounded,
              iconBgColor: themeColors.primaryAccent,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showAboutApp(context),
            ),
            SettingsListTile(
              title: 'オープンソースライセンス',
              icon: Icons.balance_rounded,
              iconBgColor: themeColors.subTextColor,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showLicenses(context),
            ),
          ],
        ),
        const SettingsSectionFooter(
          text:
              '※ KendoSync は剣道の大会・部内戦運営を支える無料のシステムです。ご意見・不具合のご報告は「お問い合わせ」フォームよりお気軽にお寄せください。',
        ),
      ],
    );
  }
}
