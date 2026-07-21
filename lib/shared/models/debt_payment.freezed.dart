// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'debt_payment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DebtPayment {

 String get id; String get debtId; double get amount; DateTime get date; String? get note;
/// Create a copy of DebtPayment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DebtPaymentCopyWith<DebtPayment> get copyWith => _$DebtPaymentCopyWithImpl<DebtPayment>(this as DebtPayment, _$identity);

  /// Serializes this DebtPayment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DebtPayment&&(identical(other.id, id) || other.id == id)&&(identical(other.debtId, debtId) || other.debtId == debtId)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.date, date) || other.date == date)&&(identical(other.note, note) || other.note == note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,debtId,amount,date,note);

@override
String toString() {
  return 'DebtPayment(id: $id, debtId: $debtId, amount: $amount, date: $date, note: $note)';
}


}

/// @nodoc
abstract mixin class $DebtPaymentCopyWith<$Res>  {
  factory $DebtPaymentCopyWith(DebtPayment value, $Res Function(DebtPayment) _then) = _$DebtPaymentCopyWithImpl;
@useResult
$Res call({
 String id, String debtId, double amount, DateTime date, String? note
});




}
/// @nodoc
class _$DebtPaymentCopyWithImpl<$Res>
    implements $DebtPaymentCopyWith<$Res> {
  _$DebtPaymentCopyWithImpl(this._self, this._then);

  final DebtPayment _self;
  final $Res Function(DebtPayment) _then;

/// Create a copy of DebtPayment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? debtId = null,Object? amount = null,Object? date = null,Object? note = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,debtId: null == debtId ? _self.debtId : debtId // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DebtPayment].
extension DebtPaymentPatterns on DebtPayment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DebtPayment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DebtPayment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DebtPayment value)  $default,){
final _that = this;
switch (_that) {
case _DebtPayment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DebtPayment value)?  $default,){
final _that = this;
switch (_that) {
case _DebtPayment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String debtId,  double amount,  DateTime date,  String? note)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DebtPayment() when $default != null:
return $default(_that.id,_that.debtId,_that.amount,_that.date,_that.note);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String debtId,  double amount,  DateTime date,  String? note)  $default,) {final _that = this;
switch (_that) {
case _DebtPayment():
return $default(_that.id,_that.debtId,_that.amount,_that.date,_that.note);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String debtId,  double amount,  DateTime date,  String? note)?  $default,) {final _that = this;
switch (_that) {
case _DebtPayment() when $default != null:
return $default(_that.id,_that.debtId,_that.amount,_that.date,_that.note);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DebtPayment implements DebtPayment {
  const _DebtPayment({required this.id, required this.debtId, required this.amount, required this.date, this.note});
  factory _DebtPayment.fromJson(Map<String, dynamic> json) => _$DebtPaymentFromJson(json);

@override final  String id;
@override final  String debtId;
@override final  double amount;
@override final  DateTime date;
@override final  String? note;

/// Create a copy of DebtPayment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DebtPaymentCopyWith<_DebtPayment> get copyWith => __$DebtPaymentCopyWithImpl<_DebtPayment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DebtPaymentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DebtPayment&&(identical(other.id, id) || other.id == id)&&(identical(other.debtId, debtId) || other.debtId == debtId)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.date, date) || other.date == date)&&(identical(other.note, note) || other.note == note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,debtId,amount,date,note);

@override
String toString() {
  return 'DebtPayment(id: $id, debtId: $debtId, amount: $amount, date: $date, note: $note)';
}


}

/// @nodoc
abstract mixin class _$DebtPaymentCopyWith<$Res> implements $DebtPaymentCopyWith<$Res> {
  factory _$DebtPaymentCopyWith(_DebtPayment value, $Res Function(_DebtPayment) _then) = __$DebtPaymentCopyWithImpl;
@override @useResult
$Res call({
 String id, String debtId, double amount, DateTime date, String? note
});




}
/// @nodoc
class __$DebtPaymentCopyWithImpl<$Res>
    implements _$DebtPaymentCopyWith<$Res> {
  __$DebtPaymentCopyWithImpl(this._self, this._then);

  final _DebtPayment _self;
  final $Res Function(_DebtPayment) _then;

/// Create a copy of DebtPayment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? debtId = null,Object? amount = null,Object? date = null,Object? note = freezed,}) {
  return _then(_DebtPayment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,debtId: null == debtId ? _self.debtId : debtId // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
