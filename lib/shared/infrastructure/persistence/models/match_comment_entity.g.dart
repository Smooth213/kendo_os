// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_comment_entity.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetMatchCommentEntityCollection on Isar {
  IsarCollection<MatchCommentEntity> get matchCommentEntitys =>
      this.collection();
}

const MatchCommentEntitySchema = CollectionSchema(
  name: r'MatchCommentEntity',
  id: 4914048968579226046,
  properties: {
    r'category': PropertySchema(
      id: 0,
      name: r'category',
      type: IsarType.string,
    ),
    r'commentId': PropertySchema(
      id: 1,
      name: r'commentId',
      type: IsarType.string,
    ),
    r'groupName': PropertySchema(
      id: 2,
      name: r'groupName',
      type: IsarType.string,
    ),
    r'lastUpdatedAt': PropertySchema(
      id: 3,
      name: r'lastUpdatedAt',
      type: IsarType.dateTime,
    ),
    r'matchGroupId': PropertySchema(
      id: 4,
      name: r'matchGroupId',
      type: IsarType.string,
    ),
    r'order': PropertySchema(id: 5, name: r'order', type: IsarType.double),
    r'syncState': PropertySchema(
      id: 6,
      name: r'syncState',
      type: IsarType.byte,
      enumMap: _MatchCommentEntitysyncStateEnumValueMap,
    ),
    r'text': PropertySchema(id: 7, name: r'text', type: IsarType.string),
    r'tournamentId': PropertySchema(
      id: 8,
      name: r'tournamentId',
      type: IsarType.string,
    ),
  },

  estimateSize: _matchCommentEntityEstimateSize,
  serialize: _matchCommentEntitySerialize,
  deserialize: _matchCommentEntityDeserialize,
  deserializeProp: _matchCommentEntityDeserializeProp,
  idName: r'id',
  indexes: {
    r'commentId': IndexSchema(
      id: 3609824276468662262,
      name: r'commentId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'commentId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'tournamentId': IndexSchema(
      id: -716810079468899455,
      name: r'tournamentId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'tournamentId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _matchCommentEntityGetId,
  getLinks: _matchCommentEntityGetLinks,
  attach: _matchCommentEntityAttach,
  version: '3.3.2',
);

int _matchCommentEntityEstimateSize(
  MatchCommentEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.category;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.commentId.length * 3;
  {
    final value = object.groupName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.matchGroupId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.text.length * 3;
  {
    final value = object.tournamentId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _matchCommentEntitySerialize(
  MatchCommentEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.category);
  writer.writeString(offsets[1], object.commentId);
  writer.writeString(offsets[2], object.groupName);
  writer.writeDateTime(offsets[3], object.lastUpdatedAt);
  writer.writeString(offsets[4], object.matchGroupId);
  writer.writeDouble(offsets[5], object.order);
  writer.writeByte(offsets[6], object.syncState.index);
  writer.writeString(offsets[7], object.text);
  writer.writeString(offsets[8], object.tournamentId);
}

MatchCommentEntity _matchCommentEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = MatchCommentEntity();
  object.category = reader.readStringOrNull(offsets[0]);
  object.commentId = reader.readString(offsets[1]);
  object.groupName = reader.readStringOrNull(offsets[2]);
  object.id = id;
  object.lastUpdatedAt = reader.readDateTimeOrNull(offsets[3]);
  object.matchGroupId = reader.readStringOrNull(offsets[4]);
  object.order = reader.readDouble(offsets[5]);
  object.syncState =
      _MatchCommentEntitysyncStateValueEnumMap[reader.readByteOrNull(
        offsets[6],
      )] ??
      SyncState.localOnly;
  object.text = reader.readString(offsets[7]);
  object.tournamentId = reader.readStringOrNull(offsets[8]);
  return object;
}

P _matchCommentEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readDouble(offset)) as P;
    case 6:
      return (_MatchCommentEntitysyncStateValueEnumMap[reader.readByteOrNull(
                offset,
              )] ??
              SyncState.localOnly)
          as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _MatchCommentEntitysyncStateEnumValueMap = {
  'localOnly': 0,
  'syncing': 1,
  'synced': 2,
  'conflict': 3,
};
const _MatchCommentEntitysyncStateValueEnumMap = {
  0: SyncState.localOnly,
  1: SyncState.syncing,
  2: SyncState.synced,
  3: SyncState.conflict,
};

Id _matchCommentEntityGetId(MatchCommentEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _matchCommentEntityGetLinks(
  MatchCommentEntity object,
) {
  return [];
}

void _matchCommentEntityAttach(
  IsarCollection<dynamic> col,
  Id id,
  MatchCommentEntity object,
) {
  object.id = id;
}

extension MatchCommentEntityByIndex on IsarCollection<MatchCommentEntity> {
  Future<MatchCommentEntity?> getByCommentId(String commentId) {
    return getByIndex(r'commentId', [commentId]);
  }

  MatchCommentEntity? getByCommentIdSync(String commentId) {
    return getByIndexSync(r'commentId', [commentId]);
  }

  Future<bool> deleteByCommentId(String commentId) {
    return deleteByIndex(r'commentId', [commentId]);
  }

  bool deleteByCommentIdSync(String commentId) {
    return deleteByIndexSync(r'commentId', [commentId]);
  }

  Future<List<MatchCommentEntity?>> getAllByCommentId(
    List<String> commentIdValues,
  ) {
    final values = commentIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'commentId', values);
  }

  List<MatchCommentEntity?> getAllByCommentIdSync(
    List<String> commentIdValues,
  ) {
    final values = commentIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'commentId', values);
  }

  Future<int> deleteAllByCommentId(List<String> commentIdValues) {
    final values = commentIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'commentId', values);
  }

  int deleteAllByCommentIdSync(List<String> commentIdValues) {
    final values = commentIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'commentId', values);
  }

  Future<Id> putByCommentId(MatchCommentEntity object) {
    return putByIndex(r'commentId', object);
  }

  Id putByCommentIdSync(MatchCommentEntity object, {bool saveLinks = true}) {
    return putByIndexSync(r'commentId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByCommentId(List<MatchCommentEntity> objects) {
    return putAllByIndex(r'commentId', objects);
  }

  List<Id> putAllByCommentIdSync(
    List<MatchCommentEntity> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'commentId', objects, saveLinks: saveLinks);
  }
}

extension MatchCommentEntityQueryWhereSort
    on QueryBuilder<MatchCommentEntity, MatchCommentEntity, QWhere> {
  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension MatchCommentEntityQueryWhere
    on QueryBuilder<MatchCommentEntity, MatchCommentEntity, QWhereClause> {
  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterWhereClause>
  idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterWhereClause>
  idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterWhereClause>
  commentIdEqualTo(String commentId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'commentId', value: [commentId]),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterWhereClause>
  commentIdNotEqualTo(String commentId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'commentId',
                lower: [],
                upper: [commentId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'commentId',
                lower: [commentId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'commentId',
                lower: [commentId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'commentId',
                lower: [],
                upper: [commentId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterWhereClause>
  tournamentIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'tournamentId', value: [null]),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterWhereClause>
  tournamentIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'tournamentId',
          lower: [null],
          includeLower: false,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterWhereClause>
  tournamentIdEqualTo(String? tournamentId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'tournamentId',
          value: [tournamentId],
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterWhereClause>
  tournamentIdNotEqualTo(String? tournamentId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'tournamentId',
                lower: [],
                upper: [tournamentId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'tournamentId',
                lower: [tournamentId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'tournamentId',
                lower: [tournamentId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'tournamentId',
                lower: [],
                upper: [tournamentId],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension MatchCommentEntityQueryFilter
    on QueryBuilder<MatchCommentEntity, MatchCommentEntity, QFilterCondition> {
  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  categoryIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'category'),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  categoryIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'category'),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  categoryEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'category',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  categoryGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'category',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  categoryLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'category',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  categoryBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'category',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  categoryStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'category',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  categoryEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'category',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  categoryContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'category',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  categoryMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'category',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  categoryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'category', value: ''),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  categoryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'category', value: ''),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  commentIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'commentId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  commentIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'commentId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  commentIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'commentId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  commentIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'commentId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  commentIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'commentId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  commentIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'commentId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  commentIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'commentId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  commentIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'commentId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  commentIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'commentId', value: ''),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  commentIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'commentId', value: ''),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  groupNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'groupName'),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  groupNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'groupName'),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  groupNameEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'groupName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  groupNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'groupName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  groupNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'groupName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  groupNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'groupName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  groupNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'groupName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  groupNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'groupName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  groupNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'groupName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  groupNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'groupName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  groupNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'groupName', value: ''),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  groupNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'groupName', value: ''),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  lastUpdatedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'lastUpdatedAt'),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  lastUpdatedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'lastUpdatedAt'),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  lastUpdatedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastUpdatedAt', value: value),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  lastUpdatedAtGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastUpdatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  lastUpdatedAtLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastUpdatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  lastUpdatedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastUpdatedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  matchGroupIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'matchGroupId'),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  matchGroupIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'matchGroupId'),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  matchGroupIdEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'matchGroupId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  matchGroupIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'matchGroupId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  matchGroupIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'matchGroupId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  matchGroupIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'matchGroupId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  matchGroupIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'matchGroupId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  matchGroupIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'matchGroupId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  matchGroupIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'matchGroupId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  matchGroupIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'matchGroupId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  matchGroupIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'matchGroupId', value: ''),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  matchGroupIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'matchGroupId', value: ''),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  orderEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'order',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  orderGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'order',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  orderLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'order',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  orderBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'order',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  syncStateEqualTo(SyncState value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'syncState', value: value),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  syncStateGreaterThan(SyncState value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'syncState',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  syncStateLessThan(SyncState value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'syncState',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  syncStateBetween(
    SyncState lower,
    SyncState upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'syncState',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  textEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  textGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  textLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  textBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'text',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  textStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  textEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  textContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  textMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'text',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  textIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'text', value: ''),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  textIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'text', value: ''),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  tournamentIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'tournamentId'),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  tournamentIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'tournamentId'),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  tournamentIdEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'tournamentId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  tournamentIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'tournamentId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  tournamentIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'tournamentId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  tournamentIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'tournamentId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  tournamentIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'tournamentId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  tournamentIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'tournamentId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  tournamentIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'tournamentId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  tournamentIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'tournamentId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  tournamentIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'tournamentId', value: ''),
      );
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterFilterCondition>
  tournamentIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'tournamentId', value: ''),
      );
    });
  }
}

extension MatchCommentEntityQueryObject
    on QueryBuilder<MatchCommentEntity, MatchCommentEntity, QFilterCondition> {}

extension MatchCommentEntityQueryLinks
    on QueryBuilder<MatchCommentEntity, MatchCommentEntity, QFilterCondition> {}

extension MatchCommentEntityQuerySortBy
    on QueryBuilder<MatchCommentEntity, MatchCommentEntity, QSortBy> {
  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterSortBy>
  sortByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterSortBy>
  sortByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterSortBy>
  sortByCommentId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'commentId', Sort.asc);
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterSortBy>
  sortByCommentIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'commentId', Sort.desc);
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterSortBy>
  sortByGroupName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupName', Sort.asc);
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterSortBy>
  sortByGroupNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupName', Sort.desc);
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterSortBy>
  sortByLastUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdatedAt', Sort.asc);
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterSortBy>
  sortByLastUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdatedAt', Sort.desc);
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterSortBy>
  sortByMatchGroupId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchGroupId', Sort.asc);
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterSortBy>
  sortByMatchGroupIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchGroupId', Sort.desc);
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterSortBy>
  sortByOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'order', Sort.asc);
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterSortBy>
  sortByOrderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'order', Sort.desc);
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterSortBy>
  sortBySyncState() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncState', Sort.asc);
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterSortBy>
  sortBySyncStateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncState', Sort.desc);
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterSortBy>
  sortByText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'text', Sort.asc);
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterSortBy>
  sortByTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'text', Sort.desc);
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterSortBy>
  sortByTournamentId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tournamentId', Sort.asc);
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterSortBy>
  sortByTournamentIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tournamentId', Sort.desc);
    });
  }
}

extension MatchCommentEntityQuerySortThenBy
    on QueryBuilder<MatchCommentEntity, MatchCommentEntity, QSortThenBy> {
  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterSortBy>
  thenByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterSortBy>
  thenByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterSortBy>
  thenByCommentId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'commentId', Sort.asc);
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterSortBy>
  thenByCommentIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'commentId', Sort.desc);
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterSortBy>
  thenByGroupName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupName', Sort.asc);
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterSortBy>
  thenByGroupNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupName', Sort.desc);
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterSortBy>
  thenByLastUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdatedAt', Sort.asc);
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterSortBy>
  thenByLastUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdatedAt', Sort.desc);
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterSortBy>
  thenByMatchGroupId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchGroupId', Sort.asc);
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterSortBy>
  thenByMatchGroupIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchGroupId', Sort.desc);
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterSortBy>
  thenByOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'order', Sort.asc);
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterSortBy>
  thenByOrderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'order', Sort.desc);
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterSortBy>
  thenBySyncState() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncState', Sort.asc);
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterSortBy>
  thenBySyncStateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncState', Sort.desc);
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterSortBy>
  thenByText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'text', Sort.asc);
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterSortBy>
  thenByTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'text', Sort.desc);
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterSortBy>
  thenByTournamentId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tournamentId', Sort.asc);
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QAfterSortBy>
  thenByTournamentIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tournamentId', Sort.desc);
    });
  }
}

extension MatchCommentEntityQueryWhereDistinct
    on QueryBuilder<MatchCommentEntity, MatchCommentEntity, QDistinct> {
  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QDistinct>
  distinctByCategory({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'category', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QDistinct>
  distinctByCommentId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'commentId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QDistinct>
  distinctByGroupName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'groupName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QDistinct>
  distinctByLastUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastUpdatedAt');
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QDistinct>
  distinctByMatchGroupId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'matchGroupId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QDistinct>
  distinctByOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'order');
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QDistinct>
  distinctBySyncState() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncState');
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QDistinct>
  distinctByText({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'text', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MatchCommentEntity, MatchCommentEntity, QDistinct>
  distinctByTournamentId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tournamentId', caseSensitive: caseSensitive);
    });
  }
}

extension MatchCommentEntityQueryProperty
    on QueryBuilder<MatchCommentEntity, MatchCommentEntity, QQueryProperty> {
  QueryBuilder<MatchCommentEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<MatchCommentEntity, String?, QQueryOperations>
  categoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'category');
    });
  }

  QueryBuilder<MatchCommentEntity, String, QQueryOperations>
  commentIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'commentId');
    });
  }

  QueryBuilder<MatchCommentEntity, String?, QQueryOperations>
  groupNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'groupName');
    });
  }

  QueryBuilder<MatchCommentEntity, DateTime?, QQueryOperations>
  lastUpdatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastUpdatedAt');
    });
  }

  QueryBuilder<MatchCommentEntity, String?, QQueryOperations>
  matchGroupIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'matchGroupId');
    });
  }

  QueryBuilder<MatchCommentEntity, double, QQueryOperations> orderProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'order');
    });
  }

  QueryBuilder<MatchCommentEntity, SyncState, QQueryOperations>
  syncStateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncState');
    });
  }

  QueryBuilder<MatchCommentEntity, String, QQueryOperations> textProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'text');
    });
  }

  QueryBuilder<MatchCommentEntity, String?, QQueryOperations>
  tournamentIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tournamentId');
    });
  }
}
