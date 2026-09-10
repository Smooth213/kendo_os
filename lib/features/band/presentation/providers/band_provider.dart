import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kendo_os/features/band/domain/entities/band_group_model.dart';
import 'package:kendo_os/features/band/infrastructure/repository/band_repository.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';

/// 🥋 BandRepository Provider（テナントID連動）
final bandRepositoryProvider = Provider<BandRepository>((ref) {
  final dojoId = ref.watch(currentDojoIdProvider);
  return BandRepository(FirebaseFirestore.instance, dojoId);
});

/// 🥋 BANDグループ一覧のリアルタイム監視StreamProvider
final bandGroupsStreamProvider = StreamProvider<List<BandGroupModel>>((ref) {
  final repo = ref.watch(bandRepositoryProvider);
  return repo.watchBandGroups();
});

/// 🥋 BANDアプリ/Webリンク起動ヘルパー
class BandLauncherHelper {
  /// BANDグループURLまたはアプリを開く
  static Future<bool> launchBandUrl(String rawUrl) async {
    String url = rawUrl.trim();
    if (url.isEmpty) {
      // URL未設定時はBANDアプリトップ（またはband.us Web）を開く
      url = 'https://band.us';
    }

    // http/https が無ければ補完
    if (!url.startsWith('http://') &&
        !url.startsWith('https://') &&
        !url.startsWith('bandapp://')) {
      url = 'https://$url';
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      debugPrint('❌ [BandLauncher] 無効なURL: $url');
      return false;
    }

    try {
      // 外部アプリ/ブラウザで起動（ユニバーサルリンク対応）
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        // フォールバック: 通常起動
        return await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
      return true;
    } catch (e) {
      debugPrint('⚠️ [BandLauncher] launchUrl 失敗: $e');
      try {
        return await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (_) {
        return false;
      }
    }
  }
}
