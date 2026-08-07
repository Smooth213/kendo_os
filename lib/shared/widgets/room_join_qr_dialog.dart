import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

import 'package:kendo_os/shared/theme/app_kendo_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/security/pwa_storage_bridge.dart';
import 'package:kendo_os/shared/presentation/providers/dojo_room_history_provider.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';

// ★ テスト時にモック（FakeFirestore）を安全に注入するための専用Provider
final roomFirestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

/// 保護者端末や会場配置モニターを、特定の道場同期空間（organizationId）へ
/// 最速かつ迷わせずに直結させるための、QR・手動入力統合ダイアログ。
class RoomJoinQrDialog extends ConsumerStatefulWidget {
  const RoomJoinQrDialog({super.key});

  static void show(BuildContext context) {
    showAppDialog(
      context: context,
      barrierDismissible: true,
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
  void dispose() {
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// クラウド（Firestore）へパケットを飛ばし、入力されたIDが既に他者に使われているか
  /// 重複を決定論的に水際検知・ガードする非同期チェックロジック
  void _handleJoin(String roomCode) async {
    final cleanCode = roomCode.trim().toLowerCase(); // 全小文字化で表記揺れ防止
    if (cleanCode.isEmpty) {
      setState(() => _errorMessage = '道場ルームコードを入力してください');
      return;
    }

    // 記号制限などのバリデーション
    if (!RegExp(r'^[a-z0-9_\\-]+$').hasMatch(cleanCode)) {
      setState(() => _errorMessage = '半角英数字、ハイフン、アンダーバーのみ使用できます');
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
    showAppDialog(
      context: parentContext,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final cardBgColor = isDark
            ? const Color(0xFF1C1C1E).withValues(alpha: 0.4)
            : AppKendoColors.pureWhite.withValues(alpha: 0.6);
        final textColor = context.appColors.textColor;
        final subTextColor = context.appColors.subTextColor;
        final borderColor = isDark
            ? AppKendoColors.pureWhite.withValues(alpha: 0.2)
            : AppKendoColors.pureWhite.withValues(alpha: 0.7);

        return Dialog(
          backgroundColor: AppKendoColors.transparent,
          elevation: 0,
          child: ClipRRect(
            borderRadius: AppRadius.xlarge,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: AppRadius.xlarge,
                  border: Border.all(color: borderColor, width: 1.5),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.report_problem_rounded,
                          color: AppKendoColors.ipponGold,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            '⚠️ ID重複・既存の部屋',
                            style: TextStyle(
                              color: textColor,
                              fontSize: AppFontSize.subhead,
                              fontWeight: AppFontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'ルームID [ $code ] はすでに存在しています。\n\n'
                      '他の道場が使用中か、過去に作成された部屋です。このまま接続して共有しますか？\n'
                      '※新規で作りたい場合はキャンセルし、別のIDに変更してください。',
                      style: TextStyle(
                        color: subTextColor,
                        fontSize: AppFontSize.bodySmall,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        TextButton(
                          onPressed: () =>
                              Navigator.of(context).pop(), // 閉じて別の名前の入力を促す
                          child: const Text(
                            'キャンセル（変更する）',
                            style: TextStyle(
                              color: AppKendoColors.grey,
                              fontWeight: AppFontWeight.bold,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppKendoColors.teal,
                            elevation: 0,
                          ),
                          onPressed: () {
                            Navigator.of(context).pop(); // 警告を閉じる
                            _executeFinalConnection(code); // 既存の部屋として接続を承認
                          },
                          child: const Text(
                            'このまま接続',
                            style: TextStyle(
                              color: AppKendoColors.pureWhite,
                              fontWeight: AppFontWeight.bold,
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
        );
      },
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
        ? const Color(0xFF1C1C1E).withValues(alpha: 0.4)
        : AppKendoColors.pureWhite.withValues(alpha: 0.6);
    final textColor = context.appColors.textColor;
    final subTextColor = context.appColors.subTextColor;
    final borderColor = isDark
        ? AppKendoColors.pureWhite.withValues(alpha: 0.2)
        : AppKendoColors.pureWhite.withValues(alpha: 0.7);
    final inputBgColor = isDark
        ? AppKendoColors.pureWhite.withValues(alpha: 0.05)
        : AppKendoColors.pureBlack.withValues(alpha: 0.05);

    return Dialog(
      backgroundColor: AppKendoColors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: AppRadius.xlarge,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: 18,
            ),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: AppRadius.xlarge,
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '道場ルームへの参加',
                    style: TextStyle(
                      fontSize: AppFontSize.header,
                      fontWeight: AppFontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    width: 130,
                    height: 130,
                    decoration: const BoxDecoration(
                      color: AppKendoColors.pureWhite,
                      borderRadius: AppRadius.large,
                    ),
                    child: const Icon(
                      Icons.qr_code_2,
                      size: 110,
                      color: Color(0xFF161B26),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '会場のQRコードをスキャンするか\n「道場ルームコード」を入力してください',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppFontSize.small,
                      color: subTextColor,
                    ),
                  ),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return RawAutocomplete<String>(
                        textEditingController: _codeController,
                        focusNode: _focusNode,
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          final text = textEditingValue.text.toLowerCase();
                          final history = ref.read(dojoRoomHistoryProvider);
                          if (text.isEmpty) return history;
                          return history.where(
                            (option) => option.toLowerCase().contains(text),
                          );
                        },
                        fieldViewBuilder:
                            (
                              context,
                              fieldController,
                              focusNode,
                              onFieldSubmitted,
                            ) {
                              return TextField(
                                controller: fieldController,
                                focusNode: focusNode,
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
                                  prefixIcon: Icon(
                                    Icons.meeting_room,
                                    color: subTextColor,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: AppRadius.medium,
                                    borderSide: BorderSide(color: borderColor),
                                  ),
                                  focusedBorder: const OutlineInputBorder(
                                    borderRadius: AppRadius.medium,
                                    borderSide: BorderSide(
                                      color: AppKendoColors.teal,
                                    ),
                                  ),
                                ),
                                onSubmitted: _handleJoin,
                              );
                            },
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 8.0,
                              borderRadius: AppRadius.medium,
                              color: isDark
                                  ? const Color(0xFF2C2C2E)
                                  : AppKendoColors.pureWhite,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight: 200,
                                  maxWidth: constraints.maxWidth,
                                ),
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  itemBuilder: (context, index) {
                                    final option = options.elementAt(index);
                                    return ListTile(
                                      leading: Icon(
                                        Icons.history,
                                        color: subTextColor,
                                        size: 20,
                                      ),
                                      title: Text(
                                        option,
                                        style: TextStyle(
                                          color: textColor,
                                          fontWeight: AppFontWeight.bold,
                                        ),
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(
                                          Icons.close,
                                          color: AppKendoColors.grey,
                                          size: 18,
                                        ),
                                        onPressed: () {
                                          ref
                                              .read(
                                                dojoRoomHistoryProvider
                                                    .notifier,
                                              )
                                              .removeHistory(option);
                                          // リストを再描画するためテキストを同値で再セットするハック
                                          final selection =
                                              _codeController.selection;
                                          _codeController.text =
                                              _codeController.text;
                                          _codeController.selection = selection;
                                        },
                                      ),
                                      onTap: () {
                                        onSelected(option);
                                        FocusScope.of(context).unfocus();
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '※ 使用可能な文字: 半角英数字、ハイフン(-)、アンダーバー(_)',
                    style: TextStyle(
                      fontSize: AppFontSize.caption,
                      color: subTextColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: Text(
                          'キャンセル',
                          style: TextStyle(
                            color: subTextColor,
                            fontWeight: AppFontWeight.bold,
                          ),
                        ),
                      ),
                      _isLoading
                          ? const CircularProgressIndicator(
                              color: AppKendoColors.teal,
                            )
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppKendoColors.teal,
                                foregroundColor: AppKendoColors.pureWhite,
                                elevation: 0,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: AppRadius.medium,
                                ),
                              ),
                              onPressed: () =>
                                  _handleJoin(_codeController.text),
                              child: const Text(
                                '接続開始',
                                style: TextStyle(
                                  fontWeight: AppFontWeight.bold,
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
