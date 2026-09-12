import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/security/pin_guard.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/presentation/providers/auth_session_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:kendo_os/shared/widgets/liquid_background.dart';

/// 🥋 ロール別PIN認証画面（セキュア認証ゲート）
/// ライフサイクル不整合・脱出不能バグを根本排除した完全堅牢設計
class PinAuthScreen extends ConsumerStatefulWidget {
  final UserRole role;
  const PinAuthScreen({super.key, required this.role});

  @override
  ConsumerState<PinAuthScreen> createState() => _PinAuthScreenState();
}

class _PinAuthScreenState extends ConsumerState<PinAuthScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {});
    // 4桁入力完了時に自動で照合を試行
    if (_controller.text.length == 4 && !_isSubmitting) {
      _handleVerify();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// 画面脱出（戻る）処理：スタック有無に関わらず100%安全に権限選択画面へ復帰
  void _handleBack() {
    AppHaptics.light();
    if (Navigator.of(context).canPop()) {
      context.pop();
    } else {
      context.go('/role-select');
    }
  }

  /// テンキーからの1文字入力
  void _handleKeypadInput(String char) {
    if (_isSubmitting) return;
    if (_controller.text.length < 4) {
      AppHaptics.selection();
      _controller.text += char;
    }
  }

  /// テンキーからの1文字削除
  void _handleKeypadBackspace() {
    if (_isSubmitting) return;
    if (_controller.text.isNotEmpty) {
      AppHaptics.selection();
      _controller.text = _controller.text.substring(
        0,
        _controller.text.length - 1,
      );
    }
  }

  /// テンキーからの全消去
  void _handleKeypadClear() {
    if (_isSubmitting) return;
    AppHaptics.selection();
    _controller.clear();
  }

  /// PIN照合処理
  Future<void> _handleVerify() async {
    if (_isSubmitting) return;
    final pin = _controller.text.trim();
    if (pin.isEmpty) {
      AppSnackBar.showError(context, 'PINコードを入力してください');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      if (PinGuard.validate(widget.role, pin)) {
        AppHaptics.success();
        await ref
            .read(authSessionProvider.notifier)
            .establishSession(widget.role, ref.read(currentDojoIdProvider));
        if (mounted) {
          context.go('/');
        }
      } else {
        AppHaptics.error();
        if (mounted) {
          AppSnackBar.showError(context, '🔒 PINコードが一致しません。認証を拒絶しました。');
          _controller.clear();
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark
        ? const Color(0xFF1C1C1E).withValues(alpha: 0.85)
        : const Color(0xFFFFFFFF).withValues(alpha: 0.90);

    final textColor = context.appColors.textColor;
    final subTextColor = context.appColors.subTextColor;

    Color roleColor;
    String roleTitle;
    switch (widget.role) {
      case UserRole.admin:
        roleColor = AppKendoColors.purple;
        roleTitle = '代表・管理者 (Admin)';
        break;
      case UserRole.operator:
        roleColor = AppKendoColors.teal;
        roleTitle = '監督・引率責任者 (Operator)';
        break;
      case UserRole.recorder:
        roleColor = AppKendoColors.indigo;
        roleTitle = 'スコア・記録係 (Recorder)';
        break;
      default:
        roleColor = AppKendoColors.blueGrey;
        roleTitle = '応援・保護者・選手 (Viewer)';
    }

    final pinLength = _controller.text.length;

    return LiquidBackground(
      child: Scaffold(
        backgroundColor: AppKendoColors.transparent,
        appBar: AppHeader(
          backgroundColor: AppKendoColors.transparent,
          title: 'PINコード認証',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            color: textColor,
            tooltip: '利用権限選択へ戻る',
            onPressed: _handleBack,
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                decoration: BoxDecoration(
                  borderRadius: AppRadius.huge,
                  boxShadow: [
                    BoxShadow(
                      color: AppKendoColors.pureBlack.withValues(
                        alpha: isDark ? 0.35 : 0.08,
                      ),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: AppRadius.huge,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xl,
                        horizontal: AppSpacing.lg,
                      ),
                      decoration: BoxDecoration(
                        color: cardBgColor,
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFFFFFFFF).withValues(alpha: 0.15)
                              : const Color(0xFFFFFFFF).withValues(alpha: 0.8),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: roleColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.lock_outline,
                              size: 36,
                              color: roleColor,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            roleTitle,
                            style: TextStyle(
                              fontSize: AppFontSize.headline,
                              fontWeight: AppFontWeight.bold,
                              color: textColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '指定のPINコード（4桁）を入力してください',
                            style: TextStyle(
                              color: subTextColor,
                              fontSize: AppFontSize.caption,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // 4桁PIN インジケーター
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(4, (index) {
                              final isFilled = index < pinLength;
                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                ),
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isFilled
                                      ? roleColor
                                      : subTextColor.withValues(alpha: 0.25),
                                  border: Border.all(
                                    color: isFilled
                                        ? roleColor
                                        : subTextColor.withValues(alpha: 0.4),
                                    width: 2,
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // オンスクリーン・テンキー
                          _buildKeypad(isDark, textColor),
                          const SizedBox(height: AppSpacing.lg),

                          // 認証ボタン
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: roleColor,
                                foregroundColor: AppKendoColors.pureWhite,
                                elevation: 0,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: AppRadius.large,
                                ),
                              ),
                              onPressed: _isSubmitting ? null : _handleVerify,
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: AppKendoColors.pureWhite,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Text(
                                      '認証して進入',
                                      style: TextStyle(
                                        fontWeight: AppFontWeight.bold,
                                        fontSize: AppFontSize.body,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),

                          // 明示的な「権限選択に戻る」リンク
                          TextButton(
                            onPressed: _handleBack,
                            child: Text(
                              '別の利用権限を選択する',
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: AppFontSize.caption,
                                fontWeight: AppFontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 洗練されたガラス調のオンスクリーン・テンキー
  Widget _buildKeypad(bool isDark, Color textColor) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildKeypadButton('1', isDark, textColor),
            _buildKeypadButton('2', isDark, textColor),
            _buildKeypadButton('3', isDark, textColor),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildKeypadButton('4', isDark, textColor),
            _buildKeypadButton('5', isDark, textColor),
            _buildKeypadButton('6', isDark, textColor),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildKeypadButton('7', isDark, textColor),
            _buildKeypadButton('8', isDark, textColor),
            _buildKeypadButton('9', isDark, textColor),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildKeypadAction('クリア', isDark, textColor, _handleKeypadClear),
            _buildKeypadButton('0', isDark, textColor),
            _buildKeypadAction('⌫', isDark, textColor, _handleKeypadBackspace),
          ],
        ),
      ],
    );
  }

  Widget _buildKeypadButton(String digit, bool isDark, Color textColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      width: 64,
      height: 52,
      child: Material(
        color: context.appColors.textColor.withValues(alpha: 0.08),
        borderRadius: AppRadius.medium,
        child: InkWell(
          onTap: () => _handleKeypadInput(digit),
          borderRadius: AppRadius.medium,
          child: Center(
            child: Text(
              digit,
              style: TextStyle(
                fontSize: AppFontSize.headline,
                fontWeight: AppFontWeight.bold,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadAction(
    String label,
    bool isDark,
    Color textColor,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      width: 64,
      height: 52,
      child: Material(
        color: context.appColors.textColor.withValues(alpha: 0.04),
        borderRadius: AppRadius.medium,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.medium,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: label == '⌫'
                    ? AppFontSize.headline
                    : AppFontSize.caption,
                fontWeight: AppFontWeight.bold,
                color: textColor.withValues(alpha: 0.8),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
