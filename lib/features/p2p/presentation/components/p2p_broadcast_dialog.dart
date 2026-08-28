import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/p2p/infrastructure/local_p2p_broadcaster.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';

/// 【Phase 5: 観戦共有】P2Pローカル配信 ＆ クラウドWebビュアー接続QRダイアログ
class P2pBroadcastDialog extends ConsumerStatefulWidget {
  final MatchModel match;

  const P2pBroadcastDialog({super.key, required this.match});

  static Future<void> show(BuildContext context, {required MatchModel match}) {
    return showAppDialog(
      context: context,
      builder: (_) => P2pBroadcastDialog(match: match),
    );
  }

  @override
  ConsumerState<P2pBroadcastDialog> createState() => _P2pBroadcastDialogState();
}

class _P2pBroadcastDialogState extends ConsumerState<P2pBroadcastDialog> {
  String? _serverUrl;
  bool _isLoading = true;
  bool _isLocalP2p = false;

  @override
  void initState() {
    super.initState();
    _initBroadcastUrl();
  }

  Future<void> _initBroadcastUrl() async {
    if (kIsWeb) {
      _fallbackToCloudUrl();
      return;
    }

    try {
      final broadcaster = ref.read(localP2pBroadcasterProvider);
      final url = await broadcaster.startServer();
      if (mounted) {
        if (url != null && url.isNotEmpty) {
          setState(() {
            _serverUrl = url;
            _isLocalP2p = true;
            _isLoading = false;
          });
          broadcaster.broadcastMatch(widget.match);
        } else {
          _fallbackToCloudUrl();
        }
      }
    } catch (_) {
      if (mounted) {
        _fallbackToCloudUrl();
      }
    }
  }

  void _fallbackToCloudUrl() {
    final dojoId = ref.read(currentDojoIdProvider);
    final cloudUrl =
        'https://kendo-os-beta.web.app/viewer/${widget.match.id}?dojoId=$dojoId';
    setState(() {
      _serverUrl = cloudUrl;
      _isLocalP2p = false;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final broadcaster = ref.watch(localP2pBroadcasterProvider);

    return AppDialog(
      title: _isLocalP2p ? '📶 圏外対応 P2Pローカル配信' : '🌐 リアルタイム観戦QRコード',
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: _isLocalP2p
                    ? const Color(0xFF34C759).withValues(alpha: 0.15)
                    : context.appColors.primaryAccent.withValues(alpha: 0.15),
                borderRadius: AppRadius.small,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isLocalP2p ? Icons.wifi : Icons.cloud_done,
                    color: _isLocalP2p
                        ? const Color(0xFF34C759)
                        : context.appColors.primaryAccent,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    _isLocalP2p ? '完全無料・オフライン対応 (0遅延)' : 'Webリアルタイム同期 (アプリ不要)',
                    style: TextStyle(
                      fontSize: AppFontSize.caption,
                      fontWeight: AppFontWeight.bold,
                      color: _isLocalP2p
                          ? (isDark
                                ? const Color(0xFF34C759)
                                : const Color(0xFF248A3D))
                          : context.appColors.primaryAccent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _isLocalP2p
                  ? '同じWi-Fi（またはテザリング）に繋いだスマホの標準カメラでQRを読み取ると、ブラウザから観戦できます。'
                  : 'スマホの標準カメラでQRコードを読み取ると、アプリ不要でブラウザからリアルタイム観戦できます。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppFontSize.bodySmall,
                color: context.appColors.subTextColor,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: CircularProgressIndicator(),
              )
            else if (_serverUrl != null) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppKendoColors.pureWhite,
                  borderRadius: AppRadius.medium,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF000000).withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: _serverUrl!,
                  version: QrVersions.auto,
                  size: 180,
                  backgroundColor: AppKendoColors.pureWhite,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                _serverUrl!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Courier',
                  fontWeight: AppFontWeight.bold,
                  fontSize: AppFontSize.caption,
                ),
              ),
              if (_isLocalP2p) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '接続中の端末: ${broadcaster.clientCount} 台',
                  style: TextStyle(
                    fontSize: AppFontSize.caption,
                    fontWeight: AppFontWeight.bold,
                    color: context.appColors.primaryAccent,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: context.appColors.primaryAccent,
            foregroundColor: AppKendoColors.pureWhite,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
          ),
          child: const Text('閉じる'),
        ),
      ],
    );
  }
}
