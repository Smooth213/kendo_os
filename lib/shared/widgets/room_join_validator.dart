/// 道場ルームコードのバリデーション結果
class RoomJoinValidationResult {
  final bool isValid;
  final String? errorMessage;

  const RoomJoinValidationResult({required this.isValid, this.errorMessage});
  const RoomJoinValidationResult.ok() : isValid = true, errorMessage = null;
  const RoomJoinValidationResult.error(String msg)
    : isValid = false,
      errorMessage = msg;
}

/// 道場ルームへの参加リクエスト バリデーター
///
/// [RoomJoinQrDialog] から分離された純粋な入力バリデーションロジック。
/// Firestoreや状態管理に依存しない純粋関数で構成され、単体テストが容易。
class RoomJoinValidator {
  const RoomJoinValidator._();

  /// ルームコードを正規化（トリム・小文字化）して返す
  static String normalize(String rawCode) => rawCode.trim().toLowerCase();

  /// ルームコードをバリデートし、[RoomJoinValidationResult] を返す
  ///
  /// - 空文字はエラー
  /// - 半角英数字・ハイフン・アンダーバー以外はエラー
  /// - それ以外は OK
  static RoomJoinValidationResult validate(String rawCode) {
    final cleanCode = normalize(rawCode);

    if (cleanCode.isEmpty) {
      return const RoomJoinValidationResult.error('道場ルームコードを入力してください');
    }

    // 使用可能文字: 半角英数字、ハイフン、アンダーバーのみ
    if (!RegExp(r'^[a-z0-9_\-]+$').hasMatch(cleanCode)) {
      return const RoomJoinValidationResult.error('半角英数字、ハイフン、アンダーバーのみ使用できます');
    }

    return const RoomJoinValidationResult.ok();
  }
}
