import 'package:flutter/material.dart';
import 'package:kendo_os/security/pwa_storage_bridge.dart';
import 'package:kendo_os/security/session_storage.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

/// 🛡️ 【Plan 3-3】不壊セーフティネット作動時のフェイルセーフ描画ビュー
/// クラッシュ時のデータ保護アナウンスと、ワンタップでの安全な復旧導線を提供する。
class SafetyNetErrorView extends StatelessWidget {
  final FlutterErrorDetails details;

  const SafetyNetErrorView({super.key, required this.details});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppKendoColors.pureBlack,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppKendoColors.pureBlack,
                borderRadius: AppRadius.large,
                border: Border.all(
                  color: AppKendoColors.ipponGold.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.shield,
                        color: AppKendoColors.ipponGold,
                        size: 28,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const Expanded(
                        child: Text(
                          '🛡️ KendoOS 不壊セーフティネット作動',
                          style: TextStyle(
                            color: AppKendoColors.pureWhite,
                            fontWeight: AppFontWeight.bold,
                            fontSize: AppFontSize.headline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    '試合データは自動退避・保護されました。クラッシュによるデータ消失は発生していません。',
                    style: TextStyle(
                      color: AppKendoColors.pureWhite,
                      fontSize: AppFontSize.body,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    details.exceptionAsString(),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppKendoColors.pureWhite.withValues(alpha: 0.6),
                      fontSize: AppFontSize.small,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            PwaStorage.reload();
                          },
                          icon: const Icon(
                            Icons.refresh,
                            size: 18,
                            color: AppKendoColors.ipponGold,
                          ),
                          label: const Text(
                            '再読み込み',
                            style: TextStyle(
                              color: AppKendoColors.pureWhite,
                              fontWeight: AppFontWeight.bold,
                              fontSize: AppFontSize.bodySmall,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: AppKendoColors.ipponGold.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            try {
                              SessionStorage.clear();
                            } catch (_) {}
                            PwaStorage.reload();
                          },
                          icon: const Icon(
                            Icons.restart_alt,
                            size: 18,
                            color: AppKendoColors.pureBlack,
                          ),
                          label: const Text(
                            'リセット復旧',
                            style: TextStyle(
                              color: AppKendoColors.pureBlack,
                              fontWeight: AppFontWeight.bold,
                              fontSize: AppFontSize.bodySmall,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppKendoColors.ipponGold,
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
