import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// kendo OS デザインシステムにおける iOS 27 超薄層フロストガラスコンテナ (Facade Widget)
///
/// 特徴:
/// 1. [RepaintBoundary] による描画隔離（第303条/第402条 発熱・Jank完全防止）
/// 2. [settingsProvider] の `enableLiquidGlass` および [isEcoModeProvider] との自動連動
///    - ON時: Frosted Glass (透過率78% + ガウスぼかし + 0.5pxヘアライン境界)
///    - OFF時/エコモード時: Solid High-Contrast (不透明ソリッド + 描画負荷ゼロ・炎天下視認性保証)
/// 3. テスト完全耐性: [ProviderScope] が存在しない単体Widgetテストでも安全にフォールバック動作
class AppGlassContainer extends StatelessWidget {
  final Widget child;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final double blur;
  final double borderWidth;
  final Color? color;
  final Color? customBackgroundColor;
  final Color? customBorderColor;
  final BoxBorder? border;
  final List<BoxShadow>? customShadows;
  final Clip clipBehavior;
  final bool? enableLiquidGlass;

  const AppGlassContainer({
    super.key,
    required this.child,
    this.borderRadius,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.blur = AppSemanticTokens.cardBlur,
    this.borderWidth = AppSemanticTokens.cardBorderWidth,
    this.color,
    this.customBackgroundColor,
    this.customBorderColor,
    this.border,
    this.customShadows,
    this.clipBehavior = Clip.antiAlias,
    this.enableLiquidGlass,
  });

  bool _resolveGlassActive(BuildContext context) {
    if (enableLiquidGlass != null) {
      return enableLiquidGlass!;
    }
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      final isEnabled = container.read(settingsProvider).enableLiquidGlass;
      final isEco = container.read(isEcoModeProvider);
      return isEnabled && !isEco;
    } catch (_) {
      // ProviderScope が存在しない単体テスト環境では安全に true を返す
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = context.appColors;
    final isGlassActive = _resolveGlassActive(context);
    final effectiveRadius = borderRadius ?? AppSemanticTokens.cardRadius;

    final effectiveBgColor =
        color ??
        customBackgroundColor ??
        (isGlassActive ? themeColors.glassSurface : themeColors.cardBackground);

    final effectiveBorderColor =
        customBorderColor ??
        (isGlassActive ? themeColors.hairlineBorder : themeColors.borderColor);

    final effectiveBorder =
        border ?? Border.all(color: effectiveBorderColor, width: borderWidth);

    final effectiveShadows =
        customShadows ??
        (isGlassActive ? AppShadows.iosAmbient : const <BoxShadow>[]);

    Widget content = Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveBgColor,
        borderRadius: effectiveRadius,
        border: effectiveBorder,
        boxShadow: effectiveShadows,
      ),
      child: child,
    );

    if (isGlassActive && blur > AppBlur.none) {
      content = ClipRRect(
        borderRadius: effectiveRadius,
        clipBehavior: clipBehavior,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: content,
        ),
      );
    }

    // 第303条/第402条: 再描画の波及を防ぎ、発熱・フレーム落ちを防止する境界
    return RepaintBoundary(child: content);
  }
}
