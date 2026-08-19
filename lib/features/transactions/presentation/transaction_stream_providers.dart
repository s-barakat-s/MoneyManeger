import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/transaction.dart' as money;
import '../../business/application/business_actor_identity_providers.dart';
import '../../business/application/business_providers.dart';
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
      return ref
          .watch(businessActorIdentityRepositoryProvider)
          .resolveTransactionActors(
            businessId: ref.watch(activeBusinessIdProvider),
            transactionIds: transactions.map((transaction) => transaction.id),
          );
    });
