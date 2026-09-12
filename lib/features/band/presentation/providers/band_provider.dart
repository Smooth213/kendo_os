import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kendo_os/features/band/domain/entities/band_group_model.dart';
import 'package:kendo_os/features/band/infrastructure/repository/band_repository.dart';
import 'package:kendo_os/features/band/presentation/services/band_web_launcher.dart'
    as web_launcher;
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
  /// テスト用URL起動インターセプター
  @visibleForTesting
  static Future<bool> Function(Uri uri)? urlLauncherOverride;

  /// テスト用詳細起動インターセプター（LaunchMode検証用）
  @visibleForTesting
  static Future<bool> Function(Uri uri, LaunchMode mode)?
  urlLauncherWithModeOverride;

  /// テスト用詳細起動インターセプター（webOnlyWindowName検証用）
  @visibleForTesting
  static Future<bool> Function(
    Uri uri,
    LaunchMode mode, {
    String? webOnlyWindowName,
  })?
  urlLauncherAdvancedOverride;

  /// テスト用Web環境シミュレーター
  @visibleForTesting
  static bool? isWebOverride;

  /// テスト用Web直接起動インターセプター
  @visibleForTesting
  static bool Function(String url)? webDirectLauncherOverride;

  /// 現在有効なWeb環境フラグ（テスト時にシミュレート可能）
  static bool get isWebEffective => isWebOverride ?? kIsWeb;

  /// BAND公式の投稿作成ディープリンクを生成
  ///
  /// BANDアプリの投稿作成画面に対戦カードテキストがあらかじめ自動入力された状態で起動します。
  /// BANDアプリ側で「投稿先Bandの選択一覧」が表示されるため、別のグループを表示中であっても
  /// 目的のグループへ確実に切り替えることができ、「現在ご利用いただけません」エラーも白紙Safariも回避できます。
  static String buildBandPostCreateUrl(
    String text, {
    String route = 'kendo-os-beta.web.app',
  }) {
    final encodedText = Uri.encodeComponent(text.trim());
    final encodedRoute = Uri.encodeComponent(route);
    return 'bandapp://create/post?text=$encodedText&route=$encodedRoute';
  }

  /// BANDのWeb URLやグループURLをカスタムスキーム（bandapp://）に変換するヘルパー
  ///
  /// - 空文字 / `https://band.us` / `band.us` ➔ `bandapp://`
  /// - `https://band.us/band/{bandId}` ➔ `bandapp://band/{bandId}`
  /// - `bandapp://...` ➔ そのまま
  /// - 未対応のパス（/n/... など）は「現在ご利用いただけません」エラーを防ぐため
  ///   Web環境では安全に `bandapp://` トップへ誘導
  static String convertToBandAppScheme(String rawUrl, {bool? isWeb}) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty ||
        trimmed == 'https://band.us' ||
        trimmed == 'http://band.us' ||
        trimmed == 'band.us' ||
        trimmed == 'https://band.us/' ||
        trimmed == 'http://band.us/' ||
        trimmed == 'band.us/') {
      return 'bandapp://';
    }

    if (trimmed.startsWith('bandapp://')) {
      return trimmed;
    }

    // 1. https://band.us/band/{bandId} or band.us/band/{bandId}
    final bandRegex = RegExp(
      r'^(?:https?:\/\/)?band\.us\/band\/([0-9a-zA-Z_]+)\/?$',
    );
    final match = bandRegex.firstMatch(trimmed);
    if (match != null) {
      final bandId = match.group(1);
      return 'bandapp://band/$bandId';
    }

    return trimmed;
  }

  /// BANDグループURLまたはアプリを開く
  ///
  /// ユーザーが登録したグループURL（https://band.us/n/... や https://band.us/band/... 等）を
  /// そのまま Universal Link / ネイティブスキーム として直接キックします。
  ///
  /// 【重要: LIVE配信対応】
  /// 公式投稿API（bandapp://create/post）はテキスト投稿専用でありLIVE配信機能がないため使用せず、
  /// グループのトップ画面を直接開くことで、ユーザーがLIVE配信や投稿を自由に開始できるようにします。
  /// 対戦カードテキストはクリップボードへ自動コピー済みのため、配信紹介文やコメントへそのまま貼り付け可能です。
  ///
  /// 【重要: 白紙Safari防止】
  /// url_launcher の window.open('noopener,noreferrer') は iOS PWA で白紙の SFSafariViewController
  /// を強制ポップアップしてしまうため、Web環境では package:web による同一コンテキスト直接キック
  /// （launchWebDirect）を最優先実行します。
  static Future<bool> launchBandUrl(String rawUrl, {String? postText}) async {
    final isWeb = isWebEffective;
    final converted = convertToBandAppScheme(rawUrl, isWeb: isWeb);

    String normalizedUrl = converted;
    if (!normalizedUrl.startsWith('http://') &&
        !normalizedUrl.startsWith('https://') &&
        !normalizedUrl.startsWith('bandapp://')) {
      normalizedUrl = 'https://$normalizedUrl';
    }

    final uri = Uri.tryParse(normalizedUrl);
    if (uri == null) {
      debugPrint('❌ [BandLauncher] 無効なURL: $normalizedUrl');
      return false;
    }

    // Web環境（iOS PWA）の場合：
    // url_launcher の window.open は 'noopener,noreferrer' を付与するため
    // iOS PWA では空の SFSafariViewController が手前に残ってしまいます。
    // そのため Web では直接ランチャー（location.href / <a>タグ直接クリック）を最優先実行します。
    if (isWeb) {
      if (webDirectLauncherOverride != null) {
        final handled = webDirectLauncherOverride!(normalizedUrl);
        if (handled) return true;
      } else {
        final launched = web_launcher.launchWebDirect(normalizedUrl);
        if (launched) return true;
      }
    }

    final isBandApp = uri.scheme == 'bandapp';
    final windowName = (isWeb && isBandApp) ? '_self' : null;

    if (urlLauncherAdvancedOverride != null) {
      return await urlLauncherAdvancedOverride!(
        uri,
        LaunchMode.externalApplication,
        webOnlyWindowName: windowName,
      );
    }

    if (urlLauncherWithModeOverride != null) {
      return await urlLauncherWithModeOverride!(
        uri,
        LaunchMode.externalApplication,
      );
    }

    if (urlLauncherOverride != null) {
      return await urlLauncherOverride!(uri);
    }

    try {
      // 外部アプリ/ブラウザで直接起動（アプリ内ブラウザは起動せず、スッと戻れるようにする）
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: windowName,
      );
      if (!launched) {
        debugPrint('⚠️ [BandLauncher] externalApplication での起動に失敗: $uri');
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('❌ [BandLauncher] launchUrl 失敗: $e');
      return false;
    }
  }
}
