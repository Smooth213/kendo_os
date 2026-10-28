import 'package:flutter/material.dart';

/// kendo OS デザインシステムにおける統一型半径 (BorderRadius) トークン
class AppRadius {
  AppRadius._();

  static const double microValue = 2.0;
  static const double tinyValue = 4.0;
  static const double subValue = 6.0;
  static const double smallValue = 8.0;
  static const double compactValue = 10.0;
  static const double smoothValue = 11.0;
  static const double mediumValue = 12.0;
  static const double modernValue = 14.0;
  static const double largeValue = 16.0;
  static const double roundValue = 20.0;
  static const double xlargeValue = 24.0;
  static const double hugeValue = 28.0;
  static const double giantValue = 32.0;
  static const double fullValue = 999.0;

  static const BorderRadius micro = BorderRadius.all(
    Radius.circular(microValue),
  );
  static const BorderRadius tiny = BorderRadius.all(Radius.circular(tinyValue));
  static const BorderRadius sub = BorderRadius.all(Radius.circular(subValue));
  static const BorderRadius small = BorderRadius.all(
    Radius.circular(smallValue),
  );
  static const BorderRadius compact = BorderRadius.all(
    Radius.circular(compactValue),
  );
  static const BorderRadius smooth = BorderRadius.all(
    Radius.circular(smoothValue),
  );
  static const BorderRadius medium = BorderRadius.all(
    Radius.circular(mediumValue),
  );
  static const BorderRadius modern = BorderRadius.all(
    Radius.circular(modernValue),
  );
  static const BorderRadius large = BorderRadius.all(
    Radius.circular(largeValue),
  );
  static const BorderRadius round = BorderRadius.all(
    Radius.circular(roundValue),
  );
  static const BorderRadius xlarge = BorderRadius.all(
    Radius.circular(xlargeValue),
  );
  static const BorderRadius huge = BorderRadius.all(Radius.circular(hugeValue));
  static const BorderRadius giant = BorderRadius.all(
    Radius.circular(giantValue),
  );
  static const BorderRadius full = BorderRadius.all(Radius.circular(fullValue));
  static const BorderRadius capsule = full;
}

/// kendo OS デザインシステムにおける統一余白 (Spacing) トークン
class AppSpacing {
  AppSpacing._();

  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double subValue = 6.0;
  static const double sm = 8.0;
  static const double nano = 9.0;
  static const double compact = 10.0;
  static const double md = 12.0;
  static const double modernValue = 14.0;
  static const double lg = 16.0;
  static const double mediumLg = 18.0;
  static const double roundValue = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double giant = 40.0;
}

/// kendo OS デザインシステムにおける統一フォントウェイト (FontWeight) トークン
class AppFontWeight {
  AppFontWeight._();

  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight black = FontWeight.w900;
}

/// kendo OS デザインシステムにおける統一フォントサイズ (Font Size) トークン
class AppFontSize {
  AppFontSize._();

  static const double micro = 8.0;
  static const double nano = 9.0;
  static const double badge = 10.0;
  static const double caption = 11.0;
  static const double small = 12.0;
  static const double bodySmall = 13.0;
  static const double body = 14.0;
  static const double bodyMedium = 15.0;
  static const double subhead = 16.0;
  static const double title = 17.0;
  static const double headline = 18.0;
  static const double header = 20.0;
  static const double titleLarge = 22.0;
  static const double display = 24.0;
  static const double heroLarge = 26.0;
  static const double hero = 28.0;
  static const double jumbo = 32.0;
  static const double heroXl = 34.0;
  static const double heroXxl = 36.0;
  static const double scoreboardMedium = 40.0;
  static const double scoreboardLarge = 46.0;
  static const double scoreboardTimer = 48.0;
  static const double scoreboardJumbo = 56.0;
}

/// kendo OS デザインシステムにおける統一パディング (EdgeInsets) トークン
class AppEdgeInsets {
  AppEdgeInsets._();

  static const EdgeInsets zero = EdgeInsets.zero;

  // all
  static const EdgeInsets allXs = EdgeInsets.all(AppSpacing.xs);
  static const EdgeInsets allSm = EdgeInsets.all(AppSpacing.sm);
  static const EdgeInsets allMd = EdgeInsets.all(AppSpacing.md);
  static const EdgeInsets allLg = EdgeInsets.all(AppSpacing.lg);
  static const EdgeInsets allXl = EdgeInsets.all(AppSpacing.xl);
  static const EdgeInsets allXxl = EdgeInsets.all(AppSpacing.xxl);

  // symmetric horizontal
  static const EdgeInsets hXs = EdgeInsets.symmetric(horizontal: AppSpacing.xs);
  static const EdgeInsets hSm = EdgeInsets.symmetric(horizontal: AppSpacing.sm);
  static const EdgeInsets hMd = EdgeInsets.symmetric(horizontal: AppSpacing.md);
  static const EdgeInsets hLg = EdgeInsets.symmetric(horizontal: AppSpacing.lg);
  static const EdgeInsets hXl = EdgeInsets.symmetric(horizontal: AppSpacing.xl);
  static const EdgeInsets hXxl = EdgeInsets.symmetric(
    horizontal: AppSpacing.xxl,
  );

  // symmetric vertical
  static const EdgeInsets vXs = EdgeInsets.symmetric(vertical: AppSpacing.xs);
  static const EdgeInsets vSm = EdgeInsets.symmetric(vertical: AppSpacing.sm);
  static const EdgeInsets vMd = EdgeInsets.symmetric(vertical: AppSpacing.md);
  static const EdgeInsets vLg = EdgeInsets.symmetric(vertical: AppSpacing.lg);
  static const EdgeInsets vXl = EdgeInsets.symmetric(vertical: AppSpacing.xl);
  static const EdgeInsets vXxl = EdgeInsets.symmetric(vertical: AppSpacing.xxl);
}

/// kendo OS デザインシステムにおける統一ブラー (Blur Sigma) トークン (iOS 27 準拠)
class AppBlur {
  AppBlur._();

  static const double none = 0.0;
  static const double ultraThin = 6.0;
  static const double thin = 10.0;
  static const double medium = 16.0;
  static const double thick = 24.0;
  static const double heavy = 32.0;
}

/// kendo OS デザインシステムにおける統一境界線幅 (Border Width) トークン (iOS 27 準拠)
class AppBorderWidth {
  AppBorderWidth._();

  static const double hairline = 0.5; // iOS標準サブピクセルヘアライン
  static const double thin = 1.0;
  static const double normal = 1.5;
  static const double thick = 2.0;
}

/// kendo OS デザインシステムにおける統一ソフトアンビエントシャドウ トークン (iOS 27 準拠)
class AppShadows {
  AppShadows._();

  /// iOS 27 自然光アンビエントシャドウ (カード・リスト用)
  static const List<BoxShadow> iosAmbient = [
    BoxShadow(
      color: Color(0x0A000000), // 極微小な広域環境光
      offset: Offset(0, 2),
      blurRadius: 10,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x0F000000), // 直下の微小シャドウ
      offset: Offset(0, 1),
      blurRadius: 3,
      spreadRadius: 0,
    ),
  ];

  /// iOS 27 浮遊ダイアログ・シート用シャドウ
  static const List<BoxShadow> iosFloating = [
    BoxShadow(
      color: Color(0x14000000),
      offset: Offset(0, 8),
      blurRadius: 24,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x0A000000),
      offset: Offset(0, 2),
      blurRadius: 6,
      spreadRadius: 0,
    ),
  ];

  /// 常設フローティングドック用アイランドシャドウ
  static const List<BoxShadow> iosDock = [
    BoxShadow(
      color: Color(0x1F000000),
      offset: Offset(0, 6),
      blurRadius: 20,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x0D000000),
      offset: Offset(0, 1),
      blurRadius: 4,
      spreadRadius: 0,
    ),
  ];
}

/// kendo OS 次世代着せ替え基盤におけるセマンティック（意味的）トークン層
class AppSemanticTokens {
  AppSemanticTokens._();

  // 形状・角丸 (用途別 - iOS 27 カプセル＆Squircle黄金比)
  static const BorderRadius cardRadius = AppRadius.large;
  static const BorderRadius dialogRadius = AppRadius.round;
  static const BorderRadius sheetRadius = AppRadius.large;
  static const BorderRadius dockRadius = AppRadius.full;
  static const BorderRadius badgeRadius = AppRadius.small;
  static const BorderRadius buttonRadius = AppRadius.full;
  static const BorderRadius inputRadius = AppRadius.full;
  static const BorderRadius multilineInputRadius = AppRadius.large;
  static const OutlinedBorder buttonShape = StadiumBorder();

  // 境界線幅 (用途別)
  static const double cardBorderWidth = AppBorderWidth.hairline;
  static const double dialogBorderWidth = AppBorderWidth.hairline;
  static const double dockBorderWidth = AppBorderWidth.hairline;

  // ブラー度合い (用途別)
  static const double cardBlur = AppBlur.thin;
  static const double headerBlur = AppBlur.medium;
  static const double dockBlur = AppBlur.medium;
  static const double sheetBlur = AppBlur.thick;
}
