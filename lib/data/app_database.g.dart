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
  static const VerificationMeta _farmerUidMeta =
      const VerificationMeta('farmerUid');
  @override
  late final GeneratedColumn<String> farmerUid = GeneratedColumn<String>(
      'farmer_uid', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
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
        farmerUid,
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
    if (data.containsKey('farmer_uid')) {
      context.handle(_farmerUidMeta,
          farmerUid.isAcceptableOrUnknown(data['farmer_uid']!, _farmerUidMeta));
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
      farmerUid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}farmer_uid']),
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
  final String? farmerUid;
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
      this.farmerUid,
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
    if (!nullToAbsent || farmerUid != null) {
      map['farmer_uid'] = Variable<String>(farmerUid);
    }
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
      farmerUid: farmerUid == null && nullToAbsent
          ? const Value.absent()
          : Value(farmerUid),
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
      farmerUid: serializer.fromJson<String?>(json['farmerUid']),
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
      'farmerUid': serializer.toJson<String?>(farmerUid),
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
          Value<String?> farmerUid = const Value.absent(),
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
        farmerUid: farmerUid.present ? farmerUid.value : this.farmerUid,
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
      farmerUid: data.farmerUid.present ? data.farmerUid.value : this.farmerUid,
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
          ..write('farmerUid: $farmerUid, ')
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
  int get hashCode => Object.hash(
      id,
      farmerUid,
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
      deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Field &&
          other.id == this.id &&
          other.farmerUid == this.farmerUid &&
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
  final Value<String?> farmerUid;
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
    this.farmerUid = const Value.absent(),
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
    this.farmerUid = const Value.absent(),
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
    Expression<String>? farmerUid,
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
      if (farmerUid != null) 'farmer_uid': farmerUid,
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
      Value<String?>? farmerUid,
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
      farmerUid: farmerUid ?? this.farmerUid,
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
    if (farmerUid.present) {
      map['farmer_uid'] = Variable<String>(farmerUid.value);
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
          ..write('farmerUid: $farmerUid, ')
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
  static const VerificationMeta _zonePolygonJsonMeta =
      const VerificationMeta('zonePolygonJson');
  @override
  late final GeneratedColumn<String> zonePolygonJson = GeneratedColumn<String>(
      'zone_polygon_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _facingDirectionMeta =
      const VerificationMeta('facingDirection');
  @override
  late final GeneratedColumn<String> facingDirection = GeneratedColumn<String>(
      'facing_direction', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isSeedlingMeta =
      const VerificationMeta('isSeedling');
  @override
  late final GeneratedColumn<bool> isSeedling = GeneratedColumn<bool>(
      'is_seedling', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_seedling" IN (0, 1))'));
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
        zonePolygonJson,
        facingDirection,
        isSeedling,
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
    if (data.containsKey('zone_polygon_json')) {
      context.handle(
          _zonePolygonJsonMeta,
          zonePolygonJson.isAcceptableOrUnknown(
              data['zone_polygon_json']!, _zonePolygonJsonMeta));
    }
    if (data.containsKey('facing_direction')) {
      context.handle(
          _facingDirectionMeta,
          facingDirection.isAcceptableOrUnknown(
              data['facing_direction']!, _facingDirectionMeta));
    }
    if (data.containsKey('is_seedling')) {
      context.handle(
          _isSeedlingMeta,
          isSeedling.isAcceptableOrUnknown(
              data['is_seedling']!, _isSeedlingMeta));
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
      zonePolygonJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}zone_polygon_json']),
      facingDirection: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}facing_direction']),
      isSeedling: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_seedling']),
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

  /// Sub-polygon JSON: [{"lat":..., "lng":...}, ...]
  /// null ise bitki tüm tarla alanına ekilmiş kabul edilir.
  final String? zonePolygonJson;

  /// Bitkinin baktığı yön — PlantFacingDirection.name değeri (ör. 'south').
  /// null ise belirsiz/girilmemiş.
  final String? facingDirection;

  /// Çok yıllık ürünler (portakal, çay) için: kullanıcı bu kaydı yeni
  /// fidan olarak mı, yoksa olgun ağaç olarak mı diktiğini belirtir.
  ///   - true  → yeni fidan; CropStateService 'perennialSeedling' modu.
  ///   - false → olgun ağaç/bahçe; 'perennialMature' modu.
  ///   - null  → bilinmiyor; tarih + bitki tipi üzerinden tahmin edilir
  ///            (3+ yaş varsayılan olarak mature).
  ///
  /// Tek yıllık bitkilerde (domates, mısır vb.) anlamı yok — null kalır.
  /// CLAUDE.md sec 11 + CropStateService.modeFor() ile eşleşir.
  final bool? isSeedling;
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
      this.zonePolygonJson,
      this.facingDirection,
      this.isSeedling,
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
    if (!nullToAbsent || zonePolygonJson != null) {
      map['zone_polygon_json'] = Variable<String>(zonePolygonJson);
    }
    if (!nullToAbsent || facingDirection != null) {
      map['facing_direction'] = Variable<String>(facingDirection);
    }
    if (!nullToAbsent || isSeedling != null) {
      map['is_seedling'] = Variable<bool>(isSeedling);
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
      zonePolygonJson: zonePolygonJson == null && nullToAbsent
          ? const Value.absent()
          : Value(zonePolygonJson),
      facingDirection: facingDirection == null && nullToAbsent
          ? const Value.absent()
          : Value(facingDirection),
      isSeedling: isSeedling == null && nullToAbsent
          ? const Value.absent()
          : Value(isSeedling),
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
      zonePolygonJson: serializer.fromJson<String?>(json['zonePolygonJson']),
      facingDirection: serializer.fromJson<String?>(json['facingDirection']),
      isSeedling: serializer.fromJson<bool?>(json['isSeedling']),
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
      'zonePolygonJson': serializer.toJson<String?>(zonePolygonJson),
      'facingDirection': serializer.toJson<String?>(facingDirection),
      'isSeedling': serializer.toJson<bool?>(isSeedling),
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
          Value<String?> zonePolygonJson = const Value.absent(),
          Value<String?> facingDirection = const Value.absent(),
          Value<bool?> isSeedling = const Value.absent(),
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
        zonePolygonJson: zonePolygonJson.present
            ? zonePolygonJson.value
            : this.zonePolygonJson,
        facingDirection: facingDirection.present
            ? facingDirection.value
            : this.facingDirection,
        isSeedling: isSeedling.present ? isSeedling.value : this.isSeedling,
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
      zonePolygonJson: data.zonePolygonJson.present
          ? data.zonePolygonJson.value
          : this.zonePolygonJson,
      facingDirection: data.facingDirection.present
          ? data.facingDirection.value
          : this.facingDirection,
      isSeedling:
          data.isSeedling.present ? data.isSeedling.value : this.isSeedling,
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
          ..write('zonePolygonJson: $zonePolygonJson, ')
          ..write('facingDirection: $facingDirection, ')
          ..write('isSeedling: $isSeedling, ')
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
      zonePolygonJson,
      facingDirection,
      isSeedling,
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
          other.zonePolygonJson == this.zonePolygonJson &&
          other.facingDirection == this.facingDirection &&
          other.isSeedling == this.isSeedling &&
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
  final Value<String?> zonePolygonJson;
  final Value<String?> facingDirection;
  final Value<bool?> isSeedling;
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
    this.zonePolygonJson = const Value.absent(),
    this.facingDirection = const Value.absent(),
    this.isSeedling = const Value.absent(),
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
    this.zonePolygonJson = const Value.absent(),
    this.facingDirection = const Value.absent(),
    this.isSeedling = const Value.absent(),
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
    Expression<String>? zonePolygonJson,
    Expression<String>? facingDirection,
    Expression<bool>? isSeedling,
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
      if (zonePolygonJson != null) 'zone_polygon_json': zonePolygonJson,
      if (facingDirection != null) 'facing_direction': facingDirection,
      if (isSeedling != null) 'is_seedling': isSeedling,
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
      Value<String?>? zonePolygonJson,
      Value<String?>? facingDirection,
      Value<bool?>? isSeedling,
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
      zonePolygonJson: zonePolygonJson ?? this.zonePolygonJson,
      facingDirection: facingDirection ?? this.facingDirection,
      isSeedling: isSeedling ?? this.isSeedling,
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
    if (zonePolygonJson.present) {
      map['zone_polygon_json'] = Variable<String>(zonePolygonJson.value);
    }
    if (facingDirection.present) {
      map['facing_direction'] = Variable<String>(facingDirection.value);
    }
    if (isSeedling.present) {
      map['is_seedling'] = Variable<bool>(isSeedling.value);
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
          ..write('zonePolygonJson: $zonePolygonJson, ')
          ..write('facingDirection: $facingDirection, ')
          ..write('isSeedling: $isSeedling, ')
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
  static const VerificationMeta _quantityMeta =
      const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
      'quantity', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
      'unit', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _recommendedQuantityMeta =
      const VerificationMeta('recommendedQuantity');
  @override
  late final GeneratedColumn<double> recommendedQuantity =
      GeneratedColumn<double>('recommended_quantity', aliasedName, true,
          type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _targetScopeMeta =
      const VerificationMeta('targetScope');
  @override
  late final GeneratedColumn<String> targetScope = GeneratedColumn<String>(
      'target_scope', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _plantInstanceIdMeta =
      const VerificationMeta('plantInstanceId');
  @override
  late final GeneratedColumn<String> plantInstanceId = GeneratedColumn<String>(
      'plant_instance_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _subtypeMeta =
      const VerificationMeta('subtype');
  @override
  late final GeneratedColumn<String> subtype = GeneratedColumn<String>(
      'subtype', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _photoPathMeta =
      const VerificationMeta('photoPath');
  @override
  late final GeneratedColumn<String> photoPath = GeneratedColumn<String>(
      'photo_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _noteTextMeta =
      const VerificationMeta('noteText');
  @override
  late final GeneratedColumn<String> noteText = GeneratedColumn<String>(
      'note_text', aliasedName, true,
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
        quantity,
        unit,
        recommendedQuantity,
        targetScope,
        plantInstanceId,
        subtype,
        photoPath,
        noteText,
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
    if (data.containsKey('quantity')) {
      context.handle(_quantityMeta,
          quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta));
    }
    if (data.containsKey('unit')) {
      context.handle(
          _unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
    }
    if (data.containsKey('recommended_quantity')) {
      context.handle(
          _recommendedQuantityMeta,
          recommendedQuantity.isAcceptableOrUnknown(
              data['recommended_quantity']!, _recommendedQuantityMeta));
    }
    if (data.containsKey('target_scope')) {
      context.handle(
          _targetScopeMeta,
          targetScope.isAcceptableOrUnknown(
              data['target_scope']!, _targetScopeMeta));
    }
    if (data.containsKey('plant_instance_id')) {
      context.handle(
          _plantInstanceIdMeta,
          plantInstanceId.isAcceptableOrUnknown(
              data['plant_instance_id']!, _plantInstanceIdMeta));
    }
    if (data.containsKey('subtype')) {
      context.handle(_subtypeMeta,
          subtype.isAcceptableOrUnknown(data['subtype']!, _subtypeMeta));
    }
    if (data.containsKey('photo_path')) {
      context.handle(_photoPathMeta,
          photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta));
    }
    if (data.containsKey('note_text')) {
      context.handle(_noteTextMeta,
          noteText.isAcceptableOrUnknown(data['note_text']!, _noteTextMeta));
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
      quantity: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}quantity']),
      unit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit']),
      recommendedQuantity: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}recommended_quantity']),
      targetScope: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}target_scope']),
      plantInstanceId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}plant_instance_id']),
      subtype: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subtype']),
      photoPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}photo_path']),
      noteText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note_text']),
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

  /// Çiftçinin gerçekten uyguladığı miktar (ör. sulama dk, gübre kg, ilaç mL).
  /// metadata_json içinde de tutulur; bu kolon GrowthEngine sorguları için
  /// indekslenebilir hızlı erişim sağlar (v4).
  final double? quantity;

  /// Miktar birimi — 'dk', 'kg', 'L', 'g', 'mL'. (v4)
  final String? unit;

  /// Direktif motorunun aynı anda önerdiği miktar — eksik/fazla oranını
  /// hesaplamak için. Null ise öneri-dışı manuel kayıt. (v4)
  final double? recommendedQuantity;

  /// Aktivite kapsamı: 'field' | 'zone' | 'plant'. null → field varsayılır. (v8)
  final String? targetScope;

  /// Tekil bitkiye iliştirilen aktivite — FieldPlantInstances.id ile eşleşir.
  /// FK constraint yok (Drift forward-reference riskinden kaçınmak için);
  /// referans bütünlüğü uygulama katmanında korunur. (v8)
  final String? plantInstanceId;

  /// Aktivite alt-tipi: 'disease_observation' | 'pest_observation' |
  /// 'hoeing' | 'thinning' | 'note'. eventType ile birlikte kullanılır;
  /// alt-tip null ise eventType tek başına yeterlidir. (v8)
  final String? subtype;

  /// Aktivite fotoğrafı yerel yolu (app docs altında, WebP). (v8)
  final String? photoPath;

  /// Çiftçi serbest metin notu — subtype='note' kayıtlarında zorunlu,
  /// diğer aktivitelerde opsiyonel açıklama. (v8)
  final String? noteText;
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
      this.quantity,
      this.unit,
      this.recommendedQuantity,
      this.targetScope,
      this.plantInstanceId,
      this.subtype,
      this.photoPath,
      this.noteText,
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
    if (!nullToAbsent || quantity != null) {
      map['quantity'] = Variable<double>(quantity);
    }
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    if (!nullToAbsent || recommendedQuantity != null) {
      map['recommended_quantity'] = Variable<double>(recommendedQuantity);
    }
    if (!nullToAbsent || targetScope != null) {
      map['target_scope'] = Variable<String>(targetScope);
    }
    if (!nullToAbsent || plantInstanceId != null) {
      map['plant_instance_id'] = Variable<String>(plantInstanceId);
    }
    if (!nullToAbsent || subtype != null) {
      map['subtype'] = Variable<String>(subtype);
    }
    if (!nullToAbsent || photoPath != null) {
      map['photo_path'] = Variable<String>(photoPath);
    }
    if (!nullToAbsent || noteText != null) {
      map['note_text'] = Variable<String>(noteText);
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
      quantity: quantity == null && nullToAbsent
          ? const Value.absent()
          : Value(quantity),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      recommendedQuantity: recommendedQuantity == null && nullToAbsent
          ? const Value.absent()
          : Value(recommendedQuantity),
      targetScope: targetScope == null && nullToAbsent
          ? const Value.absent()
          : Value(targetScope),
      plantInstanceId: plantInstanceId == null && nullToAbsent
          ? const Value.absent()
          : Value(plantInstanceId),
      subtype: subtype == null && nullToAbsent
          ? const Value.absent()
          : Value(subtype),
      photoPath: photoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(photoPath),
      noteText: noteText == null && nullToAbsent
          ? const Value.absent()
          : Value(noteText),
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
      quantity: serializer.fromJson<double?>(json['quantity']),
      unit: serializer.fromJson<String?>(json['unit']),
      recommendedQuantity:
          serializer.fromJson<double?>(json['recommendedQuantity']),
      targetScope: serializer.fromJson<String?>(json['targetScope']),
      plantInstanceId: serializer.fromJson<String?>(json['plantInstanceId']),
      subtype: serializer.fromJson<String?>(json['subtype']),
      photoPath: serializer.fromJson<String?>(json['photoPath']),
      noteText: serializer.fromJson<String?>(json['noteText']),
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
      'quantity': serializer.toJson<double?>(quantity),
      'unit': serializer.toJson<String?>(unit),
      'recommendedQuantity': serializer.toJson<double?>(recommendedQuantity),
      'targetScope': serializer.toJson<String?>(targetScope),
      'plantInstanceId': serializer.toJson<String?>(plantInstanceId),
      'subtype': serializer.toJson<String?>(subtype),
      'photoPath': serializer.toJson<String?>(photoPath),
      'noteText': serializer.toJson<String?>(noteText),
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
          Value<double?> quantity = const Value.absent(),
          Value<String?> unit = const Value.absent(),
          Value<double?> recommendedQuantity = const Value.absent(),
          Value<String?> targetScope = const Value.absent(),
          Value<String?> plantInstanceId = const Value.absent(),
          Value<String?> subtype = const Value.absent(),
          Value<String?> photoPath = const Value.absent(),
          Value<String?> noteText = const Value.absent(),
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
        quantity: quantity.present ? quantity.value : this.quantity,
        unit: unit.present ? unit.value : this.unit,
        recommendedQuantity: recommendedQuantity.present
            ? recommendedQuantity.value
            : this.recommendedQuantity,
        targetScope: targetScope.present ? targetScope.value : this.targetScope,
        plantInstanceId: plantInstanceId.present
            ? plantInstanceId.value
            : this.plantInstanceId,
        subtype: subtype.present ? subtype.value : this.subtype,
        photoPath: photoPath.present ? photoPath.value : this.photoPath,
        noteText: noteText.present ? noteText.value : this.noteText,
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
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unit: data.unit.present ? data.unit.value : this.unit,
      recommendedQuantity: data.recommendedQuantity.present
          ? data.recommendedQuantity.value
          : this.recommendedQuantity,
      targetScope:
          data.targetScope.present ? data.targetScope.value : this.targetScope,
      plantInstanceId: data.plantInstanceId.present
          ? data.plantInstanceId.value
          : this.plantInstanceId,
      subtype: data.subtype.present ? data.subtype.value : this.subtype,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
      noteText: data.noteText.present ? data.noteText.value : this.noteText,
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
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('recommendedQuantity: $recommendedQuantity, ')
          ..write('targetScope: $targetScope, ')
          ..write('plantInstanceId: $plantInstanceId, ')
          ..write('subtype: $subtype, ')
          ..write('photoPath: $photoPath, ')
          ..write('noteText: $noteText, ')
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
      cropId,
      title,
      eventType,
      eventDate,
      source,
      metadataJson,
      quantity,
      unit,
      recommendedQuantity,
      targetScope,
      plantInstanceId,
      subtype,
      photoPath,
      noteText,
      createdAt,
      updatedAt,
      deletedAt);
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
          other.quantity == this.quantity &&
          other.unit == this.unit &&
          other.recommendedQuantity == this.recommendedQuantity &&
          other.targetScope == this.targetScope &&
          other.plantInstanceId == this.plantInstanceId &&
          other.subtype == this.subtype &&
          other.photoPath == this.photoPath &&
          other.noteText == this.noteText &&
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
  final Value<double?> quantity;
  final Value<String?> unit;
  final Value<double?> recommendedQuantity;
  final Value<String?> targetScope;
  final Value<String?> plantInstanceId;
  final Value<String?> subtype;
  final Value<String?> photoPath;
  final Value<String?> noteText;
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
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.recommendedQuantity = const Value.absent(),
    this.targetScope = const Value.absent(),
    this.plantInstanceId = const Value.absent(),
    this.subtype = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.noteText = const Value.absent(),
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
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.recommendedQuantity = const Value.absent(),
    this.targetScope = const Value.absent(),
    this.plantInstanceId = const Value.absent(),
    this.subtype = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.noteText = const Value.absent(),
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
    Expression<double>? quantity,
    Expression<String>? unit,
    Expression<double>? recommendedQuantity,
    Expression<String>? targetScope,
    Expression<String>? plantInstanceId,
    Expression<String>? subtype,
    Expression<String>? photoPath,
    Expression<String>? noteText,
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
      if (quantity != null) 'quantity': quantity,
      if (unit != null) 'unit': unit,
      if (recommendedQuantity != null)
        'recommended_quantity': recommendedQuantity,
      if (targetScope != null) 'target_scope': targetScope,
      if (plantInstanceId != null) 'plant_instance_id': plantInstanceId,
      if (subtype != null) 'subtype': subtype,
      if (photoPath != null) 'photo_path': photoPath,
      if (noteText != null) 'note_text': noteText,
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
      Value<double?>? quantity,
      Value<String?>? unit,
      Value<double?>? recommendedQuantity,
      Value<String?>? targetScope,
      Value<String?>? plantInstanceId,
      Value<String?>? subtype,
      Value<String?>? photoPath,
      Value<String?>? noteText,
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
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      recommendedQuantity: recommendedQuantity ?? this.recommendedQuantity,
      targetScope: targetScope ?? this.targetScope,
      plantInstanceId: plantInstanceId ?? this.plantInstanceId,
      subtype: subtype ?? this.subtype,
      photoPath: photoPath ?? this.photoPath,
      noteText: noteText ?? this.noteText,
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
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (recommendedQuantity.present) {
      map['recommended_quantity'] = Variable<double>(recommendedQuantity.value);
    }
    if (targetScope.present) {
      map['target_scope'] = Variable<String>(targetScope.value);
    }
    if (plantInstanceId.present) {
      map['plant_instance_id'] = Variable<String>(plantInstanceId.value);
    }
    if (subtype.present) {
      map['subtype'] = Variable<String>(subtype.value);
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
    }
    if (noteText.present) {
      map['note_text'] = Variable<String>(noteText.value);
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
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('recommendedQuantity: $recommendedQuantity, ')
          ..write('targetScope: $targetScope, ')
          ..write('plantInstanceId: $plantInstanceId, ')
          ..write('subtype: $subtype, ')
          ..write('photoPath: $photoPath, ')
          ..write('noteText: $noteText, ')
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

class $CropGrowthStatesTable extends CropGrowthStates
    with TableInfo<$CropGrowthStatesTable, CropGrowthState> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CropGrowthStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cropIdMeta = const VerificationMeta('cropId');
  @override
  late final GeneratedColumn<String> cropId = GeneratedColumn<String>(
      'crop_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fieldIdMeta =
      const VerificationMeta('fieldId');
  @override
  late final GeneratedColumn<String> fieldId = GeneratedColumn<String>(
      'field_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _asOfDateMeta =
      const VerificationMeta('asOfDate');
  @override
  late final GeneratedColumn<DateTime> asOfDate = GeneratedColumn<DateTime>(
      'as_of_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _accumulatedGddMeta =
      const VerificationMeta('accumulatedGdd');
  @override
  late final GeneratedColumn<double> accumulatedGdd = GeneratedColumn<double>(
      'accumulated_gdd', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _currentStageKeyMeta =
      const VerificationMeta('currentStageKey');
  @override
  late final GeneratedColumn<String> currentStageKey = GeneratedColumn<String>(
      'current_stage_key', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('cimlenme'));
  static const VerificationMeta _stageProgressMeta =
      const VerificationMeta('stageProgress');
  @override
  late final GeneratedColumn<double> stageProgress = GeneratedColumn<double>(
      'stage_progress', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _waterDeficitMmMeta =
      const VerificationMeta('waterDeficitMm');
  @override
  late final GeneratedColumn<double> waterDeficitMm = GeneratedColumn<double>(
      'water_deficit_mm', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _nStressIdxMeta =
      const VerificationMeta('nStressIdx');
  @override
  late final GeneratedColumn<double> nStressIdx = GeneratedColumn<double>(
      'n_stress_idx', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _kStressIdxMeta =
      const VerificationMeta('kStressIdx');
  @override
  late final GeneratedColumn<double> kStressIdx = GeneratedColumn<double>(
      'k_stress_idx', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _diseasePressureMeta =
      const VerificationMeta('diseasePressure');
  @override
  late final GeneratedColumn<double> diseasePressure = GeneratedColumn<double>(
      'disease_pressure', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _heightCmMeta =
      const VerificationMeta('heightCm');
  @override
  late final GeneratedColumn<double> heightCm = GeneratedColumn<double>(
      'height_cm', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _biomassRelMeta =
      const VerificationMeta('biomassRel');
  @override
  late final GeneratedColumn<double> biomassRel = GeneratedColumn<double>(
      'biomass_rel', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _yieldMultiplierMeta =
      const VerificationMeta('yieldMultiplier');
  @override
  late final GeneratedColumn<double> yieldMultiplier = GeneratedColumn<double>(
      'yield_multiplier', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(1.0));
  static const VerificationMeta _lastComputedAtMeta =
      const VerificationMeta('lastComputedAt');
  @override
  late final GeneratedColumn<DateTime> lastComputedAt =
      GeneratedColumn<DateTime>('last_computed_at', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        cropId,
        fieldId,
        asOfDate,
        accumulatedGdd,
        currentStageKey,
        stageProgress,
        waterDeficitMm,
        nStressIdx,
        kStressIdx,
        diseasePressure,
        heightCm,
        biomassRel,
        yieldMultiplier,
        lastComputedAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'crop_growth_states';
  @override
  VerificationContext validateIntegrity(Insertable<CropGrowthState> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('crop_id')) {
      context.handle(_cropIdMeta,
          cropId.isAcceptableOrUnknown(data['crop_id']!, _cropIdMeta));
    } else if (isInserting) {
      context.missing(_cropIdMeta);
    }
    if (data.containsKey('field_id')) {
      context.handle(_fieldIdMeta,
          fieldId.isAcceptableOrUnknown(data['field_id']!, _fieldIdMeta));
    } else if (isInserting) {
      context.missing(_fieldIdMeta);
    }
    if (data.containsKey('as_of_date')) {
      context.handle(_asOfDateMeta,
          asOfDate.isAcceptableOrUnknown(data['as_of_date']!, _asOfDateMeta));
    } else if (isInserting) {
      context.missing(_asOfDateMeta);
    }
    if (data.containsKey('accumulated_gdd')) {
      context.handle(
          _accumulatedGddMeta,
          accumulatedGdd.isAcceptableOrUnknown(
              data['accumulated_gdd']!, _accumulatedGddMeta));
    }
    if (data.containsKey('current_stage_key')) {
      context.handle(
          _currentStageKeyMeta,
          currentStageKey.isAcceptableOrUnknown(
              data['current_stage_key']!, _currentStageKeyMeta));
    }
    if (data.containsKey('stage_progress')) {
      context.handle(
          _stageProgressMeta,
          stageProgress.isAcceptableOrUnknown(
              data['stage_progress']!, _stageProgressMeta));
    }
    if (data.containsKey('water_deficit_mm')) {
      context.handle(
          _waterDeficitMmMeta,
          waterDeficitMm.isAcceptableOrUnknown(
              data['water_deficit_mm']!, _waterDeficitMmMeta));
    }
    if (data.containsKey('n_stress_idx')) {
      context.handle(
          _nStressIdxMeta,
          nStressIdx.isAcceptableOrUnknown(
              data['n_stress_idx']!, _nStressIdxMeta));
    }
    if (data.containsKey('k_stress_idx')) {
      context.handle(
          _kStressIdxMeta,
          kStressIdx.isAcceptableOrUnknown(
              data['k_stress_idx']!, _kStressIdxMeta));
    }
    if (data.containsKey('disease_pressure')) {
      context.handle(
          _diseasePressureMeta,
          diseasePressure.isAcceptableOrUnknown(
              data['disease_pressure']!, _diseasePressureMeta));
    }
    if (data.containsKey('height_cm')) {
      context.handle(_heightCmMeta,
          heightCm.isAcceptableOrUnknown(data['height_cm']!, _heightCmMeta));
    }
    if (data.containsKey('biomass_rel')) {
      context.handle(
          _biomassRelMeta,
          biomassRel.isAcceptableOrUnknown(
              data['biomass_rel']!, _biomassRelMeta));
    }
    if (data.containsKey('yield_multiplier')) {
      context.handle(
          _yieldMultiplierMeta,
          yieldMultiplier.isAcceptableOrUnknown(
              data['yield_multiplier']!, _yieldMultiplierMeta));
    }
    if (data.containsKey('last_computed_at')) {
      context.handle(
          _lastComputedAtMeta,
          lastComputedAt.isAcceptableOrUnknown(
              data['last_computed_at']!, _lastComputedAtMeta));
    } else if (isInserting) {
      context.missing(_lastComputedAtMeta);
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
  Set<GeneratedColumn> get $primaryKey => {cropId};
  @override
  CropGrowthState map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CropGrowthState(
      cropId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}crop_id'])!,
      fieldId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}field_id'])!,
      asOfDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}as_of_date'])!,
      accumulatedGdd: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}accumulated_gdd'])!,
      currentStageKey: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}current_stage_key'])!,
      stageProgress: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}stage_progress'])!,
      waterDeficitMm: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}water_deficit_mm'])!,
      nStressIdx: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}n_stress_idx'])!,
      kStressIdx: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}k_stress_idx'])!,
      diseasePressure: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}disease_pressure'])!,
      heightCm: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}height_cm'])!,
      biomassRel: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}biomass_rel'])!,
      yieldMultiplier: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}yield_multiplier'])!,
      lastComputedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_computed_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $CropGrowthStatesTable createAlias(String alias) {
    return $CropGrowthStatesTable(attachedDatabase, alias);
  }
}

class CropGrowthState extends DataClass implements Insertable<CropGrowthState> {
  /// FieldCrops.id ile aynı — 1:1 ilişki.
  final String cropId;
  final String fieldId;

  /// Son hesaplama tarihi (local midnight).
  final DateTime asOfDate;

  /// Ekimden bu yana biriken GDD (gün-derece). Tbase bitkiye göre değişir.
  final double accumulatedGdd;

  /// Aktif fenoloji evresi: 'cimlenme' | 'vejetatif' | 'ciceklenme' |
  /// 'meyve_dolumu' | 'olgunlasma' | 'hasat'.
  final String currentStageKey;

  /// Aktif evre içindeki ilerleme (0..1). Büyüme animasyonu bu değeri okur.
  final double stageProgress;

  /// Sulama açığı (mm) — öneriye göre eksik veren toplam. 0 = ideal, >0 stres.
  final double waterDeficitMm;

  /// Azot (N) stresi 0..1 — gübreleme eksikliğinin kümülatif etkisi.
  /// 7-day moving average ile yumuşatılır → günlük oynaklık bastırılır.
  final double nStressIdx;

  /// Potasyum (K) stresi 0..1 — NPK gübre tipinden K oranı toplanarak
  /// hesaplanır. Çiçek/meyve evrelerinde verim çarpanı düşürür. (v6)
  final double kStressIdx;

  /// Hastalık baskısı 0..1 — yağmur + eksik ilaçlama kombinasyonu.
  final double diseasePressure;

  /// Tahmin edilen boy (cm) — görsel büyüme için.
  final double heightCm;

  /// Göreceli biyokütle 0..1 (sigmoid).
  final double biomassRel;

  /// Verim çarpanı — 0.5..1.15 aralığında; her stres zinciri bunu aşağı çeker.
  final double yieldMultiplier;
  final DateTime lastComputedAt;
  final DateTime updatedAt;
  const CropGrowthState(
      {required this.cropId,
      required this.fieldId,
      required this.asOfDate,
      required this.accumulatedGdd,
      required this.currentStageKey,
      required this.stageProgress,
      required this.waterDeficitMm,
      required this.nStressIdx,
      required this.kStressIdx,
      required this.diseasePressure,
      required this.heightCm,
      required this.biomassRel,
      required this.yieldMultiplier,
      required this.lastComputedAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['crop_id'] = Variable<String>(cropId);
    map['field_id'] = Variable<String>(fieldId);
    map['as_of_date'] = Variable<DateTime>(asOfDate);
    map['accumulated_gdd'] = Variable<double>(accumulatedGdd);
    map['current_stage_key'] = Variable<String>(currentStageKey);
    map['stage_progress'] = Variable<double>(stageProgress);
    map['water_deficit_mm'] = Variable<double>(waterDeficitMm);
    map['n_stress_idx'] = Variable<double>(nStressIdx);
    map['k_stress_idx'] = Variable<double>(kStressIdx);
    map['disease_pressure'] = Variable<double>(diseasePressure);
    map['height_cm'] = Variable<double>(heightCm);
    map['biomass_rel'] = Variable<double>(biomassRel);
    map['yield_multiplier'] = Variable<double>(yieldMultiplier);
    map['last_computed_at'] = Variable<DateTime>(lastComputedAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CropGrowthStatesCompanion toCompanion(bool nullToAbsent) {
    return CropGrowthStatesCompanion(
      cropId: Value(cropId),
      fieldId: Value(fieldId),
      asOfDate: Value(asOfDate),
      accumulatedGdd: Value(accumulatedGdd),
      currentStageKey: Value(currentStageKey),
      stageProgress: Value(stageProgress),
      waterDeficitMm: Value(waterDeficitMm),
      nStressIdx: Value(nStressIdx),
      kStressIdx: Value(kStressIdx),
      diseasePressure: Value(diseasePressure),
      heightCm: Value(heightCm),
      biomassRel: Value(biomassRel),
      yieldMultiplier: Value(yieldMultiplier),
      lastComputedAt: Value(lastComputedAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CropGrowthState.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CropGrowthState(
      cropId: serializer.fromJson<String>(json['cropId']),
      fieldId: serializer.fromJson<String>(json['fieldId']),
      asOfDate: serializer.fromJson<DateTime>(json['asOfDate']),
      accumulatedGdd: serializer.fromJson<double>(json['accumulatedGdd']),
      currentStageKey: serializer.fromJson<String>(json['currentStageKey']),
      stageProgress: serializer.fromJson<double>(json['stageProgress']),
      waterDeficitMm: serializer.fromJson<double>(json['waterDeficitMm']),
      nStressIdx: serializer.fromJson<double>(json['nStressIdx']),
      kStressIdx: serializer.fromJson<double>(json['kStressIdx']),
      diseasePressure: serializer.fromJson<double>(json['diseasePressure']),
      heightCm: serializer.fromJson<double>(json['heightCm']),
      biomassRel: serializer.fromJson<double>(json['biomassRel']),
      yieldMultiplier: serializer.fromJson<double>(json['yieldMultiplier']),
      lastComputedAt: serializer.fromJson<DateTime>(json['lastComputedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cropId': serializer.toJson<String>(cropId),
      'fieldId': serializer.toJson<String>(fieldId),
      'asOfDate': serializer.toJson<DateTime>(asOfDate),
      'accumulatedGdd': serializer.toJson<double>(accumulatedGdd),
      'currentStageKey': serializer.toJson<String>(currentStageKey),
      'stageProgress': serializer.toJson<double>(stageProgress),
      'waterDeficitMm': serializer.toJson<double>(waterDeficitMm),
      'nStressIdx': serializer.toJson<double>(nStressIdx),
      'kStressIdx': serializer.toJson<double>(kStressIdx),
      'diseasePressure': serializer.toJson<double>(diseasePressure),
      'heightCm': serializer.toJson<double>(heightCm),
      'biomassRel': serializer.toJson<double>(biomassRel),
      'yieldMultiplier': serializer.toJson<double>(yieldMultiplier),
      'lastComputedAt': serializer.toJson<DateTime>(lastComputedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CropGrowthState copyWith(
          {String? cropId,
          String? fieldId,
          DateTime? asOfDate,
          double? accumulatedGdd,
          String? currentStageKey,
          double? stageProgress,
          double? waterDeficitMm,
          double? nStressIdx,
          double? kStressIdx,
          double? diseasePressure,
          double? heightCm,
          double? biomassRel,
          double? yieldMultiplier,
          DateTime? lastComputedAt,
          DateTime? updatedAt}) =>
      CropGrowthState(
        cropId: cropId ?? this.cropId,
        fieldId: fieldId ?? this.fieldId,
        asOfDate: asOfDate ?? this.asOfDate,
        accumulatedGdd: accumulatedGdd ?? this.accumulatedGdd,
        currentStageKey: currentStageKey ?? this.currentStageKey,
        stageProgress: stageProgress ?? this.stageProgress,
        waterDeficitMm: waterDeficitMm ?? this.waterDeficitMm,
        nStressIdx: nStressIdx ?? this.nStressIdx,
        kStressIdx: kStressIdx ?? this.kStressIdx,
        diseasePressure: diseasePressure ?? this.diseasePressure,
        heightCm: heightCm ?? this.heightCm,
        biomassRel: biomassRel ?? this.biomassRel,
        yieldMultiplier: yieldMultiplier ?? this.yieldMultiplier,
        lastComputedAt: lastComputedAt ?? this.lastComputedAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  CropGrowthState copyWithCompanion(CropGrowthStatesCompanion data) {
    return CropGrowthState(
      cropId: data.cropId.present ? data.cropId.value : this.cropId,
      fieldId: data.fieldId.present ? data.fieldId.value : this.fieldId,
      asOfDate: data.asOfDate.present ? data.asOfDate.value : this.asOfDate,
      accumulatedGdd: data.accumulatedGdd.present
          ? data.accumulatedGdd.value
          : this.accumulatedGdd,
      currentStageKey: data.currentStageKey.present
          ? data.currentStageKey.value
          : this.currentStageKey,
      stageProgress: data.stageProgress.present
          ? data.stageProgress.value
          : this.stageProgress,
      waterDeficitMm: data.waterDeficitMm.present
          ? data.waterDeficitMm.value
          : this.waterDeficitMm,
      nStressIdx:
          data.nStressIdx.present ? data.nStressIdx.value : this.nStressIdx,
      kStressIdx:
          data.kStressIdx.present ? data.kStressIdx.value : this.kStressIdx,
      diseasePressure: data.diseasePressure.present
          ? data.diseasePressure.value
          : this.diseasePressure,
      heightCm: data.heightCm.present ? data.heightCm.value : this.heightCm,
      biomassRel:
          data.biomassRel.present ? data.biomassRel.value : this.biomassRel,
      yieldMultiplier: data.yieldMultiplier.present
          ? data.yieldMultiplier.value
          : this.yieldMultiplier,
      lastComputedAt: data.lastComputedAt.present
          ? data.lastComputedAt.value
          : this.lastComputedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CropGrowthState(')
          ..write('cropId: $cropId, ')
          ..write('fieldId: $fieldId, ')
          ..write('asOfDate: $asOfDate, ')
          ..write('accumulatedGdd: $accumulatedGdd, ')
          ..write('currentStageKey: $currentStageKey, ')
          ..write('stageProgress: $stageProgress, ')
          ..write('waterDeficitMm: $waterDeficitMm, ')
          ..write('nStressIdx: $nStressIdx, ')
          ..write('kStressIdx: $kStressIdx, ')
          ..write('diseasePressure: $diseasePressure, ')
          ..write('heightCm: $heightCm, ')
          ..write('biomassRel: $biomassRel, ')
          ..write('yieldMultiplier: $yieldMultiplier, ')
          ..write('lastComputedAt: $lastComputedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      cropId,
      fieldId,
      asOfDate,
      accumulatedGdd,
      currentStageKey,
      stageProgress,
      waterDeficitMm,
      nStressIdx,
      kStressIdx,
      diseasePressure,
      heightCm,
      biomassRel,
      yieldMultiplier,
      lastComputedAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CropGrowthState &&
          other.cropId == this.cropId &&
          other.fieldId == this.fieldId &&
          other.asOfDate == this.asOfDate &&
          other.accumulatedGdd == this.accumulatedGdd &&
          other.currentStageKey == this.currentStageKey &&
          other.stageProgress == this.stageProgress &&
          other.waterDeficitMm == this.waterDeficitMm &&
          other.nStressIdx == this.nStressIdx &&
          other.kStressIdx == this.kStressIdx &&
          other.diseasePressure == this.diseasePressure &&
          other.heightCm == this.heightCm &&
          other.biomassRel == this.biomassRel &&
          other.yieldMultiplier == this.yieldMultiplier &&
          other.lastComputedAt == this.lastComputedAt &&
          other.updatedAt == this.updatedAt);
}

class CropGrowthStatesCompanion extends UpdateCompanion<CropGrowthState> {
  final Value<String> cropId;
  final Value<String> fieldId;
  final Value<DateTime> asOfDate;
  final Value<double> accumulatedGdd;
  final Value<String> currentStageKey;
  final Value<double> stageProgress;
  final Value<double> waterDeficitMm;
  final Value<double> nStressIdx;
  final Value<double> kStressIdx;
  final Value<double> diseasePressure;
  final Value<double> heightCm;
  final Value<double> biomassRel;
  final Value<double> yieldMultiplier;
  final Value<DateTime> lastComputedAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CropGrowthStatesCompanion({
    this.cropId = const Value.absent(),
    this.fieldId = const Value.absent(),
    this.asOfDate = const Value.absent(),
    this.accumulatedGdd = const Value.absent(),
    this.currentStageKey = const Value.absent(),
    this.stageProgress = const Value.absent(),
    this.waterDeficitMm = const Value.absent(),
    this.nStressIdx = const Value.absent(),
    this.kStressIdx = const Value.absent(),
    this.diseasePressure = const Value.absent(),
    this.heightCm = const Value.absent(),
    this.biomassRel = const Value.absent(),
    this.yieldMultiplier = const Value.absent(),
    this.lastComputedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CropGrowthStatesCompanion.insert({
    required String cropId,
    required String fieldId,
    required DateTime asOfDate,
    this.accumulatedGdd = const Value.absent(),
    this.currentStageKey = const Value.absent(),
    this.stageProgress = const Value.absent(),
    this.waterDeficitMm = const Value.absent(),
    this.nStressIdx = const Value.absent(),
    this.kStressIdx = const Value.absent(),
    this.diseasePressure = const Value.absent(),
    this.heightCm = const Value.absent(),
    this.biomassRel = const Value.absent(),
    this.yieldMultiplier = const Value.absent(),
    required DateTime lastComputedAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : cropId = Value(cropId),
        fieldId = Value(fieldId),
        asOfDate = Value(asOfDate),
        lastComputedAt = Value(lastComputedAt),
        updatedAt = Value(updatedAt);
  static Insertable<CropGrowthState> custom({
    Expression<String>? cropId,
    Expression<String>? fieldId,
    Expression<DateTime>? asOfDate,
    Expression<double>? accumulatedGdd,
    Expression<String>? currentStageKey,
    Expression<double>? stageProgress,
    Expression<double>? waterDeficitMm,
    Expression<double>? nStressIdx,
    Expression<double>? kStressIdx,
    Expression<double>? diseasePressure,
    Expression<double>? heightCm,
    Expression<double>? biomassRel,
    Expression<double>? yieldMultiplier,
    Expression<DateTime>? lastComputedAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cropId != null) 'crop_id': cropId,
      if (fieldId != null) 'field_id': fieldId,
      if (asOfDate != null) 'as_of_date': asOfDate,
      if (accumulatedGdd != null) 'accumulated_gdd': accumulatedGdd,
      if (currentStageKey != null) 'current_stage_key': currentStageKey,
      if (stageProgress != null) 'stage_progress': stageProgress,
      if (waterDeficitMm != null) 'water_deficit_mm': waterDeficitMm,
      if (nStressIdx != null) 'n_stress_idx': nStressIdx,
      if (kStressIdx != null) 'k_stress_idx': kStressIdx,
      if (diseasePressure != null) 'disease_pressure': diseasePressure,
      if (heightCm != null) 'height_cm': heightCm,
      if (biomassRel != null) 'biomass_rel': biomassRel,
      if (yieldMultiplier != null) 'yield_multiplier': yieldMultiplier,
      if (lastComputedAt != null) 'last_computed_at': lastComputedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CropGrowthStatesCompanion copyWith(
      {Value<String>? cropId,
      Value<String>? fieldId,
      Value<DateTime>? asOfDate,
      Value<double>? accumulatedGdd,
      Value<String>? currentStageKey,
      Value<double>? stageProgress,
      Value<double>? waterDeficitMm,
      Value<double>? nStressIdx,
      Value<double>? kStressIdx,
      Value<double>? diseasePressure,
      Value<double>? heightCm,
      Value<double>? biomassRel,
      Value<double>? yieldMultiplier,
      Value<DateTime>? lastComputedAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return CropGrowthStatesCompanion(
      cropId: cropId ?? this.cropId,
      fieldId: fieldId ?? this.fieldId,
      asOfDate: asOfDate ?? this.asOfDate,
      accumulatedGdd: accumulatedGdd ?? this.accumulatedGdd,
      currentStageKey: currentStageKey ?? this.currentStageKey,
      stageProgress: stageProgress ?? this.stageProgress,
      waterDeficitMm: waterDeficitMm ?? this.waterDeficitMm,
      nStressIdx: nStressIdx ?? this.nStressIdx,
      kStressIdx: kStressIdx ?? this.kStressIdx,
      diseasePressure: diseasePressure ?? this.diseasePressure,
      heightCm: heightCm ?? this.heightCm,
      biomassRel: biomassRel ?? this.biomassRel,
      yieldMultiplier: yieldMultiplier ?? this.yieldMultiplier,
      lastComputedAt: lastComputedAt ?? this.lastComputedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cropId.present) {
      map['crop_id'] = Variable<String>(cropId.value);
    }
    if (fieldId.present) {
      map['field_id'] = Variable<String>(fieldId.value);
    }
    if (asOfDate.present) {
      map['as_of_date'] = Variable<DateTime>(asOfDate.value);
    }
    if (accumulatedGdd.present) {
      map['accumulated_gdd'] = Variable<double>(accumulatedGdd.value);
    }
    if (currentStageKey.present) {
      map['current_stage_key'] = Variable<String>(currentStageKey.value);
    }
    if (stageProgress.present) {
      map['stage_progress'] = Variable<double>(stageProgress.value);
    }
    if (waterDeficitMm.present) {
      map['water_deficit_mm'] = Variable<double>(waterDeficitMm.value);
    }
    if (nStressIdx.present) {
      map['n_stress_idx'] = Variable<double>(nStressIdx.value);
    }
    if (kStressIdx.present) {
      map['k_stress_idx'] = Variable<double>(kStressIdx.value);
    }
    if (diseasePressure.present) {
      map['disease_pressure'] = Variable<double>(diseasePressure.value);
    }
    if (heightCm.present) {
      map['height_cm'] = Variable<double>(heightCm.value);
    }
    if (biomassRel.present) {
      map['biomass_rel'] = Variable<double>(biomassRel.value);
    }
    if (yieldMultiplier.present) {
      map['yield_multiplier'] = Variable<double>(yieldMultiplier.value);
    }
    if (lastComputedAt.present) {
      map['last_computed_at'] = Variable<DateTime>(lastComputedAt.value);
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
    return (StringBuffer('CropGrowthStatesCompanion(')
          ..write('cropId: $cropId, ')
          ..write('fieldId: $fieldId, ')
          ..write('asOfDate: $asOfDate, ')
          ..write('accumulatedGdd: $accumulatedGdd, ')
          ..write('currentStageKey: $currentStageKey, ')
          ..write('stageProgress: $stageProgress, ')
          ..write('waterDeficitMm: $waterDeficitMm, ')
          ..write('nStressIdx: $nStressIdx, ')
          ..write('kStressIdx: $kStressIdx, ')
          ..write('diseasePressure: $diseasePressure, ')
          ..write('heightCm: $heightCm, ')
          ..write('biomassRel: $biomassRel, ')
          ..write('yieldMultiplier: $yieldMultiplier, ')
          ..write('lastComputedAt: $lastComputedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FieldPlantInstancesTable extends FieldPlantInstances
    with TableInfo<$FieldPlantInstancesTable, FieldPlantInstance> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FieldPlantInstancesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _plantIndexMeta =
      const VerificationMeta('plantIndex');
  @override
  late final GeneratedColumn<int> plantIndex = GeneratedColumn<int>(
      'plant_index', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _cropNameMeta =
      const VerificationMeta('cropName');
  @override
  late final GeneratedColumn<String> cropName = GeneratedColumn<String>(
      'crop_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
      'lat', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _lngMeta = const VerificationMeta('lng');
  @override
  late final GeneratedColumn<double> lng = GeneratedColumn<double>(
      'lng', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _healthStatusMeta =
      const VerificationMeta('healthStatus');
  @override
  late final GeneratedColumn<String> healthStatus = GeneratedColumn<String>(
      'health_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('healthy'));
  static const VerificationMeta _diseaseTypeMeta =
      const VerificationMeta('diseaseType');
  @override
  late final GeneratedColumn<String> diseaseType = GeneratedColumn<String>(
      'disease_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _diseasePhotoPathMeta =
      const VerificationMeta('diseasePhotoPath');
  @override
  late final GeneratedColumn<String> diseasePhotoPath = GeneratedColumn<String>(
      'disease_photo_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _diagnosisSourceMeta =
      const VerificationMeta('diagnosisSource');
  @override
  late final GeneratedColumn<String> diagnosisSource = GeneratedColumn<String>(
      'diagnosis_source', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('manual'));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _plantedAtMeta =
      const VerificationMeta('plantedAt');
  @override
  late final GeneratedColumn<DateTime> plantedAt = GeneratedColumn<DateTime>(
      'planted_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _healthChangedAtMeta =
      const VerificationMeta('healthChangedAt');
  @override
  late final GeneratedColumn<DateTime> healthChangedAt =
      GeneratedColumn<DateTime>('health_changed_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _conditionFlagsJsonMeta =
      const VerificationMeta('conditionFlagsJson');
  @override
  late final GeneratedColumn<String> conditionFlagsJson =
      GeneratedColumn<String>('condition_flags_json', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _phenologyStageKeyMeta =
      const VerificationMeta('phenologyStageKey');
  @override
  late final GeneratedColumn<String> phenologyStageKey =
      GeneratedColumn<String>('phenology_stage_key', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _facingDirectionMeta =
      const VerificationMeta('facingDirection');
  @override
  late final GeneratedColumn<String> facingDirection = GeneratedColumn<String>(
      'facing_direction', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastObservedAtMeta =
      const VerificationMeta('lastObservedAt');
  @override
  late final GeneratedColumn<DateTime> lastObservedAt =
      GeneratedColumn<DateTime>('last_observed_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _farmerUidMeta =
      const VerificationMeta('farmerUid');
  @override
  late final GeneratedColumn<String> farmerUid = GeneratedColumn<String>(
      'farmer_uid', aliasedName, true,
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
        plantIndex,
        cropName,
        lat,
        lng,
        healthStatus,
        diseaseType,
        diseasePhotoPath,
        diagnosisSource,
        notes,
        plantedAt,
        healthChangedAt,
        conditionFlagsJson,
        phenologyStageKey,
        facingDirection,
        lastObservedAt,
        farmerUid,
        createdAt,
        updatedAt,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'field_plant_instances';
  @override
  VerificationContext validateIntegrity(Insertable<FieldPlantInstance> instance,
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
    if (data.containsKey('plant_index')) {
      context.handle(
          _plantIndexMeta,
          plantIndex.isAcceptableOrUnknown(
              data['plant_index']!, _plantIndexMeta));
    }
    if (data.containsKey('crop_name')) {
      context.handle(_cropNameMeta,
          cropName.isAcceptableOrUnknown(data['crop_name']!, _cropNameMeta));
    } else if (isInserting) {
      context.missing(_cropNameMeta);
    }
    if (data.containsKey('lat')) {
      context.handle(
          _latMeta, lat.isAcceptableOrUnknown(data['lat']!, _latMeta));
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lng')) {
      context.handle(
          _lngMeta, lng.isAcceptableOrUnknown(data['lng']!, _lngMeta));
    } else if (isInserting) {
      context.missing(_lngMeta);
    }
    if (data.containsKey('health_status')) {
      context.handle(
          _healthStatusMeta,
          healthStatus.isAcceptableOrUnknown(
              data['health_status']!, _healthStatusMeta));
    }
    if (data.containsKey('disease_type')) {
      context.handle(
          _diseaseTypeMeta,
          diseaseType.isAcceptableOrUnknown(
              data['disease_type']!, _diseaseTypeMeta));
    }
    if (data.containsKey('disease_photo_path')) {
      context.handle(
          _diseasePhotoPathMeta,
          diseasePhotoPath.isAcceptableOrUnknown(
              data['disease_photo_path']!, _diseasePhotoPathMeta));
    }
    if (data.containsKey('diagnosis_source')) {
      context.handle(
          _diagnosisSourceMeta,
          diagnosisSource.isAcceptableOrUnknown(
              data['diagnosis_source']!, _diagnosisSourceMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('planted_at')) {
      context.handle(_plantedAtMeta,
          plantedAt.isAcceptableOrUnknown(data['planted_at']!, _plantedAtMeta));
    } else if (isInserting) {
      context.missing(_plantedAtMeta);
    }
    if (data.containsKey('health_changed_at')) {
      context.handle(
          _healthChangedAtMeta,
          healthChangedAt.isAcceptableOrUnknown(
              data['health_changed_at']!, _healthChangedAtMeta));
    }
    if (data.containsKey('condition_flags_json')) {
      context.handle(
          _conditionFlagsJsonMeta,
          conditionFlagsJson.isAcceptableOrUnknown(
              data['condition_flags_json']!, _conditionFlagsJsonMeta));
    }
    if (data.containsKey('phenology_stage_key')) {
      context.handle(
          _phenologyStageKeyMeta,
          phenologyStageKey.isAcceptableOrUnknown(
              data['phenology_stage_key']!, _phenologyStageKeyMeta));
    }
    if (data.containsKey('facing_direction')) {
      context.handle(
          _facingDirectionMeta,
          facingDirection.isAcceptableOrUnknown(
              data['facing_direction']!, _facingDirectionMeta));
    }
    if (data.containsKey('last_observed_at')) {
      context.handle(
          _lastObservedAtMeta,
          lastObservedAt.isAcceptableOrUnknown(
              data['last_observed_at']!, _lastObservedAtMeta));
    }
    if (data.containsKey('farmer_uid')) {
      context.handle(_farmerUidMeta,
          farmerUid.isAcceptableOrUnknown(data['farmer_uid']!, _farmerUidMeta));
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
  FieldPlantInstance map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FieldPlantInstance(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      fieldId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}field_id'])!,
      cropId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}crop_id']),
      plantIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}plant_index']),
      cropName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}crop_name'])!,
      lat: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}lat'])!,
      lng: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}lng'])!,
      healthStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}health_status'])!,
      diseaseType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}disease_type']),
      diseasePhotoPath: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}disease_photo_path']),
      diagnosisSource: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}diagnosis_source'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      plantedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}planted_at'])!,
      healthChangedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}health_changed_at']),
      conditionFlagsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}condition_flags_json']),
      phenologyStageKey: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}phenology_stage_key']),
      facingDirection: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}facing_direction']),
      lastObservedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_observed_at']),
      farmerUid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}farmer_uid']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $FieldPlantInstancesTable createAlias(String alias) {
    return $FieldPlantInstancesTable(attachedDatabase, alias);
  }
}

class FieldPlantInstance extends DataClass
    implements Insertable<FieldPlantInstance> {
  final String id;
  final String fieldId;
  final String? cropId;
  final int? plantIndex;
  final String cropName;
  final double lat;
  final double lng;

  /// 'healthy' | 'diseased' | 'dead'
  final String healthStatus;

  /// 'Mildiyö', 'Pas', 'Yaprak Lekesi', vb. (manuel veya AI sonucu)
  final String? diseaseType;

  /// Hastalık fotoğrafı yerel yolu (app docs altında).
  final String? diseasePhotoPath;

  /// 'manual' | 'ai_pending' | 'ai_completed'
  final String diagnosisSource;
  final String? notes;
  final DateTime plantedAt;
  final DateTime? healthChangedAt;

  /// Çoklu nüans bayrağı JSON — ['water_stress','nutrient_deficiency','flowering'].
  /// healthStatus üç-değerli kaba durumu tutarken bu liste niteliksel
  /// detayları taşır; tavsiye motoru her ikisini de okur. (v8)
  final String? conditionFlagsJson;

  /// Tekil bitki için fenoloji evresi override'ı. null ise zone'un
  /// CropGrowthStates.currentStageKey değerinden miras alınır. (v8)
  final String? phenologyStageKey;

  /// Tekil bitkinin baktığı yön. Toplu ekimlerde FieldCrops.facingDirection
  /// kullanılır; standalone bitkiler kendi yönünü burada tutar. (v10)
  final String? facingDirection;

  /// Son kullanıcı/AI gözlem tarihi — durum geçmişi sıralaması için. (v8)
  final DateTime? lastObservedAt;
  final String? farmerUid;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const FieldPlantInstance(
      {required this.id,
      required this.fieldId,
      this.cropId,
      this.plantIndex,
      required this.cropName,
      required this.lat,
      required this.lng,
      required this.healthStatus,
      this.diseaseType,
      this.diseasePhotoPath,
      required this.diagnosisSource,
      this.notes,
      required this.plantedAt,
      this.healthChangedAt,
      this.conditionFlagsJson,
      this.phenologyStageKey,
      this.facingDirection,
      this.lastObservedAt,
      this.farmerUid,
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
    if (!nullToAbsent || plantIndex != null) {
      map['plant_index'] = Variable<int>(plantIndex);
    }
    map['crop_name'] = Variable<String>(cropName);
    map['lat'] = Variable<double>(lat);
    map['lng'] = Variable<double>(lng);
    map['health_status'] = Variable<String>(healthStatus);
    if (!nullToAbsent || diseaseType != null) {
      map['disease_type'] = Variable<String>(diseaseType);
    }
    if (!nullToAbsent || diseasePhotoPath != null) {
      map['disease_photo_path'] = Variable<String>(diseasePhotoPath);
    }
    map['diagnosis_source'] = Variable<String>(diagnosisSource);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['planted_at'] = Variable<DateTime>(plantedAt);
    if (!nullToAbsent || healthChangedAt != null) {
      map['health_changed_at'] = Variable<DateTime>(healthChangedAt);
    }
    if (!nullToAbsent || conditionFlagsJson != null) {
      map['condition_flags_json'] = Variable<String>(conditionFlagsJson);
    }
    if (!nullToAbsent || phenologyStageKey != null) {
      map['phenology_stage_key'] = Variable<String>(phenologyStageKey);
    }
    if (!nullToAbsent || facingDirection != null) {
      map['facing_direction'] = Variable<String>(facingDirection);
    }
    if (!nullToAbsent || lastObservedAt != null) {
      map['last_observed_at'] = Variable<DateTime>(lastObservedAt);
    }
    if (!nullToAbsent || farmerUid != null) {
      map['farmer_uid'] = Variable<String>(farmerUid);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  FieldPlantInstancesCompanion toCompanion(bool nullToAbsent) {
    return FieldPlantInstancesCompanion(
      id: Value(id),
      fieldId: Value(fieldId),
      cropId:
          cropId == null && nullToAbsent ? const Value.absent() : Value(cropId),
      plantIndex: plantIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(plantIndex),
      cropName: Value(cropName),
      lat: Value(lat),
      lng: Value(lng),
      healthStatus: Value(healthStatus),
      diseaseType: diseaseType == null && nullToAbsent
          ? const Value.absent()
          : Value(diseaseType),
      diseasePhotoPath: diseasePhotoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(diseasePhotoPath),
      diagnosisSource: Value(diagnosisSource),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      plantedAt: Value(plantedAt),
      healthChangedAt: healthChangedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(healthChangedAt),
      conditionFlagsJson: conditionFlagsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(conditionFlagsJson),
      phenologyStageKey: phenologyStageKey == null && nullToAbsent
          ? const Value.absent()
          : Value(phenologyStageKey),
      facingDirection: facingDirection == null && nullToAbsent
          ? const Value.absent()
          : Value(facingDirection),
      lastObservedAt: lastObservedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastObservedAt),
      farmerUid: farmerUid == null && nullToAbsent
          ? const Value.absent()
          : Value(farmerUid),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory FieldPlantInstance.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FieldPlantInstance(
      id: serializer.fromJson<String>(json['id']),
      fieldId: serializer.fromJson<String>(json['fieldId']),
      cropId: serializer.fromJson<String?>(json['cropId']),
      plantIndex: serializer.fromJson<int?>(json['plantIndex']),
      cropName: serializer.fromJson<String>(json['cropName']),
      lat: serializer.fromJson<double>(json['lat']),
      lng: serializer.fromJson<double>(json['lng']),
      healthStatus: serializer.fromJson<String>(json['healthStatus']),
      diseaseType: serializer.fromJson<String?>(json['diseaseType']),
      diseasePhotoPath: serializer.fromJson<String?>(json['diseasePhotoPath']),
      diagnosisSource: serializer.fromJson<String>(json['diagnosisSource']),
      notes: serializer.fromJson<String?>(json['notes']),
      plantedAt: serializer.fromJson<DateTime>(json['plantedAt']),
      healthChangedAt: serializer.fromJson<DateTime?>(json['healthChangedAt']),
      conditionFlagsJson:
          serializer.fromJson<String?>(json['conditionFlagsJson']),
      phenologyStageKey:
          serializer.fromJson<String?>(json['phenologyStageKey']),
      facingDirection: serializer.fromJson<String?>(json['facingDirection']),
      lastObservedAt: serializer.fromJson<DateTime?>(json['lastObservedAt']),
      farmerUid: serializer.fromJson<String?>(json['farmerUid']),
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
      'plantIndex': serializer.toJson<int?>(plantIndex),
      'cropName': serializer.toJson<String>(cropName),
      'lat': serializer.toJson<double>(lat),
      'lng': serializer.toJson<double>(lng),
      'healthStatus': serializer.toJson<String>(healthStatus),
      'diseaseType': serializer.toJson<String?>(diseaseType),
      'diseasePhotoPath': serializer.toJson<String?>(diseasePhotoPath),
      'diagnosisSource': serializer.toJson<String>(diagnosisSource),
      'notes': serializer.toJson<String?>(notes),
      'plantedAt': serializer.toJson<DateTime>(plantedAt),
      'healthChangedAt': serializer.toJson<DateTime?>(healthChangedAt),
      'conditionFlagsJson': serializer.toJson<String?>(conditionFlagsJson),
      'phenologyStageKey': serializer.toJson<String?>(phenologyStageKey),
      'facingDirection': serializer.toJson<String?>(facingDirection),
      'lastObservedAt': serializer.toJson<DateTime?>(lastObservedAt),
      'farmerUid': serializer.toJson<String?>(farmerUid),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  FieldPlantInstance copyWith(
          {String? id,
          String? fieldId,
          Value<String?> cropId = const Value.absent(),
          Value<int?> plantIndex = const Value.absent(),
          String? cropName,
          double? lat,
          double? lng,
          String? healthStatus,
          Value<String?> diseaseType = const Value.absent(),
          Value<String?> diseasePhotoPath = const Value.absent(),
          String? diagnosisSource,
          Value<String?> notes = const Value.absent(),
          DateTime? plantedAt,
          Value<DateTime?> healthChangedAt = const Value.absent(),
          Value<String?> conditionFlagsJson = const Value.absent(),
          Value<String?> phenologyStageKey = const Value.absent(),
          Value<String?> facingDirection = const Value.absent(),
          Value<DateTime?> lastObservedAt = const Value.absent(),
          Value<String?> farmerUid = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent()}) =>
      FieldPlantInstance(
        id: id ?? this.id,
        fieldId: fieldId ?? this.fieldId,
        cropId: cropId.present ? cropId.value : this.cropId,
        plantIndex: plantIndex.present ? plantIndex.value : this.plantIndex,
        cropName: cropName ?? this.cropName,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        healthStatus: healthStatus ?? this.healthStatus,
        diseaseType: diseaseType.present ? diseaseType.value : this.diseaseType,
        diseasePhotoPath: diseasePhotoPath.present
            ? diseasePhotoPath.value
            : this.diseasePhotoPath,
        diagnosisSource: diagnosisSource ?? this.diagnosisSource,
        notes: notes.present ? notes.value : this.notes,
        plantedAt: plantedAt ?? this.plantedAt,
        healthChangedAt: healthChangedAt.present
            ? healthChangedAt.value
            : this.healthChangedAt,
        conditionFlagsJson: conditionFlagsJson.present
            ? conditionFlagsJson.value
            : this.conditionFlagsJson,
        phenologyStageKey: phenologyStageKey.present
            ? phenologyStageKey.value
            : this.phenologyStageKey,
        facingDirection: facingDirection.present
            ? facingDirection.value
            : this.facingDirection,
        lastObservedAt:
            lastObservedAt.present ? lastObservedAt.value : this.lastObservedAt,
        farmerUid: farmerUid.present ? farmerUid.value : this.farmerUid,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  FieldPlantInstance copyWithCompanion(FieldPlantInstancesCompanion data) {
    return FieldPlantInstance(
      id: data.id.present ? data.id.value : this.id,
      fieldId: data.fieldId.present ? data.fieldId.value : this.fieldId,
      cropId: data.cropId.present ? data.cropId.value : this.cropId,
      plantIndex:
          data.plantIndex.present ? data.plantIndex.value : this.plantIndex,
      cropName: data.cropName.present ? data.cropName.value : this.cropName,
      lat: data.lat.present ? data.lat.value : this.lat,
      lng: data.lng.present ? data.lng.value : this.lng,
      healthStatus: data.healthStatus.present
          ? data.healthStatus.value
          : this.healthStatus,
      diseaseType:
          data.diseaseType.present ? data.diseaseType.value : this.diseaseType,
      diseasePhotoPath: data.diseasePhotoPath.present
          ? data.diseasePhotoPath.value
          : this.diseasePhotoPath,
      diagnosisSource: data.diagnosisSource.present
          ? data.diagnosisSource.value
          : this.diagnosisSource,
      notes: data.notes.present ? data.notes.value : this.notes,
      plantedAt: data.plantedAt.present ? data.plantedAt.value : this.plantedAt,
      healthChangedAt: data.healthChangedAt.present
          ? data.healthChangedAt.value
          : this.healthChangedAt,
      conditionFlagsJson: data.conditionFlagsJson.present
          ? data.conditionFlagsJson.value
          : this.conditionFlagsJson,
      phenologyStageKey: data.phenologyStageKey.present
          ? data.phenologyStageKey.value
          : this.phenologyStageKey,
      facingDirection: data.facingDirection.present
          ? data.facingDirection.value
          : this.facingDirection,
      lastObservedAt: data.lastObservedAt.present
          ? data.lastObservedAt.value
          : this.lastObservedAt,
      farmerUid: data.farmerUid.present ? data.farmerUid.value : this.farmerUid,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FieldPlantInstance(')
          ..write('id: $id, ')
          ..write('fieldId: $fieldId, ')
          ..write('cropId: $cropId, ')
          ..write('plantIndex: $plantIndex, ')
          ..write('cropName: $cropName, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('healthStatus: $healthStatus, ')
          ..write('diseaseType: $diseaseType, ')
          ..write('diseasePhotoPath: $diseasePhotoPath, ')
          ..write('diagnosisSource: $diagnosisSource, ')
          ..write('notes: $notes, ')
          ..write('plantedAt: $plantedAt, ')
          ..write('healthChangedAt: $healthChangedAt, ')
          ..write('conditionFlagsJson: $conditionFlagsJson, ')
          ..write('phenologyStageKey: $phenologyStageKey, ')
          ..write('facingDirection: $facingDirection, ')
          ..write('lastObservedAt: $lastObservedAt, ')
          ..write('farmerUid: $farmerUid, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        fieldId,
        cropId,
        plantIndex,
        cropName,
        lat,
        lng,
        healthStatus,
        diseaseType,
        diseasePhotoPath,
        diagnosisSource,
        notes,
        plantedAt,
        healthChangedAt,
        conditionFlagsJson,
        phenologyStageKey,
        facingDirection,
        lastObservedAt,
        farmerUid,
        createdAt,
        updatedAt,
        deletedAt
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FieldPlantInstance &&
          other.id == this.id &&
          other.fieldId == this.fieldId &&
          other.cropId == this.cropId &&
          other.plantIndex == this.plantIndex &&
          other.cropName == this.cropName &&
          other.lat == this.lat &&
          other.lng == this.lng &&
          other.healthStatus == this.healthStatus &&
          other.diseaseType == this.diseaseType &&
          other.diseasePhotoPath == this.diseasePhotoPath &&
          other.diagnosisSource == this.diagnosisSource &&
          other.notes == this.notes &&
          other.plantedAt == this.plantedAt &&
          other.healthChangedAt == this.healthChangedAt &&
          other.conditionFlagsJson == this.conditionFlagsJson &&
          other.phenologyStageKey == this.phenologyStageKey &&
          other.facingDirection == this.facingDirection &&
          other.lastObservedAt == this.lastObservedAt &&
          other.farmerUid == this.farmerUid &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class FieldPlantInstancesCompanion extends UpdateCompanion<FieldPlantInstance> {
  final Value<String> id;
  final Value<String> fieldId;
  final Value<String?> cropId;
  final Value<int?> plantIndex;
  final Value<String> cropName;
  final Value<double> lat;
  final Value<double> lng;
  final Value<String> healthStatus;
  final Value<String?> diseaseType;
  final Value<String?> diseasePhotoPath;
  final Value<String> diagnosisSource;
  final Value<String?> notes;
  final Value<DateTime> plantedAt;
  final Value<DateTime?> healthChangedAt;
  final Value<String?> conditionFlagsJson;
  final Value<String?> phenologyStageKey;
  final Value<String?> facingDirection;
  final Value<DateTime?> lastObservedAt;
  final Value<String?> farmerUid;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const FieldPlantInstancesCompanion({
    this.id = const Value.absent(),
    this.fieldId = const Value.absent(),
    this.cropId = const Value.absent(),
    this.plantIndex = const Value.absent(),
    this.cropName = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.healthStatus = const Value.absent(),
    this.diseaseType = const Value.absent(),
    this.diseasePhotoPath = const Value.absent(),
    this.diagnosisSource = const Value.absent(),
    this.notes = const Value.absent(),
    this.plantedAt = const Value.absent(),
    this.healthChangedAt = const Value.absent(),
    this.conditionFlagsJson = const Value.absent(),
    this.phenologyStageKey = const Value.absent(),
    this.facingDirection = const Value.absent(),
    this.lastObservedAt = const Value.absent(),
    this.farmerUid = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FieldPlantInstancesCompanion.insert({
    required String id,
    required String fieldId,
    this.cropId = const Value.absent(),
    this.plantIndex = const Value.absent(),
    required String cropName,
    required double lat,
    required double lng,
    this.healthStatus = const Value.absent(),
    this.diseaseType = const Value.absent(),
    this.diseasePhotoPath = const Value.absent(),
    this.diagnosisSource = const Value.absent(),
    this.notes = const Value.absent(),
    required DateTime plantedAt,
    this.healthChangedAt = const Value.absent(),
    this.conditionFlagsJson = const Value.absent(),
    this.phenologyStageKey = const Value.absent(),
    this.facingDirection = const Value.absent(),
    this.lastObservedAt = const Value.absent(),
    this.farmerUid = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        fieldId = Value(fieldId),
        cropName = Value(cropName),
        lat = Value(lat),
        lng = Value(lng),
        plantedAt = Value(plantedAt),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<FieldPlantInstance> custom({
    Expression<String>? id,
    Expression<String>? fieldId,
    Expression<String>? cropId,
    Expression<int>? plantIndex,
    Expression<String>? cropName,
    Expression<double>? lat,
    Expression<double>? lng,
    Expression<String>? healthStatus,
    Expression<String>? diseaseType,
    Expression<String>? diseasePhotoPath,
    Expression<String>? diagnosisSource,
    Expression<String>? notes,
    Expression<DateTime>? plantedAt,
    Expression<DateTime>? healthChangedAt,
    Expression<String>? conditionFlagsJson,
    Expression<String>? phenologyStageKey,
    Expression<String>? facingDirection,
    Expression<DateTime>? lastObservedAt,
    Expression<String>? farmerUid,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fieldId != null) 'field_id': fieldId,
      if (cropId != null) 'crop_id': cropId,
      if (plantIndex != null) 'plant_index': plantIndex,
      if (cropName != null) 'crop_name': cropName,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (healthStatus != null) 'health_status': healthStatus,
      if (diseaseType != null) 'disease_type': diseaseType,
      if (diseasePhotoPath != null) 'disease_photo_path': diseasePhotoPath,
      if (diagnosisSource != null) 'diagnosis_source': diagnosisSource,
      if (notes != null) 'notes': notes,
      if (plantedAt != null) 'planted_at': plantedAt,
      if (healthChangedAt != null) 'health_changed_at': healthChangedAt,
      if (conditionFlagsJson != null)
        'condition_flags_json': conditionFlagsJson,
      if (phenologyStageKey != null) 'phenology_stage_key': phenologyStageKey,
      if (facingDirection != null) 'facing_direction': facingDirection,
      if (lastObservedAt != null) 'last_observed_at': lastObservedAt,
      if (farmerUid != null) 'farmer_uid': farmerUid,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FieldPlantInstancesCompanion copyWith(
      {Value<String>? id,
      Value<String>? fieldId,
      Value<String?>? cropId,
      Value<int?>? plantIndex,
      Value<String>? cropName,
      Value<double>? lat,
      Value<double>? lng,
      Value<String>? healthStatus,
      Value<String?>? diseaseType,
      Value<String?>? diseasePhotoPath,
      Value<String>? diagnosisSource,
      Value<String?>? notes,
      Value<DateTime>? plantedAt,
      Value<DateTime?>? healthChangedAt,
      Value<String?>? conditionFlagsJson,
      Value<String?>? phenologyStageKey,
      Value<String?>? facingDirection,
      Value<DateTime?>? lastObservedAt,
      Value<String?>? farmerUid,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<int>? rowid}) {
    return FieldPlantInstancesCompanion(
      id: id ?? this.id,
      fieldId: fieldId ?? this.fieldId,
      cropId: cropId ?? this.cropId,
      plantIndex: plantIndex ?? this.plantIndex,
      cropName: cropName ?? this.cropName,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      healthStatus: healthStatus ?? this.healthStatus,
      diseaseType: diseaseType ?? this.diseaseType,
      diseasePhotoPath: diseasePhotoPath ?? this.diseasePhotoPath,
      diagnosisSource: diagnosisSource ?? this.diagnosisSource,
      notes: notes ?? this.notes,
      plantedAt: plantedAt ?? this.plantedAt,
      healthChangedAt: healthChangedAt ?? this.healthChangedAt,
      conditionFlagsJson: conditionFlagsJson ?? this.conditionFlagsJson,
      phenologyStageKey: phenologyStageKey ?? this.phenologyStageKey,
      facingDirection: facingDirection ?? this.facingDirection,
      lastObservedAt: lastObservedAt ?? this.lastObservedAt,
      farmerUid: farmerUid ?? this.farmerUid,
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
    if (plantIndex.present) {
      map['plant_index'] = Variable<int>(plantIndex.value);
    }
    if (cropName.present) {
      map['crop_name'] = Variable<String>(cropName.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lng.present) {
      map['lng'] = Variable<double>(lng.value);
    }
    if (healthStatus.present) {
      map['health_status'] = Variable<String>(healthStatus.value);
    }
    if (diseaseType.present) {
      map['disease_type'] = Variable<String>(diseaseType.value);
    }
    if (diseasePhotoPath.present) {
      map['disease_photo_path'] = Variable<String>(diseasePhotoPath.value);
    }
    if (diagnosisSource.present) {
      map['diagnosis_source'] = Variable<String>(diagnosisSource.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (plantedAt.present) {
      map['planted_at'] = Variable<DateTime>(plantedAt.value);
    }
    if (healthChangedAt.present) {
      map['health_changed_at'] = Variable<DateTime>(healthChangedAt.value);
    }
    if (conditionFlagsJson.present) {
      map['condition_flags_json'] = Variable<String>(conditionFlagsJson.value);
    }
    if (phenologyStageKey.present) {
      map['phenology_stage_key'] = Variable<String>(phenologyStageKey.value);
    }
    if (facingDirection.present) {
      map['facing_direction'] = Variable<String>(facingDirection.value);
    }
    if (lastObservedAt.present) {
      map['last_observed_at'] = Variable<DateTime>(lastObservedAt.value);
    }
    if (farmerUid.present) {
      map['farmer_uid'] = Variable<String>(farmerUid.value);
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
    return (StringBuffer('FieldPlantInstancesCompanion(')
          ..write('id: $id, ')
          ..write('fieldId: $fieldId, ')
          ..write('cropId: $cropId, ')
          ..write('plantIndex: $plantIndex, ')
          ..write('cropName: $cropName, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('healthStatus: $healthStatus, ')
          ..write('diseaseType: $diseaseType, ')
          ..write('diseasePhotoPath: $diseasePhotoPath, ')
          ..write('diagnosisSource: $diagnosisSource, ')
          ..write('notes: $notes, ')
          ..write('plantedAt: $plantedAt, ')
          ..write('healthChangedAt: $healthChangedAt, ')
          ..write('conditionFlagsJson: $conditionFlagsJson, ')
          ..write('phenologyStageKey: $phenologyStageKey, ')
          ..write('facingDirection: $facingDirection, ')
          ..write('lastObservedAt: $lastObservedAt, ')
          ..write('farmerUid: $farmerUid, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlantConditionEventsTable extends PlantConditionEvents
    with TableInfo<$PlantConditionEventsTable, PlantConditionEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlantConditionEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _plantInstanceIdMeta =
      const VerificationMeta('plantInstanceId');
  @override
  late final GeneratedColumn<String> plantInstanceId = GeneratedColumn<String>(
      'plant_instance_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fieldIdMeta =
      const VerificationMeta('fieldId');
  @override
  late final GeneratedColumn<String> fieldId = GeneratedColumn<String>(
      'field_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _cropIdMeta = const VerificationMeta('cropId');
  @override
  late final GeneratedColumn<String> cropId = GeneratedColumn<String>(
      'crop_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _conditionMeta =
      const VerificationMeta('condition');
  @override
  late final GeneratedColumn<String> condition = GeneratedColumn<String>(
      'condition', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceTypeMeta =
      const VerificationMeta('sourceType');
  @override
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
      'source_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('manual'));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _photoPathMeta =
      const VerificationMeta('photoPath');
  @override
  late final GeneratedColumn<String> photoPath = GeneratedColumn<String>(
      'photo_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _observedAtMeta =
      const VerificationMeta('observedAt');
  @override
  late final GeneratedColumn<DateTime> observedAt = GeneratedColumn<DateTime>(
      'observed_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _farmerUidMeta =
      const VerificationMeta('farmerUid');
  @override
  late final GeneratedColumn<String> farmerUid = GeneratedColumn<String>(
      'farmer_uid', aliasedName, true,
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
        plantInstanceId,
        fieldId,
        cropId,
        condition,
        sourceType,
        notes,
        photoPath,
        observedAt,
        farmerUid,
        createdAt,
        updatedAt,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plant_condition_events';
  @override
  VerificationContext validateIntegrity(
      Insertable<PlantConditionEvent> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('plant_instance_id')) {
      context.handle(
          _plantInstanceIdMeta,
          plantInstanceId.isAcceptableOrUnknown(
              data['plant_instance_id']!, _plantInstanceIdMeta));
    } else if (isInserting) {
      context.missing(_plantInstanceIdMeta);
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
    if (data.containsKey('condition')) {
      context.handle(_conditionMeta,
          condition.isAcceptableOrUnknown(data['condition']!, _conditionMeta));
    } else if (isInserting) {
      context.missing(_conditionMeta);
    }
    if (data.containsKey('source_type')) {
      context.handle(
          _sourceTypeMeta,
          sourceType.isAcceptableOrUnknown(
              data['source_type']!, _sourceTypeMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('photo_path')) {
      context.handle(_photoPathMeta,
          photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta));
    }
    if (data.containsKey('observed_at')) {
      context.handle(
          _observedAtMeta,
          observedAt.isAcceptableOrUnknown(
              data['observed_at']!, _observedAtMeta));
    } else if (isInserting) {
      context.missing(_observedAtMeta);
    }
    if (data.containsKey('farmer_uid')) {
      context.handle(_farmerUidMeta,
          farmerUid.isAcceptableOrUnknown(data['farmer_uid']!, _farmerUidMeta));
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
  PlantConditionEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlantConditionEvent(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      plantInstanceId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}plant_instance_id'])!,
      fieldId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}field_id'])!,
      cropId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}crop_id']),
      condition: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}condition'])!,
      sourceType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_type'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      photoPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}photo_path']),
      observedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}observed_at'])!,
      farmerUid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}farmer_uid']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $PlantConditionEventsTable createAlias(String alias) {
    return $PlantConditionEventsTable(attachedDatabase, alias);
  }
}

class PlantConditionEvent extends DataClass
    implements Insertable<PlantConditionEvent> {
  final String id;
  final String plantInstanceId;
  final String fieldId;
  final String? cropId;

  /// 'healthy' | 'disease_symptom' | 'pest_risk' | 'water_stress' |
  /// 'nutrient_deficiency' | 'stunted' | 'flowering' | 'grain_filling' |
  /// 'near_harvest' | 'dead' | 'removed_by_user'
  final String condition;

  /// 'manual' | 'auto' | 'ai'
  final String sourceType;
  final String? notes;
  final String? photoPath;
  final DateTime observedAt;
  final String? farmerUid;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const PlantConditionEvent(
      {required this.id,
      required this.plantInstanceId,
      required this.fieldId,
      this.cropId,
      required this.condition,
      required this.sourceType,
      this.notes,
      this.photoPath,
      required this.observedAt,
      this.farmerUid,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['plant_instance_id'] = Variable<String>(plantInstanceId);
    map['field_id'] = Variable<String>(fieldId);
    if (!nullToAbsent || cropId != null) {
      map['crop_id'] = Variable<String>(cropId);
    }
    map['condition'] = Variable<String>(condition);
    map['source_type'] = Variable<String>(sourceType);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || photoPath != null) {
      map['photo_path'] = Variable<String>(photoPath);
    }
    map['observed_at'] = Variable<DateTime>(observedAt);
    if (!nullToAbsent || farmerUid != null) {
      map['farmer_uid'] = Variable<String>(farmerUid);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  PlantConditionEventsCompanion toCompanion(bool nullToAbsent) {
    return PlantConditionEventsCompanion(
      id: Value(id),
      plantInstanceId: Value(plantInstanceId),
      fieldId: Value(fieldId),
      cropId:
          cropId == null && nullToAbsent ? const Value.absent() : Value(cropId),
      condition: Value(condition),
      sourceType: Value(sourceType),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      photoPath: photoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(photoPath),
      observedAt: Value(observedAt),
      farmerUid: farmerUid == null && nullToAbsent
          ? const Value.absent()
          : Value(farmerUid),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory PlantConditionEvent.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlantConditionEvent(
      id: serializer.fromJson<String>(json['id']),
      plantInstanceId: serializer.fromJson<String>(json['plantInstanceId']),
      fieldId: serializer.fromJson<String>(json['fieldId']),
      cropId: serializer.fromJson<String?>(json['cropId']),
      condition: serializer.fromJson<String>(json['condition']),
      sourceType: serializer.fromJson<String>(json['sourceType']),
      notes: serializer.fromJson<String?>(json['notes']),
      photoPath: serializer.fromJson<String?>(json['photoPath']),
      observedAt: serializer.fromJson<DateTime>(json['observedAt']),
      farmerUid: serializer.fromJson<String?>(json['farmerUid']),
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
      'plantInstanceId': serializer.toJson<String>(plantInstanceId),
      'fieldId': serializer.toJson<String>(fieldId),
      'cropId': serializer.toJson<String?>(cropId),
      'condition': serializer.toJson<String>(condition),
      'sourceType': serializer.toJson<String>(sourceType),
      'notes': serializer.toJson<String?>(notes),
      'photoPath': serializer.toJson<String?>(photoPath),
      'observedAt': serializer.toJson<DateTime>(observedAt),
      'farmerUid': serializer.toJson<String?>(farmerUid),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  PlantConditionEvent copyWith(
          {String? id,
          String? plantInstanceId,
          String? fieldId,
          Value<String?> cropId = const Value.absent(),
          String? condition,
          String? sourceType,
          Value<String?> notes = const Value.absent(),
          Value<String?> photoPath = const Value.absent(),
          DateTime? observedAt,
          Value<String?> farmerUid = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent()}) =>
      PlantConditionEvent(
        id: id ?? this.id,
        plantInstanceId: plantInstanceId ?? this.plantInstanceId,
        fieldId: fieldId ?? this.fieldId,
        cropId: cropId.present ? cropId.value : this.cropId,
        condition: condition ?? this.condition,
        sourceType: sourceType ?? this.sourceType,
        notes: notes.present ? notes.value : this.notes,
        photoPath: photoPath.present ? photoPath.value : this.photoPath,
        observedAt: observedAt ?? this.observedAt,
        farmerUid: farmerUid.present ? farmerUid.value : this.farmerUid,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  PlantConditionEvent copyWithCompanion(PlantConditionEventsCompanion data) {
    return PlantConditionEvent(
      id: data.id.present ? data.id.value : this.id,
      plantInstanceId: data.plantInstanceId.present
          ? data.plantInstanceId.value
          : this.plantInstanceId,
      fieldId: data.fieldId.present ? data.fieldId.value : this.fieldId,
      cropId: data.cropId.present ? data.cropId.value : this.cropId,
      condition: data.condition.present ? data.condition.value : this.condition,
      sourceType:
          data.sourceType.present ? data.sourceType.value : this.sourceType,
      notes: data.notes.present ? data.notes.value : this.notes,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
      observedAt:
          data.observedAt.present ? data.observedAt.value : this.observedAt,
      farmerUid: data.farmerUid.present ? data.farmerUid.value : this.farmerUid,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlantConditionEvent(')
          ..write('id: $id, ')
          ..write('plantInstanceId: $plantInstanceId, ')
          ..write('fieldId: $fieldId, ')
          ..write('cropId: $cropId, ')
          ..write('condition: $condition, ')
          ..write('sourceType: $sourceType, ')
          ..write('notes: $notes, ')
          ..write('photoPath: $photoPath, ')
          ..write('observedAt: $observedAt, ')
          ..write('farmerUid: $farmerUid, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      plantInstanceId,
      fieldId,
      cropId,
      condition,
      sourceType,
      notes,
      photoPath,
      observedAt,
      farmerUid,
      createdAt,
      updatedAt,
      deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlantConditionEvent &&
          other.id == this.id &&
          other.plantInstanceId == this.plantInstanceId &&
          other.fieldId == this.fieldId &&
          other.cropId == this.cropId &&
          other.condition == this.condition &&
          other.sourceType == this.sourceType &&
          other.notes == this.notes &&
          other.photoPath == this.photoPath &&
          other.observedAt == this.observedAt &&
          other.farmerUid == this.farmerUid &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class PlantConditionEventsCompanion
    extends UpdateCompanion<PlantConditionEvent> {
  final Value<String> id;
  final Value<String> plantInstanceId;
  final Value<String> fieldId;
  final Value<String?> cropId;
  final Value<String> condition;
  final Value<String> sourceType;
  final Value<String?> notes;
  final Value<String?> photoPath;
  final Value<DateTime> observedAt;
  final Value<String?> farmerUid;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const PlantConditionEventsCompanion({
    this.id = const Value.absent(),
    this.plantInstanceId = const Value.absent(),
    this.fieldId = const Value.absent(),
    this.cropId = const Value.absent(),
    this.condition = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.notes = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.observedAt = const Value.absent(),
    this.farmerUid = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlantConditionEventsCompanion.insert({
    required String id,
    required String plantInstanceId,
    required String fieldId,
    this.cropId = const Value.absent(),
    required String condition,
    this.sourceType = const Value.absent(),
    this.notes = const Value.absent(),
    this.photoPath = const Value.absent(),
    required DateTime observedAt,
    this.farmerUid = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        plantInstanceId = Value(plantInstanceId),
        fieldId = Value(fieldId),
        condition = Value(condition),
        observedAt = Value(observedAt),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<PlantConditionEvent> custom({
    Expression<String>? id,
    Expression<String>? plantInstanceId,
    Expression<String>? fieldId,
    Expression<String>? cropId,
    Expression<String>? condition,
    Expression<String>? sourceType,
    Expression<String>? notes,
    Expression<String>? photoPath,
    Expression<DateTime>? observedAt,
    Expression<String>? farmerUid,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (plantInstanceId != null) 'plant_instance_id': plantInstanceId,
      if (fieldId != null) 'field_id': fieldId,
      if (cropId != null) 'crop_id': cropId,
      if (condition != null) 'condition': condition,
      if (sourceType != null) 'source_type': sourceType,
      if (notes != null) 'notes': notes,
      if (photoPath != null) 'photo_path': photoPath,
      if (observedAt != null) 'observed_at': observedAt,
      if (farmerUid != null) 'farmer_uid': farmerUid,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlantConditionEventsCompanion copyWith(
      {Value<String>? id,
      Value<String>? plantInstanceId,
      Value<String>? fieldId,
      Value<String?>? cropId,
      Value<String>? condition,
      Value<String>? sourceType,
      Value<String?>? notes,
      Value<String?>? photoPath,
      Value<DateTime>? observedAt,
      Value<String?>? farmerUid,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<int>? rowid}) {
    return PlantConditionEventsCompanion(
      id: id ?? this.id,
      plantInstanceId: plantInstanceId ?? this.plantInstanceId,
      fieldId: fieldId ?? this.fieldId,
      cropId: cropId ?? this.cropId,
      condition: condition ?? this.condition,
      sourceType: sourceType ?? this.sourceType,
      notes: notes ?? this.notes,
      photoPath: photoPath ?? this.photoPath,
      observedAt: observedAt ?? this.observedAt,
      farmerUid: farmerUid ?? this.farmerUid,
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
    if (plantInstanceId.present) {
      map['plant_instance_id'] = Variable<String>(plantInstanceId.value);
    }
    if (fieldId.present) {
      map['field_id'] = Variable<String>(fieldId.value);
    }
    if (cropId.present) {
      map['crop_id'] = Variable<String>(cropId.value);
    }
    if (condition.present) {
      map['condition'] = Variable<String>(condition.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
    }
    if (observedAt.present) {
      map['observed_at'] = Variable<DateTime>(observedAt.value);
    }
    if (farmerUid.present) {
      map['farmer_uid'] = Variable<String>(farmerUid.value);
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
    return (StringBuffer('PlantConditionEventsCompanion(')
          ..write('id: $id, ')
          ..write('plantInstanceId: $plantInstanceId, ')
          ..write('fieldId: $fieldId, ')
          ..write('cropId: $cropId, ')
          ..write('condition: $condition, ')
          ..write('sourceType: $sourceType, ')
          ..write('notes: $notes, ')
          ..write('photoPath: $photoPath, ')
          ..write('observedAt: $observedAt, ')
          ..write('farmerUid: $farmerUid, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SoilTestsTable extends SoilTests
    with TableInfo<$SoilTestsTable, SoilTest> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SoilTestsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _farmerUidMeta =
      const VerificationMeta('farmerUid');
  @override
  late final GeneratedColumn<String> farmerUid = GeneratedColumn<String>(
      'farmer_uid', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _fieldIdMeta =
      const VerificationMeta('fieldId');
  @override
  late final GeneratedColumn<String> fieldId = GeneratedColumn<String>(
      'field_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES fields (id)'));
  static const VerificationMeta _sampleLabelMeta =
      const VerificationMeta('sampleLabel');
  @override
  late final GeneratedColumn<String> sampleLabel = GeneratedColumn<String>(
      'sample_label', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _labNameMeta =
      const VerificationMeta('labName');
  @override
  late final GeneratedColumn<String> labName = GeneratedColumn<String>(
      'lab_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sampledAtMeta =
      const VerificationMeta('sampledAt');
  @override
  late final GeneratedColumn<DateTime> sampledAt = GeneratedColumn<DateTime>(
      'sampled_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _phMeta = const VerificationMeta('ph');
  @override
  late final GeneratedColumn<double> ph = GeneratedColumn<double>(
      'ph', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _saltPctMeta =
      const VerificationMeta('saltPct');
  @override
  late final GeneratedColumn<double> saltPct = GeneratedColumn<double>(
      'salt_pct', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _ecDsMMeta = const VerificationMeta('ecDsM');
  @override
  late final GeneratedColumn<double> ecDsM = GeneratedColumn<double>(
      'ec_ds_m', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _limePctMeta =
      const VerificationMeta('limePct');
  @override
  late final GeneratedColumn<double> limePct = GeneratedColumn<double>(
      'lime_pct', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _organicMatterPctMeta =
      const VerificationMeta('organicMatterPct');
  @override
  late final GeneratedColumn<double> organicMatterPct = GeneratedColumn<double>(
      'organic_matter_pct', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _phosphorusKgDaMeta =
      const VerificationMeta('phosphorusKgDa');
  @override
  late final GeneratedColumn<double> phosphorusKgDa = GeneratedColumn<double>(
      'phosphorus_kg_da', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _potassiumKgDaMeta =
      const VerificationMeta('potassiumKgDa');
  @override
  late final GeneratedColumn<double> potassiumKgDa = GeneratedColumn<double>(
      'potassium_kg_da', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _nitrogenPctMeta =
      const VerificationMeta('nitrogenPct');
  @override
  late final GeneratedColumn<double> nitrogenPct = GeneratedColumn<double>(
      'nitrogen_pct', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _saturationPctMeta =
      const VerificationMeta('saturationPct');
  @override
  late final GeneratedColumn<double> saturationPct = GeneratedColumn<double>(
      'saturation_pct', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _textureClassMeta =
      const VerificationMeta('textureClass');
  @override
  late final GeneratedColumn<String> textureClass = GeneratedColumn<String>(
      'texture_class', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sampleLatMeta =
      const VerificationMeta('sampleLat');
  @override
  late final GeneratedColumn<double> sampleLat = GeneratedColumn<double>(
      'sample_lat', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _sampleLngMeta =
      const VerificationMeta('sampleLng');
  @override
  late final GeneratedColumn<double> sampleLng = GeneratedColumn<double>(
      'sample_lng', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
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
        farmerUid,
        fieldId,
        sampleLabel,
        labName,
        sampledAt,
        ph,
        saltPct,
        ecDsM,
        limePct,
        organicMatterPct,
        phosphorusKgDa,
        potassiumKgDa,
        nitrogenPct,
        saturationPct,
        textureClass,
        sampleLat,
        sampleLng,
        notes,
        createdAt,
        updatedAt,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'soil_tests';
  @override
  VerificationContext validateIntegrity(Insertable<SoilTest> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('farmer_uid')) {
      context.handle(_farmerUidMeta,
          farmerUid.isAcceptableOrUnknown(data['farmer_uid']!, _farmerUidMeta));
    }
    if (data.containsKey('field_id')) {
      context.handle(_fieldIdMeta,
          fieldId.isAcceptableOrUnknown(data['field_id']!, _fieldIdMeta));
    } else if (isInserting) {
      context.missing(_fieldIdMeta);
    }
    if (data.containsKey('sample_label')) {
      context.handle(
          _sampleLabelMeta,
          sampleLabel.isAcceptableOrUnknown(
              data['sample_label']!, _sampleLabelMeta));
    }
    if (data.containsKey('lab_name')) {
      context.handle(_labNameMeta,
          labName.isAcceptableOrUnknown(data['lab_name']!, _labNameMeta));
    }
    if (data.containsKey('sampled_at')) {
      context.handle(_sampledAtMeta,
          sampledAt.isAcceptableOrUnknown(data['sampled_at']!, _sampledAtMeta));
    }
    if (data.containsKey('ph')) {
      context.handle(_phMeta, ph.isAcceptableOrUnknown(data['ph']!, _phMeta));
    }
    if (data.containsKey('salt_pct')) {
      context.handle(_saltPctMeta,
          saltPct.isAcceptableOrUnknown(data['salt_pct']!, _saltPctMeta));
    }
    if (data.containsKey('ec_ds_m')) {
      context.handle(_ecDsMMeta,
          ecDsM.isAcceptableOrUnknown(data['ec_ds_m']!, _ecDsMMeta));
    }
    if (data.containsKey('lime_pct')) {
      context.handle(_limePctMeta,
          limePct.isAcceptableOrUnknown(data['lime_pct']!, _limePctMeta));
    }
    if (data.containsKey('organic_matter_pct')) {
      context.handle(
          _organicMatterPctMeta,
          organicMatterPct.isAcceptableOrUnknown(
              data['organic_matter_pct']!, _organicMatterPctMeta));
    }
    if (data.containsKey('phosphorus_kg_da')) {
      context.handle(
          _phosphorusKgDaMeta,
          phosphorusKgDa.isAcceptableOrUnknown(
              data['phosphorus_kg_da']!, _phosphorusKgDaMeta));
    }
    if (data.containsKey('potassium_kg_da')) {
      context.handle(
          _potassiumKgDaMeta,
          potassiumKgDa.isAcceptableOrUnknown(
              data['potassium_kg_da']!, _potassiumKgDaMeta));
    }
    if (data.containsKey('nitrogen_pct')) {
      context.handle(
          _nitrogenPctMeta,
          nitrogenPct.isAcceptableOrUnknown(
              data['nitrogen_pct']!, _nitrogenPctMeta));
    }
    if (data.containsKey('saturation_pct')) {
      context.handle(
          _saturationPctMeta,
          saturationPct.isAcceptableOrUnknown(
              data['saturation_pct']!, _saturationPctMeta));
    }
    if (data.containsKey('texture_class')) {
      context.handle(
          _textureClassMeta,
          textureClass.isAcceptableOrUnknown(
              data['texture_class']!, _textureClassMeta));
    }
    if (data.containsKey('sample_lat')) {
      context.handle(_sampleLatMeta,
          sampleLat.isAcceptableOrUnknown(data['sample_lat']!, _sampleLatMeta));
    }
    if (data.containsKey('sample_lng')) {
      context.handle(_sampleLngMeta,
          sampleLng.isAcceptableOrUnknown(data['sample_lng']!, _sampleLngMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
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
  SoilTest map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SoilTest(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      farmerUid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}farmer_uid']),
      fieldId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}field_id'])!,
      sampleLabel: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sample_label']),
      labName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lab_name']),
      sampledAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}sampled_at']),
      ph: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}ph']),
      saltPct: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}salt_pct']),
      ecDsM: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}ec_ds_m']),
      limePct: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}lime_pct']),
      organicMatterPct: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}organic_matter_pct']),
      phosphorusKgDa: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}phosphorus_kg_da']),
      potassiumKgDa: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}potassium_kg_da']),
      nitrogenPct: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}nitrogen_pct']),
      saturationPct: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}saturation_pct']),
      textureClass: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}texture_class']),
      sampleLat: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}sample_lat']),
      sampleLng: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}sample_lng']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $SoilTestsTable createAlias(String alias) {
    return $SoilTestsTable(attachedDatabase, alias);
  }
}

class SoilTest extends DataClass implements Insertable<SoilTest> {
  final String id;
  final String? farmerUid;
  final String fieldId;

  /// Örneğin alındığı tarla kısmı (serbest metin).
  final String? sampleLabel;

  /// Analizi yapan laboratuvar/kurum adı.
  final String? labName;

  /// Örneğin alındığı/analiz tarihi.
  final DateTime? sampledAt;
  final double? ph;

  /// % toplam tuz (satüre çamur).
  final double? saltPct;

  /// EC — elektriksel iletkenlik (dS/m).
  final double? ecDsM;

  /// Kireç CaCO₃ %.
  final double? limePct;

  /// Organik madde %.
  final double? organicMatterPct;

  /// Fosfor P₂O₅ kg/dekar.
  final double? phosphorusKgDa;

  /// Potasyum K₂O kg/dekar.
  final double? potassiumKgDa;

  /// Toplam azot %.
  final double? nitrogenPct;

  /// Suyla doygunluk %.
  final double? saturationPct;

  /// Doku sınıfı (girilen veya doygunluktan türetilen).
  final String? textureClass;

  /// Örneğin haritadan seçilen noktası (tarla içi). null → harita seçimi yok.
  final double? sampleLat;
  final double? sampleLng;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const SoilTest(
      {required this.id,
      this.farmerUid,
      required this.fieldId,
      this.sampleLabel,
      this.labName,
      this.sampledAt,
      this.ph,
      this.saltPct,
      this.ecDsM,
      this.limePct,
      this.organicMatterPct,
      this.phosphorusKgDa,
      this.potassiumKgDa,
      this.nitrogenPct,
      this.saturationPct,
      this.textureClass,
      this.sampleLat,
      this.sampleLng,
      this.notes,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || farmerUid != null) {
      map['farmer_uid'] = Variable<String>(farmerUid);
    }
    map['field_id'] = Variable<String>(fieldId);
    if (!nullToAbsent || sampleLabel != null) {
      map['sample_label'] = Variable<String>(sampleLabel);
    }
    if (!nullToAbsent || labName != null) {
      map['lab_name'] = Variable<String>(labName);
    }
    if (!nullToAbsent || sampledAt != null) {
      map['sampled_at'] = Variable<DateTime>(sampledAt);
    }
    if (!nullToAbsent || ph != null) {
      map['ph'] = Variable<double>(ph);
    }
    if (!nullToAbsent || saltPct != null) {
      map['salt_pct'] = Variable<double>(saltPct);
    }
    if (!nullToAbsent || ecDsM != null) {
      map['ec_ds_m'] = Variable<double>(ecDsM);
    }
    if (!nullToAbsent || limePct != null) {
      map['lime_pct'] = Variable<double>(limePct);
    }
    if (!nullToAbsent || organicMatterPct != null) {
      map['organic_matter_pct'] = Variable<double>(organicMatterPct);
    }
    if (!nullToAbsent || phosphorusKgDa != null) {
      map['phosphorus_kg_da'] = Variable<double>(phosphorusKgDa);
    }
    if (!nullToAbsent || potassiumKgDa != null) {
      map['potassium_kg_da'] = Variable<double>(potassiumKgDa);
    }
    if (!nullToAbsent || nitrogenPct != null) {
      map['nitrogen_pct'] = Variable<double>(nitrogenPct);
    }
    if (!nullToAbsent || saturationPct != null) {
      map['saturation_pct'] = Variable<double>(saturationPct);
    }
    if (!nullToAbsent || textureClass != null) {
      map['texture_class'] = Variable<String>(textureClass);
    }
    if (!nullToAbsent || sampleLat != null) {
      map['sample_lat'] = Variable<double>(sampleLat);
    }
    if (!nullToAbsent || sampleLng != null) {
      map['sample_lng'] = Variable<double>(sampleLng);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  SoilTestsCompanion toCompanion(bool nullToAbsent) {
    return SoilTestsCompanion(
      id: Value(id),
      farmerUid: farmerUid == null && nullToAbsent
          ? const Value.absent()
          : Value(farmerUid),
      fieldId: Value(fieldId),
      sampleLabel: sampleLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(sampleLabel),
      labName: labName == null && nullToAbsent
          ? const Value.absent()
          : Value(labName),
      sampledAt: sampledAt == null && nullToAbsent
          ? const Value.absent()
          : Value(sampledAt),
      ph: ph == null && nullToAbsent ? const Value.absent() : Value(ph),
      saltPct: saltPct == null && nullToAbsent
          ? const Value.absent()
          : Value(saltPct),
      ecDsM:
          ecDsM == null && nullToAbsent ? const Value.absent() : Value(ecDsM),
      limePct: limePct == null && nullToAbsent
          ? const Value.absent()
          : Value(limePct),
      organicMatterPct: organicMatterPct == null && nullToAbsent
          ? const Value.absent()
          : Value(organicMatterPct),
      phosphorusKgDa: phosphorusKgDa == null && nullToAbsent
          ? const Value.absent()
          : Value(phosphorusKgDa),
      potassiumKgDa: potassiumKgDa == null && nullToAbsent
          ? const Value.absent()
          : Value(potassiumKgDa),
      nitrogenPct: nitrogenPct == null && nullToAbsent
          ? const Value.absent()
          : Value(nitrogenPct),
      saturationPct: saturationPct == null && nullToAbsent
          ? const Value.absent()
          : Value(saturationPct),
      textureClass: textureClass == null && nullToAbsent
          ? const Value.absent()
          : Value(textureClass),
      sampleLat: sampleLat == null && nullToAbsent
          ? const Value.absent()
          : Value(sampleLat),
      sampleLng: sampleLng == null && nullToAbsent
          ? const Value.absent()
          : Value(sampleLng),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory SoilTest.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SoilTest(
      id: serializer.fromJson<String>(json['id']),
      farmerUid: serializer.fromJson<String?>(json['farmerUid']),
      fieldId: serializer.fromJson<String>(json['fieldId']),
      sampleLabel: serializer.fromJson<String?>(json['sampleLabel']),
      labName: serializer.fromJson<String?>(json['labName']),
      sampledAt: serializer.fromJson<DateTime?>(json['sampledAt']),
      ph: serializer.fromJson<double?>(json['ph']),
      saltPct: serializer.fromJson<double?>(json['saltPct']),
      ecDsM: serializer.fromJson<double?>(json['ecDsM']),
      limePct: serializer.fromJson<double?>(json['limePct']),
      organicMatterPct: serializer.fromJson<double?>(json['organicMatterPct']),
      phosphorusKgDa: serializer.fromJson<double?>(json['phosphorusKgDa']),
      potassiumKgDa: serializer.fromJson<double?>(json['potassiumKgDa']),
      nitrogenPct: serializer.fromJson<double?>(json['nitrogenPct']),
      saturationPct: serializer.fromJson<double?>(json['saturationPct']),
      textureClass: serializer.fromJson<String?>(json['textureClass']),
      sampleLat: serializer.fromJson<double?>(json['sampleLat']),
      sampleLng: serializer.fromJson<double?>(json['sampleLng']),
      notes: serializer.fromJson<String?>(json['notes']),
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
      'farmerUid': serializer.toJson<String?>(farmerUid),
      'fieldId': serializer.toJson<String>(fieldId),
      'sampleLabel': serializer.toJson<String?>(sampleLabel),
      'labName': serializer.toJson<String?>(labName),
      'sampledAt': serializer.toJson<DateTime?>(sampledAt),
      'ph': serializer.toJson<double?>(ph),
      'saltPct': serializer.toJson<double?>(saltPct),
      'ecDsM': serializer.toJson<double?>(ecDsM),
      'limePct': serializer.toJson<double?>(limePct),
      'organicMatterPct': serializer.toJson<double?>(organicMatterPct),
      'phosphorusKgDa': serializer.toJson<double?>(phosphorusKgDa),
      'potassiumKgDa': serializer.toJson<double?>(potassiumKgDa),
      'nitrogenPct': serializer.toJson<double?>(nitrogenPct),
      'saturationPct': serializer.toJson<double?>(saturationPct),
      'textureClass': serializer.toJson<String?>(textureClass),
      'sampleLat': serializer.toJson<double?>(sampleLat),
      'sampleLng': serializer.toJson<double?>(sampleLng),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  SoilTest copyWith(
          {String? id,
          Value<String?> farmerUid = const Value.absent(),
          String? fieldId,
          Value<String?> sampleLabel = const Value.absent(),
          Value<String?> labName = const Value.absent(),
          Value<DateTime?> sampledAt = const Value.absent(),
          Value<double?> ph = const Value.absent(),
          Value<double?> saltPct = const Value.absent(),
          Value<double?> ecDsM = const Value.absent(),
          Value<double?> limePct = const Value.absent(),
          Value<double?> organicMatterPct = const Value.absent(),
          Value<double?> phosphorusKgDa = const Value.absent(),
          Value<double?> potassiumKgDa = const Value.absent(),
          Value<double?> nitrogenPct = const Value.absent(),
          Value<double?> saturationPct = const Value.absent(),
          Value<String?> textureClass = const Value.absent(),
          Value<double?> sampleLat = const Value.absent(),
          Value<double?> sampleLng = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent()}) =>
      SoilTest(
        id: id ?? this.id,
        farmerUid: farmerUid.present ? farmerUid.value : this.farmerUid,
        fieldId: fieldId ?? this.fieldId,
        sampleLabel: sampleLabel.present ? sampleLabel.value : this.sampleLabel,
        labName: labName.present ? labName.value : this.labName,
        sampledAt: sampledAt.present ? sampledAt.value : this.sampledAt,
        ph: ph.present ? ph.value : this.ph,
        saltPct: saltPct.present ? saltPct.value : this.saltPct,
        ecDsM: ecDsM.present ? ecDsM.value : this.ecDsM,
        limePct: limePct.present ? limePct.value : this.limePct,
        organicMatterPct: organicMatterPct.present
            ? organicMatterPct.value
            : this.organicMatterPct,
        phosphorusKgDa:
            phosphorusKgDa.present ? phosphorusKgDa.value : this.phosphorusKgDa,
        potassiumKgDa:
            potassiumKgDa.present ? potassiumKgDa.value : this.potassiumKgDa,
        nitrogenPct: nitrogenPct.present ? nitrogenPct.value : this.nitrogenPct,
        saturationPct:
            saturationPct.present ? saturationPct.value : this.saturationPct,
        textureClass:
            textureClass.present ? textureClass.value : this.textureClass,
        sampleLat: sampleLat.present ? sampleLat.value : this.sampleLat,
        sampleLng: sampleLng.present ? sampleLng.value : this.sampleLng,
        notes: notes.present ? notes.value : this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  SoilTest copyWithCompanion(SoilTestsCompanion data) {
    return SoilTest(
      id: data.id.present ? data.id.value : this.id,
      farmerUid: data.farmerUid.present ? data.farmerUid.value : this.farmerUid,
      fieldId: data.fieldId.present ? data.fieldId.value : this.fieldId,
      sampleLabel:
          data.sampleLabel.present ? data.sampleLabel.value : this.sampleLabel,
      labName: data.labName.present ? data.labName.value : this.labName,
      sampledAt: data.sampledAt.present ? data.sampledAt.value : this.sampledAt,
      ph: data.ph.present ? data.ph.value : this.ph,
      saltPct: data.saltPct.present ? data.saltPct.value : this.saltPct,
      ecDsM: data.ecDsM.present ? data.ecDsM.value : this.ecDsM,
      limePct: data.limePct.present ? data.limePct.value : this.limePct,
      organicMatterPct: data.organicMatterPct.present
          ? data.organicMatterPct.value
          : this.organicMatterPct,
      phosphorusKgDa: data.phosphorusKgDa.present
          ? data.phosphorusKgDa.value
          : this.phosphorusKgDa,
      potassiumKgDa: data.potassiumKgDa.present
          ? data.potassiumKgDa.value
          : this.potassiumKgDa,
      nitrogenPct:
          data.nitrogenPct.present ? data.nitrogenPct.value : this.nitrogenPct,
      saturationPct: data.saturationPct.present
          ? data.saturationPct.value
          : this.saturationPct,
      textureClass: data.textureClass.present
          ? data.textureClass.value
          : this.textureClass,
      sampleLat: data.sampleLat.present ? data.sampleLat.value : this.sampleLat,
      sampleLng: data.sampleLng.present ? data.sampleLng.value : this.sampleLng,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SoilTest(')
          ..write('id: $id, ')
          ..write('farmerUid: $farmerUid, ')
          ..write('fieldId: $fieldId, ')
          ..write('sampleLabel: $sampleLabel, ')
          ..write('labName: $labName, ')
          ..write('sampledAt: $sampledAt, ')
          ..write('ph: $ph, ')
          ..write('saltPct: $saltPct, ')
          ..write('ecDsM: $ecDsM, ')
          ..write('limePct: $limePct, ')
          ..write('organicMatterPct: $organicMatterPct, ')
          ..write('phosphorusKgDa: $phosphorusKgDa, ')
          ..write('potassiumKgDa: $potassiumKgDa, ')
          ..write('nitrogenPct: $nitrogenPct, ')
          ..write('saturationPct: $saturationPct, ')
          ..write('textureClass: $textureClass, ')
          ..write('sampleLat: $sampleLat, ')
          ..write('sampleLng: $sampleLng, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        farmerUid,
        fieldId,
        sampleLabel,
        labName,
        sampledAt,
        ph,
        saltPct,
        ecDsM,
        limePct,
        organicMatterPct,
        phosphorusKgDa,
        potassiumKgDa,
        nitrogenPct,
        saturationPct,
        textureClass,
        sampleLat,
        sampleLng,
        notes,
        createdAt,
        updatedAt,
        deletedAt
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SoilTest &&
          other.id == this.id &&
          other.farmerUid == this.farmerUid &&
          other.fieldId == this.fieldId &&
          other.sampleLabel == this.sampleLabel &&
          other.labName == this.labName &&
          other.sampledAt == this.sampledAt &&
          other.ph == this.ph &&
          other.saltPct == this.saltPct &&
          other.ecDsM == this.ecDsM &&
          other.limePct == this.limePct &&
          other.organicMatterPct == this.organicMatterPct &&
          other.phosphorusKgDa == this.phosphorusKgDa &&
          other.potassiumKgDa == this.potassiumKgDa &&
          other.nitrogenPct == this.nitrogenPct &&
          other.saturationPct == this.saturationPct &&
          other.textureClass == this.textureClass &&
          other.sampleLat == this.sampleLat &&
          other.sampleLng == this.sampleLng &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class SoilTestsCompanion extends UpdateCompanion<SoilTest> {
  final Value<String> id;
  final Value<String?> farmerUid;
  final Value<String> fieldId;
  final Value<String?> sampleLabel;
  final Value<String?> labName;
  final Value<DateTime?> sampledAt;
  final Value<double?> ph;
  final Value<double?> saltPct;
  final Value<double?> ecDsM;
  final Value<double?> limePct;
  final Value<double?> organicMatterPct;
  final Value<double?> phosphorusKgDa;
  final Value<double?> potassiumKgDa;
  final Value<double?> nitrogenPct;
  final Value<double?> saturationPct;
  final Value<String?> textureClass;
  final Value<double?> sampleLat;
  final Value<double?> sampleLng;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const SoilTestsCompanion({
    this.id = const Value.absent(),
    this.farmerUid = const Value.absent(),
    this.fieldId = const Value.absent(),
    this.sampleLabel = const Value.absent(),
    this.labName = const Value.absent(),
    this.sampledAt = const Value.absent(),
    this.ph = const Value.absent(),
    this.saltPct = const Value.absent(),
    this.ecDsM = const Value.absent(),
    this.limePct = const Value.absent(),
    this.organicMatterPct = const Value.absent(),
    this.phosphorusKgDa = const Value.absent(),
    this.potassiumKgDa = const Value.absent(),
    this.nitrogenPct = const Value.absent(),
    this.saturationPct = const Value.absent(),
    this.textureClass = const Value.absent(),
    this.sampleLat = const Value.absent(),
    this.sampleLng = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SoilTestsCompanion.insert({
    required String id,
    this.farmerUid = const Value.absent(),
    required String fieldId,
    this.sampleLabel = const Value.absent(),
    this.labName = const Value.absent(),
    this.sampledAt = const Value.absent(),
    this.ph = const Value.absent(),
    this.saltPct = const Value.absent(),
    this.ecDsM = const Value.absent(),
    this.limePct = const Value.absent(),
    this.organicMatterPct = const Value.absent(),
    this.phosphorusKgDa = const Value.absent(),
    this.potassiumKgDa = const Value.absent(),
    this.nitrogenPct = const Value.absent(),
    this.saturationPct = const Value.absent(),
    this.textureClass = const Value.absent(),
    this.sampleLat = const Value.absent(),
    this.sampleLng = const Value.absent(),
    this.notes = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        fieldId = Value(fieldId),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<SoilTest> custom({
    Expression<String>? id,
    Expression<String>? farmerUid,
    Expression<String>? fieldId,
    Expression<String>? sampleLabel,
    Expression<String>? labName,
    Expression<DateTime>? sampledAt,
    Expression<double>? ph,
    Expression<double>? saltPct,
    Expression<double>? ecDsM,
    Expression<double>? limePct,
    Expression<double>? organicMatterPct,
    Expression<double>? phosphorusKgDa,
    Expression<double>? potassiumKgDa,
    Expression<double>? nitrogenPct,
    Expression<double>? saturationPct,
    Expression<String>? textureClass,
    Expression<double>? sampleLat,
    Expression<double>? sampleLng,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (farmerUid != null) 'farmer_uid': farmerUid,
      if (fieldId != null) 'field_id': fieldId,
      if (sampleLabel != null) 'sample_label': sampleLabel,
      if (labName != null) 'lab_name': labName,
      if (sampledAt != null) 'sampled_at': sampledAt,
      if (ph != null) 'ph': ph,
      if (saltPct != null) 'salt_pct': saltPct,
      if (ecDsM != null) 'ec_ds_m': ecDsM,
      if (limePct != null) 'lime_pct': limePct,
      if (organicMatterPct != null) 'organic_matter_pct': organicMatterPct,
      if (phosphorusKgDa != null) 'phosphorus_kg_da': phosphorusKgDa,
      if (potassiumKgDa != null) 'potassium_kg_da': potassiumKgDa,
      if (nitrogenPct != null) 'nitrogen_pct': nitrogenPct,
      if (saturationPct != null) 'saturation_pct': saturationPct,
      if (textureClass != null) 'texture_class': textureClass,
      if (sampleLat != null) 'sample_lat': sampleLat,
      if (sampleLng != null) 'sample_lng': sampleLng,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SoilTestsCompanion copyWith(
      {Value<String>? id,
      Value<String?>? farmerUid,
      Value<String>? fieldId,
      Value<String?>? sampleLabel,
      Value<String?>? labName,
      Value<DateTime?>? sampledAt,
      Value<double?>? ph,
      Value<double?>? saltPct,
      Value<double?>? ecDsM,
      Value<double?>? limePct,
      Value<double?>? organicMatterPct,
      Value<double?>? phosphorusKgDa,
      Value<double?>? potassiumKgDa,
      Value<double?>? nitrogenPct,
      Value<double?>? saturationPct,
      Value<String?>? textureClass,
      Value<double?>? sampleLat,
      Value<double?>? sampleLng,
      Value<String?>? notes,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<int>? rowid}) {
    return SoilTestsCompanion(
      id: id ?? this.id,
      farmerUid: farmerUid ?? this.farmerUid,
      fieldId: fieldId ?? this.fieldId,
      sampleLabel: sampleLabel ?? this.sampleLabel,
      labName: labName ?? this.labName,
      sampledAt: sampledAt ?? this.sampledAt,
      ph: ph ?? this.ph,
      saltPct: saltPct ?? this.saltPct,
      ecDsM: ecDsM ?? this.ecDsM,
      limePct: limePct ?? this.limePct,
      organicMatterPct: organicMatterPct ?? this.organicMatterPct,
      phosphorusKgDa: phosphorusKgDa ?? this.phosphorusKgDa,
      potassiumKgDa: potassiumKgDa ?? this.potassiumKgDa,
      nitrogenPct: nitrogenPct ?? this.nitrogenPct,
      saturationPct: saturationPct ?? this.saturationPct,
      textureClass: textureClass ?? this.textureClass,
      sampleLat: sampleLat ?? this.sampleLat,
      sampleLng: sampleLng ?? this.sampleLng,
      notes: notes ?? this.notes,
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
    if (farmerUid.present) {
      map['farmer_uid'] = Variable<String>(farmerUid.value);
    }
    if (fieldId.present) {
      map['field_id'] = Variable<String>(fieldId.value);
    }
    if (sampleLabel.present) {
      map['sample_label'] = Variable<String>(sampleLabel.value);
    }
    if (labName.present) {
      map['lab_name'] = Variable<String>(labName.value);
    }
    if (sampledAt.present) {
      map['sampled_at'] = Variable<DateTime>(sampledAt.value);
    }
    if (ph.present) {
      map['ph'] = Variable<double>(ph.value);
    }
    if (saltPct.present) {
      map['salt_pct'] = Variable<double>(saltPct.value);
    }
    if (ecDsM.present) {
      map['ec_ds_m'] = Variable<double>(ecDsM.value);
    }
    if (limePct.present) {
      map['lime_pct'] = Variable<double>(limePct.value);
    }
    if (organicMatterPct.present) {
      map['organic_matter_pct'] = Variable<double>(organicMatterPct.value);
    }
    if (phosphorusKgDa.present) {
      map['phosphorus_kg_da'] = Variable<double>(phosphorusKgDa.value);
    }
    if (potassiumKgDa.present) {
      map['potassium_kg_da'] = Variable<double>(potassiumKgDa.value);
    }
    if (nitrogenPct.present) {
      map['nitrogen_pct'] = Variable<double>(nitrogenPct.value);
    }
    if (saturationPct.present) {
      map['saturation_pct'] = Variable<double>(saturationPct.value);
    }
    if (textureClass.present) {
      map['texture_class'] = Variable<String>(textureClass.value);
    }
    if (sampleLat.present) {
      map['sample_lat'] = Variable<double>(sampleLat.value);
    }
    if (sampleLng.present) {
      map['sample_lng'] = Variable<double>(sampleLng.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
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
    return (StringBuffer('SoilTestsCompanion(')
          ..write('id: $id, ')
          ..write('farmerUid: $farmerUid, ')
          ..write('fieldId: $fieldId, ')
          ..write('sampleLabel: $sampleLabel, ')
          ..write('labName: $labName, ')
          ..write('sampledAt: $sampledAt, ')
          ..write('ph: $ph, ')
          ..write('saltPct: $saltPct, ')
          ..write('ecDsM: $ecDsM, ')
          ..write('limePct: $limePct, ')
          ..write('organicMatterPct: $organicMatterPct, ')
          ..write('phosphorusKgDa: $phosphorusKgDa, ')
          ..write('potassiumKgDa: $potassiumKgDa, ')
          ..write('nitrogenPct: $nitrogenPct, ')
          ..write('saturationPct: $saturationPct, ')
          ..write('textureClass: $textureClass, ')
          ..write('sampleLat: $sampleLat, ')
          ..write('sampleLng: $sampleLng, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
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
  late final $CropGrowthStatesTable cropGrowthStates =
      $CropGrowthStatesTable(this);
  late final $FieldPlantInstancesTable fieldPlantInstances =
      $FieldPlantInstancesTable(this);
  late final $PlantConditionEventsTable plantConditionEvents =
      $PlantConditionEventsTable(this);
  late final $SoilTestsTable soilTests = $SoilTestsTable(this);
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
        syncState,
        cropGrowthStates,
        fieldPlantInstances,
        plantConditionEvents,
        soilTests
      ];
}

typedef $$FieldsTableCreateCompanionBuilder = FieldsCompanion Function({
  required String id,
  Value<String?> farmerUid,
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
  Value<String?> farmerUid,
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

  static MultiTypedResultKey<$FieldPlantInstancesTable,
      List<FieldPlantInstance>> _fieldPlantInstancesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.fieldPlantInstances,
          aliasName: $_aliasNameGenerator(
              db.fields.id, db.fieldPlantInstances.fieldId));

  $$FieldPlantInstancesTableProcessedTableManager get fieldPlantInstancesRefs {
    final manager =
        $$FieldPlantInstancesTableTableManager($_db, $_db.fieldPlantInstances)
            .filter((f) => f.fieldId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_fieldPlantInstancesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$SoilTestsTable, List<SoilTest>>
      _soilTestsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.soilTests,
          aliasName: $_aliasNameGenerator(db.fields.id, db.soilTests.fieldId));

  $$SoilTestsTableProcessedTableManager get soilTestsRefs {
    final manager = $$SoilTestsTableTableManager($_db, $_db.soilTests)
        .filter((f) => f.fieldId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_soilTestsRefsTable($_db));
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

  ColumnFilters<String> get farmerUid => $composableBuilder(
      column: $table.farmerUid, builder: (column) => ColumnFilters(column));

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

  Expression<bool> fieldPlantInstancesRefs(
      Expression<bool> Function($$FieldPlantInstancesTableFilterComposer f) f) {
    final $$FieldPlantInstancesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.fieldPlantInstances,
        getReferencedColumn: (t) => t.fieldId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FieldPlantInstancesTableFilterComposer(
              $db: $db,
              $table: $db.fieldPlantInstances,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> soilTestsRefs(
      Expression<bool> Function($$SoilTestsTableFilterComposer f) f) {
    final $$SoilTestsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.soilTests,
        getReferencedColumn: (t) => t.fieldId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SoilTestsTableFilterComposer(
              $db: $db,
              $table: $db.soilTests,
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

  ColumnOrderings<String> get farmerUid => $composableBuilder(
      column: $table.farmerUid, builder: (column) => ColumnOrderings(column));

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

  GeneratedColumn<String> get farmerUid =>
      $composableBuilder(column: $table.farmerUid, builder: (column) => column);

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

  Expression<T> fieldPlantInstancesRefs<T extends Object>(
      Expression<T> Function($$FieldPlantInstancesTableAnnotationComposer a)
          f) {
    final $$FieldPlantInstancesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.fieldPlantInstances,
            getReferencedColumn: (t) => t.fieldId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$FieldPlantInstancesTableAnnotationComposer(
                  $db: $db,
                  $table: $db.fieldPlantInstances,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> soilTestsRefs<T extends Object>(
      Expression<T> Function($$SoilTestsTableAnnotationComposer a) f) {
    final $$SoilTestsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.soilTests,
        getReferencedColumn: (t) => t.fieldId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SoilTestsTableAnnotationComposer(
              $db: $db,
              $table: $db.soilTests,
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
        bool suitabilityReportsRefs,
        bool fieldPlantInstancesRefs,
        bool soilTestsRefs})> {
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
            Value<String?> farmerUid = const Value.absent(),
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
            farmerUid: farmerUid,
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
            Value<String?> farmerUid = const Value.absent(),
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
            farmerUid: farmerUid,
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
              suitabilityReportsRefs = false,
              fieldPlantInstancesRefs = false,
              soilTestsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (fieldCropsRefs) db.fieldCrops,
                if (calendarEventsRefs) db.calendarEvents,
                if (irrigationPlansRefs) db.irrigationPlans,
                if (suitabilityReportsRefs) db.suitabilityReports,
                if (fieldPlantInstancesRefs) db.fieldPlantInstances,
                if (soilTestsRefs) db.soilTests
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
                        typedResults: items),
                  if (fieldPlantInstancesRefs)
                    await $_getPrefetchedData<Field, $FieldsTable,
                            FieldPlantInstance>(
                        currentTable: table,
                        referencedTable: $$FieldsTableReferences
                            ._fieldPlantInstancesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$FieldsTableReferences(db, table, p0)
                                .fieldPlantInstancesRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.fieldId == item.id),
                        typedResults: items),
                  if (soilTestsRefs)
                    await $_getPrefetchedData<Field, $FieldsTable, SoilTest>(
                        currentTable: table,
                        referencedTable:
                            $$FieldsTableReferences._soilTestsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$FieldsTableReferences(db, table, p0)
                                .soilTestsRefs,
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
        bool suitabilityReportsRefs,
        bool fieldPlantInstancesRefs,
        bool soilTestsRefs})>;
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
  Value<String?> zonePolygonJson,
  Value<String?> facingDirection,
  Value<bool?> isSeedling,
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
  Value<String?> zonePolygonJson,
  Value<String?> facingDirection,
  Value<bool?> isSeedling,
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

  static MultiTypedResultKey<$FieldPlantInstancesTable,
      List<FieldPlantInstance>> _fieldPlantInstancesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.fieldPlantInstances,
          aliasName: $_aliasNameGenerator(
              db.fieldCrops.id, db.fieldPlantInstances.cropId));

  $$FieldPlantInstancesTableProcessedTableManager get fieldPlantInstancesRefs {
    final manager =
        $$FieldPlantInstancesTableTableManager($_db, $_db.fieldPlantInstances)
            .filter((f) => f.cropId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_fieldPlantInstancesRefsTable($_db));
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

  ColumnFilters<String> get zonePolygonJson => $composableBuilder(
      column: $table.zonePolygonJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get facingDirection => $composableBuilder(
      column: $table.facingDirection,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSeedling => $composableBuilder(
      column: $table.isSeedling, builder: (column) => ColumnFilters(column));

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

  Expression<bool> fieldPlantInstancesRefs(
      Expression<bool> Function($$FieldPlantInstancesTableFilterComposer f) f) {
    final $$FieldPlantInstancesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.fieldPlantInstances,
        getReferencedColumn: (t) => t.cropId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FieldPlantInstancesTableFilterComposer(
              $db: $db,
              $table: $db.fieldPlantInstances,
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

  ColumnOrderings<String> get zonePolygonJson => $composableBuilder(
      column: $table.zonePolygonJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get facingDirection => $composableBuilder(
      column: $table.facingDirection,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSeedling => $composableBuilder(
      column: $table.isSeedling, builder: (column) => ColumnOrderings(column));

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

  GeneratedColumn<String> get zonePolygonJson => $composableBuilder(
      column: $table.zonePolygonJson, builder: (column) => column);

  GeneratedColumn<String> get facingDirection => $composableBuilder(
      column: $table.facingDirection, builder: (column) => column);

  GeneratedColumn<bool> get isSeedling => $composableBuilder(
      column: $table.isSeedling, builder: (column) => column);

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

  Expression<T> fieldPlantInstancesRefs<T extends Object>(
      Expression<T> Function($$FieldPlantInstancesTableAnnotationComposer a)
          f) {
    final $$FieldPlantInstancesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.fieldPlantInstances,
            getReferencedColumn: (t) => t.cropId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$FieldPlantInstancesTableAnnotationComposer(
                  $db: $db,
                  $table: $db.fieldPlantInstances,
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
        {bool fieldId,
        bool calendarEventsRefs,
        bool irrigationPlansRefs,
        bool fieldPlantInstancesRefs})> {
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
            Value<String?> zonePolygonJson = const Value.absent(),
            Value<String?> facingDirection = const Value.absent(),
            Value<bool?> isSeedling = const Value.absent(),
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
            zonePolygonJson: zonePolygonJson,
            facingDirection: facingDirection,
            isSeedling: isSeedling,
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
            Value<String?> zonePolygonJson = const Value.absent(),
            Value<String?> facingDirection = const Value.absent(),
            Value<bool?> isSeedling = const Value.absent(),
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
            zonePolygonJson: zonePolygonJson,
            facingDirection: facingDirection,
            isSeedling: isSeedling,
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
              irrigationPlansRefs = false,
              fieldPlantInstancesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (calendarEventsRefs) db.calendarEvents,
                if (irrigationPlansRefs) db.irrigationPlans,
                if (fieldPlantInstancesRefs) db.fieldPlantInstances
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
                        typedResults: items),
                  if (fieldPlantInstancesRefs)
                    await $_getPrefetchedData<FieldCrop, $FieldCropsTable,
                            FieldPlantInstance>(
                        currentTable: table,
                        referencedTable: $$FieldCropsTableReferences
                            ._fieldPlantInstancesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$FieldCropsTableReferences(db, table, p0)
                                .fieldPlantInstancesRefs,
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
        {bool fieldId,
        bool calendarEventsRefs,
        bool irrigationPlansRefs,
        bool fieldPlantInstancesRefs})>;
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
  Value<double?> quantity,
  Value<String?> unit,
  Value<double?> recommendedQuantity,
  Value<String?> targetScope,
  Value<String?> plantInstanceId,
  Value<String?> subtype,
  Value<String?> photoPath,
  Value<String?> noteText,
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
  Value<double?> quantity,
  Value<String?> unit,
  Value<double?> recommendedQuantity,
  Value<String?> targetScope,
  Value<String?> plantInstanceId,
  Value<String?> subtype,
  Value<String?> photoPath,
  Value<String?> noteText,
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

  ColumnFilters<double> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get recommendedQuantity => $composableBuilder(
      column: $table.recommendedQuantity,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get targetScope => $composableBuilder(
      column: $table.targetScope, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get plantInstanceId => $composableBuilder(
      column: $table.plantInstanceId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subtype => $composableBuilder(
      column: $table.subtype, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get photoPath => $composableBuilder(
      column: $table.photoPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get noteText => $composableBuilder(
      column: $table.noteText, builder: (column) => ColumnFilters(column));

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

  ColumnOrderings<double> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get recommendedQuantity => $composableBuilder(
      column: $table.recommendedQuantity,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get targetScope => $composableBuilder(
      column: $table.targetScope, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get plantInstanceId => $composableBuilder(
      column: $table.plantInstanceId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subtype => $composableBuilder(
      column: $table.subtype, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get photoPath => $composableBuilder(
      column: $table.photoPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get noteText => $composableBuilder(
      column: $table.noteText, builder: (column) => ColumnOrderings(column));

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

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<double> get recommendedQuantity => $composableBuilder(
      column: $table.recommendedQuantity, builder: (column) => column);

  GeneratedColumn<String> get targetScope => $composableBuilder(
      column: $table.targetScope, builder: (column) => column);

  GeneratedColumn<String> get plantInstanceId => $composableBuilder(
      column: $table.plantInstanceId, builder: (column) => column);

  GeneratedColumn<String> get subtype =>
      $composableBuilder(column: $table.subtype, builder: (column) => column);

  GeneratedColumn<String> get photoPath =>
      $composableBuilder(column: $table.photoPath, builder: (column) => column);

  GeneratedColumn<String> get noteText =>
      $composableBuilder(column: $table.noteText, builder: (column) => column);

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
            Value<double?> quantity = const Value.absent(),
            Value<String?> unit = const Value.absent(),
            Value<double?> recommendedQuantity = const Value.absent(),
            Value<String?> targetScope = const Value.absent(),
            Value<String?> plantInstanceId = const Value.absent(),
            Value<String?> subtype = const Value.absent(),
            Value<String?> photoPath = const Value.absent(),
            Value<String?> noteText = const Value.absent(),
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
            quantity: quantity,
            unit: unit,
            recommendedQuantity: recommendedQuantity,
            targetScope: targetScope,
            plantInstanceId: plantInstanceId,
            subtype: subtype,
            photoPath: photoPath,
            noteText: noteText,
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
            Value<double?> quantity = const Value.absent(),
            Value<String?> unit = const Value.absent(),
            Value<double?> recommendedQuantity = const Value.absent(),
            Value<String?> targetScope = const Value.absent(),
            Value<String?> plantInstanceId = const Value.absent(),
            Value<String?> subtype = const Value.absent(),
            Value<String?> photoPath = const Value.absent(),
            Value<String?> noteText = const Value.absent(),
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
            quantity: quantity,
            unit: unit,
            recommendedQuantity: recommendedQuantity,
            targetScope: targetScope,
            plantInstanceId: plantInstanceId,
            subtype: subtype,
            photoPath: photoPath,
            noteText: noteText,
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
typedef $$CropGrowthStatesTableCreateCompanionBuilder
    = CropGrowthStatesCompanion Function({
  required String cropId,
  required String fieldId,
  required DateTime asOfDate,
  Value<double> accumulatedGdd,
  Value<String> currentStageKey,
  Value<double> stageProgress,
  Value<double> waterDeficitMm,
  Value<double> nStressIdx,
  Value<double> kStressIdx,
  Value<double> diseasePressure,
  Value<double> heightCm,
  Value<double> biomassRel,
  Value<double> yieldMultiplier,
  required DateTime lastComputedAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$CropGrowthStatesTableUpdateCompanionBuilder
    = CropGrowthStatesCompanion Function({
  Value<String> cropId,
  Value<String> fieldId,
  Value<DateTime> asOfDate,
  Value<double> accumulatedGdd,
  Value<String> currentStageKey,
  Value<double> stageProgress,
  Value<double> waterDeficitMm,
  Value<double> nStressIdx,
  Value<double> kStressIdx,
  Value<double> diseasePressure,
  Value<double> heightCm,
  Value<double> biomassRel,
  Value<double> yieldMultiplier,
  Value<DateTime> lastComputedAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$CropGrowthStatesTableFilterComposer
    extends Composer<_$AppDatabase, $CropGrowthStatesTable> {
  $$CropGrowthStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get cropId => $composableBuilder(
      column: $table.cropId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fieldId => $composableBuilder(
      column: $table.fieldId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get asOfDate => $composableBuilder(
      column: $table.asOfDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get accumulatedGdd => $composableBuilder(
      column: $table.accumulatedGdd,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currentStageKey => $composableBuilder(
      column: $table.currentStageKey,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get stageProgress => $composableBuilder(
      column: $table.stageProgress, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get waterDeficitMm => $composableBuilder(
      column: $table.waterDeficitMm,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get nStressIdx => $composableBuilder(
      column: $table.nStressIdx, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get kStressIdx => $composableBuilder(
      column: $table.kStressIdx, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get diseasePressure => $composableBuilder(
      column: $table.diseasePressure,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get heightCm => $composableBuilder(
      column: $table.heightCm, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get biomassRel => $composableBuilder(
      column: $table.biomassRel, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get yieldMultiplier => $composableBuilder(
      column: $table.yieldMultiplier,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastComputedAt => $composableBuilder(
      column: $table.lastComputedAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$CropGrowthStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $CropGrowthStatesTable> {
  $$CropGrowthStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get cropId => $composableBuilder(
      column: $table.cropId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fieldId => $composableBuilder(
      column: $table.fieldId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get asOfDate => $composableBuilder(
      column: $table.asOfDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get accumulatedGdd => $composableBuilder(
      column: $table.accumulatedGdd,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currentStageKey => $composableBuilder(
      column: $table.currentStageKey,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get stageProgress => $composableBuilder(
      column: $table.stageProgress,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get waterDeficitMm => $composableBuilder(
      column: $table.waterDeficitMm,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get nStressIdx => $composableBuilder(
      column: $table.nStressIdx, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get kStressIdx => $composableBuilder(
      column: $table.kStressIdx, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get diseasePressure => $composableBuilder(
      column: $table.diseasePressure,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get heightCm => $composableBuilder(
      column: $table.heightCm, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get biomassRel => $composableBuilder(
      column: $table.biomassRel, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get yieldMultiplier => $composableBuilder(
      column: $table.yieldMultiplier,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastComputedAt => $composableBuilder(
      column: $table.lastComputedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$CropGrowthStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CropGrowthStatesTable> {
  $$CropGrowthStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get cropId =>
      $composableBuilder(column: $table.cropId, builder: (column) => column);

  GeneratedColumn<String> get fieldId =>
      $composableBuilder(column: $table.fieldId, builder: (column) => column);

  GeneratedColumn<DateTime> get asOfDate =>
      $composableBuilder(column: $table.asOfDate, builder: (column) => column);

  GeneratedColumn<double> get accumulatedGdd => $composableBuilder(
      column: $table.accumulatedGdd, builder: (column) => column);

  GeneratedColumn<String> get currentStageKey => $composableBuilder(
      column: $table.currentStageKey, builder: (column) => column);

  GeneratedColumn<double> get stageProgress => $composableBuilder(
      column: $table.stageProgress, builder: (column) => column);

  GeneratedColumn<double> get waterDeficitMm => $composableBuilder(
      column: $table.waterDeficitMm, builder: (column) => column);

  GeneratedColumn<double> get nStressIdx => $composableBuilder(
      column: $table.nStressIdx, builder: (column) => column);

  GeneratedColumn<double> get kStressIdx => $composableBuilder(
      column: $table.kStressIdx, builder: (column) => column);

  GeneratedColumn<double> get diseasePressure => $composableBuilder(
      column: $table.diseasePressure, builder: (column) => column);

  GeneratedColumn<double> get heightCm =>
      $composableBuilder(column: $table.heightCm, builder: (column) => column);

  GeneratedColumn<double> get biomassRel => $composableBuilder(
      column: $table.biomassRel, builder: (column) => column);

  GeneratedColumn<double> get yieldMultiplier => $composableBuilder(
      column: $table.yieldMultiplier, builder: (column) => column);

  GeneratedColumn<DateTime> get lastComputedAt => $composableBuilder(
      column: $table.lastComputedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CropGrowthStatesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CropGrowthStatesTable,
    CropGrowthState,
    $$CropGrowthStatesTableFilterComposer,
    $$CropGrowthStatesTableOrderingComposer,
    $$CropGrowthStatesTableAnnotationComposer,
    $$CropGrowthStatesTableCreateCompanionBuilder,
    $$CropGrowthStatesTableUpdateCompanionBuilder,
    (
      CropGrowthState,
      BaseReferences<_$AppDatabase, $CropGrowthStatesTable, CropGrowthState>
    ),
    CropGrowthState,
    PrefetchHooks Function()> {
  $$CropGrowthStatesTableTableManager(
      _$AppDatabase db, $CropGrowthStatesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CropGrowthStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CropGrowthStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CropGrowthStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> cropId = const Value.absent(),
            Value<String> fieldId = const Value.absent(),
            Value<DateTime> asOfDate = const Value.absent(),
            Value<double> accumulatedGdd = const Value.absent(),
            Value<String> currentStageKey = const Value.absent(),
            Value<double> stageProgress = const Value.absent(),
            Value<double> waterDeficitMm = const Value.absent(),
            Value<double> nStressIdx = const Value.absent(),
            Value<double> kStressIdx = const Value.absent(),
            Value<double> diseasePressure = const Value.absent(),
            Value<double> heightCm = const Value.absent(),
            Value<double> biomassRel = const Value.absent(),
            Value<double> yieldMultiplier = const Value.absent(),
            Value<DateTime> lastComputedAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CropGrowthStatesCompanion(
            cropId: cropId,
            fieldId: fieldId,
            asOfDate: asOfDate,
            accumulatedGdd: accumulatedGdd,
            currentStageKey: currentStageKey,
            stageProgress: stageProgress,
            waterDeficitMm: waterDeficitMm,
            nStressIdx: nStressIdx,
            kStressIdx: kStressIdx,
            diseasePressure: diseasePressure,
            heightCm: heightCm,
            biomassRel: biomassRel,
            yieldMultiplier: yieldMultiplier,
            lastComputedAt: lastComputedAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String cropId,
            required String fieldId,
            required DateTime asOfDate,
            Value<double> accumulatedGdd = const Value.absent(),
            Value<String> currentStageKey = const Value.absent(),
            Value<double> stageProgress = const Value.absent(),
            Value<double> waterDeficitMm = const Value.absent(),
            Value<double> nStressIdx = const Value.absent(),
            Value<double> kStressIdx = const Value.absent(),
            Value<double> diseasePressure = const Value.absent(),
            Value<double> heightCm = const Value.absent(),
            Value<double> biomassRel = const Value.absent(),
            Value<double> yieldMultiplier = const Value.absent(),
            required DateTime lastComputedAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              CropGrowthStatesCompanion.insert(
            cropId: cropId,
            fieldId: fieldId,
            asOfDate: asOfDate,
            accumulatedGdd: accumulatedGdd,
            currentStageKey: currentStageKey,
            stageProgress: stageProgress,
            waterDeficitMm: waterDeficitMm,
            nStressIdx: nStressIdx,
            kStressIdx: kStressIdx,
            diseasePressure: diseasePressure,
            heightCm: heightCm,
            biomassRel: biomassRel,
            yieldMultiplier: yieldMultiplier,
            lastComputedAt: lastComputedAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CropGrowthStatesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CropGrowthStatesTable,
    CropGrowthState,
    $$CropGrowthStatesTableFilterComposer,
    $$CropGrowthStatesTableOrderingComposer,
    $$CropGrowthStatesTableAnnotationComposer,
    $$CropGrowthStatesTableCreateCompanionBuilder,
    $$CropGrowthStatesTableUpdateCompanionBuilder,
    (
      CropGrowthState,
      BaseReferences<_$AppDatabase, $CropGrowthStatesTable, CropGrowthState>
    ),
    CropGrowthState,
    PrefetchHooks Function()>;
typedef $$FieldPlantInstancesTableCreateCompanionBuilder
    = FieldPlantInstancesCompanion Function({
  required String id,
  required String fieldId,
  Value<String?> cropId,
  Value<int?> plantIndex,
  required String cropName,
  required double lat,
  required double lng,
  Value<String> healthStatus,
  Value<String?> diseaseType,
  Value<String?> diseasePhotoPath,
  Value<String> diagnosisSource,
  Value<String?> notes,
  required DateTime plantedAt,
  Value<DateTime?> healthChangedAt,
  Value<String?> conditionFlagsJson,
  Value<String?> phenologyStageKey,
  Value<String?> facingDirection,
  Value<DateTime?> lastObservedAt,
  Value<String?> farmerUid,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});
typedef $$FieldPlantInstancesTableUpdateCompanionBuilder
    = FieldPlantInstancesCompanion Function({
  Value<String> id,
  Value<String> fieldId,
  Value<String?> cropId,
  Value<int?> plantIndex,
  Value<String> cropName,
  Value<double> lat,
  Value<double> lng,
  Value<String> healthStatus,
  Value<String?> diseaseType,
  Value<String?> diseasePhotoPath,
  Value<String> diagnosisSource,
  Value<String?> notes,
  Value<DateTime> plantedAt,
  Value<DateTime?> healthChangedAt,
  Value<String?> conditionFlagsJson,
  Value<String?> phenologyStageKey,
  Value<String?> facingDirection,
  Value<DateTime?> lastObservedAt,
  Value<String?> farmerUid,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});

final class $$FieldPlantInstancesTableReferences extends BaseReferences<
    _$AppDatabase, $FieldPlantInstancesTable, FieldPlantInstance> {
  $$FieldPlantInstancesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $FieldsTable _fieldIdTable(_$AppDatabase db) => db.fields.createAlias(
      $_aliasNameGenerator(db.fieldPlantInstances.fieldId, db.fields.id));

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
      db.fieldCrops.createAlias($_aliasNameGenerator(
          db.fieldPlantInstances.cropId, db.fieldCrops.id));

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

class $$FieldPlantInstancesTableFilterComposer
    extends Composer<_$AppDatabase, $FieldPlantInstancesTable> {
  $$FieldPlantInstancesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get plantIndex => $composableBuilder(
      column: $table.plantIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cropName => $composableBuilder(
      column: $table.cropName, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get lat => $composableBuilder(
      column: $table.lat, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get lng => $composableBuilder(
      column: $table.lng, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get healthStatus => $composableBuilder(
      column: $table.healthStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get diseaseType => $composableBuilder(
      column: $table.diseaseType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get diseasePhotoPath => $composableBuilder(
      column: $table.diseasePhotoPath,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get diagnosisSource => $composableBuilder(
      column: $table.diagnosisSource,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get plantedAt => $composableBuilder(
      column: $table.plantedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get healthChangedAt => $composableBuilder(
      column: $table.healthChangedAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get conditionFlagsJson => $composableBuilder(
      column: $table.conditionFlagsJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phenologyStageKey => $composableBuilder(
      column: $table.phenologyStageKey,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get facingDirection => $composableBuilder(
      column: $table.facingDirection,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastObservedAt => $composableBuilder(
      column: $table.lastObservedAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get farmerUid => $composableBuilder(
      column: $table.farmerUid, builder: (column) => ColumnFilters(column));

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

class $$FieldPlantInstancesTableOrderingComposer
    extends Composer<_$AppDatabase, $FieldPlantInstancesTable> {
  $$FieldPlantInstancesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get plantIndex => $composableBuilder(
      column: $table.plantIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cropName => $composableBuilder(
      column: $table.cropName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get lat => $composableBuilder(
      column: $table.lat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get lng => $composableBuilder(
      column: $table.lng, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get healthStatus => $composableBuilder(
      column: $table.healthStatus,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get diseaseType => $composableBuilder(
      column: $table.diseaseType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get diseasePhotoPath => $composableBuilder(
      column: $table.diseasePhotoPath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get diagnosisSource => $composableBuilder(
      column: $table.diagnosisSource,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get plantedAt => $composableBuilder(
      column: $table.plantedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get healthChangedAt => $composableBuilder(
      column: $table.healthChangedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get conditionFlagsJson => $composableBuilder(
      column: $table.conditionFlagsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phenologyStageKey => $composableBuilder(
      column: $table.phenologyStageKey,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get facingDirection => $composableBuilder(
      column: $table.facingDirection,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastObservedAt => $composableBuilder(
      column: $table.lastObservedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get farmerUid => $composableBuilder(
      column: $table.farmerUid, builder: (column) => ColumnOrderings(column));

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

class $$FieldPlantInstancesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FieldPlantInstancesTable> {
  $$FieldPlantInstancesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get plantIndex => $composableBuilder(
      column: $table.plantIndex, builder: (column) => column);

  GeneratedColumn<String> get cropName =>
      $composableBuilder(column: $table.cropName, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lng =>
      $composableBuilder(column: $table.lng, builder: (column) => column);

  GeneratedColumn<String> get healthStatus => $composableBuilder(
      column: $table.healthStatus, builder: (column) => column);

  GeneratedColumn<String> get diseaseType => $composableBuilder(
      column: $table.diseaseType, builder: (column) => column);

  GeneratedColumn<String> get diseasePhotoPath => $composableBuilder(
      column: $table.diseasePhotoPath, builder: (column) => column);

  GeneratedColumn<String> get diagnosisSource => $composableBuilder(
      column: $table.diagnosisSource, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get plantedAt =>
      $composableBuilder(column: $table.plantedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get healthChangedAt => $composableBuilder(
      column: $table.healthChangedAt, builder: (column) => column);

  GeneratedColumn<String> get conditionFlagsJson => $composableBuilder(
      column: $table.conditionFlagsJson, builder: (column) => column);

  GeneratedColumn<String> get phenologyStageKey => $composableBuilder(
      column: $table.phenologyStageKey, builder: (column) => column);

  GeneratedColumn<String> get facingDirection => $composableBuilder(
      column: $table.facingDirection, builder: (column) => column);

  GeneratedColumn<DateTime> get lastObservedAt => $composableBuilder(
      column: $table.lastObservedAt, builder: (column) => column);

  GeneratedColumn<String> get farmerUid =>
      $composableBuilder(column: $table.farmerUid, builder: (column) => column);

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

class $$FieldPlantInstancesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FieldPlantInstancesTable,
    FieldPlantInstance,
    $$FieldPlantInstancesTableFilterComposer,
    $$FieldPlantInstancesTableOrderingComposer,
    $$FieldPlantInstancesTableAnnotationComposer,
    $$FieldPlantInstancesTableCreateCompanionBuilder,
    $$FieldPlantInstancesTableUpdateCompanionBuilder,
    (FieldPlantInstance, $$FieldPlantInstancesTableReferences),
    FieldPlantInstance,
    PrefetchHooks Function({bool fieldId, bool cropId})> {
  $$FieldPlantInstancesTableTableManager(
      _$AppDatabase db, $FieldPlantInstancesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FieldPlantInstancesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FieldPlantInstancesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FieldPlantInstancesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> fieldId = const Value.absent(),
            Value<String?> cropId = const Value.absent(),
            Value<int?> plantIndex = const Value.absent(),
            Value<String> cropName = const Value.absent(),
            Value<double> lat = const Value.absent(),
            Value<double> lng = const Value.absent(),
            Value<String> healthStatus = const Value.absent(),
            Value<String?> diseaseType = const Value.absent(),
            Value<String?> diseasePhotoPath = const Value.absent(),
            Value<String> diagnosisSource = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> plantedAt = const Value.absent(),
            Value<DateTime?> healthChangedAt = const Value.absent(),
            Value<String?> conditionFlagsJson = const Value.absent(),
            Value<String?> phenologyStageKey = const Value.absent(),
            Value<String?> facingDirection = const Value.absent(),
            Value<DateTime?> lastObservedAt = const Value.absent(),
            Value<String?> farmerUid = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FieldPlantInstancesCompanion(
            id: id,
            fieldId: fieldId,
            cropId: cropId,
            plantIndex: plantIndex,
            cropName: cropName,
            lat: lat,
            lng: lng,
            healthStatus: healthStatus,
            diseaseType: diseaseType,
            diseasePhotoPath: diseasePhotoPath,
            diagnosisSource: diagnosisSource,
            notes: notes,
            plantedAt: plantedAt,
            healthChangedAt: healthChangedAt,
            conditionFlagsJson: conditionFlagsJson,
            phenologyStageKey: phenologyStageKey,
            facingDirection: facingDirection,
            lastObservedAt: lastObservedAt,
            farmerUid: farmerUid,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String fieldId,
            Value<String?> cropId = const Value.absent(),
            Value<int?> plantIndex = const Value.absent(),
            required String cropName,
            required double lat,
            required double lng,
            Value<String> healthStatus = const Value.absent(),
            Value<String?> diseaseType = const Value.absent(),
            Value<String?> diseasePhotoPath = const Value.absent(),
            Value<String> diagnosisSource = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            required DateTime plantedAt,
            Value<DateTime?> healthChangedAt = const Value.absent(),
            Value<String?> conditionFlagsJson = const Value.absent(),
            Value<String?> phenologyStageKey = const Value.absent(),
            Value<String?> facingDirection = const Value.absent(),
            Value<DateTime?> lastObservedAt = const Value.absent(),
            Value<String?> farmerUid = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FieldPlantInstancesCompanion.insert(
            id: id,
            fieldId: fieldId,
            cropId: cropId,
            plantIndex: plantIndex,
            cropName: cropName,
            lat: lat,
            lng: lng,
            healthStatus: healthStatus,
            diseaseType: diseaseType,
            diseasePhotoPath: diseasePhotoPath,
            diagnosisSource: diagnosisSource,
            notes: notes,
            plantedAt: plantedAt,
            healthChangedAt: healthChangedAt,
            conditionFlagsJson: conditionFlagsJson,
            phenologyStageKey: phenologyStageKey,
            facingDirection: facingDirection,
            lastObservedAt: lastObservedAt,
            farmerUid: farmerUid,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$FieldPlantInstancesTableReferences(db, table, e)
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
                        $$FieldPlantInstancesTableReferences._fieldIdTable(db),
                    referencedColumn: $$FieldPlantInstancesTableReferences
                        ._fieldIdTable(db)
                        .id,
                  ) as T;
                }
                if (cropId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.cropId,
                    referencedTable:
                        $$FieldPlantInstancesTableReferences._cropIdTable(db),
                    referencedColumn: $$FieldPlantInstancesTableReferences
                        ._cropIdTable(db)
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

typedef $$FieldPlantInstancesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FieldPlantInstancesTable,
    FieldPlantInstance,
    $$FieldPlantInstancesTableFilterComposer,
    $$FieldPlantInstancesTableOrderingComposer,
    $$FieldPlantInstancesTableAnnotationComposer,
    $$FieldPlantInstancesTableCreateCompanionBuilder,
    $$FieldPlantInstancesTableUpdateCompanionBuilder,
    (FieldPlantInstance, $$FieldPlantInstancesTableReferences),
    FieldPlantInstance,
    PrefetchHooks Function({bool fieldId, bool cropId})>;
typedef $$PlantConditionEventsTableCreateCompanionBuilder
    = PlantConditionEventsCompanion Function({
  required String id,
  required String plantInstanceId,
  required String fieldId,
  Value<String?> cropId,
  required String condition,
  Value<String> sourceType,
  Value<String?> notes,
  Value<String?> photoPath,
  required DateTime observedAt,
  Value<String?> farmerUid,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});
typedef $$PlantConditionEventsTableUpdateCompanionBuilder
    = PlantConditionEventsCompanion Function({
  Value<String> id,
  Value<String> plantInstanceId,
  Value<String> fieldId,
  Value<String?> cropId,
  Value<String> condition,
  Value<String> sourceType,
  Value<String?> notes,
  Value<String?> photoPath,
  Value<DateTime> observedAt,
  Value<String?> farmerUid,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});

class $$PlantConditionEventsTableFilterComposer
    extends Composer<_$AppDatabase, $PlantConditionEventsTable> {
  $$PlantConditionEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get plantInstanceId => $composableBuilder(
      column: $table.plantInstanceId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fieldId => $composableBuilder(
      column: $table.fieldId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cropId => $composableBuilder(
      column: $table.cropId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get condition => $composableBuilder(
      column: $table.condition, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceType => $composableBuilder(
      column: $table.sourceType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get photoPath => $composableBuilder(
      column: $table.photoPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get observedAt => $composableBuilder(
      column: $table.observedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get farmerUid => $composableBuilder(
      column: $table.farmerUid, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));
}

class $$PlantConditionEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlantConditionEventsTable> {
  $$PlantConditionEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get plantInstanceId => $composableBuilder(
      column: $table.plantInstanceId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fieldId => $composableBuilder(
      column: $table.fieldId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cropId => $composableBuilder(
      column: $table.cropId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get condition => $composableBuilder(
      column: $table.condition, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceType => $composableBuilder(
      column: $table.sourceType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get photoPath => $composableBuilder(
      column: $table.photoPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get observedAt => $composableBuilder(
      column: $table.observedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get farmerUid => $composableBuilder(
      column: $table.farmerUid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));
}

class $$PlantConditionEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlantConditionEventsTable> {
  $$PlantConditionEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get plantInstanceId => $composableBuilder(
      column: $table.plantInstanceId, builder: (column) => column);

  GeneratedColumn<String> get fieldId =>
      $composableBuilder(column: $table.fieldId, builder: (column) => column);

  GeneratedColumn<String> get cropId =>
      $composableBuilder(column: $table.cropId, builder: (column) => column);

  GeneratedColumn<String> get condition =>
      $composableBuilder(column: $table.condition, builder: (column) => column);

  GeneratedColumn<String> get sourceType => $composableBuilder(
      column: $table.sourceType, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get photoPath =>
      $composableBuilder(column: $table.photoPath, builder: (column) => column);

  GeneratedColumn<DateTime> get observedAt => $composableBuilder(
      column: $table.observedAt, builder: (column) => column);

  GeneratedColumn<String> get farmerUid =>
      $composableBuilder(column: $table.farmerUid, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$PlantConditionEventsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PlantConditionEventsTable,
    PlantConditionEvent,
    $$PlantConditionEventsTableFilterComposer,
    $$PlantConditionEventsTableOrderingComposer,
    $$PlantConditionEventsTableAnnotationComposer,
    $$PlantConditionEventsTableCreateCompanionBuilder,
    $$PlantConditionEventsTableUpdateCompanionBuilder,
    (
      PlantConditionEvent,
      BaseReferences<_$AppDatabase, $PlantConditionEventsTable,
          PlantConditionEvent>
    ),
    PlantConditionEvent,
    PrefetchHooks Function()> {
  $$PlantConditionEventsTableTableManager(
      _$AppDatabase db, $PlantConditionEventsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlantConditionEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlantConditionEventsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlantConditionEventsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> plantInstanceId = const Value.absent(),
            Value<String> fieldId = const Value.absent(),
            Value<String?> cropId = const Value.absent(),
            Value<String> condition = const Value.absent(),
            Value<String> sourceType = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String?> photoPath = const Value.absent(),
            Value<DateTime> observedAt = const Value.absent(),
            Value<String?> farmerUid = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PlantConditionEventsCompanion(
            id: id,
            plantInstanceId: plantInstanceId,
            fieldId: fieldId,
            cropId: cropId,
            condition: condition,
            sourceType: sourceType,
            notes: notes,
            photoPath: photoPath,
            observedAt: observedAt,
            farmerUid: farmerUid,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String plantInstanceId,
            required String fieldId,
            Value<String?> cropId = const Value.absent(),
            required String condition,
            Value<String> sourceType = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String?> photoPath = const Value.absent(),
            required DateTime observedAt,
            Value<String?> farmerUid = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PlantConditionEventsCompanion.insert(
            id: id,
            plantInstanceId: plantInstanceId,
            fieldId: fieldId,
            cropId: cropId,
            condition: condition,
            sourceType: sourceType,
            notes: notes,
            photoPath: photoPath,
            observedAt: observedAt,
            farmerUid: farmerUid,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PlantConditionEventsTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $PlantConditionEventsTable,
        PlantConditionEvent,
        $$PlantConditionEventsTableFilterComposer,
        $$PlantConditionEventsTableOrderingComposer,
        $$PlantConditionEventsTableAnnotationComposer,
        $$PlantConditionEventsTableCreateCompanionBuilder,
        $$PlantConditionEventsTableUpdateCompanionBuilder,
        (
          PlantConditionEvent,
          BaseReferences<_$AppDatabase, $PlantConditionEventsTable,
              PlantConditionEvent>
        ),
        PlantConditionEvent,
        PrefetchHooks Function()>;
typedef $$SoilTestsTableCreateCompanionBuilder = SoilTestsCompanion Function({
  required String id,
  Value<String?> farmerUid,
  required String fieldId,
  Value<String?> sampleLabel,
  Value<String?> labName,
  Value<DateTime?> sampledAt,
  Value<double?> ph,
  Value<double?> saltPct,
  Value<double?> ecDsM,
  Value<double?> limePct,
  Value<double?> organicMatterPct,
  Value<double?> phosphorusKgDa,
  Value<double?> potassiumKgDa,
  Value<double?> nitrogenPct,
  Value<double?> saturationPct,
  Value<String?> textureClass,
  Value<double?> sampleLat,
  Value<double?> sampleLng,
  Value<String?> notes,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});
typedef $$SoilTestsTableUpdateCompanionBuilder = SoilTestsCompanion Function({
  Value<String> id,
  Value<String?> farmerUid,
  Value<String> fieldId,
  Value<String?> sampleLabel,
  Value<String?> labName,
  Value<DateTime?> sampledAt,
  Value<double?> ph,
  Value<double?> saltPct,
  Value<double?> ecDsM,
  Value<double?> limePct,
  Value<double?> organicMatterPct,
  Value<double?> phosphorusKgDa,
  Value<double?> potassiumKgDa,
  Value<double?> nitrogenPct,
  Value<double?> saturationPct,
  Value<String?> textureClass,
  Value<double?> sampleLat,
  Value<double?> sampleLng,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});

final class $$SoilTestsTableReferences
    extends BaseReferences<_$AppDatabase, $SoilTestsTable, SoilTest> {
  $$SoilTestsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FieldsTable _fieldIdTable(_$AppDatabase db) => db.fields
      .createAlias($_aliasNameGenerator(db.soilTests.fieldId, db.fields.id));

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

class $$SoilTestsTableFilterComposer
    extends Composer<_$AppDatabase, $SoilTestsTable> {
  $$SoilTestsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get farmerUid => $composableBuilder(
      column: $table.farmerUid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sampleLabel => $composableBuilder(
      column: $table.sampleLabel, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get labName => $composableBuilder(
      column: $table.labName, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get sampledAt => $composableBuilder(
      column: $table.sampledAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get ph => $composableBuilder(
      column: $table.ph, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get saltPct => $composableBuilder(
      column: $table.saltPct, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get ecDsM => $composableBuilder(
      column: $table.ecDsM, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get limePct => $composableBuilder(
      column: $table.limePct, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get organicMatterPct => $composableBuilder(
      column: $table.organicMatterPct,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get phosphorusKgDa => $composableBuilder(
      column: $table.phosphorusKgDa,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get potassiumKgDa => $composableBuilder(
      column: $table.potassiumKgDa, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get nitrogenPct => $composableBuilder(
      column: $table.nitrogenPct, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get saturationPct => $composableBuilder(
      column: $table.saturationPct, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get textureClass => $composableBuilder(
      column: $table.textureClass, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get sampleLat => $composableBuilder(
      column: $table.sampleLat, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get sampleLng => $composableBuilder(
      column: $table.sampleLng, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

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

class $$SoilTestsTableOrderingComposer
    extends Composer<_$AppDatabase, $SoilTestsTable> {
  $$SoilTestsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get farmerUid => $composableBuilder(
      column: $table.farmerUid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sampleLabel => $composableBuilder(
      column: $table.sampleLabel, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get labName => $composableBuilder(
      column: $table.labName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get sampledAt => $composableBuilder(
      column: $table.sampledAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get ph => $composableBuilder(
      column: $table.ph, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get saltPct => $composableBuilder(
      column: $table.saltPct, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get ecDsM => $composableBuilder(
      column: $table.ecDsM, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get limePct => $composableBuilder(
      column: $table.limePct, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get organicMatterPct => $composableBuilder(
      column: $table.organicMatterPct,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get phosphorusKgDa => $composableBuilder(
      column: $table.phosphorusKgDa,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get potassiumKgDa => $composableBuilder(
      column: $table.potassiumKgDa,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get nitrogenPct => $composableBuilder(
      column: $table.nitrogenPct, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get saturationPct => $composableBuilder(
      column: $table.saturationPct,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get textureClass => $composableBuilder(
      column: $table.textureClass,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get sampleLat => $composableBuilder(
      column: $table.sampleLat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get sampleLng => $composableBuilder(
      column: $table.sampleLng, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

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

class $$SoilTestsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SoilTestsTable> {
  $$SoilTestsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get farmerUid =>
      $composableBuilder(column: $table.farmerUid, builder: (column) => column);

  GeneratedColumn<String> get sampleLabel => $composableBuilder(
      column: $table.sampleLabel, builder: (column) => column);

  GeneratedColumn<String> get labName =>
      $composableBuilder(column: $table.labName, builder: (column) => column);

  GeneratedColumn<DateTime> get sampledAt =>
      $composableBuilder(column: $table.sampledAt, builder: (column) => column);

  GeneratedColumn<double> get ph =>
      $composableBuilder(column: $table.ph, builder: (column) => column);

  GeneratedColumn<double> get saltPct =>
      $composableBuilder(column: $table.saltPct, builder: (column) => column);

  GeneratedColumn<double> get ecDsM =>
      $composableBuilder(column: $table.ecDsM, builder: (column) => column);

  GeneratedColumn<double> get limePct =>
      $composableBuilder(column: $table.limePct, builder: (column) => column);

  GeneratedColumn<double> get organicMatterPct => $composableBuilder(
      column: $table.organicMatterPct, builder: (column) => column);

  GeneratedColumn<double> get phosphorusKgDa => $composableBuilder(
      column: $table.phosphorusKgDa, builder: (column) => column);

  GeneratedColumn<double> get potassiumKgDa => $composableBuilder(
      column: $table.potassiumKgDa, builder: (column) => column);

  GeneratedColumn<double> get nitrogenPct => $composableBuilder(
      column: $table.nitrogenPct, builder: (column) => column);

  GeneratedColumn<double> get saturationPct => $composableBuilder(
      column: $table.saturationPct, builder: (column) => column);

  GeneratedColumn<String> get textureClass => $composableBuilder(
      column: $table.textureClass, builder: (column) => column);

  GeneratedColumn<double> get sampleLat =>
      $composableBuilder(column: $table.sampleLat, builder: (column) => column);

  GeneratedColumn<double> get sampleLng =>
      $composableBuilder(column: $table.sampleLng, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

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

class $$SoilTestsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SoilTestsTable,
    SoilTest,
    $$SoilTestsTableFilterComposer,
    $$SoilTestsTableOrderingComposer,
    $$SoilTestsTableAnnotationComposer,
    $$SoilTestsTableCreateCompanionBuilder,
    $$SoilTestsTableUpdateCompanionBuilder,
    (SoilTest, $$SoilTestsTableReferences),
    SoilTest,
    PrefetchHooks Function({bool fieldId})> {
  $$SoilTestsTableTableManager(_$AppDatabase db, $SoilTestsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SoilTestsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SoilTestsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SoilTestsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> farmerUid = const Value.absent(),
            Value<String> fieldId = const Value.absent(),
            Value<String?> sampleLabel = const Value.absent(),
            Value<String?> labName = const Value.absent(),
            Value<DateTime?> sampledAt = const Value.absent(),
            Value<double?> ph = const Value.absent(),
            Value<double?> saltPct = const Value.absent(),
            Value<double?> ecDsM = const Value.absent(),
            Value<double?> limePct = const Value.absent(),
            Value<double?> organicMatterPct = const Value.absent(),
            Value<double?> phosphorusKgDa = const Value.absent(),
            Value<double?> potassiumKgDa = const Value.absent(),
            Value<double?> nitrogenPct = const Value.absent(),
            Value<double?> saturationPct = const Value.absent(),
            Value<String?> textureClass = const Value.absent(),
            Value<double?> sampleLat = const Value.absent(),
            Value<double?> sampleLng = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SoilTestsCompanion(
            id: id,
            farmerUid: farmerUid,
            fieldId: fieldId,
            sampleLabel: sampleLabel,
            labName: labName,
            sampledAt: sampledAt,
            ph: ph,
            saltPct: saltPct,
            ecDsM: ecDsM,
            limePct: limePct,
            organicMatterPct: organicMatterPct,
            phosphorusKgDa: phosphorusKgDa,
            potassiumKgDa: potassiumKgDa,
            nitrogenPct: nitrogenPct,
            saturationPct: saturationPct,
            textureClass: textureClass,
            sampleLat: sampleLat,
            sampleLng: sampleLng,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String?> farmerUid = const Value.absent(),
            required String fieldId,
            Value<String?> sampleLabel = const Value.absent(),
            Value<String?> labName = const Value.absent(),
            Value<DateTime?> sampledAt = const Value.absent(),
            Value<double?> ph = const Value.absent(),
            Value<double?> saltPct = const Value.absent(),
            Value<double?> ecDsM = const Value.absent(),
            Value<double?> limePct = const Value.absent(),
            Value<double?> organicMatterPct = const Value.absent(),
            Value<double?> phosphorusKgDa = const Value.absent(),
            Value<double?> potassiumKgDa = const Value.absent(),
            Value<double?> nitrogenPct = const Value.absent(),
            Value<double?> saturationPct = const Value.absent(),
            Value<String?> textureClass = const Value.absent(),
            Value<double?> sampleLat = const Value.absent(),
            Value<double?> sampleLng = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SoilTestsCompanion.insert(
            id: id,
            farmerUid: farmerUid,
            fieldId: fieldId,
            sampleLabel: sampleLabel,
            labName: labName,
            sampledAt: sampledAt,
            ph: ph,
            saltPct: saltPct,
            ecDsM: ecDsM,
            limePct: limePct,
            organicMatterPct: organicMatterPct,
            phosphorusKgDa: phosphorusKgDa,
            potassiumKgDa: potassiumKgDa,
            nitrogenPct: nitrogenPct,
            saturationPct: saturationPct,
            textureClass: textureClass,
            sampleLat: sampleLat,
            sampleLng: sampleLng,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$SoilTestsTableReferences(db, table, e)
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
                        $$SoilTestsTableReferences._fieldIdTable(db),
                    referencedColumn:
                        $$SoilTestsTableReferences._fieldIdTable(db).id,
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

typedef $$SoilTestsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SoilTestsTable,
    SoilTest,
    $$SoilTestsTableFilterComposer,
    $$SoilTestsTableOrderingComposer,
    $$SoilTestsTableAnnotationComposer,
    $$SoilTestsTableCreateCompanionBuilder,
    $$SoilTestsTableUpdateCompanionBuilder,
    (SoilTest, $$SoilTestsTableReferences),
    SoilTest,
    PrefetchHooks Function({bool fieldId})>;

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
  $$CropGrowthStatesTableTableManager get cropGrowthStates =>
      $$CropGrowthStatesTableTableManager(_db, _db.cropGrowthStates);
  $$FieldPlantInstancesTableTableManager get fieldPlantInstances =>
      $$FieldPlantInstancesTableTableManager(_db, _db.fieldPlantInstances);
  $$PlantConditionEventsTableTableManager get plantConditionEvents =>
      $$PlantConditionEventsTableTableManager(_db, _db.plantConditionEvents);
  $$SoilTestsTableTableManager get soilTests =>
      $$SoilTestsTableTableManager(_db, _db.soilTests);
}
