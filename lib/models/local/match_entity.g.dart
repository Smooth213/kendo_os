// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_entity.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetMatchEntityCollection on Isar {
  IsarCollection<MatchEntity> get matchEntitys => this.collection();
}

const MatchEntitySchema = CollectionSchema(
  name: r'MatchEntity',
  id: 1961780345530759423,
  properties: {
    r'category': PropertySchema(
      id: 0,
      name: r'category',
      type: IsarType.string,
    ),
    r'countForStandings': PropertySchema(
      id: 1,
      name: r'countForStandings',
      type: IsarType.bool,
    ),
    r'events': PropertySchema(
      id: 2,
      name: r'events',
      type: IsarType.objectList,

      target: r'ScoreEventEntity',
    ),
    r'extensionCount': PropertySchema(
      id: 3,
      name: r'extensionCount',
      type: IsarType.long,
    ),
    r'extensionTimeMinutes': PropertySchema(
      id: 4,
      name: r'extensionTimeMinutes',
      type: IsarType.long,
    ),
    r'firestoreId': PropertySchema(
      id: 5,
      name: r'firestoreId',
      type: IsarType.string,
    ),
    r'groupName': PropertySchema(
      id: 6,
      name: r'groupName',
      type: IsarType.string,
    ),
    r'hasExtension': PropertySchema(
      id: 7,
      name: r'hasExtension',
      type: IsarType.bool,
    ),
    r'hasHantei': PropertySchema(
      id: 8,
      name: r'hasHantei',
      type: IsarType.bool,
    ),
    r'isAutoAssigned': PropertySchema(
      id: 9,
      name: r'isAutoAssigned',
      type: IsarType.bool,
    ),
    r'isDirty': PropertySchema(id: 10, name: r'isDirty', type: IsarType.bool),
    r'isKachinuki': PropertySchema(
      id: 11,
      name: r'isKachinuki',
      type: IsarType.bool,
    ),
    r'isRunningTime': PropertySchema(
      id: 12,
      name: r'isRunningTime',
      type: IsarType.bool,
    ),
    r'lastUpdatedAt': PropertySchema(
      id: 13,
      name: r'lastUpdatedAt',
      type: IsarType.dateTime,
    ),
    r'matchOrder': PropertySchema(
      id: 14,
      name: r'matchOrder',
      type: IsarType.long,
    ),
    r'matchTimeMinutes': PropertySchema(
      id: 15,
      name: r'matchTimeMinutes',
      type: IsarType.long,
    ),
    r'matchType': PropertySchema(
      id: 16,
      name: r'matchType',
      type: IsarType.string,
    ),
    r'note': PropertySchema(id: 17, name: r'note', type: IsarType.string),
    r'order': PropertySchema(id: 18, name: r'order', type: IsarType.double),
    r'redName': PropertySchema(id: 19, name: r'redName', type: IsarType.string),
    r'redRemaining': PropertySchema(
      id: 20,
      name: r'redRemaining',
      type: IsarType.stringList,
    ),
    r'redScore': PropertySchema(id: 21, name: r'redScore', type: IsarType.long),
    r'refereeNames': PropertySchema(
      id: 22,
      name: r'refereeNames',
      type: IsarType.stringList,
    ),
    r'remainingSeconds': PropertySchema(
      id: 23,
      name: r'remainingSeconds',
      type: IsarType.long,
    ),
    r'ruleJson': PropertySchema(
      id: 24,
      name: r'ruleJson',
      type: IsarType.string,
    ),
    r'scorerId': PropertySchema(
      id: 25,
      name: r'scorerId',
      type: IsarType.string,
    ),
    r'snapshots': PropertySchema(
      id: 26,
      name: r'snapshots',
      type: IsarType.objectList,

      target: r'MatchSnapshotEntity',
    ),
    r'source': PropertySchema(id: 27, name: r'source', type: IsarType.string),
    r'status': PropertySchema(id: 28, name: r'status', type: IsarType.string),
    r'timerIsRunning': PropertySchema(
      id: 29,
      name: r'timerIsRunning',
      type: IsarType.bool,
    ),
    r'tournamentId': PropertySchema(
      id: 30,
      name: r'tournamentId',
      type: IsarType.string,
    ),
    r'version': PropertySchema(id: 31, name: r'version', type: IsarType.long),
    r'whiteName': PropertySchema(
      id: 32,
      name: r'whiteName',
      type: IsarType.string,
    ),
    r'whiteRemaining': PropertySchema(
      id: 33,
      name: r'whiteRemaining',
      type: IsarType.stringList,
    ),
    r'whiteScore': PropertySchema(
      id: 34,
      name: r'whiteScore',
      type: IsarType.long,
    ),
  },

  estimateSize: _matchEntityEstimateSize,
  serialize: _matchEntitySerialize,
  deserialize: _matchEntityDeserialize,
  deserializeProp: _matchEntityDeserializeProp,
  idName: r'id',
  indexes: {
    r'firestoreId': IndexSchema(
      id: 1863077355534729001,
      name: r'firestoreId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'firestoreId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {
    r'ScoreEventEntity': ScoreEventEntitySchema,
    r'MatchSnapshotEntity': MatchSnapshotEntitySchema,
  },

  getId: _matchEntityGetId,
  getLinks: _matchEntityGetLinks,
  attach: _matchEntityAttach,
  version: '3.3.2',
);

int _matchEntityEstimateSize(
  MatchEntity object,
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
  bytesCount += 3 + object.events.length * 3;
  {
    final offsets = allOffsets[ScoreEventEntity]!;
    for (var i = 0; i < object.events.length; i++) {
      final value = object.events[i];
      bytesCount += ScoreEventEntitySchema.estimateSize(
        value,
        offsets,
        allOffsets,
      );
    }
  }
  bytesCount += 3 + object.firestoreId.length * 3;
  {
    final value = object.groupName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.matchType.length * 3;
  bytesCount += 3 + object.note.length * 3;
  bytesCount += 3 + object.redName.length * 3;
  bytesCount += 3 + object.redRemaining.length * 3;
  {
    for (var i = 0; i < object.redRemaining.length; i++) {
      final value = object.redRemaining[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.refereeNames.length * 3;
  {
    for (var i = 0; i < object.refereeNames.length; i++) {
      final value = object.refereeNames[i];
      bytesCount += value.length * 3;
    }
  }
  {
    final value = object.ruleJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.scorerId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.snapshots.length * 3;
  {
    final offsets = allOffsets[MatchSnapshotEntity]!;
    for (var i = 0; i < object.snapshots.length; i++) {
      final value = object.snapshots[i];
      bytesCount += MatchSnapshotEntitySchema.estimateSize(
        value,
        offsets,
        allOffsets,
      );
    }
  }
  bytesCount += 3 + object.source.length * 3;
  bytesCount += 3 + object.status.length * 3;
  {
    final value = object.tournamentId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.whiteName.length * 3;
  bytesCount += 3 + object.whiteRemaining.length * 3;
  {
    for (var i = 0; i < object.whiteRemaining.length; i++) {
      final value = object.whiteRemaining[i];
      bytesCount += value.length * 3;
    }
  }
  return bytesCount;
}

void _matchEntitySerialize(
  MatchEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.category);
  writer.writeBool(offsets[1], object.countForStandings);
  writer.writeObjectList<ScoreEventEntity>(
    offsets[2],
    allOffsets,
    ScoreEventEntitySchema.serialize,
    object.events,
  );
  writer.writeLong(offsets[3], object.extensionCount);
  writer.writeLong(offsets[4], object.extensionTimeMinutes);
  writer.writeString(offsets[5], object.firestoreId);
  writer.writeString(offsets[6], object.groupName);
  writer.writeBool(offsets[7], object.hasExtension);
  writer.writeBool(offsets[8], object.hasHantei);
  writer.writeBool(offsets[9], object.isAutoAssigned);
  writer.writeBool(offsets[10], object.isDirty);
  writer.writeBool(offsets[11], object.isKachinuki);
  writer.writeBool(offsets[12], object.isRunningTime);
  writer.writeDateTime(offsets[13], object.lastUpdatedAt);
  writer.writeLong(offsets[14], object.matchOrder);
  writer.writeLong(offsets[15], object.matchTimeMinutes);
  writer.writeString(offsets[16], object.matchType);
  writer.writeString(offsets[17], object.note);
  writer.writeDouble(offsets[18], object.order);
  writer.writeString(offsets[19], object.redName);
  writer.writeStringList(offsets[20], object.redRemaining);
  writer.writeLong(offsets[21], object.redScore);
  writer.writeStringList(offsets[22], object.refereeNames);
  writer.writeLong(offsets[23], object.remainingSeconds);
  writer.writeString(offsets[24], object.ruleJson);
  writer.writeString(offsets[25], object.scorerId);
  writer.writeObjectList<MatchSnapshotEntity>(
    offsets[26],
    allOffsets,
    MatchSnapshotEntitySchema.serialize,
    object.snapshots,
  );
  writer.writeString(offsets[27], object.source);
  writer.writeString(offsets[28], object.status);
  writer.writeBool(offsets[29], object.timerIsRunning);
  writer.writeString(offsets[30], object.tournamentId);
  writer.writeLong(offsets[31], object.version);
  writer.writeString(offsets[32], object.whiteName);
  writer.writeStringList(offsets[33], object.whiteRemaining);
  writer.writeLong(offsets[34], object.whiteScore);
}

MatchEntity _matchEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = MatchEntity();
  object.category = reader.readStringOrNull(offsets[0]);
  object.countForStandings = reader.readBool(offsets[1]);
  object.events =
      reader.readObjectList<ScoreEventEntity>(
        offsets[2],
        ScoreEventEntitySchema.deserialize,
        allOffsets,
        ScoreEventEntity(),
      ) ??
      [];
  object.extensionCount = reader.readLongOrNull(offsets[3]);
  object.extensionTimeMinutes = reader.readLongOrNull(offsets[4]);
  object.firestoreId = reader.readString(offsets[5]);
  object.groupName = reader.readStringOrNull(offsets[6]);
  object.hasExtension = reader.readBool(offsets[7]);
  object.hasHantei = reader.readBool(offsets[8]);
  object.id = id;
  object.isAutoAssigned = reader.readBool(offsets[9]);
  object.isDirty = reader.readBool(offsets[10]);
  object.isKachinuki = reader.readBool(offsets[11]);
  object.isRunningTime = reader.readBool(offsets[12]);
  object.lastUpdatedAt = reader.readDateTimeOrNull(offsets[13]);
  object.matchOrder = reader.readLongOrNull(offsets[14]);
  object.matchTimeMinutes = reader.readLong(offsets[15]);
  object.matchType = reader.readString(offsets[16]);
  object.note = reader.readString(offsets[17]);
  object.order = reader.readDouble(offsets[18]);
  object.redName = reader.readString(offsets[19]);
  object.redRemaining = reader.readStringList(offsets[20]) ?? [];
  object.redScore = reader.readLong(offsets[21]);
  object.refereeNames = reader.readStringList(offsets[22]) ?? [];
  object.remainingSeconds = reader.readLong(offsets[23]);
  object.ruleJson = reader.readStringOrNull(offsets[24]);
  object.scorerId = reader.readStringOrNull(offsets[25]);
  object.snapshots =
      reader.readObjectList<MatchSnapshotEntity>(
        offsets[26],
        MatchSnapshotEntitySchema.deserialize,
        allOffsets,
        MatchSnapshotEntity(),
      ) ??
      [];
  object.source = reader.readString(offsets[27]);
  object.status = reader.readString(offsets[28]);
  object.timerIsRunning = reader.readBool(offsets[29]);
  object.tournamentId = reader.readStringOrNull(offsets[30]);
  object.version = reader.readLong(offsets[31]);
  object.whiteName = reader.readString(offsets[32]);
  object.whiteRemaining = reader.readStringList(offsets[33]) ?? [];
  object.whiteScore = reader.readLong(offsets[34]);
  return object;
}

P _matchEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readBool(offset)) as P;
    case 2:
      return (reader.readObjectList<ScoreEventEntity>(
                offset,
                ScoreEventEntitySchema.deserialize,
                allOffsets,
                ScoreEventEntity(),
              ) ??
              [])
          as P;
    case 3:
      return (reader.readLongOrNull(offset)) as P;
    case 4:
      return (reader.readLongOrNull(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readBool(offset)) as P;
    case 8:
      return (reader.readBool(offset)) as P;
    case 9:
      return (reader.readBool(offset)) as P;
    case 10:
      return (reader.readBool(offset)) as P;
    case 11:
      return (reader.readBool(offset)) as P;
    case 12:
      return (reader.readBool(offset)) as P;
    case 13:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 14:
      return (reader.readLongOrNull(offset)) as P;
    case 15:
      return (reader.readLong(offset)) as P;
    case 16:
      return (reader.readString(offset)) as P;
    case 17:
      return (reader.readString(offset)) as P;
    case 18:
      return (reader.readDouble(offset)) as P;
    case 19:
      return (reader.readString(offset)) as P;
    case 20:
      return (reader.readStringList(offset) ?? []) as P;
    case 21:
      return (reader.readLong(offset)) as P;
    case 22:
      return (reader.readStringList(offset) ?? []) as P;
    case 23:
      return (reader.readLong(offset)) as P;
    case 24:
      return (reader.readStringOrNull(offset)) as P;
    case 25:
      return (reader.readStringOrNull(offset)) as P;
    case 26:
      return (reader.readObjectList<MatchSnapshotEntity>(
                offset,
                MatchSnapshotEntitySchema.deserialize,
                allOffsets,
                MatchSnapshotEntity(),
              ) ??
              [])
          as P;
    case 27:
      return (reader.readString(offset)) as P;
    case 28:
      return (reader.readString(offset)) as P;
    case 29:
      return (reader.readBool(offset)) as P;
    case 30:
      return (reader.readStringOrNull(offset)) as P;
    case 31:
      return (reader.readLong(offset)) as P;
    case 32:
      return (reader.readString(offset)) as P;
    case 33:
      return (reader.readStringList(offset) ?? []) as P;
    case 34:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _matchEntityGetId(MatchEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _matchEntityGetLinks(MatchEntity object) {
  return [];
}

void _matchEntityAttach(
  IsarCollection<dynamic> col,
  Id id,
  MatchEntity object,
) {
  object.id = id;
}

extension MatchEntityByIndex on IsarCollection<MatchEntity> {
  Future<MatchEntity?> getByFirestoreId(String firestoreId) {
    return getByIndex(r'firestoreId', [firestoreId]);
  }

  MatchEntity? getByFirestoreIdSync(String firestoreId) {
    return getByIndexSync(r'firestoreId', [firestoreId]);
  }

  Future<bool> deleteByFirestoreId(String firestoreId) {
    return deleteByIndex(r'firestoreId', [firestoreId]);
  }

  bool deleteByFirestoreIdSync(String firestoreId) {
    return deleteByIndexSync(r'firestoreId', [firestoreId]);
  }

  Future<List<MatchEntity?>> getAllByFirestoreId(
    List<String> firestoreIdValues,
  ) {
    final values = firestoreIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'firestoreId', values);
  }

  List<MatchEntity?> getAllByFirestoreIdSync(List<String> firestoreIdValues) {
    final values = firestoreIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'firestoreId', values);
  }

  Future<int> deleteAllByFirestoreId(List<String> firestoreIdValues) {
    final values = firestoreIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'firestoreId', values);
  }

  int deleteAllByFirestoreIdSync(List<String> firestoreIdValues) {
    final values = firestoreIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'firestoreId', values);
  }

  Future<Id> putByFirestoreId(MatchEntity object) {
    return putByIndex(r'firestoreId', object);
  }

  Id putByFirestoreIdSync(MatchEntity object, {bool saveLinks = true}) {
    return putByIndexSync(r'firestoreId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByFirestoreId(List<MatchEntity> objects) {
    return putAllByIndex(r'firestoreId', objects);
  }

  List<Id> putAllByFirestoreIdSync(
    List<MatchEntity> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'firestoreId', objects, saveLinks: saveLinks);
  }
}

extension MatchEntityQueryWhereSort
    on QueryBuilder<MatchEntity, MatchEntity, QWhere> {
  QueryBuilder<MatchEntity, MatchEntity, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension MatchEntityQueryWhere
    on QueryBuilder<MatchEntity, MatchEntity, QWhereClause> {
  QueryBuilder<MatchEntity, MatchEntity, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterWhereClause> idNotEqualTo(
    Id id,
  ) {
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterWhereClause> idBetween(
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterWhereClause> firestoreIdEqualTo(
    String firestoreId,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'firestoreId',
          value: [firestoreId],
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterWhereClause>
  firestoreIdNotEqualTo(String firestoreId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'firestoreId',
                lower: [],
                upper: [firestoreId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'firestoreId',
                lower: [firestoreId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'firestoreId',
                lower: [firestoreId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'firestoreId',
                lower: [],
                upper: [firestoreId],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension MatchEntityQueryFilter
    on QueryBuilder<MatchEntity, MatchEntity, QFilterCondition> {
  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  categoryIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'category'),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  categoryIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'category'),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition> categoryEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition> categoryBetween(
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition> categoryMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  categoryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'category', value: ''),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  categoryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'category', value: ''),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  countForStandingsEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'countForStandings', value: value),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  eventsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'events', length, true, length, true);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  eventsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'events', 0, true, 0, true);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  eventsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'events', 0, false, 999999, true);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  eventsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'events', 0, true, length, include);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  eventsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'events', length, include, 999999, true);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  eventsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'events',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  extensionCountIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'extensionCount'),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  extensionCountIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'extensionCount'),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  extensionCountEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'extensionCount', value: value),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  extensionCountGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'extensionCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  extensionCountLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'extensionCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  extensionCountBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'extensionCount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  extensionTimeMinutesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'extensionTimeMinutes'),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  extensionTimeMinutesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'extensionTimeMinutes'),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  extensionTimeMinutesEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'extensionTimeMinutes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  extensionTimeMinutesGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'extensionTimeMinutes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  extensionTimeMinutesLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'extensionTimeMinutes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  extensionTimeMinutesBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'extensionTimeMinutes',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  firestoreIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'firestoreId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  firestoreIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'firestoreId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  firestoreIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'firestoreId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  firestoreIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'firestoreId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  firestoreIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'firestoreId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  firestoreIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'firestoreId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  firestoreIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'firestoreId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  firestoreIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'firestoreId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  firestoreIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'firestoreId', value: ''),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  firestoreIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'firestoreId', value: ''),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  groupNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'groupName'),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  groupNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'groupName'),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  groupNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'groupName', value: ''),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  groupNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'groupName', value: ''),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  hasExtensionEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'hasExtension', value: value),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  hasHanteiEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'hasHantei', value: value),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition> idBetween(
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  isAutoAssignedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isAutoAssigned', value: value),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition> isDirtyEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isDirty', value: value),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  isKachinukiEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isKachinuki', value: value),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  isRunningTimeEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isRunningTime', value: value),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  lastUpdatedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'lastUpdatedAt'),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  lastUpdatedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'lastUpdatedAt'),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  lastUpdatedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastUpdatedAt', value: value),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  matchOrderIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'matchOrder'),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  matchOrderIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'matchOrder'),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  matchOrderEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'matchOrder', value: value),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  matchOrderGreaterThan(int? value, {bool include = false}) {
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  matchOrderLessThan(int? value, {bool include = false}) {
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  matchOrderBetween(
    int? lower,
    int? upper, {
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  matchTimeMinutesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'matchTimeMinutes', value: value),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  matchTimeMinutesGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'matchTimeMinutes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  matchTimeMinutesLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'matchTimeMinutes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  matchTimeMinutesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'matchTimeMinutes',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  matchTypeEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  matchTypeGreaterThan(
    String value, {
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  matchTypeLessThan(
    String value, {
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  matchTypeBetween(
    String lower,
    String upper, {
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  matchTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'matchType', value: ''),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  matchTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'matchType', value: ''),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition> noteEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition> noteGreaterThan(
    String value, {
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition> noteLessThan(
    String value, {
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition> noteBetween(
    String lower,
    String upper, {
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition> noteStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition> noteEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition> noteContains(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition> noteMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition> noteIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'note', value: ''),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  noteIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'note', value: ''),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition> orderEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition> orderLessThan(
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition> orderBetween(
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition> redNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition> redNameLessThan(
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition> redNameBetween(
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition> redNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition> redNameContains(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition> redNameMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  redNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'redName', value: ''),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  redNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'redName', value: ''),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  redRemainingElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'redRemaining',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  redRemainingElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'redRemaining',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  redRemainingElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'redRemaining',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  redRemainingElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'redRemaining',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  redRemainingElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'redRemaining',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  redRemainingElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'redRemaining',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  redRemainingElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'redRemaining',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  redRemainingElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'redRemaining',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  redRemainingElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'redRemaining', value: ''),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  redRemainingElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'redRemaining', value: ''),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  redRemainingLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'redRemaining', length, true, length, true);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  redRemainingIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'redRemaining', 0, true, 0, true);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  redRemainingIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'redRemaining', 0, false, 999999, true);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  redRemainingLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'redRemaining', 0, true, length, include);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  redRemainingLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'redRemaining', length, include, 999999, true);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  redRemainingLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'redRemaining',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition> redScoreEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'redScore', value: value),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition> redScoreBetween(
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  refereeNamesElementEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  refereeNamesElementGreaterThan(
    String value, {
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  refereeNamesElementLessThan(
    String value, {
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  refereeNamesElementBetween(
    String lower,
    String upper, {
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  refereeNamesElementStartsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  refereeNamesElementEndsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  refereeNamesElementContains(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  refereeNamesElementMatches(String pattern, {bool caseSensitive = true}) {
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  refereeNamesElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'refereeNames', value: ''),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  refereeNamesElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'refereeNames', value: ''),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  refereeNamesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'refereeNames', length, true, length, true);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  refereeNamesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'refereeNames', 0, true, 0, true);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  refereeNamesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'refereeNames', 0, false, 999999, true);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  refereeNamesLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'refereeNames', 0, true, length, include);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  refereeNamesLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'refereeNames', length, include, 999999, true);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  refereeNamesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'refereeNames',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  remainingSecondsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'remainingSeconds', value: value),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  remainingSecondsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'remainingSeconds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  remainingSecondsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'remainingSeconds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  remainingSecondsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'remainingSeconds',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  ruleJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'ruleJson'),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  ruleJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'ruleJson'),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition> ruleJsonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'ruleJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  ruleJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'ruleJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  ruleJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'ruleJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition> ruleJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'ruleJson',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  ruleJsonStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'ruleJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  ruleJsonEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'ruleJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  ruleJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'ruleJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition> ruleJsonMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'ruleJson',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  ruleJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'ruleJson', value: ''),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  ruleJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'ruleJson', value: ''),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  scorerIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'scorerId'),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  scorerIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'scorerId'),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition> scorerIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'scorerId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  scorerIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'scorerId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  scorerIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'scorerId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition> scorerIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'scorerId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  scorerIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'scorerId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  scorerIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'scorerId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  scorerIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'scorerId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition> scorerIdMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'scorerId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  scorerIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'scorerId', value: ''),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  scorerIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'scorerId', value: ''),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  snapshotsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'snapshots', length, true, length, true);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  snapshotsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'snapshots', 0, true, 0, true);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  snapshotsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'snapshots', 0, false, 999999, true);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  snapshotsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'snapshots', 0, true, length, include);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  snapshotsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'snapshots', length, include, 999999, true);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  snapshotsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'snapshots',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition> sourceEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'source',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  sourceGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'source',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition> sourceLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'source',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition> sourceBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'source',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  sourceStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'source',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition> sourceEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'source',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition> sourceContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'source',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition> sourceMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'source',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  sourceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'source', value: ''),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  sourceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'source', value: ''),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition> statusEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition> statusLessThan(
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition> statusBetween(
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition> statusEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition> statusContains(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition> statusMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'status', value: ''),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'status', value: ''),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  timerIsRunningEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'timerIsRunning', value: value),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  tournamentIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'tournamentId'),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  tournamentIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'tournamentId'),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  tournamentIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'tournamentId', value: ''),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  tournamentIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'tournamentId', value: ''),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition> versionEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'version', value: value),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  versionGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'version',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition> versionLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'version',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition> versionBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'version',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  whiteNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'whiteName', value: ''),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  whiteNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'whiteName', value: ''),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  whiteRemainingElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'whiteRemaining',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  whiteRemainingElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'whiteRemaining',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  whiteRemainingElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'whiteRemaining',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  whiteRemainingElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'whiteRemaining',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  whiteRemainingElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'whiteRemaining',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  whiteRemainingElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'whiteRemaining',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  whiteRemainingElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'whiteRemaining',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  whiteRemainingElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'whiteRemaining',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  whiteRemainingElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'whiteRemaining', value: ''),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  whiteRemainingElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'whiteRemaining', value: ''),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  whiteRemainingLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'whiteRemaining', length, true, length, true);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  whiteRemainingIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'whiteRemaining', 0, true, 0, true);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  whiteRemainingIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'whiteRemaining', 0, false, 999999, true);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  whiteRemainingLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'whiteRemaining', 0, true, length, include);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  whiteRemainingLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'whiteRemaining', length, include, 999999, true);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  whiteRemainingLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'whiteRemaining',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  whiteScoreEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'whiteScore', value: value),
      );
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
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

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
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
}

extension MatchEntityQueryObject
    on QueryBuilder<MatchEntity, MatchEntity, QFilterCondition> {
  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition> eventsElement(
    FilterQuery<ScoreEventEntity> q,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'events');
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterFilterCondition>
  snapshotsElement(FilterQuery<MatchSnapshotEntity> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'snapshots');
    });
  }
}

extension MatchEntityQueryLinks
    on QueryBuilder<MatchEntity, MatchEntity, QFilterCondition> {}

extension MatchEntityQuerySortBy
    on QueryBuilder<MatchEntity, MatchEntity, QSortBy> {
  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> sortByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> sortByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy>
  sortByCountForStandings() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'countForStandings', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy>
  sortByCountForStandingsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'countForStandings', Sort.desc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> sortByExtensionCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'extensionCount', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy>
  sortByExtensionCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'extensionCount', Sort.desc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy>
  sortByExtensionTimeMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'extensionTimeMinutes', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy>
  sortByExtensionTimeMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'extensionTimeMinutes', Sort.desc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> sortByFirestoreId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firestoreId', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> sortByFirestoreIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firestoreId', Sort.desc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> sortByGroupName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupName', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> sortByGroupNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupName', Sort.desc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> sortByHasExtension() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasExtension', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy>
  sortByHasExtensionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasExtension', Sort.desc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> sortByHasHantei() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasHantei', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> sortByHasHanteiDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasHantei', Sort.desc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> sortByIsAutoAssigned() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isAutoAssigned', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy>
  sortByIsAutoAssignedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isAutoAssigned', Sort.desc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> sortByIsDirty() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDirty', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> sortByIsDirtyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDirty', Sort.desc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> sortByIsKachinuki() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isKachinuki', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> sortByIsKachinukiDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isKachinuki', Sort.desc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> sortByIsRunningTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isRunningTime', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy>
  sortByIsRunningTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isRunningTime', Sort.desc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> sortByLastUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdatedAt', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy>
  sortByLastUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdatedAt', Sort.desc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> sortByMatchOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchOrder', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> sortByMatchOrderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchOrder', Sort.desc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy>
  sortByMatchTimeMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchTimeMinutes', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy>
  sortByMatchTimeMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchTimeMinutes', Sort.desc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> sortByMatchType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchType', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> sortByMatchTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchType', Sort.desc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> sortByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> sortByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> sortByOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'order', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> sortByOrderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'order', Sort.desc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> sortByRedName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'redName', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> sortByRedNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'redName', Sort.desc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> sortByRedScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'redScore', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> sortByRedScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'redScore', Sort.desc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy>
  sortByRemainingSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remainingSeconds', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy>
  sortByRemainingSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remainingSeconds', Sort.desc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> sortByRuleJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ruleJson', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> sortByRuleJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ruleJson', Sort.desc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> sortByScorerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scorerId', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> sortByScorerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scorerId', Sort.desc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> sortBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> sortBySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.desc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> sortByTimerIsRunning() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timerIsRunning', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy>
  sortByTimerIsRunningDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timerIsRunning', Sort.desc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> sortByTournamentId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tournamentId', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy>
  sortByTournamentIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tournamentId', Sort.desc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> sortByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> sortByVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.desc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> sortByWhiteName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'whiteName', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> sortByWhiteNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'whiteName', Sort.desc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> sortByWhiteScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'whiteScore', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> sortByWhiteScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'whiteScore', Sort.desc);
    });
  }
}

extension MatchEntityQuerySortThenBy
    on QueryBuilder<MatchEntity, MatchEntity, QSortThenBy> {
  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> thenByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> thenByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy>
  thenByCountForStandings() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'countForStandings', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy>
  thenByCountForStandingsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'countForStandings', Sort.desc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> thenByExtensionCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'extensionCount', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy>
  thenByExtensionCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'extensionCount', Sort.desc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy>
  thenByExtensionTimeMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'extensionTimeMinutes', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy>
  thenByExtensionTimeMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'extensionTimeMinutes', Sort.desc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> thenByFirestoreId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firestoreId', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> thenByFirestoreIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firestoreId', Sort.desc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> thenByGroupName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupName', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> thenByGroupNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupName', Sort.desc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> thenByHasExtension() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasExtension', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy>
  thenByHasExtensionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasExtension', Sort.desc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> thenByHasHantei() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasHantei', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> thenByHasHanteiDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasHantei', Sort.desc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> thenByIsAutoAssigned() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isAutoAssigned', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy>
  thenByIsAutoAssignedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isAutoAssigned', Sort.desc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> thenByIsDirty() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDirty', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> thenByIsDirtyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDirty', Sort.desc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> thenByIsKachinuki() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isKachinuki', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> thenByIsKachinukiDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isKachinuki', Sort.desc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> thenByIsRunningTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isRunningTime', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy>
  thenByIsRunningTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isRunningTime', Sort.desc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> thenByLastUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdatedAt', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy>
  thenByLastUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdatedAt', Sort.desc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> thenByMatchOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchOrder', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> thenByMatchOrderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchOrder', Sort.desc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy>
  thenByMatchTimeMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchTimeMinutes', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy>
  thenByMatchTimeMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchTimeMinutes', Sort.desc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> thenByMatchType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchType', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> thenByMatchTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchType', Sort.desc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> thenByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> thenByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> thenByOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'order', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> thenByOrderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'order', Sort.desc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> thenByRedName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'redName', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> thenByRedNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'redName', Sort.desc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> thenByRedScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'redScore', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> thenByRedScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'redScore', Sort.desc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy>
  thenByRemainingSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remainingSeconds', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy>
  thenByRemainingSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remainingSeconds', Sort.desc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> thenByRuleJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ruleJson', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> thenByRuleJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ruleJson', Sort.desc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> thenByScorerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scorerId', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> thenByScorerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scorerId', Sort.desc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> thenBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> thenBySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.desc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> thenByTimerIsRunning() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timerIsRunning', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy>
  thenByTimerIsRunningDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timerIsRunning', Sort.desc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> thenByTournamentId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tournamentId', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy>
  thenByTournamentIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tournamentId', Sort.desc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> thenByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> thenByVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.desc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> thenByWhiteName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'whiteName', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> thenByWhiteNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'whiteName', Sort.desc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> thenByWhiteScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'whiteScore', Sort.asc);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QAfterSortBy> thenByWhiteScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'whiteScore', Sort.desc);
    });
  }
}

extension MatchEntityQueryWhereDistinct
    on QueryBuilder<MatchEntity, MatchEntity, QDistinct> {
  QueryBuilder<MatchEntity, MatchEntity, QDistinct> distinctByCategory({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'category', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QDistinct>
  distinctByCountForStandings() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'countForStandings');
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QDistinct> distinctByExtensionCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'extensionCount');
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QDistinct>
  distinctByExtensionTimeMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'extensionTimeMinutes');
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QDistinct> distinctByFirestoreId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'firestoreId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QDistinct> distinctByGroupName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'groupName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QDistinct> distinctByHasExtension() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hasExtension');
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QDistinct> distinctByHasHantei() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hasHantei');
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QDistinct> distinctByIsAutoAssigned() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isAutoAssigned');
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QDistinct> distinctByIsDirty() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isDirty');
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QDistinct> distinctByIsKachinuki() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isKachinuki');
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QDistinct> distinctByIsRunningTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isRunningTime');
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QDistinct> distinctByLastUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastUpdatedAt');
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QDistinct> distinctByMatchOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'matchOrder');
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QDistinct>
  distinctByMatchTimeMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'matchTimeMinutes');
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QDistinct> distinctByMatchType({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'matchType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QDistinct> distinctByNote({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'note', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QDistinct> distinctByOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'order');
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QDistinct> distinctByRedName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'redName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QDistinct> distinctByRedRemaining() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'redRemaining');
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QDistinct> distinctByRedScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'redScore');
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QDistinct> distinctByRefereeNames() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'refereeNames');
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QDistinct>
  distinctByRemainingSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remainingSeconds');
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QDistinct> distinctByRuleJson({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ruleJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QDistinct> distinctByScorerId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'scorerId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QDistinct> distinctBySource({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'source', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QDistinct> distinctByStatus({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QDistinct> distinctByTimerIsRunning() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timerIsRunning');
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QDistinct> distinctByTournamentId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tournamentId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QDistinct> distinctByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'version');
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QDistinct> distinctByWhiteName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'whiteName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QDistinct> distinctByWhiteRemaining() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'whiteRemaining');
    });
  }

  QueryBuilder<MatchEntity, MatchEntity, QDistinct> distinctByWhiteScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'whiteScore');
    });
  }
}

extension MatchEntityQueryProperty
    on QueryBuilder<MatchEntity, MatchEntity, QQueryProperty> {
  QueryBuilder<MatchEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<MatchEntity, String?, QQueryOperations> categoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'category');
    });
  }

  QueryBuilder<MatchEntity, bool, QQueryOperations>
  countForStandingsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'countForStandings');
    });
  }

  QueryBuilder<MatchEntity, List<ScoreEventEntity>, QQueryOperations>
  eventsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'events');
    });
  }

  QueryBuilder<MatchEntity, int?, QQueryOperations> extensionCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'extensionCount');
    });
  }

  QueryBuilder<MatchEntity, int?, QQueryOperations>
  extensionTimeMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'extensionTimeMinutes');
    });
  }

  QueryBuilder<MatchEntity, String, QQueryOperations> firestoreIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'firestoreId');
    });
  }

  QueryBuilder<MatchEntity, String?, QQueryOperations> groupNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'groupName');
    });
  }

  QueryBuilder<MatchEntity, bool, QQueryOperations> hasExtensionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hasExtension');
    });
  }

  QueryBuilder<MatchEntity, bool, QQueryOperations> hasHanteiProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hasHantei');
    });
  }

  QueryBuilder<MatchEntity, bool, QQueryOperations> isAutoAssignedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isAutoAssigned');
    });
  }

  QueryBuilder<MatchEntity, bool, QQueryOperations> isDirtyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isDirty');
    });
  }

  QueryBuilder<MatchEntity, bool, QQueryOperations> isKachinukiProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isKachinuki');
    });
  }

  QueryBuilder<MatchEntity, bool, QQueryOperations> isRunningTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isRunningTime');
    });
  }

  QueryBuilder<MatchEntity, DateTime?, QQueryOperations>
  lastUpdatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastUpdatedAt');
    });
  }

  QueryBuilder<MatchEntity, int?, QQueryOperations> matchOrderProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'matchOrder');
    });
  }

  QueryBuilder<MatchEntity, int, QQueryOperations> matchTimeMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'matchTimeMinutes');
    });
  }

  QueryBuilder<MatchEntity, String, QQueryOperations> matchTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'matchType');
    });
  }

  QueryBuilder<MatchEntity, String, QQueryOperations> noteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'note');
    });
  }

  QueryBuilder<MatchEntity, double, QQueryOperations> orderProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'order');
    });
  }

  QueryBuilder<MatchEntity, String, QQueryOperations> redNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'redName');
    });
  }

  QueryBuilder<MatchEntity, List<String>, QQueryOperations>
  redRemainingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'redRemaining');
    });
  }

  QueryBuilder<MatchEntity, int, QQueryOperations> redScoreProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'redScore');
    });
  }

  QueryBuilder<MatchEntity, List<String>, QQueryOperations>
  refereeNamesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'refereeNames');
    });
  }

  QueryBuilder<MatchEntity, int, QQueryOperations> remainingSecondsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remainingSeconds');
    });
  }

  QueryBuilder<MatchEntity, String?, QQueryOperations> ruleJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ruleJson');
    });
  }

  QueryBuilder<MatchEntity, String?, QQueryOperations> scorerIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'scorerId');
    });
  }

  QueryBuilder<MatchEntity, List<MatchSnapshotEntity>, QQueryOperations>
  snapshotsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'snapshots');
    });
  }

  QueryBuilder<MatchEntity, String, QQueryOperations> sourceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'source');
    });
  }

  QueryBuilder<MatchEntity, String, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<MatchEntity, bool, QQueryOperations> timerIsRunningProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timerIsRunning');
    });
  }

  QueryBuilder<MatchEntity, String?, QQueryOperations> tournamentIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tournamentId');
    });
  }

  QueryBuilder<MatchEntity, int, QQueryOperations> versionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'version');
    });
  }

  QueryBuilder<MatchEntity, String, QQueryOperations> whiteNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'whiteName');
    });
  }

  QueryBuilder<MatchEntity, List<String>, QQueryOperations>
  whiteRemainingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'whiteRemaining');
    });
  }

  QueryBuilder<MatchEntity, int, QQueryOperations> whiteScoreProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'whiteScore');
    });
  }
}

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const ScoreEventEntitySchema = Schema(
  name: r'ScoreEventEntity',
  id: -3959885099761782625,
  properties: {
    r'id': PropertySchema(id: 0, name: r'id', type: IsarType.string),
    r'sequence': PropertySchema(id: 1, name: r'sequence', type: IsarType.long),
    r'side': PropertySchema(
      id: 2,
      name: r'side',
      type: IsarType.byte,
      enumMap: _ScoreEventEntitysideEnumValueMap,
    ),
    r'timestamp': PropertySchema(
      id: 3,
      name: r'timestamp',
      type: IsarType.dateTime,
    ),
    r'type': PropertySchema(
      id: 4,
      name: r'type',
      type: IsarType.byte,
      enumMap: _ScoreEventEntitytypeEnumValueMap,
    ),
    r'userId': PropertySchema(id: 5, name: r'userId', type: IsarType.string),
  },

  estimateSize: _scoreEventEntityEstimateSize,
  serialize: _scoreEventEntitySerialize,
  deserialize: _scoreEventEntityDeserialize,
  deserializeProp: _scoreEventEntityDeserializeProp,
);

int _scoreEventEntityEstimateSize(
  ScoreEventEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.id;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.userId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _scoreEventEntitySerialize(
  ScoreEventEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.id);
  writer.writeLong(offsets[1], object.sequence);
  writer.writeByte(offsets[2], object.side.index);
  writer.writeDateTime(offsets[3], object.timestamp);
  writer.writeByte(offsets[4], object.type.index);
  writer.writeString(offsets[5], object.userId);
}

ScoreEventEntity _scoreEventEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ScoreEventEntity();
  object.id = reader.readStringOrNull(offsets[0]);
  object.sequence = reader.readLong(offsets[1]);
  object.side =
      _ScoreEventEntitysideValueEnumMap[reader.readByteOrNull(offsets[2])] ??
      Side.red;
  object.timestamp = reader.readDateTimeOrNull(offsets[3]);
  object.type =
      _ScoreEventEntitytypeValueEnumMap[reader.readByteOrNull(offsets[4])] ??
      PointType.men;
  object.userId = reader.readStringOrNull(offsets[5]);
  return object;
}

P _scoreEventEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (_ScoreEventEntitysideValueEnumMap[reader.readByteOrNull(
                offset,
              )] ??
              Side.red)
          as P;
    case 3:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 4:
      return (_ScoreEventEntitytypeValueEnumMap[reader.readByteOrNull(
                offset,
              )] ??
              PointType.men)
          as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _ScoreEventEntitysideEnumValueMap = {'red': 0, 'white': 1, 'none': 2};
const _ScoreEventEntitysideValueEnumMap = {
  0: Side.red,
  1: Side.white,
  2: Side.none,
};
const _ScoreEventEntitytypeEnumValueMap = {
  'men': 0,
  'kote': 1,
  'doIdo': 2,
  'tsuki': 3,
  'hansoku': 4,
  'undo': 5,
  'fusen': 6,
  'hantei': 7,
  'restore': 8,
};
const _ScoreEventEntitytypeValueEnumMap = {
  0: PointType.men,
  1: PointType.kote,
  2: PointType.doIdo,
  3: PointType.tsuki,
  4: PointType.hansoku,
  5: PointType.undo,
  6: PointType.fusen,
  7: PointType.hantei,
  8: PointType.restore,
};

extension ScoreEventEntityQueryFilter
    on QueryBuilder<ScoreEventEntity, ScoreEventEntity, QFilterCondition> {
  QueryBuilder<ScoreEventEntity, ScoreEventEntity, QAfterFilterCondition>
  idIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'id'),
      );
    });
  }

  QueryBuilder<ScoreEventEntity, ScoreEventEntity, QAfterFilterCondition>
  idIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'id'),
      );
    });
  }

  QueryBuilder<ScoreEventEntity, ScoreEventEntity, QAfterFilterCondition>
  idEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoreEventEntity, ScoreEventEntity, QAfterFilterCondition>
  idGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoreEventEntity, ScoreEventEntity, QAfterFilterCondition>
  idLessThan(String? value, {bool include = false, bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoreEventEntity, ScoreEventEntity, QAfterFilterCondition>
  idBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoreEventEntity, ScoreEventEntity, QAfterFilterCondition>
  idStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoreEventEntity, ScoreEventEntity, QAfterFilterCondition>
  idEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoreEventEntity, ScoreEventEntity, QAfterFilterCondition>
  idContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoreEventEntity, ScoreEventEntity, QAfterFilterCondition>
  idMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'id',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoreEventEntity, ScoreEventEntity, QAfterFilterCondition>
  idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: ''),
      );
    });
  }

  QueryBuilder<ScoreEventEntity, ScoreEventEntity, QAfterFilterCondition>
  idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'id', value: ''),
      );
    });
  }

  QueryBuilder<ScoreEventEntity, ScoreEventEntity, QAfterFilterCondition>
  sequenceEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sequence', value: value),
      );
    });
  }

  QueryBuilder<ScoreEventEntity, ScoreEventEntity, QAfterFilterCondition>
  sequenceGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sequence',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ScoreEventEntity, ScoreEventEntity, QAfterFilterCondition>
  sequenceLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sequence',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ScoreEventEntity, ScoreEventEntity, QAfterFilterCondition>
  sequenceBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sequence',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<ScoreEventEntity, ScoreEventEntity, QAfterFilterCondition>
  sideEqualTo(Side value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'side', value: value),
      );
    });
  }

  QueryBuilder<ScoreEventEntity, ScoreEventEntity, QAfterFilterCondition>
  sideGreaterThan(Side value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'side',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ScoreEventEntity, ScoreEventEntity, QAfterFilterCondition>
  sideLessThan(Side value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'side',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ScoreEventEntity, ScoreEventEntity, QAfterFilterCondition>
  sideBetween(
    Side lower,
    Side upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'side',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<ScoreEventEntity, ScoreEventEntity, QAfterFilterCondition>
  timestampIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'timestamp'),
      );
    });
  }

  QueryBuilder<ScoreEventEntity, ScoreEventEntity, QAfterFilterCondition>
  timestampIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'timestamp'),
      );
    });
  }

  QueryBuilder<ScoreEventEntity, ScoreEventEntity, QAfterFilterCondition>
  timestampEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'timestamp', value: value),
      );
    });
  }

  QueryBuilder<ScoreEventEntity, ScoreEventEntity, QAfterFilterCondition>
  timestampGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'timestamp',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ScoreEventEntity, ScoreEventEntity, QAfterFilterCondition>
  timestampLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'timestamp',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ScoreEventEntity, ScoreEventEntity, QAfterFilterCondition>
  timestampBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'timestamp',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<ScoreEventEntity, ScoreEventEntity, QAfterFilterCondition>
  typeEqualTo(PointType value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'type', value: value),
      );
    });
  }

  QueryBuilder<ScoreEventEntity, ScoreEventEntity, QAfterFilterCondition>
  typeGreaterThan(PointType value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'type',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ScoreEventEntity, ScoreEventEntity, QAfterFilterCondition>
  typeLessThan(PointType value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'type',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ScoreEventEntity, ScoreEventEntity, QAfterFilterCondition>
  typeBetween(
    PointType lower,
    PointType upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'type',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<ScoreEventEntity, ScoreEventEntity, QAfterFilterCondition>
  userIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'userId'),
      );
    });
  }

  QueryBuilder<ScoreEventEntity, ScoreEventEntity, QAfterFilterCondition>
  userIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'userId'),
      );
    });
  }

  QueryBuilder<ScoreEventEntity, ScoreEventEntity, QAfterFilterCondition>
  userIdEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'userId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoreEventEntity, ScoreEventEntity, QAfterFilterCondition>
  userIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'userId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoreEventEntity, ScoreEventEntity, QAfterFilterCondition>
  userIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'userId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoreEventEntity, ScoreEventEntity, QAfterFilterCondition>
  userIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'userId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoreEventEntity, ScoreEventEntity, QAfterFilterCondition>
  userIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'userId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoreEventEntity, ScoreEventEntity, QAfterFilterCondition>
  userIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'userId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoreEventEntity, ScoreEventEntity, QAfterFilterCondition>
  userIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'userId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoreEventEntity, ScoreEventEntity, QAfterFilterCondition>
  userIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'userId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ScoreEventEntity, ScoreEventEntity, QAfterFilterCondition>
  userIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'userId', value: ''),
      );
    });
  }

  QueryBuilder<ScoreEventEntity, ScoreEventEntity, QAfterFilterCondition>
  userIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'userId', value: ''),
      );
    });
  }
}

extension ScoreEventEntityQueryObject
    on QueryBuilder<ScoreEventEntity, ScoreEventEntity, QFilterCondition> {}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const MatchSnapshotEntitySchema = Schema(
  name: r'MatchSnapshotEntity',
  id: -2426652353465081499,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'events': PropertySchema(
      id: 1,
      name: r'events',
      type: IsarType.objectList,

      target: r'ScoreEventEntity',
    ),
    r'id': PropertySchema(id: 2, name: r'id', type: IsarType.string),
    r'reason': PropertySchema(id: 3, name: r'reason', type: IsarType.string),
  },

  estimateSize: _matchSnapshotEntityEstimateSize,
  serialize: _matchSnapshotEntitySerialize,
  deserialize: _matchSnapshotEntityDeserialize,
  deserializeProp: _matchSnapshotEntityDeserializeProp,
);

int _matchSnapshotEntityEstimateSize(
  MatchSnapshotEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.events.length * 3;
  {
    final offsets = allOffsets[ScoreEventEntity]!;
    for (var i = 0; i < object.events.length; i++) {
      final value = object.events[i];
      bytesCount += ScoreEventEntitySchema.estimateSize(
        value,
        offsets,
        allOffsets,
      );
    }
  }
  {
    final value = object.id;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.reason;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _matchSnapshotEntitySerialize(
  MatchSnapshotEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeObjectList<ScoreEventEntity>(
    offsets[1],
    allOffsets,
    ScoreEventEntitySchema.serialize,
    object.events,
  );
  writer.writeString(offsets[2], object.id);
  writer.writeString(offsets[3], object.reason);
}

MatchSnapshotEntity _matchSnapshotEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = MatchSnapshotEntity();
  object.createdAt = reader.readDateTimeOrNull(offsets[0]);
  object.events =
      reader.readObjectList<ScoreEventEntity>(
        offsets[1],
        ScoreEventEntitySchema.deserialize,
        allOffsets,
        ScoreEventEntity(),
      ) ??
      [];
  object.id = reader.readStringOrNull(offsets[2]);
  object.reason = reader.readStringOrNull(offsets[3]);
  return object;
}

P _matchSnapshotEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 1:
      return (reader.readObjectList<ScoreEventEntity>(
                offset,
                ScoreEventEntitySchema.deserialize,
                allOffsets,
                ScoreEventEntity(),
              ) ??
              [])
          as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension MatchSnapshotEntityQueryFilter
    on
        QueryBuilder<
          MatchSnapshotEntity,
          MatchSnapshotEntity,
          QFilterCondition
        > {
  QueryBuilder<MatchSnapshotEntity, MatchSnapshotEntity, QAfterFilterCondition>
  createdAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'createdAt'),
      );
    });
  }

  QueryBuilder<MatchSnapshotEntity, MatchSnapshotEntity, QAfterFilterCondition>
  createdAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'createdAt'),
      );
    });
  }

  QueryBuilder<MatchSnapshotEntity, MatchSnapshotEntity, QAfterFilterCondition>
  createdAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<MatchSnapshotEntity, MatchSnapshotEntity, QAfterFilterCondition>
  createdAtGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MatchSnapshotEntity, MatchSnapshotEntity, QAfterFilterCondition>
  createdAtLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MatchSnapshotEntity, MatchSnapshotEntity, QAfterFilterCondition>
  createdAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'createdAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<MatchSnapshotEntity, MatchSnapshotEntity, QAfterFilterCondition>
  eventsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'events', length, true, length, true);
    });
  }

  QueryBuilder<MatchSnapshotEntity, MatchSnapshotEntity, QAfterFilterCondition>
  eventsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'events', 0, true, 0, true);
    });
  }

  QueryBuilder<MatchSnapshotEntity, MatchSnapshotEntity, QAfterFilterCondition>
  eventsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'events', 0, false, 999999, true);
    });
  }

  QueryBuilder<MatchSnapshotEntity, MatchSnapshotEntity, QAfterFilterCondition>
  eventsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'events', 0, true, length, include);
    });
  }

  QueryBuilder<MatchSnapshotEntity, MatchSnapshotEntity, QAfterFilterCondition>
  eventsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'events', length, include, 999999, true);
    });
  }

  QueryBuilder<MatchSnapshotEntity, MatchSnapshotEntity, QAfterFilterCondition>
  eventsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'events',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<MatchSnapshotEntity, MatchSnapshotEntity, QAfterFilterCondition>
  idIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'id'),
      );
    });
  }

  QueryBuilder<MatchSnapshotEntity, MatchSnapshotEntity, QAfterFilterCondition>
  idIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'id'),
      );
    });
  }

  QueryBuilder<MatchSnapshotEntity, MatchSnapshotEntity, QAfterFilterCondition>
  idEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchSnapshotEntity, MatchSnapshotEntity, QAfterFilterCondition>
  idGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchSnapshotEntity, MatchSnapshotEntity, QAfterFilterCondition>
  idLessThan(String? value, {bool include = false, bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchSnapshotEntity, MatchSnapshotEntity, QAfterFilterCondition>
  idBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchSnapshotEntity, MatchSnapshotEntity, QAfterFilterCondition>
  idStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchSnapshotEntity, MatchSnapshotEntity, QAfterFilterCondition>
  idEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchSnapshotEntity, MatchSnapshotEntity, QAfterFilterCondition>
  idContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchSnapshotEntity, MatchSnapshotEntity, QAfterFilterCondition>
  idMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'id',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchSnapshotEntity, MatchSnapshotEntity, QAfterFilterCondition>
  idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: ''),
      );
    });
  }

  QueryBuilder<MatchSnapshotEntity, MatchSnapshotEntity, QAfterFilterCondition>
  idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'id', value: ''),
      );
    });
  }

  QueryBuilder<MatchSnapshotEntity, MatchSnapshotEntity, QAfterFilterCondition>
  reasonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'reason'),
      );
    });
  }

  QueryBuilder<MatchSnapshotEntity, MatchSnapshotEntity, QAfterFilterCondition>
  reasonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'reason'),
      );
    });
  }

  QueryBuilder<MatchSnapshotEntity, MatchSnapshotEntity, QAfterFilterCondition>
  reasonEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'reason',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchSnapshotEntity, MatchSnapshotEntity, QAfterFilterCondition>
  reasonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'reason',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchSnapshotEntity, MatchSnapshotEntity, QAfterFilterCondition>
  reasonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'reason',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchSnapshotEntity, MatchSnapshotEntity, QAfterFilterCondition>
  reasonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'reason',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchSnapshotEntity, MatchSnapshotEntity, QAfterFilterCondition>
  reasonStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'reason',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchSnapshotEntity, MatchSnapshotEntity, QAfterFilterCondition>
  reasonEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'reason',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchSnapshotEntity, MatchSnapshotEntity, QAfterFilterCondition>
  reasonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'reason',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchSnapshotEntity, MatchSnapshotEntity, QAfterFilterCondition>
  reasonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'reason',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MatchSnapshotEntity, MatchSnapshotEntity, QAfterFilterCondition>
  reasonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'reason', value: ''),
      );
    });
  }

  QueryBuilder<MatchSnapshotEntity, MatchSnapshotEntity, QAfterFilterCondition>
  reasonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'reason', value: ''),
      );
    });
  }
}

extension MatchSnapshotEntityQueryObject
    on
        QueryBuilder<
          MatchSnapshotEntity,
          MatchSnapshotEntity,
          QFilterCondition
        > {
  QueryBuilder<MatchSnapshotEntity, MatchSnapshotEntity, QAfterFilterCondition>
  eventsElement(FilterQuery<ScoreEventEntity> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'events');
    });
  }
}
