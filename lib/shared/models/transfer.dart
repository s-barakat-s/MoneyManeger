import 'package:freezed_annotation/freezed_annotation.dart';

part 'transfer.freezed.dart';
part 'transfer.g.dart';

/// A money movement from one owner to another owner.
@freezed
abstract class Transfer with _$Transfer {
  const factory Transfer({
    required String id,
    required String fromOwnerId,
    required String toOwnerId,
    required double amount,
    required DateTime date,
    String? note,
  }) = _Transfer;

  factory Transfer.fromJson(Map<String, dynamic> json) =>
      _$TransferFromJson(json);
}
