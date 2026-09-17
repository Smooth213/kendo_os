import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';

/// 🥋 計算機シート用洗練されたアコーディオン展開カード
class MatchCalculatorAccordionCard extends StatefulWidget {
  final IconData? icon;
  final Widget? leadingIcon;
  final String title;
  final String? badgeText;
  final Widget child;
  final bool initiallyExpanded;

  const MatchCalculatorAccordionCard({
    super.key,
    this.icon,
    this.leadingIcon,
    required this.title,
    this.badgeText,
    required this.child,
    this.initiallyExpanded = false,
  });

  @override
  State<MatchCalculatorAccordionCard> createState() =>
      _MatchCalculatorAccordionCardState();
}

class _MatchCalculatorAccordionCardState
    extends State<MatchCalculatorAccordionCard>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 220),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );

    if (_isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    AppHaptics.selection();
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'bunaiksen');

    final primaryAccent = themeColors.primaryAccent;

    return Container(
      decoration: BoxDecoration(
        color: themeColors.surface,
        borderRadius: AppRadius.medium,
        border: Border.all(
          color: _isExpanded
              ? primaryAccent.withValues(alpha: 0.35)
              : themeColors.subTextColor.withValues(alpha: 0.15),
          width: _isExpanded ? 1.2 : 1.0,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ヘッダー（タップで開閉）
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggleExpand,
              borderRadius: AppRadius.medium,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm + 2,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xxs + 2),
                      decoration: BoxDecoration(
                        color: primaryAccent.withValues(
                          alpha: _isExpanded ? 0.18 : 0.08,
                        ),
                        borderRadius: AppRadius.small,
                      ),
                      child:
                          widget.leadingIcon ??
                          (widget.icon != null
                              ? Icon(
                                  widget.icon,
                                  size: 16,
                                  color: primaryAccent,
                                )
                              : const SizedBox.shrink()),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: AppFontSize.bodySmall,
                              fontWeight: AppFontWeight.bold,
                              color: themeColors.textColor,
                            ),
                          ),
                          if (widget.badgeText != null &&
                              widget.badgeText!.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.xxs),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xs + 2,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: primaryAccent.withValues(
                                  alpha: _isExpanded ? 0.2 : 0.1,
                                ),
                                borderRadius: AppRadius.capsule,
                                border: Border.all(
                                  color: primaryAccent.withValues(alpha: 0.25),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                widget.badgeText!,
                                style: TextStyle(
                                  fontSize: AppFontSize.caption - 1,
                                  fontWeight: AppFontWeight.bold,
                                  color: primaryAccent,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    RotationTransition(
                      turns: _rotateAnimation,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: themeColors.subTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // コンテンツ部分
          SizeTransition(
            sizeFactor: _expandAnimation,
            alignment: Alignment.topCenter,
            child: Column(
              children: [
                Divider(
                  height: 1,
                  thickness: 1,
                  color: themeColors.subTextColor.withValues(alpha: 0.1),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: widget.child,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
