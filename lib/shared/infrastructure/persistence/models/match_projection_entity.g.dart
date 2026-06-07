// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_projection_entity.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetMatchProjectionEntityCollection on Isar {
  IsarCollection<MatchProjectionEntity> get matchProjectionEntitys =>
      this.collection();
}

const MatchProjectionEntitySchema = CollectionSchema(
  name: r'MatchProjectionEntity',
  id: -4754560425679175056,
  properties: {
    r'category': PropertySchema(
      id: 0,
      name: r'category',
      type: IsarType.string,
    ),
    r'groupName': PropertySchema(
      id: 1,
      name: r'groupName',
      type: IsarType.string,
    ),
    r'lastUpdatedAt': PropertySchema(
      id: 2,
      name: r'lastUpdatedAt',
      type: IsarType.dateTime,
    ),
    r'matchId': PropertySchema(id: 3, name: r'matchId', type: IsarType.string),
    r'matchOrder': PropertySchema(
      id: 4,
      name: r'matchOrder',
      type: IsarType.long,
    ),
    r'matchType': PropertySchema(
      id: 5,
      name: r'matchType',
      type: IsarType.string,
    ),
    r'note': PropertySchema(id: 6, name: r'note', type: IsarType.string),
    r'redName': PropertySchema(id: 7, name: r'redName', type: IsarType.string),
    r'redScore': PropertySchema(id: 8, name: r'redScore', type: IsarType.long),
    r'refereeNames': PropertySchema(
      id: 9,
      name: r'refereeNames',
      type: IsarType.string,
    ),
    r'status': PropertySchema(id: 10, name: r'status', type: IsarType.string),
    r'tournamentId': PropertySchema(
      id: 11,
      name: r'tournamentId',
      type: IsarType.string,
    ),
    r'whiteName': PropertySchema(
      id: 12,
      name: r'whiteName',
      type: IsarType.string,
    ),
    r'whiteScore': PropertySchema(
      id: 13,
      name: r'whiteScore',
      type: IsarType.long,
    ),
    r'winnerName': PropertySchema(
      id: 14,
      name: r'winnerName',
      type: IsarType.string,
    ),
  },

  estimateSize: _matchProjectionEntityEstimateSize,
  serialize: _matchProjectionEntitySerialize,
  deserialize: _matchProjectionEntityDeserialize,
  deserializeProp: _matchProjectionEntityDeserializeProp,
  idName: r'id',
  indexes: {
    r'matchId': IndexSchema(
      id: -6517933327003962923,
      name: r'matchId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'matchId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _matchProjectionEntityGetId,
  getLinks: _matchProjectionEntityGetLinks,
  attach: _matchProjectionEntityAttach,
  version: '3.3.2',
);

int _matchProjectionEntityEstimateSize(
  MatchProjectionEntity object,
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
  {
    final value = object.groupName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.matchId.length * 3;
  {
    final value = object.matchType;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.note;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.redName.length * 3;
  {
    final value = object.refereeNames;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.status.length * 3;
  bytesCount += 3 + object.tournamentId.length * 3;
  bytesCount += 3 + object.whiteName.length * 3;
  {
    final value = object.winnerName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _matchProjectionEntitySerialize(
  MatchProjectionEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.category);
  writer.writeString(offsets[1], object.groupName);
  writer.writeDateTime(offsets[2], object.lastUpdatedAt);
  writer.writeString(offsets[3], object.matchId);
  writer.writeLong(offsets[4], object.matchOrder);
  writer.writeString(offsets[5], object.matchType);
  writer.writeString(offsets[6], object.note);
  writer.writeString(offsets[7], object.redName);
  writer.writeLong(offsets[8], object.redScore);
  writer.writeString(offsets[9], object.refereeNames);
  writer.writeString(offsets[10], object.status);
  writer.writeString(offsets[11], object.tournamentId);
  writer.writeString(offsets[12], object.whiteName);
  writer.writeLong(offsets[13], object.whiteScore);
  writer.writeString(offsets[14], object.winnerName);
}

MatchProjectionEntity _matchProjectionEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = MatchProjectionEntity();
  object.category = reader.readStringOrNull(offsets[0]);
  object.groupName = reader.readStringOrNull(offsets[1]);
  object.id = id;
  object.lastUpdatedAt = reader.readDateTime(offsets[2]);
  object.matchId = reader.readString(offsets[3]);
  object.matchOrder = reader.readLong(offsets[4]);
  object.matchType = reader.readStringOrNull(offsets[5]);
  object.note = reader.readStringOrNull(offsets[6]);
  object.redName = reader.readString(offsets[7]);
  object.redScore = reader.readLong(offsets[8]);
  object.refereeNames = reader.readStringOrNull(offsets[9]);
  object.status = reader.readString(offsets[10]);
  object.tournamentId = reader.readString(offsets[11]);
  object.whiteName = reader.readString(offsets[12]);
  object.whiteScore = reader.readLong(offsets[13]);
  object.winnerName = reader.readStringOrNull(offsets[14]);
  return object;
}

P _matchProjectionEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    case 11:
      return (reader.readString(offset)) as P;
    case 12:
      return (reader.readString(offset)) as P;
    case 13:
      return (reader.readLong(offset)) as P;
    case 14:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _matchProjectionEntityGetId(MatchProjectionEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _matchProjectionEntityGetLinks(
  MatchProjectionEntity object,
) {
  return [];
}

void _matchProjectionEntityAttach(
  IsarCollection<dynamic> col,
  Id id,
  MatchProjectionEntity object,
) {
  object.id = id;
}

extension MatchProjectionEntityByIndex
    on IsarCollection<MatchProjectionEntity> {
  Future<MatchProjectionEntity?> getByMatchId(String matchId) {
    return getByIndex(r'matchId', [matchId]);
  }

  MatchProjectionEntity? getByMatchIdSync(String matchId) {
    return getByIndexSync(r'matchId', [matchId]);
  }

  Future<bool> deleteByMatchId(String matchId) {
    return deleteByIndex(r'matchId', [matchId]);
  }

  bool deleteByMatchIdSync(String matchId) {
    return deleteByIndexSync(r'matchId', [matchId]);
  }

  Future<List<MatchProjectionEntity?>> getAllByMatchId(
    List<String> matchIdValues,
  ) {
    final values = matchIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'matchId', values);
  }

  List<MatchProjectionEntity?> getAllByMatchIdSync(List<String> matchIdValues) {
    final values = matchIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'matchId', values);
  }

  Future<int> deleteAllByMatchId(List<String> matchIdValues) {
    final values = matchIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'matchId', values);
  }

  int deleteAllByMatchIdSync(List<String> matchIdValues) {
    final values = matchIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'matchId', values);
  }

  Future<Id> putByMatchId(MatchProjectionEntity object) {
    return putByIndex(r'matchId', object);
  }

  Id putByMatchIdSync(MatchProjectionEntity object, {bool saveLinks = true}) {
    return putByIndexSync(r'matchId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByMatchId(List<MatchProjectionEntity> objects) {
    return putAllByIndex(r'matchId', objects);
  }

  List<Id> putAllByMatchIdSync(
    List<MatchProjectionEntity> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'matchId', objects, saveLinks: saveLinks);
  }
}

extension MatchProjectionEntityQueryWhereSort
    on QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QWhere> {
  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterWhere>
  anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension MatchProjectionEntityQueryWhere
    on
        QueryBuilder<
          MatchProjectionEntity,
          MatchProjectionEntity,
          QWhereClause
        > {
  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterWhereClause>
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

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterWhereClause>
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

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterWhereClause>
  matchIdEqualTo(String matchId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'matchId', value: [matchId]),
      );
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterWhereClause>
  matchIdNotEqualTo(String matchId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'matchId',
                lower: [],
                upper: [matchId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'matchId',
                lower: [matchId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'matchId',
                lower: [matchId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'matchId',
                lower: [],
                upper: [matchId],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension MatchProjectionEntityQueryFilter
    on
        QueryBuilder<
          MatchProjectionEntity,
          MatchProjectionEntity,
          QFilterCondition
        > {
  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  categoryIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'category'),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  categoryIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'category'),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  categoryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'category', value: ''),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  categoryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'category', value: ''),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  groupNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'groupName'),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  groupNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'groupName'),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  groupNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'groupName', value: ''),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  groupNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'groupName', value: ''),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  lastUpdatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastUpdatedAt', value: value),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  lastUpdatedAtGreaterThan(DateTime value, {bool include = false}) {
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

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  lastUpdatedAtLessThan(DateTime value, {bool include = false}) {
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

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  lastUpdatedAtBetween(
    DateTime lower,
    DateTime upper, {
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

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  matchIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'matchId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  matchIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'matchId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  matchIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'matchId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  matchIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'matchId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  matchIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'matchId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  matchIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'matchId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  matchIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'matchId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  matchIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'matchId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  matchIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'matchId', value: ''),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  matchIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'matchId', value: ''),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  matchOrderEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'matchOrder', value: value),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  matchOrderGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'matchOrder',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  matchOrderLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'matchOrder',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  matchOrderBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'matchOrder',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  matchTypeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'matchType'),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  matchTypeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'matchType'),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  matchTypeEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'matchType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  matchTypeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'matchType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  matchTypeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'matchType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  matchTypeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'matchType',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  matchTypeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'matchType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  matchTypeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'matchType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  matchTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'matchType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  matchTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'matchType',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  matchTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'matchType', value: ''),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  matchTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'matchType', value: ''),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  noteIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'note'),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  noteIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'note'),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  noteEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'note',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  noteGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'note',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  noteLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'note',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  noteBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'note',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  noteStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'note',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  noteEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'note',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  noteContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'note',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  noteMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'note',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  noteIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'note', value: ''),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  noteIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'note', value: ''),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  redNameEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'redName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  redNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'redName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  redNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'redName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  redNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'redName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  redNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'redName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  redNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'redName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  redNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'redName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  redNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'redName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  redNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'redName', value: ''),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  redNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'redName', value: ''),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  redScoreEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'redScore', value: value),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  redScoreGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'redScore',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  redScoreLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'redScore',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  redScoreBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'redScore',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  refereeNamesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'refereeNames'),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  refereeNamesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'refereeNames'),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  refereeNamesEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'refereeNames',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  refereeNamesGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'refereeNames',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  refereeNamesLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'refereeNames',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  refereeNamesBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'refereeNames',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  refereeNamesStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'refereeNames',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  refereeNamesEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'refereeNames',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  refereeNamesContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'refereeNames',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  refereeNamesMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'refereeNames',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  refereeNamesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'refereeNames', value: ''),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  refereeNamesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'refereeNames', value: ''),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  statusEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  statusGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  statusLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  statusBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'status',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  statusStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  statusEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  statusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  statusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'status',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'status', value: ''),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'status', value: ''),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  tournamentIdEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  tournamentIdGreaterThan(
    String value, {
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

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  tournamentIdLessThan(
    String value, {
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

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  tournamentIdBetween(
    String lower,
    String upper, {
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

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  tournamentIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'tournamentId', value: ''),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  tournamentIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'tournamentId', value: ''),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  whiteNameEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'whiteName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  whiteNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'whiteName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  whiteNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'whiteName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  whiteNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'whiteName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  whiteNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'whiteName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  whiteNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'whiteName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  whiteNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'whiteName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  whiteNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'whiteName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  whiteNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'whiteName', value: ''),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  whiteNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'whiteName', value: ''),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  whiteScoreEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'whiteScore', value: value),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  whiteScoreGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'whiteScore',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  whiteScoreLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'whiteScore',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  whiteScoreBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'whiteScore',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  winnerNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'winnerName'),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  winnerNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'winnerName'),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  winnerNameEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'winnerName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  winnerNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'winnerName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  winnerNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'winnerName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  winnerNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'winnerName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  winnerNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'winnerName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  winnerNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'winnerName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  winnerNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'winnerName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  winnerNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'winnerName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  winnerNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'winnerName', value: ''),
      );
    });
  }

  QueryBuilder<
    MatchProjectionEntity,
    MatchProjectionEntity,
    QAfterFilterCondition
  >
  winnerNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'winnerName', value: ''),
      );
    });
  }
}

extension MatchProjectionEntityQueryObject
    on
        QueryBuilder<
          MatchProjectionEntity,
          MatchProjectionEntity,
          QFilterCondition
        > {}

extension MatchProjectionEntityQueryLinks
    on
        QueryBuilder<
          MatchProjectionEntity,
          MatchProjectionEntity,
          QFilterCondition
        > {}

extension MatchProjectionEntityQuerySortBy
    on QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QSortBy> {
  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  sortByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  sortByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  sortByGroupName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupName', Sort.asc);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  sortByGroupNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupName', Sort.desc);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  sortByLastUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdatedAt', Sort.asc);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  sortByLastUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdatedAt', Sort.desc);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  sortByMatchId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchId', Sort.asc);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  sortByMatchIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchId', Sort.desc);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  sortByMatchOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchOrder', Sort.asc);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  sortByMatchOrderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchOrder', Sort.desc);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  sortByMatchType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchType', Sort.asc);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  sortByMatchTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchType', Sort.desc);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  sortByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  sortByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  sortByRedName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'redName', Sort.asc);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  sortByRedNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'redName', Sort.desc);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  sortByRedScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'redScore', Sort.asc);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  sortByRedScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'redScore', Sort.desc);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  sortByRefereeNames() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'refereeNames', Sort.asc);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  sortByRefereeNamesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'refereeNames', Sort.desc);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  sortByTournamentId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tournamentId', Sort.asc);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  sortByTournamentIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tournamentId', Sort.desc);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  sortByWhiteName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'whiteName', Sort.asc);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  sortByWhiteNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'whiteName', Sort.desc);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  sortByWhiteScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'whiteScore', Sort.asc);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  sortByWhiteScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'whiteScore', Sort.desc);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  sortByWinnerName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'winnerName', Sort.asc);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  sortByWinnerNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'winnerName', Sort.desc);
    });
  }
}

extension MatchProjectionEntityQuerySortThenBy
    on QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QSortThenBy> {
  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  thenByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  thenByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  thenByGroupName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupName', Sort.asc);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  thenByGroupNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupName', Sort.desc);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  thenByLastUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdatedAt', Sort.asc);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  thenByLastUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdatedAt', Sort.desc);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  thenByMatchId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchId', Sort.asc);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  thenByMatchIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchId', Sort.desc);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  thenByMatchOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchOrder', Sort.asc);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  thenByMatchOrderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchOrder', Sort.desc);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  thenByMatchType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchType', Sort.asc);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  thenByMatchTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchType', Sort.desc);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  thenByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  thenByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  thenByRedName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'redName', Sort.asc);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  thenByRedNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'redName', Sort.desc);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  thenByRedScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'redScore', Sort.asc);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  thenByRedScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'redScore', Sort.desc);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  thenByRefereeNames() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'refereeNames', Sort.asc);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  thenByRefereeNamesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'refereeNames', Sort.desc);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  thenByTournamentId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tournamentId', Sort.asc);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  thenByTournamentIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tournamentId', Sort.desc);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  thenByWhiteName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'whiteName', Sort.asc);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  thenByWhiteNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'whiteName', Sort.desc);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  thenByWhiteScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'whiteScore', Sort.asc);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  thenByWhiteScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'whiteScore', Sort.desc);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  thenByWinnerName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'winnerName', Sort.asc);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QAfterSortBy>
  thenByWinnerNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'winnerName', Sort.desc);
    });
  }
}

extension MatchProjectionEntityQueryWhereDistinct
    on QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QDistinct> {
  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QDistinct>
  distinctByCategory({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'category', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QDistinct>
  distinctByGroupName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'groupName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QDistinct>
  distinctByLastUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastUpdatedAt');
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QDistinct>
  distinctByMatchId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'matchId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QDistinct>
  distinctByMatchOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'matchOrder');
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QDistinct>
  distinctByMatchType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'matchType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QDistinct>
  distinctByNote({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'note', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QDistinct>
  distinctByRedName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'redName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QDistinct>
  distinctByRedScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'redScore');
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QDistinct>
  distinctByRefereeNames({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'refereeNames', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QDistinct>
  distinctByStatus({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QDistinct>
  distinctByTournamentId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tournamentId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QDistinct>
  distinctByWhiteName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'whiteName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QDistinct>
  distinctByWhiteScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'whiteScore');
    });
  }

  QueryBuilder<MatchProjectionEntity, MatchProjectionEntity, QDistinct>
  distinctByWinnerName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'winnerName', caseSensitive: caseSensitive);
    });
  }
}

extension MatchProjectionEntityQueryProperty
    on
        QueryBuilder<
          MatchProjectionEntity,
          MatchProjectionEntity,
          QQueryProperty
        > {
  QueryBuilder<MatchProjectionEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<MatchProjectionEntity, String?, QQueryOperations>
  categoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'category');
    });
  }

  QueryBuilder<MatchProjectionEntity, String?, QQueryOperations>
  groupNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'groupName');
    });
  }

  QueryBuilder<MatchProjectionEntity, DateTime, QQueryOperations>
  lastUpdatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastUpdatedAt');
    });
  }

  QueryBuilder<MatchProjectionEntity, String, QQueryOperations>
  matchIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'matchId');
    });
  }

  QueryBuilder<MatchProjectionEntity, int, QQueryOperations>
  matchOrderProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'matchOrder');
    });
  }

  QueryBuilder<MatchProjectionEntity, String?, QQueryOperations>
  matchTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'matchType');
    });
  }

  QueryBuilder<MatchProjectionEntity, String?, QQueryOperations>
  noteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'note');
    });
  }

  QueryBuilder<MatchProjectionEntity, String, QQueryOperations>
  redNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'redName');
    });
  }

  QueryBuilder<MatchProjectionEntity, int, QQueryOperations>
  redScoreProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'redScore');
    });
  }

  QueryBuilder<MatchProjectionEntity, String?, QQueryOperations>
  refereeNamesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'refereeNames');
    });
  }

  QueryBuilder<MatchProjectionEntity, String, QQueryOperations>
  statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<MatchProjectionEntity, String, QQueryOperations>
  tournamentIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tournamentId');
    });
  }

  QueryBuilder<MatchProjectionEntity, String, QQueryOperations>
  whiteNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'whiteName');
    });
  }

  QueryBuilder<MatchProjectionEntity, int, QQueryOperations>
  whiteScoreProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'whiteScore');
    });
  }

  QueryBuilder<MatchProjectionEntity, String?, QQueryOperations>
  winnerNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'winnerName');
    });
  }
}
