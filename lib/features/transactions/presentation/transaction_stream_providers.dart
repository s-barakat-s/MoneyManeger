import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/transaction.dart' as money;
import '../../business/application/business_actor_name_providers.dart';
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

final transactionActorNamesProvider =
    FutureProvider.autoDispose<Map<String, String>>((ref) async {
      final transactions = await ref.watch(transactionsStreamProvider.future);
      final actorUids = transactions
          .map((transaction) => transaction.audit.createdBy)
          .whereType<String>()
          .toSet()
          .toList()
        ..sort();
      return ref.watch(actorNamesProvider(actorUids.join('|')).future);
    });
