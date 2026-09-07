import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// 🥋 Google認証・アカウント連携サービス
class GoogleAuthService {
  final FirebaseAuth? _injectedAuth;
  final GoogleSignIn _googleSignIn;

  GoogleAuthService({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
    : _injectedAuth = auth,
      _googleSignIn =
          googleSignIn ?? GoogleSignIn(scopes: ['email', 'profile']);

  FirebaseAuth? get _auth {
    if (_injectedAuth != null) return _injectedAuth;
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  /// 現在のFirebaseユーザー
  User? get currentUser => _auth?.currentUser;

  /// ユーザー認証状態のストリーム（プロバイダ連携変更も検知）
  Stream<User?> get userChanges => _auth?.userChanges() ?? const Stream.empty();

  /// Googleプロバイダが連携済みかどうか
  bool get isGoogleLinked {
    final user = currentUser;
    if (user == null) return false;
    return user.providerData.any((p) => p.providerId == 'google.com');
  }

  /// 連携中のGoogleメールアドレス（未連携ならnull）
  String? get userEmail {
    final user = currentUser;
    if (user == null) return null;
    for (final p in user.providerData) {
      if (p.providerId == 'google.com' && p.email != null) {
        return p.email;
      }
    }
    return user.email;
  }

  bool _isPopupBlocked(dynamic e) {
    final str = e.toString().toLowerCase();
    return str.contains('popup-blocked') ||
        str.contains('popup_blocked') ||
        str.contains('blocked by the browser') ||
        (e is FirebaseException && e.code == 'popup-blocked');
  }

  bool _isCredentialInUse(dynamic e) {
    if (e is FirebaseAuthException) {
      return e.code == 'credential-already-in-use' ||
          e.code == 'email-already-in-use' ||
          e.code == 'provider-already-linked';
    }
    final str = e.toString();
    return str.contains('credential-already-in-use') ||
        str.contains('email-already-in-use') ||
        str.contains('provider-already-linked');
  }

  /// Webリダイレクト認証後の結果をチェック（画面遷移で戻ってきた際の結果受信）
  Future<UserCredential?> checkRedirectResult() async {
    if (!kIsWeb) return null;
    final auth = _auth;
    if (auth == null) return null;
    try {
      final cred = await auth.getRedirectResult();
      if (cred.user != null) {
        debugPrint(
          '✅ [GoogleAuthService] Redirect result received: ${cred.user?.email}',
        );
        return cred;
      }
      return null;
    } catch (e) {
      debugPrint('ℹ️ [GoogleAuthService] checkRedirectResult: $e');
      return null;
    }
  }

  /// Googleアカウントとの連携を実行（既存匿名アカウントがあれば安全に昇格）
  Future<UserCredential?> linkOrSignInWithGoogle() async {
    final auth = _auth;
    if (auth == null) {
      throw Exception('Firebase is not initialized');
    }
    try {
      final user = auth.currentUser;

      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        provider.addScope('email');
        provider.addScope('profile');

        try {
          // 1. 匿名ユーザーがいる場合はリンク（昇格）を試行
          if (user != null && user.isAnonymous) {
            try {
              final result = await user.linkWithPopup(provider);
              debugPrint(
                '✅ [GoogleAuthService] Web: Anonymous user linked to Google successfully',
              );
              return result;
            } catch (linkErr) {
              if (_isCredentialInUse(linkErr)) {
                debugPrint(
                  'ℹ️ [GoogleAuthService] Web: Credential in use, falling back to signInWithPopup',
                );
                return await auth.signInWithPopup(provider);
              }
              rethrow;
            }
          } else {
            // 通常のサインイン
            return await auth.signInWithPopup(provider);
          }
        } catch (popupErr) {
          if (_isPopupBlocked(popupErr)) {
            debugPrint('⚠️ [GoogleAuthService] Web: Popup blocked by browser');
            throw Exception('popup-blocked');
          }
          rethrow;
        }
      } else {
        // モバイル環境フロー (google_sign_in 6.x)
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null; // ユーザーによるキャンセル

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        if (user != null && user.isAnonymous) {
          try {
            return await user.linkWithCredential(credential);
          } on FirebaseAuthException catch (e) {
            if (e.code == 'credential-already-in-use' ||
                e.code == 'email-already-in-use') {
              return await auth.signInWithCredential(credential);
            }
            rethrow;
          }
        } else {
          return await auth.signInWithCredential(credential);
        }
      }
    } catch (e) {
      debugPrint('⚠️ [GoogleAuthService] linkOrSignIn error: $e');
      rethrow;
    }
  }

  /// Googleアカウントの連携を解除（匿名アカウントへ戻すかサインアウト）
  Future<void> unlinkGoogle() async {
    final user = currentUser;
    if (user == null) return;

    try {
      final isLinked = user.providerData.any(
        (p) => p.providerId == 'google.com',
      );
      if (isLinked) {
        await user.unlink('google.com');
        debugPrint('✅ [GoogleAuthService] Unlinked Google provider');
      }
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }
    } catch (e) {
      debugPrint('⚠️ [GoogleAuthService] unlink error: $e');
      rethrow;
    }
  }
}

/// 🥋 GoogleAuthService プロバイダ
final googleAuthServiceProvider = Provider<GoogleAuthService>((ref) {
  return GoogleAuthService();
});

/// 🥋 認証状態（プロバイダ変更含む）を購読するプロバイダ
final authUserChangesProvider = StreamProvider<User?>((ref) {
  final service = ref.watch(googleAuthServiceProvider);
  return service.userChanges;
});

/// 🥋 Google連携状態フラグプロバイダ
final isGoogleLinkedProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(authUserChangesProvider);
  final user = userAsync.valueOrNull;
  if (user == null) return false;
  return user.providerData.any((p) => p.providerId == 'google.com');
});

/// 🥋 連携中Googleメールアドレスプロバイダ
final linkedGoogleEmailProvider = Provider<String?>((ref) {
  final userAsync = ref.watch(authUserChangesProvider);
  final user = userAsync.valueOrNull;
  if (user == null) return null;
  for (final p in user.providerData) {
    if (p.providerId == 'google.com' && p.email != null) {
      return p.email;
    }
  }
  return user.email;
});

/// 🥋 連携中Google UIDプロバイダ（端末間の一致検証用）
final linkedGoogleUidProvider = Provider<String?>((ref) {
  final userAsync = ref.watch(authUserChangesProvider);
  final user = userAsync.valueOrNull;
  if (user == null) return null;
  final isGoogle = user.providerData.any((p) => p.providerId == 'google.com');
  return isGoogle ? user.uid : null;
});
