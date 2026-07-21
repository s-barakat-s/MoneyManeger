import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction.freezed.dart';
part 'transaction.g.dart';

/// The direction of a transaction for a single owner.
enum TransactionType {
  income,
  expense,
}

/// A money movement attached to one owner.
@freezed
abstract class Transaction with _$Transaction {
  const factory Transaction({
    required String id,
    required String ownerId,
    required TransactionType type,
    required double amount,
    required DateTime date,
    String? note,
  }) = _Transaction;

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);
}
