import '../../../../shared/models/transfer.dart';

/// Contract for reading and persisting transfers between owners.
abstract interface class TransferRepository {
  Stream<List<Transfer>> watchTransfers();

  Stream<List<Transfer>> watchTransfersByOwner(String ownerId);

  Future<List<Transfer>> getTransfers();

  Future<Transfer?> getTransferById(String id);

  Future<void> saveTransfer(Transfer transfer);

  Future<void> deleteTransfer(String id);
}
