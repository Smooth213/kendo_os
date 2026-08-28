import 'package:flutter/cupertino.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// kendo OS 全体で統一された iOS スタイルのローディングインジケータ
class AppLoadingIndicator extends StatelessWidget {
  final double radius;
  final Color? color;

  const AppLoadingIndicator({super.key, this.radius = 10.0, this.color});

  /// 小サイズ (iOS ナビゲーションバーやボタン内用)
  const AppLoadingIndicator.small({super.key, this.radius = 8.0, this.color});

  /// 大サイズ (フルスクリーン読み込み用)
  const AppLoadingIndicator.large({super.key, this.radius = 14.0, this.color});

  @override
  Widget build(BuildContext context) {
    final themeColors = context.appColors;
    final effectiveColor = color ?? themeColors.primaryAccent;

    return CupertinoActivityIndicator(radius: radius, color: effectiveColor);
  }
}
