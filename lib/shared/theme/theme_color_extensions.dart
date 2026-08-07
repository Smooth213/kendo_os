import 'package:flutter/material.dart';

class AppThemeColors extends ThemeExtension<AppThemeColors> {
  final Color primaryAccent;
  final Color softAccent;
  final Color cardBackground;
  final Color scaffoldBackground;
  final Color textColor;
  final Color subTextColor;
  final Color separatorColor;
  final Color inputBackground;
  final Color hintColor;
  final Color rosePink; // 差し色としてのローズピンク
  final Color successColor; // 成功状態カラー
  final Color warningColor; // 警告状態カラー
  final Color errorColor; // エラー状態カラー
  final Color infoColor; // 情報状態カラー

  const AppThemeColors({
    required this.primaryAccent,
    required this.softAccent,
    required this.cardBackground,
    required this.scaffoldBackground,
    required this.textColor,
    required this.subTextColor,
    required this.separatorColor,
    required this.inputBackground,
    required this.hintColor,
    required this.rosePink,
    required this.successColor,
    required this.warningColor,
    required this.errorColor,
    required this.infoColor,
  });

  @override
  AppThemeColors copyWith({
    Color? primaryAccent,
    Color? softAccent,
    Color? cardBackground,
    Color? scaffoldBackground,
    Color? textColor,
    Color? subTextColor,
    Color? separatorColor,
    Color? inputBackground,
    Color? hintColor,
    Color? rosePink,
    Color? successColor,
    Color? warningColor,
    Color? errorColor,
    Color? infoColor,
  }) {
    return AppThemeColors(
      primaryAccent: primaryAccent ?? this.primaryAccent,
      softAccent: softAccent ?? this.softAccent,
      cardBackground: cardBackground ?? this.cardBackground,
      scaffoldBackground: scaffoldBackground ?? this.scaffoldBackground,
      textColor: textColor ?? this.textColor,
      subTextColor: subTextColor ?? this.subTextColor,
      separatorColor: separatorColor ?? this.separatorColor,
      inputBackground: inputBackground ?? this.inputBackground,
      hintColor: hintColor ?? this.hintColor,
      rosePink: rosePink ?? this.rosePink,
      successColor: successColor ?? this.successColor,
      warningColor: warningColor ?? this.warningColor,
      errorColor: errorColor ?? this.errorColor,
      infoColor: infoColor ?? this.infoColor,
    );
  }

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) {
      return this;
    }
    return AppThemeColors(
      primaryAccent: Color.lerp(primaryAccent, other.primaryAccent, t)!,
      softAccent: Color.lerp(softAccent, other.softAccent, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      scaffoldBackground: Color.lerp(
        scaffoldBackground,
        other.scaffoldBackground,
        t,
      )!,
      textColor: Color.lerp(textColor, other.textColor, t)!,
      subTextColor: Color.lerp(subTextColor, other.subTextColor, t)!,
      separatorColor: Color.lerp(separatorColor, other.separatorColor, t)!,
      inputBackground: Color.lerp(inputBackground, other.inputBackground, t)!,
      hintColor: Color.lerp(hintColor, other.hintColor, t)!,
      rosePink: Color.lerp(rosePink, other.rosePink, t)!,
      successColor: Color.lerp(successColor, other.successColor, t)!,
      warningColor: Color.lerp(warningColor, other.warningColor, t)!,
      errorColor: Color.lerp(errorColor, other.errorColor, t)!,
      infoColor: Color.lerp(infoColor, other.infoColor, t)!,
    );
  }

  // ファクトリメソッド群：通常大会、部内戦、観戦用テーマを解決
  static AppThemeColors ofMode({
    required bool isDark,
    required String
    mode, // 'normal', 'bunaiksen', 'normal_viewer', 'bunaiksen_viewer'
  }) {
    final Color rosePink = const Color(0xFFE06287);

    // 1. 各モードごとのベース色を設定
    final Color primaryAccent;
    final Color softAccent;

    if (mode == 'bunaiksen') {
      primaryAccent = isDark
          ? Colors.deepPurple.shade300
          : Colors.deepPurple.shade700;
      softAccent = isDark
          ? Colors.deepPurple.withValues(alpha: 0.15)
          : Colors.deepPurple.shade50;
    } else if (mode == 'normal_viewer') {
      primaryAccent = isDark
          ? Colors.blueGrey.shade400
          : Colors.blueGrey.shade700;
      softAccent = isDark
          ? Colors.blueGrey.withValues(alpha: 0.15)
          : Colors.blueGrey.shade50;
    } else if (mode == 'bunaiksen_viewer') {
      // ラベンダー・藤色系 (Colors.purple)
      primaryAccent = isDark ? Colors.purple.shade300 : Colors.purple.shade700;
      softAccent = isDark
          ? Colors.purple.withValues(alpha: 0.15)
          : Colors.purple.shade50;
    } else {
      // normal: Indigo
      primaryAccent = isDark ? Colors.indigo.shade400 : Colors.indigo.shade700;
      softAccent = isDark
          ? Colors.indigo.withValues(alpha: 0.15)
          : Colors.indigo.shade50;
    }

    // 2. ライト/ダーク共通・標準のUIカラー
    final Color cardBackground = isDark
        ? const Color(0xFF1C1C1E)
        : Colors.white;
    final Color scaffoldBackground = isDark
        ? Colors.black
        : const Color(0xFFF2F2F7);
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color subTextColor = isDark
        ? const Color(0xFF8E8E93)
        : const Color(0xFF636366);
    final Color separatorColor = isDark
        ? const Color(0xFF38383A)
        : const Color(0xFFC6C6C8);
    final Color inputBackground = isDark
        ? const Color(0xFF2C2C2E)
        : Colors.grey.shade100;
    final Color hintColor = isDark
        ? const Color(0xFF8E8E93)
        : Colors.grey.shade600;

    // 3. セマンティックステータスカラー
    final Color successColor = isDark
        ? Colors.green.shade400
        : Colors.green.shade700;
    final Color warningColor = isDark
        ? Colors.orange.shade400
        : Colors.orange.shade800;
    final Color errorColor = isDark ? Colors.red.shade400 : Colors.red.shade700;
    final Color infoColor = isDark
        ? Colors.blue.shade400
        : Colors.blue.shade700;

    return AppThemeColors(
      primaryAccent: primaryAccent,
      softAccent: softAccent,
      cardBackground: cardBackground,
      scaffoldBackground: scaffoldBackground,
      textColor: textColor,
      subTextColor: subTextColor,
      separatorColor: separatorColor,
      inputBackground: inputBackground,
      hintColor: hintColor,
      rosePink: rosePink,
      successColor: successColor,
      warningColor: warningColor,
      errorColor: errorColor,
      infoColor: infoColor,
    );
  }
}

class AppThemeModeWrapper extends StatelessWidget {
  final String mode;
  final Widget child;

  const AppThemeModeWrapper({
    super.key,
    required this.mode,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Theme(
      data: Theme.of(context).copyWith(
        extensions: [AppThemeColors.ofMode(isDark: isDark, mode: mode)],
      ),
      child: child,
    );
  }
}

/// BuildContext 経由で AppThemeColors へ即座にアクセスできる便利な拡張
extension AppContextThemeX on BuildContext {
  AppThemeColors get appColors =>
      Theme.of(this).extension<AppThemeColors>() ??
      AppThemeColors.ofMode(
        isDark: Theme.of(this).brightness == Brightness.dark,
        mode: 'normal',
      );
}
