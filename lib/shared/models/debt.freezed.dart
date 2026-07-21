// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'debt.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Debt {

 String get id; String get personName; DebtType get type; double get totalAmount; double get paidAmount; DebtStatus get status; DateTime get createdAt; DateTime? get updatedAt; DateTime? get dueDate; DateTime? get archivedAt; String? get note;
/// Create a copy of Debt
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DebtCopyWith<Debt> get copyWith => _$DebtCopyWithImpl<Debt>(this as Debt, _$identity);

  /// Serializes this Debt to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Debt&&(identical(other.id, id) || other.id == id)&&(identical(other.personName, personName) || other.personName == personName)&&(identical(other.type, type) || other.type == type)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.paidAmount, paidAmount) || other.paidAmount == paidAmount)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt)&&(identical(other.note, note) || other.note == note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,personName,type,totalAmount,paidAmount,status,createdAt,updatedAt,dueDate,archivedAt,note);

@override
String toString() {
  return 'Debt(id: $id, personName: $personName, type: $type, totalAmount: $totalAmount, paidAmount: $paidAmount, status: $status, createdAt: $createdAt, updatedAt: $updatedAt, dueDate: $dueDate, archivedAt: $archivedAt, note: $note)';
}


}

/// @nodoc
abstract mixin class $DebtCopyWith<$Res>  {
  factory $DebtCopyWith(Debt value, $Res Function(Debt) _then) = _$DebtCopyWithImpl;
@useResult
$Res call({
 String id, String personName, DebtType type, double totalAmount, double paidAmount, DebtStatus status, DateTime createdAt, DateTime? updatedAt, DateTime? dueDate, DateTime? archivedAt, String? note
});




}
/// @nodoc
class _$DebtCopyWithImpl<$Res>
    implements $DebtCopyWith<$Res> {
  _$DebtCopyWithImpl(this._self, this._then);

  final Debt _self;
  final $Res Function(Debt) _then;

/// Create a copy of Debt
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? personName = null,Object? type = null,Object? totalAmount = null,Object? paidAmount = null,Object? status = null,Object? createdAt = null,Object? updatedAt = freezed,Object? dueDate = freezed,Object? archivedAt = freezed,Object? note = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,personName: null == personName ? _self.personName : personName // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as DebtType,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as double,paidAmount: null == paidAmount ? _self.paidAmount : paidAmount // ignore: cast_nullable_to_non_nullable
as double,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DebtStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,archivedAt: freezed == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Debt].
extension DebtPatterns on Debt {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Debt value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Debt() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Debt value)  $default,){
final _that = this;
switch (_that) {
case _Debt():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Debt value)?  $default,){
final _that = this;
switch (_that) {
case _Debt() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String personName,  DebtType type,  double totalAmount,  double paidAmount,  DebtStatus status,  DateTime createdAt,  DateTime? updatedAt,  DateTime? dueDate,  DateTime? archivedAt,  String? note)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Debt() when $default != null:
return $default(_that.id,_that.personName,_that.type,_that.totalAmount,_that.paidAmount,_that.status,_that.createdAt,_that.updatedAt,_that.dueDate,_that.archivedAt,_that.note);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String personName,  DebtType type,  double totalAmount,  double paidAmount,  DebtStatus status,  DateTime createdAt,  DateTime? updatedAt,  DateTime? dueDate,  DateTime? archivedAt,  String? note)  $default,) {final _that = this;
switch (_that) {
case _Debt():
return $default(_that.id,_that.personName,_that.type,_that.totalAmount,_that.paidAmount,_that.status,_that.createdAt,_that.updatedAt,_that.dueDate,_that.archivedAt,_that.note);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String personName,  DebtType type,  double totalAmount,  double paidAmount,  DebtStatus status,  DateTime createdAt,  DateTime? updatedAt,  DateTime? dueDate,  DateTime? archivedAt,  String? note)?  $default,) {final _that = this;
switch (_that) {
case _Debt() when $default != null:
return $default(_that.id,_that.personName,_that.type,_that.totalAmount,_that.paidAmount,_that.status,_that.createdAt,_that.updatedAt,_that.dueDate,_that.archivedAt,_that.note);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Debt implements Debt {
  const _Debt({required this.id, required this.personName, required this.type, required this.totalAmount, this.paidAmount = 0, this.status = DebtStatus.active, required this.createdAt, this.updatedAt, this.dueDate, this.archivedAt, this.note});
  factory _Debt.fromJson(Map<String, dynamic> json) => _$DebtFromJson(json);

@override final  String id;
@override final  String personName;
@override final  DebtType type;
@override final  double totalAmount;
@override@JsonKey() final  double paidAmount;
@override@JsonKey() final  DebtStatus status;
@override final  DateTime createdAt;
@override final  DateTime? updatedAt;
@override final  DateTime? dueDate;
@override final  DateTime? archivedAt;
@override final  String? note;

/// Create a copy of Debt
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DebtCopyWith<_Debt> get copyWith => __$DebtCopyWithImpl<_Debt>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DebtToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Debt&&(identical(other.id, id) || other.id == id)&&(identical(other.personName, personName) || other.personName == personName)&&(identical(other.type, type) || other.type == type)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.paidAmount, paidAmount) || other.paidAmount == paidAmount)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt)&&(identical(other.note, note) || other.note == note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,personName,type,totalAmount,paidAmount,status,createdAt,updatedAt,dueDate,archivedAt,note);

@override
String toString() {
  return 'Debt(id: $id, personName: $personName, type: $type, totalAmount: $totalAmount, paidAmount: $paidAmount, status: $status, createdAt: $createdAt, updatedAt: $updatedAt, dueDate: $dueDate, archivedAt: $archivedAt, note: $note)';
}


}

/// @nodoc
abstract mixin class _$DebtCopyWith<$Res> implements $DebtCopyWith<$Res> {
  factory _$DebtCopyWith(_Debt value, $Res Function(_Debt) _then) = __$DebtCopyWithImpl;
@override @useResult
$Res call({
 String id, String personName, DebtType type, double totalAmount, double paidAmount, DebtStatus status, DateTime createdAt, DateTime? updatedAt, DateTime? dueDate, DateTime? archivedAt, String? note
});




}
/// @nodoc
class __$DebtCopyWithImpl<$Res>
    implements _$DebtCopyWith<$Res> {
  __$DebtCopyWithImpl(this._self, this._then);

  final _Debt _self;
  final $Res Function(_Debt) _then;

/// Create a copy of Debt
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? personName = null,Object? type = null,Object? totalAmount = null,Object? paidAmount = null,Object? status = null,Object? createdAt = null,Object? updatedAt = freezed,Object? dueDate = freezed,Object? archivedAt = freezed,Object? note = freezed,}) {
  return _then(_Debt(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,personName: null == personName ? _self.personName : personName // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as DebtType,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as double,paidAmount: null == paidAmount ? _self.paidAmount : paidAmount // ignore: cast_nullable_to_non_nullable
as double,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DebtStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,archivedAt: freezed == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
