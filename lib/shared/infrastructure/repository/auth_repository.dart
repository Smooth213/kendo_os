import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ★ 提供されたWebクライアントIDで初期化を確実化
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId:
        '164010781926-62n3ne0oal1jov5qpa26htp4q9ele8pa.apps.googleusercontent.com',
  );

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ★ 匿名認証の実装を追加
  Future<void> signInAnonymously() async {
    try {
      await _auth.signInAnonymously();
    } catch (e) {
      debugPrint("匿名ログインエラー: $e");
      rethrow; // ★ これを追加！エラーを呼び出し元（LoginScreen）に伝える
    }
  }

  // ★ 監査官による復元: Googleログイン
  Future<void> signInWithGoogle() async {
    try {
      debugPrint("🔍 [Auth] Googleサインイン開始...");
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint("⚠️ [Auth] ユーザーがサインインをキャンセルしました");
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      debugPrint("✅ [Auth] Googleログイン成功");
    } catch (e, stack) {
      debugPrint("🔥 [Auth] Googleログイン失敗: $e\n$stack");
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      debugPrint('Sign Out Error: $e');
    }
  }
}
