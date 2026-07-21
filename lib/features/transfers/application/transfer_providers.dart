import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/transfer.dart';
import '../domain/repositories/transfer_repository.dart';
import 'use_cases/create_transfer.dart';
import 'use_cases/delete_transfer.dart';

final transferRepositoryProvider = Provider<TransferRepository>((ref) {
  throw UnimplementedError('TransferRepository is not configured.');
});

final createTransferProvider = Provider<CreateTransfer>((ref) {
  return CreateTransfer(ref.watch(transferRepositoryProvider));
});

final deleteTransferProvider = Provider<DeleteTransfer>((ref) {
  return DeleteTransfer(ref.watch(transferRepositoryProvider));
});

final watchTransfersProvider = Provider<Stream<List<Transfer>> Function()>((ref) {
  return ref.watch(transferRepositoryProvider).watchTransfers;
});
