// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'company_asset.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CompanyAsset {

 String get id; String get name; AssetCategory get category; double get purchasePrice; DateTime get purchaseDate; DateTime get createdAt; String? get note;
/// Create a copy of CompanyAsset
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CompanyAssetCopyWith<CompanyAsset> get copyWith => _$CompanyAssetCopyWithImpl<CompanyAsset>(this as CompanyAsset, _$identity);

  /// Serializes this CompanyAsset to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CompanyAsset&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.category, category) || other.category == category)&&(identical(other.purchasePrice, purchasePrice) || other.purchasePrice == purchasePrice)&&(identical(other.purchaseDate, purchaseDate) || other.purchaseDate == purchaseDate)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.note, note) || other.note == note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,category,purchasePrice,purchaseDate,createdAt,note);

@override
String toString() {
  return 'CompanyAsset(id: $id, name: $name, category: $category, purchasePrice: $purchasePrice, purchaseDate: $purchaseDate, createdAt: $createdAt, note: $note)';
}


}

/// @nodoc
abstract mixin class $CompanyAssetCopyWith<$Res>  {
  factory $CompanyAssetCopyWith(CompanyAsset value, $Res Function(CompanyAsset) _then) = _$CompanyAssetCopyWithImpl;
@useResult
$Res call({
 String id, String name, AssetCategory category, double purchasePrice, DateTime purchaseDate, DateTime createdAt, String? note
});




}
/// @nodoc
class _$CompanyAssetCopyWithImpl<$Res>
    implements $CompanyAssetCopyWith<$Res> {
  _$CompanyAssetCopyWithImpl(this._self, this._then);

  final CompanyAsset _self;
  final $Res Function(CompanyAsset) _then;

/// Create a copy of CompanyAsset
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? category = null,Object? purchasePrice = null,Object? purchaseDate = null,Object? createdAt = null,Object? note = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as AssetCategory,purchasePrice: null == purchasePrice ? _self.purchasePrice : purchasePrice // ignore: cast_nullable_to_non_nullable
as double,purchaseDate: null == purchaseDate ? _self.purchaseDate : purchaseDate // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CompanyAsset].
extension CompanyAssetPatterns on CompanyAsset {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CompanyAsset value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CompanyAsset() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CompanyAsset value)  $default,){
final _that = this;
switch (_that) {
case _CompanyAsset():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CompanyAsset value)?  $default,){
final _that = this;
switch (_that) {
case _CompanyAsset() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  AssetCategory category,  double purchasePrice,  DateTime purchaseDate,  DateTime createdAt,  String? note)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CompanyAsset() when $default != null:
return $default(_that.id,_that.name,_that.category,_that.purchasePrice,_that.purchaseDate,_that.createdAt,_that.note);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  AssetCategory category,  double purchasePrice,  DateTime purchaseDate,  DateTime createdAt,  String? note)  $default,) {final _that = this;
switch (_that) {
case _CompanyAsset():
return $default(_that.id,_that.name,_that.category,_that.purchasePrice,_that.purchaseDate,_that.createdAt,_that.note);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  AssetCategory category,  double purchasePrice,  DateTime purchaseDate,  DateTime createdAt,  String? note)?  $default,) {final _that = this;
switch (_that) {
case _CompanyAsset() when $default != null:
return $default(_that.id,_that.name,_that.category,_that.purchasePrice,_that.purchaseDate,_that.createdAt,_that.note);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CompanyAsset implements CompanyAsset {
  const _CompanyAsset({required this.id, required this.name, required this.category, required this.purchasePrice, required this.purchaseDate, required this.createdAt, this.note});
  factory _CompanyAsset.fromJson(Map<String, dynamic> json) => _$CompanyAssetFromJson(json);

@override final  String id;
@override final  String name;
@override final  AssetCategory category;
@override final  double purchasePrice;
@override final  DateTime purchaseDate;
@override final  DateTime createdAt;
@override final  String? note;

/// Create a copy of CompanyAsset
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CompanyAssetCopyWith<_CompanyAsset> get copyWith => __$CompanyAssetCopyWithImpl<_CompanyAsset>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CompanyAssetToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CompanyAsset&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.category, category) || other.category == category)&&(identical(other.purchasePrice, purchasePrice) || other.purchasePrice == purchasePrice)&&(identical(other.purchaseDate, purchaseDate) || other.purchaseDate == purchaseDate)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.note, note) || other.note == note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,category,purchasePrice,purchaseDate,createdAt,note);

@override
String toString() {
  return 'CompanyAsset(id: $id, name: $name, category: $category, purchasePrice: $purchasePrice, purchaseDate: $purchaseDate, createdAt: $createdAt, note: $note)';
}


}

/// @nodoc
abstract mixin class _$CompanyAssetCopyWith<$Res> implements $CompanyAssetCopyWith<$Res> {
  factory _$CompanyAssetCopyWith(_CompanyAsset value, $Res Function(_CompanyAsset) _then) = __$CompanyAssetCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, AssetCategory category, double purchasePrice, DateTime purchaseDate, DateTime createdAt, String? note
});




}
/// @nodoc
class __$CompanyAssetCopyWithImpl<$Res>
    implements _$CompanyAssetCopyWith<$Res> {
  __$CompanyAssetCopyWithImpl(this._self, this._then);

  final _CompanyAsset _self;
  final $Res Function(_CompanyAsset) _then;

/// Create a copy of CompanyAsset
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? category = null,Object? purchasePrice = null,Object? purchaseDate = null,Object? createdAt = null,Object? note = freezed,}) {
  return _then(_CompanyAsset(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as AssetCategory,purchasePrice: null == purchasePrice ? _self.purchasePrice : purchasePrice // ignore: cast_nullable_to_non_nullable
as double,purchaseDate: null == purchaseDate ? _self.purchaseDate : purchaseDate // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
