import 'package:cloud_firestore/cloud_firestore.dart';

/// 🌟 通知・アナウンスの重要度/トリガー種別を定義する列挙型
enum AnnounceType {
  emergency, // 【緊急】会場変更など、強制ポップアップ対象
  matchAdded, // 【試合追加】新しい試合が登録された時
  matchStarted, // 【試合開始】コート主任が試合を開始した時
  result, // 【試合終了】勝敗が決した時
}

class AnnounceModel {
  final String id;
  final String tournamentId;
  final String title;
  final String body;
  final DateTime timestamp;
  final AnnounceType type;
  final bool isRead; // 🌟 通知履歴画面（サクラピンクドット表示）の制御用フラグ

  const AnnounceModel({
    required this.id,
    required this.tournamentId,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.type,
    this.isRead = false,
  });

  /// 🌟 コピー用メソッド（未読・既読の切り替え時に安全に状態変更を可能にする）
  AnnounceModel copyWith({
    String? id,
    String? tournamentId,
    String? title,
    String? body,
    DateTime? timestamp,
    AnnounceType? type,
    bool? isRead,
  }) {
    return AnnounceModel(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      title: title ?? this.title,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
    );
  }

  /// 🌟 Firestore / Json からのデシリアライズ（再帰的サニタイズ設計に完全準拠）
  factory AnnounceModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedTime;
    final rawTimestamp = json['timestamp'];

    if (rawTimestamp is Timestamp) {
      parsedTime = rawTimestamp.toDate();
    } else if (rawTimestamp is String) {
      parsedTime = DateTime.parse(rawTimestamp);
    } else {
      parsedTime = DateTime.now();
    }

    return AnnounceModel(
      id: json['id'] as String? ?? '',
      tournamentId: json['tournamentId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      timestamp: parsedTime,
      type: AnnounceType.values.firstWhere(
        (e) => e.name == (json['type'] as String? ?? 'emergency'),
        orElse: () => AnnounceType.emergency,
      ),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  /// 🌟 Firestore / Webキャッシュへのシリアライズ
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tournamentId': tournamentId,
      'title': title,
      'body': body,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      'isRead': isRead,
    };
  }
}
