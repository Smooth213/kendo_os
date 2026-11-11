/// 1大会限定 観戦共有リンクの有効期限プリセット
enum ViewerShareExpiryPreset {
  hours24('24h', '24時間'),
  days7('7d', '7日間'),
  unlimited('unlimited', '無期限'),
  revoked('revoked', '停止');

  final String key;
  final String label;

  const ViewerShareExpiryPreset(this.key, this.label);

  static ViewerShareExpiryPreset fromKey(String? key) {
    return ViewerShareExpiryPreset.values.firstWhere(
      (e) => e.key == key,
      orElse: () => ViewerShareExpiryPreset.days7,
    );
  }

  /// 基準時刻から有効期限日時を算出する（無期限はnull、停止は過去時刻扱い）
  DateTime? computeExpiresAt({DateTime? now}) {
    final base = now ?? DateTime.now();
    switch (this) {
      case ViewerShareExpiryPreset.hours24:
        return base.add(const Duration(hours: 24));
      case ViewerShareExpiryPreset.days7:
        return base.add(const Duration(days: 7));
      case ViewerShareExpiryPreset.unlimited:
        return null;
      case ViewerShareExpiryPreset.revoked:
        return base.subtract(const Duration(seconds: 1));
    }
  }
}

/// Firestore上の観戦共有リンクメタ情報
class ViewerShareLinkInfo {
  final String token;
  final String dojoId;
  final String tournamentId;
  final ViewerShareExpiryPreset preset;
  final DateTime? expiresAt;
  final bool isRevoked;

  const ViewerShareLinkInfo({
    required this.token,
    required this.dojoId,
    required this.tournamentId,
    required this.preset,
    this.expiresAt,
    this.isRevoked = false,
  });

  bool get isUnlimited =>
      !isRevoked &&
      preset == ViewerShareExpiryPreset.unlimited &&
      expiresAt == null;

  bool isActiveAt(DateTime now) {
    if (isRevoked || preset == ViewerShareExpiryPreset.revoked) {
      return false;
    }
    if (expiresAt == null) {
      return true;
    }
    return !now.isAfter(expiresAt!);
  }
}

/// 共有リンク検証時の状態区分
enum ViewerShareAccessStatus {
  valid,
  expired,
  revoked,
  invalid,
  offlineOrUnavailable,
}

/// 共有リンク検証結果
class ViewerShareVerificationResult {
  final ViewerShareAccessStatus status;
  final ViewerShareLinkInfo? linkInfo;

  const ViewerShareVerificationResult({required this.status, this.linkInfo});

  bool get isAllowed => status == ViewerShareAccessStatus.valid;
}

/// 道場ルームのPIN保護状態
enum DojoJoinStatus { notFound, requiresPin, legacyUnsetPin }
