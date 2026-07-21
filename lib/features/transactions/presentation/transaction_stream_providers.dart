import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/transaction.dart' as money;
import '../application/transaction_providers.dart';

final selectedOwnerFilterProvider =
    NotifierProvider.autoDispose<SelectedOwnerFilter, String?>(
      SelectedOwnerFilter.new,
    );

class SelectedOwnerFilter extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? ownerId) {
    state = ownerId;
  }
}

final transactionsStreamProvider =
    StreamProvider.autoDispose<List<money.Transaction>>((ref) {
      final ownerId = ref.watch(selectedOwnerFilterProvider);
      final repository = ref.watch(transactionRepositoryProvider);

      if (ownerId == null) {
        return ref.watch(watchTransactionsProvider)();
      }

      return repository.watchTransactionsByOwner(ownerId);
    });
