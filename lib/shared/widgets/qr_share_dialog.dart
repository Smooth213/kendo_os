import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/security/viewer_share_models.dart';
import 'package:kendo_os/security/viewer_share_repository.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/presentation/providers/auth_session_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_user_role_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';
import 'package:kendo_os/shared/widgets/viewer_share_expiry_selector.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

/// 🥋 統一QRコード共有ダイアログ
///
/// アプリ内のすべてのQRコード表示ダイアログ（大会観戦リンク、部内戦観戦リンク、Webアプリリンク等）で
/// 一貫したプレミアムなデザインと使い心地を提供します。
class QrShareDialog extends StatefulWidget {
  final String title;
  final IconData titleIcon;
  final Color themeColor;
  final String description;
  final String shareUrl;
  final String shareText;
  final String? shareSubject;
  final String? subtitleBadge;
  final String shareButtonLabel;
  final String copySuccessMessage;
  final VoidCallback? onClose;
  final String? shareDojoId;
  final String? shareTournamentId;

  const QrShareDialog({
    super.key,
    required this.title,
    this.titleIcon = Icons.qr_code_2_rounded,
    this.themeColor = AppKendoColors.teal,
    required this.description,
    required this.shareUrl,
    required this.shareText,
    this.shareSubject,
    this.subtitleBadge,
    this.shareButtonLabel = 'LINEやSNSでURLを送る',
    this.copySuccessMessage = 'URLをクリップボードにコピーしました',
    this.onClose,
    this.shareDojoId,
    this.shareTournamentId,
  });

  static void show(
    BuildContext context, {
    required String title,
    IconData titleIcon = Icons.qr_code_2_rounded,
    Color themeColor = AppKendoColors.teal,
    required String description,
    required String shareUrl,
    required String shareText,
    String? shareSubject,
    String? subtitleBadge,
    String shareButtonLabel = 'LINEやSNSでURLを送る',
    String copySuccessMessage = 'URLをクリップボードにコピーしました',
    VoidCallback? onClose,
    String? shareDojoId,
    String? shareTournamentId,
  }) {
    showAppDialog(
      context: context,
      builder: (ctx) => QrShareDialog(
        title: title,
        titleIcon: titleIcon,
        themeColor: themeColor,
        description: description,
        shareUrl: shareUrl,
        shareText: shareText,
        shareSubject: shareSubject,
        subtitleBadge: subtitleBadge,
        shareButtonLabel: shareButtonLabel,
        copySuccessMessage: copySuccessMessage,
        onClose: onClose,
        shareDojoId: shareDojoId,
        shareTournamentId: shareTournamentId,
      ),
    );
  }

  @override
  State<QrShareDialog> createState() => _QrShareDialogState();
}

class _QrShareDialogState extends State<QrShareDialog> {
  bool _initialized = false;
  bool _showExpiryControls = false;
  bool _isUpdatingShare = false;
  ViewerShareExpiryPreset _preset = ViewerShareExpiryPreset.days7;
  DateTime? _expiresAt;
  String? _activeToken;
  ViewerShareRepository? _shareRepo;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _initShareTokenContext();
  }

  void _initShareTokenContext() {
    final dojoId = widget.shareDojoId;
    final tournamentId = widget.shareTournamentId;
    if (dojoId == null ||
        dojoId.isEmpty ||
        dojoId == 'default_dojo_room' ||
        dojoId == 'default_org' ||
        tournamentId == null ||
        tournamentId.isEmpty) {
      return;
    }

    try {
      final container = ProviderScope.containerOf(context, listen: false);
      final role = container.read(currentUserRoleProvider);
      final session = container.read(authSessionProvider);
      final repo = container.read(viewerShareRepositoryProvider);

      if (session != null &&
          session.isShareScoped &&
          session.sharedTournamentId == tournamentId &&
          session.shareToken != null) {
        _activeToken = session.shareToken;
        return;
      }

      if (repo != null && role != UserRole.viewer) {
        _shareRepo = repo;
        _showExpiryControls = true;
        _loadOrIssueShareLink(
          repo: repo,
          dojoId: dojoId,
          tournamentId: tournamentId,
        );
      }
    } catch (_) {}
  }

  Future<void> _loadOrIssueShareLink({
    required ViewerShareRepository repo,
    required String dojoId,
    required String tournamentId,
  }) async {
    setState(() => _isUpdatingShare = true);
    try {
      final existing = await repo.getTournamentShareMeta(
        dojoId: dojoId,
        tournamentId: tournamentId,
      );
      if (!mounted) return;
      if (existing != null) {
        setState(() {
          _activeToken = existing.token;
          _preset = existing.preset;
          _expiresAt = existing.expiresAt;
          _isUpdatingShare = false;
        });
        return;
      }
      final uid = Firebase.apps.isNotEmpty
          ? (FirebaseAuth.instance.currentUser?.uid ?? 'staff_terminal')
          : 'staff_terminal';
      final created = await repo.saveTournamentShareLink(
        dojoId: dojoId,
        tournamentId: tournamentId,
        preset: ViewerShareExpiryPreset.days7,
        uid: uid,
      );
      if (!mounted) return;
      setState(() {
        _activeToken = created.token;
        _preset = created.preset;
        _expiresAt = created.expiresAt;
        _isUpdatingShare = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isUpdatingShare = false);
    }
  }

  Future<void> _updatePreset(ViewerShareExpiryPreset nextPreset) async {
    final repo = _shareRepo;
    final dojoId = widget.shareDojoId;
    final tournamentId = widget.shareTournamentId;
    if (repo == null || dojoId == null || tournamentId == null) return;

    setState(() => _isUpdatingShare = true);
    try {
      final uid = Firebase.apps.isNotEmpty
          ? (FirebaseAuth.instance.currentUser?.uid ?? 'staff_terminal')
          : 'staff_terminal';
      final updated = await repo.saveTournamentShareLink(
        dojoId: dojoId,
        tournamentId: tournamentId,
        preset: nextPreset,
        existingToken: _activeToken,
        uid: uid,
      );
      if (!mounted) return;
      setState(() {
        _activeToken = updated.token;
        _preset = updated.preset;
        _expiresAt = updated.expiresAt;
        _isUpdatingShare = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isUpdatingShare = false);
        AppSnackBar.showError(context, '有効期限の更新に失敗しました: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
    final effectiveShareUrl = ViewerShareUrlHelper.attachToken(
      widget.shareUrl,
      _activeToken,
    );
    final effectiveShareText = ViewerShareUrlHelper.replaceUrlInText(
      widget.shareText,
      widget.shareUrl,
      effectiveShareUrl,
    );

    return AppDialog(
      title: widget.title,
      titleIcon: widget.titleIcon,
      iconColor: widget.themeColor,
      content: SizedBox(
        width: 320,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 説明テキスト
              Text(
                widget.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppFontSize.bodySmall,
                  color: themeColors.subTextColor,
                  height: 1.4,
                ),
              ),
              if (_showExpiryControls) ...[
                const SizedBox(height: AppSpacing.md),
                ViewerShareExpirySelector(
                  selectedPreset: _preset,
                  expiresAt: _expiresAt,
                  isUpdating: _isUpdatingShare,
                  onPresetSelected: _updatePreset,
                ),
              ],
              const SizedBox(height: AppSpacing.md),

              // QRコードカード
              Center(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppKendoColors.pureWhite,
                    borderRadius: AppRadius.large,
                    boxShadow: [
                      BoxShadow(
                        color: AppKendoColors.pureBlack.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      QrImageView(
                        data: effectiveShareUrl,
                        version: QrVersions.auto,
                        size: 180.0,
                        backgroundColor: AppKendoColors.pureWhite,
                      ),
                      if (widget.subtitleBadge != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          widget.subtitleBadge!,
                          style: const TextStyle(
                            fontSize: AppFontSize.badge,
                            color: AppKendoColors.grey,
                            fontWeight: AppFontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // URL表示 ＆ コピーフィールド
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: themeColors.inputBackground,
                  borderRadius: AppSemanticTokens.inputRadius,
                  border: Border.all(
                    color: themeColors.separatorColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.link, size: 18, color: widget.themeColor),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: SelectableText(
                        effectiveShareUrl,
                        style: TextStyle(
                          fontSize: AppFontSize.bodySmall,
                          fontWeight: AppFontWeight.semiBold,
                          color: themeColors.textColor,
                        ),
                        maxLines: 1,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      tooltip: 'URLをコピー',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      onPressed: () async {
                        AppHaptics.success();
                        await Clipboard.setData(
                          ClipboardData(text: effectiveShareUrl),
                        );
                        if (context.mounted) {
                          AppSnackBar.showSuccess(
                            context,
                            widget.copySuccessMessage,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // シェアボタン
              ElevatedButton.icon(
                onPressed: () {
                  AppHaptics.medium();
                  SharePlus.instance.share(
                    ShareParams(
                      text: effectiveShareText,
                      subject: widget.shareSubject,
                    ),
                  );
                },
                icon: const Icon(
                  Icons.ios_share,
                  size: 18,
                  color: AppKendoColors.pureWhite,
                ),
                label: Text(
                  widget.shareButtonLabel,
                  style: const TextStyle(
                    fontWeight: AppFontWeight.bold,
                    color: AppKendoColors.pureWhite,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.themeColor,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.onClose ?? () => Navigator.pop(context),
          child: const Text('閉じる'),
        ),
      ],
    );
  }
}
