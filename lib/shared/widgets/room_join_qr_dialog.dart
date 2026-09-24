import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/security/pwa_storage_bridge.dart';
import 'package:kendo_os/shared/presentation/providers/dojo_room_history_provider.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/room_join_validator.dart';
import 'package:kendo_os/shared/widgets/room_join_qr_dialog_actions.dart';
import 'package:kendo_os/shared/widgets/room_join_duplicate_warning_dialog.dart';

// ★ テスト時にモック（FakeFirestore）を安全に注入するための専用Provider
final roomFirestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

/// 保護者端末や会場配置モニターを、特定の道場同期空間（organizationId）へ
/// 最速かつ迷わせずに直結させるための、QR・手動入力統合シート。
/// （※ 選手マスタ登録シートと同様に、キーボード追従型ボトムシートとして堅牢に稼働）
class RoomJoinQrDialog extends ConsumerStatefulWidget {
  const RoomJoinQrDialog({super.key});

  static void show(BuildContext context) {
    showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      builder: (context) => const RoomJoinQrDialog(),
    );
  }

  @override
  ConsumerState<RoomJoinQrDialog> createState() => _RoomJoinQrDialogState();
}

class _RoomJoinQrDialogState extends ConsumerState<RoomJoinQrDialog> {
  final _codeController = TextEditingController();
  final _focusNode = FocusNode();
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _codeController.value = TextEditingValue(
        text: _codeController.text,
        selection: _codeController.selection,
      );
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// クラウド（Firestore）へパケットを飛ばし、入力されたIDが既に他者に使われているか
  /// 重複を決定論的に水際検知・ガードする非同期チェックロジック
  void _handleJoin(String roomCode) async {
    final cleanCode = RoomJoinValidator.normalize(roomCode);
    final validation = RoomJoinValidator.validate(roomCode);

    if (!validation.isValid) {
      setState(() => _errorMessage = validation.errorMessage);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. 指定されたIDのフォルダ（組織ドキュメント）がFirestore上に実在するか get 照会
      final docSnapshot = await ref
          .read(roomFirestoreProvider)
          .collection('organizations')
          .doc(cleanCode)
          .get();

      // 2. 🌟 重複チェックの執行
      if (docSnapshot.exists) {
        // 既にドキュメントが存在する場合 ➔ 現場でデータ汚染を起こさないための警告ダイアログを発火
        if (mounted) {
          _showDuplicateWarningDialog(context, cleanCode);
        }
        return;
      }

      // 3. 重複していなければ、完全新規の綺麗な道場ルームとして安全に初期創設を執行
      await ref
          .read(roomFirestoreProvider)
          .collection('organizations')
          .doc(cleanCode)
          .set({
            'createdAt': FieldValue.serverTimestamp(),
            'createdBy': 'owner_terminal',
          });

      _executeFinalConnection(cleanCode);
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = '通信エラーが発生しました。電波状況を確認してください。');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// ⚠️ 被りが発生した際に、ユーザーを誤操作から物理救済するエラー警告ポップアップ
  void _showDuplicateWarningDialog(BuildContext parentContext, String code) {
    RoomJoinDuplicateWarningDialog.show(
      context: parentContext,
      code: code,
      onConfirm: () => _executeFinalConnection(code),
    );
  }

  /// 最終的な接続処理
  void _executeFinalConnection(String code) {
    ref.read(currentDojoIdProvider.notifier).state = code;
    try {
      PwaStorage.setItem('kendo_os_active_dojo_id', code);
    } catch (_) {}

    // ★ 接続に成功したIDを履歴に保存
    ref.read(dojoRoomHistoryProvider.notifier).addHistory(code);

    // ダイアログを閉じる
    Navigator.of(context).pop();

    AppSnackBar.showSuccess(context, '⚡ 道場空間 [ $code ] にリアルタイム直結しました');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFFFFFFF);
    final textColor = context.appColors.textColor;
    final subTextColor = context.appColors.subTextColor;
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFCBD5E1);
    final inputBgColor = isDark
        ? const Color(0xFF0F172A)
        : const Color(0xFFF8FAFC);

    final keyboardHeight = kIsWeb
        ? 0.0
        : MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible =
        _focusNode.hasFocus ||
        keyboardHeight > 0 ||
        MediaQuery.viewInsetsOf(context).bottom > 50;

    final screenHeight = MediaQuery.of(context).size.height;
    final maxSheetHeight = screenHeight * 0.90;

    return Container(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xlargeValue),
        ),
      ),
      padding: const EdgeInsets.only(
        top: AppSpacing.md,
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        bottom: AppSpacing.xl,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ドラッグハンドルバー
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFFFFFFFF).withValues(alpha: 0.2)
                      : const Color(0x33000000),
                  borderRadius: AppRadius.medium,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '道場ルームへの参加',
              style: TextStyle(
                fontSize: AppFontSize.header,
                fontWeight: AppFontWeight.bold,
                color: textColor,
              ),
            ),
            if (!isKeyboardVisible) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppKendoColors.pureWhite,
                  borderRadius: AppRadius.large,
                ),
                child: const Icon(
                  Icons.qr_code_2,
                  size: 64,
                  color: Color(0xFF161B26),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '会場のQRコードをスキャンするか\n「道場ルームコード」を入力してください',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppFontSize.small,
                  color: subTextColor,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _codeController,
              focusNode: _focusNode,
              scrollPadding: EdgeInsets.zero,
              style: TextStyle(
                color: textColor,
                fontWeight: AppFontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: '例: tokyo_dojo_2026',
                hintStyle: TextStyle(color: subTextColor),
                filled: true,
                fillColor: inputBgColor,
                errorText: _errorMessage,
                errorStyle: const TextStyle(
                  color: AppKendoColors.orangeAccent,
                  fontWeight: AppFontWeight.bold,
                ),
                prefixIcon: Icon(Icons.meeting_room, color: subTextColor),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.medium,
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: AppRadius.medium,
                  borderSide: BorderSide(color: AppKendoColors.teal),
                ),
              ),
              onSubmitted: _handleJoin,
            ),
            // 履歴サジェスト（インラインチップ形式でOverlayPortalのWeb跳ね上がり・表示崩れを完全根絶）
            Consumer(
              builder: (context, ref, _) {
                final history = ref.watch(dojoRoomHistoryProvider);
                if (history.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: history.map((roomCode) {
                        return Material(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFF1F5F9),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.capsule,
                            side: BorderSide(
                              color: isDark
                                  ? const Color(0xFF475569)
                                  : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: InkWell(
                            borderRadius: AppRadius.capsule,
                            onTap: () {
                              _codeController.text = roomCode;
                              _codeController.selection =
                                  TextSelection.fromPosition(
                                    TextPosition(offset: roomCode.length),
                                  );
                              setState(() {});
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.compact,
                                vertical: AppSpacing.subValue,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.history,
                                    size: 16,
                                    color: subTextColor,
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Text(
                                    roomCode,
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: AppFontWeight.bold,
                                      fontSize: AppFontSize.caption,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.subValue),
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      ref
                                          .read(
                                            dojoRoomHistoryProvider.notifier,
                                          )
                                          .removeHistory(roomCode);
                                    },
                                    child: Icon(
                                      Icons.close,
                                      size: 14,
                                      color: subTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.subValue),
            Text(
              '※ 使用可能な文字: 半角英数字、ハイフン(-)、アンダーバー(_)',
              style: TextStyle(
                fontSize: AppFontSize.caption,
                color: subTextColor,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            RoomJoinQrDialogActions(
              isLoading: _isLoading,
              isDark: isDark,
              onCancel: () => Navigator.of(context).pop(),
              onJoin: () => _handleJoin(_codeController.text),
            ),
            if (!kIsWeb && isKeyboardVisible) SizedBox(height: keyboardHeight),
          ],
        ),
      ),
    );
  }
}
