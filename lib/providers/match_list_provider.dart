import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/match_model.dart';

// ★ Phase 3: Firestore自体を提供するProvider
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

// ★ Phase 3: 読み取り専用（List表示）に特化したNotifier
// データの保存(Command)、生成(Generator)、タイマー(Timer)は別のProviderへ完全に分離済み
final matchListProvider = NotifierProvider<MatchListNotifier, List<MatchModel>>(() {
  return MatchListNotifier();
});

class MatchListNotifier extends Notifier<List<MatchModel>> {
  
  @override
  List<MatchModel> build() {
    _init();
    return const [];
  }

  FirebaseFirestore get _firestore => ref.read(firestoreProvider);

  // Firestoreとの同期（リアルタイム監視）
  void _init() {
    bool isDisposed = false;
    final subscription = _firestore.collection('matches').snapshots().listen((snapshot) {
      if (isDisposed) return;
      final List<MatchModel> parsedMatches = [];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          if (data['order'] is int) {
            data['order'] = (data['order'] as int).toDouble();
          }
          parsedMatches.add(MatchModel.fromJson({...data, 'id': doc.id}));
        } catch (e) {
          debugPrint('⚠️ Data Skip (ID: ${doc.id}): $e');
        }
      }
      Future.microtask(() {
        if (!isDisposed) state = parsedMatches;
      });
    });

    ref.onDispose(() {
      isDisposed = true;
      subscription.cancel();
    });
  }

  // ★ Step 3-1 最終クリーンアップ: 
  // 全ての「書き込み」ロジックは MatchCommandProvider へ移管したため、
  // この ListProvider 内にはメソッドを一切置かない（読み取り専用にする）。
}

// 競合発生時の専用例外
class ConflictException implements Exception {
  final String message;
  ConflictException([this.message = '他の端末でデータが更新されました。']);
  @override
  String toString() => message;
}