// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'audit_metadata.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AuditMetadata {

 DateTime? get createdAt; String? get createdBy; DateTime? get updatedAt; String? get updatedBy; DateTime? get archivedAt; String? get archivedBy;
/// Create a copy of AuditMetadata
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuditMetadataCopyWith<AuditMetadata> get copyWith => _$AuditMetadataCopyWithImpl<AuditMetadata>(this as AuditMetadata, _$identity);

  /// Serializes this AuditMetadata to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuditMetadata&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt)&&(identical(other.archivedBy, archivedBy) || other.archivedBy == archivedBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,createdAt,createdBy,updatedAt,updatedBy,archivedAt,archivedBy);

@override
String toString() {
  return 'AuditMetadata(createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy, archivedAt: $archivedAt, archivedBy: $archivedBy)';
}


}

/// @nodoc
abstract mixin class $AuditMetadataCopyWith<$Res>  {
  factory $AuditMetadataCopyWith(AuditMetadata value, $Res Function(AuditMetadata) _then) = _$AuditMetadataCopyWithImpl;
@useResult
$Res call({
 DateTime? createdAt, String? createdBy, DateTime? updatedAt, String? updatedBy, DateTime? archivedAt, String? archivedBy
});




}
/// @nodoc
class _$AuditMetadataCopyWithImpl<$Res>
    implements $AuditMetadataCopyWith<$Res> {
  _$AuditMetadataCopyWithImpl(this._self, this._then);

  final AuditMetadata _self;
  final $Res Function(AuditMetadata) _then;

/// Create a copy of AuditMetadata
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? createdAt = freezed,Object? createdBy = freezed,Object? updatedAt = freezed,Object? updatedBy = freezed,Object? archivedAt = freezed,Object? archivedBy = freezed,}) {
  return _then(_self.copyWith(
createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedBy: freezed == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String?,archivedAt: freezed == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,archivedBy: freezed == archivedBy ? _self.archivedBy : archivedBy // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AuditMetadata].
extension AuditMetadataPatterns on AuditMetadata {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuditMetadata value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuditMetadata() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuditMetadata value)  $default,){
final _that = this;
switch (_that) {
case _AuditMetadata():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuditMetadata value)?  $default,){
final _that = this;
switch (_that) {
case _AuditMetadata() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime? createdAt,  String? createdBy,  DateTime? updatedAt,  String? updatedBy,  DateTime? archivedAt,  String? archivedBy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuditMetadata() when $default != null:
return $default(_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy,_that.archivedAt,_that.archivedBy);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime? createdAt,  String? createdBy,  DateTime? updatedAt,  String? updatedBy,  DateTime? archivedAt,  String? archivedBy)  $default,) {final _that = this;
switch (_that) {
case _AuditMetadata():
return $default(_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy,_that.archivedAt,_that.archivedBy);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime? createdAt,  String? createdBy,  DateTime? updatedAt,  String? updatedBy,  DateTime? archivedAt,  String? archivedBy)?  $default,) {final _that = this;
switch (_that) {
case _AuditMetadata() when $default != null:
return $default(_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy,_that.archivedAt,_that.archivedBy);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AuditMetadata implements AuditMetadata {
  const _AuditMetadata({this.createdAt, this.createdBy, this.updatedAt, this.updatedBy, this.archivedAt, this.archivedBy});
  factory _AuditMetadata.fromJson(Map<String, dynamic> json) => _$AuditMetadataFromJson(json);

@override final  DateTime? createdAt;
@override final  String? createdBy;
@override final  DateTime? updatedAt;
@override final  String? updatedBy;
@override final  DateTime? archivedAt;
@override final  String? archivedBy;

/// Create a copy of AuditMetadata
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuditMetadataCopyWith<_AuditMetadata> get copyWith => __$AuditMetadataCopyWithImpl<_AuditMetadata>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AuditMetadataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuditMetadata&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt)&&(identical(other.archivedBy, archivedBy) || other.archivedBy == archivedBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,createdAt,createdBy,updatedAt,updatedBy,archivedAt,archivedBy);

@override
String toString() {
  return 'AuditMetadata(createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy, archivedAt: $archivedAt, archivedBy: $archivedBy)';
}


}

/// @nodoc
abstract mixin class _$AuditMetadataCopyWith<$Res> implements $AuditMetadataCopyWith<$Res> {
  factory _$AuditMetadataCopyWith(_AuditMetadata value, $Res Function(_AuditMetadata) _then) = __$AuditMetadataCopyWithImpl;
@override @useResult
$Res call({
 DateTime? createdAt, String? createdBy, DateTime? updatedAt, String? updatedBy, DateTime? archivedAt, String? archivedBy
});




}
/// @nodoc
class __$AuditMetadataCopyWithImpl<$Res>
    implements _$AuditMetadataCopyWith<$Res> {
  __$AuditMetadataCopyWithImpl(this._self, this._then);

  final _AuditMetadata _self;
  final $Res Function(_AuditMetadata) _then;

/// Create a copy of AuditMetadata
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? createdAt = freezed,Object? createdBy = freezed,Object? updatedAt = freezed,Object? updatedBy = freezed,Object? archivedAt = freezed,Object? archivedBy = freezed,}) {
  return _then(_AuditMetadata(
createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedBy: freezed == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String?,archivedAt: freezed == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,archivedBy: freezed == archivedBy ? _self.archivedBy : archivedBy // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
