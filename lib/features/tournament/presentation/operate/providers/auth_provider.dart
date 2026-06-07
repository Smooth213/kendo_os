import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/infrastructure/repository/auth_repository.dart';

// ログイン状態をリアルタイムで監視するプロバイダー
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});
