import 'package:isar_community/isar.dart';
import 'package:kendo_os/domain/match/match_model.dart';

part 'match_comment_entity.g.dart';

@collection
class MatchCommentEntity {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true)
  late String commentId;
  
  @Index()
  String? tournamentId;
  
  String? category;
  String? groupName;
  String? matchGroupId; // ★ 追加: アコーディオン内部のグループID
  
  late String text;
  
  late double order;
  
  @enumerated
  late SyncState syncState;
  
  DateTime? lastUpdatedAt;
}