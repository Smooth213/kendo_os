import 'package:flutter/material.dart';
import 'package:kendo_os/security/viewer_share_models.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';
import 'package:kendo_os/shared/widgets/app_loading_indicator.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

/// 道場単位の代表者Googleアカウント（PIN初期化・代替わり引き継ぎ用 / 最大5名）管理カード
class DojoOwnerAccountsCard extends StatefulWidget {
  final AppThemeColors themeColors;
  final List<DojoOwnerAccount> owners;
  final String? currentGoogleEmail;
  final bool isUpdating;
  final Future<void> Function() onLinkCurrentGoogle;
  final Future<void> Function(String email) onAddManualEmail;
  final Future<void> Function(String email) onRemoveEmail;

  const DojoOwnerAccountsCard({
    super.key,
    required this.themeColors,
    required this.owners,
    required this.currentGoogleEmail,
    required this.isUpdating,
    required this.onLinkCurrentGoogle,
    required this.onAddManualEmail,
    required this.onRemoveEmail,
  });

  @override
  State<DojoOwnerAccountsCard> createState() => _DojoOwnerAccountsCardState();
}

class _DojoOwnerAccountsCardState extends State<DojoOwnerAccountsCard> {
  final TextEditingController _emailCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitManualEmail() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || widget.isUpdating) return;
    await widget.onAddManualEmail(email);
    if (mounted) {
      _emailCtrl.clear();
    }
  }

  Future<void> _confirmAndRemove(String email) async {
    if (widget.isUpdating) return;
    if (widget.owners.length <= 1) {
      final confirmed = await showAppDialog<bool>(
        context: context,
        builder: (ctx) => AppDialog(
          title: '最後の代表者を削除しますか？',
          titleIcon: Icons.warning_amber_rounded,
          iconColor: AppKendoColors.orangeAccent,
          content: Text(
            '代表者を0名にすると、PINを忘れた際にGoogleアカウントで初期化できなくなります。\n'
            '引き継ぎの場合は、先に新しい代表者を追加してから削除することをおすすめします。',
            style: TextStyle(
              color: widget.themeColors.subTextColor,
              fontSize: AppFontSize.bodySmall,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'キャンセル',
                style: TextStyle(
                  color: widget.themeColors.subTextColor,
                  fontWeight: AppFontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppKendoColors.redAccent,
                foregroundColor: AppKendoColors.pureWhite,
                elevation: 0,
                shape: const StadiumBorder(),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(
                '削除する',
                style: TextStyle(fontWeight: AppFontWeight.bold),
              ),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await widget.onRemoveEmail(email);
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = widget.themeColors;
    final owners = widget.owners;
    final isFull = owners.length >= maxDojoOwnerAccounts;
    final signedInEmail = widget.currentGoogleEmail?.trim().toLowerCase();
    final isSignedInAlreadyRegistered =
        signedInEmail != null &&
        signedInEmail.isNotEmpty &&
        owners.any((o) => o.normalizedEmail == signedInEmail);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: themeColors.inputBackground.withValues(alpha: 0.55),
        borderRadius: AppRadius.large,
        border: Border.all(
          color: themeColors.separatorColor.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '3. 代表者Googleアカウント（PIN復旧・引き継ぎ用）',
                  style: TextStyle(
                    color: themeColors.subTextColor,
                    fontSize: AppFontSize.caption,
                    fontWeight: AppFontWeight.bold,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: AppKendoColors.teal.withValues(alpha: 0.14),
                  borderRadius: AppRadius.capsule,
                ),
                child: Text(
                  '${owners.length} / $maxDojoOwnerAccounts 名',
                  style: const TextStyle(
                    color: AppKendoColors.teal,
                    fontSize: AppFontSize.badge,
                    fontWeight: AppFontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'PINを忘れた際の初期化や、部活・団体の代替わり引き継ぎに使います（主将・顧問など最大$maxDojoOwnerAccounts名）。',
            style: TextStyle(
              color: themeColors.subTextColor,
              fontSize: AppFontSize.small,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (owners.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppKendoColors.orangeAccent.withValues(alpha: 0.1),
                borderRadius: AppRadius.medium,
              ),
              child: Text(
                '未登録です。万が一PINを忘れた場合に備えて、代表者のGoogleアカウントを登録してください。',
                style: TextStyle(
                  color: themeColors.textColor,
                  fontSize: AppFontSize.small,
                  height: 1.4,
                ),
              ),
            )
          else
            Column(
              children: [
                for (int i = 0; i < owners.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: themeColors.cardBackground,
                      borderRadius: AppRadius.medium,
                      border: Border.all(
                        color: themeColors.separatorColor.withValues(
                          alpha: 0.45,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.verified_user_outlined,
                          size: 18,
                          color: AppKendoColors.teal,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                owners[i].email,
                                style: TextStyle(
                                  color: themeColors.textColor,
                                  fontSize: AppFontSize.bodySmall,
                                  fontWeight: AppFontWeight.semiBold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (owners[i].displayName != null &&
                                  owners[i].displayName!.isNotEmpty)
                                Text(
                                  owners[i].displayName!,
                                  style: TextStyle(
                                    color: themeColors.subTextColor,
                                    fontSize: AppFontSize.caption,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: '代表者から削除',
                          icon: Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: themeColors.subTextColor,
                          ),
                          onPressed: widget.isUpdating
                              ? null
                              : () => _confirmAndRemove(owners[i].email),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          if (!isFull) ...[
            const SizedBox(height: AppSpacing.md),
            if (widget.isUpdating)
              const Center(
                child: AppLoadingIndicator(color: AppKendoColors.teal),
              )
            else ...[
              if (!isSignedInAlreadyRegistered)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppKendoColors.teal,
                    side: const BorderSide(color: AppKendoColors.teal),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                      horizontal: AppSpacing.md,
                    ),
                    shape: const StadiumBorder(),
                  ),
                  onPressed: widget.onLinkCurrentGoogle,
                  icon: const Icon(Icons.account_circle_outlined, size: 18),
                  label: Text(
                    signedInEmail != null && signedInEmail.isNotEmpty
                        ? '連携中のアカウント（$signedInEmail）を追加'
                        : 'Googleでログインして代表者に追加',
                    style: const TextStyle(
                      fontSize: AppFontSize.small,
                      fontWeight: AppFontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (!isSignedInAlreadyRegistered)
                const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(
                        color: themeColors.textColor,
                        fontSize: AppFontSize.bodySmall,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        hintText: '引き継ぎ先のGmailアドレスを追加',
                        hintStyle: TextStyle(
                          color: themeColors.subTextColor,
                          fontSize: AppFontSize.caption,
                        ),
                        filled: true,
                        fillColor: themeColors.cardBackground,
                        border: const OutlineInputBorder(
                          borderRadius: AppRadius.capsule,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppRadius.capsule,
                          borderSide: BorderSide(
                            color: themeColors.separatorColor,
                          ),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: AppRadius.capsule,
                          borderSide: BorderSide(color: AppKendoColors.teal),
                        ),
                      ),
                      onSubmitted: (_) => _submitManualEmail(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppKendoColors.teal,
                      foregroundColor: AppKendoColors.pureWhite,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      shape: const StadiumBorder(),
                    ),
                    onPressed: _submitManualEmail,
                    child: const Text(
                      '追加',
                      style: TextStyle(
                        fontSize: AppFontSize.small,
                        fontWeight: AppFontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}
