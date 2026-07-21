import 'package:freezed_annotation/freezed_annotation.dart';

part 'debt.freezed.dart';
part 'debt.g.dart';

/// The direction of a debt relative to the app owner.
enum DebtType {
  @JsonValue('we_owe')
  weOwe,
  @JsonValue('owed_to_us')
  owedToUs,
}

enum DebtStatus {
  active,
  paid,
  archived,
}

/// A debt record tracked against an external person.
@freezed
abstract class Debt with _$Debt {
  const factory Debt({
    required String id,
    required String personName,
    required DebtType type,
    required double totalAmount,
    @Default(0) double paidAmount,
    @Default(DebtStatus.active) DebtStatus status,
    required DateTime createdAt,
    DateTime? updatedAt,
    DateTime? dueDate,
    DateTime? archivedAt,
    String? note,
  }) = _Debt;

  factory Debt.fromJson(Map<String, dynamic> json) => _$DebtFromJson(json);
}
