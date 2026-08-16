import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';

/// 試合スコアラーの排他制御・ロック管理ユースケース
class ScorerLockUseCase {
  const ScorerLockUseCase();

  /// スコアラー権限を取得できるか判定し、可能であれば更新された [MatchModel] を返す
  MatchModel? tryClaimScorer(MatchModel match, String userId, {DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    final isLockExpired =
        match.lockExpiresAt != null &&
        match.lockExpiresAt!.isBefore(currentTime);

    if (match.scorerId == null || match.scorerId == userId || isLockExpired) {
      final expiresAt = currentTime.add(const Duration(minutes: 30));
      return match.copyWith(scorerId: userId, lockExpiresAt: expiresAt);
    }
    return null;
  }

  /// スコアラー権限を強制取得した [MatchModel] を返す
  MatchModel forceClaimScorer(
    MatchModel match,
    String userId, {
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();
    final expiresAt = currentTime.add(const Duration(minutes: 30));
    return match.copyWith(scorerId: userId, lockExpiresAt: expiresAt);
  }

  /// スコアラー権限を解放した [MatchModel] を返す（該当ユーザーの場合のみ解放）
  MatchModel? releaseScorer(MatchModel match, String userId) {
    if (match.scorerId == userId) {
      return match.copyWith(scorerId: null, lockExpiresAt: null);
    }
    return null;
  }
}

final scorerLockUseCaseProvider = Provider<ScorerLockUseCase>((ref) {
  return const ScorerLockUseCase();
});
