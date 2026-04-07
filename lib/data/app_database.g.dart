// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $FieldsTable extends Fields with TableInfo<$FieldsTable, Field> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FieldsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _cropMeta = const VerificationMeta('crop');
  @override
  late final GeneratedColumn<String> crop = GeneratedColumn<String>(
      'crop', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
      'date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _latitudeMeta =
      const VerificationMeta('latitude');
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
      'latitude', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _longitudeMeta =
      const VerificationMeta('longitude');
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
      'longitude', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _areaDekarMeta =
      const VerificationMeta('areaDekar');
  @override
  late final GeneratedColumn<double> areaDekar = GeneratedColumn<double>(
      'area_dekar', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _areaSqmMeta =
      const VerificationMeta('areaSqm');
  @override
  late final GeneratedColumn<double> areaSqm = GeneratedColumn<double>(
      'area_sqm', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _polygonJsonMeta =
      const VerificationMeta('polygonJson');
  @override
  late final GeneratedColumn<String> polygonJson = GeneratedColumn<String>(
      'polygon_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        crop,
        date,
        latitude,
        longitude,
        areaDekar,
        areaSqm,
        polygonJson,
        createdAt,
        updatedAt,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fields';
  @override
  VerificationContext validateIntegrity(Insertable<Field> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('crop')) {
      context.handle(
          _cropMeta, crop.isAcceptableOrUnknown(data['crop']!, _cropMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(_latitudeMeta,
          latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta));
    }
    if (data.containsKey('longitude')) {
      context.handle(_longitudeMeta,
          longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta));
    }
    if (data.containsKey('area_dekar')) {
      context.handle(_areaDekarMeta,
          areaDekar.isAcceptableOrUnknown(data['area_dekar']!, _areaDekarMeta));
    }
    if (data.containsKey('area_sqm')) {
      context.handle(_areaSqmMeta,
          areaSqm.isAcceptableOrUnknown(data['area_sqm']!, _areaSqmMeta));
    }
    if (data.containsKey('polygon_json')) {
      context.handle(
          _polygonJsonMeta,
          polygonJson.isAcceptableOrUnknown(
              data['polygon_json']!, _polygonJsonMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Field map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Field(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      crop: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}crop']),
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}date'])!,
      latitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}latitude']),
      longitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}longitude']),
      areaDekar: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}area_dekar']),
      areaSqm: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}area_sqm']),
      polygonJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}polygon_json']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $FieldsTable createAlias(String alias) {
    return $FieldsTable(attachedDatabase, alias);
  }
}

class Field extends DataClass implements Insertable<Field> {
  final String id;
  final String name;
  final String? crop;
  final String date;
  final double? latitude;
  final double? longitude;
  final double? areaDekar;
  final double? areaSqm;
  final String? polygonJson;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const Field(
      {required this.id,
      required this.name,
      this.crop,
      required this.date,
      this.latitude,
      this.longitude,
      this.areaDekar,
      this.areaSqm,
      this.polygonJson,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || crop != null) {
      map['crop'] = Variable<String>(crop);
    }
    map['date'] = Variable<String>(date);
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    if (!nullToAbsent || areaDekar != null) {
      map['area_dekar'] = Variable<double>(areaDekar);
    }
    if (!nullToAbsent || areaSqm != null) {
      map['area_sqm'] = Variable<double>(areaSqm);
    }
    if (!nullToAbsent || polygonJson != null) {
      map['polygon_json'] = Variable<String>(polygonJson);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  FieldsCompanion toCompanion(bool nullToAbsent) {
    return FieldsCompanion(
      id: Value(id),
      name: Value(name),
      crop: crop == null && nullToAbsent ? const Value.absent() : Value(crop),
      date: Value(date),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      areaDekar: areaDekar == null && nullToAbsent
          ? const Value.absent()
          : Value(areaDekar),
      areaSqm: areaSqm == null && nullToAbsent
          ? const Value.absent()
          : Value(areaSqm),
      polygonJson: polygonJson == null && nullToAbsent
          ? const Value.absent()
          : Value(polygonJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Field.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Field(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      crop: serializer.fromJson<String?>(json['crop']),
      date: serializer.fromJson<String>(json['date']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      areaDekar: serializer.fromJson<double?>(json['areaDekar']),
      areaSqm: serializer.fromJson<double?>(json['areaSqm']),
      polygonJson: serializer.fromJson<String?>(json['polygonJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'crop': serializer.toJson<String?>(crop),
      'date': serializer.toJson<String>(date),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
      'areaDekar': serializer.toJson<double?>(areaDekar),
      'areaSqm': serializer.toJson<double?>(areaSqm),
      'polygonJson': serializer.toJson<String?>(polygonJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Field copyWith(
          {String? id,
          String? name,
          Value<String?> crop = const Value.absent(),
          String? date,
          Value<double?> latitude = const Value.absent(),
          Value<double?> longitude = const Value.absent(),
          Value<double?> areaDekar = const Value.absent(),
          Value<double?> areaSqm = const Value.absent(),
          Value<String?> polygonJson = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent()}) =>
      Field(
        id: id ?? this.id,
        name: name ?? this.name,
        crop: crop.present ? crop.value : this.crop,
        date: date ?? this.date,
        latitude: latitude.present ? latitude.value : this.latitude,
        longitude: longitude.present ? longitude.value : this.longitude,
        areaDekar: areaDekar.present ? areaDekar.value : this.areaDekar,
        areaSqm: areaSqm.present ? areaSqm.value : this.areaSqm,
        polygonJson: polygonJson.present ? polygonJson.value : this.polygonJson,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  Field copyWithCompanion(FieldsCompanion data) {
    return Field(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      crop: data.crop.present ? data.crop.value : this.crop,
      date: data.date.present ? data.date.value : this.date,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      areaDekar: data.areaDekar.present ? data.areaDekar.value : this.areaDekar,
      areaSqm: data.areaSqm.present ? data.areaSqm.value : this.areaSqm,
      polygonJson:
          data.polygonJson.present ? data.polygonJson.value : this.polygonJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Field(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('crop: $crop, ')
          ..write('date: $date, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('areaDekar: $areaDekar, ')
          ..write('areaSqm: $areaSqm, ')
          ..write('polygonJson: $polygonJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, crop, date, latitude, longitude,
      areaDekar, areaSqm, polygonJson, createdAt, updatedAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Field &&
          other.id == this.id &&
          other.name == this.name &&
          other.crop == this.crop &&
          other.date == this.date &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.areaDekar == this.areaDekar &&
          other.areaSqm == this.areaSqm &&
          other.polygonJson == this.polygonJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class FieldsCompanion extends UpdateCompanion<Field> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> crop;
  final Value<String> date;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<double?> areaDekar;
  final Value<double?> areaSqm;
  final Value<String?> polygonJson;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const FieldsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.crop = const Value.absent(),
    this.date = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.areaDekar = const Value.absent(),
    this.areaSqm = const Value.absent(),
    this.polygonJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FieldsCompanion.insert({
    required String id,
    required String name,
    this.crop = const Value.absent(),
    required String date,
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.areaDekar = const Value.absent(),
    this.areaSqm = const Value.absent(),
    this.polygonJson = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        date = Value(date),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Field> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? crop,
    Expression<String>? date,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<double>? areaDekar,
    Expression<double>? areaSqm,
    Expression<String>? polygonJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (crop != null) 'crop': crop,
      if (date != null) 'date': date,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (areaDekar != null) 'area_dekar': areaDekar,
      if (areaSqm != null) 'area_sqm': areaSqm,
      if (polygonJson != null) 'polygon_json': polygonJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FieldsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String?>? crop,
      Value<String>? date,
      Value<double?>? latitude,
      Value<double?>? longitude,
      Value<double?>? areaDekar,
      Value<double?>? areaSqm,
      Value<String?>? polygonJson,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<int>? rowid}) {
    return FieldsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      crop: crop ?? this.crop,
      date: date ?? this.date,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      areaDekar: areaDekar ?? this.areaDekar,
      areaSqm: areaSqm ?? this.areaSqm,
      polygonJson: polygonJson ?? this.polygonJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (crop.present) {
      map['crop'] = Variable<String>(crop.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (areaDekar.present) {
      map['area_dekar'] = Variable<double>(areaDekar.value);
    }
    if (areaSqm.present) {
      map['area_sqm'] = Variable<double>(areaSqm.value);
    }
    if (polygonJson.present) {
      map['polygon_json'] = Variable<String>(polygonJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FieldsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('crop: $crop, ')
          ..write('date: $date, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('areaDekar: $areaDekar, ')
          ..write('areaSqm: $areaSqm, ')
          ..write('polygonJson: $polygonJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FieldCropsTable extends FieldCrops
    with TableInfo<$FieldCropsTable, FieldCrop> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FieldCropsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fieldIdMeta =
      const VerificationMeta('fieldId');
  @override
  late final GeneratedColumn<String> fieldId = GeneratedColumn<String>(
      'field_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES fields (id)'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _zoneStartMeta =
      const VerificationMeta('zoneStart');
  @override
  late final GeneratedColumn<double> zoneStart = GeneratedColumn<double>(
      'zone_start', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _zoneEndMeta =
      const VerificationMeta('zoneEnd');
  @override
  late final GeneratedColumn<double> zoneEnd = GeneratedColumn<double>(
      'zone_end', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _rowSpacingCmMeta =
      const VerificationMeta('rowSpacingCm');
  @override
  late final GeneratedColumn<double> rowSpacingCm = GeneratedColumn<double>(
      'row_spacing_cm', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _plantSpacingCmMeta =
      const VerificationMeta('plantSpacingCm');
  @override
  late final GeneratedColumn<double> plantSpacingCm = GeneratedColumn<double>(
      'plant_spacing_cm', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _colorValueMeta =
      const VerificationMeta('colorValue');
  @override
  late final GeneratedColumn<int> colorValue = GeneratedColumn<int>(
      'color_value', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _plantedDateMeta =
      const VerificationMeta('plantedDate');
  @override
  late final GeneratedColumn<String> plantedDate = GeneratedColumn<String>(
      'planted_date', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _harvestDaysMeta =
      const VerificationMeta('harvestDays');
  @override
  late final GeneratedColumn<int> harvestDays = GeneratedColumn<int>(
      'harvest_days', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _waterIntervalDaysMeta =
      const VerificationMeta('waterIntervalDays');
  @override
  late final GeneratedColumn<int> waterIntervalDays = GeneratedColumn<int>(
      'water_interval_days', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        fieldId,
        name,
        zoneStart,
        zoneEnd,
        rowSpacingCm,
        plantSpacingCm,
        colorValue,
        plantedDate,
        harvestDays,
        waterIntervalDays,
        createdAt,
        updatedAt,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'field_crops';
  @override
  VerificationContext validateIntegrity(Insertable<FieldCrop> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('field_id')) {
      context.handle(_fieldIdMeta,
          fieldId.isAcceptableOrUnknown(data['field_id']!, _fieldIdMeta));
    } else if (isInserting) {
      context.missing(_fieldIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('zone_start')) {
      context.handle(_zoneStartMeta,
          zoneStart.isAcceptableOrUnknown(data['zone_start']!, _zoneStartMeta));
    } else if (isInserting) {
      context.missing(_zoneStartMeta);
    }
    if (data.containsKey('zone_end')) {
      context.handle(_zoneEndMeta,
          zoneEnd.isAcceptableOrUnknown(data['zone_end']!, _zoneEndMeta));
    } else if (isInserting) {
      context.missing(_zoneEndMeta);
    }
    if (data.containsKey('row_spacing_cm')) {
      context.handle(
          _rowSpacingCmMeta,
          rowSpacingCm.isAcceptableOrUnknown(
              data['row_spacing_cm']!, _rowSpacingCmMeta));
    } else if (isInserting) {
      context.missing(_rowSpacingCmMeta);
    }
    if (data.containsKey('plant_spacing_cm')) {
      context.handle(
          _plantSpacingCmMeta,
          plantSpacingCm.isAcceptableOrUnknown(
              data['plant_spacing_cm']!, _plantSpacingCmMeta));
    } else if (isInserting) {
      context.missing(_plantSpacingCmMeta);
    }
    if (data.containsKey('color_value')) {
      context.handle(
          _colorValueMeta,
          colorValue.isAcceptableOrUnknown(
              data['color_value']!, _colorValueMeta));
    }
    if (data.containsKey('planted_date')) {
      context.handle(
          _plantedDateMeta,
          plantedDate.isAcceptableOrUnknown(
              data['planted_date']!, _plantedDateMeta));
    }
    if (data.containsKey('harvest_days')) {
      context.handle(
          _harvestDaysMeta,
          harvestDays.isAcceptableOrUnknown(
              data['harvest_days']!, _harvestDaysMeta));
    }
    if (data.containsKey('water_interval_days')) {
      context.handle(
          _waterIntervalDaysMeta,
          waterIntervalDays.isAcceptableOrUnknown(
              data['water_interval_days']!, _waterIntervalDaysMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FieldCrop map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FieldCrop(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      fieldId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}field_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      zoneStart: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}zone_start'])!,
      zoneEnd: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}zone_end'])!,
      rowSpacingCm: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}row_spacing_cm'])!,
      plantSpacingCm: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}plant_spacing_cm'])!,
      colorValue: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}color_value']),
      plantedDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}planted_date']),
      harvestDays: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}harvest_days']),
      waterIntervalDays: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}water_interval_days']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $FieldCropsTable createAlias(String alias) {
    return $FieldCropsTable(attachedDatabase, alias);
  }
}

class FieldCrop extends DataClass implements Insertable<FieldCrop> {
  final String id;
  final String fieldId;
  final String name;
  final double zoneStart;
  final double zoneEnd;
  final double rowSpacingCm;
  final double plantSpacingCm;
  final int? colorValue;
  final String? plantedDate;
  final int? harvestDays;
  final int? waterIntervalDays;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const FieldCrop(
      {required this.id,
      required this.fieldId,
      required this.name,
      required this.zoneStart,
      required this.zoneEnd,
      required this.rowSpacingCm,
      required this.plantSpacingCm,
      this.colorValue,
      this.plantedDate,
      this.harvestDays,
      this.waterIntervalDays,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['field_id'] = Variable<String>(fieldId);
    map['name'] = Variable<String>(name);
    map['zone_start'] = Variable<double>(zoneStart);
    map['zone_end'] = Variable<double>(zoneEnd);
    map['row_spacing_cm'] = Variable<double>(rowSpacingCm);
    map['plant_spacing_cm'] = Variable<double>(plantSpacingCm);
    if (!nullToAbsent || colorValue != null) {
      map['color_value'] = Variable<int>(colorValue);
    }
    if (!nullToAbsent || plantedDate != null) {
      map['planted_date'] = Variable<String>(plantedDate);
    }
    if (!nullToAbsent || harvestDays != null) {
      map['harvest_days'] = Variable<int>(harvestDays);
    }
    if (!nullToAbsent || waterIntervalDays != null) {
      map['water_interval_days'] = Variable<int>(waterIntervalDays);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  FieldCropsCompanion toCompanion(bool nullToAbsent) {
    return FieldCropsCompanion(
      id: Value(id),
      fieldId: Value(fieldId),
      name: Value(name),
      zoneStart: Value(zoneStart),
      zoneEnd: Value(zoneEnd),
      rowSpacingCm: Value(rowSpacingCm),
      plantSpacingCm: Value(plantSpacingCm),
      colorValue: colorValue == null && nullToAbsent
          ? const Value.absent()
          : Value(colorValue),
      plantedDate: plantedDate == null && nullToAbsent
          ? const Value.absent()
          : Value(plantedDate),
      harvestDays: harvestDays == null && nullToAbsent
          ? const Value.absent()
          : Value(harvestDays),
      waterIntervalDays: waterIntervalDays == null && nullToAbsent
          ? const Value.absent()
          : Value(waterIntervalDays),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory FieldCrop.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FieldCrop(
      id: serializer.fromJson<String>(json['id']),
      fieldId: serializer.fromJson<String>(json['fieldId']),
      name: serializer.fromJson<String>(json['name']),
      zoneStart: serializer.fromJson<double>(json['zoneStart']),
      zoneEnd: serializer.fromJson<double>(json['zoneEnd']),
      rowSpacingCm: serializer.fromJson<double>(json['rowSpacingCm']),
      plantSpacingCm: serializer.fromJson<double>(json['plantSpacingCm']),
      colorValue: serializer.fromJson<int?>(json['colorValue']),
      plantedDate: serializer.fromJson<String?>(json['plantedDate']),
      harvestDays: serializer.fromJson<int?>(json['harvestDays']),
      waterIntervalDays: serializer.fromJson<int?>(json['waterIntervalDays']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'fieldId': serializer.toJson<String>(fieldId),
      'name': serializer.toJson<String>(name),
      'zoneStart': serializer.toJson<double>(zoneStart),
      'zoneEnd': serializer.toJson<double>(zoneEnd),
      'rowSpacingCm': serializer.toJson<double>(rowSpacingCm),
      'plantSpacingCm': serializer.toJson<double>(plantSpacingCm),
      'colorValue': serializer.toJson<int?>(colorValue),
      'plantedDate': serializer.toJson<String?>(plantedDate),
      'harvestDays': serializer.toJson<int?>(harvestDays),
      'waterIntervalDays': serializer.toJson<int?>(waterIntervalDays),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  FieldCrop copyWith(
          {String? id,
          String? fieldId,
          String? name,
          double? zoneStart,
          double? zoneEnd,
          double? rowSpacingCm,
          double? plantSpacingCm,
          Value<int?> colorValue = const Value.absent(),
          Value<String?> plantedDate = const Value.absent(),
          Value<int?> harvestDays = const Value.absent(),
          Value<int?> waterIntervalDays = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent()}) =>
      FieldCrop(
        id: id ?? this.id,
        fieldId: fieldId ?? this.fieldId,
        name: name ?? this.name,
        zoneStart: zoneStart ?? this.zoneStart,
        zoneEnd: zoneEnd ?? this.zoneEnd,
        rowSpacingCm: rowSpacingCm ?? this.rowSpacingCm,
        plantSpacingCm: plantSpacingCm ?? this.plantSpacingCm,
        colorValue: colorValue.present ? colorValue.value : this.colorValue,
        plantedDate: plantedDate.present ? plantedDate.value : this.plantedDate,
        harvestDays: harvestDays.present ? harvestDays.value : this.harvestDays,
        waterIntervalDays: waterIntervalDays.present
            ? waterIntervalDays.value
            : this.waterIntervalDays,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  FieldCrop copyWithCompanion(FieldCropsCompanion data) {
    return FieldCrop(
      id: data.id.present ? data.id.value : this.id,
      fieldId: data.fieldId.present ? data.fieldId.value : this.fieldId,
      name: data.name.present ? data.name.value : this.name,
      zoneStart: data.zoneStart.present ? data.zoneStart.value : this.zoneStart,
      zoneEnd: data.zoneEnd.present ? data.zoneEnd.value : this.zoneEnd,
      rowSpacingCm: data.rowSpacingCm.present
          ? data.rowSpacingCm.value
          : this.rowSpacingCm,
      plantSpacingCm: data.plantSpacingCm.present
          ? data.plantSpacingCm.value
          : this.plantSpacingCm,
      colorValue:
          data.colorValue.present ? data.colorValue.value : this.colorValue,
      plantedDate:
          data.plantedDate.present ? data.plantedDate.value : this.plantedDate,
      harvestDays:
          data.harvestDays.present ? data.harvestDays.value : this.harvestDays,
      waterIntervalDays: data.waterIntervalDays.present
          ? data.waterIntervalDays.value
          : this.waterIntervalDays,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FieldCrop(')
          ..write('id: $id, ')
          ..write('fieldId: $fieldId, ')
          ..write('name: $name, ')
          ..write('zoneStart: $zoneStart, ')
          ..write('zoneEnd: $zoneEnd, ')
          ..write('rowSpacingCm: $rowSpacingCm, ')
          ..write('plantSpacingCm: $plantSpacingCm, ')
          ..write('colorValue: $colorValue, ')
          ..write('plantedDate: $plantedDate, ')
          ..write('harvestDays: $harvestDays, ')
          ..write('waterIntervalDays: $waterIntervalDays, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      fieldId,
      name,
      zoneStart,
      zoneEnd,
      rowSpacingCm,
      plantSpacingCm,
      colorValue,
      plantedDate,
      harvestDays,
      waterIntervalDays,
      createdAt,
      updatedAt,
      deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FieldCrop &&
          other.id == this.id &&
          other.fieldId == this.fieldId &&
          other.name == this.name &&
          other.zoneStart == this.zoneStart &&
          other.zoneEnd == this.zoneEnd &&
          other.rowSpacingCm == this.rowSpacingCm &&
          other.plantSpacingCm == this.plantSpacingCm &&
          other.colorValue == this.colorValue &&
          other.plantedDate == this.plantedDate &&
          other.harvestDays == this.harvestDays &&
          other.waterIntervalDays == this.waterIntervalDays &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class FieldCropsCompanion extends UpdateCompanion<FieldCrop> {
  final Value<String> id;
  final Value<String> fieldId;
  final Value<String> name;
  final Value<double> zoneStart;
  final Value<double> zoneEnd;
  final Value<double> rowSpacingCm;
  final Value<double> plantSpacingCm;
  final Value<int?> colorValue;
  final Value<String?> plantedDate;
  final Value<int?> harvestDays;
  final Value<int?> waterIntervalDays;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const FieldCropsCompanion({
    this.id = const Value.absent(),
    this.fieldId = const Value.absent(),
    this.name = const Value.absent(),
    this.zoneStart = const Value.absent(),
    this.zoneEnd = const Value.absent(),
    this.rowSpacingCm = const Value.absent(),
    this.plantSpacingCm = const Value.absent(),
    this.colorValue = const Value.absent(),
    this.plantedDate = const Value.absent(),
    this.harvestDays = const Value.absent(),
    this.waterIntervalDays = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FieldCropsCompanion.insert({
    required String id,
    required String fieldId,
    required String name,
    required double zoneStart,
    required double zoneEnd,
    required double rowSpacingCm,
    required double plantSpacingCm,
    this.colorValue = const Value.absent(),
    this.plantedDate = const Value.absent(),
    this.harvestDays = const Value.absent(),
    this.waterIntervalDays = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        fieldId = Value(fieldId),
        name = Value(name),
        zoneStart = Value(zoneStart),
        zoneEnd = Value(zoneEnd),
        rowSpacingCm = Value(rowSpacingCm),
        plantSpacingCm = Value(plantSpacingCm),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<FieldCrop> custom({
    Expression<String>? id,
    Expression<String>? fieldId,
    Expression<String>? name,
    Expression<double>? zoneStart,
    Expression<double>? zoneEnd,
    Expression<double>? rowSpacingCm,
    Expression<double>? plantSpacingCm,
    Expression<int>? colorValue,
    Expression<String>? plantedDate,
    Expression<int>? harvestDays,
    Expression<int>? waterIntervalDays,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fieldId != null) 'field_id': fieldId,
      if (name != null) 'name': name,
      if (zoneStart != null) 'zone_start': zoneStart,
      if (zoneEnd != null) 'zone_end': zoneEnd,
      if (rowSpacingCm != null) 'row_spacing_cm': rowSpacingCm,
      if (plantSpacingCm != null) 'plant_spacing_cm': plantSpacingCm,
      if (colorValue != null) 'color_value': colorValue,
      if (plantedDate != null) 'planted_date': plantedDate,
      if (harvestDays != null) 'harvest_days': harvestDays,
      if (waterIntervalDays != null) 'water_interval_days': waterIntervalDays,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FieldCropsCompanion copyWith(
      {Value<String>? id,
      Value<String>? fieldId,
      Value<String>? name,
      Value<double>? zoneStart,
      Value<double>? zoneEnd,
      Value<double>? rowSpacingCm,
      Value<double>? plantSpacingCm,
      Value<int?>? colorValue,
      Value<String?>? plantedDate,
      Value<int?>? harvestDays,
      Value<int?>? waterIntervalDays,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<int>? rowid}) {
    return FieldCropsCompanion(
      id: id ?? this.id,
      fieldId: fieldId ?? this.fieldId,
      name: name ?? this.name,
      zoneStart: zoneStart ?? this.zoneStart,
      zoneEnd: zoneEnd ?? this.zoneEnd,
      rowSpacingCm: rowSpacingCm ?? this.rowSpacingCm,
      plantSpacingCm: plantSpacingCm ?? this.plantSpacingCm,
      colorValue: colorValue ?? this.colorValue,
      plantedDate: plantedDate ?? this.plantedDate,
      harvestDays: harvestDays ?? this.harvestDays,
      waterIntervalDays: waterIntervalDays ?? this.waterIntervalDays,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (fieldId.present) {
      map['field_id'] = Variable<String>(fieldId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (zoneStart.present) {
      map['zone_start'] = Variable<double>(zoneStart.value);
    }
    if (zoneEnd.present) {
      map['zone_end'] = Variable<double>(zoneEnd.value);
    }
    if (rowSpacingCm.present) {
      map['row_spacing_cm'] = Variable<double>(rowSpacingCm.value);
    }
    if (plantSpacingCm.present) {
      map['plant_spacing_cm'] = Variable<double>(plantSpacingCm.value);
    }
    if (colorValue.present) {
      map['color_value'] = Variable<int>(colorValue.value);
    }
    if (plantedDate.present) {
      map['planted_date'] = Variable<String>(plantedDate.value);
    }
    if (harvestDays.present) {
      map['harvest_days'] = Variable<int>(harvestDays.value);
    }
    if (waterIntervalDays.present) {
      map['water_interval_days'] = Variable<int>(waterIntervalDays.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FieldCropsCompanion(')
          ..write('id: $id, ')
          ..write('fieldId: $fieldId, ')
          ..write('name: $name, ')
          ..write('zoneStart: $zoneStart, ')
          ..write('zoneEnd: $zoneEnd, ')
          ..write('rowSpacingCm: $rowSpacingCm, ')
          ..write('plantSpacingCm: $plantSpacingCm, ')
          ..write('colorValue: $colorValue, ')
          ..write('plantedDate: $plantedDate, ')
          ..write('harvestDays: $harvestDays, ')
          ..write('waterIntervalDays: $waterIntervalDays, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CalendarEventsTable extends CalendarEvents
    with TableInfo<$CalendarEventsTable, CalendarEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CalendarEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fieldIdMeta =
      const VerificationMeta('fieldId');
  @override
  late final GeneratedColumn<String> fieldId = GeneratedColumn<String>(
      'field_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES fields (id)'));
  static const VerificationMeta _cropIdMeta = const VerificationMeta('cropId');
  @override
  late final GeneratedColumn<String> cropId = GeneratedColumn<String>(
      'crop_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES field_crops (id)'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _eventTypeMeta =
      const VerificationMeta('eventType');
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
      'event_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _eventDateMeta =
      const VerificationMeta('eventDate');
  @override
  late final GeneratedColumn<DateTime> eventDate = GeneratedColumn<DateTime>(
      'event_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('manual'));
  static const VerificationMeta _metadataJsonMeta =
      const VerificationMeta('metadataJson');
  @override
  late final GeneratedColumn<String> metadataJson = GeneratedColumn<String>(
      'metadata_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        fieldId,
        cropId,
        title,
        eventType,
        eventDate,
        source,
        metadataJson,
        createdAt,
        updatedAt,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'calendar_events';
  @override
  VerificationContext validateIntegrity(Insertable<CalendarEvent> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('field_id')) {
      context.handle(_fieldIdMeta,
          fieldId.isAcceptableOrUnknown(data['field_id']!, _fieldIdMeta));
    }
    if (data.containsKey('crop_id')) {
      context.handle(_cropIdMeta,
          cropId.isAcceptableOrUnknown(data['crop_id']!, _cropIdMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('event_type')) {
      context.handle(_eventTypeMeta,
          eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta));
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('event_date')) {
      context.handle(_eventDateMeta,
          eventDate.isAcceptableOrUnknown(data['event_date']!, _eventDateMeta));
    } else if (isInserting) {
      context.missing(_eventDateMeta);
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    }
    if (data.containsKey('metadata_json')) {
      context.handle(
          _metadataJsonMeta,
          metadataJson.isAcceptableOrUnknown(
              data['metadata_json']!, _metadataJsonMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CalendarEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CalendarEvent(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      fieldId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}field_id']),
      cropId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}crop_id']),
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      eventType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}event_type'])!,
      eventDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}event_date'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      metadataJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}metadata_json']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $CalendarEventsTable createAlias(String alias) {
    return $CalendarEventsTable(attachedDatabase, alias);
  }
}

class CalendarEvent extends DataClass implements Insertable<CalendarEvent> {
  final String id;
  final String? fieldId;
  final String? cropId;
  final String title;
  final String eventType;
  final DateTime eventDate;
  final String source;
  final String? metadataJson;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const CalendarEvent(
      {required this.id,
      this.fieldId,
      this.cropId,
      required this.title,
      required this.eventType,
      required this.eventDate,
      required this.source,
      this.metadataJson,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || fieldId != null) {
      map['field_id'] = Variable<String>(fieldId);
    }
    if (!nullToAbsent || cropId != null) {
      map['crop_id'] = Variable<String>(cropId);
    }
    map['title'] = Variable<String>(title);
    map['event_type'] = Variable<String>(eventType);
    map['event_date'] = Variable<DateTime>(eventDate);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || metadataJson != null) {
      map['metadata_json'] = Variable<String>(metadataJson);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  CalendarEventsCompanion toCompanion(bool nullToAbsent) {
    return CalendarEventsCompanion(
      id: Value(id),
      fieldId: fieldId == null && nullToAbsent
          ? const Value.absent()
          : Value(fieldId),
      cropId:
          cropId == null && nullToAbsent ? const Value.absent() : Value(cropId),
      title: Value(title),
      eventType: Value(eventType),
      eventDate: Value(eventDate),
      source: Value(source),
      metadataJson: metadataJson == null && nullToAbsent
          ? const Value.absent()
          : Value(metadataJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory CalendarEvent.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CalendarEvent(
      id: serializer.fromJson<String>(json['id']),
      fieldId: serializer.fromJson<String?>(json['fieldId']),
      cropId: serializer.fromJson<String?>(json['cropId']),
      title: serializer.fromJson<String>(json['title']),
      eventType: serializer.fromJson<String>(json['eventType']),
      eventDate: serializer.fromJson<DateTime>(json['eventDate']),
      source: serializer.fromJson<String>(json['source']),
      metadataJson: serializer.fromJson<String?>(json['metadataJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'fieldId': serializer.toJson<String?>(fieldId),
      'cropId': serializer.toJson<String?>(cropId),
      'title': serializer.toJson<String>(title),
      'eventType': serializer.toJson<String>(eventType),
      'eventDate': serializer.toJson<DateTime>(eventDate),
      'source': serializer.toJson<String>(source),
      'metadataJson': serializer.toJson<String?>(metadataJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  CalendarEvent copyWith(
          {String? id,
          Value<String?> fieldId = const Value.absent(),
          Value<String?> cropId = const Value.absent(),
          String? title,
          String? eventType,
          DateTime? eventDate,
          String? source,
          Value<String?> metadataJson = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent()}) =>
      CalendarEvent(
        id: id ?? this.id,
        fieldId: fieldId.present ? fieldId.value : this.fieldId,
        cropId: cropId.present ? cropId.value : this.cropId,
        title: title ?? this.title,
        eventType: eventType ?? this.eventType,
        eventDate: eventDate ?? this.eventDate,
        source: source ?? this.source,
        metadataJson:
            metadataJson.present ? metadataJson.value : this.metadataJson,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  CalendarEvent copyWithCompanion(CalendarEventsCompanion data) {
    return CalendarEvent(
      id: data.id.present ? data.id.value : this.id,
      fieldId: data.fieldId.present ? data.fieldId.value : this.fieldId,
      cropId: data.cropId.present ? data.cropId.value : this.cropId,
      title: data.title.present ? data.title.value : this.title,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      eventDate: data.eventDate.present ? data.eventDate.value : this.eventDate,
      source: data.source.present ? data.source.value : this.source,
      metadataJson: data.metadataJson.present
          ? data.metadataJson.value
          : this.metadataJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CalendarEvent(')
          ..write('id: $id, ')
          ..write('fieldId: $fieldId, ')
          ..write('cropId: $cropId, ')
          ..write('title: $title, ')
          ..write('eventType: $eventType, ')
          ..write('eventDate: $eventDate, ')
          ..write('source: $source, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, fieldId, cropId, title, eventType,
      eventDate, source, metadataJson, createdAt, updatedAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CalendarEvent &&
          other.id == this.id &&
          other.fieldId == this.fieldId &&
          other.cropId == this.cropId &&
          other.title == this.title &&
          other.eventType == this.eventType &&
          other.eventDate == this.eventDate &&
          other.source == this.source &&
          other.metadataJson == this.metadataJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class CalendarEventsCompanion extends UpdateCompanion<CalendarEvent> {
  final Value<String> id;
  final Value<String?> fieldId;
  final Value<String?> cropId;
  final Value<String> title;
  final Value<String> eventType;
  final Value<DateTime> eventDate;
  final Value<String> source;
  final Value<String?> metadataJson;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const CalendarEventsCompanion({
    this.id = const Value.absent(),
    this.fieldId = const Value.absent(),
    this.cropId = const Value.absent(),
    this.title = const Value.absent(),
    this.eventType = const Value.absent(),
    this.eventDate = const Value.absent(),
    this.source = const Value.absent(),
    this.metadataJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CalendarEventsCompanion.insert({
    required String id,
    this.fieldId = const Value.absent(),
    this.cropId = const Value.absent(),
    required String title,
    required String eventType,
    required DateTime eventDate,
    this.source = const Value.absent(),
    this.metadataJson = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title),
        eventType = Value(eventType),
        eventDate = Value(eventDate),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<CalendarEvent> custom({
    Expression<String>? id,
    Expression<String>? fieldId,
    Expression<String>? cropId,
    Expression<String>? title,
    Expression<String>? eventType,
    Expression<DateTime>? eventDate,
    Expression<String>? source,
    Expression<String>? metadataJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fieldId != null) 'field_id': fieldId,
      if (cropId != null) 'crop_id': cropId,
      if (title != null) 'title': title,
      if (eventType != null) 'event_type': eventType,
      if (eventDate != null) 'event_date': eventDate,
      if (source != null) 'source': source,
      if (metadataJson != null) 'metadata_json': metadataJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CalendarEventsCompanion copyWith(
      {Value<String>? id,
      Value<String?>? fieldId,
      Value<String?>? cropId,
      Value<String>? title,
      Value<String>? eventType,
      Value<DateTime>? eventDate,
      Value<String>? source,
      Value<String?>? metadataJson,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<int>? rowid}) {
    return CalendarEventsCompanion(
      id: id ?? this.id,
      fieldId: fieldId ?? this.fieldId,
      cropId: cropId ?? this.cropId,
      title: title ?? this.title,
      eventType: eventType ?? this.eventType,
      eventDate: eventDate ?? this.eventDate,
      source: source ?? this.source,
      metadataJson: metadataJson ?? this.metadataJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (fieldId.present) {
      map['field_id'] = Variable<String>(fieldId.value);
    }
    if (cropId.present) {
      map['crop_id'] = Variable<String>(cropId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (eventDate.present) {
      map['event_date'] = Variable<DateTime>(eventDate.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (metadataJson.present) {
      map['metadata_json'] = Variable<String>(metadataJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CalendarEventsCompanion(')
          ..write('id: $id, ')
          ..write('fieldId: $fieldId, ')
          ..write('cropId: $cropId, ')
          ..write('title: $title, ')
          ..write('eventType: $eventType, ')
          ..write('eventDate: $eventDate, ')
          ..write('source: $source, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $IrrigationPlansTable extends IrrigationPlans
    with TableInfo<$IrrigationPlansTable, IrrigationPlan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IrrigationPlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fieldIdMeta =
      const VerificationMeta('fieldId');
  @override
  late final GeneratedColumn<String> fieldId = GeneratedColumn<String>(
      'field_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES fields (id)'));
  static const VerificationMeta _cropIdMeta = const VerificationMeta('cropId');
  @override
  late final GeneratedColumn<String> cropId = GeneratedColumn<String>(
      'crop_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES field_crops (id)'));
  static const VerificationMeta _scheduledDateMeta =
      const VerificationMeta('scheduledDate');
  @override
  late final GeneratedColumn<DateTime> scheduledDate =
      GeneratedColumn<DateTime>('scheduled_date', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _shouldIrrigateMeta =
      const VerificationMeta('shouldIrrigate');
  @override
  late final GeneratedColumn<bool> shouldIrrigate = GeneratedColumn<bool>(
      'should_irrigate', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("should_irrigate" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
      'reason', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _recommendationMeta =
      const VerificationMeta('recommendation');
  @override
  late final GeneratedColumn<String> recommendation = GeneratedColumn<String>(
      'recommendation', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        fieldId,
        cropId,
        scheduledDate,
        shouldIrrigate,
        reason,
        recommendation,
        createdAt,
        updatedAt,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'irrigation_plans';
  @override
  VerificationContext validateIntegrity(Insertable<IrrigationPlan> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('field_id')) {
      context.handle(_fieldIdMeta,
          fieldId.isAcceptableOrUnknown(data['field_id']!, _fieldIdMeta));
    } else if (isInserting) {
      context.missing(_fieldIdMeta);
    }
    if (data.containsKey('crop_id')) {
      context.handle(_cropIdMeta,
          cropId.isAcceptableOrUnknown(data['crop_id']!, _cropIdMeta));
    }
    if (data.containsKey('scheduled_date')) {
      context.handle(
          _scheduledDateMeta,
          scheduledDate.isAcceptableOrUnknown(
              data['scheduled_date']!, _scheduledDateMeta));
    } else if (isInserting) {
      context.missing(_scheduledDateMeta);
    }
    if (data.containsKey('should_irrigate')) {
      context.handle(
          _shouldIrrigateMeta,
          shouldIrrigate.isAcceptableOrUnknown(
              data['should_irrigate']!, _shouldIrrigateMeta));
    }
    if (data.containsKey('reason')) {
      context.handle(_reasonMeta,
          reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta));
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('recommendation')) {
      context.handle(
          _recommendationMeta,
          recommendation.isAcceptableOrUnknown(
              data['recommendation']!, _recommendationMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  IrrigationPlan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IrrigationPlan(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      fieldId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}field_id'])!,
      cropId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}crop_id']),
      scheduledDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}scheduled_date'])!,
      shouldIrrigate: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}should_irrigate'])!,
      reason: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reason'])!,
      recommendation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}recommendation']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $IrrigationPlansTable createAlias(String alias) {
    return $IrrigationPlansTable(attachedDatabase, alias);
  }
}

class IrrigationPlan extends DataClass implements Insertable<IrrigationPlan> {
  final String id;
  final String fieldId;
  final String? cropId;
  final DateTime scheduledDate;
  final bool shouldIrrigate;
  final String reason;
  final String? recommendation;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const IrrigationPlan(
      {required this.id,
      required this.fieldId,
      this.cropId,
      required this.scheduledDate,
      required this.shouldIrrigate,
      required this.reason,
      this.recommendation,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['field_id'] = Variable<String>(fieldId);
    if (!nullToAbsent || cropId != null) {
      map['crop_id'] = Variable<String>(cropId);
    }
    map['scheduled_date'] = Variable<DateTime>(scheduledDate);
    map['should_irrigate'] = Variable<bool>(shouldIrrigate);
    map['reason'] = Variable<String>(reason);
    if (!nullToAbsent || recommendation != null) {
      map['recommendation'] = Variable<String>(recommendation);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  IrrigationPlansCompanion toCompanion(bool nullToAbsent) {
    return IrrigationPlansCompanion(
      id: Value(id),
      fieldId: Value(fieldId),
      cropId:
          cropId == null && nullToAbsent ? const Value.absent() : Value(cropId),
      scheduledDate: Value(scheduledDate),
      shouldIrrigate: Value(shouldIrrigate),
      reason: Value(reason),
      recommendation: recommendation == null && nullToAbsent
          ? const Value.absent()
          : Value(recommendation),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory IrrigationPlan.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IrrigationPlan(
      id: serializer.fromJson<String>(json['id']),
      fieldId: serializer.fromJson<String>(json['fieldId']),
      cropId: serializer.fromJson<String?>(json['cropId']),
      scheduledDate: serializer.fromJson<DateTime>(json['scheduledDate']),
      shouldIrrigate: serializer.fromJson<bool>(json['shouldIrrigate']),
      reason: serializer.fromJson<String>(json['reason']),
      recommendation: serializer.fromJson<String?>(json['recommendation']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'fieldId': serializer.toJson<String>(fieldId),
      'cropId': serializer.toJson<String?>(cropId),
      'scheduledDate': serializer.toJson<DateTime>(scheduledDate),
      'shouldIrrigate': serializer.toJson<bool>(shouldIrrigate),
      'reason': serializer.toJson<String>(reason),
      'recommendation': serializer.toJson<String?>(recommendation),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  IrrigationPlan copyWith(
          {String? id,
          String? fieldId,
          Value<String?> cropId = const Value.absent(),
          DateTime? scheduledDate,
          bool? shouldIrrigate,
          String? reason,
          Value<String?> recommendation = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent()}) =>
      IrrigationPlan(
        id: id ?? this.id,
        fieldId: fieldId ?? this.fieldId,
        cropId: cropId.present ? cropId.value : this.cropId,
        scheduledDate: scheduledDate ?? this.scheduledDate,
        shouldIrrigate: shouldIrrigate ?? this.shouldIrrigate,
        reason: reason ?? this.reason,
        recommendation:
            recommendation.present ? recommendation.value : this.recommendation,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  IrrigationPlan copyWithCompanion(IrrigationPlansCompanion data) {
    return IrrigationPlan(
      id: data.id.present ? data.id.value : this.id,
      fieldId: data.fieldId.present ? data.fieldId.value : this.fieldId,
      cropId: data.cropId.present ? data.cropId.value : this.cropId,
      scheduledDate: data.scheduledDate.present
          ? data.scheduledDate.value
          : this.scheduledDate,
      shouldIrrigate: data.shouldIrrigate.present
          ? data.shouldIrrigate.value
          : this.shouldIrrigate,
      reason: data.reason.present ? data.reason.value : this.reason,
      recommendation: data.recommendation.present
          ? data.recommendation.value
          : this.recommendation,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IrrigationPlan(')
          ..write('id: $id, ')
          ..write('fieldId: $fieldId, ')
          ..write('cropId: $cropId, ')
          ..write('scheduledDate: $scheduledDate, ')
          ..write('shouldIrrigate: $shouldIrrigate, ')
          ..write('reason: $reason, ')
          ..write('recommendation: $recommendation, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, fieldId, cropId, scheduledDate,
      shouldIrrigate, reason, recommendation, createdAt, updatedAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IrrigationPlan &&
          other.id == this.id &&
          other.fieldId == this.fieldId &&
          other.cropId == this.cropId &&
          other.scheduledDate == this.scheduledDate &&
          other.shouldIrrigate == this.shouldIrrigate &&
          other.reason == this.reason &&
          other.recommendation == this.recommendation &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class IrrigationPlansCompanion extends UpdateCompanion<IrrigationPlan> {
  final Value<String> id;
  final Value<String> fieldId;
  final Value<String?> cropId;
  final Value<DateTime> scheduledDate;
  final Value<bool> shouldIrrigate;
  final Value<String> reason;
  final Value<String?> recommendation;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const IrrigationPlansCompanion({
    this.id = const Value.absent(),
    this.fieldId = const Value.absent(),
    this.cropId = const Value.absent(),
    this.scheduledDate = const Value.absent(),
    this.shouldIrrigate = const Value.absent(),
    this.reason = const Value.absent(),
    this.recommendation = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IrrigationPlansCompanion.insert({
    required String id,
    required String fieldId,
    this.cropId = const Value.absent(),
    required DateTime scheduledDate,
    this.shouldIrrigate = const Value.absent(),
    required String reason,
    this.recommendation = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        fieldId = Value(fieldId),
        scheduledDate = Value(scheduledDate),
        reason = Value(reason),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<IrrigationPlan> custom({
    Expression<String>? id,
    Expression<String>? fieldId,
    Expression<String>? cropId,
    Expression<DateTime>? scheduledDate,
    Expression<bool>? shouldIrrigate,
    Expression<String>? reason,
    Expression<String>? recommendation,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fieldId != null) 'field_id': fieldId,
      if (cropId != null) 'crop_id': cropId,
      if (scheduledDate != null) 'scheduled_date': scheduledDate,
      if (shouldIrrigate != null) 'should_irrigate': shouldIrrigate,
      if (reason != null) 'reason': reason,
      if (recommendation != null) 'recommendation': recommendation,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IrrigationPlansCompanion copyWith(
      {Value<String>? id,
      Value<String>? fieldId,
      Value<String?>? cropId,
      Value<DateTime>? scheduledDate,
      Value<bool>? shouldIrrigate,
      Value<String>? reason,
      Value<String?>? recommendation,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<int>? rowid}) {
    return IrrigationPlansCompanion(
      id: id ?? this.id,
      fieldId: fieldId ?? this.fieldId,
      cropId: cropId ?? this.cropId,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      shouldIrrigate: shouldIrrigate ?? this.shouldIrrigate,
      reason: reason ?? this.reason,
      recommendation: recommendation ?? this.recommendation,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (fieldId.present) {
      map['field_id'] = Variable<String>(fieldId.value);
    }
    if (cropId.present) {
      map['crop_id'] = Variable<String>(cropId.value);
    }
    if (scheduledDate.present) {
      map['scheduled_date'] = Variable<DateTime>(scheduledDate.value);
    }
    if (shouldIrrigate.present) {
      map['should_irrigate'] = Variable<bool>(shouldIrrigate.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (recommendation.present) {
      map['recommendation'] = Variable<String>(recommendation.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IrrigationPlansCompanion(')
          ..write('id: $id, ')
          ..write('fieldId: $fieldId, ')
          ..write('cropId: $cropId, ')
          ..write('scheduledDate: $scheduledDate, ')
          ..write('shouldIrrigate: $shouldIrrigate, ')
          ..write('reason: $reason, ')
          ..write('recommendation: $recommendation, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SuitabilityReportsTable extends SuitabilityReports
    with TableInfo<$SuitabilityReportsTable, SuitabilityReport> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SuitabilityReportsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fieldIdMeta =
      const VerificationMeta('fieldId');
  @override
  late final GeneratedColumn<String> fieldId = GeneratedColumn<String>(
      'field_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES fields (id)'));
  static const VerificationMeta _cropNameMeta =
      const VerificationMeta('cropName');
  @override
  late final GeneratedColumn<String> cropName = GeneratedColumn<String>(
      'crop_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<double> score = GeneratedColumn<double>(
      'score', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _reportJsonMeta =
      const VerificationMeta('reportJson');
  @override
  late final GeneratedColumn<String> reportJson = GeneratedColumn<String>(
      'report_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        fieldId,
        cropName,
        score,
        reportJson,
        createdAt,
        updatedAt,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'suitability_reports';
  @override
  VerificationContext validateIntegrity(Insertable<SuitabilityReport> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('field_id')) {
      context.handle(_fieldIdMeta,
          fieldId.isAcceptableOrUnknown(data['field_id']!, _fieldIdMeta));
    } else if (isInserting) {
      context.missing(_fieldIdMeta);
    }
    if (data.containsKey('crop_name')) {
      context.handle(_cropNameMeta,
          cropName.isAcceptableOrUnknown(data['crop_name']!, _cropNameMeta));
    } else if (isInserting) {
      context.missing(_cropNameMeta);
    }
    if (data.containsKey('score')) {
      context.handle(
          _scoreMeta, score.isAcceptableOrUnknown(data['score']!, _scoreMeta));
    }
    if (data.containsKey('report_json')) {
      context.handle(
          _reportJsonMeta,
          reportJson.isAcceptableOrUnknown(
              data['report_json']!, _reportJsonMeta));
    } else if (isInserting) {
      context.missing(_reportJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SuitabilityReport map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SuitabilityReport(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      fieldId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}field_id'])!,
      cropName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}crop_name'])!,
      score: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}score']),
      reportJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}report_json'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $SuitabilityReportsTable createAlias(String alias) {
    return $SuitabilityReportsTable(attachedDatabase, alias);
  }
}

class SuitabilityReport extends DataClass
    implements Insertable<SuitabilityReport> {
  final String id;
  final String fieldId;
  final String cropName;
  final double? score;
  final String reportJson;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const SuitabilityReport(
      {required this.id,
      required this.fieldId,
      required this.cropName,
      this.score,
      required this.reportJson,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['field_id'] = Variable<String>(fieldId);
    map['crop_name'] = Variable<String>(cropName);
    if (!nullToAbsent || score != null) {
      map['score'] = Variable<double>(score);
    }
    map['report_json'] = Variable<String>(reportJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  SuitabilityReportsCompanion toCompanion(bool nullToAbsent) {
    return SuitabilityReportsCompanion(
      id: Value(id),
      fieldId: Value(fieldId),
      cropName: Value(cropName),
      score:
          score == null && nullToAbsent ? const Value.absent() : Value(score),
      reportJson: Value(reportJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory SuitabilityReport.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SuitabilityReport(
      id: serializer.fromJson<String>(json['id']),
      fieldId: serializer.fromJson<String>(json['fieldId']),
      cropName: serializer.fromJson<String>(json['cropName']),
      score: serializer.fromJson<double?>(json['score']),
      reportJson: serializer.fromJson<String>(json['reportJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'fieldId': serializer.toJson<String>(fieldId),
      'cropName': serializer.toJson<String>(cropName),
      'score': serializer.toJson<double?>(score),
      'reportJson': serializer.toJson<String>(reportJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  SuitabilityReport copyWith(
          {String? id,
          String? fieldId,
          String? cropName,
          Value<double?> score = const Value.absent(),
          String? reportJson,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent()}) =>
      SuitabilityReport(
        id: id ?? this.id,
        fieldId: fieldId ?? this.fieldId,
        cropName: cropName ?? this.cropName,
        score: score.present ? score.value : this.score,
        reportJson: reportJson ?? this.reportJson,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  SuitabilityReport copyWithCompanion(SuitabilityReportsCompanion data) {
    return SuitabilityReport(
      id: data.id.present ? data.id.value : this.id,
      fieldId: data.fieldId.present ? data.fieldId.value : this.fieldId,
      cropName: data.cropName.present ? data.cropName.value : this.cropName,
      score: data.score.present ? data.score.value : this.score,
      reportJson:
          data.reportJson.present ? data.reportJson.value : this.reportJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SuitabilityReport(')
          ..write('id: $id, ')
          ..write('fieldId: $fieldId, ')
          ..write('cropName: $cropName, ')
          ..write('score: $score, ')
          ..write('reportJson: $reportJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, fieldId, cropName, score, reportJson,
      createdAt, updatedAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SuitabilityReport &&
          other.id == this.id &&
          other.fieldId == this.fieldId &&
          other.cropName == this.cropName &&
          other.score == this.score &&
          other.reportJson == this.reportJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class SuitabilityReportsCompanion extends UpdateCompanion<SuitabilityReport> {
  final Value<String> id;
  final Value<String> fieldId;
  final Value<String> cropName;
  final Value<double?> score;
  final Value<String> reportJson;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const SuitabilityReportsCompanion({
    this.id = const Value.absent(),
    this.fieldId = const Value.absent(),
    this.cropName = const Value.absent(),
    this.score = const Value.absent(),
    this.reportJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SuitabilityReportsCompanion.insert({
    required String id,
    required String fieldId,
    required String cropName,
    this.score = const Value.absent(),
    required String reportJson,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        fieldId = Value(fieldId),
        cropName = Value(cropName),
        reportJson = Value(reportJson),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<SuitabilityReport> custom({
    Expression<String>? id,
    Expression<String>? fieldId,
    Expression<String>? cropName,
    Expression<double>? score,
    Expression<String>? reportJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fieldId != null) 'field_id': fieldId,
      if (cropName != null) 'crop_name': cropName,
      if (score != null) 'score': score,
      if (reportJson != null) 'report_json': reportJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SuitabilityReportsCompanion copyWith(
      {Value<String>? id,
      Value<String>? fieldId,
      Value<String>? cropName,
      Value<double?>? score,
      Value<String>? reportJson,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<int>? rowid}) {
    return SuitabilityReportsCompanion(
      id: id ?? this.id,
      fieldId: fieldId ?? this.fieldId,
      cropName: cropName ?? this.cropName,
      score: score ?? this.score,
      reportJson: reportJson ?? this.reportJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (fieldId.present) {
      map['field_id'] = Variable<String>(fieldId.value);
    }
    if (cropName.present) {
      map['crop_name'] = Variable<String>(cropName.value);
    }
    if (score.present) {
      map['score'] = Variable<double>(score.value);
    }
    if (reportJson.present) {
      map['report_json'] = Variable<String>(reportJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SuitabilityReportsCompanion(')
          ..write('id: $id, ')
          ..write('fieldId: $fieldId, ')
          ..write('cropName: $cropName, ')
          ..write('score: $score, ')
          ..write('reportJson: $reportJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncJobsTable extends SyncJobs with TableInfo<$SyncJobsTable, SyncJob> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncJobsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _entityTypeMeta =
      const VerificationMeta('entityType');
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
      'entity_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityIdMeta =
      const VerificationMeta('entityId');
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
      'entity_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _operationMeta =
      const VerificationMeta('operation');
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
      'operation', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadJsonMeta =
      const VerificationMeta('payloadJson');
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
      'payload_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _attemptCountMeta =
      const VerificationMeta('attemptCount');
  @override
  late final GeneratedColumn<int> attemptCount = GeneratedColumn<int>(
      'attempt_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastErrorMeta =
      const VerificationMeta('lastError');
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
      'last_error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pending'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        entityType,
        entityId,
        operation,
        payloadJson,
        updatedAt,
        attemptCount,
        lastError,
        status
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_jobs';
  @override
  VerificationContext validateIntegrity(Insertable<SyncJob> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entity_type')) {
      context.handle(
          _entityTypeMeta,
          entityType.isAcceptableOrUnknown(
              data['entity_type']!, _entityTypeMeta));
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(_entityIdMeta,
          entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta));
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(_operationMeta,
          operation.isAcceptableOrUnknown(data['operation']!, _operationMeta));
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
          _payloadJsonMeta,
          payloadJson.isAcceptableOrUnknown(
              data['payload_json']!, _payloadJsonMeta));
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
          _attemptCountMeta,
          attemptCount.isAcceptableOrUnknown(
              data['attempt_count']!, _attemptCountMeta));
    }
    if (data.containsKey('last_error')) {
      context.handle(_lastErrorMeta,
          lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncJob map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncJob(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      entityType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_type'])!,
      entityId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_id'])!,
      operation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}operation'])!,
      payloadJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload_json'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      attemptCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}attempt_count'])!,
      lastError: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_error']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
    );
  }

  @override
  $SyncJobsTable createAlias(String alias) {
    return $SyncJobsTable(attachedDatabase, alias);
  }
}

class SyncJob extends DataClass implements Insertable<SyncJob> {
  final int id;
  final String entityType;
  final String entityId;
  final String operation;
  final String payloadJson;
  final DateTime updatedAt;
  final int attemptCount;
  final String? lastError;
  final String status;
  const SyncJob(
      {required this.id,
      required this.entityType,
      required this.entityId,
      required this.operation,
      required this.payloadJson,
      required this.updatedAt,
      required this.attemptCount,
      this.lastError,
      required this.status});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['operation'] = Variable<String>(operation);
    map['payload_json'] = Variable<String>(payloadJson);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['attempt_count'] = Variable<int>(attemptCount);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['status'] = Variable<String>(status);
    return map;
  }

  SyncJobsCompanion toCompanion(bool nullToAbsent) {
    return SyncJobsCompanion(
      id: Value(id),
      entityType: Value(entityType),
      entityId: Value(entityId),
      operation: Value(operation),
      payloadJson: Value(payloadJson),
      updatedAt: Value(updatedAt),
      attemptCount: Value(attemptCount),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      status: Value(status),
    );
  }

  factory SyncJob.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncJob(
      id: serializer.fromJson<int>(json['id']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      operation: serializer.fromJson<String>(json['operation']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      attemptCount: serializer.fromJson<int>(json['attemptCount']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'operation': serializer.toJson<String>(operation),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'attemptCount': serializer.toJson<int>(attemptCount),
      'lastError': serializer.toJson<String?>(lastError),
      'status': serializer.toJson<String>(status),
    };
  }

  SyncJob copyWith(
          {int? id,
          String? entityType,
          String? entityId,
          String? operation,
          String? payloadJson,
          DateTime? updatedAt,
          int? attemptCount,
          Value<String?> lastError = const Value.absent(),
          String? status}) =>
      SyncJob(
        id: id ?? this.id,
        entityType: entityType ?? this.entityType,
        entityId: entityId ?? this.entityId,
        operation: operation ?? this.operation,
        payloadJson: payloadJson ?? this.payloadJson,
        updatedAt: updatedAt ?? this.updatedAt,
        attemptCount: attemptCount ?? this.attemptCount,
        lastError: lastError.present ? lastError.value : this.lastError,
        status: status ?? this.status,
      );
  SyncJob copyWithCompanion(SyncJobsCompanion data) {
    return SyncJob(
      id: data.id.present ? data.id.value : this.id,
      entityType:
          data.entityType.present ? data.entityType.value : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      operation: data.operation.present ? data.operation.value : this.operation,
      payloadJson:
          data.payloadJson.present ? data.payloadJson.value : this.payloadJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      attemptCount: data.attemptCount.present
          ? data.attemptCount.value
          : this.attemptCount,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncJob(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('lastError: $lastError, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, entityType, entityId, operation,
      payloadJson, updatedAt, attemptCount, lastError, status);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncJob &&
          other.id == this.id &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.operation == this.operation &&
          other.payloadJson == this.payloadJson &&
          other.updatedAt == this.updatedAt &&
          other.attemptCount == this.attemptCount &&
          other.lastError == this.lastError &&
          other.status == this.status);
}

class SyncJobsCompanion extends UpdateCompanion<SyncJob> {
  final Value<int> id;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> operation;
  final Value<String> payloadJson;
  final Value<DateTime> updatedAt;
  final Value<int> attemptCount;
  final Value<String?> lastError;
  final Value<String> status;
  const SyncJobsCompanion({
    this.id = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.operation = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.status = const Value.absent(),
  });
  SyncJobsCompanion.insert({
    this.id = const Value.absent(),
    required String entityType,
    required String entityId,
    required String operation,
    required String payloadJson,
    required DateTime updatedAt,
    this.attemptCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.status = const Value.absent(),
  })  : entityType = Value(entityType),
        entityId = Value(entityId),
        operation = Value(operation),
        payloadJson = Value(payloadJson),
        updatedAt = Value(updatedAt);
  static Insertable<SyncJob> custom({
    Expression<int>? id,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? operation,
    Expression<String>? payloadJson,
    Expression<DateTime>? updatedAt,
    Expression<int>? attemptCount,
    Expression<String>? lastError,
    Expression<String>? status,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (operation != null) 'operation': operation,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (lastError != null) 'last_error': lastError,
      if (status != null) 'status': status,
    });
  }

  SyncJobsCompanion copyWith(
      {Value<int>? id,
      Value<String>? entityType,
      Value<String>? entityId,
      Value<String>? operation,
      Value<String>? payloadJson,
      Value<DateTime>? updatedAt,
      Value<int>? attemptCount,
      Value<String?>? lastError,
      Value<String>? status}) {
    return SyncJobsCompanion(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      payloadJson: payloadJson ?? this.payloadJson,
      updatedAt: updatedAt ?? this.updatedAt,
      attemptCount: attemptCount ?? this.attemptCount,
      lastError: lastError ?? this.lastError,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncJobsCompanion(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('lastError: $lastError, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }
}

class $SyncStateTable extends SyncState
    with TableInfo<$SyncStateTable, SyncStateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_state';
  @override
  VerificationContext validateIntegrity(Insertable<SyncStateData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SyncStateData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncStateData(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $SyncStateTable createAlias(String alias) {
    return $SyncStateTable(attachedDatabase, alias);
  }
}

class SyncStateData extends DataClass implements Insertable<SyncStateData> {
  final String key;
  final String? value;
  final DateTime updatedAt;
  const SyncStateData({required this.key, this.value, required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<String>(value);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SyncStateCompanion toCompanion(bool nullToAbsent) {
    return SyncStateCompanion(
      key: Value(key),
      value:
          value == null && nullToAbsent ? const Value.absent() : Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory SyncStateData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncStateData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String?>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String?>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SyncStateData copyWith(
          {String? key,
          Value<String?> value = const Value.absent(),
          DateTime? updatedAt}) =>
      SyncStateData(
        key: key ?? this.key,
        value: value.present ? value.value : this.value,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  SyncStateData copyWithCompanion(SyncStateCompanion data) {
    return SyncStateData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateData(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncStateData &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class SyncStateCompanion extends UpdateCompanion<SyncStateData> {
  final Value<String> key;
  final Value<String?> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SyncStateCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncStateCompanion.insert({
    required String key,
    this.value = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        updatedAt = Value(updatedAt);
  static Insertable<SyncStateData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncStateCompanion copyWith(
      {Value<String>? key,
      Value<String?>? value,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return SyncStateCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $FieldsTable fields = $FieldsTable(this);
  late final $FieldCropsTable fieldCrops = $FieldCropsTable(this);
  late final $CalendarEventsTable calendarEvents = $CalendarEventsTable(this);
  late final $IrrigationPlansTable irrigationPlans =
      $IrrigationPlansTable(this);
  late final $SuitabilityReportsTable suitabilityReports =
      $SuitabilityReportsTable(this);
  late final $SyncJobsTable syncJobs = $SyncJobsTable(this);
  late final $SyncStateTable syncState = $SyncStateTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        fields,
        fieldCrops,
        calendarEvents,
        irrigationPlans,
        suitabilityReports,
        syncJobs,
        syncState
      ];
}

typedef $$FieldsTableCreateCompanionBuilder = FieldsCompanion Function({
  required String id,
  required String name,
  Value<String?> crop,
  required String date,
  Value<double?> latitude,
  Value<double?> longitude,
  Value<double?> areaDekar,
  Value<double?> areaSqm,
  Value<String?> polygonJson,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});
typedef $$FieldsTableUpdateCompanionBuilder = FieldsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String?> crop,
  Value<String> date,
  Value<double?> latitude,
  Value<double?> longitude,
  Value<double?> areaDekar,
  Value<double?> areaSqm,
  Value<String?> polygonJson,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});

final class $$FieldsTableReferences
    extends BaseReferences<_$AppDatabase, $FieldsTable, Field> {
  $$FieldsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$FieldCropsTable, List<FieldCrop>>
      _fieldCropsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.fieldCrops,
          aliasName: $_aliasNameGenerator(db.fields.id, db.fieldCrops.fieldId));

  $$FieldCropsTableProcessedTableManager get fieldCropsRefs {
    final manager = $$FieldCropsTableTableManager($_db, $_db.fieldCrops)
        .filter((f) => f.fieldId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_fieldCropsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$CalendarEventsTable, List<CalendarEvent>>
      _calendarEventsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.calendarEvents,
              aliasName: $_aliasNameGenerator(
                  db.fields.id, db.calendarEvents.fieldId));

  $$CalendarEventsTableProcessedTableManager get calendarEventsRefs {
    final manager = $$CalendarEventsTableTableManager($_db, $_db.calendarEvents)
        .filter((f) => f.fieldId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_calendarEventsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$IrrigationPlansTable, List<IrrigationPlan>>
      _irrigationPlansRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.irrigationPlans,
              aliasName: $_aliasNameGenerator(
                  db.fields.id, db.irrigationPlans.fieldId));

  $$IrrigationPlansTableProcessedTableManager get irrigationPlansRefs {
    final manager =
        $$IrrigationPlansTableTableManager($_db, $_db.irrigationPlans)
            .filter((f) => f.fieldId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_irrigationPlansRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$SuitabilityReportsTable, List<SuitabilityReport>>
      _suitabilityReportsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.suitabilityReports,
              aliasName: $_aliasNameGenerator(
                  db.fields.id, db.suitabilityReports.fieldId));

  $$SuitabilityReportsTableProcessedTableManager get suitabilityReportsRefs {
    final manager =
        $$SuitabilityReportsTableTableManager($_db, $_db.suitabilityReports)
            .filter((f) => f.fieldId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_suitabilityReportsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$FieldsTableFilterComposer
    extends Composer<_$AppDatabase, $FieldsTable> {
  $$FieldsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get crop => $composableBuilder(
      column: $table.crop, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get areaDekar => $composableBuilder(
      column: $table.areaDekar, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get areaSqm => $composableBuilder(
      column: $table.areaSqm, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get polygonJson => $composableBuilder(
      column: $table.polygonJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> fieldCropsRefs(
      Expression<bool> Function($$FieldCropsTableFilterComposer f) f) {
    final $$FieldCropsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.fieldCrops,
        getReferencedColumn: (t) => t.fieldId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FieldCropsTableFilterComposer(
              $db: $db,
              $table: $db.fieldCrops,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> calendarEventsRefs(
      Expression<bool> Function($$CalendarEventsTableFilterComposer f) f) {
    final $$CalendarEventsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.calendarEvents,
        getReferencedColumn: (t) => t.fieldId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CalendarEventsTableFilterComposer(
              $db: $db,
              $table: $db.calendarEvents,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> irrigationPlansRefs(
      Expression<bool> Function($$IrrigationPlansTableFilterComposer f) f) {
    final $$IrrigationPlansTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.irrigationPlans,
        getReferencedColumn: (t) => t.fieldId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IrrigationPlansTableFilterComposer(
              $db: $db,
              $table: $db.irrigationPlans,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> suitabilityReportsRefs(
      Expression<bool> Function($$SuitabilityReportsTableFilterComposer f) f) {
    final $$SuitabilityReportsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.suitabilityReports,
        getReferencedColumn: (t) => t.fieldId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SuitabilityReportsTableFilterComposer(
              $db: $db,
              $table: $db.suitabilityReports,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$FieldsTableOrderingComposer
    extends Composer<_$AppDatabase, $FieldsTable> {
  $$FieldsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get crop => $composableBuilder(
      column: $table.crop, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get areaDekar => $composableBuilder(
      column: $table.areaDekar, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get areaSqm => $composableBuilder(
      column: $table.areaSqm, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get polygonJson => $composableBuilder(
      column: $table.polygonJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));
}

class $$FieldsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FieldsTable> {
  $$FieldsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get crop =>
      $composableBuilder(column: $table.crop, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<double> get areaDekar =>
      $composableBuilder(column: $table.areaDekar, builder: (column) => column);

  GeneratedColumn<double> get areaSqm =>
      $composableBuilder(column: $table.areaSqm, builder: (column) => column);

  GeneratedColumn<String> get polygonJson => $composableBuilder(
      column: $table.polygonJson, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  Expression<T> fieldCropsRefs<T extends Object>(
      Expression<T> Function($$FieldCropsTableAnnotationComposer a) f) {
    final $$FieldCropsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.fieldCrops,
        getReferencedColumn: (t) => t.fieldId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FieldCropsTableAnnotationComposer(
              $db: $db,
              $table: $db.fieldCrops,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> calendarEventsRefs<T extends Object>(
      Expression<T> Function($$CalendarEventsTableAnnotationComposer a) f) {
    final $$CalendarEventsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.calendarEvents,
        getReferencedColumn: (t) => t.fieldId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CalendarEventsTableAnnotationComposer(
              $db: $db,
              $table: $db.calendarEvents,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> irrigationPlansRefs<T extends Object>(
      Expression<T> Function($$IrrigationPlansTableAnnotationComposer a) f) {
    final $$IrrigationPlansTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.irrigationPlans,
        getReferencedColumn: (t) => t.fieldId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IrrigationPlansTableAnnotationComposer(
              $db: $db,
              $table: $db.irrigationPlans,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> suitabilityReportsRefs<T extends Object>(
      Expression<T> Function($$SuitabilityReportsTableAnnotationComposer a) f) {
    final $$SuitabilityReportsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.suitabilityReports,
            getReferencedColumn: (t) => t.fieldId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$SuitabilityReportsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.suitabilityReports,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$FieldsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FieldsTable,
    Field,
    $$FieldsTableFilterComposer,
    $$FieldsTableOrderingComposer,
    $$FieldsTableAnnotationComposer,
    $$FieldsTableCreateCompanionBuilder,
    $$FieldsTableUpdateCompanionBuilder,
    (Field, $$FieldsTableReferences),
    Field,
    PrefetchHooks Function(
        {bool fieldCropsRefs,
        bool calendarEventsRefs,
        bool irrigationPlansRefs,
        bool suitabilityReportsRefs})> {
  $$FieldsTableTableManager(_$AppDatabase db, $FieldsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FieldsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FieldsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FieldsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> crop = const Value.absent(),
            Value<String> date = const Value.absent(),
            Value<double?> latitude = const Value.absent(),
            Value<double?> longitude = const Value.absent(),
            Value<double?> areaDekar = const Value.absent(),
            Value<double?> areaSqm = const Value.absent(),
            Value<String?> polygonJson = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FieldsCompanion(
            id: id,
            name: name,
            crop: crop,
            date: date,
            latitude: latitude,
            longitude: longitude,
            areaDekar: areaDekar,
            areaSqm: areaSqm,
            polygonJson: polygonJson,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String?> crop = const Value.absent(),
            required String date,
            Value<double?> latitude = const Value.absent(),
            Value<double?> longitude = const Value.absent(),
            Value<double?> areaDekar = const Value.absent(),
            Value<double?> areaSqm = const Value.absent(),
            Value<String?> polygonJson = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FieldsCompanion.insert(
            id: id,
            name: name,
            crop: crop,
            date: date,
            latitude: latitude,
            longitude: longitude,
            areaDekar: areaDekar,
            areaSqm: areaSqm,
            polygonJson: polygonJson,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$FieldsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {fieldCropsRefs = false,
              calendarEventsRefs = false,
              irrigationPlansRefs = false,
              suitabilityReportsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (fieldCropsRefs) db.fieldCrops,
                if (calendarEventsRefs) db.calendarEvents,
                if (irrigationPlansRefs) db.irrigationPlans,
                if (suitabilityReportsRefs) db.suitabilityReports
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (fieldCropsRefs)
                    await $_getPrefetchedData<Field, $FieldsTable, FieldCrop>(
                        currentTable: table,
                        referencedTable:
                            $$FieldsTableReferences._fieldCropsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$FieldsTableReferences(db, table, p0)
                                .fieldCropsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.fieldId == item.id),
                        typedResults: items),
                  if (calendarEventsRefs)
                    await $_getPrefetchedData<Field, $FieldsTable,
                            CalendarEvent>(
                        currentTable: table,
                        referencedTable: $$FieldsTableReferences
                            ._calendarEventsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$FieldsTableReferences(db, table, p0)
                                .calendarEventsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.fieldId == item.id),
                        typedResults: items),
                  if (irrigationPlansRefs)
                    await $_getPrefetchedData<Field, $FieldsTable,
                            IrrigationPlan>(
                        currentTable: table,
                        referencedTable: $$FieldsTableReferences
                            ._irrigationPlansRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$FieldsTableReferences(db, table, p0)
                                .irrigationPlansRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.fieldId == item.id),
                        typedResults: items),
                  if (suitabilityReportsRefs)
                    await $_getPrefetchedData<Field, $FieldsTable,
                            SuitabilityReport>(
                        currentTable: table,
                        referencedTable: $$FieldsTableReferences
                            ._suitabilityReportsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$FieldsTableReferences(db, table, p0)
                                .suitabilityReportsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.fieldId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$FieldsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FieldsTable,
    Field,
    $$FieldsTableFilterComposer,
    $$FieldsTableOrderingComposer,
    $$FieldsTableAnnotationComposer,
    $$FieldsTableCreateCompanionBuilder,
    $$FieldsTableUpdateCompanionBuilder,
    (Field, $$FieldsTableReferences),
    Field,
    PrefetchHooks Function(
        {bool fieldCropsRefs,
        bool calendarEventsRefs,
        bool irrigationPlansRefs,
        bool suitabilityReportsRefs})>;
typedef $$FieldCropsTableCreateCompanionBuilder = FieldCropsCompanion Function({
  required String id,
  required String fieldId,
  required String name,
  required double zoneStart,
  required double zoneEnd,
  required double rowSpacingCm,
  required double plantSpacingCm,
  Value<int?> colorValue,
  Value<String?> plantedDate,
  Value<int?> harvestDays,
  Value<int?> waterIntervalDays,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});
typedef $$FieldCropsTableUpdateCompanionBuilder = FieldCropsCompanion Function({
  Value<String> id,
  Value<String> fieldId,
  Value<String> name,
  Value<double> zoneStart,
  Value<double> zoneEnd,
  Value<double> rowSpacingCm,
  Value<double> plantSpacingCm,
  Value<int?> colorValue,
  Value<String?> plantedDate,
  Value<int?> harvestDays,
  Value<int?> waterIntervalDays,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});

final class $$FieldCropsTableReferences
    extends BaseReferences<_$AppDatabase, $FieldCropsTable, FieldCrop> {
  $$FieldCropsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FieldsTable _fieldIdTable(_$AppDatabase db) => db.fields
      .createAlias($_aliasNameGenerator(db.fieldCrops.fieldId, db.fields.id));

  $$FieldsTableProcessedTableManager get fieldId {
    final $_column = $_itemColumn<String>('field_id')!;

    final manager = $$FieldsTableTableManager($_db, $_db.fields)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_fieldIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$CalendarEventsTable, List<CalendarEvent>>
      _calendarEventsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.calendarEvents,
              aliasName: $_aliasNameGenerator(
                  db.fieldCrops.id, db.calendarEvents.cropId));

  $$CalendarEventsTableProcessedTableManager get calendarEventsRefs {
    final manager = $$CalendarEventsTableTableManager($_db, $_db.calendarEvents)
        .filter((f) => f.cropId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_calendarEventsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$IrrigationPlansTable, List<IrrigationPlan>>
      _irrigationPlansRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.irrigationPlans,
              aliasName: $_aliasNameGenerator(
                  db.fieldCrops.id, db.irrigationPlans.cropId));

  $$IrrigationPlansTableProcessedTableManager get irrigationPlansRefs {
    final manager =
        $$IrrigationPlansTableTableManager($_db, $_db.irrigationPlans)
            .filter((f) => f.cropId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_irrigationPlansRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$FieldCropsTableFilterComposer
    extends Composer<_$AppDatabase, $FieldCropsTable> {
  $$FieldCropsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get zoneStart => $composableBuilder(
      column: $table.zoneStart, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get zoneEnd => $composableBuilder(
      column: $table.zoneEnd, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get rowSpacingCm => $composableBuilder(
      column: $table.rowSpacingCm, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get plantSpacingCm => $composableBuilder(
      column: $table.plantSpacingCm,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get colorValue => $composableBuilder(
      column: $table.colorValue, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get plantedDate => $composableBuilder(
      column: $table.plantedDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get harvestDays => $composableBuilder(
      column: $table.harvestDays, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get waterIntervalDays => $composableBuilder(
      column: $table.waterIntervalDays,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  $$FieldsTableFilterComposer get fieldId {
    final $$FieldsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.fieldId,
        referencedTable: $db.fields,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FieldsTableFilterComposer(
              $db: $db,
              $table: $db.fields,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> calendarEventsRefs(
      Expression<bool> Function($$CalendarEventsTableFilterComposer f) f) {
    final $$CalendarEventsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.calendarEvents,
        getReferencedColumn: (t) => t.cropId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CalendarEventsTableFilterComposer(
              $db: $db,
              $table: $db.calendarEvents,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> irrigationPlansRefs(
      Expression<bool> Function($$IrrigationPlansTableFilterComposer f) f) {
    final $$IrrigationPlansTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.irrigationPlans,
        getReferencedColumn: (t) => t.cropId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IrrigationPlansTableFilterComposer(
              $db: $db,
              $table: $db.irrigationPlans,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$FieldCropsTableOrderingComposer
    extends Composer<_$AppDatabase, $FieldCropsTable> {
  $$FieldCropsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get zoneStart => $composableBuilder(
      column: $table.zoneStart, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get zoneEnd => $composableBuilder(
      column: $table.zoneEnd, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get rowSpacingCm => $composableBuilder(
      column: $table.rowSpacingCm,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get plantSpacingCm => $composableBuilder(
      column: $table.plantSpacingCm,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get colorValue => $composableBuilder(
      column: $table.colorValue, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get plantedDate => $composableBuilder(
      column: $table.plantedDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get harvestDays => $composableBuilder(
      column: $table.harvestDays, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get waterIntervalDays => $composableBuilder(
      column: $table.waterIntervalDays,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  $$FieldsTableOrderingComposer get fieldId {
    final $$FieldsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.fieldId,
        referencedTable: $db.fields,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FieldsTableOrderingComposer(
              $db: $db,
              $table: $db.fields,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$FieldCropsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FieldCropsTable> {
  $$FieldCropsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get zoneStart =>
      $composableBuilder(column: $table.zoneStart, builder: (column) => column);

  GeneratedColumn<double> get zoneEnd =>
      $composableBuilder(column: $table.zoneEnd, builder: (column) => column);

  GeneratedColumn<double> get rowSpacingCm => $composableBuilder(
      column: $table.rowSpacingCm, builder: (column) => column);

  GeneratedColumn<double> get plantSpacingCm => $composableBuilder(
      column: $table.plantSpacingCm, builder: (column) => column);

  GeneratedColumn<int> get colorValue => $composableBuilder(
      column: $table.colorValue, builder: (column) => column);

  GeneratedColumn<String> get plantedDate => $composableBuilder(
      column: $table.plantedDate, builder: (column) => column);

  GeneratedColumn<int> get harvestDays => $composableBuilder(
      column: $table.harvestDays, builder: (column) => column);

  GeneratedColumn<int> get waterIntervalDays => $composableBuilder(
      column: $table.waterIntervalDays, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$FieldsTableAnnotationComposer get fieldId {
    final $$FieldsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.fieldId,
        referencedTable: $db.fields,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FieldsTableAnnotationComposer(
              $db: $db,
              $table: $db.fields,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> calendarEventsRefs<T extends Object>(
      Expression<T> Function($$CalendarEventsTableAnnotationComposer a) f) {
    final $$CalendarEventsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.calendarEvents,
        getReferencedColumn: (t) => t.cropId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CalendarEventsTableAnnotationComposer(
              $db: $db,
              $table: $db.calendarEvents,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> irrigationPlansRefs<T extends Object>(
      Expression<T> Function($$IrrigationPlansTableAnnotationComposer a) f) {
    final $$IrrigationPlansTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.irrigationPlans,
        getReferencedColumn: (t) => t.cropId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IrrigationPlansTableAnnotationComposer(
              $db: $db,
              $table: $db.irrigationPlans,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$FieldCropsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FieldCropsTable,
    FieldCrop,
    $$FieldCropsTableFilterComposer,
    $$FieldCropsTableOrderingComposer,
    $$FieldCropsTableAnnotationComposer,
    $$FieldCropsTableCreateCompanionBuilder,
    $$FieldCropsTableUpdateCompanionBuilder,
    (FieldCrop, $$FieldCropsTableReferences),
    FieldCrop,
    PrefetchHooks Function(
        {bool fieldId, bool calendarEventsRefs, bool irrigationPlansRefs})> {
  $$FieldCropsTableTableManager(_$AppDatabase db, $FieldCropsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FieldCropsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FieldCropsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FieldCropsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> fieldId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<double> zoneStart = const Value.absent(),
            Value<double> zoneEnd = const Value.absent(),
            Value<double> rowSpacingCm = const Value.absent(),
            Value<double> plantSpacingCm = const Value.absent(),
            Value<int?> colorValue = const Value.absent(),
            Value<String?> plantedDate = const Value.absent(),
            Value<int?> harvestDays = const Value.absent(),
            Value<int?> waterIntervalDays = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FieldCropsCompanion(
            id: id,
            fieldId: fieldId,
            name: name,
            zoneStart: zoneStart,
            zoneEnd: zoneEnd,
            rowSpacingCm: rowSpacingCm,
            plantSpacingCm: plantSpacingCm,
            colorValue: colorValue,
            plantedDate: plantedDate,
            harvestDays: harvestDays,
            waterIntervalDays: waterIntervalDays,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String fieldId,
            required String name,
            required double zoneStart,
            required double zoneEnd,
            required double rowSpacingCm,
            required double plantSpacingCm,
            Value<int?> colorValue = const Value.absent(),
            Value<String?> plantedDate = const Value.absent(),
            Value<int?> harvestDays = const Value.absent(),
            Value<int?> waterIntervalDays = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FieldCropsCompanion.insert(
            id: id,
            fieldId: fieldId,
            name: name,
            zoneStart: zoneStart,
            zoneEnd: zoneEnd,
            rowSpacingCm: rowSpacingCm,
            plantSpacingCm: plantSpacingCm,
            colorValue: colorValue,
            plantedDate: plantedDate,
            harvestDays: harvestDays,
            waterIntervalDays: waterIntervalDays,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$FieldCropsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {fieldId = false,
              calendarEventsRefs = false,
              irrigationPlansRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (calendarEventsRefs) db.calendarEvents,
                if (irrigationPlansRefs) db.irrigationPlans
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (fieldId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.fieldId,
                    referencedTable:
                        $$FieldCropsTableReferences._fieldIdTable(db),
                    referencedColumn:
                        $$FieldCropsTableReferences._fieldIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (calendarEventsRefs)
                    await $_getPrefetchedData<FieldCrop, $FieldCropsTable,
                            CalendarEvent>(
                        currentTable: table,
                        referencedTable: $$FieldCropsTableReferences
                            ._calendarEventsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$FieldCropsTableReferences(db, table, p0)
                                .calendarEventsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.cropId == item.id),
                        typedResults: items),
                  if (irrigationPlansRefs)
                    await $_getPrefetchedData<FieldCrop, $FieldCropsTable,
                            IrrigationPlan>(
                        currentTable: table,
                        referencedTable: $$FieldCropsTableReferences
                            ._irrigationPlansRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$FieldCropsTableReferences(db, table, p0)
                                .irrigationPlansRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.cropId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$FieldCropsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FieldCropsTable,
    FieldCrop,
    $$FieldCropsTableFilterComposer,
    $$FieldCropsTableOrderingComposer,
    $$FieldCropsTableAnnotationComposer,
    $$FieldCropsTableCreateCompanionBuilder,
    $$FieldCropsTableUpdateCompanionBuilder,
    (FieldCrop, $$FieldCropsTableReferences),
    FieldCrop,
    PrefetchHooks Function(
        {bool fieldId, bool calendarEventsRefs, bool irrigationPlansRefs})>;
typedef $$CalendarEventsTableCreateCompanionBuilder = CalendarEventsCompanion
    Function({
  required String id,
  Value<String?> fieldId,
  Value<String?> cropId,
  required String title,
  required String eventType,
  required DateTime eventDate,
  Value<String> source,
  Value<String?> metadataJson,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});
typedef $$CalendarEventsTableUpdateCompanionBuilder = CalendarEventsCompanion
    Function({
  Value<String> id,
  Value<String?> fieldId,
  Value<String?> cropId,
  Value<String> title,
  Value<String> eventType,
  Value<DateTime> eventDate,
  Value<String> source,
  Value<String?> metadataJson,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});

final class $$CalendarEventsTableReferences
    extends BaseReferences<_$AppDatabase, $CalendarEventsTable, CalendarEvent> {
  $$CalendarEventsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $FieldsTable _fieldIdTable(_$AppDatabase db) => db.fields.createAlias(
      $_aliasNameGenerator(db.calendarEvents.fieldId, db.fields.id));

  $$FieldsTableProcessedTableManager? get fieldId {
    final $_column = $_itemColumn<String>('field_id');
    if ($_column == null) return null;
    final manager = $$FieldsTableTableManager($_db, $_db.fields)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_fieldIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $FieldCropsTable _cropIdTable(_$AppDatabase db) =>
      db.fieldCrops.createAlias(
          $_aliasNameGenerator(db.calendarEvents.cropId, db.fieldCrops.id));

  $$FieldCropsTableProcessedTableManager? get cropId {
    final $_column = $_itemColumn<String>('crop_id');
    if ($_column == null) return null;
    final manager = $$FieldCropsTableTableManager($_db, $_db.fieldCrops)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cropIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$CalendarEventsTableFilterComposer
    extends Composer<_$AppDatabase, $CalendarEventsTable> {
  $$CalendarEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get eventType => $composableBuilder(
      column: $table.eventType, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get eventDate => $composableBuilder(
      column: $table.eventDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get metadataJson => $composableBuilder(
      column: $table.metadataJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  $$FieldsTableFilterComposer get fieldId {
    final $$FieldsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.fieldId,
        referencedTable: $db.fields,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FieldsTableFilterComposer(
              $db: $db,
              $table: $db.fields,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$FieldCropsTableFilterComposer get cropId {
    final $$FieldCropsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.cropId,
        referencedTable: $db.fieldCrops,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FieldCropsTableFilterComposer(
              $db: $db,
              $table: $db.fieldCrops,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CalendarEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $CalendarEventsTable> {
  $$CalendarEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get eventType => $composableBuilder(
      column: $table.eventType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get eventDate => $composableBuilder(
      column: $table.eventDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get metadataJson => $composableBuilder(
      column: $table.metadataJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  $$FieldsTableOrderingComposer get fieldId {
    final $$FieldsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.fieldId,
        referencedTable: $db.fields,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FieldsTableOrderingComposer(
              $db: $db,
              $table: $db.fields,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$FieldCropsTableOrderingComposer get cropId {
    final $$FieldCropsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.cropId,
        referencedTable: $db.fieldCrops,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FieldCropsTableOrderingComposer(
              $db: $db,
              $table: $db.fieldCrops,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CalendarEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CalendarEventsTable> {
  $$CalendarEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<DateTime> get eventDate =>
      $composableBuilder(column: $table.eventDate, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get metadataJson => $composableBuilder(
      column: $table.metadataJson, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$FieldsTableAnnotationComposer get fieldId {
    final $$FieldsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.fieldId,
        referencedTable: $db.fields,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FieldsTableAnnotationComposer(
              $db: $db,
              $table: $db.fields,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$FieldCropsTableAnnotationComposer get cropId {
    final $$FieldCropsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.cropId,
        referencedTable: $db.fieldCrops,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FieldCropsTableAnnotationComposer(
              $db: $db,
              $table: $db.fieldCrops,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CalendarEventsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CalendarEventsTable,
    CalendarEvent,
    $$CalendarEventsTableFilterComposer,
    $$CalendarEventsTableOrderingComposer,
    $$CalendarEventsTableAnnotationComposer,
    $$CalendarEventsTableCreateCompanionBuilder,
    $$CalendarEventsTableUpdateCompanionBuilder,
    (CalendarEvent, $$CalendarEventsTableReferences),
    CalendarEvent,
    PrefetchHooks Function({bool fieldId, bool cropId})> {
  $$CalendarEventsTableTableManager(
      _$AppDatabase db, $CalendarEventsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CalendarEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CalendarEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CalendarEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> fieldId = const Value.absent(),
            Value<String?> cropId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> eventType = const Value.absent(),
            Value<DateTime> eventDate = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<String?> metadataJson = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CalendarEventsCompanion(
            id: id,
            fieldId: fieldId,
            cropId: cropId,
            title: title,
            eventType: eventType,
            eventDate: eventDate,
            source: source,
            metadataJson: metadataJson,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String?> fieldId = const Value.absent(),
            Value<String?> cropId = const Value.absent(),
            required String title,
            required String eventType,
            required DateTime eventDate,
            Value<String> source = const Value.absent(),
            Value<String?> metadataJson = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CalendarEventsCompanion.insert(
            id: id,
            fieldId: fieldId,
            cropId: cropId,
            title: title,
            eventType: eventType,
            eventDate: eventDate,
            source: source,
            metadataJson: metadataJson,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$CalendarEventsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({fieldId = false, cropId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (fieldId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.fieldId,
                    referencedTable:
                        $$CalendarEventsTableReferences._fieldIdTable(db),
                    referencedColumn:
                        $$CalendarEventsTableReferences._fieldIdTable(db).id,
                  ) as T;
                }
                if (cropId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.cropId,
                    referencedTable:
                        $$CalendarEventsTableReferences._cropIdTable(db),
                    referencedColumn:
                        $$CalendarEventsTableReferences._cropIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$CalendarEventsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CalendarEventsTable,
    CalendarEvent,
    $$CalendarEventsTableFilterComposer,
    $$CalendarEventsTableOrderingComposer,
    $$CalendarEventsTableAnnotationComposer,
    $$CalendarEventsTableCreateCompanionBuilder,
    $$CalendarEventsTableUpdateCompanionBuilder,
    (CalendarEvent, $$CalendarEventsTableReferences),
    CalendarEvent,
    PrefetchHooks Function({bool fieldId, bool cropId})>;
typedef $$IrrigationPlansTableCreateCompanionBuilder = IrrigationPlansCompanion
    Function({
  required String id,
  required String fieldId,
  Value<String?> cropId,
  required DateTime scheduledDate,
  Value<bool> shouldIrrigate,
  required String reason,
  Value<String?> recommendation,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});
typedef $$IrrigationPlansTableUpdateCompanionBuilder = IrrigationPlansCompanion
    Function({
  Value<String> id,
  Value<String> fieldId,
  Value<String?> cropId,
  Value<DateTime> scheduledDate,
  Value<bool> shouldIrrigate,
  Value<String> reason,
  Value<String?> recommendation,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});

final class $$IrrigationPlansTableReferences extends BaseReferences<
    _$AppDatabase, $IrrigationPlansTable, IrrigationPlan> {
  $$IrrigationPlansTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $FieldsTable _fieldIdTable(_$AppDatabase db) => db.fields.createAlias(
      $_aliasNameGenerator(db.irrigationPlans.fieldId, db.fields.id));

  $$FieldsTableProcessedTableManager get fieldId {
    final $_column = $_itemColumn<String>('field_id')!;

    final manager = $$FieldsTableTableManager($_db, $_db.fields)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_fieldIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $FieldCropsTable _cropIdTable(_$AppDatabase db) =>
      db.fieldCrops.createAlias(
          $_aliasNameGenerator(db.irrigationPlans.cropId, db.fieldCrops.id));

  $$FieldCropsTableProcessedTableManager? get cropId {
    final $_column = $_itemColumn<String>('crop_id');
    if ($_column == null) return null;
    final manager = $$FieldCropsTableTableManager($_db, $_db.fieldCrops)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cropIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$IrrigationPlansTableFilterComposer
    extends Composer<_$AppDatabase, $IrrigationPlansTable> {
  $$IrrigationPlansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get scheduledDate => $composableBuilder(
      column: $table.scheduledDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get shouldIrrigate => $composableBuilder(
      column: $table.shouldIrrigate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get recommendation => $composableBuilder(
      column: $table.recommendation,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  $$FieldsTableFilterComposer get fieldId {
    final $$FieldsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.fieldId,
        referencedTable: $db.fields,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FieldsTableFilterComposer(
              $db: $db,
              $table: $db.fields,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$FieldCropsTableFilterComposer get cropId {
    final $$FieldCropsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.cropId,
        referencedTable: $db.fieldCrops,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FieldCropsTableFilterComposer(
              $db: $db,
              $table: $db.fieldCrops,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$IrrigationPlansTableOrderingComposer
    extends Composer<_$AppDatabase, $IrrigationPlansTable> {
  $$IrrigationPlansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get scheduledDate => $composableBuilder(
      column: $table.scheduledDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get shouldIrrigate => $composableBuilder(
      column: $table.shouldIrrigate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get recommendation => $composableBuilder(
      column: $table.recommendation,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  $$FieldsTableOrderingComposer get fieldId {
    final $$FieldsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.fieldId,
        referencedTable: $db.fields,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FieldsTableOrderingComposer(
              $db: $db,
              $table: $db.fields,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$FieldCropsTableOrderingComposer get cropId {
    final $$FieldCropsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.cropId,
        referencedTable: $db.fieldCrops,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FieldCropsTableOrderingComposer(
              $db: $db,
              $table: $db.fieldCrops,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$IrrigationPlansTableAnnotationComposer
    extends Composer<_$AppDatabase, $IrrigationPlansTable> {
  $$IrrigationPlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get scheduledDate => $composableBuilder(
      column: $table.scheduledDate, builder: (column) => column);

  GeneratedColumn<bool> get shouldIrrigate => $composableBuilder(
      column: $table.shouldIrrigate, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get recommendation => $composableBuilder(
      column: $table.recommendation, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$FieldsTableAnnotationComposer get fieldId {
    final $$FieldsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.fieldId,
        referencedTable: $db.fields,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FieldsTableAnnotationComposer(
              $db: $db,
              $table: $db.fields,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$FieldCropsTableAnnotationComposer get cropId {
    final $$FieldCropsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.cropId,
        referencedTable: $db.fieldCrops,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FieldCropsTableAnnotationComposer(
              $db: $db,
              $table: $db.fieldCrops,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$IrrigationPlansTableTableManager extends RootTableManager<
    _$AppDatabase,
    $IrrigationPlansTable,
    IrrigationPlan,
    $$IrrigationPlansTableFilterComposer,
    $$IrrigationPlansTableOrderingComposer,
    $$IrrigationPlansTableAnnotationComposer,
    $$IrrigationPlansTableCreateCompanionBuilder,
    $$IrrigationPlansTableUpdateCompanionBuilder,
    (IrrigationPlan, $$IrrigationPlansTableReferences),
    IrrigationPlan,
    PrefetchHooks Function({bool fieldId, bool cropId})> {
  $$IrrigationPlansTableTableManager(
      _$AppDatabase db, $IrrigationPlansTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IrrigationPlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IrrigationPlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IrrigationPlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> fieldId = const Value.absent(),
            Value<String?> cropId = const Value.absent(),
            Value<DateTime> scheduledDate = const Value.absent(),
            Value<bool> shouldIrrigate = const Value.absent(),
            Value<String> reason = const Value.absent(),
            Value<String?> recommendation = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              IrrigationPlansCompanion(
            id: id,
            fieldId: fieldId,
            cropId: cropId,
            scheduledDate: scheduledDate,
            shouldIrrigate: shouldIrrigate,
            reason: reason,
            recommendation: recommendation,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String fieldId,
            Value<String?> cropId = const Value.absent(),
            required DateTime scheduledDate,
            Value<bool> shouldIrrigate = const Value.absent(),
            required String reason,
            Value<String?> recommendation = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              IrrigationPlansCompanion.insert(
            id: id,
            fieldId: fieldId,
            cropId: cropId,
            scheduledDate: scheduledDate,
            shouldIrrigate: shouldIrrigate,
            reason: reason,
            recommendation: recommendation,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$IrrigationPlansTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({fieldId = false, cropId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (fieldId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.fieldId,
                    referencedTable:
                        $$IrrigationPlansTableReferences._fieldIdTable(db),
                    referencedColumn:
                        $$IrrigationPlansTableReferences._fieldIdTable(db).id,
                  ) as T;
                }
                if (cropId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.cropId,
                    referencedTable:
                        $$IrrigationPlansTableReferences._cropIdTable(db),
                    referencedColumn:
                        $$IrrigationPlansTableReferences._cropIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$IrrigationPlansTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $IrrigationPlansTable,
    IrrigationPlan,
    $$IrrigationPlansTableFilterComposer,
    $$IrrigationPlansTableOrderingComposer,
    $$IrrigationPlansTableAnnotationComposer,
    $$IrrigationPlansTableCreateCompanionBuilder,
    $$IrrigationPlansTableUpdateCompanionBuilder,
    (IrrigationPlan, $$IrrigationPlansTableReferences),
    IrrigationPlan,
    PrefetchHooks Function({bool fieldId, bool cropId})>;
typedef $$SuitabilityReportsTableCreateCompanionBuilder
    = SuitabilityReportsCompanion Function({
  required String id,
  required String fieldId,
  required String cropName,
  Value<double?> score,
  required String reportJson,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});
typedef $$SuitabilityReportsTableUpdateCompanionBuilder
    = SuitabilityReportsCompanion Function({
  Value<String> id,
  Value<String> fieldId,
  Value<String> cropName,
  Value<double?> score,
  Value<String> reportJson,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});

final class $$SuitabilityReportsTableReferences extends BaseReferences<
    _$AppDatabase, $SuitabilityReportsTable, SuitabilityReport> {
  $$SuitabilityReportsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $FieldsTable _fieldIdTable(_$AppDatabase db) => db.fields.createAlias(
      $_aliasNameGenerator(db.suitabilityReports.fieldId, db.fields.id));

  $$FieldsTableProcessedTableManager get fieldId {
    final $_column = $_itemColumn<String>('field_id')!;

    final manager = $$FieldsTableTableManager($_db, $_db.fields)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_fieldIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$SuitabilityReportsTableFilterComposer
    extends Composer<_$AppDatabase, $SuitabilityReportsTable> {
  $$SuitabilityReportsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cropName => $composableBuilder(
      column: $table.cropName, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get score => $composableBuilder(
      column: $table.score, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reportJson => $composableBuilder(
      column: $table.reportJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  $$FieldsTableFilterComposer get fieldId {
    final $$FieldsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.fieldId,
        referencedTable: $db.fields,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FieldsTableFilterComposer(
              $db: $db,
              $table: $db.fields,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SuitabilityReportsTableOrderingComposer
    extends Composer<_$AppDatabase, $SuitabilityReportsTable> {
  $$SuitabilityReportsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cropName => $composableBuilder(
      column: $table.cropName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get score => $composableBuilder(
      column: $table.score, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reportJson => $composableBuilder(
      column: $table.reportJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  $$FieldsTableOrderingComposer get fieldId {
    final $$FieldsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.fieldId,
        referencedTable: $db.fields,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FieldsTableOrderingComposer(
              $db: $db,
              $table: $db.fields,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SuitabilityReportsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SuitabilityReportsTable> {
  $$SuitabilityReportsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get cropName =>
      $composableBuilder(column: $table.cropName, builder: (column) => column);

  GeneratedColumn<double> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<String> get reportJson => $composableBuilder(
      column: $table.reportJson, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$FieldsTableAnnotationComposer get fieldId {
    final $$FieldsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.fieldId,
        referencedTable: $db.fields,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FieldsTableAnnotationComposer(
              $db: $db,
              $table: $db.fields,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SuitabilityReportsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SuitabilityReportsTable,
    SuitabilityReport,
    $$SuitabilityReportsTableFilterComposer,
    $$SuitabilityReportsTableOrderingComposer,
    $$SuitabilityReportsTableAnnotationComposer,
    $$SuitabilityReportsTableCreateCompanionBuilder,
    $$SuitabilityReportsTableUpdateCompanionBuilder,
    (SuitabilityReport, $$SuitabilityReportsTableReferences),
    SuitabilityReport,
    PrefetchHooks Function({bool fieldId})> {
  $$SuitabilityReportsTableTableManager(
      _$AppDatabase db, $SuitabilityReportsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SuitabilityReportsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SuitabilityReportsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SuitabilityReportsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> fieldId = const Value.absent(),
            Value<String> cropName = const Value.absent(),
            Value<double?> score = const Value.absent(),
            Value<String> reportJson = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SuitabilityReportsCompanion(
            id: id,
            fieldId: fieldId,
            cropName: cropName,
            score: score,
            reportJson: reportJson,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String fieldId,
            required String cropName,
            Value<double?> score = const Value.absent(),
            required String reportJson,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SuitabilityReportsCompanion.insert(
            id: id,
            fieldId: fieldId,
            cropName: cropName,
            score: score,
            reportJson: reportJson,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$SuitabilityReportsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({fieldId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (fieldId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.fieldId,
                    referencedTable:
                        $$SuitabilityReportsTableReferences._fieldIdTable(db),
                    referencedColumn: $$SuitabilityReportsTableReferences
                        ._fieldIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$SuitabilityReportsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SuitabilityReportsTable,
    SuitabilityReport,
    $$SuitabilityReportsTableFilterComposer,
    $$SuitabilityReportsTableOrderingComposer,
    $$SuitabilityReportsTableAnnotationComposer,
    $$SuitabilityReportsTableCreateCompanionBuilder,
    $$SuitabilityReportsTableUpdateCompanionBuilder,
    (SuitabilityReport, $$SuitabilityReportsTableReferences),
    SuitabilityReport,
    PrefetchHooks Function({bool fieldId})>;
typedef $$SyncJobsTableCreateCompanionBuilder = SyncJobsCompanion Function({
  Value<int> id,
  required String entityType,
  required String entityId,
  required String operation,
  required String payloadJson,
  required DateTime updatedAt,
  Value<int> attemptCount,
  Value<String?> lastError,
  Value<String> status,
});
typedef $$SyncJobsTableUpdateCompanionBuilder = SyncJobsCompanion Function({
  Value<int> id,
  Value<String> entityType,
  Value<String> entityId,
  Value<String> operation,
  Value<String> payloadJson,
  Value<DateTime> updatedAt,
  Value<int> attemptCount,
  Value<String?> lastError,
  Value<String> status,
});

class $$SyncJobsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncJobsTable> {
  $$SyncJobsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get operation => $composableBuilder(
      column: $table.operation, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get attemptCount => $composableBuilder(
      column: $table.attemptCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));
}

class $$SyncJobsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncJobsTable> {
  $$SyncJobsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get operation => $composableBuilder(
      column: $table.operation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get attemptCount => $composableBuilder(
      column: $table.attemptCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));
}

class $$SyncJobsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncJobsTable> {
  $$SyncJobsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get attemptCount => $composableBuilder(
      column: $table.attemptCount, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$SyncJobsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncJobsTable,
    SyncJob,
    $$SyncJobsTableFilterComposer,
    $$SyncJobsTableOrderingComposer,
    $$SyncJobsTableAnnotationComposer,
    $$SyncJobsTableCreateCompanionBuilder,
    $$SyncJobsTableUpdateCompanionBuilder,
    (SyncJob, BaseReferences<_$AppDatabase, $SyncJobsTable, SyncJob>),
    SyncJob,
    PrefetchHooks Function()> {
  $$SyncJobsTableTableManager(_$AppDatabase db, $SyncJobsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncJobsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncJobsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncJobsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> entityType = const Value.absent(),
            Value<String> entityId = const Value.absent(),
            Value<String> operation = const Value.absent(),
            Value<String> payloadJson = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> attemptCount = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<String> status = const Value.absent(),
          }) =>
              SyncJobsCompanion(
            id: id,
            entityType: entityType,
            entityId: entityId,
            operation: operation,
            payloadJson: payloadJson,
            updatedAt: updatedAt,
            attemptCount: attemptCount,
            lastError: lastError,
            status: status,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String entityType,
            required String entityId,
            required String operation,
            required String payloadJson,
            required DateTime updatedAt,
            Value<int> attemptCount = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<String> status = const Value.absent(),
          }) =>
              SyncJobsCompanion.insert(
            id: id,
            entityType: entityType,
            entityId: entityId,
            operation: operation,
            payloadJson: payloadJson,
            updatedAt: updatedAt,
            attemptCount: attemptCount,
            lastError: lastError,
            status: status,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncJobsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncJobsTable,
    SyncJob,
    $$SyncJobsTableFilterComposer,
    $$SyncJobsTableOrderingComposer,
    $$SyncJobsTableAnnotationComposer,
    $$SyncJobsTableCreateCompanionBuilder,
    $$SyncJobsTableUpdateCompanionBuilder,
    (SyncJob, BaseReferences<_$AppDatabase, $SyncJobsTable, SyncJob>),
    SyncJob,
    PrefetchHooks Function()>;
typedef $$SyncStateTableCreateCompanionBuilder = SyncStateCompanion Function({
  required String key,
  Value<String?> value,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$SyncStateTableUpdateCompanionBuilder = SyncStateCompanion Function({
  Value<String> key,
  Value<String?> value,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$SyncStateTableFilterComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$SyncStateTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$SyncStateTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SyncStateTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncStateTable,
    SyncStateData,
    $$SyncStateTableFilterComposer,
    $$SyncStateTableOrderingComposer,
    $$SyncStateTableAnnotationComposer,
    $$SyncStateTableCreateCompanionBuilder,
    $$SyncStateTableUpdateCompanionBuilder,
    (
      SyncStateData,
      BaseReferences<_$AppDatabase, $SyncStateTable, SyncStateData>
    ),
    SyncStateData,
    PrefetchHooks Function()> {
  $$SyncStateTableTableManager(_$AppDatabase db, $SyncStateTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String?> value = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncStateCompanion(
            key: key,
            value: value,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            Value<String?> value = const Value.absent(),
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncStateCompanion.insert(
            key: key,
            value: value,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncStateTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncStateTable,
    SyncStateData,
    $$SyncStateTableFilterComposer,
    $$SyncStateTableOrderingComposer,
    $$SyncStateTableAnnotationComposer,
    $$SyncStateTableCreateCompanionBuilder,
    $$SyncStateTableUpdateCompanionBuilder,
    (
      SyncStateData,
      BaseReferences<_$AppDatabase, $SyncStateTable, SyncStateData>
    ),
    SyncStateData,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$FieldsTableTableManager get fields =>
      $$FieldsTableTableManager(_db, _db.fields);
  $$FieldCropsTableTableManager get fieldCrops =>
      $$FieldCropsTableTableManager(_db, _db.fieldCrops);
  $$CalendarEventsTableTableManager get calendarEvents =>
      $$CalendarEventsTableTableManager(_db, _db.calendarEvents);
  $$IrrigationPlansTableTableManager get irrigationPlans =>
      $$IrrigationPlansTableTableManager(_db, _db.irrigationPlans);
  $$SuitabilityReportsTableTableManager get suitabilityReports =>
      $$SuitabilityReportsTableTableManager(_db, _db.suitabilityReports);
  $$SyncJobsTableTableManager get syncJobs =>
      $$SyncJobsTableTableManager(_db, _db.syncJobs);
  $$SyncStateTableTableManager get syncState =>
      $$SyncStateTableTableManager(_db, _db.syncState);
}
