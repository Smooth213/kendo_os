import 'package:flutter/material.dart';

/// kendo OS デザインシステムにおける統一型半径 (BorderRadius) トークン
class AppRadius {
  AppRadius._();

  static const double microValue = 2.0;
  static const double tinyValue = 4.0;
  static const double subValue = 6.0;
  static const double smallValue = 8.0;
  static const double mediumValue = 12.0;
  static const double largeValue = 16.0;
  static const double roundValue = 20.0;
  static const double xlargeValue = 24.0;
  static const double fullValue = 999.0;

  static const BorderRadius micro = BorderRadius.all(
    Radius.circular(microValue),
  );
  static const BorderRadius tiny = BorderRadius.all(Radius.circular(tinyValue));
  static const BorderRadius sub = BorderRadius.all(Radius.circular(subValue));
  static const BorderRadius small = BorderRadius.all(
    Radius.circular(smallValue),
  );
  static const BorderRadius medium = BorderRadius.all(
    Radius.circular(mediumValue),
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
  static const BorderRadius full = BorderRadius.all(Radius.circular(fullValue));
}

/// kendo OS デザインシステムにおける統一余白 (Spacing) トークン
class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
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
  static const double display = 24.0;
  static const double hero = 28.0;
  static const double jumbo = 32.0;
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
