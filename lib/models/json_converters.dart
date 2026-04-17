import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

// 1. 日付の変換フィルター（Firestore Timestamp <-> Dart DateTime）
class TimestampConverter implements JsonConverter<DateTime, dynamic> {
  const TimestampConverter();

  @override
  DateTime fromJson(dynamic json) {
    if (json is Timestamp) return json.toDate();
    if (json is String) return DateTime.tryParse(json) ?? DateTime.now();
    if (json is int) return DateTime.fromMillisecondsSinceEpoch(json);
    return DateTime.now(); // どれにも当てはまらない場合は現在時刻（エラー回避）
  }

  @override
  dynamic toJson(DateTime object) => Timestamp.fromDate(object);
}

// 2. 小数の変換フィルター（Firestoreの 1 と 1.0 の揺れを吸収）
class DoubleConverter implements JsonConverter<double, dynamic> {
  const DoubleConverter();

  @override
  double fromJson(dynamic json) {
    if (json is int) return json.toDouble();
    if (json is double) return json;
    if (json is String) return double.tryParse(json) ?? 0.0;
    return 0.0;
  }

  @override
  dynamic toJson(double object) => object;
}