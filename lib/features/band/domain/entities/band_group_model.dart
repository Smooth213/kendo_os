import 'package:flutter/foundation.dart';

/// 🥋 BANDグループ情報モデル
@immutable
class BandGroupModel {
  final String id;
  final String name;
  final String url;
  final int order;
  final DateTime? createdAt;

  const BandGroupModel({
    required this.id,
    required this.name,
    required this.url,
    this.order = 0,
    this.createdAt,
  });

  BandGroupModel copyWith({
    String? id,
    String? name,
    String? url,
    int? order,
    DateTime? createdAt,
  }) {
    return BandGroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'order': order,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory BandGroupModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedCreatedAt;
    if (json['createdAt'] != null) {
      if (json['createdAt'] is String) {
        parsedCreatedAt = DateTime.tryParse(json['createdAt'] as String);
      }
    }

    return BandGroupModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      url: json['url'] as String? ?? '',
      order: json['order'] as int? ?? 0,
      createdAt: parsedCreatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BandGroupModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          url == other.url &&
          order == other.order;

  @override
  int get hashCode =>
      id.hashCode ^ name.hashCode ^ url.hashCode ^ order.hashCode;

  @override
  String toString() =>
      'BandGroupModel(id: $id, name: $name, url: $url, order: $order)';
}
