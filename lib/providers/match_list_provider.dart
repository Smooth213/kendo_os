import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/match_model.dart';
import '../repositories/local_match_repository.dart'; // ★ ここを変更

// ★ Phase 3: Firestore自体を提供するProvider
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

// ★ 読み込み元を localMatchRepositoryProvider (Isar) に変更！
final matchStreamProvider = StreamProvider<List<MatchModel>>((ref) {
  return ref.watch(localMatchRepositoryProvider).watchMatches();
});

final matchListProvider = Provider<List<MatchModel>>((ref) {
  return ref.watch(matchStreamProvider).value ?? [];
});

// 競合発生時の専用例外
class ConflictException implements Exception {
  final String message;
  ConflictException([this.message = '他の端末でデータが更新されました。']);
  @override
  String toString() => message;
}