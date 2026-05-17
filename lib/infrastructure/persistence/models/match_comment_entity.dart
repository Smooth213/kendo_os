import 'package:isar_community/isar.dart';
import '../../../../domain/entities/match_model.dart';

part 'match_comment_entity.g.dart';

@collection
class MatchCommentEntity {
  Id get isarId => fastHash(id);

  late String id;
  
  @Index()
  String? tournamentId;
  
  String? category;
  String? groupName;
  
  late String text;
  
  late double order;
  
  @enumerated
  late SyncState syncState;
  
  DateTime? lastUpdatedAt;
}

/// Isar v3においてString IDを安全にId(int)に変換するための標準関数
int fastHash(String string) {
  var hash = 0xcbf29ce484222325;
  int i = 0;
  while (i < string.length) {
    final codeUnit = string.codeUnitAt(i++);
    hash ^= codeUnit >> 8;
    hash *= 0x100000001b3;
    hash ^= codeUnit & 0xFF;
    hash *= 0x100000001b3;
  }
  return hash;
}