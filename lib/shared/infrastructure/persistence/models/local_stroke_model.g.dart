// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_stroke_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetLocalStrokeModelCollection on Isar {
  IsarCollection<LocalStrokeModel> get localStrokeModels => this.collection();
}

const LocalStrokeModelSchema = CollectionSchema(
  name: r'LocalStrokeModel',
  id: -1760441421689311977,
  properties: {
    r'colorValue': PropertySchema(
      id: 0,
      name: r'colorValue',
      type: IsarType.long,
    ),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'pointsX': PropertySchema(
      id: 2,
      name: r'pointsX',
      type: IsarType.doubleList,
    ),
    r'pointsY': PropertySchema(
      id: 3,
      name: r'pointsY',
      type: IsarType.doubleList,
    ),
    r'programId': PropertySchema(
      id: 4,
      name: r'programId',
      type: IsarType.string,
    ),
    r'strokeWidth': PropertySchema(
      id: 5,
      name: r'strokeWidth',
      type: IsarType.double,
    ),
  },

  estimateSize: _localStrokeModelEstimateSize,
  serialize: _localStrokeModelSerialize,
  deserialize: _localStrokeModelDeserialize,
  deserializeProp: _localStrokeModelDeserializeProp,
  idName: r'id',
  indexes: {
    r'programId': IndexSchema(
      id: 8658639611369428834,
      name: r'programId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'programId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _localStrokeModelGetId,
  getLinks: _localStrokeModelGetLinks,
  attach: _localStrokeModelAttach,
  version: '3.3.2',
);

int _localStrokeModelEstimateSize(
  LocalStrokeModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.pointsX.length * 8;
  bytesCount += 3 + object.pointsY.length * 8;
  bytesCount += 3 + object.programId.length * 3;
  return bytesCount;
}

void _localStrokeModelSerialize(
  LocalStrokeModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.colorValue);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeDoubleList(offsets[2], object.pointsX);
  writer.writeDoubleList(offsets[3], object.pointsY);
  writer.writeString(offsets[4], object.programId);
  writer.writeDouble(offsets[5], object.strokeWidth);
}

LocalStrokeModel _localStrokeModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = LocalStrokeModel();
  object.colorValue = reader.readLong(offsets[0]);
  object.createdAt = reader.readDateTime(offsets[1]);
  object.id = id;
  object.pointsX = reader.readDoubleList(offsets[2]) ?? [];
  object.pointsY = reader.readDoubleList(offsets[3]) ?? [];
  object.programId = reader.readString(offsets[4]);
  object.strokeWidth = reader.readDouble(offsets[5]);
  return object;
}

P _localStrokeModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readDoubleList(offset) ?? []) as P;
    case 3:
      return (reader.readDoubleList(offset) ?? []) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readDouble(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _localStrokeModelGetId(LocalStrokeModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _localStrokeModelGetLinks(LocalStrokeModel object) {
  return [];
}

void _localStrokeModelAttach(
  IsarCollection<dynamic> col,
  Id id,
  LocalStrokeModel object,
) {
  object.id = id;
}

extension LocalStrokeModelQueryWhereSort
    on QueryBuilder<LocalStrokeModel, LocalStrokeModel, QWhere> {
  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension LocalStrokeModelQueryWhere
    on QueryBuilder<LocalStrokeModel, LocalStrokeModel, QWhereClause> {
  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterWhereClause>
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

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterWhereClause> idBetween(
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

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterWhereClause>
  programIdEqualTo(String programId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'programId', value: [programId]),
      );
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterWhereClause>
  programIdNotEqualTo(String programId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'programId',
                lower: [],
                upper: [programId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'programId',
                lower: [programId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'programId',
                lower: [programId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'programId',
                lower: [],
                upper: [programId],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension LocalStrokeModelQueryFilter
    on QueryBuilder<LocalStrokeModel, LocalStrokeModel, QFilterCondition> {
  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterFilterCondition>
  colorValueEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'colorValue', value: value),
      );
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterFilterCondition>
  colorValueGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'colorValue',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterFilterCondition>
  colorValueLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'colorValue',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterFilterCondition>
  colorValueBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'colorValue',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterFilterCondition>
  createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterFilterCondition>
  createdAtGreaterThan(DateTime value, {bool include = false}) {
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

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterFilterCondition>
  createdAtLessThan(DateTime value, {bool include = false}) {
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

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterFilterCondition>
  createdAtBetween(
    DateTime lower,
    DateTime upper, {
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

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterFilterCondition>
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

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterFilterCondition>
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

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterFilterCondition>
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

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterFilterCondition>
  pointsXElementEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'pointsX',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterFilterCondition>
  pointsXElementGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'pointsX',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterFilterCondition>
  pointsXElementLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'pointsX',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterFilterCondition>
  pointsXElementBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'pointsX',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterFilterCondition>
  pointsXLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'pointsX', length, true, length, true);
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterFilterCondition>
  pointsXIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'pointsX', 0, true, 0, true);
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterFilterCondition>
  pointsXIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'pointsX', 0, false, 999999, true);
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterFilterCondition>
  pointsXLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'pointsX', 0, true, length, include);
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterFilterCondition>
  pointsXLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'pointsX', length, include, 999999, true);
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterFilterCondition>
  pointsXLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'pointsX',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterFilterCondition>
  pointsYElementEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'pointsY',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterFilterCondition>
  pointsYElementGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'pointsY',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterFilterCondition>
  pointsYElementLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'pointsY',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterFilterCondition>
  pointsYElementBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'pointsY',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterFilterCondition>
  pointsYLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'pointsY', length, true, length, true);
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterFilterCondition>
  pointsYIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'pointsY', 0, true, 0, true);
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterFilterCondition>
  pointsYIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'pointsY', 0, false, 999999, true);
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterFilterCondition>
  pointsYLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'pointsY', 0, true, length, include);
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterFilterCondition>
  pointsYLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'pointsY', length, include, 999999, true);
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterFilterCondition>
  pointsYLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'pointsY',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterFilterCondition>
  programIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'programId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterFilterCondition>
  programIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'programId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterFilterCondition>
  programIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'programId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterFilterCondition>
  programIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'programId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterFilterCondition>
  programIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'programId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterFilterCondition>
  programIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'programId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterFilterCondition>
  programIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'programId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterFilterCondition>
  programIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'programId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterFilterCondition>
  programIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'programId', value: ''),
      );
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterFilterCondition>
  programIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'programId', value: ''),
      );
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterFilterCondition>
  strokeWidthEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'strokeWidth',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterFilterCondition>
  strokeWidthGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'strokeWidth',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterFilterCondition>
  strokeWidthLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'strokeWidth',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterFilterCondition>
  strokeWidthBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'strokeWidth',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }
}

extension LocalStrokeModelQueryObject
    on QueryBuilder<LocalStrokeModel, LocalStrokeModel, QFilterCondition> {}

extension LocalStrokeModelQueryLinks
    on QueryBuilder<LocalStrokeModel, LocalStrokeModel, QFilterCondition> {}

extension LocalStrokeModelQuerySortBy
    on QueryBuilder<LocalStrokeModel, LocalStrokeModel, QSortBy> {
  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterSortBy>
  sortByColorValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorValue', Sort.asc);
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterSortBy>
  sortByColorValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorValue', Sort.desc);
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterSortBy>
  sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterSortBy>
  sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterSortBy>
  sortByProgramId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'programId', Sort.asc);
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterSortBy>
  sortByProgramIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'programId', Sort.desc);
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterSortBy>
  sortByStrokeWidth() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'strokeWidth', Sort.asc);
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterSortBy>
  sortByStrokeWidthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'strokeWidth', Sort.desc);
    });
  }
}

extension LocalStrokeModelQuerySortThenBy
    on QueryBuilder<LocalStrokeModel, LocalStrokeModel, QSortThenBy> {
  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterSortBy>
  thenByColorValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorValue', Sort.asc);
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterSortBy>
  thenByColorValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorValue', Sort.desc);
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterSortBy>
  thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterSortBy>
  thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterSortBy>
  thenByProgramId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'programId', Sort.asc);
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterSortBy>
  thenByProgramIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'programId', Sort.desc);
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterSortBy>
  thenByStrokeWidth() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'strokeWidth', Sort.asc);
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QAfterSortBy>
  thenByStrokeWidthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'strokeWidth', Sort.desc);
    });
  }
}

extension LocalStrokeModelQueryWhereDistinct
    on QueryBuilder<LocalStrokeModel, LocalStrokeModel, QDistinct> {
  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QDistinct>
  distinctByColorValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'colorValue');
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QDistinct>
  distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QDistinct>
  distinctByPointsX() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pointsX');
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QDistinct>
  distinctByPointsY() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pointsY');
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QDistinct>
  distinctByProgramId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'programId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalStrokeModel, LocalStrokeModel, QDistinct>
  distinctByStrokeWidth() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'strokeWidth');
    });
  }
}

extension LocalStrokeModelQueryProperty
    on QueryBuilder<LocalStrokeModel, LocalStrokeModel, QQueryProperty> {
  QueryBuilder<LocalStrokeModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<LocalStrokeModel, int, QQueryOperations> colorValueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'colorValue');
    });
  }

  QueryBuilder<LocalStrokeModel, DateTime, QQueryOperations>
  createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<LocalStrokeModel, List<double>, QQueryOperations>
  pointsXProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pointsX');
    });
  }

  QueryBuilder<LocalStrokeModel, List<double>, QQueryOperations>
  pointsYProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pointsY');
    });
  }

  QueryBuilder<LocalStrokeModel, String, QQueryOperations> programIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'programId');
    });
  }

  QueryBuilder<LocalStrokeModel, double, QQueryOperations>
  strokeWidthProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'strokeWidth');
    });
  }
}
