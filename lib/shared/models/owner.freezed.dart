// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'owner.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Owner {

 String get id; String get name; DateTime get createdAt;
/// Create a copy of Owner
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OwnerCopyWith<Owner> get copyWith => _$OwnerCopyWithImpl<Owner>(this as Owner, _$identity);

  /// Serializes this Owner to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Owner&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,createdAt);

@override
String toString() {
  return 'Owner(id: $id, name: $name, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $OwnerCopyWith<$Res>  {
  factory $OwnerCopyWith(Owner value, $Res Function(Owner) _then) = _$OwnerCopyWithImpl;
@useResult
$Res call({
 String id, String name, DateTime createdAt
});




}
/// @nodoc
class _$OwnerCopyWithImpl<$Res>
    implements $OwnerCopyWith<$Res> {
  _$OwnerCopyWithImpl(this._self, this._then);

  final Owner _self;
  final $Res Function(Owner) _then;

/// Create a copy of Owner
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Owner].
extension OwnerPatterns on Owner {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Owner value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Owner() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Owner value)  $default,){
final _that = this;
switch (_that) {
case _Owner():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Owner value)?  $default,){
final _that = this;
switch (_that) {
case _Owner() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Owner() when $default != null:
return $default(_that.id,_that.name,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _Owner():
return $default(_that.id,_that.name,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Owner() when $default != null:
return $default(_that.id,_that.name,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Owner implements Owner {
  const _Owner({required this.id, required this.name, required this.createdAt});
  factory _Owner.fromJson(Map<String, dynamic> json) => _$OwnerFromJson(json);

@override final  String id;
@override final  String name;
@override final  DateTime createdAt;

/// Create a copy of Owner
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OwnerCopyWith<_Owner> get copyWith => __$OwnerCopyWithImpl<_Owner>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OwnerToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Owner&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,createdAt);

@override
String toString() {
  return 'Owner(id: $id, name: $name, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$OwnerCopyWith<$Res> implements $OwnerCopyWith<$Res> {
  factory _$OwnerCopyWith(_Owner value, $Res Function(_Owner) _then) = __$OwnerCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, DateTime createdAt
});




}
/// @nodoc
class __$OwnerCopyWithImpl<$Res>
    implements _$OwnerCopyWith<$Res> {
  __$OwnerCopyWithImpl(this._self, this._then);

  final _Owner _self;
  final $Res Function(_Owner) _then;

/// Create a copy of Owner
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? createdAt = null,}) {
  return _then(_Owner(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
