import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/current_sync_context_provider.dart';
import '../../../../core/security/pwa_storage_bridge.dart';

// ★ テスト時にモック（FakeFirestore）を安全に注入するための専用Provider
final roomFirestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

/// 保護者端末や会場配置モニターを、特定の道場同期空間（organizationId）へ
/// 最速かつ迷わせずに直結させるための、QR・手動入力統合ダイアログ。
class RoomJoinQrDialog extends ConsumerStatefulWidget {
  const RoomJoinQrDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
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
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
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
      final docSnapshot = await ref.read(roomFirestoreProvider)
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
      await ref.read(roomFirestoreProvider)
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
    showDialog(
      context: parentContext,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final cardBgColor = isDark 
            ? const Color(0xFF1C1C1E).withValues(alpha: 0.4) 
            : Colors.white.withValues(alpha: 0.6);
        final textColor = isDark ? Colors.white : const Color(0xFF1A237E);
        final subTextColor = isDark ? Colors.white70 : Colors.black87;
        final borderColor = isDark 
            ? Colors.white.withValues(alpha: 0.2) 
            : Colors.white.withValues(alpha: 0.7);

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor, width: 1.5),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.report_problem_rounded, color: Colors.amber),
                        const SizedBox(width: 8),
                        Expanded(child: Text('⚠️ ID重複・既存の部屋', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ルームID [ $code ] はすでに存在しています。\n\n'
                      '他の道場が使用中か、過去に作成された部屋です。このまま接続して共有しますか？\n'
                      '※新規で作りたい場合はキャンセルし、別のIDに変更してください。',
                      style: TextStyle(color: subTextColor, fontSize: 13, height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(), // 閉じて別の名前の入力を促す
                          child: const Text('キャンセル（変更する）', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, elevation: 0),
                          onPressed: () {
                            Navigator.of(context).pop(); // 警告を閉じる
                            _executeFinalConnection(code); // 既存の部屋として接続を承認
                          },
                          child: const Text('このまま接続', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    )
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

    // ダイアログを閉じる
    Navigator.of(context).pop();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⚡ 道場空間 [ $code ] にリアルタイム直結しました'),
        backgroundColor: Colors.teal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark 
        ? const Color(0xFF1C1C1E).withValues(alpha: 0.4) 
        : Colors.white.withValues(alpha: 0.6);
    final textColor = isDark ? Colors.white : const Color(0xFF1A237E);
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final borderColor = isDark 
        ? Colors.white.withValues(alpha: 0.2) 
        : Colors.white.withValues(alpha: 0.7);
    final inputBgColor = isDark 
        ? Colors.white.withValues(alpha: 0.05) 
        : Colors.black.withValues(alpha: 0.05);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '道場ルームへの参加',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                ),
                const SizedBox(height: 16),
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.qr_code_2, size: 110, color: Color(0xFF161B26)),
                ),
                const SizedBox(height: 12),
                Text(
                  '会場のQRコードをスキャンするか\n「道場ルームコード」を入力してください',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: subTextColor),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _codeController,
                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: '例: tokyo_dojo_2026',
                    hintStyle: TextStyle(color: subTextColor),
                    filled: true,
                    fillColor: inputBgColor,
                    errorText: _errorMessage,
                    errorStyle: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold),
                    prefixIcon: Icon(Icons.meeting_room, color: subTextColor),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.teal)),
                  ),
                  onSubmitted: _handleJoin,
                ),
                const SizedBox(height: 8),
                Text(
                  '※ 使用可能な文字: 半角英数字、ハイフン(-)、アンダーバー(_)',
                  style: TextStyle(fontSize: 11, color: subTextColor),
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      child: Text('キャンセル', style: TextStyle(color: subTextColor, fontWeight: FontWeight.bold)),
                    ),
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.teal)
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => _handleJoin(_codeController.text),
                            child: const Text('接続開始', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}